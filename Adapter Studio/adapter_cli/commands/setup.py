"""Setup command - Create venv and install dependencies"""

import subprocess
import sys
from pathlib import Path

from ..config import get_toolkit_path


def run_setup():
    """Setup Python environment for adapter training"""
    print()
    
    # Get toolkit path
    toolkit_path = get_toolkit_path()
    if not toolkit_path:
        print("Error: Toolkit not configured. Run 'adapter-studio init' first.\n")
        return
    
    toolkit_path = Path(toolkit_path)
    requirements_file = toolkit_path / "requirements.txt"
    
    if not requirements_file.exists():
        print(f"Error: requirements.txt not found at {requirements_file}\n")
        return
    
    # Determine venv location (in toolkit directory)
    venv_path = toolkit_path / "venv"
    
    print(f"Toolkit: {toolkit_path}")
    print(f"Virtual environment: {venv_path}\n")
    
    # Step 1: Create venv
    print("Creating Python virtual environment...")
    try:
        subprocess.run(
            [sys.executable, "-m", "venv", str(venv_path)],
            check=True,
            capture_output=True,
        )
        print("  Virtual environment created.\n")
    except subprocess.CalledProcessError as e:
        print(f"  Error: Failed to create venv\n  {e}\n")
        return
    
    # Step 2: Install dependencies
    print("Installing dependencies...")
    pip_path = venv_path / "bin" / "pip"
    
    try:
        subprocess.run(
            [str(pip_path), "install", "-r", str(requirements_file)],
            check=True,
            capture_output=True,
        )
        print("  Dependencies installed.\n")
    except subprocess.CalledProcessError as e:
        print(f"  Error: Failed to install dependencies\n  {e}\n")
        return
    
    # Step 3: Validate installation
    print("Validating installation...")
    try:
        result = subprocess.run(
            [str(venv_path / "bin" / "python"), "-c", "import torch; import tamm; import sentencepiece"],
            check=True,
            capture_output=True,
            text=True,
        )
        print("  All packages validated.\n")
    except subprocess.CalledProcessError as e:
        print(f"  Warning: Some packages may not be installed correctly\n")
    
    # Success message
    print("Setup complete!\n")
    print("Next steps:")
    print("  1. Prepare your training dataset (JSONL format)")
    print("  2. Run: adapter-studio generate --prompt 'Test prompt'")
    print("  3. Train an adapter with: adapter-studio train-adapter --help\n")
    print(f"To activate venv manually:")
    print(f"  source {venv_path}/bin/activate\n")
