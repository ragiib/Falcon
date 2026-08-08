"""
File & Folder Plugin for Falcon Tool Manager.
Opens system folders (Downloads, Documents), files, creates files, and writes notes.
"""
import os
import re
import subprocess
from core.tools.plugins.base import ToolPlugin
from utils.logger import get_logger

logger = get_logger("tools.plugins.file_folder")

class FileFolderPlugin(ToolPlugin):
    """Plugin for folder, file navigation, and file writing operations."""

    @property
    def name(self) -> str:
        return "FileFolder"

    @property
    def description(self) -> str:
        return "Opens system folders (Downloads, Documents), files, creates files, and writes notes."

    def can_handle(self, text: str) -> bool:
        text_lower = text.lower().strip()
        patterns = [
            r"\bopen\s+(downloads|documents|desktop|folder|directory)\b",
            r"\bopen\s+folder\b",
            r"\bcreate\s+(a\s+)?file\b",
            r"\bwrite\s+.*?\s+to\s+file\b",
            r"\bwrite\s+['\"].*?['\"]\b"
        ]
        return any(re.search(p, text_lower) for p in patterns)

    def execute(self, text: str) -> str:
        text_lower = text.lower().strip()
        user_profile = os.environ.get("USERPROFILE", r"C:\Users\Public")
        logger.info(f"[FileFolderPlugin] Executing file/folder action for '{text}'")

        try:
            # 1. Downloads Folder
            if "downloads" in text_lower:
                downloads_path = os.path.join(user_profile, "Downloads")
                subprocess.Popen(["explorer.exe", downloads_path])
                return "Opening Downloads folder, sir."

            # 2. Documents Folder
            elif "documents" in text_lower:
                docs_path = os.path.join(user_profile, "Documents")
                subprocess.Popen(["explorer.exe", docs_path])
                return "Opening Documents folder, sir."

            # 3. Desktop Folder
            elif "desktop" in text_lower:
                desktop_path = os.path.join(user_profile, "Desktop")
                subprocess.Popen(["explorer.exe", desktop_path])
                return "Opening Desktop folder, sir."

            # 4. Write note/file
            elif "write" in text_lower:
                match = re.search(r"write\s+['\"](.*?)['\"]", text, re.IGNORECASE)
                content = match.group(1) if match else "Falcon note content"
                note_file = "notes.txt"
                with open(note_file, "a", encoding="utf-8") as f:
                    f.write(content + "\n")
                subprocess.Popen(["notepad.exe", note_file])
                return f"Saved note to notes.txt and opened Notepad, sir."

            # 5. Generic File / Folder Open
            elif "folder" in text_lower or "directory" in text_lower:
                subprocess.Popen(["explorer.exe"])
                return "Opening File Explorer, sir."

            return "Executed file folder action, sir."

        except Exception as e:
            logger.error(f"[FileFolderPlugin] Error in file/folder action: {e}")
            return f"Failed to open file or folder: {str(e)}"
