"""
Development script to verify Qwen streaming.
"""
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.providers import ProviderFactory
from utils.logger import get_logger
import sys as system_sys

logger = get_logger("verify_qwen_stream")

def main():
    logger.info("Initializing ProviderFactory...")
    ProviderFactory.initialize()
    
    provider = ProviderFactory.get_provider()
    
    prompt = "Write a short poem about an AI learning to stream its thoughts."
    logger.info(f"Sending prompt: {prompt}")
    
    try:
        stream = provider.generate_stream(prompt)
        logger.info("Streaming response:")
        print("-" * 40)
        
        for chunk in stream:
            system_sys.stdout.write(chunk)
            system_sys.stdout.flush()
            
        print("\n" + "-" * 40)
        logger.info("Stream complete.")
        
    except Exception as e:
        logger.error(f"Failed during streaming: {str(e)}")

if __name__ == "__main__":
    main()
