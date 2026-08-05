"""
Context Manager for maintaining short-term conversational history.
"""
from typing import List, Dict
from config import settings
from core.intelligence.schemas import IntelligenceContext
from utils.logger import get_logger

logger = get_logger("intelligence.context")

class ContextManager:
    """Manages conversational history limits."""
    
    _history: Dict[str, List[Dict[str, str]]] = {}
    
    @classmethod
    def get_history(cls, session_id: str) -> List[Dict[str, str]]:
        """Retrieves history for a session."""
        if not settings.ENABLE_CONTEXT_MANAGER:
            return []
        return cls._history.get(session_id, [])
        
    @classmethod
    def add_interaction(cls, session_id: str, user_msg: str, assistant_msg: str) -> None:
        """Appends a completed interaction to the history and trims excess."""
        if not settings.ENABLE_CONTEXT_MANAGER:
            return
            
        if session_id not in cls._history:
            cls._history[session_id] = []
            
        cls._history[session_id].append({"role": "user", "content": user_msg})
        cls._history[session_id].append({"role": "assistant", "content": assistant_msg})
        
        # Trim history if it exceeds the limit (times 2 because a turn is 2 messages)
        limit = settings.MAX_CONVERSATION_HISTORY * 2
        if len(cls._history[session_id]) > limit:
            cls._history[session_id] = cls._history[session_id][-limit:]
            logger.debug(f"Trimmed context history for session {session_id}")

    @staticmethod
    def process(context: IntelligenceContext) -> IntelligenceContext:
        """Loads conversation history into the current context."""
        context.conversation_history = ContextManager.get_history(context.session_id)
        return context
