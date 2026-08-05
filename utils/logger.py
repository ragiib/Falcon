"""
Centralized logging utility for the AI services.
"""
import logging
import os
import sys
from config.settings import LOG_LEVEL, APP_NAME

def get_logger(module_name: str) -> logging.Logger:
    """
    Returns a configured logger instance.
    
    Args:
        module_name (str): The name of the module requesting the logger.
        
    Returns:
        logging.Logger: The configured logger instance.
    """
    logger = logging.getLogger(f"{APP_NAME}.{module_name}")
    
    if not logger.handlers:
        logger.setLevel(LOG_LEVEL)
        
        # File handler
        log_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "logs")
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(log_dir, "falcon.log")
        
        file_handler = logging.FileHandler(log_file, encoding='utf-8')
        file_handler.setLevel(LOG_LEVEL)
        
        # Formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        
    return logger
