"""
Health routing for checking system status.
"""
import time
from fastapi import APIRouter, Depends
from api.schemas import APIResponse, HealthResponseData
from api.dependencies import get_request_id, get_provider_factory
from core.providers.factory import ProviderFactory
from config import settings

router = APIRouter(prefix="/health", tags=["Health"])

START_TIME = time.time()

@router.get("", response_model=APIResponse)
async def check_health(
    request_id: str = Depends(get_request_id)
):
    """Checks the health and status of the API, Model Provider, and Intelligence Layer."""
    
    # Calculate uptime
    uptime_seconds = time.time() - START_TIME
    
    # Provider Info
    provider = "unknown"
    cuda_available = False
    status = "healthy"
    
    try:
        provider_name = settings.MODEL_PROVIDER.lower()
        if provider_name == "qwen":
            from core.providers.qwen_provider import QwenProvider
            # Just inspecting class properties safely
            provider = "qwen"
            cuda_available = QwenProvider._has_cuda()
        elif provider_name == "placeholder":
            provider = "placeholder"
    except Exception as e:
        status = "degraded"
        provider = f"error: {str(e)}"
        
    return APIResponse(
        success=True,
        request_id=request_id,
        data=HealthResponseData(
            status=status,
            uptime_seconds=uptime_seconds,
            provider=provider,
            cuda_available=cuda_available
        )
    )
