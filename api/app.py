"""
API application instance and startup/shutdown events.
"""
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from config import settings
from utils.logger import get_logger

# Middleware
from api.middleware import (
    RequestIDMiddleware,
    RequestTimingMiddleware,
    RequestLoggingMiddleware,
    custom_exception_handler
)

# Exceptions
from api.exceptions import APIError

# Routes
from api.routes import chat, session, health, metrics, ws

# Core dependencies
from core.providers.factory import ProviderFactory
from core.intelligence.session import SessionManager

logger = get_logger("api.app")

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting up API server...")
    # Initialize the provider (lazily loads the model)
    ProviderFactory.initialize()
    logger.info("API server startup complete.")
    
    yield
    
    logger.info("Shutting down API server...")
    # Gracefully close sessions
    SessionManager._sessions.clear()
    
    # We leave Provider unloading to OS / Python GC as llama_cpp doesn't have explicit explicit unload
    # But we log it.
    logger.info("API server shutdown complete.")

def create_app() -> FastAPI:
    """Creates and configures the FastAPI application."""
    
    app = FastAPI(
        title="Falcon AI Services API",
        description="Backend API for the Falcon AI Platform",
        version="1.0.0",
        docs_url="/api/v1/docs",
        redoc_url="/api/v1/redoc",
        openapi_url="/api/v1/openapi.json",
        lifespan=lifespan
    )
    
    # 1. Custom Exception Handlers
    app.add_exception_handler(APIError, custom_exception_handler)
    
    # 2. CORS Middleware
    if settings.ENABLE_CORS:
        allow_origins = settings.CORS_ALLOWED_ORIGINS.split(",")
        app.add_middleware(
            CORSMiddleware,
            allow_origins=allow_origins,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
        
    # 3. Custom Middlewares (Order matters: innermost to outermost)
    app.add_middleware(RequestLoggingMiddleware)
    app.add_middleware(RequestTimingMiddleware)
    app.add_middleware(RequestIDMiddleware)
    
    # 4. Include Routers (Versioned)
    api_v1_prefix = "/api/v1"
    app.include_router(chat.router, prefix=api_v1_prefix)
    app.include_router(session.router, prefix=api_v1_prefix)
    app.include_router(health.router, prefix=api_v1_prefix)
    app.include_router(metrics.router, prefix=api_v1_prefix)
    app.include_router(ws.router, prefix=api_v1_prefix)
    
    return app

app = create_app()

if __name__ == "__main__":
    uvicorn.run(
        "api.app:app", 
        host=settings.API_HOST, 
        port=settings.API_PORT, 
        reload=settings.API_DEBUG
    )
