"""
Schemas for the AI Orchestrator.
"""
from dataclasses import dataclass, field
from typing import Dict, Any, Optional
from core.gateway.schemas import GatewayRequest

@dataclass
class OrchestratorContext:
    """The context built and passed through the orchestration pipeline."""
    request: GatewayRequest
    intent: str = "unknown"
    session_info: Dict[str, Any] = field(default_factory=dict)
    model_response: Optional[str] = None
    usage: Dict[str, int] = field(default_factory=dict)
