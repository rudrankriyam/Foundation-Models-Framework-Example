#!/usr/bin/env python3
"""Adapter Studio CLI - Main entry point"""

import argparse
import sys

from .banner import print_banner
from .commands.init import run_init
from .commands.setup import run_setup


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
