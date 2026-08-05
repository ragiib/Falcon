"""
Main entry point for the AI Orchestrator.
"""
from core.gateway.schemas import GatewayRequest
from core.orchestrator.pipeline import OrchestratorPipeline

class AIOrchestrator:
    """Coordinates request processing through the pipeline."""
    
    @staticmethod
    def process(request: GatewayRequest) -> dict:
        """
        Receives a validated request, runs it through the pipeline, 
        and returns the results.
        """
        context = OrchestratorPipeline.execute(request)
        
        return {
            "reply": context.model_response,
            "usage": context.usage
        }
