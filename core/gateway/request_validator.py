"""
Validation logic for incoming requests.
"""
from typing import Dict, Any
from core.gateway.schemas import GatewayRequest
from core.gateway.exceptions import GatewayValidationError

class RequestValidator:
    """Validates raw request dictionaries against the standard schema."""

    @staticmethod
    def validate_and_parse(raw_request: Dict[str, Any]) -> GatewayRequest:
        """
        Validates the raw request and parses it into a GatewayRequest object.
        
        Args:
            raw_request: The incoming request payload.
            
        Returns:
            GatewayRequest: The validated and parsed request.
            
        Raises:
            GatewayValidationError: If the request is malformed or invalid.
        """
        errors = []

        # Required fields check
        required_fields = ["request_id", "session_id", "user_id", "message"]
        for field in required_fields:
            if field not in raw_request:
                errors.append(f"Missing required field: '{field}'")
            elif not isinstance(raw_request[field], str):
                errors.append(f"Field '{field}' must be a string")
        
        # Message validation
        message = raw_request.get("message", "")
        if isinstance(message, str) and not message.strip():
            errors.append("Message cannot be empty")
            
        # Attachments validation
        attachments = raw_request.get("attachments", [])
        if not isinstance(attachments, list):
            errors.append("Field 'attachments' must be a list")
        else:
            for i, att in enumerate(attachments):
                if not isinstance(att, dict):
                    errors.append(f"Attachment at index {i} must be a dictionary")
                elif "format" in att and att["format"] not in ["pdf", "txt", "image/png", "image/jpeg"]:
                    errors.append(f"Unsupported attachment format: {att.get('format')}")
                    
        # Metadata validation
        metadata = raw_request.get("metadata", {})
        if not isinstance(metadata, dict):
            errors.append("Field 'metadata' must be a dictionary")

        if errors:
            raise GatewayValidationError("Request validation failed", errors=errors)

        return GatewayRequest(
            request_id=raw_request["request_id"],
            session_id=raw_request["session_id"],
            user_id=raw_request["user_id"],
            message=raw_request["message"],
            attachments=attachments,
            metadata=metadata
        )
