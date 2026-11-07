// Game dock checks: placement and visibility from niri events, stats parsing, recording status.
// Never starts niri, nvidia-smi or the OBS helper (their `running` stays false).
//   QT_QPA_PLATFORM=offscreen qs -p gamedock-smoke.qml --no-color
// BORON_DOCK_CAPTURE=1 (with GPU rendering, see README) saves /tmp/boron-gamedock-recording.png and -idle.png.
import QtQuick
import Quickshell
import "features/gamedock"

ShellRoot {
    id: test
    property int tick: 0
    readonly property bool capture: Quickshell.env("BORON_DOCK_CAPTURE") === "1"

    DockState { id: dock }
    SystemStats { id: stats }
    readonly property var systemStats: stats
    readonly property var recordingStatus: recording
    readonly property var fakePlayer: player
    // The view gets these through differently named ids: `recording: recording` would bind the view to itself.
    RecordingStatus { id: recording }

    QtObject {
        id: player
        property string identity: "Spotify"
        property string trackTitle: "Midnight City"
        property string trackArtist: "M83"
        property bool isPlaying: true
        property bool canGoPrevious: true
        property bool canGoNext: true
        property bool canTogglePlaying: true
    }

    Window {
        visible: true; width: 2048; height: 564; color: "#050505"
        DockView { id: view; anchors.fill: parent; recording: recordingStatus; stats: systemStats; player: fakePlayer }
    }

    function check(condition, message) {
        if (!condition) { ticks.stop(); throw new Error("GAMEDOCK SMOKE FAILED at tick " + tick + ": " + message); }
    }
    function event(object) { dock.handleEvent(JSON.stringify(object)); }
    function workspaces(activeId) {
        return {WorkspacesChanged: {workspaces: [
            {id: 1, output: "HDMI-A-3", is_active: activeId === 1},
            {id: 4, output: "HDMI-A-3", is_active: activeId === 4},
            {id: 9, output: "DP-1", is_active: true},
        ]}};
    }
    function save(name) { view.grabToImage(r => r.saveToFile("/tmp/boron-gamedock-" + name + ".png")); }

    Timer {
        id: ticks
        interval: 100; running: true; repeat: true
        onTriggered: {
            switch (test.tick++) {
            case 1:
                // Placement and visibility.
                check(!dock.visible, "hidden until placed");
                dock.show("HDMI-A-3", 4, 77, 4, 1160, 2048, 564);
                check(dock.visible && dock.strip.y === 1160 && dock.strip.width === 2048, "placed and visible");
                event(workspaces(4));
                check(dock.visible, "still visible on its workspace");
                event({WorkspaceActivated: {id: 1, focused: true}});
                check(!dock.visible && dock.placed, "hidden on another workspace, still placed");
                event({WorkspaceActivated: {id: 9, focused: true}});
                check(!dock.visible && dock.activeWorkspaceId === 1, "another output's workspace changes nothing");
                event({WorkspaceActivated: {id: 4, focused: true}});
                check(dock.visible, "back on its workspace");
                dock.handleEvent("not json");
                check(dock.visible, "garbage lines are ignored");
                event({WindowsChanged: {windows: [{id: 77}, {id: 5}]}});
                check(dock.visible, "game still open");
                event({WindowClosed: {id: 5}});
                check(dock.visible, "another window closing changes nothing");
                event({WindowClosed: {id: 77}});
                check(!dock.visible && !dock.placed, "game closed: dock gone");
                dock.show("HDMI-A-3", 4, 77, 4, 1160, 2048, 564);
                event({WindowsChanged: {windows: [{id: 5}]}});
                check(!dock.placed, "game missing from a full window list: dock gone");
                dock.show("HDMI-A-3", 4, 77, 4, 1160, 2048, 564);
                dock.hide();
                check(!dock.visible, "hide()");

                // CPU from /proc/stat deltas, temperature in millidegrees.
                stats.handleCpuOutput("cpu  100 0 100 800 0 0 0 0 0 0");
                check(stats.cpuPercent === 0, "first sample has no delta");
                stats.handleCpuOutput("cpu  150 0 150 900 0 0 0 0 0 0");
                check(Math.abs(stats.cpuPercent - 50) < 0.01, "50% busy: " + stats.cpuPercent);
                stats.handleCpuOutput("temp 58250");
                check(stats.cpuTemp === 58.25, "cpu temp");
                // nvidia-smi CSV, including [N/A] fields.
                stats.parseGpuLine("61, 67, 5222, 8192, 40, 121.35");
                check(stats.gpuPercent === 61 && stats.gpuTemp === 67 && stats.vramUsed === 5222
                      && stats.vramTotal === 8192 && stats.fanPercent === 40 && stats.powerWatts === 121.35, "gpu line");
                stats.parseGpuLine("12, 50, 1000, 8192, [N/A], [N/A]");
                check(stats.fanPercent === -1 && stats.powerWatts === -1, "N/A fields");
                stats.parseGpuLine("garbage");
                check(stats.gpuPercent === 12, "garbage gpu line ignored");

                // Recording status lines from obs_status.py.
                check(recording.clock(4000123) === "01:06:40" && recording.clock(0) === "00:00:00", "clock");
                recording.apply('{"connected":false,"reason":"disabled"}');
                check(!recording.connected && recording.offlineText === "OBS WEBSOCKET OFF", "offline reason");
                recording.apply('{"connected":true,"recording":true,"recordPaused":false,"recordMs":4352000,"streaming":true,"streamMs":725000,"reconnecting":false}');
                check(recording.connected && recording.recording && recording.streaming && recording.streamMs === 725000, "recording and streaming");
                stats.parseGpuLine("61, 67, 5222, 8192, 40, 121.35");
                break;
            case 8:
                if (test.capture) test.save("recording");
                break;
            case 10:
                recording.apply('{"connected":false,"reason":"closed"}');
                player.isPlaying = false;
                break;
            case 14:
                if (test.capture) test.save("idle");
                break;
            case 18:
                check(!recording.recording && recording.recordMs === 0, "disconnect clears status");
                console.warn("GAMEDOCK SMOKE PASSED");
                Qt.quit();
            }
        }
    }
}
