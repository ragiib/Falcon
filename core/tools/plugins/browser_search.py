"""
Browser Search Plugin for Falcon Tool Manager.
Executes Google/YouTube searches and opens URLs directly in the default browser.
"""
import re
import subprocess
import urllib.parse
from core.tools.plugins.base import ToolPlugin
from utils.logger import get_logger

logger = get_logger("tools.plugins.browser_search")

class BrowserSearchPlugin(ToolPlugin):
    """Plugin for web search and URL opening actions."""

    @property
    def name(self) -> str:
        return "BrowserSearch"

    @property
    def description(self) -> str:
        return "Executes Google/YouTube web searches and opens URLs directly in the default browser."

    def can_handle(self, text: str) -> bool:
        text_lower = text.lower().strip()
        patterns = [
            r"\b(search\s+google|google\s+search|search\s+for)\b",
            r"\bsearch\s+youtube\b",
            r"\bopen\s+(website|site|url|http|https|www\.)\b",
            r"\bopen\s+google\b"
        ]
        return any(re.search(p, text_lower) for p in patterns)

    def execute(self, text: str) -> str:
        text_lower = text.lower().strip()
        logger.info(f"[BrowserSearchPlugin] Executing browser search for '{text}'")

        try:
            # 1. YouTube Search
            if "youtube" in text_lower and "search" in text_lower:
                match = re.search(r"search\s+(youtube\s+for|for)?\s*(.*)", text_lower)
                query = match.group(2).strip() if match and match.group(2) else "trending"
                encoded = urllib.parse.quote_plus(query)
                url = f"https://www.youtube.com/results?search_query={encoded}"
                subprocess.Popen(["start", url], shell=True)
                return f"Searching YouTube for {query}, sir."

            # 2. Google Search
            elif "google" in text_lower or "search" in text_lower:
                match = re.search(r"(search\s+(google\s+for|for)?|google\s+search)\s*(.*)", text_lower)
                query = match.group(3).strip() if match and match.group(3) else text
                # Filter out pure 'google' phrase
                if query == "google" or not query:
                    url = "https://www.google.com"
                    subprocess.Popen(["start", url], shell=True)
                    return "Opening Google, sir."
                
                encoded = urllib.parse.quote_plus(query)
                url = f"https://www.google.com/search?q={encoded}"
                subprocess.Popen(["start", url], shell=True)
                return f"Searching Google for {query}, sir."

            # 3. Direct Website / URL
            elif "open" in text_lower and ("website" in text_lower or "site" in text_lower or "www." in text_lower):
                match = re.search(r"open\s+(website|site|url)?\s*([a-zA-Z0-9\.\-]+)", text_lower)
                target = match.group(2).strip() if match else "google.com"
                if not target.startswith("http"):
                    target = f"https://{target}"
                subprocess.Popen(["start", target], shell=True)
                return f"Opening {target}, sir."

            return "Opened browser successfully, sir."

        except Exception as e:
            logger.error(f"[BrowserSearchPlugin] Error executing search: {e}")
            return f"Failed to execute browser search: {str(e)}"
