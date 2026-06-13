"""Export adapter command - Export trained adapter to .fmadapter format"""

import re
import subprocess
from argparse import Namespace
from pathlib import Path

from .. import EXIT_FAILURE, EXIT_USAGE
from ..config import get_toolkit_path


def _validate_adapter_name(name: str) -> bool:
    """Validate adapter name format to align with toolkit expectations"""
    if not name or len(name) > 255:
        return False
    return bool(re.match(r"^\w+$", name))


def run_export(args: Namespace) -> int:
    """Export trained adapter to .fmadapter format using toolkit's export_fmadapter module"""
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

    if not args.adapter_name:
        print("Error: --adapter-name is required\n")
        return EXIT_USAGE

    if not _validate_adapter_name(args.adapter_name):
        print("Error: --adapter-name must contain only letters, numbers, and underscores (1-255 chars)\n")
        return EXIT_USAGE

    if not args.checkpoint:
        print("Error: --checkpoint is required\n")
        return EXIT_USAGE

    if not args.output_dir:
        print("Error: --output-dir is required\n")
        return EXIT_USAGE

    checkpoint = Path(args.checkpoint).expanduser().resolve()
    if not checkpoint.exists():
        print(f"Error: Checkpoint not found at {checkpoint}\n")
        return EXIT_USAGE

    output_dir = Path(args.output_dir).expanduser().resolve()
    try:
        output_dir.mkdir(parents=True, exist_ok=True)
    except OSError as error:
        print(f"Error: Could not create output directory: {error}\n")
        return EXIT_FAILURE

    draft_checkpoint = Path(args.draft_checkpoint).expanduser().resolve() if args.draft_checkpoint else None
    if draft_checkpoint and not draft_checkpoint.exists():
        print(f"Error: Draft checkpoint not found at {draft_checkpoint}\n")
        return EXIT_USAGE

    print("Exporting adapter to .fmadapter format...\n")
    print(f"Adapter name: {args.adapter_name}")
    print(f"Checkpoint: {checkpoint}")
    if draft_checkpoint:
        print(f"Draft checkpoint: {draft_checkpoint}")
    print(f"Output directory: {output_dir}\n")
    
    cmd = [str(venv_python), "-m", "export.export_fmadapter"]

    cmd.extend(["--adapter-name", args.adapter_name])
    cmd.extend(["--checkpoint", str(checkpoint)])
    cmd.extend(["--output-dir", str(output_dir)])
    
    if draft_checkpoint:
        cmd.extend(["--draft-checkpoint", str(draft_checkpoint)])
    
    if args.author:
        cmd.extend(["--author", args.author])
    if args.description:
        cmd.extend(["--description", args.description])
    
    print("Starting export...\n")

    try:
        result = subprocess.run(
            cmd,
            cwd=str(toolkit_path),
            timeout=1800,
        )

        if result.returncode == 0:
            fmadapter_path = output_dir / f"{args.adapter_name}.fmadapter"
            print("\nExport complete!")
            print(f"Adapter saved to: {fmadapter_path}\n")
            print("You can now:")
            print("  1. Add it to Xcode for testing")
            print("  2. Deploy via Background Assets framework")
            print("  3. Use it in your app with Foundation Models framework\n")

        return result.returncode
    except subprocess.TimeoutExpired:
        print("\n\nExport timed out (exceeded 30 minutes). The adapter may be very large.\n")
        return EXIT_FAILURE
    except KeyboardInterrupt:
        print("\n\nExport cancelled.\n")
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
