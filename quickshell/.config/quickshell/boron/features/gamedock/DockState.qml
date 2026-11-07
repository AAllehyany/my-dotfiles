import QtQuick
import Quickshell
import Quickshell.Io

// Where the game dock lives and whether it shows. niri's `game-layout` script calls show() with the
// strip under the game. The dock then shows only while that workspace is active on its output, and
// goes away for good when the game window closes. Niri events come from `niri msg --json event-stream`,
// which runs only while a dock is placed.
Scope {
    id: root
    property bool placed: false
    property string outputName: ""
    property int workspaceId: -1
    property int gameId: -1
    property rect strip: Qt.rect(0, 0, 0, 0)
    property int activeWorkspaceId: -1
    property var workspaceOutputs: ({})   // workspace id → output name, from WorkspacesChanged
    readonly property bool visible: placed && activeWorkspaceId === workspaceId && strip.width > 0 && strip.height > 0

    function show(output, workspace, game, x, y, w, h) {
        outputName = output;
        workspaceId = workspace;
        gameId = game;
        strip = Qt.rect(x, y, w, h);
        // The script runs on the focused workspace, so it is active right now.
        activeWorkspaceId = workspace;
        placed = true;
    }

    function hide() {
        placed = false;
    }

    // One event-stream line. Returns nothing; updates state.
    function handleEvent(line) {
        let event;
        try { event = JSON.parse(line); } catch (e) { return; }

        if (event.WorkspacesChanged) {
            const outputs = {};
            for (const ws of event.WorkspacesChanged.workspaces) {
                outputs[ws.id] = ws.output;
                if (ws.is_active && ws.output === outputName) activeWorkspaceId = ws.id;
            }
            workspaceOutputs = outputs;
            if (placed && !(workspaceId in outputs)) hide();
        } else if (event.WorkspaceActivated) {
            const id = event.WorkspaceActivated.id;
            if (workspaceOutputs[id] === outputName) activeWorkspaceId = id;
        } else if (event.WindowClosed) {
            if (event.WindowClosed.id === gameId) hide();
        } else if (event.WindowsChanged) {
            if (placed && !event.WindowsChanged.windows.some(w => w.id === gameId)) hide();
        }
    }

    Process {
        command: ["niri", "msg", "--json", "event-stream"]
        running: root.placed && Quickshell.env("NIRI_SOCKET") !== ""
        stdout: SplitParser { onRead: line => root.handleEvent(line) }
    }
}
