import QtQuick
import Quickshell
import Quickshell.Wayland

// Captures every monitor just before locking, so the lock can show this desktop blurred and
// sharpen back into it on unlock. Frames stay in memory (grab results) and are never written to disk.
// Each capture runs in a 1×1 transparent overlay window that exists only while capturing.
Scope {
    id: root
    property bool capturing: false
    property var frames: ({})   // screen name → image url
    property var results: []    // keeps the grab results alive; their urls stop working without them
    property int remaining: 0
    signal finished()

    function capture() {
        clear();
        remaining = Quickshell.screens.length;
        if (remaining === 0) { finished(); return; }
        capturing = true;
        timeout.restart();
    }

    function clear() {
        frames = ({});
        results = [];
    }

    function done() {
        timeout.stop();
        capturing = false;
        finished();
    }

    function store(name, result) {
        if (!capturing) return;
        const next = Object.assign({}, frames);
        next[name] = String(result.url);
        frames = next;
        results = results.concat([result]);
        if (--remaining <= 0) done();
    }

    // Don't hold the lock back if a monitor never delivers a frame; it falls back to the wallpaper.
    Timer { id: timeout; interval: 700; onTriggered: root.done() }

    Variants {
        model: root.capturing ? Quickshell.screens : []
        PanelWindow {
            id: window
            required property var modelData
            screen: modelData
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            anchors { top: true; left: true }
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "boron-lock-snapshot"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            ScreencopyView {
                id: view
                width: window.modelData.width
                height: window.modelData.height
                captureSource: window.modelData
                live: false
                // The grab is at the output's real pixel size (logical size × scale), so the final
                // unblurred frame matches the desktop exactly.
                onHasContentChanged: {
                    if (hasContent)
                        grabToImage(result => root.store(window.modelData.name, result));
                }
            }
        }
    }
}
