import os
import sys
import requests
import time

MODEL_DIR = r"c:\falcon\models\stt\faster-whisper-large-v3"
os.makedirs(MODEL_DIR, exist_ok=True)

FILES = {
    "config.json": "https://huggingface.co/Systran/faster-whisper-large-v3/resolve/main/config.json",
    "preprocessor_config.json": "https://huggingface.co/Systran/faster-whisper-large-v3/resolve/main/preprocessor_config.json",
    "tokenizer.json": "https://huggingface.co/Systran/faster-whisper-large-v3/resolve/main/tokenizer.json",
    "vocabulary.json": "https://huggingface.co/Systran/faster-whisper-large-v3/resolve/main/vocabulary.json",
    "model.bin": "https://huggingface.co/Systran/faster-whisper-large-v3/resolve/main/model.bin"
}

def download_file(filename, url):
    dest_path = os.path.join(MODEL_DIR, filename)
    target_total = None

    while True:
        existing_bytes = os.path.getsize(dest_path) if os.path.exists(dest_path) else 0
        headers = {}
        mode = "wb"

        if existing_bytes > 0:
            headers['Range'] = f"bytes={existing_bytes}-"
            mode = "ab"

        try:
            with requests.get(url, headers=headers, stream=True, timeout=30) as r:
                if r.status_code in (200, 206):
                    if r.status_code == 200:
                        existing_bytes = 0
                        mode = "wb"
                        target_total = int(r.headers.get('content-length', 0))
                    elif r.status_code == 206 and target_total is None:
                        content_range = r.headers.get('content-range', '')
                        if '/' in content_range:
                            target_total = int(content_range.split('/')[-1])

                    if target_total and existing_bytes >= target_total:
                        print(f"[COMPLETE] {filename} is fully downloaded ({existing_bytes} bytes).")
                        break

                    downloaded = existing_bytes
                    last_log = time.time()

                    with open(dest_path, mode) as f:
                        for chunk in r.iter_content(chunk_size=65536):
                            if chunk:
                                f.write(chunk)
                                downloaded += len(chunk)
                                now = time.time()
                                if now - last_log >= 3.0:
                                    mb = downloaded / (1024 * 1024)
                                    if target_total:
                                        total_mb = target_total / (1024 * 1024)
                                        pct = (downloaded / target_total) * 100
                                        print(f"[{filename}] {mb:.1f} MB / {total_mb:.1f} MB ({pct:.1f}%)", flush=True)
                                    else:
                                        print(f"[{filename}] {mb:.1f} MB downloaded", flush=True)
                                    last_log = now

                    final_size = os.path.getsize(dest_path)
                    if target_total and final_size >= target_total:
                        print(f"[SUCCESS] {filename} saved ({final_size} bytes).", flush=True)
                        break
                elif r.status_code == 416: # Range Not Satisfiable -> fully downloaded
                    print(f"[COMPLETE] {filename} is fully downloaded.", flush=True)
                    break
                else:
                    print(f"[RETRY] HTTP {r.status_code} for {filename}, retrying in 3s...", flush=True)
                    time.sleep(3)
        except Exception as e:
            print(f"[RETRY] Exception during {filename} download: {e}, retrying in 3s...", flush=True)
            time.sleep(3)

for fname, url in FILES.items():
    download_file(fname, url)

print("[COMPLETE] All Faster-Whisper Large-v3 model files verified and ready.", flush=True)
