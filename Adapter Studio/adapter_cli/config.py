"""Configuration management for Adapter Studio CLI"""

import json
import os
import tempfile
from pathlib import Path


CONFIG_DIR = Path.home() / ".adapter-studio"
CONFIG_FILE = CONFIG_DIR / "config.json"


def get_config_dir() -> Path:
    """Get or create config directory"""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    return CONFIG_DIR


def load_config() -> dict:
    """Load config from file, return empty dict if not found or corrupted"""
    get_config_dir()
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except json.JSONDecodeError:
            print("Warning: Config file corrupted. Resetting.\n")
            CONFIG_FILE.unlink()  # Delete corrupted file
            return {}
    return {}


def save_config(config: dict) -> None:
    """Atomically save config to file to prevent corruption on crash/power loss"""
    config_dir = get_config_dir()
    
    # Write to temporary file first
    with tempfile.NamedTemporaryFile(
        mode='w',
        dir=config_dir,
        delete=False,
        suffix='.tmp',
    ) as tmp_file:
        json.dump(config, tmp_file, indent=2)
        temp_path = tmp_file.name
    
    try:
        # Atomic move (on POSIX systems this is atomic)
        os.replace(temp_path, CONFIG_FILE)
    except Exception as e:
        # Clean up temp file if move fails
        try:
            os.unlink(temp_path)
        except OSError:
            pass
        raise e


def get_toolkit_path() -> Path | None:
    """Get toolkit path from config, or None if not set"""
    config = load_config()
    toolkit_path = config.get("toolkit_path")
    if toolkit_path:
        return Path(toolkit_path)
    return None


def set_toolkit_path(path: str) -> None:
    """Save toolkit path to config"""
    config = load_config()
    config["toolkit_path"] = str(Path(path).expanduser().resolve())
    save_config(config)
