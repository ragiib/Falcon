"""
Custom exceptions for the API Layer.
"""
from typing import Any, Dict, Optional

class APIError(Exception):
    """Base exception for all API errors."""
    def __init__(self, message: str, code: str = "internal_error", status_code: int = 500, details: Optional[Dict[str, Any]] = None):
        super().__init__(message)
        self.message = message
        self.code = code
        self.status_code = status_code
        self.details = details or {}

class ValidationError(APIError):
    """Raised when request validation fails."""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            code="validation_error",
            status_code=400,
            details=details
        )

class SessionNotFoundError(APIError):
    """Raised when a session ID is invalid or expired."""
    def __init__(self, session_id: str):
        super().__init__(
            message=f"Session not found or expired: {session_id}",
            code="session_not_found",
            status_code=404,
            details={"session_id": session_id}
        )

class ProviderError(APIError):
    """Raised when the underlying AI provider fails."""
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            code="provider_error",
            status_code=502,
            details=details
        )
