"""
Routes requests to the appropriate component based on intent.
"""
from core.orchestrator.schemas import OrchestratorContext
from core.providers import ProviderFactory
from utils.logger import get_logger

logger = get_logger("orchestrator.dispatcher")

class Dispatcher:
    """Selects the next processing component."""
    
    @staticmethod
    def dispatch(context: OrchestratorContext) -> OrchestratorContext:
        """Routes to the model provider."""
        logger.info(f"Dispatching request {context.request.request_id} with intent '{context.intent}'")
        
        provider = ProviderFactory.get_provider()
        
        # In the future, the prompt for generation will be built dynamically. 
        # For now, we just pass the user message.
        prompt = context.request.message
        
        try:
            response = provider.generate(prompt, intent=context.intent)
            context.model_response = response.get("reply")
            context.usage = response.get("usage", {})
        except Exception as e:
            logger.error(f"Error during dispatch generation: {str(e)}")
            raise
            
        return context
