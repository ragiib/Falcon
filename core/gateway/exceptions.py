"""
Gateway specific exceptions.
"""
from core.exceptions import AIServiceError

class GatewayValidationError(AIServiceError):
    """Raised when a request fails validation."""
    def __init__(self, message: str, errors: list = None):
        super().__init__(message)
        self.errors = errors or []

class GatewayProcessingError(AIServiceError):
    """Raised when the gateway fails to process a request."""
    pass
