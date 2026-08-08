import os
import sys
import time
import queue
import re
import traceback
import threading
import numpy as np

# Force UTF-8 encoding for stdout
sys.stdout.reconfigure(encoding='utf-8')

LOG_FILE = r"c:\falcon\logs\stt_py.log"
MODEL_DIR = r"c:\falcon\models\stt"

def log(msg: str):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] [STT_PY] {msg}"
    print(formatted, file=sys.stderr, flush=True)
    try:
        os.makedirs(r"c:\falcon\logs", exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    except Exception:
        pass

log("[Wake] Wake-word service starts.")

# Control state: PAUSE/RESUME STT when host TTS is speaking
is_paused = False

def stdin_listener():
    global is_paused
    for line in sys.stdin:
        cmd = line.strip().upper()
        if cmd == "PAUSE":
            is_paused = True
            log("STT Listener PAUSED (Host TTS active).")
        elif cmd == "RESUME":
            is_paused = False
            log("STT Listener RESUMED (Listening active).")

threading.Thread(target=stdin_listener, daemon=True).start()

# Create models directory
os.makedirs(MODEL_DIR, exist_ok=True)

# Try importing faster-whisper and sounddevice
try:
    import sounddevice as sd
    from faster_whisper import WhisperModel
except Exception as e:
    log(f"CRITICAL: Failed to import required packages: {e}")
    sys.exit(1)

# Model Initialization: Switch to Faster-Whisper Base.en for higher accuracy
LOCAL_BASE_PATH = r"c:\falcon\models\stt\faster-whisper-base.en"
if os.path.exists(os.path.join(LOCAL_BASE_PATH, "model.bin")):
    MODEL_TARGET = LOCAL_BASE_PATH
    log(f"Found local base model directory at {LOCAL_BASE_PATH}")
else:
    MODEL_TARGET = "base.en"
    log("Loading Faster-Whisper Base.en for real-time low-latency performance with higher accuracy...")

def verify_model_transcribe(m):
    # Pass 0.5s of silent audio to force CTranslate2 CUDA kernel initialization & DLL checks
    dummy = np.zeros(8000, dtype=np.float32)
    segments, _ = m.transcribe(dummy, language="en", beam_size=1)
    list(segments)

def preprocess_audio(audio_np):
    if len(audio_np) == 0:
        return audio_np
    
    # 1. Noise Suppression (NS): 80Hz High-Pass Filter removes mic hum & room rumble
    try:
        from scipy.signal import butter, lfilter
        b, a = butter(2, 80.0 / (SAMPLE_RATE / 2.0), btype='high')
        audio_np = lfilter(b, a, audio_np).astype(np.float32)
    except Exception:
        pass

    # 2. Automatic Gain Control (AGC): Normalize peak amplitude to 0.85
    max_val = np.max(np.abs(audio_np))
    if max_val > 1e-4:
        audio_np = (audio_np / max_val) * 0.85

    return audio_np

model = None
device_used = "cuda"
compute_type_used = "float16"

cuda_available = True
try:
    log(f"Attempting to load Faster-Whisper Base.en ({MODEL_TARGET}) on GPU (CUDA float16)...")
    m = WhisperModel(
        MODEL_TARGET,
        device="cuda",
        compute_type="float16",
        download_root=MODEL_DIR
    )
    verify_model_transcribe(m)
    model = m
    log("Successfully initialized and verified Faster-Whisper Base.en on GPU (CUDA float16).")
except Exception as cuda_err:
    log(f"GPU CUDA float16 load/warmup failed: {cuda_err}")
    err_str = str(cuda_err).lower()
    if "cublas" in err_str or "cudnn" in err_str or "not found" in err_str or "cuda" in err_str:
        log("CUDA library error detected. Skipping GPU retries and falling directly back to CPU.")
        cuda_available = False

    if cuda_available:
        try:
            log("Retrying on GPU (CUDA int8_float16)...")
            m = WhisperModel(
                MODEL_TARGET,
                device="cuda",
                compute_type="int8_float16",
                download_root=MODEL_DIR
            )
            verify_model_transcribe(m)
            model = m
            compute_type_used = "int8_float16"
            log("Successfully initialized and verified Faster-Whisper Base.en on GPU (CUDA int8_float16).")
        except Exception as cuda_err2:
            log(f"GPU CUDA int8_float16 load/warmup failed: {cuda_err2}")
            cuda_available = False

if model is None:
    log("Falling back to CPU (int8, 4 threads)...")
    try:
        model = WhisperModel(
            MODEL_TARGET,
            device="cpu",
            compute_type="int8",
            cpu_threads=4,
            download_root=MODEL_DIR
        )
        verify_model_transcribe(model)
        device_used = "cpu"
        compute_type_used = "int8"
        log("Successfully initialized and verified Faster-Whisper Base.en on CPU.")
    except Exception as cpu_err:
        log(f"CRITICAL: CPU model initialization failed: {cpu_err}\n{traceback.format_exc()}")
        sys.exit(1)

log(f"Model ready on {device_used.upper()} ({compute_type_used}). Signal STT_INITIALIZED to host.")

# Audio parameters
SAMPLE_RATE = 16000
CHUNK_DURATION = 0.05  # 50ms chunks
CHUNK_SIZE = int(SAMPLE_RATE * CHUNK_DURATION)

audio_queue = queue.Queue()
frames_received_count = 0

def audio_callback(indata, frames, time_info, status):
    global frames_received_count
    if status:
        log(f"SoundDevice status warning: {status}")
    frames_received_count += 1
    audio_queue.put((indata.copy(), time.perf_counter()))

try:
    default_dev = sd.query_devices(kind='input')
    dev_name = default_dev.get('name', 'Default Microphone')
    log(f"Microphone Device Found: '{dev_name}' (Channels: {default_dev.get('max_input_channels')}, Sample Rate: {default_dev.get('default_samplerate')} Hz)")
    stream = sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=1,
        dtype='float32',
        blocksize=CHUNK_SIZE,
        callback=audio_callback
    )
    stream.start()
    log(f"[Wake] Microphone device opened successfully: '{dev_name}'")
