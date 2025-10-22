#!/usr/bin/env python3
"""Example: Adapter Studio CLI with ASCII art"""

import sys

BANNER = r"""
 █████╗ ██████╗  █████╗ ██████╗ ████████╗███████╗██████╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
███████║██║  ██║███████║██████╔╝   ██║   █████╗  ██████╔╝
██╔══██║██║  ██║██╔══██║██╔═══╝    ██║   ██╔══╝  ██╔══██╗
██║  ██║██████╔╝██║  ██║██║        ██║   ███████╗██║  ██║
╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝        ╚═╝   ╚══════╝╚═╝  ╚═╝

███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗
██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗
███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║
╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║
███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝
╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝
"""

MENU_OPTIONS = [
    "Generate Training Data",
    "Train Adapter",
    "Train Draft Model", 
    "Export Adapter",
    "Run Full Pipeline",
    "Exit"
]

def print_banner():
    """Print the banner"""
    print(BANNER)

def print_menu():
    """Print interactive menu"""
    print("\n" + "─" * 50)
    print("What would you like to do?")
    print("─" * 50)
    for i, option in enumerate(MENU_OPTIONS, 1):
        print(f"  [{i}] {option}")
    print("─" * 50)

def main():
    print_banner()
    
    while True:
        print_menu()
        try:
            choice = input("\nEnter your choice (1-6): ").strip()
            
            if choice == "1":
                print("\n▶ Generating training data...")
            elif choice == "2":
                print("\n▶ Training adapter...")
            elif choice == "3":
                print("\n▶ Training draft model...")
            elif choice == "4":
                print("\n▶ Exporting adapter...")
            elif choice == "5":
                print("\n▶ Running full pipeline...")
            elif choice == "6":
                print("\nGoodbye!")
                break
            else:
                print("\n❌ Invalid choice. Please enter 1-6.")
                continue
                
        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            print(f"\n❌ Error: {e}")

if __name__ == "__main__":
    main()
