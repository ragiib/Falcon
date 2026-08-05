"""
Qwen local model provider using llama-cpp-python.
"""
import os
from typing import Any, Dict
from interfaces.base import IModelProvider
from core.providers.exceptions import ModelNotFoundError, ModelLoadError, InferenceError
from config import settings
from utils.logger import get_logger

logger = get_logger("providers.qwen")

class QwenProvider(IModelProvider):
    """Model provider for local Qwen GGUF models."""
    
    def __init__(self):
        self.llm = None
        self.status = "unloaded"
        
    def load_model(self) -> None:
        """Loads the Qwen model into memory using llama_cpp."""
        if self.llm is not None:
            logger.info("Qwen model is already loaded.")
            return
            
        if not os.path.exists(settings.MODEL_PATH):
            self.status = "error"
            raise ModelNotFoundError(f"Model file not found at {settings.MODEL_PATH}")
            
        self.status = "loading"
        logger.info(f"Loading Qwen model from {settings.MODEL_PATH}...")
        
        try:
            from llama_cpp import Llama, llama_log_set
            import ctypes
            
            @ctypes.CFUNCTYPE(None, ctypes.c_int, ctypes.c_char_p, ctypes.c_void_p)
            def custom_log_callback(level, text, user_data):
                try:
                    msg = text.decode("utf-8", errors="ignore").strip()
                    if msg:
                        logger.debug(f"[LLAMA] {msg}")
                except:
                    pass
                    
            # Keep a reference to prevent garbage collection
            self._log_callback = custom_log_callback
            llama_log_set(self._log_callback, ctypes.c_void_p(0))
            
            self.llm = Llama(
                model_path=settings.MODEL_PATH,
                n_ctx=settings.MODEL_CONTEXT_LENGTH,
                n_gpu_layers=settings.MODEL_GPU_LAYERS,
                verbose=True # We keep this True so it emits logs, but they are now captured by our callback
            )
            self.status = "loaded"
            logger.info("Qwen model loaded successfully.")
        except Exception as e:
            self.status = "error"
            logger.error(f"Failed to load Qwen model: {str(e)}")
            raise ModelLoadError(f"Failed to load model: {str(e)}") from e
            
    def unload_model(self) -> None:
        """Unloads the model and frees resources."""
        if self.llm is not None:
            logger.info("Unloading Qwen model...")
            del self.llm
            self.llm = None
        self.status = "unloaded"
        
    def health_check(self) -> Dict[str, Any]:
        """Returns the health status of the Qwen provider."""
        return {
            "provider": "qwen",
            "model_loaded": self.llm is not None,
            "model_path": settings.MODEL_PATH,
            "inference_backend": "llama-cpp-python",
            "status": self.status
        }
        
    def _format_chatml(self, prompt: Any) -> str:
        """Converts a structured prompt into Qwen's ChatML format."""
        if isinstance(prompt, str):
            return prompt
            
        formatted = ""
        for msg in prompt:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            formatted += f"<|im_start|>{role}\n{content}<|im_end|>\n"
            
        formatted += "<|im_start|>assistant\n"
        return formatted

    def generate(self, prompt: str, **kwargs) -> Any:
        """Generates a response from the Qwen model."""
        if self.llm is None:
            self.load_model()
            
        import time
        logger.info("Starting generation...")
        start_time = time.time()
        
        # Override settings with request-specific kwargs if provided
        temperature = kwargs.get("temperature", settings.MODEL_TEMPERATURE)
        max_tokens = kwargs.get("max_tokens", settings.MODEL_MAX_TOKENS)
        top_p = kwargs.get("top_p", settings.MODEL_TOP_P)
        repeat_penalty = kwargs.get("repeat_penalty", settings.MODEL_REPEAT_PENALTY)
        
        formatted_prompt = self._format_chatml(prompt)
        
        try:
            response = self.llm(
                formatted_prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                top_p=top_p,
                repeat_penalty=repeat_penalty,
                echo=False
            )
            
            reply = response['choices'][0]['text']
            usage = response.get('usage', {})
            duration = time.time() - start_time
            
            completion_tokens = usage.get("completion_tokens", 0)
            tps = completion_tokens / duration if duration > 0 else 0
            logger.info(f"Generation complete in {duration:.2f}s. Tokens: {completion_tokens}. TPS: {tps:.2f}")
            
            return {
                "reply": reply,
                "usage": usage
            }
        except Exception as e:
            logger.error(f"Inference failed: {str(e)}")
            raise InferenceError(f"Failed during model inference: {str(e)}") from e

    def generate_stream(self, prompt: str, **kwargs) -> Any:
        """Generates a streaming response from the Qwen model."""
        if self.llm is None:
            self.load_model()
            
        import time
        logger.info("Starting streaming generation...")
        start_time = time.time()
        
        temperature = kwargs.get("temperature", settings.MODEL_TEMPERATURE)
        max_tokens = kwargs.get("max_tokens", settings.MODEL_MAX_TOKENS)
        top_p = kwargs.get("top_p", settings.MODEL_TOP_P)
        repeat_penalty = kwargs.get("repeat_penalty", settings.MODEL_REPEAT_PENALTY)
        
        formatted_prompt = self._format_chatml(prompt)
        
        try:
            stream = self.llm(
                formatted_prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                top_p=top_p,
                repeat_penalty=repeat_penalty,
                stream=True,
                echo=False
            )
            
            for chunk in stream:
                yield chunk['choices'][0]['text']
                
            duration = time.time() - start_time
            logger.info(f"Streaming generation complete in {duration:.2f}s.")
        except Exception as e:
            logger.error(f"Streaming inference failed: {str(e)}")
            raise InferenceError(f"Failed during streaming inference: {str(e)}") from e
