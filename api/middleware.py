"""
Middlewares for the API Layer (Logging, Timing, Error Handling).
"""
import time
import uuid
from typing import Callable
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from utils.logger import get_logger
from api.exceptions import APIError

logger = get_logger("api.middleware")

class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response

class RequestTimingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        start_time = time.time()
        response = await call_next(request)
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time)
        return response

class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        request_id = getattr(request.state, "request_id", "unknown")
        
        # Log request start
        logger.info(f"Request started: {request.method} {request.url.path} (ID: {request_id})")
        
        start_time = time.time()
        try:
            response = await call_next(request)
            process_time = (time.time() - start_time) * 1000
            
            logger.info(
                f"Request completed: {request.method} {request.url.path} "
                f"- Status: {response.status_code} "
                f"- Time: {process_time:.2f}ms "
                f"(ID: {request_id})"
            )
            return response
        except Exception as e:
            process_time = (time.time() - start_time) * 1000
            logger.error(
                f"Request failed: {request.method} {request.url.path} "
                f"- Error: {str(e)} "
                f"- Time: {process_time:.2f}ms "
                f"(ID: {request_id})",
                exc_info=True
            )
            raise e

async def custom_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Centralized exception handler to prevent tracebacks in API responses."""
    request_id = getattr(request.state, "request_id", "unknown")
    
    if isinstance(exc, APIError):
        status_code = exc.status_code
        error_payload = {
            "code": exc.code,
            "message": exc.message,
            "details": exc.details
        }
    else:
        # Generic unhandled exception fallback
        status_code = 500
        error_payload = {
            "code": "internal_server_error",
            "message": "An unexpected error occurred.",
            "details": None
        }
    
    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "request_id": request_id,
            "error": error_payload
        }
    )
