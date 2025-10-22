"""Export adapter command - Export trained adapter to .fmadapter format"""

import subprocess
import sys
from pathlib import Path

from ..config import get_toolkit_path


def run_export(args):
    """Export trained adapter to .fmadapter format using toolkit's export_fmadapter module"""
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
    if not args.adapter_name:
        print("Error: --adapter-name is required\n")
        return
    
    if not args.checkpoint:
        print("Error: --checkpoint is required\n")
        return
    
    if not args.output_dir:
        print("Error: --output-dir is required\n")
        return
    
    checkpoint = Path(args.checkpoint)
    if not checkpoint.exists():
        print(f"Error: Checkpoint not found at {checkpoint}\n")
        return
    
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    draft_checkpoint = Path(args.draft_checkpoint) if args.draft_checkpoint else None
    if draft_checkpoint and not draft_checkpoint.exists():
        print(f"Error: Draft checkpoint not found at {draft_checkpoint}\n")
        return
    
    print("Exporting adapter to .fmadapter format...\n")
    print(f"Adapter name: {args.adapter_name}")
    print(f"Checkpoint: {checkpoint}")
    if draft_checkpoint:
        print(f"Draft checkpoint: {draft_checkpoint}")
    print(f"Output directory: {output_dir}\n")
    
    # Build command to run export.export_fmadapter
    cmd = [str(venv_python), "-m", "export.export_fmadapter"]
    
    cmd.extend(["--adapter-name", args.adapter_name])
    cmd.extend(["--checkpoint", str(checkpoint)])
    cmd.extend(["--output-dir", str(output_dir)])
    
    if draft_checkpoint:
        cmd.extend(["--draft-checkpoint", str(draft_checkpoint)])
    
    # Metadata
    if args.author:
        cmd.extend(["--author", args.author])
    if args.description:
        cmd.extend(["--description", args.description])
    
    # Run the command
    print("Starting export...\n")
    
    try:
        result = subprocess.run(
            cmd,
            cwd=str(toolkit_path),
            check=False,
        )
        
        if result.returncode == 0:
            fmadapter_path = output_dir / f"{args.adapter_name}.fmadapter"
            print(f"\nExport complete!")
            print(f"Adapter saved to: {fmadapter_path}\n")
            print("You can now:")
            print("  1. Add it to Xcode for testing")
            print("  2. Deploy via Background Assets framework")
            print("  3. Use it in your app with Foundation Models framework\n")
        
        sys.exit(result.returncode)
    except KeyboardInterrupt:
        print("\n\nExport cancelled.\n")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}\n")
        sys.exit(1)
