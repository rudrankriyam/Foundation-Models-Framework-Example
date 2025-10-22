"""Train adapter command - Train adapter with toy dataset or custom data"""

import os
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

from ..config import get_toolkit_path


def run_train_adapter(args):
    """Run adapter training using toolkit's train_adapter module"""
    print()
    
    # Validate numeric ranges
    if args.epochs < 1 or args.epochs > 100:
        print("Error: --epochs must be between 1 and 100\n")
        return
    if args.learning_rate <= 0:
        print("Error: --learning-rate must be greater than 0\n")
        return
    if args.batch_size < 1 or args.batch_size > 128:
        print("Error: --batch-size must be between 1 and 128\n")
        return
    if args.warmup_epochs < 0 or args.warmup_epochs > args.epochs:
        print("Error: --warmup-epochs must be between 0 and number of epochs\n")
        return
    
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
    created_checkpoint_dir = False

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
        created_checkpoint_dir = True
        
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
        
        train_data = Path(args.train_data).expanduser().resolve()
        if not train_data.exists():
            print(f"Error: Train data not found at {train_data}\n")
            return
        if not train_data.is_file() or not os.access(train_data, os.R_OK):
            print(f"Error: Train data is not readable: {train_data}\n")
            return

        checkpoint_dir = Path(args.checkpoint_dir).expanduser().resolve()
        checkpoint_dir_existed = checkpoint_dir.exists()
        checkpoint_dir.mkdir(parents=True, exist_ok=True)
        created_checkpoint_dir = not checkpoint_dir_existed

        eval_data = Path(args.eval_data).expanduser().resolve() if args.eval_data else None
        if eval_data and not eval_data.exists():
            print(f"Error: Eval data not found at {eval_data}\n")
            return
        if eval_data and (not eval_data.is_file() or not os.access(eval_data, os.R_OK)):
            print(f"Error: Eval data is not readable: {eval_data}\n")
            return
        
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
    if args.loss_update_frequency is not None:
        cmd.extend(["--loss-update-frequency", str(args.loss_update_frequency)])
    if args.checkpoint_frequency is not None:
        cmd.extend(["--checkpoint-frequency", str(args.checkpoint_frequency)])

    # Flags
    if args.activation_checkpointing:
        cmd.append("--activation-checkpointing")
    if args.compile_model:
        cmd.append("--compile-model")
    if args.fixed_sized_sequences:
        cmd.append("--fixed-sized-sequences")
    if args.pack_sequences:
        cmd.append("--pack-sequences")
    
    # Run the command (let subprocess inherit stdout/stderr for live output)
    print("Starting training...\n")
    
    try:
        result = subprocess.run(
            cmd,
            cwd=str(toolkit_path),
            timeout=86400,  # 24 hours for training
        )
        
        if result.returncode == 0:
            print(f"\nTraining complete! Checkpoints saved to: {checkpoint_dir}\n")
        else:
            print(f"\nTraining failed with exit code {result.returncode}. Cleaning up checkpoint directory.\n")
            # Clean up on failure to avoid leaving incomplete checkpoints
            if created_checkpoint_dir:
                try:
                    shutil.rmtree(checkpoint_dir)
                except Exception as cleanup_error:
                    print(f"Warning: Could not clean up checkpoint directory: {cleanup_error}\n")

        return result.returncode
    except subprocess.TimeoutExpired:
        print("\n\nTraining timed out (exceeded 24 hours). Consider reducing epochs or batch size.\n")
        print("Cleaning up checkpoint directory.\n")
        if created_checkpoint_dir:
            try:
                shutil.rmtree(checkpoint_dir)
            except Exception as cleanup_error:
                print(f"Warning: Could not clean up checkpoint directory: {cleanup_error}\n")
        return 1
    except KeyboardInterrupt:
        print("\n\nTraining cancelled.\n")
        print("Cleaning up checkpoint directory.\n")
        if created_checkpoint_dir:
            try:
                shutil.rmtree(checkpoint_dir)
            except Exception as cleanup_error:
                print(f"Warning: Could not clean up checkpoint directory: {cleanup_error}\n")
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
