#!/usr/bin/env python3
"""Adapter Studio CLI - Main entry point"""

import argparse
import sys

from .banner import print_banner
from .commands.init import run_init
from .commands.setup import run_setup
from .commands.demo import run_demo


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
    demo_parser.add_argument(
        "--precision",
        choices=["f32", "bf16", "bf16-mixed", "f16-mixed"],
        default="bf16-mixed",
        help="Model precision (default: bf16-mixed)"
    )
    demo_parser.add_argument(
        "--temperature",
        type=float,
        default=None,
        help="Sampling temperature (default: 1.0)"
    )
    demo_parser.add_argument(
        "--top-k",
        type=int,
        default=None,
        help="Limit sampling to top-k tokens (default: 50)"
    )
    demo_parser.add_argument(
        "--max-new-tokens",
        type=int,
        default=None,
        help="Maximum tokens to generate (default: 50)"
    )
    demo_parser.add_argument(
        "--batch-size",
        type=int,
        default=None,
        help="Batch size for processing (default: 1)"
    )
    demo_parser.add_argument(
        "--compile-model",
        action="store_true",
        help="Compile model before inference"
    )
    
    # Generate command (placeholder)
    subparsers.add_parser(
        "generate",
        help="Generate text using the base or adapted model"
    )
    
    # Train adapter command (placeholder)
    subparsers.add_parser(
        "train-adapter",
        help="Train a custom adapter"
    )
    
    # Train draft command (placeholder)
    subparsers.add_parser(
        "train-draft",
        help="Train a draft model"
    )
    
    # Export command (placeholder)
    subparsers.add_parser(
        "export",
        help="Export trained adapter to .fmadapter format"
    )
    
    return parser


def main():
    """Main CLI entry point"""
    # Show banner first (before parsing, so it shows even on --help)
    print_banner()
    
    parser = create_parser()
    args = parser.parse_args()
    
    # Route to commands
    if args.command == "init":
        run_init()
    elif args.command == "setup":
        run_setup()
    elif args.command == "demo":
        run_demo(args)
    elif args.command == "generate":
        print("\nGenerate command (coming soon)")
    elif args.command == "train-adapter":
        print("\nTrain adapter command (coming soon)")
    elif args.command == "train-draft":
        print("\nTrain draft command (coming soon)")
    elif args.command == "export":
        print("\nExport command (coming soon)")
    else:
        # No command specified, show help
        parser.print_help()


if __name__ == "__main__":
    main()
