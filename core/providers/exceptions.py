"""
Model Provider specific exceptions.
"""
from core.exceptions import AIServiceError

class ProviderError(AIServiceError):
    """Base exception for provider errors."""
    pass
    
class ModelNotFoundError(ProviderError):
    """Raised when the requested model file or path cannot be found."""
    pass
    
class ModelLoadError(ProviderError):
    """Raised when the model fails to load into memory."""
    pass

class InferenceError(ProviderError):
    """Raised when model inference fails."""
    pass
