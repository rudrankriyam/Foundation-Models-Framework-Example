"""Train draft model command - Train draft model for speculative decoding"""

import subprocess
import sys
from pathlib import Path

from ..config import get_toolkit_path


def run_train_draft(args):
    """Run draft model training using toolkit's train_draft_model module"""
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
    if not args.checkpoint:
        print("Error: --checkpoint (trained adapter) is required\n")
        return
    
    if not args.train_data:
        print("Error: --train-data is required\n")
        return
    
    if not args.checkpoint_dir:
        print("Error: --checkpoint-dir is required\n")
        return
    
    checkpoint = Path(args.checkpoint)
    if not checkpoint.exists():
        print(f"Error: Checkpoint not found at {checkpoint}\n")
        return
    
    train_data = Path(args.train_data)
    if not train_data.exists():
        print(f"Error: Train data not found at {train_data}\n")
        return
    
    checkpoint_dir = Path(args.checkpoint_dir)
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    
    eval_data = Path(args.eval_data) if args.eval_data else None
    
    print("Training draft model for speculative decoding...\n")
    print(f"Adapter checkpoint: {checkpoint}")
    print(f"Train data: {train_data}")
    if eval_data:
        print(f"Eval data: {eval_data}")
    print(f"Draft checkpoints: {checkpoint_dir}\n")
    
    # Build command to run examples.train_draft_model
    cmd = [str(venv_python), "-m", "examples.train_draft_model"]
    
    cmd.extend(["--checkpoint", str(checkpoint)])
    cmd.extend(["--train-data", str(train_data)])
    if eval_data:
        cmd.extend(["--eval-data", str(eval_data)])
    cmd.extend(["--checkpoint-dir", str(checkpoint_dir)])
    
    # Add training hyperparameters
    cmd.extend(["--epochs", str(args.epochs)])
    cmd.extend(["--learning-rate", str(args.learning_rate)])
    cmd.extend(["--batch-size", str(args.batch_size)])
    cmd.extend(["--target-precision", args.target_precision])
    cmd.extend(["--draft-precision", args.draft_precision])
    
    # Optional parameters
    if args.warmup_epochs is not None:
        cmd.extend(["--warmup-epochs", str(args.warmup_epochs)])
    if args.gradient_accumulation_steps is not None:
        cmd.extend(["--gradient-accumulation-steps", str(args.gradient_accumulation_steps)])
    if args.weight_decay is not None:
        cmd.extend(["--weight-decay", str(args.weight_decay)])
    if args.clip_grad_norm is not None:
        cmd.extend(["--clip-grad-norm", str(args.clip_grad_norm)])
    if args.max_sequence_length is not None:
        cmd.extend(["--max-sequence-length", str(args.max_sequence_length)])
    if args.checkpoint_frequency is not None:
        cmd.extend(["--checkpoint-frequency", str(args.checkpoint_frequency)])
    
    # Flags
    if args.activation_checkpointing:
        cmd.append("--activation-checkpointing")
    if args.compile_target_model:
        cmd.append("--compile-target-model")
    if args.compile_draft_model:
        cmd.append("--compile-draft-model")
    if args.fixed_sized_sequences:
        cmd.append("--fixed_sized_sequences")
    if args.pack_sequences:
        cmd.append("--pack-sequences")
    
    # Run the command
    print("Starting draft model training...\n")
    
    try:
        result = subprocess.run(
            cmd,
            cwd=str(toolkit_path),
            check=False,
        )
        
        if result.returncode == 0:
            print(f"\nDraft training complete! Checkpoints saved to: {checkpoint_dir}\n")
        
        sys.exit(result.returncode)
    except KeyboardInterrupt:
        print("\n\nDraft training cancelled.\n")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}\n")
        sys.exit(1)
