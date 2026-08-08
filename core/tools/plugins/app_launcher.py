"""
App Launcher Plugin for Falcon Tool Manager.
Launches desktop applications and returns short natural confirmations.
"""
import re
import subprocess
from core.tools.plugins.base import ToolPlugin
from utils.logger import get_logger

logger = get_logger("tools.plugins.app_launcher")

class AppLauncherPlugin(ToolPlugin):
    """Plugin for launching installed desktop applications."""

    @property
    def name(self) -> str:
        return "AppLauncher"

    @property
    def description(self) -> str:
        return "Launches installed desktop applications (VS Code, Chrome, Terminal, Calculator, Discord, Spotify, Notepad, Explorer)."

    def can_handle(self, text: str) -> bool:
        text_lower = text.lower().strip()
        patterns = [
            r"\b(open|launch|start|run)\s+(vs\s*code|vscode|code)\b",
            r"\b(open|launch|start|run)\s+(terminal|cmd|command\s+prompt|powershell)\b",
            r"\b(open|launch|start|run)\s+(chrome|browser|google\s+chrome)\b",
            r"\b(open|launch|start|run)\s+(calculator|calc)\b",
            r"\b(open|launch|start|run)\s+(discord)\b",
            r"\b(open|launch|start|run)\s+(spotify|music)\b",
            r"\b(open|launch|start|run)\s+(notepad|notes)\b",
            r"\b(open|launch|start|run)\s+(explorer|file\s+explorer|files)\b",
            r"\b(open|launch|start|run)\s+(youtube)\b"
        ]
        return any(re.search(p, text_lower) for p in patterns)

    def execute(self, text: str) -> str:
        text_lower = text.lower().strip()
        logger.info(f"[AppLauncherPlugin] Executing app launch for '{text}'")

        try:
            if "vs code" in text_lower or "vscode" in text_lower or re.search(r"\bopen\s+code\b", text_lower):
                subprocess.Popen(["code"], shell=True)
                return "Opening Visual Studio Code, sir."

            elif "terminal" in text_lower or "cmd" in text_lower or "command prompt" in text_lower or "powershell" in text_lower:
                # Try wt (Windows Terminal) first, fall back to cmd.exe
                try:
                    subprocess.Popen(["wt"], shell=True)
                except Exception:
                    subprocess.Popen(["cmd.exe"])
                return "Launching Terminal, sir."

            elif "chrome" in text_lower or "google chrome" in text_lower or "browser" in text_lower:
                subprocess.Popen(["start", "chrome"], shell=True)
                return "Opening Google Chrome, sir."

            elif "youtube" in text_lower:
                subprocess.Popen(["start", "https://youtube.com"], shell=True)
                return "Opening YouTube, sir."

            elif "calculator" in text_lower or "calc" in text_lower:
                subprocess.Popen(["calc.exe"])
                return "Opening Calculator, sir."

            elif "discord" in text_lower:
                subprocess.Popen(["start", "discord://"], shell=True)
                return "Opening Discord, sir."

            elif "spotify" in text_lower:
                subprocess.Popen(["start", "spotify:"], shell=True)
                return "Opening Spotify, sir."

            elif "notepad" in text_lower:
                subprocess.Popen(["notepad.exe"])
                return "Opening Notepad, sir."

            elif "explorer" in text_lower or "files" in text_lower:
                subprocess.Popen(["explorer.exe"])
                return "Opening File Explorer, sir."

            return f"Opening application for {text}, sir."

        except Exception as e:
            logger.error(f"[AppLauncherPlugin] Error launching app: {e}")
            return f"Failed to open application: {str(e)}"
