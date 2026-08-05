"""
WebSocket placeholder for future Voice mode.
"""
from fastapi import APIRouter, WebSocket, HTTPException

router = APIRouter(prefix="/ws", tags=["WebSocket"])

@router.websocket("")
async def websocket_endpoint(websocket: WebSocket):
    """
    Placeholder for future Voice Mode / WebSocket integration.
    Currently returns 501 Not Implemented.
    """
    await websocket.close(code=1011, reason="501 Not Implemented: Voice Mode not yet supported.")

@router.get("")
async def websocket_get():
    """
    Fallback GET endpoint for HTTP clients testing the route.
    """
    raise HTTPException(status_code=501, detail="Not Implemented")
