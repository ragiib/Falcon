"""
Schemas for the AI Intelligence Layer.
"""
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional

@dataclass
class ResponseProfile:
    """Structured response instructions and limits."""
    profile_name: str
    max_tokens: int
    style: str
    formatting: str
    verbosity: str
    output_format: str

@dataclass
class IntelligenceContext:
    """Internal context for the Intelligence pipeline."""
    session_id: str
    user_input: str
    intent: str = "unknown"
    response_profile: Optional[ResponseProfile] = None
    conversation_history: List[Dict[str, str]] = field(default_factory=list)
    structured_prompt: List[Dict[str, str]] = field(default_factory=list)
    metrics: Dict[str, Any] = field(default_factory=dict)
