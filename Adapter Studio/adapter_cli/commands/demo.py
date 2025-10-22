"""Demo command - Test generation with the base model"""

import subprocess
import sys
from pathlib import Path

from ..config import get_toolkit_path


def run_demo(args):
    """Run demo generation using toolkit's example"""
    print()
    
    # Get toolkit path
    toolkit_path = get_toolkit_path()
    if not toolkit_path:
        print("Error: Toolkit not configured. Run 'adapter-studio init' first.\n")
        return
    
    toolkit_path = Path(toolkit_path)
    venv_python = toolkit_path / "venv" / "bin" / "python"
    
    if not venv_python.exists():
        print("Error: Virtual environment not set up. Run 'adapter-studio setup' first.\n")
        return
    
    # Build command to run examples.generate
    cmd = [str(venv_python), "-m", "examples.generate"]
    
    # Add required prompt argument
    if not args.prompt:
        print("Error: --prompt is required\n")
        return
    
    cmd.extend(["--prompt", args.prompt])
    
    # Add optional arguments if provided
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
    
    # Run the command
    print("Generating text with base model...\n")
    
    try:
        result = subprocess.run(
            cmd,
            cwd=str(toolkit_path),
            check=False,
        )
        sys.exit(result.returncode)
    except KeyboardInterrupt:
        print("\n\nGeneration cancelled.\n")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}\n")
        sys.exit(1)
