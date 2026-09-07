"""Regression tests for Kerma Python CLI entry point and help formatting."""

import io
import sys
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch
from kerma import cli


class TestCLI(unittest.TestCase):
    def test_cli_execution_and_help_rendering(self):
        # Verify standard execution completes cleanly
        buf = io.StringIO()
        with patch.object(sys, "argv", ["kerma.cli", "--phantom", "water", "--mu", "100"]), redirect_stdout(buf):
            cli.main()
        output = buf.getvalue()
        self.assertIn("Maximum Absorbed Dose", output)
        self.assertIn("Passing Rate:", output)

    def test_cli_help_flag_does_not_fail_percent_escape(self):
        # Regression test for argparse ValueError on unescaped '%' in help text
        buf = io.StringIO()
        with patch.object(sys, "argv", ["kerma.cli", "--help"]), redirect_stdout(buf):
            with self.assertRaises(SystemExit) as cm:
                cli.main()
            self.assertEqual(cm.exception.code, 0)
        self.assertIn("Gamma dose difference criterion", buf.getvalue())


if __name__ == "__main__":
    unittest.main()
