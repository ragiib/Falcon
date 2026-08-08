"""
Wake word activation routing and status sync with Falcon Wake Listener background service.
"""
import socket
import json
from fastapi import APIRouter, Depends
from api.schemas import APIResponse, WakeEventRequest, WakeResponseData
from api.dependencies import get_request_id
from utils.logger import get_logger

logger = get_logger("api.routes.wake")

router = APIRouter(prefix="/wake", tags=["WakeWord"])

IPC_HOST = "127.0.0.1"
IPC_PORT = 8009

def send_ipc_command(command: str) -> bool:
    """Sends IPC command to falcon_wake_listener.py over local TCP socket."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1.0)
        s.connect((IPC_HOST, IPC_PORT))
        msg = (json.dumps({"command": command}) + "\n").encode('utf-8')
        s.sendall(msg)
        s.close()
        return True
    except Exception as e:
        logger.debug(f"IPC command send failed ({command}): {e}")
        return False

@router.post("/trigger", response_model=APIResponse)
async def trigger_wake(
    req: WakeEventRequest,
    request_id: str = Depends(get_request_id)
):
    """Triggered when 'Falcon wake up' is detected by the background listener service."""
    logger.info(f"[WAKE API] Wake event received: '{req.phrase}' from source '{req.source}'")
    
    # Notify background listener to pause mic for handoff
    send_ipc_command("MIC_PAUSE")

    return APIResponse(
        success=True,
        request_id=request_id,
        data=WakeResponseData(
            status="ACTIVATED",
            action="wake_word_handshake_complete"
        )
    )

@router.post("/standby", response_model=APIResponse)
async def enter_standby(
    request_id: str = Depends(get_request_id)
):
    """Notifies background listener service that assistant has returned to STANDBY mode."""
    logger.info("[WAKE API] Assistant returned to STANDBY. Notifying wake listener to resume microphone.")
    
    # Notify background listener to resume standby mic stream
    send_ipc_command("MIC_RESUME")

    return APIResponse(
        success=True,
        request_id=request_id,
        data=WakeResponseData(
            status="STANDBY",
            action="mic_resumed"
        )
    )
