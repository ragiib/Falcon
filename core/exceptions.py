"""
Custom exception and error-handling system.
"""

class AIServiceError(Exception):
    """Base exception for all AI Service errors."""
    def __init__(self, message: str, original_error: Exception = None):
        super().__init__(message)
        self.message = message
        self.original_error = original_error

class ConfigurationError(AIServiceError):
    """Raised when there is a configuration issue."""
    pass

class ModelExecutionError(AIServiceError):
    """Raised when an AI model fails to execute properly."""
    pass

class ToolExecutionError(AIServiceError):
    """Raised when a tool execution fails."""
    pass
