"""
Pydantic schemas for request and response validation.
"""
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field

# -----------------------------------------------------------------------------
# Generic Response Envelopes
# -----------------------------------------------------------------------------
class APIErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[Dict[str, Any]] = None

class APIResponse(BaseModel):
    success: bool
    request_id: str
    data: Optional[Any] = None
    error: Optional[APIErrorDetail] = None

# -----------------------------------------------------------------------------
# Chat Schemas
# -----------------------------------------------------------------------------
class ChatRequest(BaseModel):
    session_id: str = Field(..., description="Unique session identifier for the conversation")
    message: str = Field(..., min_length=1, description="The user's input message")

class ChatResponseData(BaseModel):
    response: str
    intent: str
    profile: str
    session_id: str

# -----------------------------------------------------------------------------
# Session Schemas
# -----------------------------------------------------------------------------
class SessionCreateResponseData(BaseModel):
    session_id: str

class SessionStatusResponseData(BaseModel):
    session_id: str
    last_active: float
    created_at: float

class SessionDeleteResponseData(BaseModel):
    session_id: str
    deleted: bool

# -----------------------------------------------------------------------------
# Operating Mode Schemas
# -----------------------------------------------------------------------------
class ModeRequest(BaseModel):
    mode: str = Field(..., description="Target operating mode: 'agent' or 'offline_ai'")

class ModeResponseData(BaseModel):
    mode: str
    status: str
    qwen_loaded: bool
    internet_available: bool

class HealthResponseData(BaseModel):
    status: str
    uptime_seconds: float
    provider: str
    cuda_available: bool

class MetricsResponseData(BaseModel):
    model: str
    provider: str
    gpu_layers: int
    active_sessions: int
    uptime_seconds: float
    # Memory stats placeholders
    ram_usage_mb: Optional[float] = None
    vram_usage_mb: Optional[float] = None

# -----------------------------------------------------------------------------
# Wake Word & IPC Schemas
# -----------------------------------------------------------------------------
class WakeEventRequest(BaseModel):
    phrase: str = Field(default="falcon wake up", description="The detected wake phrase")
    source: str = Field(default="wake_listener", description="Source component")
    timestamp: Optional[int] = None

class WakeResponseData(BaseModel):
    status: str
    action: str

