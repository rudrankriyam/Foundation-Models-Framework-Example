#!/usr/bin/env python3
"""Adapter Studio CLI - Main entry point"""

import argparse
import sys

from .banner import print_banner
from .commands.init import run_init
from .commands.setup import run_setup
from .commands.demo import run_demo
from .commands.generate import run_generate
from .commands.train_adapter import run_train_adapter
from .commands.train_draft import run_train_draft
from .commands.export import run_export


def add_generation_args(parser):
    """Add generation arguments that mirror toolkit defaults"""
    parser.add_argument(
        "--precision",
        choices=["f32", "bf16", "bf16-mixed", "f16-mixed"],
        default="bf16-mixed",
        help="Model precision (default: bf16-mixed)"
    )
    parser.add_argument(
        "--temperature",
        type=float,
        default=1.0,
        help="Sampling temperature (default: 1.0)"
    )
    parser.add_argument(
        "--top-k",
        type=int,
        default=50,
        help="Limit sampling to top-k tokens (default: 50)"
    )
    parser.add_argument(
        "--max-new-tokens",
        type=int,
        default=50,
        help="Maximum tokens to generate (default: 50)"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=1,
        help="Batch size for processing (default: 1)"
    )
    parser.add_argument(
        "--num-draft-tokens",
        type=int,
        default=5,
        help="Number of draft steps before verification (default: 5)"
    )
    parser.add_argument(
        "--compile-model",
        action="store_true",
        help="Compile model before inference"
    )


def add_adapter_training_args(parser):
    """Add adapter training arguments to a parser"""
    parser.add_argument(
        "--epochs",
        type=int,
        default=2,
        help="Number of training epochs (default: 2)"
    )
    parser.add_argument(
        "--learning-rate",
        type=float,
        default=1e-3,
        help="Learning rate (default: 1e-3)"
    )
    parser.add_argument(
        "--warmup-epochs",
        type=int,
        default=1,
        help="Warmup epochs (default: 1)"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=4,
        help="Batch size (default: 4)"
    )
    parser.add_argument(
        "--gradient-accumulation-steps",
        type=int,
        default=1,
        help="Gradient accumulation steps (default: 1)"
    )
    parser.add_argument(
        "--activation-checkpointing",
        action="store_true",
        help="Recompute activations to reduce memory"
    )
    parser.add_argument(
        "--precision",
        choices=["f32", "bf16", "bf16-mixed", "f16-mixed"],
        default="bf16-mixed",
        help="Model precision (default: bf16-mixed)"
    )
    parser.add_argument(
        "--compile-model",
        action="store_true",
        help="Compile model before training"
    )
    parser.add_argument(
        "--weight-decay",
        type=float,
        default=1e-2,
        help="Weight decay coefficient (default: 1e-2)"
    )
    parser.add_argument(
        "--clip-grad-norm",
        type=float,
        default=1.0,
        help="Gradient clipping norm (default: 1.0)"
    )
    parser.add_argument(
        "--max-sequence-length",
        type=int,
        help="Maximum sequence length (required when packing)"
    )
    parser.add_argument(
        "--fixed-sized-sequences",
        action="store_true",
        help="Pad sequences to max sequence length"
    )
    parser.add_argument(
        "--pack-sequences",
        action="store_true",
        help="Pack multiple sequences together"
    )
    parser.add_argument(
        "--loss-update-frequency",
        type=int,
        default=3,
        help="Frequency for loss logging (default: 3)"
    )
    parser.add_argument(
        "--checkpoint-frequency",
        type=int,
        default=1,
        help="Save checkpoint every N epochs (default: 1)"
    )


def add_draft_training_args(parser):
    """Add draft model training arguments to a parser"""
    parser.add_argument(
        "--epochs",
        type=int,
        default=2,
        help="Number of training epochs (default: 2)"
    )
    parser.add_argument(
        "--learning-rate",
        type=float,
        default=1e-3,
        help="Learning rate (default: 1e-3)"
    )
    parser.add_argument(
        "--warmup-epochs",
        type=int,
        default=1,
        help="Warmup epochs (default: 1)"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=4,
        help="Batch size (default: 4)"
    )
    parser.add_argument(
        "--gradient-accumulation-steps",
        type=int,
        default=1,
        help="Gradient accumulation steps (default: 1)"
    )
    parser.add_argument(
        "--activation-checkpointing",
        action="store_true",
        help="Recompute activations to reduce memory"
    )
    parser.add_argument(
        "--target-precision",
        choices=["f32", "bf16", "bf16-mixed", "f16-mixed"],
        default="bf16-mixed",
        help="Target model precision (default: bf16-mixed)"
    )
    parser.add_argument(
        "--compile-target-model",
        action="store_true",
        help="Compile target model before training"
    )
    parser.add_argument(
        "--draft-precision",
        choices=["f32", "bf16", "bf16-mixed", "f16-mixed"],
        default="bf16-mixed",
        help="Draft model precision (default: bf16-mixed)"
    )
    parser.add_argument(
        "--compile-draft-model",
        action="store_true",
        help="Compile draft model before training"
    )
    parser.add_argument(
        "--weight-decay",
        type=float,
        default=1e-2,
        help="Weight decay coefficient (default: 1e-2)"
    )
    parser.add_argument(
        "--clip-grad-norm",
        type=float,
        default=1.0,
        help="Gradient clipping norm (default: 1.0)"
    )
    parser.add_argument(
        "--max-sequence-length",
        type=int,
        help="Maximum sequence length (required when packing)"
    )
    parser.add_argument(
        "--fixed-sized-sequences",
        action="store_true",
        help="Pad sequences to max sequence length"
    )
    parser.add_argument(
        "--pack-sequences",
        action="store_true",
        help="Pack multiple sequences together"
    )
    parser.add_argument(
        "--loss-update-frequency",
        type=int,
        default=3,
        help="Frequency for loss logging (default: 3)"
    )
    parser.add_argument(
        "--checkpoint-frequency",
        type=int,
        default=1,
        help="Save checkpoint every N epochs (default: 1)"
    )


