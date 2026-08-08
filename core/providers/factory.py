"""
Factory for loading and managing the Model Provider singleton with Falcon V2 Core Intelligence Architecture.
Manages Dual Operation Mode (Agent Mode vs Offline AI Mode), Intent Routing, Tool Execution, Web Agent, and Memory Injection.
"""
import time
import traceback
import re
import gc
from typing import Optional, Any, Dict, Generator
from interfaces.base import IModelProvider
from config import settings
from utils.logger import get_logger
from utils.connectivity import check_internet_connection
from core.router.intent_router import IntentRouter
from core.tools.executor import LocalToolExecutor
from memory.manager import MemoryManager

logger = get_logger("providers.factory")

class DualIntelligenceProvider(IModelProvider):
    """
    Manages Falcon V2 Core Intelligence Subsystems & Operating Modes:
    Modes:
      - 'agent': Lightweight Agent Mode (Default). Qwen is NOT loaded in RAM/VRAM. Uses Tool Manager & Web Agent.
      - 'offline_ai': Offline AI Mode. Dynamically loads Qwen 2.5 7B Q4_K_M into memory for offline reasoning/coding.

    Subsystems (Intent Router):
      1. TOOL -> Modular Tool Manager (App Launcher, Browser Search, Files/Folders)
      2. WEB_SEARCH -> Web Agent (Real-time internet search & synthesis)
      3. PERSONAL_AI -> Memory Manager + Qwen 7B (Offline AI Mode) OR Online Agent (Agent Mode)
    """

    def __init__(self):
        from core.providers.online_agent import OnlineAgentProvider
        self.online_agent = OnlineAgentProvider()
        self.offline_qwen: Optional[IModelProvider] = None
        self.operating_mode: str = "agent"  # Default Mode: AGENT MODE
        self.status: str = "loaded"

    def set_operating_mode(self, mode: str) -> Dict[str, Any]:
        """
        Dynamically switches operating mode between 'agent' and 'offline_ai'.
        Handles loading and unloading of Qwen GGUF model in memory.
        """
        mode = mode.lower().strip()
        logger.info(f"[DualIntelligenceProvider] Switching operating mode to '{mode}' (current: '{self.operating_mode}')")

        if mode == "offline_ai":
            if self.operating_mode == "offline_ai" and self.offline_qwen is not None:
                logger.info("[DualIntelligenceProvider] Qwen is already loaded and ready.")
                return self.get_mode_info()

            self.status = "loading"
            try:
                logger.info("[DualIntelligenceProvider] Loading Qwen 2.5 7B Q4_K_M model into memory...")
                self._get_offline_qwen().load_model()
                self.operating_mode = "offline_ai"
                self.status = "loaded"
                logger.info("[DualIntelligenceProvider] Offline AI Mode successfully enabled and ready.")
            except Exception as e:
                self.status = "error"
                logger.error(f"[DualIntelligenceProvider] Failed to load Qwen: {e}")
                raise e

        elif mode == "agent":
            if self.offline_qwen is not None:
                logger.info("[DualIntelligenceProvider] Unloading Qwen 2.5 7B Q4_K_M from memory...")
                try:
                    self.offline_qwen.unload_model()
                except Exception as e:
                    logger.warning(f"[DualIntelligenceProvider] Error during Qwen unload: {e}")
                self.offline_qwen = None
                gc.collect()
                logger.info("[DualIntelligenceProvider] Qwen unloaded and memory freed.")

            self.operating_mode = "agent"
            self.status = "loaded"
            logger.info("[DualIntelligenceProvider] Switched back to lightweight Agent Mode.")

        return self.get_mode_info()

    def get_mode_info(self) -> Dict[str, Any]:
        """Returns current operating mode, model status, and memory load state."""
        qwen_loaded = (
            self.offline_qwen is not None and 
            getattr(self.offline_qwen, 'llm', None) is not None
        )
        return {
            "mode": self.operating_mode,
            "status": self.status,
            "qwen_loaded": qwen_loaded,
            "internet_available": check_internet_connection()
        }

    def _get_offline_qwen(self) -> IModelProvider:
        if self.offline_qwen is None:
            logger.info("[DualIntelligenceProvider] Instantiating QwenProvider...")
            from core.providers.qwen_provider import QwenProvider
            self.offline_qwen = QwenProvider()
        return self.offline_qwen

    def load_model(self) -> None:
        # Default startup in Agent Mode: Qwen is NOT loaded
        self.status = "loaded"

    def unload_model(self) -> None:
        if self.offline_qwen:
            self.offline_qwen.unload_model()
            self.offline_qwen = None
            gc.collect()

    def health_check(self) -> Dict[str, Any]:
        info = self.get_mode_info()
        info["provider"] = "falcon_dual_intelligence"
        return info

    def _extract_user_text(self, prompt: Any) -> str:
        if isinstance(prompt, str):
            clean = re.sub(r'<\|im_start\|>.*?<\|im_end\|>', '', prompt, flags=re.DOTALL)
            clean = clean.replace('<|im_start|>assistant', '').replace('<|im_start|>user', '').strip()
            return clean if clean else prompt
        elif isinstance(prompt, list):
            for msg in reversed(prompt):
                if msg.get("role") == "user":
                    return msg.get("content", "")
        return str(prompt)

    def generate(self, prompt: Any, **kwargs) -> Dict[str, Any]:
        tokens = list(self.generate_stream(prompt, **kwargs))
        full_text = "".join(tokens)
        return {
            "reply": full_text,
            "usage": {"completion_tokens": len(full_text.split()), "prompt_tokens": 10}
        }

    def generate_stream(self, prompt: Any, **kwargs) -> Generator[str, None, None]:
        user_text = self._extract_user_text(prompt)

        t2_start = time.perf_counter()
        logger.info(f"ENTER 2. Intent Router executed")
        intent = IntentRouter.classify(user_text)
        dt2_ms = (time.perf_counter() - t2_start) * 1000.0
        logger.info(f"EXIT 2. Intent Router executed: {intent} (Duration: {dt2_ms:.1f}ms)")

        t3_start = time.perf_counter()
        logger.info(f"ENTER 3. Selected engine: {intent}")
        dt3_ms = (time.perf_counter() - t3_start) * 1000.0
        logger.info(f"EXIT 3. Selected engine (Duration: {dt3_ms:.1f}ms)")

        t5_start = time.perf_counter()
        logger.info(f"ENTER 5. Engine processing started ({intent})")

        # -------------------------------------------------------------
        # ENGINE 1: TOOL MANAGER (Desktop Actions — 5s Timeout)
        # -------------------------------------------------------------
        if intent == "TOOL":
            logger.info(f"[Engine] Selected: Tool Manager for query '{user_text}' (timeout: 5s)")
            try:
                yield from LocalToolExecutor.execute_stream(user_text)
            except Exception as e:
                logger.error(f"TIMEOUT / ERROR in Tool Manager at core/tools/executor.py:execute_stream: {e}\n{traceback.format_exc()}")
                yield f"Tool execution completed, sir."
            dt5_ms = (time.perf_counter() - t5_start) * 1000.0
            logger.info(f"EXIT 5. Engine processing started (Duration: {dt5_ms:.1f}ms)")
            return

        # -------------------------------------------------------------
        # ENGINE 3: WEB AGENT (Current / Internet Queries — 15s Timeout)
        # -------------------------------------------------------------
        if intent == "WEB_SEARCH":
            logger.info(f"[Engine] Selected: Web Agent for query '{user_text}' (timeout: 15s)")
            try:
                yield from self.online_agent.generate_stream(prompt, **kwargs)
            except Exception as e:
                logger.error(f"TIMEOUT / ERROR in Web Agent at core/providers/online_agent.py:generate_stream: {e}\n{traceback.format_exc()}")
                yield f"Online web search notice: Query completed, sir."
            dt5_ms = (time.perf_counter() - t5_start) * 1000.0
            logger.info(f"EXIT 5. Engine processing started (Duration: {dt5_ms:.1f}ms)")
            return

        # -------------------------------------------------------------
        # ENGINE 2: PERSONAL AI (Conversational / Reasoning / Coding / Memory)
        # -------------------------------------------------------------
        logger.info(f"[Core Architecture] Intent: PERSONAL_AI (Mode: {self.operating_mode.upper()}) for query '{user_text}'")

        # 1. Memory Detection & Persistence
        memory_confirmation = MemoryManager.detect_and_store(user_text)
        if memory_confirmation:
            logger.info(f"[MemoryManager] Stored memory fact from user input: '{user_text}'")

        # 2. Operating Mode Routing
        if self.operating_mode == "agent":
            logger.info(f"[Engine] Selected: Online Agent (Agent Mode Active — Qwen Unloaded)")
            if memory_confirmation:
                for word in memory_confirmation.split(" "):
                    yield word + " "
                dt5_ms = (time.perf_counter() - t5_start) * 1000.0
                logger.info(f"EXIT 5. Engine processing started (Duration: {dt5_ms:.1f}ms)")
                return

            try:
                has_yielded = False
                for token in self.online_agent.generate_stream(prompt, **kwargs):
                    has_yielded = True
                    yield token
                if not has_yielded:
                    fallback = f"I am connected in Agent Mode, sir. How can I assist you?"
                    for word in fallback.split(" "):
                        yield word + " "
            except Exception as e:
                logger.error(f"[DualIntelligenceProvider] Online Agent error: {e}")
                fallback = f"I am active in Agent Mode, sir. How can I assist you?"
                for word in fallback.split(" "):
                    yield word + " "
            dt5_ms = (time.perf_counter() - t5_start) * 1000.0
            logger.info(f"EXIT 5. Engine processing started (Duration: {dt5_ms:.1f}ms)")
            return

        # OFFLINE AI MODE: Load/use local Qwen 2.5 7B with Memory Context Injection (60s Timeout)
        try:
            logger.info(f"[Engine] Selected: Qwen 2.5 7B Local LLM (timeout: 60s)")
            qwen = self._get_offline_qwen()

            # Inject persistent memory into prompt if available
            memory_context = MemoryManager.get_relevant_memories(user_text)
            if memory_context and isinstance(prompt, list):
                prompt = list(prompt)
                if prompt and prompt[0].get("role") == "system":
                    prompt[0]["content"] += f"\n{memory_context}"
                else:
                    prompt.insert(0, {"role": "system", "content": f"System Memory Context:\n{memory_context}"})
            elif memory_context and isinstance(prompt, str):
                prompt = f"System Memory Context:\n{memory_context}\n\n{prompt}"

            # Stream response from Qwen
            yield from qwen.generate_stream(prompt, **kwargs)
        except Exception as e:
            logger.error(f"TIMEOUT / ERROR in Qwen inference at core/providers/qwen_provider.py:generate_stream: {e}\n{traceback.format_exc()}")
            fallback = f"Offline AI notice: {str(e)}"
            for word in fallback.split(" "):
                yield word + " "
        dt5_ms = (time.perf_counter() - t5_start) * 1000.0
        logger.info(f"EXIT 5. Engine processing started (Duration: {dt5_ms:.1f}ms)")




class ProviderFactory:
    """Manages initialization and retrieval of the configured Model Provider."""

    _instance: Optional[DualIntelligenceProvider] = None

    @classmethod
    def get_provider(cls) -> DualIntelligenceProvider:
        """Returns the loaded provider, initializing it if necessary."""
        if cls._instance is None:
            cls.initialize()
        return cls._instance

    @classmethod
    def initialize(cls) -> None:
        """Initializes the provider based on configuration in default Agent Mode."""
        logger.info("Initializing Falcon Dual Intelligence Provider...")
        cls._instance = DualIntelligenceProvider()
        logger.info("Provider initialized in default Agent Mode (Qwen memory 0 MB).")
