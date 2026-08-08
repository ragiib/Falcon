"""
Chat routing for standard and streaming conversation.
"""
import json
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from api.schemas import APIResponse, ChatRequest, ChatResponseData
from api.dependencies import get_request_id
from core.intelligence.engine import ConversationEngine
from core.intelligence.session import SessionManager
from api.exceptions import SessionNotFoundError

router = APIRouter(prefix="/chat", tags=["Chat"])

@router.post("", response_model=APIResponse)
async def chat_sync(
    request: ChatRequest,
    request_id: str = Depends(get_request_id)
):
    """
    Synchronous chat endpoint.
    Wait for the full response and return it.
    """
    if request.session_id not in SessionManager._sessions:
        raise SessionNotFoundError(request.session_id)
        
    metrics_out = {}
    
    # Engine is a generator, so we join all chunks
    # This might block if not run in a threadpool depending on provider implementation
    # But QwenProvider handles it synchronously anyway when yielded.
    # To truly avoid blocking the event loop for sync endpoints, we could use `asyncio.to_thread`
    # but the generator needs to be iterated. Doing it simply for now.
    
    full_response = ""
    for chunk in ConversationEngine.chat_stream(request.session_id, request.message, metrics_out):
        full_response += chunk
        
    return APIResponse(
        success=True,
        request_id=request_id,
        data=ChatResponseData(
            response=full_response,
            intent=metrics_out.get("intent", "unknown"),
            profile=metrics_out.get("profile", "none"),
            session_id=metrics_out.get("session_id", request.session_id)
        )
    )

@router.post("/stream")
async def chat_stream(
    request: ChatRequest,
    request_id: str = Depends(get_request_id)
):
    """
    Streaming chat endpoint.
    Returns Server-Sent Events (SSE).
    """
    # Auto-create session if not present to ensure seamless streaming
    session_id = SessionManager.get_or_create(request.session_id)
    
    def generate():
        metrics_out = {}
        generator = ConversationEngine.chat_stream(session_id, request.message, metrics_out)
        
        for chunk in generator:
            # Yield SSE format: data: {"token": "..."}\n\n
            payload = json.dumps({"token": chunk})
            yield f"data: {payload}\n\n"
            
        # Yield done signal
        payload = json.dumps({"done": True, "metadata": metrics_out})
        yield f"data: {payload}\n\n"
        
    return StreamingResponse(generate(), media_type="text/event-stream")