def create_parser():
    """Create and configure argument parser"""
    # Custom formatter to replace "positional arguments" with "Available commands"
    class CustomFormatter(argparse.RawDescriptionHelpFormatter):
        def start_section(self, heading):
            if heading == "positional arguments":
                heading = "Available commands"
            elif heading == "options":
                heading = "Options"
            elif heading == "usage":
                heading = "Usage"
            super().start_section(heading)
        
        def _format_usage(self, usage, actions, groups, prefix):
            return ""
    
    parser = argparse.ArgumentParser(
        prog="adapter-studio",
        description="Command-line toolkit for Apple Foundation Models adapter training",
        formatter_class=CustomFormatter,
    )
    
    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s 0.1.0"
    )
    
    subparsers = parser.add_subparsers(dest="command", metavar="")
    
    # Init command
    subparsers.add_parser(
        "init",
        help="Setup toolkit path (run this first!)"
    )
    
    # Setup command
    subparsers.add_parser(
        "setup",
        help="Create Python venv and install dependencies"
    )
    
    # Demo command
    demo_parser = subparsers.add_parser(
        "demo",
        help="Test generation with the base model"
    )
    demo_parser.add_argument(
        "--prompt",
        type=str,
        required=True,
        help="Text prompt to generate from"
    )
    add_generation_args(demo_parser)
    
    # Generate command
    generate_parser = subparsers.add_parser(
        "generate",
        help="Generate text using the base or adapted model"
    )
    generate_parser.add_argument(
        "--prompt",
        type=str,
        required=True,
        help="Text prompt to generate from"
    )
    generate_parser.add_argument(
        "--checkpoint",
        type=str,
        help="Path to trained adapter checkpoint (optional)"
    )
    generate_parser.add_argument(
        "--draft-checkpoint",
        type=str,
        help="Path to trained draft model checkpoint (optional)"
    )
    add_generation_args(generate_parser)
    
    # Train adapter command
    train_adapter_parser = subparsers.add_parser(
        "train-adapter",
        help="Train a custom adapter"
    )
    train_adapter_parser.add_argument(
        "--demo",
        action="store_true",
        help="Train with toy dataset (quick demo)"
    )
    train_adapter_parser.add_argument(
        "--train-data",
        type=str,
        help="Path to training dataset (JSONL)"
    )
    train_adapter_parser.add_argument(
        "--eval-data",
        type=str,
        help="Path to evaluation dataset (JSONL)"
    )
    train_adapter_parser.add_argument(
        "--checkpoint-dir",
        type=str,
        help="Directory to save checkpoints"
    )
    add_adapter_training_args(train_adapter_parser)
    
    # Train draft command
    train_draft_parser = subparsers.add_parser(
        "train-draft",
        help="Train a draft model for speculative decoding"
    )
    train_draft_parser.add_argument(
        "--checkpoint",
        type=str,
        help="Path to trained adapter checkpoint"
    )
    train_draft_parser.add_argument(
        "--train-data",
        type=str,
        required=True,
        help="Path to training dataset (JSONL)"
    )
    train_draft_parser.add_argument(
        "--eval-data",
        type=str,
        help="Path to evaluation dataset (JSONL)"
    )
    train_draft_parser.add_argument(
        "--checkpoint-dir",
        type=str,
        required=True,
        help="Directory to save draft model checkpoints"
    )
    add_draft_training_args(train_draft_parser)
    
    # Export command
    export_parser = subparsers.add_parser(
        "export",
        help="Export trained adapter to .fmadapter format"
    )
    export_parser.add_argument(
        "--adapter-name",
        type=str,
        required=True,
        help="Name of the adapter (alphanumeric + underscore)"
    )
    export_parser.add_argument(
        "--checkpoint",
        type=str,
        required=True,
        help="Path to trained adapter checkpoint"
    )
    export_parser.add_argument(
        "--draft-checkpoint",
        type=str,
        help="Path to trained draft model checkpoint (optional)"
    )
    export_parser.add_argument(
        "--output-dir",
        type=str,
        required=True,
        help="Directory where .fmadapter will be saved"
    )
    export_parser.add_argument(
        "--author",
        type=str,
        default="3P developer",
        help="Author name (default: '3P developer')"
    )
    export_parser.add_argument(
        "--description",
        type=str,
        default="",
        help="Adapter description"
    )
    
    return parser


def main():
    """Main CLI entry point"""
    # Show banner first (before parsing, so it shows even on --help)
    print_banner()
    
    parser = create_parser()
    args = parser.parse_args()
    
    exit_code = 0
    
    # Route to commands
    if args.command == "init":
        run_init()
    elif args.command == "setup":
        run_setup()
    elif args.command == "demo":
        exit_code = run_demo(args)
    elif args.command == "generate":
        exit_code = run_generate(args)
    elif args.command == "train-adapter":
        exit_code = run_train_adapter(args)
    elif args.command == "train-draft":
        exit_code = run_train_draft(args)
    elif args.command == "export":
        exit_code = run_export(args)
    else:
        # No command specified, show help
        parser.print_help()
    
    if exit_code != 0:
        sys.exit(exit_code)


if __name__ == "__main__":
    main()
