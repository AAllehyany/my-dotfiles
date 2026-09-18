pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string socketPath:
        Quickshell.env("NIRI_SOCKET") ?? ""

    property var workspaces: []
    property var activeWorkspaceByOutput: ({})
    property string focusedOutput: ""

    readonly property bool available:
        niriSocket.connected

    function workspaceForOutput(outputName) {
        return root.activeWorkspaceByOutput[outputName] ?? null;
    }
    function workspacesForOutput(outputName) {
        return root.workspaces
            .filter(workspace => workspace.output === outputName)
            .sort((a, b) => a.idx - b.idx);
    }
    function rebuildActiveWorkspaces() {
        const active = {};
        let focusedOutput = "";

        for (const workspace of root.workspaces) {
            if (workspace.output && workspace.is_active)
                active[workspace.output] = workspace;

            if (workspace.output && workspace.is_focused)
                focusedOutput = workspace.output;
        }

        // Important: assign a NEW object.
        //
        // QML sees the property change and updates bindings.
        root.activeWorkspaceByOutput = active;
        root.focusedOutput = focusedOutput;
    }

    function handleWorkspacesChanged(event) {
        root.workspaces = event.workspaces ?? [];
        root.rebuildActiveWorkspaces();
    }

    function handleWorkspaceActivated(event) {
        const activatedId = event.id;

        const activatedWorkspace =
            root.workspaces.find(
                workspace => workspace.id === activatedId
            );

        if (!activatedWorkspace || !activatedWorkspace.output)
            return;

        const outputName = activatedWorkspace.output;

        // Build NEW workspace objects so QML can observe the change.
        const nextWorkspaces = root.workspaces.map(workspace => {
            const copy = Object.assign({}, workspace);

            // There is exactly one active workspace per output.
            if (workspace.output === outputName) {
                copy.is_active =
                    workspace.id === activatedId;
            }

            // is_focused is global: only update it when Niri tells us
            // this activation also moved keyboard focus.
            if (event.focused) {
                copy.is_focused =
                    workspace.id === activatedId;
            }

            return copy;
        });

        // Assign a NEW array so bindings depending on root.workspaces
        // are reevaluated.
        root.workspaces = nextWorkspaces;

        // Rebuild our derived state from the now-correct workspace array.
        root.rebuildActiveWorkspaces();
    }

    function handleMessage(message) {
        if (message.length === 0)
            return;

        let event;

        try {
            event = JSON.parse(message);
        } catch (error) {
            console.warn(
                "Niri: failed to parse IPC message:",
                message
            );
            return;
        }

        if (event.WorkspacesChanged) {
            root.handleWorkspacesChanged(
                event.WorkspacesChanged
            );
            return;
        }

        if (event.WorkspaceActivated) {
            root.handleWorkspaceActivated(
                event.WorkspaceActivated
            );
            return;
        }

        // Ignore all other Niri events for now.
    }

    Socket {
        id: niriSocket

        path: root.socketPath

        parser: SplitParser {
            onRead: message => {
                root.handleMessage(message);
            }
        }

        onConnectedChanged: {
            if (connected) {
                console.log("Niri: IPC connected");

                write("\"EventStream\"\n");
                flush();
            } else {
                console.warn("Niri: IPC disconnected");

                reconnectTimer.restart();
            }
        }

        onError: error => {
            console.warn("Niri: socket error:", error);
        }
    }

    Timer {
        id: reconnectTimer

        interval: 1000
        repeat: false

        onTriggered: {
            if (root.socketPath.length > 0)
                niriSocket.connected = true;
        }
    }

    Component.onCompleted: {
        if (root.socketPath.length === 0) {
            console.warn("Niri: NIRI_SOCKET is not set");
            return;
        }

        niriSocket.connected = true;
    }
}
