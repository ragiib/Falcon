"""
Metrics routing for checking usage and runtime statistics.
"""
import time
import psutil
from fastapi import APIRouter, Depends
from api.schemas import APIResponse, MetricsResponseData
from api.dependencies import get_request_id
from api.routes.health import START_TIME
from core.intelligence.session import SessionManager
from config import settings

router = APIRouter(prefix="/metrics", tags=["Metrics"])

@router.get("", response_model=APIResponse)
async def get_metrics(
    request_id: str = Depends(get_request_id)
):
    """Retrieves operational metrics (sessions, memory usage, uptime, active model configs)."""
    
    uptime_seconds = time.time() - START_TIME
    active_sessions = len(SessionManager._sessions)
    
    # System RAM usage
    ram_usage_mb = psutil.Process().memory_info().rss / (1024 * 1024)
    
    # VRAM (Optional/Hard to get without nvidia-smi bindings, leaving as None for now unless implemented in provider)
    vram_usage_mb = None
    
    return APIResponse(
        success=True,
        request_id=request_id,
        data=MetricsResponseData(
            model=settings.MODEL_PATH.split("\\")[-1].split("/")[-1], # Extract basic name
            provider=settings.MODEL_PROVIDER,
            gpu_layers=settings.MODEL_GPU_LAYERS,
            active_sessions=active_sessions,
            uptime_seconds=uptime_seconds,
            ram_usage_mb=ram_usage_mb,
            vram_usage_mb=vram_usage_mb
        )
    )
