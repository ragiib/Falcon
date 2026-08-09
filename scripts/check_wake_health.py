"""
Falcon Wake System Health Diagnostic Utility
Queries background listener process and socket IPC on port 8009.
"""
import sys
import socket
import json
import psutil

IPC_HOST = "127.0.0.1"
IPC_PORT = 8009

def check_process():
    pid = None
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            cmd = " ".join(proc.info['cmdline'] or []).lower()
            if "falcon_wake_listener.py" in cmd:
                pid = proc.info['pid']
                break
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return pid

def check_ipc():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(2.0)
        s.connect((IPC_HOST, IPC_PORT))
        s.sendall(b'{"command":"GET_STATUS"}\n')
        
        response = ""
        while True:
            chunk = s.recv(1024).decode('utf-8')
            if not chunk:
                break
            response += chunk
            if "\n" in response:
                break
        s.close()
        
        if response.strip():
            return json.loads(response.strip())
    except Exception as e:
        return {"error": str(e)}
    return None

def main():
    print("==================================================")
    print(" FALCON WAKE SYSTEM DIAGNOSTIC REPORT")
    print("==================================================")
    
    pid = check_process()
    if pid:
        print(f"PROCESS:       RUNNING (PID: {pid})")
    else:
        print("PROCESS:       NOT RUNNING")

    status_data = check_ipc()
    if status_data and "error" not in status_data:
        mic_dev = status_data.get("mic_device", "Unknown")
        mic_stat = status_data.get("microphone", "UNKNOWN")
        state = status_data.get("state", "UNKNOWN")
        
        print(f"MICROPHONE:    {mic_stat} ('{mic_dev}')")
        print(f"WAKE DETECTOR: READY")
        print(f"IPC:           READY ({IPC_HOST}:{IPC_PORT})")
        print(f"STATE:         {state}")
    else:
        err = status_data.get("error", "No response") if status_data else "Failed to connect"
        print(f"MICROPHONE:    UNKNOWN")
        print(f"WAKE DETECTOR: UNKNOWN")
        print(f"IPC:           FAILED ({err})")
        print(f"STATE:         UNKNOWN")
        
    print("==================================================")

if __name__ == "__main__":
    main()
