"""
Session Manager for tracking active conversations and users.
"""
import uuid
import time
from typing import Dict, Any
from config import settings
from utils.logger import get_logger

logger = get_logger("intelligence.session")

class SessionManager:
    """
    Manages active chat sessions, including expiry.
    Prepares for multi-user/multi-agent scaling.
    """
    
    _sessions: Dict[str, Dict[str, Any]] = {}
    
    @classmethod
    def create_session(cls) -> str:
        """Creates a new session and returns its ID."""
        session_id = str(uuid.uuid4())
        cls._sessions[session_id] = {
            "created_at": time.time(),
            "last_active": time.time(),
            "metadata": {}
        }
        logger.info(f"Created new session: {session_id}")
        return session_id
        
    @classmethod
    def get_or_create(cls, session_id: str = None) -> str:
        """Gets an existing session or creates a new one."""
        if not settings.ENABLE_SESSION_MANAGER:
            return "default_session"
            
        if session_id:
            if session_id in cls._sessions:
                cls.update_activity(session_id)
                return session_id
            else:
                # Create session with the provided ID
                cls._sessions[session_id] = {
                    "created_at": time.time(),
                    "last_active": time.time(),
                    "metadata": {}
                }
                logger.info(f"Created explicit session: {session_id}")
                return session_id
                
        return cls.create_session()
        
    @classmethod
    def update_activity(cls, session_id: str) -> None:
        """Updates the last_active timestamp for a session."""
        if session_id in cls._sessions:
            cls._sessions[session_id]["last_active"] = time.time()
            
    @classmethod
    def expire_sessions(cls) -> None:
        """Removes sessions that have exceeded SESSION_TIMEOUT."""
        current_time = time.time()
        timeout = settings.SESSION_TIMEOUT
        
        expired = [
            sid for sid, data in cls._sessions.items()
            if current_time - data["last_active"] > timeout
        ]
        
        for sid in expired:
            del cls._sessions[sid]
            logger.info(f"Expired session: {sid}")
