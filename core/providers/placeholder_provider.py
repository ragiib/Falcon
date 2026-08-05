"""
Placeholder model provider for testing, CI, and fallback scenarios.
"""
from typing import Any, Dict
from interfaces.base import IModelProvider
from utils.logger import get_logger

logger = get_logger("providers.placeholder")

class PlaceholderProvider(IModelProvider):
    """A deterministic model provider replacement for testing the pipeline."""
    
    def __init__(self):
        self.is_loaded = False
        
    def load_model(self) -> None:
        logger.info("Loading PlaceholderProvider...")
        self.is_loaded = True
        
    def unload_model(self) -> None:
        logger.info("Unloading PlaceholderProvider...")
        self.is_loaded = False
        
    def health_check(self) -> Dict[str, Any]:
        return {
            "provider": "placeholder",
            "model_loaded": self.is_loaded,
            "model_path": "N/A",
            "inference_backend": "none",
            "status": "loaded" if self.is_loaded else "unloaded"
        }
        
    def generate(self, prompt: str, **kwargs) -> Any:
        if not self.is_loaded:
            self.load_model()
            
        logger.info(f"Generating response using PlaceholderProvider.")
        import time
        start_time = time.time()
        
        # We assume intent is passed in kwargs for the placeholder echo test
        intent = kwargs.get("intent", "UNKNOWN")
        
        reply = f"[{intent.upper()}] Request successfully processed by the Orchestrator. You said: '{prompt}'"
        
        duration = time.time() - start_time
        tokens = len(prompt.split())
        tps = tokens / duration if duration > 0 else 0
        logger.info(f"Generation complete in {duration:.2f}s. Tokens: {tokens}. TPS: {tps:.2f}")
        
        return {
            "reply": reply,
            "usage": {"tokens": tokens}
        }
        
    def generate_stream(self, prompt: str, **kwargs) -> Any:
        if not self.is_loaded:
            self.load_model()
            
        logger.info(f"Generating stream using PlaceholderProvider.")
        intent = kwargs.get("intent", "UNKNOWN")
        words = f"[{intent.upper()}] Request successfully processed by the Orchestrator. You said: '{prompt}'".split()
        
        for word in words:
            yield word + " "
