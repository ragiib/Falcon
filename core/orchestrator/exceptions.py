"""
Orchestrator specific exceptions.
"""
from core.exceptions import AIServiceError

class OrchestrationError(AIServiceError):
    """Raised when the orchestrator fails to process a request."""
    pass
    
class IntentAnalysisError(OrchestrationError):
    """Raised when intent analysis fails."""
    pass
