import importlib.util
from pathlib import Path
import unittest
from unittest.mock import Mock

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("pairing", ROOT / "features/devices/pairing_agent.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PairingTests(unittest.TestCase):
    def setUp(self):
        self.agent = module.Agent.__new__(module.Agent)
        self.agent.device = "/org/bluez/hci0/dev_test"
        self.agent.pending = None
        self.agent.kind = None
        self.agent.registered = False
        self.agent.emit = Mock()
        self.agent.bus = Mock()

    def test_unrequested_device_rejected(self):
        invocation = Mock()
        self.agent.method(None, None, None, None, "RequestConfirmation", module.GLib.Variant("(ou)", ("/other", 123456)), invocation)
        invocation.return_dbus_error.assert_called_once()
        self.agent.emit.assert_not_called()

    def test_confirmation_and_answer(self):
        invocation = Mock()
        self.agent.method(None, None, None, None, "RequestConfirmation", module.GLib.Variant("(ou)", (self.agent.device, 123456)), invocation)
        self.assertIn("123456", self.agent.emit.call_args.kwargs["message"])
        self.agent.receive({"method": "answer"})
        invocation.return_value.assert_called_once_with(None)

    def test_invalid_passkey_cancels(self):
        invocation = Mock()
        self.agent.pending, self.agent.kind = invocation, "RequestPasskey"
        self.agent.receive({"method": "answer", "value": "1000000"})
        invocation.return_dbus_error.assert_called_once()
        self.assertIsNone(self.agent.device)
        self.assertEqual(self.agent.emit.call_args.kwargs["type"], "error")

    def test_cancel_rejects_outstanding_prompt(self):
        invocation = Mock()
        self.agent.pending = invocation
        self.agent.cancel()
        invocation.return_dbus_error.assert_called_once()
        self.assertIsNone(self.agent.pending)


if __name__ == "__main__":
    unittest.main()
