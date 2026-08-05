"""
Context builder for assembling required data before model execution.
"""
from core.gateway.schemas import GatewayRequest
from core.orchestrator.schemas import OrchestratorContext
from utils.logger import get_logger

logger = get_logger("orchestrator.context_builder")

class ContextBuilder:
    """Assembles the execution context for a request."""
    
    @staticmethod
    def build(request: GatewayRequest) -> OrchestratorContext:
        """Creates the initial orchestrator context."""
        logger.info(f"Building context for request {request.request_id}")
        
        # Placeholder for session logic (e.g., retrieving previous messages)
        session_info = {
            "session_id": request.session_id,
            "user_id": request.user_id,
            "history": [] # No memory retrieval yet
        }
        
        return OrchestratorContext(
            request=request,
            session_info=session_info
        )
