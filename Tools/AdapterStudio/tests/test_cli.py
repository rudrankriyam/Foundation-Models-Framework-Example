import io
import sys
import tempfile
import unittest
from pathlib import Path
from subprocess import CalledProcessError, CompletedProcess
from types import SimpleNamespace
from unittest.mock import patch

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from adapter_cli import EXIT_FAILURE, EXIT_SUCCESS, EXIT_USAGE
from adapter_cli import __main__ as cli
from adapter_cli.commands.demo import run_demo
from adapter_cli.commands.export import run_export
from adapter_cli.commands.generate import run_generate
from adapter_cli.commands.init import run_init
from adapter_cli.commands.setup import run_setup
from adapter_cli.commands.train_adapter import run_train_adapter
from adapter_cli.commands.train_draft import run_train_draft


class CLITests(unittest.TestCase):
    def setUp(self):
        self.parser = cli.create_parser()

    def test_parser_uses_fmas_program_name(self):
        self.assertEqual(self.parser.prog, "fmas")

    def test_main_returns_usage_when_command_is_missing(self):
        with patch.object(cli, "print_banner"), patch(
            "sys.stdout",
            new_callable=io.StringIO,
        ):
            self.assertEqual(cli.main([]), EXIT_USAGE)

    def test_main_propagates_command_status(self):
        with patch.object(cli, "print_banner"), patch.object(
            cli,
            "run_setup",
            return_value=9,
        ):
            self.assertEqual(cli.main(["setup"]), 9)

    def test_commands_fail_when_toolkit_is_not_configured(self):
        cases = [
            (
                "adapter_cli.commands.demo.get_toolkit_path",
                run_demo,
                self.parser.parse_args(["demo", "--prompt", "Hello"]),
            ),
            (
                "adapter_cli.commands.generate.get_toolkit_path",
                run_generate,
                self.parser.parse_args(["generate", "--prompt", "Hello"]),
            ),
            (
                "adapter_cli.commands.export.get_toolkit_path",
                run_export,
                self.parser.parse_args(
                    [
                        "export",
                        "--adapter-name",
                        "example",
                        "--checkpoint",
                        "/tmp/checkpoint",
                        "--output-dir",
                        "/tmp/output",
                    ]
                ),
            ),
            (
                "adapter_cli.commands.train_adapter.get_toolkit_path",
                run_train_adapter,
                self.parser.parse_args(["train-adapter"]),
            ),
            (
                "adapter_cli.commands.train_draft.get_toolkit_path",
                run_train_draft,
                self.parser.parse_args(
                    [
                        "train-draft",
                        "--train-data",
                        "/tmp/train.jsonl",
                        "--checkpoint-dir",
                        "/tmp/checkpoints",
                    ]
                ),
            ),
        ]

        for patch_target, command, arguments in cases:
            with self.subTest(command=arguments.command), patch(
                patch_target,
                return_value=None,
            ), patch("sys.stdout", new_callable=io.StringIO):
                self.assertEqual(command(arguments), EXIT_FAILURE)

        with patch(
            "adapter_cli.commands.setup.get_toolkit_path",
            return_value=None,
        ), patch("sys.stdout", new_callable=io.StringIO):
            self.assertEqual(run_setup(), EXIT_FAILURE)

    def test_demo_propagates_toolkit_process_status(self):
        with tempfile.TemporaryDirectory() as directory:
            toolkit = Path(directory)
            python = toolkit / "venv" / "bin" / "python"
            python.parent.mkdir(parents=True)
            python.touch()
            arguments = self.parser.parse_args(
                ["demo", "--prompt", "Hello"]
            )

            with patch(
                "adapter_cli.commands.demo.get_toolkit_path",
                return_value=toolkit,
            ), patch(
                "adapter_cli.commands.demo.subprocess.run",
                return_value=SimpleNamespace(returncode=7),
            ), patch("sys.stdout", new_callable=io.StringIO):
                self.assertEqual(run_demo(arguments), 7)

    def test_setup_fails_when_dependency_validation_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            toolkit = Path(directory)
            (toolkit / "requirements.txt").touch()
            successful_run = CompletedProcess(args=[], returncode=0)
            validation_error = CalledProcessError(
                returncode=1,
                cmd=[],
                stderr="missing dependency",
            )

            with patch(
                "adapter_cli.commands.setup.get_toolkit_path",
                return_value=toolkit,
            ), patch(
                "adapter_cli.commands.setup.subprocess.run",
                side_effect=[
                    successful_run,
                    successful_run,
                    validation_error,
                ],
            ), patch("sys.stdout", new_callable=io.StringIO):
                self.assertEqual(run_setup(), EXIT_FAILURE)

    def test_setup_reuses_existing_virtual_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            toolkit = Path(directory)
            (toolkit / "requirements.txt").touch()
            python = toolkit / "venv" / "bin" / "python"
            python.parent.mkdir(parents=True)
            python.touch()
            successful_run = CompletedProcess(args=[], returncode=0)

            with patch(
                "adapter_cli.commands.setup.get_toolkit_path",
                return_value=toolkit,
            ), patch(
                "adapter_cli.commands.setup.subprocess.run",
                side_effect=[successful_run, successful_run],
            ) as run, patch("sys.stdout", new_callable=io.StringIO):
                self.assertEqual(run_setup(), EXIT_SUCCESS)
                self.assertEqual(run.call_count, 2)
                self.assertEqual(
                    run.call_args_list[0].args[0][:3],
                    [str(python), "-m", "pip"],
                )

    def test_init_keeps_existing_configuration_successfully(self):
        with patch(
            "adapter_cli.commands.init.get_toolkit_path",
            return_value=Path("/tmp/toolkit"),
        ), patch("builtins.input", return_value="n"), patch(
            "sys.stdout",
            new_callable=io.StringIO,
        ):
            self.assertEqual(run_init(), EXIT_SUCCESS)

    def test_init_reports_cancelled_manual_setup_as_failure(self):
        with patch(
            "adapter_cli.commands.init.get_toolkit_path",
            return_value=None,
        ), patch(
            "adapter_cli.commands.init.find_toolkit",
            return_value=None,
        ), patch(
            "builtins.input",
            side_effect=EOFError,
        ), patch("sys.stdout", new_callable=io.StringIO):
            self.assertEqual(run_init(), EXIT_FAILURE)

    def test_init_reports_cancelled_existing_setup_as_failure(self):
        with patch(
            "adapter_cli.commands.init.get_toolkit_path",
            return_value=Path("/tmp/toolkit"),
        ), patch(
            "builtins.input",
            side_effect=KeyboardInterrupt,
        ), patch("sys.stdout", new_callable=io.StringIO):
            self.assertEqual(run_init(), EXIT_FAILURE)

    def test_invalid_training_range_returns_usage_error(self):
        arguments = self.parser.parse_args(
            ["train-adapter", "--epochs", "0"]
        )

        with patch("sys.stdout", new_callable=io.StringIO):
            self.assertEqual(run_train_adapter(arguments), EXIT_USAGE)


if __name__ == "__main__":
    unittest.main()
