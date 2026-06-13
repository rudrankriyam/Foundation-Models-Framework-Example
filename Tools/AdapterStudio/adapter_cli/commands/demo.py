"""Demo command - Test generation with the base model"""

import subprocess
from argparse import Namespace
from pathlib import Path

from .. import EXIT_FAILURE, EXIT_USAGE
from ..config import get_toolkit_path


def run_demo(args: Namespace) -> int:
    """Run demo generation using toolkit's example"""
    print()

    toolkit_path = get_toolkit_path()
    if not toolkit_path:
        print("Error: Toolkit not configured. Run 'fmas init' first.\n")
        return EXIT_FAILURE

    toolkit_path = Path(toolkit_path)
    venv_python = toolkit_path / "venv" / "bin" / "python"

    if not venv_python.exists():
        print("Error: Virtual environment not set up. Run 'fmas setup' first.\n")
        return EXIT_FAILURE

    cmd = [str(venv_python), "-m", "examples.generate"]

    if not args.prompt:
        print("Error: --prompt is required\n")
        return EXIT_USAGE

    cmd.extend(["--prompt", args.prompt])

    if args.precision:
        cmd.extend(["--precision", args.precision])
    if args.temperature is not None:
        cmd.extend(["--temperature", str(args.temperature)])
    if args.top_k is not None:
        cmd.extend(["--top-k", str(args.top_k)])
    if args.max_new_tokens is not None:
        cmd.extend(["--max-new-tokens", str(args.max_new_tokens)])
    if args.batch_size is not None:
        cmd.extend(["--batch-size", str(args.batch_size)])
    if args.compile_model:
        cmd.append("--compile-model")
    if args.num_draft_tokens is not None:
        cmd.extend(["--num_draft_tokens", str(args.num_draft_tokens)])
    
    print("Generating text with base model...\n")

    try:
        result = subprocess.run(
            cmd,
            cwd=str(toolkit_path),
            timeout=300,
        )
        return result.returncode
    except subprocess.TimeoutExpired:
        print("\n\nGeneration timed out (exceeded 5 minutes). Check model size or system resources.\n")
        return EXIT_FAILURE
    except KeyboardInterrupt:
        print("\n\nGeneration cancelled.\n")
        return EXIT_FAILURE
    except FileNotFoundError as e:
        print(f"Error: File not found: {e}\n")
        return EXIT_FAILURE
    except PermissionError as e:
        print(f"Error: Permission denied: {e}\n")
        return EXIT_FAILURE
    except OSError as e:
        print(f"OS error: {e}\n")
        return EXIT_FAILURE
    except Exception as e:
        print(f"Unexpected error: {type(e).__name__}: {e}\n")
        return EXIT_FAILURE