except Exception as stream_err:
    log(f"CRITICAL: Failed to open default microphone stream: {stream_err}")
    sys.exit(1)

# Signal initialization complete to parent process (Flutter)
print("STT_INITIALIZED", flush=True)

# State for VAD & Speech processing
SPEECH_THRESHOLD = 0.005  # Sensitive RMS energy threshold for speech (detects quiet voice)
SILENCE_DURATION_LIMIT = 0.20  # 200ms continuous silence for end-of-speech (was 300ms)
MIN_SPEECH_DURATION = 0.05  # Lowered from 0.30 to 0.05 to prevent discarding short audio clips
MAX_QUEUE_DEPTH = 20  # If queue exceeds this, drain old chunks to stay real-time

speech_buffer = []
silence_counter = 0.0
in_speech = False
last_vol_print = time.time()
last_frame_log = time.time()
# Note: No _is_transcribing guard — faster-whisper is thread-safe and concurrent calls are intentional.

WAKE_WORDS = [
    "falcon, wake up", 
    "falcon wake up", 
    "wake up falcon", 
    "hey falcon wake up",
    "ok falcon wake up",
    "falcon", 
    "hey falcon", 
    "ok falcon", 
    "computer"
]

def clean_transcript(text: str) -> str:
    text = re.sub(r'\[.*?\]|\(.*?\)', '', text).strip()
    return text

def clean_text_for_wake(text: str) -> str:
    return re.sub(r'[^\w\s]', '', text.lower()).strip()

def check_wake_word(text: str):
    text_clean = clean_text_for_wake(text)
    for ww in sorted(WAKE_WORDS, key=len, reverse=True):
        ww_clean = clean_text_for_wake(ww)
        if ww_clean in text_clean:
            return True, ww
    return False, ""

