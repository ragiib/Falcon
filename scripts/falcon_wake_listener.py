"""
Falcon Always-On Standby Wake Word Listener Service.
Runs continuously from Windows startup with minimal resource footprint (<40MB RAM, 0% CPU idle).
Monitors default microphone for "Falcon wake up" using Faster-Whisper STT with strict confidence filtering.
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

# Safe UTF-8 encoding configuration for stdout/stderr
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass
if sys.stderr is not None and hasattr(sys.stderr, 'reconfigure'):
    try:
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

LOG_FILE = r"c:\falcon\logs\wake_listener.log"
FALCON_LAUNCHER = r"c:\falcon\FalconLauncher.ps1"
HEALTH_URL = "http://127.0.0.1:8000/api/v1/health"
WAKE_TRIGGER_URL = "http://127.0.0.1:8000/api/v1/wake/trigger"
IPC_HOST = "127.0.0.1"
IPC_PORT = 8009
MODEL_DIR = r"c:\falcon\models\stt"

# Check for Test Mode: WAKE_TEST_MODE=true or --test-mode argument
WAKE_TEST_MODE = os.getenv("WAKE_TEST_MODE", "false").lower() in ("true", "1", "yes") or "--test-mode" in sys.argv

def log(msg: str, level: str = "INFO"):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] [FALCON WAKE][{level}] {msg}"
    if sys.stderr is not None:
        try:
            print(formatted, file=sys.stderr, flush=True)
        except Exception:
            pass
    try:
        os.makedirs(r"c:\falcon\logs", exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    except Exception:
        pass

def log_startup_diagnostics():
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    log("==================================================")
    log(f"Process started")
    log(f"Python executable: {sys.executable}")
    log(f"Working directory: {os.getcwd()}")
    log(f"Script path: {os.path.abspath(__file__)}")
    log(f"Startup timestamp: {ts}")
    log(f"Test Mode Active: {WAKE_TEST_MODE}")
    log("==================================================")

log_startup_diagnostics()

# Global state control
current_state = "STANDBY"
mic_paused = False
mic_status = "INITIALIZING"
selected_mic_name = "None"
client_sockets = []
client_sockets_lock = threading.Lock()
audio_queue = queue.Queue()
last_activation_ts = 0.0
pending_wake_event = False
last_matched_phrase = "falcon wake up"
cold_wake_id = 0  # Monotonic counter incremented on each cold-start wake cycle

def transition_to(new_state: str):
    global current_state
    if current_state != new_state:
        log(f"[STATE] {current_state} → {new_state}", "INFO")
        current_state = new_state

def return_to_standby(reason: str = "Falcon session ended"):
    global mic_paused, pending_confirmation_ts, current_state, mic_status, wake_stt_model, pending_wake_event
    if current_state == "STANDBY" and not mic_paused:
        return

    transition_to("RETURNING_TO_STANDBY")
    log(f"[FALCON WAKE] {reason}", "INFO")
    log("[FALCON WAKE] Releasing microphone", "INFO")
    log("[FALCON WAKE] Resuming wake listener microphone", "INFO")

    mic_paused = False
    pending_wake_event = False
    pending_confirmation_ts = 0.0

    # Flush audio queue
    while not audio_queue.empty():
        try:
            audio_queue.get_nowait()
        except Exception:
            break

    log("[FALCON WAKE] Microphone READY", "INFO")
    detector_status = "READY" if wake_stt_model is not None else "DEGRADED"
    log(f"[FALCON WAKE] Wake detector {detector_status}", "INFO")
    log("[FALCON WAKE] STATUS = STANDBY", "INFO")
    transition_to("STANDBY")

def session_monitor_loop():
    """Background watcher that detects Falcon session termination and automatically returns wake listener to STANDBY."""
    while True:
        try:
            time.sleep(1.0)
            if mic_paused or current_state in ["ACTIVE", "ACTIVATING", "WAKE_DETECTED"]:
                now = time.time()
                # 45s grace period following launch to allow cold-boot launcher, API startup & Flutter IPC connect
                if (now - last_activation_ts) >= 45.0:
                    with client_sockets_lock:
                        has_active_clients = len(client_sockets) > 0
                    if not has_active_clients and not is_falcon_running():
                        return_to_standby("Falcon session ended (no active clients & process terminated)")
        except Exception as err:
            log(f"Session monitor exception: {err}", "DEBUG")

threading.Thread(target=session_monitor_loop, daemon=True).start()

# Wake word confirmation state
pending_confirmation_ts = 0.0
CONFIRMATION_WINDOW_SEC = 3.0

FULL_WAKE_PHRASES = [
    "falcon wake up",
    "falcon, wake up",
    "wake up falcon",
    "hey falcon wake up",
    "ok falcon wake up"
]
FALCON_KEYWORDS = ["falcon", "hey falcon", "ok falcon"]

# Audio & Networking imports
try:
    import sounddevice as sd
    from scipy.signal import butter, lfilter
    HAS_AUDIO_LIBS = True
except Exception as e:
    log(f"Audio library import warning: {e}", "WARN")
    HAS_AUDIO_LIBS = False

try:
    from faster_whisper import WhisperModel
    HAS_WHISPER = True
except Exception as e:
    log(f"Faster-Whisper import warning: {e}", "WARN")
    HAS_WHISPER = False

try:
    import requests
    import psutil
    HAS_NET_LIBS = True
except Exception as e:
    log(f"Network/system library import warning: {e}", "WARN")
    HAS_NET_LIBS = False

# Faster-Whisper Model Instance for Standby Wake Detection
wake_stt_model = None

def init_stt_engine():
    global wake_stt_model
    if not HAS_WHISPER:
        log("Faster-Whisper library not installed. Cannot initialize STT wake engine.", "ERROR")
        return False

    os.makedirs(MODEL_DIR, exist_ok=True)
    model_target = "tiny.en"
    log(f"Loading Faster-Whisper '{model_target}' model...", "INFO")

    try:
        m = WhisperModel(
            model_target,
            device="cpu",
            compute_type="int8",
            cpu_threads=2,
            download_root=MODEL_DIR
        )
        # Warmup model with 0.5s dummy silent audio
        dummy = np.zeros(8000, dtype=np.float32)
        segments, _ = m.transcribe(dummy, language="en", beam_size=1, temperature=0.0)
        list(segments)
        wake_stt_model = m
        log("Faster-Whisper tiny.en STT wake engine initialized successfully on CPU (int8).", "SUCCESS")
        return True
    except Exception as err:
        log(f"Failed to initialize Faster-Whisper STT engine: {err}\n{traceback.format_exc()}", "ERROR")
        return False

def preprocess_audio(audio_np):
    """Applies noise suppression high-pass filter & peak normalization."""
    if len(audio_np) == 0:
        return audio_np
    try:
        b, a = butter(2, 80.0 / (8000.0), btype='high')
        audio_np = lfilter(b, a, audio_np).astype(np.float32)
    except Exception:
        pass

    max_val = np.max(np.abs(audio_np))
    if max_val > 1e-4:
        audio_np = (audio_np / max_val) * 0.85

    return audio_np

def is_falcon_running() -> bool:
    """Checks whether the Falcon Flutter UI process (falcon.exe) is currently running."""
    if HAS_NET_LIBS:
        try:
            for proc in psutil.process_iter(['name', 'cmdline']):
                try:
                    name = (proc.info['name'] or '').lower()
                    cmdline_list = proc.info['cmdline'] or []
                    cmdline = " ".join(cmdline_list).lower()

                    # Filter out diagnostic scripts or tools searching for process names
                    if any(ignore in cmdline for ignore in ["get-ciminstance", "get-process", "check_wake_health", "grep", "test_ipc"]):
                        continue

                    if "falcon.exe" in name:
                        return True
                    if "falconlauncher.ps1" in cmdline and "powershell" in name:
                        return True
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
        except Exception:
            pass

    return False

def launch_falcon_if_needed(reason: str = "WAKE_WORD_DETECTED"):
    """Launches Falcon application via FalconLauncher.ps1 if not currently running."""
    allowed_reasons = ["WAKE_WORD_DETECTED", "MANUAL_TRIGGER"]
    if reason not in allowed_reasons:
        log(f"Launch request blocked: reason '{reason}' is not an authorized launch event.", "WARN")
        return

    log("[COLD TRACE] 3 ENTER launch_falcon_if_needed()", "INFO")
    log("[COLD TRACE] 4 Checking whether Falcon is already running", "INFO")
    running = is_falcon_running()
    log(f"[COLD TRACE] 5 Falcon running = {str(running).lower()}", "INFO")

    if not running:
        log("[COLD TRACE] 6 Starting FalconLauncher.ps1", "INFO")
        try:
            proc = subprocess.Popen([
                "powershell.exe",
                "-ExecutionPolicy", "Bypass",
                "-WindowStyle", "Normal",
                "-File", FALCON_LAUNCHER
            ])
            log(f"[COLD TRACE] 7 PowerShell process started successfully | PID={proc.pid}", "SUCCESS")
            log("[COLD TRACE] 8 Waiting for Flutter IPC client on port 8009", "INFO")
        except Exception as e:
            log(f"[COLD TRACE] ERROR Starting FalconLauncher.ps1: {e}", "ERROR")
            log(f"[COLD TRACE] Stderr/Exception: {traceback.format_exc()}", "ERROR")
    else:
        log("Falcon application UI is already running.", "INFO")
        log("[COLD TRACE] 8 Waiting for Flutter IPC client on port 8009", "INFO")

def broadcast_ipc_event(event_dict: dict):
    """Sends JSON IPC message to all connected clients (Flutter / Backend)."""
    payload = (json.dumps(event_dict) + "\n").encode('utf-8')
    with client_sockets_lock:
        client_count = len(client_sockets)
        log(f"[WAKE TRACE] Sending WAKE_WORD_DETECTED to Flutter clients (count={client_count})", "INFO")
        dead_sockets = []
        for s in client_sockets:
            try:
                s.sendall(payload)
                log("[WAKE TRACE] WAKE_WORD_DETECTED sent successfully over active socket", "SUCCESS")
            except Exception as e:
                log(f"[WAKE TRACE] Send error to client: {e}", "WARN")
                dead_sockets.append(s)
        for ds in dead_sockets:
            if ds in client_sockets:
                client_sockets.remove(ds)
                try:
                    ds.close()
                except Exception:
                    pass

def bring_falcon_to_foreground():
    """Forces Windows OS to restore and bring Falcon UI window to active foreground focus."""
    try:
        import ctypes
        user32 = ctypes.windll.user32
        hwnd = user32.FindWindowW(None, "Falcon AI")
        if hwnd:
            user32.ShowWindow(hwnd, 9)  # SW_RESTORE = 9
            user32.SetForegroundWindow(hwnd)
            log("Falcon UI window brought to active foreground focus.", "SUCCESS")
    except Exception as e:
        log(f"Foreground focus exception: {e}", "DEBUG")

def trigger_wake_event(phrase: str):
    """Executes activation handshake: releases mic, notifies IPC clients & API endpoint."""
    global mic_paused, last_activation_ts, pending_wake_event, last_matched_phrase, cold_wake_id

    cold_wake_id += 1
    log("[COLD TRACE] 1 WAKE DETECTED", "SUCCESS")
    pending_wake_event = True
    last_matched_phrase = phrase
    log("[COLD TRACE] 2 pending_wake_event = True", "INFO")

    transition_to("WAKE_DETECTED")
    transition_to("ACTIVATING")

    # Force window to foreground focus
    bring_falcon_to_foreground()

    if WAKE_TEST_MODE:
        log(f"[WAKE TEST MODE] WAKE EVENT TRIGGERED! Matched phrase: '{phrase}' (Falcon launch suppressed)", "SUCCESS")
        event_data = {
            "event": "WAKE_WORD_DETECTED",
            "timestamp": int(time.time() * 1000),
            "source": "wake_listener",
            "phrase": phrase,
            "test_mode": True
        }
        broadcast_ipc_event(event_data)
        mic_paused = True
        last_activation_ts = time.time()
        transition_to("ACTIVE")
        return

    log(f"WAKE EVENT TRIGGERED! Matched phrase: '{phrase}'", "SUCCESS")

    # 1. Pause microphone capture for handoff to main app STT
    mic_paused = True
    last_activation_ts = time.time()

    # 2. Single instance check & launch if closed
    launch_reason = "MANUAL_TRIGGER" if phrase == "manual_trigger" else "WAKE_WORD_DETECTED"
    launch_falcon_if_needed(reason=launch_reason)

    # 3. Broadcast IPC event over socket (to already-connected clients, if any)
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

    transition_to("ACTIVE")

def handle_client_connection(conn, addr):
    """Handles IPC client commands (Flutter UI / Backend API)."""
    global mic_paused, mic_status, selected_mic_name, pending_wake_event, last_matched_phrase, last_activation_ts
    log("[COLD TRACE] 4 Flutter client connected", "INFO")
    log(f"[COLD TRACE] 4 pending_wake_event = {pending_wake_event}", "INFO")
    log(f"[COLD WAKE {cold_wake_id:03d}] Flutter IPC client connected: {addr}", "INFO")
    log(f"IPC Client connected from {addr}", "INFO")
    with client_sockets_lock:
        client_sockets.append(conn)

    # Deliver pending cold-start wake event to this newly connected client
    log(f"[COLD WAKE {cold_wake_id:03d}] Pending wake event exists = {pending_wake_event}", "INFO")
    delivered_wake_event = False
    if pending_wake_event or (time.time() - last_activation_ts < 45.0 and mic_paused):
        log(f"[COLD WAKE {cold_wake_id:03d}] Delivering pending WAKE_WORD_DETECTED to {addr}", "SUCCESS")
        log(f"[WAKE TRACE] Sending WAKE_WORD_DETECTED to Flutter clients", "INFO")
        log(f"[WAKE TRACE] Connected IPC clients: 1", "INFO")
        event_data = {
            "event": "WAKE_WORD_DETECTED",
            "timestamp": int(time.time() * 1000),
            "source": "wake_listener",
            "phrase": last_matched_phrase
        }
        try:
            log("[COLD TRACE] 5 Sending WAKE_WORD_DETECTED", "INFO")
            conn.sendall((json.dumps(event_data) + "\n").encode('utf-8'))
            log("[COLD TRACE] 6 WAKE_WORD_DETECTED send completed", "SUCCESS")
            log(f"[COLD WAKE {cold_wake_id:03d}] WAKE_WORD_DETECTED sent successfully to {addr}", "SUCCESS")
            log("[WAKE TRACE] WAKE_WORD_DETECTED sent successfully", "SUCCESS")
            delivered_wake_event = True
        except Exception as e:
            log(f"[WAKE TRACE] Send error to client: {e}", "WARN")

    buffer = ""
    remaining_clients = 0
    conn_start_ts = time.time()
    is_command_client = False
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
                is_command_client = True
                log(f"IPC Received Command: {line}", "DEBUG")
                try:
                    cmd_json = json.loads(line)
                    cmd = cmd_json.get("command", "").upper()
                except Exception:
                    cmd = line.upper()

                if cmd in ["PAUSE_MIC", "MIC_PAUSE", "STATE:LISTENING", "STATE:GREETING", "STATE:SPEAKING"]:
                    mic_paused = True
                    transition_to("ACTIVE")
                    log("IPC command received: Microphone PAUSED (Handoff active)", "INFO")
                    conn.sendall(b'{"status":"OK","mic_paused":true}\n')
                elif cmd in ["RESUME_MIC", "MIC_RESUME", "STATE:STANDBY"]:
                    if pending_wake_event:
                        log(f"[COLD WAKE {cold_wake_id:03d}] MIC_RESUME received but pending wake event not yet delivered — keeping event alive, skipping return_to_standby()", "WARN")
                        mic_paused = False
                        conn.sendall(b'{"status":"OK","mic_paused":false,"pending_wake_preserved":true}\n')
                    else:
                        return_to_standby("IPC command received: Microphone RESUMED (Standby active)")
                        conn.sendall(b'{"status":"OK","mic_paused":false}\n')
                elif cmd in ["GET_STATUS", "STATUS"]:
                    status_report = {
                        "status": "OK",
                        "process": "RUNNING",
                        "microphone": mic_status,
                        "mic_device": selected_mic_name,
                        "wake_detector": "READY" if wake_stt_model is not None else "DEGRADED",
                        "stt_engine": "Faster-Whisper tiny.en",
                        "test_mode": WAKE_TEST_MODE,
                        "ipc": "READY",
                        "state": current_state,
                        "mic_paused": mic_paused
                    }
                    conn.sendall((json.dumps(status_report) + "\n").encode('utf-8'))
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
            remaining_clients = len(client_sockets)
        try:
            conn.close()
        except Exception:
            pass
        log(f"IPC Client disconnected: {addr}", "INFO")

        # Determine whether this connection consumed the pending wake event or was just a short probe
        if delivered_wake_event:
            conn_duration = time.time() - conn_start_ts
            if conn_duration < 0.5:
                log(f"[COLD WAKE {cold_wake_id:03d}] Client {addr} was a short probe connection (duration: {conn_duration:.2f}s) — preserving pending_wake_event = True", "INFO")
            else:
                log(f"[COLD WAKE {cold_wake_id:03d}] Wake event successfully delivered to persistent Flutter UI client {addr} (duration: {conn_duration:.2f}s)", "SUCCESS")
                pending_wake_event = False

        # Use 60s grace period — enough for cold-start reconnect cycles without wiping pending events
        if remaining_clients == 0 and mic_paused and (time.time() - last_activation_ts >= 60.0) and not is_falcon_running():
            return_to_standby("Falcon session ended (IPC client disconnected after 60s)")


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

# Audio parameters
SAMPLE_RATE = 16000
CHUNK_DURATION = 0.05
CHUNK_SIZE = int(SAMPLE_RATE * CHUNK_DURATION)
SPEECH_RMS_THRESHOLD = 0.006

def audio_callback(indata, frames, time_info, status):
    if status:
        log(f"SoundDevice status warning: {status}", "WARN")
    if not mic_paused:
        audio_queue.put(indata.copy())

def start_heartbeat_loop():
    """Periodic status heartbeat logging for persistent monitoring."""
    while True:
        try:
            time.sleep(60)
            if mic_status == "READY":
                log(f"Heartbeat — STANDBY — microphone OK | TestMode={WAKE_TEST_MODE}", "INFO")
        except Exception:
            pass

threading.Thread(target=start_heartbeat_loop, daemon=True).start()

def process_audio_segment(segment_np, dur_sec: float):
    """Processes buffered speech segment through Faster-Whisper with confidence validation."""
    global pending_confirmation_ts

    if wake_stt_model is None:
        log("[Wake Detector] STT Model not initialized. Cannot evaluate audio segment.", "WARN")
        return

    processed_np = preprocess_audio(segment_np)
    
    try:
        segments, _ = wake_stt_model.transcribe(
            processed_np,
            language="en",
            beam_size=1,
            best_of=1,
            temperature=0.0,
            condition_on_previous_text=False,
            vad_filter=False,
            initial_prompt="Falcon, wake up."
        )
        seg_list = list(segments)
    except Exception as stt_err:
        log(f"[Wake Detector] Transcription error: {stt_err}", "WARN")
        return

    raw_text = " ".join([s.text.strip() for s in seg_list]).strip()
    clean_text = re.sub(r'[^\w\s]', '', raw_text.lower()).strip()

    if seg_list:
        avg_logprob = sum([s.avg_logprob for s in seg_list]) / len(seg_list)
        no_speech_prob = max([getattr(s, 'no_speech_prob', 0.0) for s in seg_list])
    else:
        avg_logprob = -99.0
        no_speech_prob = 1.0

    now = time.time()
    window_active = (pending_confirmation_ts > 0.0 and (now - pending_confirmation_ts) <= CONFIRMATION_WINDOW_SEC)

    # Check expiration of confirmation window
    if pending_confirmation_ts > 0.0 and not window_active:
        log(f"Candidate confirmation window expired ({CONFIRMATION_WINDOW_SEC}s). Resetting to STANDBY.", "DEBUG")
        pending_confirmation_ts = 0.0

    # 1. Filter out empty, low logprob, or non-speech transcriptions
    if not clean_text or no_speech_prob > 0.40 or avg_logprob < -1.2:
        log(f'Candidate text="{raw_text}" | confidence={avg_logprob:.2f} | no_speech_prob={no_speech_prob:.2f} | duration={dur_sec:.2f}s | speech=false | decision=REJECT | reason=high no_speech_prob / low logprob / empty', "DEBUG")
        return

    has_full_phrase = any(phrase in clean_text for phrase in FULL_WAKE_PHRASES) or ("falcon" in clean_text and "wake up" in clean_text)
    has_falcon = any(kw in clean_text for kw in FALCON_KEYWORDS)
    has_wakeup = "wake up" in clean_text

    # 2. Case A: Full Wake Phrase ("Falcon wake up") in a single segment
    if has_full_phrase:
        log(f'Candidate text="{raw_text}" | confidence={avg_logprob:.2f} | no_speech_prob={no_speech_prob:.2f} | duration={dur_sec:.2f}s | speech=true | decision=ACCEPT | reason=Full wake phrase detected', "DEBUG")
        pending_confirmation_ts = 0.0
        trigger_wake_event("falcon wake up")
        return

    # 3. Case B: "wake up" detected
    if has_wakeup and not has_falcon:
        if window_active:
            log(f'Candidate text="{raw_text}" | confidence={avg_logprob:.2f} | no_speech_prob={no_speech_prob:.2f} | duration={dur_sec:.2f}s | speech=true | decision=ACCEPT | reason=Candidate phrase \'wake up\' confirmed following preceding Falcon', "DEBUG")
            pending_confirmation_ts = 0.0
            trigger_wake_event("falcon wake up")
            return
        else:
            log(f'Candidate text="{raw_text}" | confidence={avg_logprob:.2f} | no_speech_prob={no_speech_prob:.2f} | duration={dur_sec:.2f}s | speech=true | decision=REJECT | reason=wake up heard without active preceding Falcon candidate', "DEBUG")
            return

    # 4. Case C: "Falcon" detected alone
    if has_falcon:
        pending_confirmation_ts = now
        log(f'Candidate text="{raw_text}" | confidence={avg_logprob:.2f} | no_speech_prob={no_speech_prob:.2f} | duration={dur_sec:.2f}s | speech=true | decision=ACCEPT | reason=Keyword \'Falcon\' heard with high confidence. Opening {CONFIRMATION_WINDOW_SEC}s confirmation window for \'wake up\'', "DEBUG")
        return

    # 5. Case D: Unrelated speech
    log(f'Candidate text="{raw_text}" | confidence={avg_logprob:.2f} | no_speech_prob={no_speech_prob:.2f} | duration={dur_sec:.2f}s | speech=true | decision=REJECT | reason=no wake keyword matched', "DEBUG")

def run_audio_monitor():
    global mic_paused, pending_confirmation_ts, mic_status, selected_mic_name
    retry_delay = 1.0
    max_retry_delay = 10.0

    log("Audio monitor thread starting...", "INFO")

    if not init_stt_engine():
        log("STT Engine initialization failed. Background service running in degraded mode.", "ERROR")

    while True:
        if not HAS_AUDIO_LIBS:
            mic_status = "AUDIO_LIBS_MISSING"
            log("Audio libraries missing. Background listener running in IPC-only mode.", "WARN")
            time.sleep(5)
            continue

        log("Enumerating audio devices...", "INFO")
        try:
            input_devices = [d for d in sd.query_devices() if d.get('max_input_channels', 0) > 0]
            if not input_devices:
                mic_status = "NO_INPUT_DEVICES"
                log("No audio input devices found! Retrying in 3s...", "WARN")
                time.sleep(3)
                continue

            default_dev = sd.query_devices(kind='input')
            dev_name = default_dev.get('name', 'Default Microphone')
            selected_mic_name = dev_name
            log(f"Selected microphone: '{dev_name}'", "SUCCESS")
            log(f"Opening microphone on '{dev_name}'...", "INFO")

            stream = sd.InputStream(
                samplerate=SAMPLE_RATE,
                channels=1,
                dtype='float32',
                blocksize=CHUNK_SIZE,
                callback=audio_callback
            )
            stream.start()
            mic_status = "READY"
            log(f"Microphone initialized successfully.", "SUCCESS")
            log(f"[Wake Detector] Detector initialized. STATUS = STANDBY (Test Mode = {WAKE_TEST_MODE})", "SUCCESS")
            retry_delay = 1.0

            # Audio stream warmup: flush initialization noise spikes
            time.sleep(1.5)
            while not audio_queue.empty():
                try:
                    audio_queue.get_nowait()
                except queue.Empty:
                    break

            buffer_frames = []
            silence_counter = 0

            while True:
                try:
                    chunk = audio_queue.get(timeout=0.5)
                except queue.Empty:
                    if mic_paused:
                        buffer_frames.clear()
                        silence_counter = 0
                    continue

                if mic_paused:
                    buffer_frames.clear()
                    silence_counter = 0
                    continue

                chunk_flat = chunk.flatten()
                rms = float(np.sqrt(np.mean(chunk_flat**2)))

                # Voice Activity Energy Gating (RMS >= 0.006)
                if rms >= SPEECH_RMS_THRESHOLD:
                    buffer_frames.append(chunk_flat)
                    silence_counter = 0
                else:
                    if len(buffer_frames) > 0:
                        silence_counter += 1
                        # 5 continuous chunks of silence (250ms) signifies end of speech segment
                        if silence_counter >= 5:
                            segment_np = np.concatenate(buffer_frames)
                            buffer_frames.clear()
                            silence_counter = 0

                            dur_sec = len(segment_np) / SAMPLE_RATE

                            # Evaluate segment if between 350ms and 5.0s
                            if 0.35 <= dur_sec <= 5.0:
                                process_audio_segment(segment_np, dur_sec)

        except Exception as stream_err:
            mic_status = f"ERROR: {stream_err}"
            log(f"Microphone initialization or stream error: {stream_err}. Retrying in {retry_delay:.1f}s...", "ERROR")
            log(traceback.format_exc(), "DEBUG")
            time.sleep(retry_delay)
            retry_delay = min(retry_delay * 2.0, max_retry_delay)

def main():
    log("Falcon Always-On Standby Wake Word Listener Service active.")
    log(f"STATUS: STANDBY (Monitoring for 'Falcon wake up' on {IPC_HOST}:{IPC_PORT} | TestMode={WAKE_TEST_MODE})", "SUCCESS")
    
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
