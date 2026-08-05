"""
Response building utilities to ensure standardized responses.
"""
from core.gateway.schemas import GatewayResponse

class ResponseBuilder:
    """Utility to build standard GatewayResponses."""
    
    @staticmethod
    def success(request_id: str, reply: str, actions: list = None, metadata: dict = None, usage: dict = None) -> GatewayResponse:
        """Builds a successful response."""
        return GatewayResponse(
            status="success",
            request_id=request_id,
            reply=reply,
            actions=actions or [],
            metadata=metadata or {},
            usage=usage or {}
        )
        
    @staticmethod
    def error(request_id: str, errors: list, metadata: dict = None) -> GatewayResponse:
        """Builds an error response."""
        return GatewayResponse(
            status="error",
            request_id=request_id,
            errors=errors,
            metadata=metadata or {}
        )
