import os
import sys
import time

current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from core.providers.factory import ProviderFactory
from core.intelligence.engine import ConversationEngine
from config import settings

def main():
    print("Initializing ProviderFactory...")
    ProviderFactory.initialize()
    provider = ProviderFactory.get_provider()
    provider.load_model()
    
    queries = [
        "Hello",
        "Who is Messi?",
        "Explain python lists vs tuples deeply",
        "Who is Messi? under 50 words",
        "What sport does he play?"
    ]
    
    session_id = "validation_session"
    
    for user_input in queries:
        print(f"\n=======================")
        print(f"You: {user_input}")
        print(f"=======================")
        print("Assistant: ", end="", flush=True)
        
        metrics = {}
        generator = ConversationEngine.chat_stream(session_id, user_input, metrics_out=metrics)
        
        try:
            for chunk in generator:
                print(chunk, end="", flush=True)
        except Exception as e:
            print(f"\n[Error: {e}]")
            
        print("\n\n--- DEVELOPER DIAGNOSTICS ---")
        print(f"Intent : {metrics.get('intent')}")
        print(f"Profile: {metrics.get('profile')}")
        print("-----------------------------\n")

if __name__ == "__main__":
    main()
