"""
Low-latency internet connectivity detector for Falcon Dual Intelligence Mode.
"""
import socket
from utils.logger import get_logger

logger = get_logger("utils.connectivity")

def check_internet_connection(host: str = "8.8.8.8", port: int = 53, timeout: float = 1.0) -> bool:
    """
    Checks if internet connection is available using a fast socket test (DNS port 53).
    Returns True if online, False if offline.
    """
    try:
        socket.setdefaulttimeout(timeout)
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((host, port))
        s.close()
        return True
    except Exception:
        # Secondary fallback test (Cloudflare DNS 1.1.1.1)
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect(("1.1.1.1", 53))
            s.close()
            return True
        except Exception:
            return False
