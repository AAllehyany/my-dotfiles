import base64
import hashlib
import json
from pathlib import Path
import socket
import struct
import sys
import tempfile
import threading
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "features/gamedock"))
import obs_status
from obs_status import ObsError, auth_string, connect, load_config, poll


def server_frame(text, opcode: int = 0x1) -> bytes:
    payload = text if isinstance(text, bytes) else text.encode()
    assert len(payload) < 1 << 16
    if len(payload) < 126:
        return bytes([0x80 | opcode, len(payload)]) + payload
    return bytes([0x80 | opcode, 126]) + struct.pack("!H", len(payload)) + payload


def read_client_frame(conn: socket.socket) -> dict:
    def take(n):
        data = b""
        while len(data) < n:
            chunk = conn.recv(n - len(data))
            if not chunk:
                raise ConnectionError
            data += chunk
        return data
    first, second = take(2)
    length = second & 0x7F
    if length == 126:
        length = struct.unpack("!H", take(2))[0]
    mask = take(4)
    payload = bytes(b ^ mask[i % 4] for i, b in enumerate(take(length)))
    return json.loads(payload)


class FakeObs(threading.Thread):
    """Just enough of obs-websocket v5 to authenticate and answer status requests."""

    def __init__(self, password="hunter2", record=None, stream=None):
        super().__init__(daemon=True)
        self.password = password
        self.record = record or {"outputActive": True, "outputPaused": False, "outputDuration": 4_000_123}
        self.stream = stream or {"outputActive": False, "outputDuration": 0, "outputReconnecting": False}
        self.listener = socket.socket()
        self.listener.bind(("127.0.0.1", 0))
        self.listener.listen(1)
        self.port = self.listener.getsockname()[1]
        self.identify = None

    def run(self):
        conn, _ = self.listener.accept()
        with conn:
            request = b""
            while b"\r\n\r\n" not in request:
                request += conn.recv(4096)
            assert b"Sec-WebSocket-Protocol: obswebsocket.json" in request
            conn.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                         b"Sec-WebSocket-Protocol: obswebsocket.json\r\n\r\n")
            salt, challenge = "c2FsdA==", "Y2hhbGxlbmdl"
            conn.sendall(server_frame(json.dumps({"op": 0, "d": {"rpcVersion": 1, "authentication": {
                "salt": salt, "challenge": challenge}}})))
            self.identify = read_client_frame(conn)
            # Server-side check, written out independently of obs_status.auth_string.
            secret = base64.b64encode(hashlib.sha256((self.password + salt).encode()).digest())
            expected = base64.b64encode(hashlib.sha256(secret + challenge.encode()).digest()).decode()
            if self.identify["d"].get("authentication") != expected:
                conn.sendall(server_frame(struct.pack("!H", 4009), 0x8))
                return
            conn.sendall(server_frame(json.dumps({"op": 2, "d": {"negotiatedRpcVersion": 1}})))
            conn.sendall(server_frame("", 0x9))  # a ping the client must answer and skip
            try:
                while True:
                    request = read_client_frame(conn)
                    if request.get("op") != 6:
                        continue
                    kind = request["d"]["requestType"]
                    data = self.record if kind == "GetRecordStatus" else self.stream
                    conn.sendall(server_frame(json.dumps({"op": 7, "d": {
                        "requestType": kind, "requestId": request["d"]["requestId"],
                        "requestStatus": {"result": True, "code": 100}, "responseData": data}})))
            except (ConnectionError, OSError):
                pass


def config_for(server, password="hunter2", enabled=True):
    return {"server_enabled": enabled, "server_port": server.port if server else 1, "server_password": password}


class ObsStatusTests(unittest.TestCase):
    def test_auth_string_matches_protocol(self):
        secret = base64.b64encode(hashlib.sha256(b"pwSALT").digest())
        expected = base64.b64encode(hashlib.sha256(secret + b"CHAL").digest()).decode()
        self.assertEqual(auth_string("pw", "SALT", "CHAL"), expected)

    def test_reads_status_after_authenticating(self):
        server = FakeObs()
        server.start()
        ws = connect(config_for(server))
        try:
            status = poll(ws, 0)
        finally:
            ws.close()
        self.assertEqual(server.identify["d"]["eventSubscriptions"], 64)
        self.assertEqual(status, {"connected": True, "recording": True, "recordPaused": False,
                                  "recordMs": 4_000_123, "streaming": False, "streamMs": 0,
                                  "reconnecting": False})

    def test_wrong_password_reports_auth(self):
        server = FakeObs(password="right")
        server.start()
        with self.assertRaisesRegex(ObsError, "auth"):
            ws = connect(config_for(server, password="wrong"))
            poll(ws, 0)

    def test_disabled_server_and_closed_obs(self):
        with self.assertRaisesRegex(ObsError, "disabled"):
            connect(config_for(None, enabled=False))
        free = socket.socket()
        free.bind(("127.0.0.1", 0))
        port = free.getsockname()[1]
        free.close()
        with self.assertRaisesRegex(ObsError, "closed"):
            connect({"server_enabled": True, "server_port": port, "server_password": ""})

    def test_config_prefers_flatpak_then_native(self):
        with tempfile.TemporaryDirectory() as tmp:
            flatpak, native = Path(tmp, "flatpak.json"), Path(tmp, "native.json")
            native.write_text(json.dumps({"server_port": 1111}))
            self.assertEqual(load_config([flatpak, native])["server_port"], 1111)
            flatpak.write_text(json.dumps({"server_port": 2222}))
            self.assertEqual(load_config([flatpak, native])["server_port"], 2222)
            with self.assertRaisesRegex(ObsError, "no-config"):
                load_config([Path(tmp, "missing.json")])

    def test_large_frames_round_trip(self):
        frame = obs_status.encode_frame("x" * 70000)
        self.assertEqual(frame[1] & 0x7F, 127)


if __name__ == "__main__":
    unittest.main()
