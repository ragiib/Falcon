"""
Verification & Test Suite for Falcon Dual Intelligence Mode.
"""
import sys
import os
import time

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.connectivity import check_internet_connection
from core.providers.factory import ProviderFactory, DualIntelligenceProvider
from core.intelligence.engine import ConversationEngine
from core.intelligence.context import ContextManager
from utils.logger import get_logger

logger = get_logger("test_dual_intelligence")

def test_connectivity():
    logger.info("--- Testing Internet Connectivity Detection ---")
    t0 = time.perf_counter()
    is_online = check_internet_connection()
    dt = (time.perf_counter() - t0) * 1000.0
    logger.info(f"Internet Connection Detected: {is_online} (Detection Time: {dt:.2f}ms)")
    return is_online

def test_online_mode():
    logger.info("\n--- Testing ONLINE MODE (Internet Available) ---")
    ProviderFactory._instance = None
    ProviderFactory.initialize()
    provider = ProviderFactory.get_provider()
    
    assert isinstance(provider, DualIntelligenceProvider)
    
    health = provider.health_check()
    logger.info(f"Health Check Status: {health}")
    logger.info(f"Offline Qwen Loaded: {health['offline_qwen_loaded']} (Must be False!)")
    
    session_id = "test_online_session_101"
    user_query = "What are the latest developments in AI technology today?"
    
    logger.info(f"Prompting Online Agent: '{user_query}'")
    stream = ConversationEngine.chat_stream(session_id, user_query)
    
    full_resp = ""
    for token in stream:
        full_resp += token
        print(token, end="", flush=True)
    print("\n")
    
    # Verify zero local Qwen load
    health_post = provider.health_check()
    logger.info(f"Post-Stream Offline Qwen Loaded: {health_post['offline_qwen_loaded']} (Must be False!)")
    assert health_post['offline_qwen_loaded'] == False, "CRITICAL ERROR: Local Qwen was loaded during Online Mode!"

def test_offline_mode():
    logger.info("\n--- Testing OFFLINE MODE (Local Qwen 2.5 7B Q4_K_M) ---")
    provider = ProviderFactory.get_provider()
    
    session_id = "test_offline_session_202"
    user_query = "Explain quantum computing in one simple sentence."
    
    logger.info(f"Simulating Offline Mode for local Qwen model...")
    # Force route to offline model
    qwen = provider._get_offline_qwen()
    qwen.load_model()
    
    health_post = provider.health_check()
    logger.info(f"Health Check: {health_post}")
    
    tokens = list(qwen.generate_stream(user_query))
    full_resp = "".join(tokens)
    logger.info(f"Offline Qwen Response: {full_resp}")

def main():
    logger.info("==================================================")
    logger.info("FALCON DUAL INTELLIGENCE MODE TEST SUITE")
    logger.info("==================================================")
    
    is_online = test_connectivity()
    if is_online:
        test_online_mode()
    test_offline_mode()
    
    logger.info("\n==================================================")
    logger.info("DUAL INTELLIGENCE MODE VERIFICATION COMPLETE - SUCCESS!")
    logger.info("==================================================")

if __name__ == "__main__":
    main()
