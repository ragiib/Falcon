"""
Base data models representing entities in the AI services.
"""
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional
from datetime import datetime

@dataclass
class Message:
    """Represents a single message in a conversation."""
    role: str
    content: str
    timestamp: datetime = field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class AgentResponse:
    """Represents a standardized response from an AI agent."""
    content: str
    model_name: str
    usage: Dict[str, int] = field(default_factory=dict)
    finish_reason: Optional[str] = None
