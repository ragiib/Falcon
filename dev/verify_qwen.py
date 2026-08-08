"""
End-to-End Verification script for Qwen 2.5 7B Q4_K_M model integration.
"""
import sys
import os
import time
import subprocess
import psutil

# Add parent dir to path to allow importing core modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.providers import ProviderFactory
from utils.logger import get_logger
from config import settings
import sys as system_sys

logger = get_logger("verify_qwen_e2e")

def get_vram_usage():
    try:
        result = subprocess.run(
            ['nvidia-smi', '--query-gpu=memory.used', '--format=csv,noheader,nounits'],
            stdout=subprocess.PIPE, text=True, check=True
        )
        return int(result.stdout.strip())
    except Exception as e:
        logger.warning(f"Failed to get VRAM: {e}")
        return 0

def get_ram_usage():
    process = psutil.Process(os.getpid())
    return process.memory_info().rss / (1024 * 1024)

def print_memory_stats(label):
    vram = get_vram_usage()
    ram = get_ram_usage()
    logger.info(f"[{label}] RAM Usage: {ram:.2f} MB | VRAM Usage: {vram} MB")

def main():
    logger.info("Starting End-to-End Verification")
    
    # 1. Verify GGUF files
    model_dir = os.path.dirname(settings.MODEL_PATH)
    logger.info(f"Checking model directory: {model_dir}")
    if os.path.exists(model_dir):
        files = os.listdir(model_dir)
        gguf_files = [f for f in files if f.endswith('.gguf')]
        logger.info(f"Found GGUF files:\n" + "\n".join(f"  - {f}" for f in gguf_files))
    else:
        logger.error(f"Model directory not found: {model_dir}")
        return

    # 2. Verify Provider setup
    ProviderFactory.initialize()
    provider = ProviderFactory.get_provider()
    
    print_memory_stats("Before Model Load")
    
    # 3 & 4. Explicit model load to measure load time & check offloading
    logger.info("Forcing model load to measure time...")
    start_time = time.time()
    provider.load_model()
    load_time = time.time() - start_time
    logger.info(f"Model Load Time: {load_time:.2f} seconds")
    
    print_memory_stats("After Model Load")
    
    # 5. Health Check
    health = provider.health_check()
    logger.info(f"Health Check: {health}")

    # 6. Execute Prompts
    prompts_standard = [
        "Hello, who are you?",
        "Write a Python function that reverses a string."
    ]
    
    for idx, prompt in enumerate(prompts_standard):
        logger.info(f"\n--- Standard Prompt {idx+1} ---")
        logger.info(f"Prompt: {prompt}")
        start_gen = time.time()
        
        response = provider.generate(prompt)
        
        total_time = time.time() - start_gen
        reply = response["reply"].strip()
        usage = response.get("usage", {})
        tokens = usage.get("completion_tokens", 0)
        tps = tokens / total_time if total_time > 0 else 0
        
        logger.info(f"Reply: {reply}")
        logger.info(f"Total Generation Time: {total_time:.2f}s | Tokens: {tokens} | TPS: {tps:.2f}")
        print_memory_stats(f"After Prompt {idx+1}")

    logger.info("\n--- Streaming Prompt ---")
    prompt_stream = "Explain what an AI agent is in simple language."
    logger.info(f"Prompt: {prompt_stream}")
    
    start_stream = time.time()
    stream = provider.generate_stream(prompt_stream)
    
    first_token_time = None
    tokens_generated = 0
    
    print("Streaming Reply: ", end="")
    for chunk in stream:
        if first_token_time is None:
            first_token_time = time.time() - start_stream
            logger.info(f"\n[First Token Latency: {first_token_time:.2f}s]")
        
        system_sys.stdout.write(chunk)
        system_sys.stdout.flush()
        tokens_generated += 1
        
    total_stream_time = time.time() - start_stream
    print("\n")
    tps_stream = tokens_generated / total_stream_time if total_stream_time > 0 else 0
    logger.info(f"Total Stream Time: {total_stream_time:.2f}s | Tokens (est): {tokens_generated} | TPS: {tps_stream:.2f}")
    print_memory_stats("After Streaming Prompt")
    
    logger.info("\nEnd-to-End Verification Complete.")

if __name__ == "__main__":
    main()
