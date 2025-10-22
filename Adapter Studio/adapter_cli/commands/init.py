"""Init command - Setup toolkit path"""

from pathlib import Path

from ..config import get_toolkit_path, set_toolkit_path
from ..discovery import find_toolkit
from ..validator import validate_toolkit


def run_init():
    """Run interactive toolkit setup"""
    print()
    
    # Check if already configured
    existing_path = get_toolkit_path()
    if existing_path:
        print(f"Toolkit already configured at:")
        print(f"  {existing_path}\n")
        change = input("Do you want to change it? [y/n]: ").strip().lower()
        if change != "y":
            print("Keeping existing configuration.\n")
            return
    
    # Try auto-discovery
    print("Searching for toolkit in common locations...\n")
    discovered_toolkit = find_toolkit()
    
    if discovered_toolkit:
        print(f"Found toolkit at: {discovered_toolkit}\n")
        use_found = input("Use this toolkit? [y/n]: ").strip().lower()
        if use_found == "y":
            _save_and_confirm(discovered_toolkit)
            return
        print()
    else:
        print("No toolkit found in common locations.")
        print("(Searched: ~/Downloads/, ~/adapter-toolkit, /opt/adapter-toolkit)\n")
    
    # Manual path entry
    print("This tool requires the Apple Foundation Models Adapter Training Toolkit.")
    print("Download it from: https://developer.apple.com/machine-learning/foundation-models/\n")
    
    while True:
        try:
            toolkit_input = input("Enter path to toolkit: ").strip()
        except KeyboardInterrupt:
            print("\n\nSetup cancelled.\n")
            return
        except EOFError:
            print("\n\nSetup cancelled.\n")
            return
        
        if not toolkit_input:
            print("Error: Path cannot be empty.\n")
            continue
        
        try:
            toolkit_path = Path(toolkit_input).expanduser().resolve()
        except (RuntimeError, ValueError) as e:
            print(f"Error: Invalid path: {e}")
            print("   Tip: Use absolute paths or ~/path (e.g., ~/Downloads/adapter_toolkit)\n")
            continue
        
        # Validate
        is_valid, errors = validate_toolkit(toolkit_path)
        
        if is_valid:
            _save_and_confirm(toolkit_path)
            return
        else:
            print("\nError: Toolkit validation failed:")
            for error in errors:
                print(f"   - {error}")
            print("\nPlease check the path and try again.\n")


def _save_and_confirm(toolkit_path: Path) -> None:
    """Save toolkit path and show confirmation"""
    print("\nValidating toolkit structure...")
    print("  Found examples/")
    print("  Found assets/")
    print("  Found export/")
    print("  Found requirements.txt")
    print("  All files present!\n")
    
    set_toolkit_path(str(toolkit_path))
    print(f"Config saved to: ~/.adapter-studio/config.json")
    print(f"Ready to go!\n")
    print("Try: adapter-studio generate --help\n")
