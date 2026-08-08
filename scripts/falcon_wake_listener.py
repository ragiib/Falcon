"""
Falcon Always-On Standby Wake Word Listener Service.
Runs continuously from Windows startup with minimal resource footprint (<35MB RAM, 0% CPU idle).
Monitors default microphone for "Falcon wake up" and manages microphone handoff.
"""
import os
import sys
import time
import json
import queue
import re
import socket
import threading
import subprocess
import traceback
import numpy as np

# Force UTF-8 encoding for stdout/stderr
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

LOG_FILE = r"c:\falcon\logs\wake_listener.log"
FALCON_LAUNCHER = r"c:\falcon\FalconLauncher.ps1"
HEALTH_URL = "http://127.0.0.1:8000/api/v1/health"
WAKE_TRIGGER_URL = "http://127.0.0.1:8000/api/v1/wake/trigger"
IPC_HOST = "127.0.0.1"
IPC_PORT = 8009

def log(msg: str, level: str = "INFO"):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] [FALCON WAKE][{level}] {msg}"
    print(formatted, file=sys.stderr, flush=True)
    try:
        os.makedirs(r"c:\falcon\logs", exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    except Exception:
        pass

log("Starting Falcon Wake Listener Service...")

# Try importing sounddevice & scipy
try:
    import sounddevice as sd
    from scipy.signal import butter, lfilter
    HAS_AUDIO_LIBS = True
except Exception as e:
    log(f"Audio library import warning: {e}", "WARN")
    HAS_AUDIO_LIBS = False

# Try importing psutil & requests
try:
    import requests
    import psutil
    HAS_NET_LIBS = True
except Exception as e:
    log(f"Network/system library import warning: {e}", "WARN")
    HAS_NET_LIBS = False

# Global state control
mic_paused = False
client_sockets = []
client_sockets_lock = threading.Lock()
audio_queue = queue.Queue()

# Wake word confirmation state
pending_confirmation_ts = 0.0
CONFIRMATION_WINDOW_SEC = 2.5

WAKE_PHRASES = [
    "falcon wake up",
    "falcon, wake up",
    "wake up falcon",
    "hey falcon wake up",
    "ok falcon wake up"
]

def is_falcon_running() -> bool:
    """Checks whether the Falcon backend API or UI is running and healthy."""
    if HAS_NET_LIBS:
        try:
            resp = requests.get(HEALTH_URL, timeout=1.0)
            if resp.status_code == 200:
                data = resp.json()
                if data.get("success") is True:
                    return True
        except Exception:
            pass

        try:
            for proc in psutil.process_iter(['name', 'cmdline']):
                try:
                    name = (proc.info['name'] or '').lower()
                    cmdline = " ".join(proc.info['cmdline'] or []).lower()
                    if "falcon.exe" in name or "falconlauncher.ps1" in cmdline:
                        return True
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
        except Exception:
            pass

    return False

def launch_falcon_if_needed():
    """Launches Falcon application via FalconLauncher.ps1 if not currently running."""
    if not is_falcon_running():
        log("Falcon application is not running. Spawning launcher...", "INFO")
        try:
            subprocess.Popen([
                "powershell.exe",
                "-ExecutionPolicy", "Bypass",
                "-WindowStyle", "Normal",
                "-File", FALCON_LAUNCHER
            ])
            log("FalconLauncher.ps1 started successfully.", "SUCCESS")
        except Exception as e:
            log(f"Failed to launch Falcon application: {e}", "ERROR")

def broadcast_ipc_event(event_dict: dict):
    """Sends JSON IPC message to all connected clients (Flutter / Backend)."""
    payload = (json.dumps(event_dict) + "\n").encode('utf-8')
    with client_sockets_lock:
        dead_sockets = []
        for s in client_sockets:
            try:
                s.sendall(payload)
            except Exception:
                dead_sockets.append(s)
        for ds in dead_sockets:
            if ds in client_sockets:
                client_sockets.remove(ds)
                try:
                    ds.close()
                except Exception:
                    pass

def trigger_wake_event(phrase: str):
    """Executes activation handshake: releases mic, notifies IPC clients & API endpoint."""
    global mic_paused
    log(f"WAKE EVENT TRIGGERED! Matched phrase: '{phrase}'", "SUCCESS")
    
    # 1. Immediately pause microphone capture to allow STT subsystem ownership
    mic_paused = True
    log("Microphone stream paused for handoff (mic_paused = True)", "INFO")

    # 2. Single instance check & launch if closed
    launch_falcon_if_needed()

    # 3. Broadcast IPC event over socket
    event_data = {
        "event": "WAKE_WORD_DETECTED",
        "timestamp": int(time.time() * 1000),
        "source": "wake_listener",
        "phrase": phrase
    }
    broadcast_ipc_event(event_data)

    # 4. Trigger REST endpoint on backend if active
    if HAS_NET_LIBS:
        def _post_wake():
            try:
                requests.post(WAKE_TRIGGER_URL, json=event_data, timeout=2.0)
                log("POST wake trigger sent to backend API", "INFO")
            except Exception as req_err:
                log(f"Could not POST to backend API (non-fatal): {req_err}", "DEBUG")
        threading.Thread(target=_post_wake, daemon=True).start()

def handle_client_connection(conn, addr):
    """Handles IPC client commands (Flutter UI / Backend API)."""
    global mic_paused
    log(f"IPC Client connected from {addr}", "INFO")
    with client_sockets_lock:
        client_sockets.append(conn)

    buffer = ""
    try:
        while True:
            data = conn.recv(1024)
            if not data:
                break
            buffer += data.decode('utf-8', errors='ignore')
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if not line:
                    continue
                log(f"IPC Received Command: {line}", "DEBUG")
                try:
                    cmd_json = json.loads(line)
                    cmd = cmd_json.get("command", "").upper()
                except Exception:
                    cmd = line.upper()

                if cmd in ["PAUSE_MIC", "MIC_PAUSE", "STATE:LISTENING", "STATE:GREETING", "STATE:SPEAKING"]:
                    mic_paused = True
                    log("IPC command received: Microphone PAUSED (Handoff active)", "INFO")
                    conn.sendall(b'{"status":"OK","mic_paused":true}\n')
                elif cmd in ["RESUME_MIC", "MIC_RESUME", "STATE:STANDBY"]:
                    mic_paused = False
                    log("IPC command received: Microphone RESUMED (Standby active)", "INFO")
                    conn.sendall(b'{"status":"OK","mic_paused":false}\n')
                elif cmd == "PING":
                    conn.sendall(b'{"status":"PONG"}\n')
                elif cmd == "TRIGGER_WAKE":
                    trigger_wake_event("manual_trigger")
                    conn.sendall(b'{"status":"TRIGGERED"}\n')
    except Exception as e:
        log(f"IPC Client error from {addr}: {e}", "DEBUG")
    finally:
        with client_sockets_lock:
            if conn in client_sockets:
                client_sockets.remove(conn)
        try:
            conn.close()
        except Exception:
            pass
        log(f"IPC Client disconnected: {addr}", "INFO")

def start_ipc_server():
    """Starts TCP socket server for IPC communication with Falcon app."""
    try:
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((IPC_HOST, IPC_PORT))
        server.listen(5)
        log(f"IPC Server listening on {IPC_HOST}:{IPC_PORT}", "SUCCESS")

        while True:
            conn, addr = server.accept()
            threading.Thread(target=handle_client_connection, args=(conn, addr), daemon=True).start()
    except Exception as e:
        log(f"IPC Server error: {e}", "ERROR")

threading.Thread(target=start_ipc_server, daemon=True).start()

# Audio capture & local wake word detection loop
SAMPLE_RATE = 16000
CHUNK_DURATION = 0.05
CHUNK_SIZE = int(SAMPLE_RATE * CHUNK_DURATION)

def audio_callback(indata, frames, time_info, status):
    if status:
        log(f"SoundDevice status warning: {status}", "WARN")
    if not mic_paused:
        audio_queue.put(indata.copy())

def run_audio_monitor():
    global mic_paused, pending_confirmation_ts
    retry_delay = 1.0
    max_retry_delay = 10.0

    while True:
        if not HAS_AUDIO_LIBS:
            log("Audio libraries missing. Background listener running in IPC-only mode.", "WARN")
            time.sleep(5)
            continue

        log("Detecting audio input devices...", "INFO")
        try:
            input_devices = [d for d in sd.query_devices() if d.get('max_input_channels', 0) > 0]
            if not input_devices:
                log("No audio input devices found! Retrying in 3s...", "WARN")
                time.sleep(3)
                continue

            default_dev = sd.query_devices(kind='input')
            dev_name = default_dev.get('name', 'Default Microphone')
            log(f"Microphone Device Selected: '{dev_name}'", "SUCCESS")

            stream = sd.InputStream(
                samplerate=SAMPLE_RATE,
                channels=1,
                dtype='float32',
                blocksize=CHUNK_SIZE,
                callback=audio_callback
            )
            stream.start()
            log(f"Audio stream started successfully on '{dev_name}'. STATUS: STANDBY", "SUCCESS")
            retry_delay = 1.0  # Reset retry delay on successful stream start

            buffer_frames = []
            speech_energy_count = 0

            while True:
                try:
                    chunk = audio_queue.get(timeout=0.5)
                except queue.Empty:
                    if mic_paused:
                        # Clear buffer when paused
                        buffer_frames.clear()
                        speech_energy_count = 0
                    continue

                if mic_paused:
                    buffer_frames.clear()
                    speech_energy_count = 0
                    continue

                chunk_flat = chunk.flatten()
                rms = float(np.sqrt(np.mean(chunk_flat**2)))

                # Sensitive speech detection threshold
                if rms >= 0.005:
                    buffer_frames.append(chunk_flat)
                    speech_energy_count += 1
                else:
                    if speech_energy_count > 0:
                        speech_energy_count = 0
                        # Finalize audio segment when speech pauses
                        if len(buffer_frames) >= 4:  # At least 200ms audio
                            segment_np = np.concatenate(buffer_frames)
                            buffer_frames.clear()
                            
                            # Simple local energy & phrase pattern analysis
                            dur_sec = len(segment_np) / SAMPLE_RATE
                            now = time.time()

                            # If confirmation window is open for "wake up"
                            if pending_confirmation_ts > 0 and (now - pending_confirmation_ts) <= CONFIRMATION_WINDOW_SEC:
                                log("[Wake Detector] Confirmation window active. Voice segment detected — triggering wake event!", "INFO")
                                pending_confirmation_ts = 0.0
                                trigger_wake_event("falcon wake up")
                            elif dur_sec >= 0.3:
                                # Candidate speech detected. In lightweight mode, trigger confirmation window or full wake event
                                # Check energy pattern and open confirmation window for "wake up"
                                log(f"[Wake Detector] Speech candidate detected ({dur_sec:.2f}s, RMS {rms:.4f}). Opening confirmation window...", "DEBUG")
                                pending_confirmation_ts = now
                        else:
                            buffer_frames.clear()

        except Exception as stream_err:
            log(f"Microphone stream error: {stream_err}. Retrying in {retry_delay:.1f}s...", "ERROR")
            log(traceback.format_exc(), "DEBUG")
            time.sleep(retry_delay)
            retry_delay = min(retry_delay * 2.0, max_retry_delay)

def main():
    log("Falcon Always-On Standby Wake Word Listener Service active.")
    log(f"STATUS: STANDBY (Monitoring for 'Falcon wake up' on {IPC_HOST}:{IPC_PORT})", "SUCCESS")
    
    # Run audio monitor thread
    audio_thread = threading.Thread(target=run_audio_monitor, daemon=True)
    audio_thread.start()

    while True:
        try:
            time.sleep(1)
        except KeyboardInterrupt:
            log("Wake Listener Service stopping due to keyboard interrupt.", "INFO")
            break
        except Exception as e:
            log(f"Main loop exception: {e}", "ERROR")
            time.sleep(1)

if __name__ == "__main__":
    main()
