"""
Intent Router for Falcon V2 Core Intelligence Architecture.
Classifies user queries into TOOL, WEB_SEARCH, or PERSONAL_AI.
"""
import re
from core.tools.executor import LocalToolExecutor
from utils.logger import get_logger

logger = get_logger("router.intent")

class IntentRouter:
    """Classifies user input into predefined subsystems: TOOL, WEB_SEARCH, or PERSONAL_AI."""

    WEB_SEARCH_PATTERNS = [
        r"\b(latest|recent|current)\s+(news|weather|price|rate|score|results|event|updates|version|model)\b",
        r"\b(who\s+won|yesterday['\s]*s|today['\s]*s)\b",
        r"\b(price\s+of|bitcoin|crypto|stock|weather|score)\b",
        r"\b(ufc|cricket|nba|nfl|premier\s+league)\s+(results|match|score)\b",
        r"\bwhat\s+happened\s+(today|yesterday|recently)\b",
        r"\bwhat\s+is\s+the\s+latest\b",
        r"\b(what|how|who|where)\s+is\s+the\s+current\b"
    ]

    PERSONAL_AI_PATTERNS = [
        r"\b(remember|interview|schedule|routine|feel|feeling|workout|study|plan|code|python|algorithm|explain|how\s+does|write\s+a\s+function|debug)\b",
        r"\b(help\s+me|write\s+code|explain\s+recursion|binary\s+search|architecture|design)\b",
        r"\bwhat\s+do\s+you\s+think\b",
        r"\bcontinue\s+our\s+conversation\b"
    ]

    @classmethod
    def classify(cls, text: str) -> str:
        """
        Classifies query into target subsystem:
        1. 'TOOL' -> Modular Tool Manager (Highest priority)
        2. 'WEB_SEARCH' -> Web Agent (Current/real-time web queries)
        3. 'PERSONAL_AI' -> Personal AI (Conversational, reasoning, coding, memory)
        """
        logger.info("ENTER: routeIntent()")
        text_lower = text.lower().strip()

        # Engine 1: Tool Manager (Highest Priority — Desktop Actions)
        if LocalToolExecutor.is_tool_command(text_lower):
            logger.info(f"[Intent] Intent detected: TOOL for query: '{text}'")
            logger.info("EXIT: routeIntent()")
            return "TOOL"

        # Engine 3: Web Agent (Factual / Current Internet Queries)
        for pattern in cls.WEB_SEARCH_PATTERNS:
            if re.search(pattern, text_lower):
                logger.info(f"[Intent] Intent detected: WEB_SEARCH for query: '{text}'")
                logger.info("EXIT: routeIntent()")
                return "WEB_SEARCH"

        # Engine 2: Personal AI (Reasoning, Coding, Memory, Chat)
        logger.info(f"[Intent] Intent detected: PERSONAL_AI for query: '{text}'")
        logger.info("EXIT: routeIntent()")
        return "PERSONAL_AI"
