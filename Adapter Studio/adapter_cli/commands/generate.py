"""Generate command - Generate text with base model or trained adapter"""

import subprocess
from pathlib import Path

from ..config import get_toolkit_path


def run_generate(args):
    """Run text generation using toolkit's examples.generate module"""
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
    
    # Validate required arguments
    if not args.prompt:
        print("Error: --prompt is required\n")
        return
    
    # Validate checkpoints if provided
    checkpoint = None
    draft_checkpoint = None
    
    if args.checkpoint:
        checkpoint = Path(args.checkpoint)
        if not checkpoint.exists():
            print(f"Error: Checkpoint not found at {checkpoint}\n")
            return
    
    if args.draft_checkpoint:
        draft_checkpoint = Path(args.draft_checkpoint)
        if not draft_checkpoint.exists():
            print(f"Error: Draft checkpoint not found at {draft_checkpoint}\n")
            return
    
    # Determine what we're generating with
    if checkpoint:
        print(f"Generating text with trained adapter...\n")
        print(f"Prompt: {args.prompt}")
        print(f"Adapter checkpoint: {checkpoint}")
        if draft_checkpoint:
            print(f"Draft checkpoint: {draft_checkpoint}")
    else:
        print(f"Generating text with base model...\n")
        print(f"Prompt: {args.prompt}")
    
    print()
    
    # Build command to run examples.generate
    cmd = [str(venv_python), "-m", "examples.generate"]
    
    cmd.extend(["--prompt", args.prompt])
    
    if checkpoint:
        cmd.extend(["--checkpoint", str(checkpoint)])
    
    if draft_checkpoint:
        cmd.extend(["--draft-checkpoint", str(draft_checkpoint)])
    
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
    if args.num_draft_tokens is not None:
        cmd.extend(["--num_draft_tokens", str(args.num_draft_tokens)])
    
    # Run the command (let subprocess inherit stdout/stderr for live output)
    print("Generating...\n")
    
    try:
        result = subprocess.run(
            cmd,
            cwd=str(toolkit_path),
            timeout=300,  # 5 minutes for generation
        )
        return result.returncode
    except subprocess.TimeoutExpired:
        print("\n\nGeneration timed out (exceeded 5 minutes). Check model size or system resources.\n")
        return 1
    except KeyboardInterrupt:
        print("\n\nGeneration cancelled.\n")
        return 1
    except FileNotFoundError as e:
        print(f"Error: File not found: {e}\n")
        return 1
    except PermissionError as e:
        print(f"Error: Permission denied: {e}\n")
        return 1
    except OSError as e:
        print(f"OS error: {e}\n")
        return 1
    except Exception as e:
        print(f"Unexpected error: {type(e).__name__}: {e}\n")
        return 1
