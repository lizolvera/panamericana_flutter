from pathlib import Path
from subprocess import CompletedProcess
from unittest import TestCase
from unittest.mock import patch
from run_maestro import run_guest, start_guest, APP


class MaestroRecoveryTests(TestCase):
    def execute(self, outcomes):
        commands = []

        def run(command, **_):
            commands.append(command)
            if command[0] == "maestro":
                status, text = outcomes.pop(0)
                return CompletedProcess(command, status, text, "")
            if "clear" in command:
                return CompletedProcess(command, 0, "Success", "")
            if "start" in command:
                return CompletedProcess(command, 0, "Starting: Intent { cmp=app/.MainActivity }", "")
            return CompletedProcess(command, 0, "1", "")

        with patch.object(Path, "glob", return_value=[]):
            code = run_guest("maestro", run=run, sleep=lambda _: None, output=lambda _: None)
        return code, commands

    def test_success_needs_no_retry(self):
        code, commands = self.execute([(0, "passed")])
        self.assertEqual(code, 0)
        self.assertEqual(sum(c[0] == "maestro" for c in commands), 1)
        clear = ["adb", "-s", "emulator-5554", "shell", "pm", "clear", APP]
        self.assertLess(commands.index(clear), next(i for i,c in enumerate(commands) if c[0] == "maestro"))

    def test_clear_failure_blocks_flow(self):
        def run(command, **_):
            return CompletedProcess(command, 0, "Failed" if "clear" in command else "", "")
        self.assertFalse(start_guest(run, lambda _: None))

    def test_android_start_error_blocks_flow_even_with_zero_exit(self):
        def run(command, **_):
            return CompletedProcess(command, 0, "Success" if "clear" in command else "Starting: Intent\nError: Activity not found", "")
        self.assertFalse(start_guest(run, lambda _: None))

    def test_assertion_failure_is_not_retried(self):
        code, commands = self.execute([(1, "Assertion failed: button not found")])
        self.assertEqual(code, 1)
        self.assertEqual(sum(c[0] == "maestro" for c in commands), 1)

    def test_offline_transport_can_recover_once(self):
        code, commands = self.execute([(1, "device offline"), (0, "passed")])
        self.assertEqual(code, 0)
        self.assertIn(["adb", "reconnect", "offline"], commands)

    def test_persistent_offline_still_fails(self):
        code, commands = self.execute([(1, "device offline"), (1, "device offline")])
        self.assertEqual(code, 1)
        self.assertEqual(sum(c[0] == "maestro" for c in commands), 2)
