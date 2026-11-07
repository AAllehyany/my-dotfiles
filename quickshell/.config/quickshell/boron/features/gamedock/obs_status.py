#!/usr/bin/env python3
"""Stream OBS recording/streaming status as JSON lines for Boron's game dock.

Talks obs-websocket v5 (built into OBS 28+) on localhost with the standard library only.
The port and password come from OBS's own websocket config, so nothing needs setting up
beyond enabling the server in OBS (Tools > WebSocket Server Settings).

Every second, while connected, it prints one line:
    {"connected": true, "recording": bool, "recordPaused": bool, "recordMs": int,
     "streaming": bool, "streamMs": int, "reconnecting": bool}
Otherwise it prints {"connected": false, "reason": "..."} and retries every 5 seconds.
Reasons: "no-config", "disabled" (server off in OBS), "closed" (OBS not running), "auth" (wrong password).
"""

import base64
import hashlib
import json
import os
import select
import socket
import struct
import sys
import time
from pathlib import Path

CONFIG_PATHS = [
    Path.home() / ".var/app/com.obsproject.Studio/config/obs-studio/plugin_config/obs-websocket/config.json",
    Path.home() / ".config/obs-studio/plugin_config/obs-websocket/config.json",
]
OUTPUTS_EVENTS = 1 << 6  # obs-websocket EventSubscription.Outputs
POLL_SECONDS = 1.0
RETRY_SECONDS = 5.0


class ObsError(Exception):
    """A reason the dock shows instead of the status."""


def emit(payload: dict) -> None:
    print(json.dumps(payload, separators=(",", ":")), flush=True)


def load_config(paths=CONFIG_PATHS) -> dict:
    for path in paths:
        try:
            return json.loads(Path(path).read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
    raise ObsError("no-config")


def auth_string(password: str, salt: str, challenge: str) -> str:
    """obs-websocket v5: base64(sha256(base64(sha256(password + salt)) + challenge))."""
    secret = base64.b64encode(hashlib.sha256((password + salt).encode()).digest()).decode()
    return base64.b64encode(hashlib.sha256((secret + challenge).encode()).digest()).decode()


# ---------- minimal WebSocket client (RFC 6455, text frames) ----------

def encode_frame(text: str, opcode: int = 0x1) -> bytes:
    payload = text.encode()
    header = bytes([0x80 | opcode])
    length = len(payload)
    if length < 126:
        header += bytes([0x80 | length])
    elif length < 1 << 16:
        header += bytes([0x80 | 126]) + struct.pack("!H", length)
    else:
        header += bytes([0x80 | 127]) + struct.pack("!Q", length)
    mask = os.urandom(4)
    return header + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(payload))


class WebSocket:
    def __init__(self, host: str, port: int, timeout: float = 3.0):
        self.sock = socket.create_connection((host, port), timeout=timeout)
        self.buffer = b""
        key = base64.b64encode(os.urandom(16)).decode()
        self.sock.sendall((
            f"GET / HTTP/1.1\r\nHost: {host}:{port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n"
            "Sec-WebSocket-Protocol: obswebsocket.json\r\n\r\n"
        ).encode())
        while b"\r\n\r\n" not in self.buffer:
            self._fill()
        head, self.buffer = self.buffer.split(b"\r\n\r\n", 1)
        if b" 101 " not in head.split(b"\r\n", 1)[0]:
            raise ObsError("closed")

    def _fill(self) -> None:
        chunk = self.sock.recv(65536)
        if not chunk:
            raise ObsError("closed")
        self.buffer += chunk

    def _take(self, count: int) -> bytes:
        while len(self.buffer) < count:
            self._fill()
        data, self.buffer = self.buffer[:count], self.buffer[count:]
        return data

    def send(self, message: dict) -> None:
        self.sock.sendall(encode_frame(json.dumps(message)))

    def pending(self, timeout: float) -> bool:
        return bool(self.buffer) or bool(select.select([self.sock], [], [], timeout)[0])

    def recv(self) -> dict:
        """Next JSON message. Answers pings; a close frame raises with its close code."""
        message = b""
        while True:
            first, second = self._take(2)
            opcode, length = first & 0x0F, second & 0x7F
            if length == 126:
                length = struct.unpack("!H", self._take(2))[0]
            elif length == 127:
                length = struct.unpack("!Q", self._take(8))[0]
            mask = self._take(4) if second & 0x80 else None
            payload = self._take(length)
            if mask:
                payload = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
            if opcode == 0x8:
                code = struct.unpack("!H", payload[:2])[0] if len(payload) >= 2 else 1000
                raise ObsError("auth" if code == 4009 else "closed")
            if opcode == 0x9:
                self.sock.sendall(encode_frame(payload.decode(errors="replace"), 0xA))
                continue
            if opcode in (0x1, 0x0):
                message += payload
                if first & 0x80:
                    return json.loads(message)

    def close(self) -> None:
        try:
            self.sock.close()
        except OSError:
            pass


