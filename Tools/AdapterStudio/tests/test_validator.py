import sys
import tempfile
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from adapter_cli.validator import validate_toolkit


class ValidatorTests(unittest.TestCase):
    def test_complete_toolkit_is_valid(self):
        with tempfile.TemporaryDirectory() as directory:
            toolkit = self.make_toolkit(Path(directory))

            is_valid, errors = validate_toolkit(toolkit)

            self.assertTrue(is_valid)
            self.assertEqual(errors, [])

    def test_missing_asset_is_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            toolkit = self.make_toolkit(Path(directory))
            (toolkit / "assets" / "tokenizer.model").unlink()

            is_valid, errors = validate_toolkit(toolkit)

            self.assertFalse(is_valid)
            self.assertIn(
                "Missing asset: assets/tokenizer.model",
                errors,
            )

    def make_toolkit(self, root: Path) -> Path:
        for directory in ("assets", "examples", "export"):
            (root / directory).mkdir()

        (root / "requirements.txt").touch()
        for asset in (
            "base-model.pt",
            "tokenizer.model",
            "checkpoint_spec.yaml",
        ):
            (root / "assets" / asset).touch()

        return root


if __name__ == "__main__":
    unittest.main()
