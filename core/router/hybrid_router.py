"""
Smart Hybrid Intelligence Router for Falcon.
Classifies user queries prior to inference into Local Tools, Online Agent, or Local Qwen 7B.
"""
import re
from core.tools.executor import LocalToolExecutor
from utils.logger import get_logger

logger = get_logger("router.hybrid")

class SmartHybridRouter:
    """Classifies user queries into 'tool', 'online', or 'local_qwen' targets."""

    FACTUAL_PATTERNS = [
        r"\b(latest|recent|current)\s+(nvidia|gpu|windows|update|news|price|rate|score|results|event)\b",
        r"\b(who\s+won|yesterday['\s]*s|today['\s]*s)\b",
        r"\b(price\s+of|bitcoin|crypto|stock|weather|score)\b",
        r"\b(search|google)\s+(for|about)?\b",
        r"\b(ufc|cricket|nba|nfl|premier\s+league)\s+(results|match|score)\b",
        r"\bwhat\s+happened\s+(today|yesterday|recently)\b",
        r"\bwhat\s+is\s+the\s+latest\b"
    ]

    PERSONAL_PATTERNS = [
        r"\b(i\s+feel|feeling|workout|exercise|sad|happy|stressed|study|routine|tomorrow|girlfriend|boyfriend|idea|remind)\b",
        r"\b(help\b.*?\bplan|write\b.*?\bmessage|how\s+can\s+i\s+improve)\b",
        r"\bwhat\s+should\s+i\s+(do|eat|wear|say)\b"
    ]

    @classmethod
    def classify(cls, text: str) -> str:
        """
        Classifies query into target engine:
        1. 'tool' -> Local Tool Executor
        2. 'online' -> Online Web Agent
        3. 'local_qwen' -> Local Qwen 2.5 7B Q4_K_M
        """
        text_lower = text.lower().strip()

        # Priority 1: System / Tool Commands
        if LocalToolExecutor.is_tool_command(text_lower):
            logger.info(f"[Smart Router] Route: 'tool' for command '{text}'")
            return "tool"

        # Priority 2: Check for explicit Personal / Assistant patterns
        for p in cls.PERSONAL_PATTERNS:
            if re.search(p, text_lower):
                logger.info(f"[Smart Router] Route: 'local_qwen' (Personal/Assistant pattern matched) for query '{text}'")
                return "local_qwen"

        # Priority 3: Factual / Current / Real-time Web Queries
        for p in cls.FACTUAL_PATTERNS:
            if re.search(p, text_lower):
                logger.info(f"[Smart Router] Route: 'online' (Factual/Current pattern matched) for query '{text}'")
                return "online"

        # Priority 4: Default -> Local Qwen 2.5 7B Q4_K_M
        logger.info(f"[Smart Router] Route: 'local_qwen' (General query default) for query '{text}'")
        return "local_qwen"
