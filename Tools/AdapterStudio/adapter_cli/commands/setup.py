"""Setup command - Create venv and install dependencies"""

import platform
import subprocess
import sys
from pathlib import Path

from .. import EXIT_FAILURE, EXIT_SUCCESS
from ..config import get_toolkit_path


def run_setup() -> int:
    """Setup Python environment for adapter training"""
    print()

    toolkit_path = get_toolkit_path()
    if not toolkit_path:
        print("Error: Toolkit not configured. Run 'fmas init' first.\n")
        return EXIT_FAILURE

    toolkit_path = Path(toolkit_path)
    requirements_file = toolkit_path / "requirements.txt"

    if not requirements_file.exists():
        print(f"Error: requirements.txt not found at {requirements_file}\n")
        return EXIT_FAILURE

    venv_path = toolkit_path / "venv"
    if platform.system() == "Windows":
        python_path = venv_path / "Scripts" / "python.exe"
    else:
        python_path = venv_path / "bin" / "python"

    print(f"Toolkit: {toolkit_path}")
    print(f"Virtual environment: {venv_path}\n")

    if python_path.exists():
        print("Using existing Python virtual environment.\n")
    else:
        print("Creating Python virtual environment...")
        try:
            subprocess.run(
                [sys.executable, "-m", "venv", str(venv_path)],
                check=True,
            )
            print("  Virtual environment created.\n")
        except subprocess.CalledProcessError as e:
            print(f"  Error: Failed to create venv\n  {e}\n")
            return EXIT_FAILURE
        except OSError as error:
            print(f"  Error: Failed to launch Python\n  {error}\n")
            return EXIT_FAILURE

    print("Installing dependencies...")

    try:
        subprocess.run(
            [str(python_path), "-m", "pip", "install", "-r", str(requirements_file)],
            check=True,
        )
        print("  Dependencies installed.\n")
    except subprocess.CalledProcessError as e:
        print(f"  Error: Failed to install dependencies\n  {e}\n")
        return EXIT_FAILURE
    except OSError as error:
        print(f"  Error: Failed to launch the virtual environment\n  {error}\n")
        return EXIT_FAILURE

    print("Validating installation...")
    try:
        subprocess.run(
            [str(python_path), "-c", "import torch; import tamm; import sentencepiece"],
            check=True,
            text=True,
            capture_output=True,
        )
        print("  All packages validated.\n")
    except subprocess.CalledProcessError as e:
        print("  Error: Required packages failed to import\n")
        if e.stderr:
            print(e.stderr)
        return EXIT_FAILURE
    except OSError as error:
        print(f"  Error: Failed to validate the environment\n  {error}\n")
        return EXIT_FAILURE

    print("Setup complete!\n")
    print("Next steps:")
    print("  1. Prepare your training dataset (JSONL format)")
    print("  2. Run: fmas generate --prompt 'Test prompt'")
    print("  3. Train an adapter with: fmas train-adapter --help\n")
    print("To activate venv manually:")
    print(f"  source {venv_path}/bin/activate\n")
    return EXIT_SUCCESS
