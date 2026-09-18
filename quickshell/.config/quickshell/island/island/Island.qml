import Quickshell
import Quickshell.Io
import QtQuick

import qs.attention
import qs.services
Scope {
    id: root

    // Store compositor output names, not ShellScreen references. ShellScreen
    // objects become dangling when an output disconnects.
    property string expandedOutputName: ""
    property string attentionOutputName: ""
    property string lastOutputName: ""
    readonly property string timeText: Qt.formatDateTime(clock.date, "HH:mm")
    Connections {
        target: AttentionCenter

        function onCurrentChanged() {
            if (AttentionCenter.active) {
                root.attentionOutputName = root.defaultOutputName();
            } else {
                root.attentionOutputName = "";
            }
        }
    }
    ValueAttentionSource {
      enabled: Audio.available
      value: Math.round(Audio.volume * 100)

      eventFactory: vol => ({
        key: "audio",
        kind: "volume",
        label: "VOL",
        valueText: vol + "%",
        duration: 900
      })
    }
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function surfaceForOutput(name) {
        if (!name)
            return null;

        for (let i = 0; i < islandVariants.instances.length; ++i) {
            const surface = islandVariants.instances[i];
            if (surface.outputName === name)
                return surface;
        }

        return null;
    }

    function outputExists(name) {
        return root.surfaceForOutput(name) !== null;
    }

    function defaultOutputName() {
        if (root.lastOutputName && root.outputExists(root.lastOutputName))
            return root.lastOutputName;

        return islandVariants.instances.length > 0
            ? islandVariants.instances[0].outputName
            : "";
    }

    function openIsland(outputName) {
        const target = outputName && root.outputExists(outputName)
            ? outputName
            : root.defaultOutputName();

        if (!target)
            return;

        root.lastOutputName = target;
        root.expandedOutputName = target;
    }

    function closeIsland() {
        root.expandedOutputName = "";
    }

    function toggleIsland(outputName) {
        // Phase 0 has no Niri focused-output service yet. With no explicit
        // output, close the current island first; otherwise reopen the most
        // recently interacted output, falling back to the first variant.
        if (!outputName) {
            if (root.expandedOutputName) {
                root.closeIsland();
                return;
            }

            root.openIsland(root.defaultOutputName());
            return;
        }

        if (root.expandedOutputName === outputName)
            root.closeIsland();
        else
            root.openIsland(outputName);
    }

    function reconcileOutputs() {
        if (root.expandedOutputName && !root.outputExists(root.expandedOutputName))
            root.expandedOutputName = "";

        if (root.lastOutputName && !root.outputExists(root.lastOutputName))
            root.lastOutputName = "";
    }
    function workspaceTextFor(outputName) {
        const workspace = Niri.workspaceForOutput(outputName);

        if (!workspace)
            return "--";

        const index = String(workspace.idx).padStart(2, "0");

        if (workspace.name && workspace.name.length > 0)
            return index + " · " + workspace.name;

        return index;
    }
    // Variants is the owner of per-output surface lifetime. Quickshell.screens
    // is used only as its reactive model; orchestration uses instances instead
    // of manually iterating/storing ShellScreen objects.
    Variants {
        id: islandVariants
        model: Quickshell.screens

        IslandSurface {
            expanded: root.expandedOutputName === outputName
            timeText: root.timeText
            workspaceText: root.workspaceTextFor(outputName)
            workspaces: Niri.workspacesForOutput(outputName)
            attention: AttentionCenter.active && root.attentionOutputName === outputName ? AttentionCenter.current : null
            onRequestToggle: outputName => root.toggleIsland(outputName)
            onRequestClose: root.closeIsland()
        }

        onInstancesChanged: Qt.callLater(root.reconcileOutputs)
    }

    IpcHandler {
        target: "island"

        function toggle(): void {
            root.toggleIsland("");
        }

        function open(): void {
            root.openIsland("");
        }

        function close(): void {
            root.closeIsland();
        }

        function toggleOn(outputName: string): bool {
            if (!root.outputExists(outputName))
                return false;

            root.toggleIsland(outputName);
            return true;
        }

        function openOn(outputName: string): bool {
            if (!root.outputExists(outputName))
                return false;

            root.openIsland(outputName);
            return true;
        }
    }
}
