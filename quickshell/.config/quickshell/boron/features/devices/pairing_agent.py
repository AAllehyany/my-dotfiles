#!/usr/bin/env python3
"""Temporary BlueZ Agent1, registered only while pairing from Boron."""
import json
import sys
import threading

from gi.repository import Gio, GLib

XML = '''<node><interface name="org.bluez.Agent1">
<method name="Release"/><method name="Cancel"/>
<method name="RequestPinCode"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
<method name="DisplayPinCode"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="RequestPasskey"><arg type="o" direction="in"/><arg type="u" direction="out"/></method>
<method name="DisplayPasskey"><arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/></method>
<method name="RequestConfirmation"><arg type="o" direction="in"/><arg type="u" direction="in"/></method>
<method name="RequestAuthorization"><arg type="o" direction="in"/></method>
<method name="AuthorizeService"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
</interface></node>'''


class Agent:
    path = "/org/boron/PairingAgent"

    def __init__(self):
        self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        self.pending = None
        self.device = None
        self.registered = False
        self.kind = None
        self.bus.register_object(self.path, Gio.DBusNodeInfo.new_for_xml(XML).interfaces[0], self.method, None, None)

    def emit(self, **message):
        print(json.dumps(message), flush=True)

    def call(self, path, interface, method, args=None):
        return self.bus.call_sync("org.bluez", path, interface, method, args, None, Gio.DBusCallFlags.NONE, 5000, None)

    def unregister(self):
        if self.registered:
            try:
                self.call("/org/bluez", "org.bluez.AgentManager1", "UnregisterAgent", GLib.Variant("(o)", (self.path,)))
            except GLib.Error:
                pass
            self.registered = False

    def cancel(self):
        if self.pending:
            self.pending.return_dbus_error("org.bluez.Error.Canceled", "Pairing dismissed")
            self.pending = None
        if self.device:
            self.bus.call("org.bluez", self.device, "org.bluez.Device1", "CancelPairing", None, None,
                          Gio.DBusCallFlags.NONE, 5000, None, None)
        self.device = None
        self.unregister()

    def method(self, bus, sender, path, interface, method, parameters, invocation):
        args = parameters.unpack()
        if method in ("Cancel", "Release"):
            self.cancel()
            invocation.return_value(None)
            self.emit(type="done", error="Pairing canceled")
            return
        if not self.device or args[0] != self.device:
            invocation.return_dbus_error("org.bluez.Error.Rejected", "No pairing requested for this device")
            return
        if method.startswith("Display"):
            code = str(args[1]) if method == "DisplayPinCode" else f"{args[1]:06d}"
            self.emit(type="prompt", message="Enter on your device: " + code, displayOnly=True)
            invocation.return_value(None)
            return
        if self.pending:
            invocation.return_dbus_error("org.bluez.Error.Rejected", "Another prompt is active")
            return
        self.pending, self.kind = invocation, method
        if method in ("RequestPinCode", "RequestPasskey"):
            self.emit(type="prompt", message="Enter the code shown on your device.", field="PIN" if method == "RequestPinCode" else "Passkey")
        else:
            message = f"Does {args[1]:06d} match your device?" if method == "RequestConfirmation" else "Allow this device to pair?"
            self.emit(type="prompt", message=message)

    def done(self, bus, result, device):
        if device != self.device:
            return
        error = None
        try:
            bus.call_finish(result)
        except GLib.Error as exc:
            error = str(exc)
        if self.pending:
            self.pending.return_dbus_error("org.bluez.Error.Canceled", "Pairing ended")
            self.pending = None
        self.device = None
        self.unregister()
        self.emit(type="done", error=error)

    def receive(self, message):
        try:
            method = message.get("method")
            if method == "pair":
                self.cancel()
                self.call("/org/bluez", "org.bluez.AgentManager1", "RegisterAgent", GLib.Variant("(os)", (self.path, "KeyboardDisplay")))
                self.registered = True
                self.device = message["path"]
                # Pair from this D-Bus connection so BlueZ uses this agent, without replacing the session default.
                self.bus.call("org.bluez", self.device, "org.bluez.Device1", "Pair", None, None,
                              Gio.DBusCallFlags.NONE, 120000, None, self.done, self.device)
            elif method == "answer" and self.pending:
                value = message.get("value", "")
                if self.kind == "RequestPasskey":
                    if not str(value).isdigit() or not 0 <= int(value) <= 999999:
                        raise ValueError("Passkey must be 0–999999")
                    response = GLib.Variant("(u)", (int(value),))
                elif self.kind == "RequestPinCode":
                    if not 1 <= len(value) <= 16:
                        raise ValueError("PIN must contain 1–16 characters")
                    response = GLib.Variant("(s)", (value,))
                else:
                    response = None
                self.pending.return_value(response)
                self.pending = None
            elif method == "cancel":
                self.cancel()
        except (GLib.Error, ValueError, KeyError) as exc:
            self.cancel()
            self.emit(type="error", message=str(exc))
        return False


def main():
    loop = GLib.MainLoop()
    agent = Agent()
    def reader():
        for line in sys.stdin:
            try:
                GLib.idle_add(agent.receive, json.loads(line))
            except ValueError:
                pass
        GLib.idle_add(agent.cancel)
        GLib.idle_add(loop.quit)
    threading.Thread(target=reader, daemon=True).start()
    agent.emit(type="ready")
    loop.run()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print(json.dumps({"type": "error", "message": "Cannot start pairing agent. Check BlueZ, D-Bus and python3-gobject."}), flush=True)
        sys.exit(1)
