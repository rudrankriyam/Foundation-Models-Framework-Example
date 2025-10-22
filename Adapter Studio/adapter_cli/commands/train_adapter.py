"""Train adapter command - Train adapter with toy dataset or custom data"""

import subprocess
import sys
from datetime import datetime
from pathlib import Path

from ..config import get_toolkit_path


def run_train_adapter(args):
    """Run adapter training using toolkit's train_adapter module"""
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
    
    # Determine mode: demo or custom
    if args.demo:
        print("Training adapter with toy dataset (demo mode)...\n")
        
        # Use toy dataset
        toy_dataset_path = toolkit_path / "examples" / "toy_dataset"
        train_data = toy_dataset_path / "playwriting_train.jsonl"
        eval_data = toy_dataset_path / "playwriting_valid.jsonl"
        
        if not train_data.exists() or not eval_data.exists():
            print(f"Error: Toy dataset not found at {toy_dataset_path}\n")
            return
        
        # Create checkpoint directory with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        checkpoint_dir = toolkit_path / "checkpoints" / f"demo_{timestamp}"
        checkpoint_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"Train data: {train_data}")
        print(f"Eval data: {eval_data}")
        print(f"Checkpoints: {checkpoint_dir}\n")
    else:
        print("Training adapter with custom dataset...\n")
        
        # Validate required arguments
        if not args.train_data:
            print("Error: --train-data is required (or use --demo for toy dataset)\n")
            return
        
        if not args.checkpoint_dir:
            print("Error: --checkpoint-dir is required (or use --demo)\n")
            return
        
        train_data = Path(args.train_data)
        if not train_data.exists():
            print(f"Error: Train data not found at {train_data}\n")
            return
        
        checkpoint_dir = Path(args.checkpoint_dir)
        checkpoint_dir.mkdir(parents=True, exist_ok=True)
        
        eval_data = Path(args.eval_data) if args.eval_data else None
        
        print(f"Train data: {train_data}")
        if eval_data:
            print(f"Eval data: {eval_data}")
        print(f"Checkpoints: {checkpoint_dir}\n")
    
    # Build command to run examples.train_adapter
    cmd = [str(venv_python), "-m", "examples.train_adapter"]
    
    cmd.extend(["--train-data", str(train_data)])
    if eval_data:
        cmd.extend(["--eval-data", str(eval_data)])
    cmd.extend(["--checkpoint-dir", str(checkpoint_dir)])
    
    # Add training hyperparameters
    cmd.extend(["--epochs", str(args.epochs)])
    cmd.extend(["--learning-rate", str(args.learning_rate)])
    cmd.extend(["--batch-size", str(args.batch_size)])
    cmd.extend(["--precision", args.precision])
    
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
    if args.compile_model:
        cmd.append("--compile-model")
    if args.fixed_sized_sequences:
        cmd.append("--fixed_sized_sequences")
    if args.pack_sequences:
        cmd.append("--pack-sequences")
    
    # Run the command
    print("Starting training...\n")
    
    try:
        result = subprocess.run(
            cmd,
            cwd=str(toolkit_path),
            check=False,
        )
        
        if result.returncode == 0:
            print(f"\nTraining complete! Checkpoints saved to: {checkpoint_dir}\n")
        
        sys.exit(result.returncode)
    except KeyboardInterrupt:
        print("\n\nTraining cancelled.\n")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}\n")
        sys.exit(1)
