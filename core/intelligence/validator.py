"""
Prompt Validator for ensuring prompt structure integrity.
"""
from core.intelligence.schemas import IntelligenceContext
from config import settings
from utils.logger import get_logger

logger = get_logger("intelligence.validator")

class PromptValidator:
    """Validates the structured prompt before dispatch."""
    
    @staticmethod
    def process(context: IntelligenceContext) -> IntelligenceContext:
        """Validates the structure of the generated prompt."""
        if not settings.ENABLE_PROMPT_VALIDATOR:
            return context
            
        prompt = context.structured_prompt
        
        if not isinstance(prompt, list):
            raise ValueError("Prompt must be a list of dictionaries.")
            
        if not prompt:
            raise ValueError("Prompt is empty.")
            
        has_system = False
        has_user = False
        
        for msg in prompt:
            if not isinstance(msg, dict):
                raise ValueError("Each message must be a dictionary.")
            if "role" not in msg or "content" not in msg:
                raise ValueError("Each message must contain 'role' and 'content' keys.")
            if msg["role"] == "system":
                has_system = True
            if msg["role"] == "user":
                has_user = True
                
        if not has_user:
            raise ValueError("Prompt must contain at least one 'user' message.")
            
        # In a real scenario, we might compress or summarize if it exceeds hard token limits
        
        logger.debug("Prompt validated successfully.")
        return context
