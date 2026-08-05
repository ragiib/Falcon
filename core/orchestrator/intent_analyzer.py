"""
Lightweight intent analyzer using rule-based logic.
"""
from core.orchestrator.schemas import OrchestratorContext
from utils.logger import get_logger

logger = get_logger("orchestrator.intent_analyzer")

class IntentAnalyzer:
    """Classifies requests into categories using simple heuristics."""
    
    @staticmethod
    def analyze(context: OrchestratorContext) -> OrchestratorContext:
        """Determines the intent of the message and updates the context."""
        msg = context.request.message.lower()
        
        if any(word in msg for word in ["code", "function", "debug", "bug", "python"]):
            intent = "coding"
        elif any(word in msg for word in ["summarize", "tl;dr", "shorten"]):
            intent = "summarization"
        elif any(word in msg for word in ["translate", "spanish", "french", "german"]):
            intent = "translation"
        elif any(word in msg for word in ["what", "how", "why", "who", "when"]):
            intent = "question_answering"
        elif any(word in msg for word in ["hi", "hello", "hey", "greetings"]):
            intent = "chat"
        else:
            intent = "unknown"
            
        logger.info(f"Detected intent '{intent}' for request {context.request.request_id}")
        context.intent = intent
        return context
