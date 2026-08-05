"""
Dynamic Response Controller for managing AI output length and format.
"""
import re
from core.intelligence.schemas import IntelligenceContext, ResponseProfile
from config import settings
from utils.logger import get_logger

logger = get_logger("intelligence.controller")

class ResponseController:
    """Controls the verbosity and format of the generated response."""
    
    @staticmethod
    def process(context: IntelligenceContext) -> IntelligenceContext:
        """Determines the ResponseProfile for the request."""
        if not settings.ENABLE_DYNAMIC_RESPONSE:
            context.response_profile = ResponseController._get_default_profile()
            return context
            
        msg = context.user_input.lower()
        
        # 1. Check for explicit user instructions (Overrides all defaults)
        profile = ResponseController._check_explicit_instructions(msg)
        
        # 2. Automatic profile selection based on intent
        if not profile:
            profile = ResponseController._select_by_intent(context.intent)
            
        context.response_profile = profile
        logger.info(f"Selected Response Profile: {profile.profile_name}")
        return context

    @staticmethod
    def _check_explicit_instructions(msg: str) -> ResponseProfile:
        """Looks for explicit length or formatting instructions."""
        
        # One sentence / one line
        if "one sentence" in msg or "single sentence" in msg or "one line" in msg:
            return ResponseProfile(
                profile_name="one_sentence",
                max_tokens=50,
                style="concise",
                formatting="Must be exactly one single sentence. No line breaks.",
                verbosity="Extremely brief.",
                output_format="text"
            )
            
        # Word limits (e.g. under 20 words, under 50 words)
        word_limit_match = re.search(r'under (\d+) words', msg)
        if word_limit_match:
            words = int(word_limit_match.group(1))
            return ResponseProfile(
                profile_name=f"under_{words}_words",
                max_tokens=int(words * 1.5), # Roughly 1.5 tokens per word
                style="concise",
                formatting=f"Must be strictly under {words} words.",
                verbosity="Brief and direct.",
                output_format="text"
            )
            
        if "short answer" in msg or "brief" in msg:
            return ResponseProfile(
                profile_name="short_answer",
                max_tokens=150,
                style="concise",
                formatting="No conversational filler. Just the answer.",
                verbosity="Brief.",
                output_format="text"
            )
            
        if "bullet points" in msg or "bullet list" in msg:
            return ResponseProfile(
                profile_name="bullet_points",
                max_tokens=500,
                style="structured",
                formatting="Use a bulleted list.",
                verbosity="Normal.",
                output_format="list"
            )
            
        if "detailed explanation" in msg or "explain deeply" in msg or "step-by-step" in msg:
            return ResponseProfile(
                profile_name="detailed",
                max_tokens=2048,
                style="comprehensive",
                formatting="Use markdown, headers, and detailed sections. Explain step-by-step if applicable.",
                verbosity="High.",
                output_format="markdown"
            )
            
        return None

    @staticmethod
    def _select_by_intent(intent: str) -> ResponseProfile:
        """Selects a profile automatically based on detected intent."""
        
        if intent == "chat":
            return ResponseProfile(
                profile_name="tiny",
                max_tokens=100,
                style="casual",
                formatting="Keep it conversational but very short.",
                verbosity="Low.",
                output_format="text"
            )
        elif intent == "question_answering":
            return ResponseProfile(
                profile_name="short",
                max_tokens=300,
                style="direct",
                formatting="Answer directly without unnecessary elaboration.",
                verbosity="Moderate-Low.",
                output_format="text"
            )
        elif intent in ["coding", "planning", "architecture"]:
            return ResponseProfile(
                profile_name="detailed",
                max_tokens=2048,
                style="technical",
                formatting="Use proper markdown, code blocks if necessary, and logical structure.",
                verbosity="High.",
                output_format="markdown"
            )
        else:
            return ResponseController._get_default_profile()
            
    @staticmethod
    def _get_default_profile() -> ResponseProfile:
        return ResponseProfile(
            profile_name="normal",
            max_tokens=1024,
            style="balanced",
            formatting="Standard response.",
            verbosity="Moderate.",
            output_format="text"
        )
