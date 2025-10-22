"""Train draft model command - Train draft model for speculative decoding"""

import os
import shutil
import subprocess
from pathlib import Path

from ..config import get_toolkit_path


def run_train_draft(args):
    """Run draft model training using toolkit's train_draft_model module"""
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
    
    # Validate required arguments
    if not args.train_data:
        print("Error: --train-data is required\n")
        return
    
    if not args.checkpoint_dir:
        print("Error: --checkpoint-dir is required\n")
        return
    
    checkpoint = Path(args.checkpoint).expanduser().resolve() if args.checkpoint else None
    if checkpoint and not checkpoint.exists():
        print(f"Error: Checkpoint not found at {checkpoint}\n")
        return
    
    train_data = Path(args.train_data).expanduser().resolve()
    if not train_data.exists():
        print(f"Error: Train data not found at {train_data}\n")
        return
    if not train_data.is_file() or not os.access(train_data, os.R_OK):
        print(f"Error: Train data is not readable: {train_data}\n")
        return
    
    created_checkpoint_dir = False

    checkpoint_dir = Path(args.checkpoint_dir).expanduser().resolve()
    checkpoint_dir_existed = checkpoint_dir.exists()
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    created_checkpoint_dir = not checkpoint_dir_existed
    
    eval_data = Path(args.eval_data).expanduser().resolve() if args.eval_data else None
    
    print("Training draft model for speculative decoding...\n")
    if checkpoint:
        print(f"Adapter checkpoint: {checkpoint}")
    else:
        print("Adapter checkpoint: base model (no fine-tuned checkpoint provided)")
    print(f"Train data: {train_data}")
    if eval_data:
        print(f"Eval data: {eval_data}")
    print(f"Draft checkpoints: {checkpoint_dir}\n")
    
    # Build command to run examples.train_draft_model
    cmd = [str(venv_python), "-m", "examples.train_draft_model"]
    
    if checkpoint:
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
    if args.loss_update_frequency is not None:
        cmd.extend(["--loss-update-frequency", str(args.loss_update_frequency)])
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
        cmd.append("--fixed-sized-sequences")
    if args.pack_sequences:
        cmd.append("--pack-sequences")
    
    # Run the command (let subprocess inherit stdout/stderr for live output)
    print("Starting draft model training...\n")
    
    try:
        result = subprocess.run(
            cmd,
            cwd=str(toolkit_path),
            timeout=86400,  # 24 hours for training
        )
        
        if result.returncode == 0:
            print(f"\nDraft training complete! Checkpoints saved to: {checkpoint_dir}\n")
        else:
            print(f"\nDraft training failed with exit code {result.returncode}. Cleaning up checkpoint directory.\n")
            # Clean up on failure to avoid leaving incomplete checkpoints
            if created_checkpoint_dir:
                try:
                    shutil.rmtree(checkpoint_dir)
                except Exception as cleanup_error:
                    print(f"Warning: Could not clean up checkpoint directory: {cleanup_error}\n")

        return result.returncode
    except subprocess.TimeoutExpired:
        print("\n\nDraft training timed out (exceeded 24 hours). Consider reducing epochs or batch size.\n")
        print("Cleaning up checkpoint directory.\n")
        if created_checkpoint_dir:
            try:
                shutil.rmtree(checkpoint_dir)
            except Exception as cleanup_error:
                print(f"Warning: Could not clean up checkpoint directory: {cleanup_error}\n")
        return 1
    except KeyboardInterrupt:
        print("\n\nDraft training cancelled.\n")
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