def process_audio_segment(audio_np, speech_start_ts):
    try:
        segment_start = time.perf_counter()
        audio_dur_ms = (len(audio_np) / SAMPLE_RATE) * 1000.0
        queue_latency_ms = (segment_start - speech_start_ts) * 1000.0

        # STAGE 5: Audio buffer finalized
        log(f"ENTER: processAudioSegment() | Audio: {audio_dur_ms:.0f} ms | Queue latency: {queue_latency_ms:.0f} ms")

        if audio_dur_ms < (MIN_SPEECH_DURATION * 1000.0):
            log(f"EXIT: processAudioSegment() | SKIPPED — under minimum threshold ({audio_dur_ms:.0f} ms < {MIN_SPEECH_DURATION*1000:.0f} ms)")
            return

        preprocess_start = time.perf_counter()
        audio_np = preprocess_audio(audio_np)
        preprocess_ms = (time.perf_counter() - preprocess_start) * 1000.0
        log(f"[Latency] Preprocess (NS+AGC): {preprocess_ms:.1f} ms")

        # STAGE 6: Whisper transcription started
        log("ENTER: transcribe()")
        log("[Stage 6] Whisper transcription started")
        print("TIMING:STT_STARTED", flush=True)
        t0 = time.perf_counter()

        segments, _ = model.transcribe(
            audio_np,
            language="en",
            beam_size=1,
            best_of=1,
            temperature=0.0,
            condition_on_previous_text=False,
            vad_filter=False,
            initial_prompt="Falcon, wake up."
        )

        seg_list = list(segments)
        t1 = time.perf_counter()
        dt_ms = (t1 - t0) * 1000.0

        # STAGE 7: Whisper transcription completed
        log(f"EXIT: transcribe() | Duration: {dt_ms:.1f} ms")
        log(f"[Stage 7] Whisper transcription completed in {dt_ms:.1f} ms")

        ipc_send_ts = int(time.time() * 1000)
        print(f"TIMING:METRICS:{ipc_send_ts}:{dt_ms:.1f}:{audio_dur_ms:.0f}", flush=True)

        # STAGE 8: Transcript produced
        raw_text = " ".join([s.text.strip() for s in seg_list]).strip()
        full_text = clean_transcript(raw_text)
        log(f"[Stage 8] Raw transcript: \"{raw_text}\"")

        if not full_text:
            log("[Stage 8] Transcript is empty — no speech content. Skipping.")
            return

        total_latency_ms = (time.perf_counter() - speech_start_ts) * 1000.0
        log(f"[Latency] Total speech→transcript: {total_latency_ms:.0f} ms (STT: {dt_ms:.0f} ms | Queue: {queue_latency_ms:.0f} ms)")

        # STAGE 9: Transcript printed EXACTLY
        log(f"[Stage 9] Transcript: \"{full_text}\"")
        print(f"TRANSCRIPT_DEBUG:{full_text}", flush=True)

        # STAGE 10: Wake phrase comparison executed
        log("ENTER: checkWakeWord()")
        text_clean = clean_text_for_wake(full_text)
        log(f"[Stage 10] Cleaned transcript for comparison: \"{text_clean}\"")

        is_ww = False
        matched_ww = ""
        for ww in sorted(WAKE_WORDS, key=len, reverse=True):
            ww_clean = clean_text_for_wake(ww)
            match = ww_clean in text_clean
            log(f"[Stage 10] Comparing: transcript=\"{text_clean}\" vs wake=\"{ww_clean}\" => MATCH={str(match).upper()}")
            if match:
                is_ww = True
                matched_ww = ww
                break

        # STAGE 11: Match result
        if is_ww:
            log(f"[Stage 11] MATCH = TRUE — Phrase: \"{matched_ww}\"")
        else:
            log(f"[Stage 11] MATCH = FALSE — Transcript \"{text_clean}\" does not contain any wake phrase")
            log(f"[Stage 11] Expected one of: {[clean_text_for_wake(w) for w in WAKE_WORDS]}")

        log("EXIT: checkWakeWord()")

        wake_check_ms = (time.perf_counter() - t1) * 1000.0
        log(f"[Latency] Wake-word check: {wake_check_ms:.1f} ms")

        if is_ww:
            # STAGE 12: Wake callback executed
            final_latency_ms = (time.perf_counter() - speech_start_ts) * 1000.0
            log(f"[Stage 12] Wake callback executing. Total latency: {final_latency_ms:.0f} ms")
            print(f"WAKE_WORD_DETECTED:{matched_ww}", flush=True)
            log(f"[Stage 12] WAKE_WORD_DETECTED sent to Flutter via stdout")

            pattern = re.compile(re.escape(matched_ww), re.IGNORECASE)
            remainder = pattern.sub("", full_text, count=1).strip()
            remainder = re.sub(r'^[,\.\?\!\s]+', '', remainder).strip()
            remainder_lower = remainder.lower()

            if remainder_lower in ["wake up", "please", "sir", "wake up sir", "wake up please", "up"]:
                remainder = ""

            if len(remainder.split()) >= 1 and len(remainder) > 2:
                log(f"[Stage 12] Extra speech after wake word: '{remainder}'")
                print(f"RECOGNIZED:{remainder}", flush=True)
        else:
            log(f"[Stage 11] Sending as regular speech: '{full_text}'")
            print(f"RECOGNIZED:{full_text}", flush=True)

        log(f"EXIT: processAudioSegment()")

    except Exception as tx_err:
        log(f"[FATAL Stage Error] Exception in process_audio_segment: {tx_err}\n{traceback.format_exc()}")

