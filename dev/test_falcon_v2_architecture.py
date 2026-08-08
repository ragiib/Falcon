"""
Developer test script for FALCON V2 Core Intelligence Architecture and Dual Operation Mode.
"""
import sys
import os

# Add root directory to python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from core.router.intent_router import IntentRouter
from core.tools.executor import LocalToolExecutor
from memory.manager import MemoryManager
from core.providers.factory import ProviderFactory

def test_intent_router():
    print("\n--- TEST 1: INTENT ROUTER ---")
    test_queries = [
        ("Open VS Code.", "TOOL"),
        ("Open Google and search Flutter.", "TOOL"),
        ("What is the latest Android version?", "WEB_SEARCH"),
        ("Explain binary search.", "PERSONAL_AI"),
        ("Remember that my interview is on Monday.", "PERSONAL_AI"),
    ]

    for query, expected in test_queries:
        intent = IntentRouter.classify(query)
        print(f"Query: '{query}' -> Detected Intent: {intent} (Expected: {expected})")
        assert intent == expected, f"Expected {expected} but got {intent}"
    print("Intent Router test PASSED!")

def test_tool_manager():
    print("\n--- TEST 2: TOOL MANAGER ---")
    print("Is 'open vs code' a tool command?", LocalToolExecutor.is_tool_command("open vs code"))
    assert LocalToolExecutor.is_tool_command("open vs code") is True

    # Test dry execution (confirmation string)
    cmd_res = LocalToolExecutor.execute_command("open vs code")
    print("Execution result:", cmd_res)
    assert "Opening Visual Studio Code" in cmd_res
    print("Tool Manager test PASSED!")

def test_memory_manager():
    print("\n--- TEST 3: MEMORY MANAGER ---")
    conf = MemoryManager.detect_and_store("Remember that my interview is on Monday.")
    print("Memory Store Result:", conf)
    assert conf is not None and "interview is on Monday" in conf

    mem_ctx = MemoryManager.get_relevant_memories()
    print("Retrieved Memory Context:\n", mem_ctx)
    assert "interview is on Monday" in mem_ctx
    print("Memory Manager test PASSED!")

def test_dual_operation_mode():
    print("\n--- TEST 4: DUAL OPERATION MODE & MEMORY MANAGEMENT ---")
    provider = ProviderFactory.get_provider()
    
    # 1. Startup in Agent Mode
    mode_info = provider.get_mode_info()
    print("Startup mode info:", mode_info)
    assert mode_info["mode"] == "agent"
    assert mode_info["qwen_loaded"] is False
    print("Agent Mode verified: Qwen NOT loaded in memory.")

    # 2. Test TOOL streaming in Agent Mode
    stream_res = list(provider.generate_stream("Open VS Code"))
    response_text = "".join(stream_res)
    print("Agent Mode TOOL response:", response_text)
    assert "Opening Visual Studio Code" in response_text

    print("Dual Operation Mode test PASSED!")

if __name__ == "__main__":
    test_intent_router()
    test_tool_manager()
    test_memory_manager()
    test_dual_operation_mode()
    print("\nALL FALCON V2 CORE ARCHITECTURE TESTS PASSED SUCCESSFULLY!")
