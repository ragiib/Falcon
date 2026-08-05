"""
Modular pipeline for request processing.
"""
from core.gateway.schemas import GatewayRequest
from core.orchestrator.schemas import OrchestratorContext
from core.orchestrator.context_builder import ContextBuilder
from core.orchestrator.intent_analyzer import IntentAnalyzer
from core.orchestrator.dispatcher import Dispatcher
from utils.logger import get_logger
import time

logger = get_logger("orchestrator.pipeline")

class OrchestratorPipeline:
    """Executes stages sequentially."""
    
    @staticmethod
    def execute(request: GatewayRequest) -> OrchestratorContext:
        """Runs the request through the orchestration pipeline."""
        start_time = time.time()
        logger.info(f"Starting pipeline for request {request.request_id}")
        
        try:
            # Stage 1: Build Context
            context = ContextBuilder.build(request)
            
            # Stage 2: Analyze Intent
            context = IntentAnalyzer.analyze(context)
            
            # Stage 3: Dispatch & Execute
            context = Dispatcher.dispatch(context)
            
            execution_time = time.time() - start_time
            logger.info(f"Pipeline completed successfully in {execution_time:.3f}s")
            
            return context
            
        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(f"Pipeline failed after {execution_time:.3f}s: {str(e)}")
            raise
