"""
Local Tool Executor for Falcon System Commands.
Delegates system actions to independent, modular tool plugins.
"""
import time
from typing import Generator, List
from core.tools.plugins.base import ToolPlugin
from core.tools.plugins.app_launcher import AppLauncherPlugin
from core.tools.plugins.browser_search import BrowserSearchPlugin
from core.tools.plugins.file_folder import FileFolderPlugin
from utils.logger import get_logger

logger = get_logger("tools.executor")

class LocalToolExecutor:
    """Registry and executor for modular Falcon tool plugins."""

    _plugins: List[ToolPlugin] = [
        AppLauncherPlugin(),
        BrowserSearchPlugin(),
        FileFolderPlugin()
    ]

    @classmethod
    def register_plugin(cls, plugin: ToolPlugin) -> None:
        """Dynamically adds a new tool plugin to the registry."""
        cls._plugins.append(plugin)
        logger.info(f"[LocalToolExecutor] Registered new plugin: {plugin.name}")

    @classmethod
    def is_tool_command(cls, text: str) -> bool:
        """Determines if user input is handled by any registered tool plugin."""
        return any(plugin.can_handle(text) for plugin in cls._plugins)

    @classmethod
    def execute_command(cls, text: str) -> str:
        """Executes matching tool plugin and returns confirmation string."""
        logger.info(f"[LocalToolExecutor] Processing command: '{text}'")
        for plugin in cls._plugins:
            if plugin.can_handle(text):
                logger.info(f"[LocalToolExecutor] Matched plugin '{plugin.name}' for input '{text}'")
                return plugin.execute(text)
        
        return f"Executed command: {text}"

    @classmethod
    def execute_stream(cls, text: str) -> Generator[str, None, None]:
        """Streams confirmation tokens for TTS and UI."""
        result = cls.execute_command(text)
        for word in result.split(" "):
            yield word + " "
            time.sleep(0.01)
