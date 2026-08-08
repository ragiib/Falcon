"""
Verification Suite for Falcon Smart Hybrid Intelligence Router.
"""
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.router.hybrid_router import SmartHybridRouter
from core.providers.factory import ProviderFactory
from core.intelligence.engine import ConversationEngine
from utils.logger import get_logger

logger = get_logger("test_hybrid_router")

def test_router_classification():
    logger.info("==================================================")
    logger.info("1. TESTING SMART ROUTER CLASSIFICATION RULES")
    logger.info("==================================================")

    test_cases = [
        # Personal / Assistant questions -> local_qwen
        ("Falcon, I am feeling stressed.", "local_qwen"),
        ("How can I improve my workout?", "local_qwen"),
        ("I feel sad today.", "local_qwen"),
        ("Help me plan my study routine.", "local_qwen"),
        ("Remember this idea.", "local_qwen"),
        ("What should I do tomorrow?", "local_qwen"),
        ("Write a message for my girlfriend.", "local_qwen"),

        # Factual / Current Information -> online
        ("Falcon, what is the latest Windows 11 update?", "online"),
        ("What is the latest NVIDIA GPU?", "online"),
        ("Who won yesterday's cricket match?", "online"),
        ("What is the current price of Bitcoin?", "online"),
        ("Latest UFC results", "online"),
        ("What happened today in AI news?", "online"),
        ("Search Google for space exploration", "online"),

        # System / Agent Commands -> tool
        ("Falcon, open Notepad and write 'Buy milk.'", "tool"),
        ("Open Notepad", "tool"),
        ("Open VS Code", "tool"),
        ("Open Chrome", "tool"),
        ("Create a file named notes.txt", "tool"),
        ("Play music", "tool"),
    ]

    passed_count = 0
    for query, expected_target in test_cases:
        actual_target = SmartHybridRouter.classify(query)
        status = "PASSED" if actual_target == expected_target else f"FAILED (Got '{actual_target}')"
        logger.info(f"Query: '{query}' => Target: '{actual_target}' [{status}]")
        assert actual_target == expected_target, f"Failed routing for '{query}': expected '{expected_target}', got '{actual_target}'"
        passed_count += 1

    logger.info(f"\nClassification Test Results: {passed_count}/{len(test_cases)} Passed Successfully!\n")

def test_e2e_routing():
    logger.info("==================================================")
    logger.info("2. TESTING END-TO-END ENGINE ROUTING")
    logger.info("==================================================")

    ProviderFactory._instance = None
    ProviderFactory.initialize()

    queries = [
        ("Falcon, I am feeling stressed.", "local_qwen"),
        ("Falcon, what is the latest Windows 11 update?", "online"),
        ("Falcon, open Notepad and write 'Buy milk.'", "tool"),
    ]

    for idx, (query, expected) in enumerate(queries, 1):
        logger.info(f"\n--- Example {idx}: '{query}' (Expected: {expected}) ---")
        session_id = f"test_session_{idx}"
        stream = ConversationEngine.chat_stream(session_id, query)
        
        reply = "".join(list(stream))
        logger.info(f"Engine Output: '{reply.strip()}'\n")

def main():
    test_router_classification()
    test_e2e_routing()
    logger.info("==================================================")
    logger.info("SMART HYBRID ROUTER VERIFICATION COMPLETE - SUCCESS!")
    logger.info("==================================================")

if __name__ == "__main__":
    main()
