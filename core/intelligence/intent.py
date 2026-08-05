"""
Intent Detector for the Intelligence Layer.
"""
from core.intelligence.schemas import IntelligenceContext
from utils.logger import get_logger

logger = get_logger("intelligence.intent")

class IntentDetector:
    """Classifies user input into predefined intents."""
    
    @staticmethod
    def detect(context: IntelligenceContext) -> IntelligenceContext:
        """Determines the intent of the message."""
        msg = context.user_input.lower()
        
        # Rule-based intent classification
        if any(word in msg for word in ["code", "function", "debug", "bug", "python", "javascript", "script"]):
            intent = "coding"
        elif any(word in msg for word in ["plan", "architecture", "design", "structure"]):
            intent = "planning"
        elif any(word in msg for word in ["summarize", "tl;dr", "shorten", "brief"]):
            intent = "summarization"
        elif any(word in msg for word in ["translate", "spanish", "french", "german"]):
            intent = "translation"
        elif any(word in msg for word in ["what", "how", "why", "who", "when", "where", "explain"]):
            intent = "question_answering"
        elif msg in ["hi", "hello", "hey", "greetings", "good morning", "good evening"]:
            intent = "chat"
        else:
            intent = "general"
            
        logger.info(f"Detected intent '{intent}' for session {context.session_id}")
        context.intent = intent
        return context
