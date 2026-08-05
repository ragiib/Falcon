"""
Centralized configuration and constants for the AI services.
"""
import os
import logging
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Application constants
APP_NAME = os.getenv("APP_NAME", "falcon_ai_services")
APP_ENV = os.getenv("APP_ENV", "development")

# Logging configuration
LOG_LEVEL_STR = os.getenv("LOG_LEVEL", "INFO").upper()
# Safely get the log level, defaulting to INFO
LOG_LEVEL = getattr(logging, LOG_LEVEL_STR, logging.INFO)

# Model Provider Configuration
MODEL_PROVIDER = os.getenv("MODEL_PROVIDER", "placeholder") # Options: "qwen", "placeholder"

# Qwen specific configuration
MODEL_PATH = os.getenv("MODEL_PATH", "/path/to/models/Qwen2.5-14B-Q4_K_M.gguf")
MODEL_TEMPERATURE = float(os.getenv("MODEL_TEMPERATURE", "0.7"))
MODEL_MAX_TOKENS = int(os.getenv("MODEL_MAX_TOKENS", "2048"))
MODEL_TOP_P = float(os.getenv("MODEL_TOP_P", "0.9"))
MODEL_CONTEXT_LENGTH = int(os.getenv("MODEL_CONTEXT_LENGTH", "4096"))
MODEL_GPU_LAYERS = int(os.getenv("MODEL_GPU_LAYERS", "32"))
MODEL_REPEAT_PENALTY = float(os.getenv("MODEL_REPEAT_PENALTY", "1.1"))

# Intelligence Layer Configuration
DEFAULT_RESPONSE_PROFILE = os.getenv("DEFAULT_RESPONSE_PROFILE", "normal")
ENABLE_DYNAMIC_RESPONSE = os.getenv("ENABLE_DYNAMIC_RESPONSE", "true").lower() == "true"
ENABLE_CONTEXT_MANAGER = os.getenv("ENABLE_CONTEXT_MANAGER", "true").lower() == "true"
ENABLE_HALLUCINATION_GUARD = os.getenv("ENABLE_HALLUCINATION_GUARD", "true").lower() == "true"
ENABLE_SESSION_MANAGER = os.getenv("ENABLE_SESSION_MANAGER", "true").lower() == "true"
ENABLE_PROMPT_VALIDATOR = os.getenv("ENABLE_PROMPT_VALIDATOR", "true").lower() == "true"
MAX_CONVERSATION_HISTORY = int(os.getenv("MAX_CONVERSATION_HISTORY", "10"))
SESSION_TIMEOUT = int(os.getenv("SESSION_TIMEOUT", "3600"))

# API Configuration
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8000"))
API_DEBUG = os.getenv("API_DEBUG", "true").lower() == "true"
ENABLE_CORS = os.getenv("ENABLE_CORS", "true").lower() == "true"
CORS_ALLOWED_ORIGINS = os.getenv("CORS_ALLOWED_ORIGINS", "*")
MAX_REQUEST_SIZE = int(os.getenv("MAX_REQUEST_SIZE", "10485760"))
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "60"))
ENABLE_STREAMING = os.getenv("ENABLE_STREAMING", "true").lower() == "true"
