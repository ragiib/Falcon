"""
Persistent Memory Manager for Falcon.
Maintains persistent user facts, preferences, and project memories independently of the LLM.
"""
import os
import json
import re
from typing import Dict, Any, List, Optional
from utils.logger import get_logger

logger = get_logger("memory.manager")

MEMORY_FILE = os.path.join(os.path.dirname(__file__), "persistent_memory.json")

class MemoryManager:
    """Manages persistent memory storage and retrieval for Falcon Personal AI."""

    _memories: List[Dict[str, Any]] = []

    @classmethod
    def _load_storage(cls) -> None:
        """Loads memories from JSON storage on disk."""
        if os.path.exists(MEMORY_FILE):
            try:
                with open(MEMORY_FILE, "r", encoding="utf-8") as f:
                    cls._memories = json.load(f)
                logger.info(f"[MemoryManager] Loaded {len(cls._memories)} persistent memories.")
            except Exception as e:
                logger.error(f"[MemoryManager] Failed to load memory file: {e}")
                cls._memories = []
        else:
            cls._memories = []

    @classmethod
    def _save_storage(cls) -> None:
        """Saves current memory state to JSON file."""
        try:
            with open(MEMORY_FILE, "w", encoding="utf-8") as f:
                json.dump(cls._memories, f, indent=2)
            logger.info(f"[MemoryManager] Saved memories to disk ({len(cls._memories)} items).")
        except Exception as e:
            logger.error(f"[MemoryManager] Failed to save memory file: {e}")

    @classmethod
    def store_memory(cls, fact: str, category: str = "general") -> None:
        """Stores a new fact into memory."""
        cls._load_storage()
        entry = {
            "fact": fact,
            "category": category,
            "timestamp": os.path.getmtime(MEMORY_FILE) if os.path.exists(MEMORY_FILE) else 0
        }
        # Check if similar memory already exists to avoid duplicates
        for item in cls._memories:
            if item.get("fact", "").lower() == fact.lower():
                return
        cls._memories.append(entry)
        cls._save_storage()
        logger.info(f"[MemoryManager] Stored new fact: '{fact}'")

    @classmethod
    def detect_and_store(cls, user_text: str) -> Optional[str]:
        """
        Detects explicit memory commands like 'Remember that...' or 'My interview is on Monday'.
        Stores the fact if detected and returns a confirmation phrase.
        """
        text_lower = user_text.lower().strip()
        
        # Pattern 1: Explicit "remember that X" or "remember X"
        match = re.search(r"\bremember\s+(that\s+)?(.*)", user_text, re.IGNORECASE)
        if match and match.group(2):
            fact = match.group(2).strip()
            cls.store_memory(fact, category="user_fact")
            return f"I will remember that {fact}, sir."

        # Pattern 2: "My X is Y" or "I am X"
        match = re.search(r"\b(my\s+[a-z\s]+\s+is\s+.*)", user_text, re.IGNORECASE)
        if match and "what is my" not in text_lower:
            fact = match.group(1).strip()
            cls.store_memory(fact, category="user_preference")

        return None

    @classmethod
    def get_relevant_memories(cls, query: str = "") -> str:
        """Retrieves and formats stored memories into a system prompt snippet."""
        cls._load_storage()
        if not cls._memories:
            return ""

        facts = [m["fact"] for m in cls._memories[-10:]]
        if not facts:
            return ""

        memory_formatted = "\n[USER RELEVANT MEMORIES & FACTS]:\n" + "\n".join(f"- {f}" for f in facts) + "\n"
        return memory_formatted
