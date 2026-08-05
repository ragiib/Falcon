"""
Session routing for managing chat sessions.
"""
from fastapi import APIRouter, Depends, Path
from api.schemas import (
    APIResponse,
    SessionCreateResponseData,
    SessionStatusResponseData,
    SessionDeleteResponseData
)
from api.dependencies import get_request_id
from api.exceptions import SessionNotFoundError
from core.intelligence.session import SessionManager

router = APIRouter(prefix="/session", tags=["Session"])

@router.post("", response_model=APIResponse)
async def create_session(request_id: str = Depends(get_request_id)):
    """Creates a new session and returns its ID."""
    session_id = SessionManager.create_session()
    
    return APIResponse(
        success=True,
        request_id=request_id,
        data=SessionCreateResponseData(session_id=session_id)
    )

@router.get("/{session_id}", response_model=APIResponse)
async def get_session(
    session_id: str = Path(..., description="The session ID to retrieve"),
    request_id: str = Depends(get_request_id)
):
    """Retrieves metadata and status of an existing session."""
    session_data = SessionManager._sessions.get(session_id)
    if not session_data:
        raise SessionNotFoundError(session_id)
        
    return APIResponse(
        success=True,
        request_id=request_id,
        data=SessionStatusResponseData(
            session_id=session_id,
            last_active=session_data["last_active"],
            created_at=session_data["created_at"]
        )
    )

@router.delete("/{session_id}", response_model=APIResponse)
async def delete_session(
    session_id: str = Path(..., description="The session ID to delete"),
    request_id: str = Depends(get_request_id)
):
    """Deletes an active session."""
    if session_id in SessionManager._sessions:
        del SessionManager._sessions[session_id]
        deleted = True
    else:
        # We can either return success=True and deleted=False, or raise NotFound.
        # Idempotent deletion typically returns success.
        deleted = False
        
    return APIResponse(
        success=True,
        request_id=request_id,
        data=SessionDeleteResponseData(
            session_id=session_id,
            deleted=deleted
        )
    )