log("Entering main audio loop...")

try:
    while True:
        # --- DRAIN STALE AUDIO: Always read the newest chunks ---
        chunks = []
        try:
            # Block briefly for the first chunk
            chunk_data = audio_queue.get(timeout=0.2)
            chunks.append(chunk_data)
        except queue.Empty:
            continue

        # Drain all remaining queued chunks immediately (non-blocking)
        while not audio_queue.empty():
            try:
                chunks.append(audio_queue.get_nowait())
            except queue.Empty:
                break

        queue_depth = len(chunks)
        if queue_depth > MAX_QUEUE_DEPTH:
            # Queue fell behind real-time: discard old chunks, keep only newest
            discarded = queue_depth - MAX_QUEUE_DEPTH
            chunks = chunks[-MAX_QUEUE_DEPTH:]
            log(f"[Latency] WARNING: Queue backlog detected ({queue_depth} chunks). Discarded {discarded} old chunks.")

        if is_paused:
            speech_buffer.clear()
            in_speech = False
            silence_counter = 0.0
            continue

        # Process ALL drained chunks through VAD
        for chunk_data in chunks:
            chunk, chunk_ts = chunk_data
            chunk_flat = chunk.flatten()
            rms = float(np.sqrt(np.mean(chunk_flat**2)))
            vol = min(100.0, max(0.0, rms * 400.0))

            now = time.time()
            if now - last_frame_log >= 2.0:
                log(f"[Wake] Audio frames continuously being received (total: {frames_received_count})")
                log(f"[Wake] Audio RMS: {rms:.4f}, Vol: {vol:.1f}")
                log(f"[Latency] Queue depth: {audio_queue.qsize()}, Batch size: {queue_depth}")
                last_frame_log = now

            if now - last_vol_print >= 0.08:
                print(f"VOLUME:{vol:.1f}", flush=True)
                last_vol_print = now

            # VAD & Speech Segmentation
            if rms >= SPEECH_THRESHOLD:
                if not in_speech:
                    in_speech = True
                    speech_buffer = []
                    _speech_start_ts = chunk_ts  # Timestamp when speech started
                    log("[Voice] Speech Started")
                    print("TIMING:SPEECH_DETECTED", flush=True)
                speech_buffer.append(chunk_flat)
                silence_counter = 0.0
            else:
                if in_speech:
                    speech_buffer.append(chunk_flat)
                    silence_counter += CHUNK_DURATION
                    if silence_counter >= SILENCE_DURATION_LIMIT:
                        in_speech = False
                        log("[Voice] Speech Ended")
                        print("TIMING:END_OF_SPEECH", flush=True)
                        complete_speech = np.concatenate(speech_buffer)
                        speech_end_ts = time.perf_counter()
                        vad_latency_ms = (speech_end_ts - _speech_start_ts) * 1000.0
                        log(f"[Latency] VAD speech duration: {vad_latency_ms:.0f} ms")
                        speech_buffer = []
                        silence_counter = 0.0

                        # Dispatch to background thread — faster-whisper is thread-safe
                        log("ENTER: dispatchTranscription()")
                        threading.Thread(
                            target=process_audio_segment,
                            args=(complete_speech, _speech_start_ts),
                            daemon=True
                        ).start()
                        log("EXIT: dispatchTranscription()")
except KeyboardInterrupt:
    log("STT Listener process terminated by keyboard interrupt.")
except Exception as loop_err:
    log(f"Fatal error in STT main loop: {loop_err}\n{traceback.format_exc()}")
    sys.exit(1)
finally:
    try:
        stream.stop()
        stream.close()
    except Exception:
        pass
    log("Audio stream closed. STT Listener exited.")
