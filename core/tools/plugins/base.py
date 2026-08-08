"""
Base class for modular Tool Plugins in Falcon Tool Manager.
"""
from abc import ABC, abstractmethod
from typing import Generator

class ToolPlugin(ABC):
    """Abstract base class for all Falcon tool plugins."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Name of the plugin."""
        pass

    @property
    @abstractmethod
    def description(self) -> str:
        """Brief description of the tool plugin."""
        pass

    @abstractmethod
    def can_handle(self, text: str) -> bool:
        """Determines whether this plugin can handle the user input."""
        pass

    @abstractmethod
    def execute(self, text: str) -> str:
        """Executes the tool action synchronously and returns confirmation string."""
        pass

    def execute_stream(self, text: str) -> Generator[str, None, None]:
        """Yields streaming tokens for TTS and UI confirmation."""
        result = self.execute(text)
        for word in result.split(" "):
            yield word + " "
