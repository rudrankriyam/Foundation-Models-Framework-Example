import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from adapter_cli import config


class ConfigTests(unittest.TestCase):
    def test_config_round_trip_uses_atomic_file(self):
        with tempfile.TemporaryDirectory() as directory:
            config_directory = Path(directory) / "config"
            config_file = config_directory / "config.json"

            with patch.object(config, "CONFIG_DIR", config_directory), patch.object(
                config,
                "CONFIG_FILE",
                config_file,
            ):
                config.save_config({"toolkit_path": "/tmp/toolkit"})

                self.assertEqual(
                    config.load_config(),
                    {"toolkit_path": "/tmp/toolkit"},
                )
                self.assertEqual(list(config_directory.glob("*.tmp")), [])

    def test_corrupted_config_is_removed(self):
        with tempfile.TemporaryDirectory() as directory:
            config_directory = Path(directory) / "config"
            config_directory.mkdir()
            config_file = config_directory / "config.json"
            config_file.write_text("{invalid", encoding="utf-8")

            with patch.object(config, "CONFIG_DIR", config_directory), patch.object(
                config,
                "CONFIG_FILE",
                config_file,
            ):
                self.assertEqual(config.load_config(), {})
                self.assertFalse(config_file.exists())

    def test_saved_config_is_valid_json(self):
        with tempfile.TemporaryDirectory() as directory:
            config_directory = Path(directory) / "config"
            config_file = config_directory / "config.json"

            with patch.object(config, "CONFIG_DIR", config_directory), patch.object(
                config,
                "CONFIG_FILE",
                config_file,
            ):
                config.save_config({"toolkit_path": "/tmp/toolkit"})
                loaded = json.loads(config_file.read_text(encoding="utf-8"))

                self.assertEqual(loaded["toolkit_path"], "/tmp/toolkit")


if __name__ == "__main__":
    unittest.main()
