"""Real notifications and signals, isolated from the user's desktop bus.

Run explicitly: python3 tests/test_notifications_bus.py
Not discovered by unittest: this check requires Quickshell, D-Bus and Gio.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time


def run_session():
    from gi.repository import Gio, GLib

    harness = Path(__file__).resolve().parent.parent / "notification-bus-smoke.qml"
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    # Occupy the name first to test conflict reporting and automatic handover.
    bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                  "RequestName", GLib.Variant("(su)", ("org.freedesktop.Notifications", 0)),
                  None, Gio.DBusCallFlags.NONE, 2000, None)
    events = []
    bus.signal_subscribe(
        None, "org.freedesktop.Notifications", None, "/org/freedesktop/Notifications",
        None, Gio.DBusSignalFlags.NONE,
        lambda conn, sender, path, interface, signal, parameters, data:
            events.append((signal, parameters.unpack())), None,
    )

    def call(method, signature="()", args=()):
        return bus.call_sync(
            "org.freedesktop.Notifications", "/org/freedesktop/Notifications",
            "org.freedesktop.Notifications", method, GLib.Variant(signature, args),
            None, Gio.DBusCallFlags.NONE, 2000, None,
        ).unpack()

    def notify(title, *, replace=0, actions=(), hints=None, timeout=-1):
        return call("Notify", "(susssasa{sv}i)",
                    ("Boron test", replace, "", title, "Native body", list(actions), hints or {}, timeout))[0]

    def ipc(method, *args):
        result = subprocess.run(
            ["qs", "-p", str(harness), "ipc", "call", "notificationTest", method, *map(str, args)],
            capture_output=True, text=True, timeout=3, check=True,
        )
        return result.stdout.strip()

    def snapshot():
        return json.loads(ipc("snapshot"))

    def wait_for(predicate, timeout=4):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            while GLib.MainContext.default().pending():
                GLib.MainContext.default().iteration(False)
            try:
                value = predicate()
                if value:
                    return value
            except (subprocess.CalledProcessError, json.JSONDecodeError, GLib.Error):
                pass
            time.sleep(0.025)
        raise AssertionError("Timed out waiting for notification state")

    with tempfile.TemporaryDirectory(prefix="boron-notification-bus-") as runtime:
        env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=runtime, QS_NO_RELOAD_POPUP="1")
        env.pop("WAYLAND_DISPLAY", None)
        # All qs IPC clients must use the same private runtime directory.
        os.environ.update(QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=runtime)
        os.environ.pop("WAYLAND_DISPLAY", None)
        with tempfile.TemporaryFile(mode="w+") as log:
            process = subprocess.Popen(["qs", "-p", str(harness), "--no-color"], env=env,
                                       stdout=log, stderr=subprocess.STDOUT)
            try:
                wait_for(snapshot)
                wait_for(lambda: "Another notification daemon" in snapshot()["error"])
                bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                              "ReleaseName", GLib.Variant("(s)", ("org.freedesktop.Notifications",)),
                              None, Gio.DBusCallFlags.NONE, 2000, None)
                wait_for(lambda: snapshot()["error"] == "", timeout=6)
                assert call("GetServerInformation")[0] == "quickshell"
                capabilities = call("GetCapabilities")[0]
                assert {"body", "actions", "persistence", "icon-static"} <= set(capabilities)
                assert "body-markup" not in capabilities and "inline-reply" not in capabilities

                picture = notify("Image data", hints={"image-data": GLib.Variant("(iiibiiay)",
                    (1, 1, 4, True, 8, 4, [255, 128, 0, 255]))})
                assert snapshot()["entries"][0]["image"].startswith("image://")
                ipc("dismiss", picture)

                first = notify("First", actions=("default", "Open", "reply", "Reply"), timeout=0)
                wait_for(lambda: len(snapshot()["entries"]) == 1 and snapshot()["entries"][0]["toast"])
                replaced = notify("Updated", replace=first, actions=("default", "Open"), timeout=500)
                assert replaced == first
                wait_for(lambda: snapshot()["entries"][0]["title"] == "Updated")
                time.sleep(3.1)
                history = snapshot()["entries"]
                assert len(history) == 1 and not history[0]["toast"] and history[0]["unread"]
                ipc("activate", first, "default")
                wait_for(lambda: ("ActionInvoked", (first, "default")) in events)
                wait_for(lambda: ("NotificationClosed", (first, 2)) in events)
                assert not snapshot()["entries"]

                resident = notify("Resident", actions=("reply", "Reply"), hints={"resident": GLib.Variant("b", True)})
                ipc("activate", resident, "reply")
                wait_for(lambda: ("ActionInvoked", (resident, "reply")) in events)
                wait_for(lambda: ("NotificationClosed", (resident, 2)) in events)
                assert not snapshot()["entries"]

                transient = notify("Transient", hints={"transient": GLib.Variant("b", True)})
                wait_for(lambda: ("NotificationClosed", (transient, 1)) in events)
                assert not snapshot()["entries"]

                withdrawn = notify("Withdrawn")
                call("CloseNotification", "(u)", (withdrawn,))
                wait_for(lambda: ("NotificationClosed", (withdrawn, 3)) in events)
                assert not snapshot()["entries"]

                reloaded = notify("Keep across reload", actions=("default", "Open"))
                wait_for(lambda: snapshot()["entries"] and snapshot()["entries"][0]["toast"])
                original_timestamp = snapshot()["entries"][0]["receivedAt"]
                ipc("reload")
                try:
                    wait_for(lambda: len(snapshot()["entries"]) == 1 and not snapshot()["entries"][0]["unread"])
                except AssertionError:
                    print("Reload snapshot:", snapshot(), file=sys.stderr)
                    raise
                state = snapshot()
                assert state["entries"][0]["id"] == reloaded and not state["entries"][0]["toast"]
                assert state["entries"][0]["receivedAt"] == original_timestamp
                ipc("activate", reloaded, "default")
                wait_for(lambda: ("ActionInvoked", (reloaded, "default")) in events)
                assert not snapshot()["entries"]

                ipc("center", "true")
                suppressed = notify("Center only")
                time.sleep(0.1)
                assert snapshot()["entries"][0]["id"] == suppressed and not snapshot()["entries"][0]["toast"]
                ipc("clear")
                wait_for(lambda: ("NotificationClosed", (suppressed, 2)) in events)
                assert not snapshot()["entries"]
                print("NOTIFICATION BUS CHECKS PASSED")
            finally:
                process.terminate()
                process.wait(timeout=5)
                log.seek(0)
                output = log.read()
                if sys.exc_info()[0] is not None:
                    print(output, file=sys.stderr)
                if "ERROR" in output or "TypeError" in output or "ReferenceError" in output:
                    print(output, file=sys.stderr)
                    raise AssertionError("Quickshell logged an error")


if __name__ == "__main__":
    if "--session" in sys.argv:
        run_session()
    else:
        # Omit service directories so no desktop daemon can be auto-activated.
        with tempfile.TemporaryDirectory(prefix="boron-private-bus-") as directory:
            config = Path(directory) / "session.conf"
            config.write_text('''<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen>
<policy context="default"><allow send_destination="*"/><allow receive_sender="*"/>
<allow own="*"/></policy></busconfig>''')
            result = subprocess.run(["dbus-run-session", "--config-file=" + str(config), "--",
                                     sys.executable, __file__, "--session"])
            raise SystemExit(result.returncode)
