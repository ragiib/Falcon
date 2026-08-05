"""
Base interfaces that future modules can extend.
"""
from abc import ABC, abstractmethod
from typing import Any, Dict

class IModelProvider(ABC):
    """Base interface for all AI model providers."""
    
    @abstractmethod
    def load_model(self) -> None:
        """Loads the model into memory."""
        pass
        
    @abstractmethod
    def unload_model(self) -> None:
        """Unloads the model from memory to free resources."""
        pass
        
    @abstractmethod
    def health_check(self) -> Dict[str, Any]:
        """Returns the health status of the provider (e.g., loaded, loading, error)."""
        pass
        
    @abstractmethod
    def generate(self, prompt: str, **kwargs) -> Any:
        """Generate a response based on a prompt."""
        pass

    @abstractmethod
    def generate_stream(self, prompt: str, **kwargs) -> Any:
        """Generate a response as a stream based on a prompt."""
        pass

class ITool(ABC):
    """Base interface for all agent tools."""
    
    @property
    @abstractmethod
    def name(self) -> str:
        """Name of the tool."""
        pass
        
    @property
    @abstractmethod
    def description(self) -> str:
        """Description of what the tool does."""
        pass
        
    @abstractmethod
    def execute(self, **kwargs) -> Any:
        """Execute the tool's action."""
        pass

class IMemory(ABC):
    """Base interface for agent memory."""
    
    @abstractmethod
    def add_message(self, role: str, content: str) -> None:
        """Add a message to the memory."""
        pass
        
    @abstractmethod
    def get_context(self) -> list:
        """Retrieve the current memory context."""
        pass
        
    @abstractmethod
    def clear(self) -> None:
        """Clear the memory."""
        pass
