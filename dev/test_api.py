"""
Developer utility to test the Backend API Layer.
Run this after starting the API server: `python -m uvicorn api.app:app`
"""
import requests
import json
import time

BASE_URL = "http://localhost:8000/api/v1"

def test_health():
    print("\n--- Testing /health ---")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))
    return response.status_code == 200

def test_metrics():
    print("\n--- Testing /metrics ---")
    response = requests.get(f"{BASE_URL}/metrics")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

def test_create_session():
    print("\n--- Testing /session (Create) ---")
    response = requests.post(f"{BASE_URL}/session")
    print(f"Status: {response.status_code}")
    data = response.json()
    print(json.dumps(data, indent=2))
    return data["data"]["session_id"] if data["success"] else None

def test_chat_sync(session_id: str):
    print("\n--- Testing /chat (Sync) ---")
    payload = {
        "session_id": session_id,
        "message": "Hello, what is your name?"
    }
    start = time.time()
    response = requests.post(f"{BASE_URL}/chat", json=payload)
    latency = time.time() - start
    
    print(f"Status: {response.status_code} (Latency: {latency:.2f}s)")
    print(json.dumps(response.json(), indent=2))

def test_chat_stream(session_id: str):
    print("\n--- Testing /chat/stream (SSE) ---")
    payload = {
        "session_id": session_id,
        "message": "Write a haiku about artificial intelligence."
    }
    
    # We use stream=True to process Server-Sent Events
    start = time.time()
    response = requests.post(f"{BASE_URL}/chat/stream", json=payload, stream=True)
    
    print(f"Status: {response.status_code}")
    print("Streaming output:")
    
    for line in response.iter_lines(decode_unicode=True):
        if line:
            if line.startswith("data: "):
                data_str = line[len("data: "):]
                data = json.loads(data_str)
                if "token" in data:
                    print(data["token"], end="", flush=True)
                elif "done" in data:
                    print("\n\n[Stream Finished]")
                    print(f"Metadata: {json.dumps(data.get('metadata'), indent=2)}")
    
    latency = time.time() - start
    print(f"Total stream latency: {latency:.2f}s")

def test_delete_session(session_id: str):
    print("\n--- Testing /session (Delete) ---")
    response = requests.delete(f"{BASE_URL}/{session_id}")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

if __name__ == "__main__":
    print("Starting API tests. Ensure server is running at", BASE_URL)
    try:
        # Check health first
        if test_health():
            test_metrics()
            
            # End-to-end chat flow
            session_id = test_create_session()
            if session_id:
                test_chat_sync(session_id)
                test_chat_stream(session_id)
                # test_delete_session(session_id) # Optionally cleanup
        else:
            print("Health check failed. Ensure the API server is running.")
    except requests.exceptions.ConnectionError:
        print("\nConnection Error: Is the API server running? Start it with 'uvicorn api.app:app'")
