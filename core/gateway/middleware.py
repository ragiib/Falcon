"""
Middleware to wrap requests and responses.
"""
import time
from typing import Dict, Any, Callable
from utils.logger import get_logger
from core.gateway.schemas import GatewayResponse

logger = get_logger("gateway.middleware")

class LoggingMiddleware:
    """Middleware to log request execution times and outcomes."""
    
    @staticmethod
    def process(raw_request: Dict[str, Any], next_handler: Callable[[Dict[str, Any]], GatewayResponse]) -> GatewayResponse:
        """
        Wraps the request handling with logging.
        """
        request_id = raw_request.get("request_id", "unknown_request")
        logger.info(f"Received request: {request_id}")
        start_time = time.time()
        
        try:
            response = next_handler(raw_request)
            execution_time = time.time() - start_time
            if response.status == "success":
                logger.info(f"Request {request_id} processed successfully in {execution_time:.3f}s")
            else:
                logger.warning(f"Request {request_id} processed with errors in {execution_time:.3f}s: {response.errors}")
            return response
        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(f"Unexpected error processing request {request_id} after {execution_time:.3f}s: {str(e)}")
            raise
