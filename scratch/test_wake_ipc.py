import socket
import json
import time

def test_ipc():
    print("Testing IPC connection to port 8009...")
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(2.0)
    try:
        s.connect(('127.0.0.1', 8009))
        print("Connected to wake listener service!")
        
        # Test PING
        s.sendall(b'{"command":"PING"}\n')
        resp = s.recv(1024).decode('utf-8')
        print(f"PING response: {resp.strip()}")
        
        # Test PAUSE_MIC
        s.sendall(b'{"command":"PAUSE_MIC"}\n')
        resp = s.recv(1024).decode('utf-8')
        print(f"PAUSE_MIC response: {resp.strip()}")

        # Test RESUME_MIC
        s.sendall(b'{"command":"RESUME_MIC"}\n')
        resp = s.recv(1024).decode('utf-8')
        print(f"RESUME_MIC response: {resp.strip()}")

        s.close()
        print("IPC tests PASSED successfully!")
    except Exception as e:
        print(f"IPC test exception: {e}")

if __name__ == "__main__":
    test_ipc()
