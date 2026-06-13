"""Auto-discovery of toolkit in common locations"""

from pathlib import Path

from .validator import validate_toolkit


COMMON_LOCATIONS = [
    Path.home() / "Downloads",
    Path.home() / "adapter-toolkit",
    Path("/opt/adapter-toolkit"),
]


def find_toolkit() -> Path | None:
    """
    Search common locations for a valid toolkit.
    
    Returns: Path to toolkit or None if not found
    """
    for location in COMMON_LOCATIONS:
        if not location.exists():
            continue
        
        # Check if location is the toolkit itself
        is_valid, _ = validate_toolkit(location)
        if is_valid:
            return location
        
        # Check subdirectories (e.g., ~/Downloads/adapter_training_toolkit_v26_0_0)
        if location.is_dir():
            for subdir in location.iterdir():
                if not subdir.is_dir():
                    continue
                
                # Look for adapter_training_toolkit* pattern
                if "adapter_training_toolkit" in subdir.name or "adapter-toolkit" in subdir.name:
                    is_valid, _ = validate_toolkit(subdir)
                    if is_valid:
                        return subdir
    
    return None
