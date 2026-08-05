"""
Standard request and response schemas for the AI Gateway.
"""
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional
from datetime import datetime

@dataclass
class GatewayRequest:
    """Standardized request schema for the AI Gateway."""
    request_id: str
    session_id: str
    user_id: str
    message: str
    attachments: List[Dict[str, Any]] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.utcnow)

@dataclass
class GatewayResponse:
    """Standardized response schema for the AI Gateway."""
    status: str
    request_id: str
    reply: Optional[str] = None
    actions: List[Dict[str, Any]] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    usage: Dict[str, int] = field(default_factory=dict)
    errors: List[str] = field(default_factory=list)
