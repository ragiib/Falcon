"""
Conversation Engine for coordinating the Intelligence Layer pipeline.
"""
from typing import Generator, Any
from core.intelligence.schemas import IntelligenceContext
from core.intelligence.session import SessionManager
from core.intelligence.intent import IntentDetector
from core.intelligence.controller import ResponseController
from core.intelligence.context import ContextManager
from core.intelligence.prompt import PromptManager
from core.intelligence.validator import PromptValidator
from core.providers import ProviderFactory
from utils.logger import get_logger

logger = get_logger("intelligence.engine")

class ConversationEngine:
    """Coordinates the AI Intelligence pipeline."""
    
    @staticmethod
    def chat_stream(session_id: str, user_input: str, metrics_out: dict = None) -> Generator[str, None, None]:
        """Processes the request and yields streamed tokens. Populates metrics_out if provided."""
        
        # 1. Session Manager
        session_id = SessionManager.get_or_create(session_id)
        
        # Initialize Context
        context = IntelligenceContext(session_id=session_id, user_input=user_input)
        
        # 2. Intent Detector
        context = IntentDetector.detect(context)
        
        # 3. Dynamic Response Controller
        context = ResponseController.process(context)
        
        # 4. Context Manager
        context = ContextManager.process(context)
        
        # 5. System Prompt Manager
        context = PromptManager.process(context)
        
        # 6. Prompt Validator
        context = PromptValidator.process(context)
        
        # Populate metrics_out early so caller can see intent/profile before stream finishes
        if metrics_out is not None:
            metrics_out["intent"] = context.intent
            metrics_out["profile"] = context.response_profile.profile_name if context.response_profile else "none"
            metrics_out["session_id"] = session_id
            
        # 7. AI Orchestrator / Provider Dispatch
        provider = ProviderFactory.get_provider()
        
        # Prepare kwargs for the provider
        kwargs = {}
        if context.response_profile:
            kwargs["max_tokens"] = context.response_profile.max_tokens
            
        logger.info(f"Dispatching to provider for session {session_id}")
        
        # Stream response
        full_response = ""
        for chunk in provider.generate_stream(context.structured_prompt, **kwargs):
            full_response += chunk
            yield chunk
            
        # Update context history with the completed interaction
        ContextManager.add_interaction(session_id, user_input, full_response)
