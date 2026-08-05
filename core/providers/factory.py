"""
Factory for loading and managing the Model Provider singleton.
"""
from typing import Optional
from interfaces.base import IModelProvider
from config import settings
from utils.logger import get_logger

logger = get_logger("providers.factory")

class ProviderFactory:
    """Manages initialization and retrieval of the configured Model Provider."""
    
    _instance: Optional[IModelProvider] = None
    
    @classmethod
    def get_provider(cls) -> IModelProvider:
        """Returns the loaded provider, initializing it if necessary."""
        if cls._instance is None:
            cls.initialize()
        return cls._instance
        
    @classmethod
    def initialize(cls) -> None:
        """Initializes the provider based on configuration and loads the model."""
        provider_name = settings.MODEL_PROVIDER.lower()
        logger.info(f"Initializing model provider: {provider_name}")
        
        if provider_name == "qwen":
            from core.providers.qwen_provider import QwenProvider
            cls._instance = QwenProvider()
        elif provider_name == "placeholder":
            from core.providers.placeholder_provider import PlaceholderProvider
            cls._instance = PlaceholderProvider()
        else:
            logger.warning(f"Unknown provider '{provider_name}'. Falling back to PlaceholderProvider.")
            from core.providers.placeholder_provider import PlaceholderProvider
            cls._instance = PlaceholderProvider()
            
        # Model is purposefully NOT loaded here to support lazy loading.
        logger.info(f"Provider {provider_name} initialized. Model will load lazily on first request.")
