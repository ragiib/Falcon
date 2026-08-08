"""
Operating Mode routing for dynamic switching between Agent Mode and Offline AI Mode.
"""
from fastapi import APIRouter, Depends
from api.schemas import APIResponse, ModeRequest, ModeResponseData
from api.dependencies import get_request_id
from core.providers.factory import ProviderFactory

router = APIRouter(prefix="/mode", tags=["Operating Mode"])

@router.get("", response_model=APIResponse)
async def get_mode(
    request_id: str = Depends(get_request_id)
):
    """Returns the current operating mode and Qwen model status."""
    provider = ProviderFactory.get_provider()
    info = provider.get_mode_info()
    return APIResponse(
        success=True,
        request_id=request_id,
        data=ModeResponseData(
            mode=info["mode"],
            status=info["status"],
            qwen_loaded=info["qwen_loaded"],
            internet_available=info["internet_available"]
        )
    )

@router.post("", response_model=APIResponse)
async def set_mode(
    request: ModeRequest,
    request_id: str = Depends(get_request_id)
):
    """
    Switches operating mode dynamically.
    - 'agent': Unloads Qwen, frees memory, returns to lightweight Agent Mode.
    - 'offline_ai': Loads Qwen 2.5 7B model into memory.
    """
    provider = ProviderFactory.get_provider()
    info = provider.set_operating_mode(request.mode)
    return APIResponse(
        success=True,
        request_id=request_id,
        data=ModeResponseData(
            mode=info["mode"],
            status=info["status"],
            qwen_loaded=info["qwen_loaded"],
            internet_available=info["internet_available"]
        )
    )
