"""Configuration management for Adapter Studio CLI"""

import json
import os
from pathlib import Path


CONFIG_DIR = Path.home() / ".adapter-studio"
CONFIG_FILE = CONFIG_DIR / "config.json"


def get_config_dir() -> Path:
    """Get or create config directory"""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    return CONFIG_DIR


def load_config() -> dict:
    """Load config from file, return empty dict if not found"""
    get_config_dir()
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return {}


def save_config(config: dict) -> None:
    """Save config to file"""
    get_config_dir()
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)


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
