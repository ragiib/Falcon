import os
import sys
import time
import queue
import re
import traceback
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

log("Starting Faster-Whisper Large-v3 STT Listener...")

# Create models directory
os.makedirs(MODEL_DIR, exist_ok=True)

# Try importing faster-whisper and sounddevice
try:
    import sounddevice as sd
    from faster_whisper import WhisperModel
except Exception as e:
    log(f"CRITICAL: Failed to import required packages: {e}")
    sys.exit(1)

# Model Initialization with GPU -> CPU Fallback
LOCAL_MODEL_PATH = r"c:\falcon\models\stt\faster-whisper-large-v3"
if os.path.exists(os.path.join(LOCAL_MODEL_PATH, "model.bin")):
    MODEL_TARGET = LOCAL_MODEL_PATH
    log(f"Found local model directory at {LOCAL_MODEL_PATH}")
else:
    MODEL_TARGET = "large-v3"
    log("Local model directory incomplete, will download/load via HuggingFace Hub...")

model = None
device_used = "cuda"
compute_type_used = "float16"

try:
    log(f"Attempting to load Faster-Whisper Large-v3 ({MODEL_TARGET}) on GPU (CUDA float16)...")
    model = WhisperModel(
        MODEL_TARGET,
        device="cuda",
        compute_type="float16",
        download_root=MODEL_DIR
    )
    log("Successfully initialized Faster-Whisper Large-v3 on GPU (CUDA float16).")
except Exception as cuda_err:
    log(f"GPU CUDA float16 load failed: {cuda_err}")
    try:
        log("Retrying on GPU (CUDA int8_float16)...")
        model = WhisperModel(
            MODEL_TARGET,
            device="cuda",
            compute_type="int8_float16",
            download_root=MODEL_DIR
        )
        compute_type_used = "int8_float16"
        log("Successfully initialized Faster-Whisper Large-v3 on GPU (CUDA int8_float16).")
    except Exception as cuda_err2:
        log(f"GPU CUDA int8_float16 load failed: {cuda_err2}")
        log("Falling back to CPU (int8, 4 threads)...")
        try:
            model = WhisperModel(
                MODEL_TARGET,
                device="cpu",
                compute_type="int8",
                cpu_threads=4,
                download_root=MODEL_DIR
            )
            device_used = "cpu"
            compute_type_used = "int8"
            log("Successfully initialized Faster-Whisper Large-v3 on CPU.")
        except Exception as cpu_err:
            log(f"CRITICAL: CPU model initialization failed: {cpu_err}\n{traceback.format_exc()}")
            sys.exit(1)

log(f"Model ready on {device_used.upper()} ({compute_type_used}). Signal STT_INITIALIZED to host.")

# Audio parameters
SAMPLE_RATE = 16000
CHUNK_DURATION = 0.05  # 50ms chunks
CHUNK_SIZE = int(SAMPLE_RATE * CHUNK_DURATION)

audio_queue = queue.Queue()

def audio_callback(indata, frames, time_info, status):
    if status:
        log(f"SoundDevice status warning: {status}")
    audio_queue.put(indata.copy())

try:
    stream = sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=1,
        dtype='float32',
        blocksize=CHUNK_SIZE,
        callback=audio_callback
    )
    stream.start()
    log("Microphone audio stream started successfully.")
except Exception as stream_err:
    log(f"CRITICAL: Failed to open default microphone stream: {stream_err}")
    sys.exit(1)

# Signal initialization complete to parent process (Flutter)
print("STT_INITIALIZED", flush=True)

# State for VAD & Speech processing
SPEECH_THRESHOLD = 0.012  # RMS energy threshold for speech
SILENCE_DURATION_LIMIT = 0.8  # Seconds of silence to trigger transcription
MIN_SPEECH_DURATION = 0.4  # Minimum duration (s) of speech to transcribe

speech_buffer = []
silence_counter = 0.0
in_speech = False
last_vol_print = time.time()

WAKE_WORDS = ["falcon", "hey falcon", "ok falcon", "computer", "hey computer"]

def clean_transcript(text: str) -> str:
    # Remove common hallucinated whisper artifacts or repetitive brackets
    text = re.sub(r'\[.*?\]|\(.*?\)', '', text).strip()
    return text

def check_wake_word(text: str):
    text_lower = text.lower()
    for ww in WAKE_WORDS:
        if ww in text_lower:
            return True, ww
    return False, ""

def process_audio_segment(audio_np):
    if len(audio_np) < int(SAMPLE_RATE * MIN_SPEECH_DURATION):
        return

    try:
        segments, _ = model.transcribe(
            audio_np,
            language="en",
            beam_size=1,
            vad_filter=True,
            vad_parameters=dict(min_silence_duration_ms=500),
            initial_prompt="Falcon, computer, assistant, user command."
        )
        
        full_text = " ".join([s.text.strip() for s in segments]).strip()
        full_text = clean_transcript(full_text)
        
        if not full_text:
            return

        log(f"Raw Transcribed Text: '{full_text}'")

        is_ww, matched_ww = check_wake_word(full_text)

        if is_ww:
            log(f"Wake word detected in transcript: '{matched_ww}'")
            print("WAKE_WORD_DETECTED", flush=True)
            
            # Check if there is extra transcript after wake word
            pattern = re.compile(re.escape(matched_ww), re.IGNORECASE)
            remainder = pattern.sub("", full_text, count=1).strip()
            # Clean punctuation from start of remainder
            remainder = re.sub(r'^[,\.\?\!\s]+', '', remainder).strip()

            if len(remainder.split()) >= 1 and len(remainder) > 2:
                log(f"Extra speech recognized alongside wake word: '{remainder}'")
                print(f"RECOGNIZED:{remainder}", flush=True)
        else:
            log(f"Speech Recognized: '{full_text}'")
            print(f"RECOGNIZED:{full_text}", flush=True)

    except Exception as tx_err:
        log(f"Error during transcription: {tx_err}\n{traceback.format_exc()}")

log("Entering main audio loop...")

try:
    while True:
        try:
            chunk = audio_queue.get(timeout=0.2)
        except queue.Empty:
            continue

        chunk_flat = chunk.flatten()
        rms = float(np.sqrt(np.mean(chunk_flat**2)))
        
        # Calculate volume level 0-100
        vol = min(100.0, max(0.0, rms * 400.0))

        now = time.time()
        if now - last_vol_print >= 0.08:  # Send volume update ~12 times per sec
            print(f"VOLUME:{vol:.1f}", flush=True)
            last_vol_print = now

        # VAD & Speech Segmentation
        if rms >= SPEECH_THRESHOLD:
            if not in_speech:
                in_speech = True
                speech_buffer = []
            speech_buffer.append(chunk_flat)
            silence_counter = 0.0
        else:
            if in_speech:
                speech_buffer.append(chunk_flat)
                silence_counter += CHUNK_DURATION
                if silence_counter >= SILENCE_DURATION_LIMIT:
                    # Speech segment finished
                    in_speech = False
                    complete_speech = np.concatenate(speech_buffer)
                    speech_buffer = []
                    silence_counter = 0.0

                    # Process in background / transcribe
                    process_audio_segment(complete_speech)
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
