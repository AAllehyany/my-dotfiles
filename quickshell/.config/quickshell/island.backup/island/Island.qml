import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    // Store compositor output names, not ShellScreen references. ShellScreen
    // objects become dangling when an output disconnects.
    property string expandedOutputName: ""
    property string lastOutputName: ""
    readonly property string timeText: Qt.formatDateTime(clock.date, "HH:mm")

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

    // Variants is the owner of per-output surface lifetime. Quickshell.screens
    // is used only as its reactive model; orchestration uses instances instead
    // of manually iterating/storing ShellScreen objects.
    Variants {
        id: islandVariants
        model: Quickshell.screens

        IslandSurface {
            expanded: root.expandedOutputName === outputName
            timeText: root.timeText
            workspaceText: "02 · dev"

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
