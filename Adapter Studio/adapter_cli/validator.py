"""Validation utilities for toolkit integrity"""

from pathlib import Path


REQUIRED_DIRS = ["assets", "examples", "export"]
REQUIRED_FILES = ["requirements.txt"]
REQUIRED_ASSETS = ["base-model.pt", "tokenizer.model", "checkpoint_spec.yaml"]


def validate_toolkit(toolkit_path: Path) -> tuple[bool, list[str]]:
    """
    Validate toolkit structure.
    
    Returns: (is_valid, list_of_errors)
    """
    errors = []
    
    if not toolkit_path.exists():
        errors.append(f"Toolkit path does not exist: {toolkit_path}")
        return False, errors
    
    if not toolkit_path.is_dir():
        errors.append(f"Toolkit path is not a directory: {toolkit_path}")
        return False, errors
    
    # Check required directories
    for dir_name in REQUIRED_DIRS:
        dir_path = toolkit_path / dir_name
        if not dir_path.exists():
            errors.append(f"Missing directory: {dir_name}/")
        elif not dir_path.is_dir():
            errors.append(f"{dir_name}/ exists but is not a directory")
    
    # Check required files
    for file_name in REQUIRED_FILES:
        file_path = toolkit_path / file_name
        if not file_path.exists():
            errors.append(f"Missing file: {file_name}")
    
    # Check required assets
    assets_path = toolkit_path / "assets"
    if assets_path.exists():
        for asset_name in REQUIRED_ASSETS:
            asset_path = assets_path / asset_name
            if not asset_path.exists():
                errors.append(f"Missing asset: assets/{asset_name}")
    
    return len(errors) == 0, errors