# ---------- obs-websocket session ----------

def connect(config: dict) -> WebSocket:
    if not config.get("server_enabled", False):
        raise ObsError("disabled")
    try:
        ws = WebSocket("127.0.0.1", int(config.get("server_port", 4455)))
    except OSError:
        raise ObsError("closed")
    hello = ws.recv()
    identify = {"rpcVersion": 1, "eventSubscriptions": OUTPUTS_EVENTS}
    challenge = (hello.get("d") or {}).get("authentication")
    if challenge:
        identify["authentication"] = auth_string(
            str(config.get("server_password", "")), challenge["salt"], challenge["challenge"]
        )
    ws.send({"op": 1, "d": identify})
    while ws.recv().get("op") != 2:  # Identified
        pass
    return ws


def status_from(responses: dict) -> dict:
    record = responses.get("GetRecordStatus", {})
    stream = responses.get("GetStreamStatus", {})
    return {
        "connected": True,
        "recording": bool(record.get("outputActive")),
        "recordPaused": bool(record.get("outputPaused")),
        "recordMs": int(record.get("outputDuration") or 0),
        "streaming": bool(stream.get("outputActive")),
        "streamMs": int(stream.get("outputDuration") or 0),
        "reconnecting": bool(stream.get("outputReconnecting")),
    }


def poll(ws: WebSocket, request_id: int) -> dict:
    """Ask for both statuses; events in between just make the next poll come sooner."""
    wanted = {}
    for kind in ("GetRecordStatus", "GetStreamStatus"):
        request_id += 1
        wanted[str(request_id)] = kind
        ws.send({"op": 6, "d": {"requestType": kind, "requestId": str(request_id)}})
    responses = {}
    deadline = time.monotonic() + 3
    while len(responses) < len(wanted):
        if time.monotonic() > deadline:
            raise ObsError("closed")
        message = ws.recv()
        data = message.get("d") or {}
        if message.get("op") == 7 and data.get("requestId") in wanted:
            responses[wanted[data["requestId"]]] = data.get("responseData") or {}
    return status_from(responses)


def session(config: dict) -> None:
    ws = connect(config)
    try:
        request_id = 0
        while True:
            emit(poll(ws, request_id))
            request_id += 2
            # Wait out the second, but wake early on a record/stream state change.
            deadline = time.monotonic() + POLL_SECONDS
            while (remaining := deadline - time.monotonic()) > 0:
                if ws.pending(remaining):
                    message = ws.recv()
                    if message.get("op") == 5 and "StateChanged" in (message.get("d") or {}).get("eventType", ""):
                        break
    finally:
        ws.close()


def main() -> None:
    while True:
        try:
            session(load_config())
        except ObsError as error:
            emit({"connected": False, "reason": str(error)})
        except (OSError, ValueError, KeyError):
            emit({"connected": False, "reason": "closed"})
        time.sleep(RETRY_SECONDS)


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
