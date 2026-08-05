"""
System Prompt Manager for building structured agnostic prompts.
"""
from typing import List, Dict
from core.intelligence.schemas import IntelligenceContext
from config import settings
from utils.logger import get_logger

logger = get_logger("intelligence.prompt")

class PromptManager:
    """Builds the structured prompt array for the Provider."""
    
    FALCON_PERSONALITY = (
        "You are Falcon, an intelligent AI assistant designed to be accurate, concise, professional, and helpful.\n"
        "Prioritize factual correctness over sounding confident.\n"
        "Never invent information.\n"
        "If you are uncertain, clearly state your uncertainty instead of guessing.\n"
        "Answer only what the user asks.\n"
        "Keep responses concise by default.\n"
        "Provide more detail only when the user explicitly requests it.\n"
        "Maintain a calm, natural, conversational tone."
    )
    
    HALLUCINATION_GUARD = (
        "\n\n[CRITICAL INSTRUCTIONS]\n"
        "- Never invent facts or fabricate names.\n"
        "- Admit uncertainty if you do not know the answer.\n"
        "- Ask clarifying questions if the prompt is ambiguous.\n"
        "- Do not make unnecessary assumptions."
    )
    
    @staticmethod
    def process(context: IntelligenceContext) -> IntelligenceContext:
        """Assembles the final structured prompt list."""
        
        structured_prompt: List[Dict[str, str]] = []
        
        # 1. Base Personality
        system_content = PromptManager.FALCON_PERSONALITY
        
        # 2. Hallucination Guard
        if settings.ENABLE_HALLUCINATION_GUARD:
            system_content += PromptManager.HALLUCINATION_GUARD
            
        # 3. Dynamic Response Rules
        if context.response_profile:
            system_content += f"\n\n[RESPONSE PROFILE: {context.response_profile.profile_name}]\n"
            system_content += f"Formatting: {context.response_profile.formatting}\n"
            system_content += f"Verbosity: {context.response_profile.verbosity}\n"
            
        structured_prompt.append({"role": "system", "content": system_content})
        
        # 4. Inject Tools Placeholder
        # TODO: Implement Tool Calling Schema injection in a future phase
        
        # 5. Inject History
        if context.conversation_history:
            structured_prompt.extend(context.conversation_history)
            
        # 6. Current User Request
        structured_prompt.append({"role": "user", "content": context.user_input})
        
        context.structured_prompt = structured_prompt
        logger.info(f"Generated prompt profile with {len(structured_prompt)} messages.")
        
        return context
