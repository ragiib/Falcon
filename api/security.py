"""
Security placeholder module for future Authentication (API Keys, JWT, OAuth).
"""
from fastapi import Request

async def get_current_user(request: Request):
    """
    Placeholder dependency for authentication.
    Currently allows all requests.
    """
    # TODO: Implement API Key or JWT validation here
    return {"user_id": "anonymous", "role": "user"}
