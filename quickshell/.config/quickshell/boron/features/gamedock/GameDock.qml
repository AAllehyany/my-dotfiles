import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

// The game dock: a panel in the strip under the game in niri's game layout (see niri/scripts/game-layout).
// It sits on the bottom layer, under windows and over the wallpaper, so a window moved there simply covers it.
Scope {
    id: root
    required property var state   // DockState

    RecordingStatus { id: dockRecording; running: root.state.visible }
    SystemStats { id: dockStats; running: root.state.visible }

    // The playing player first, otherwise the first one that has a track.
    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) || players.find(p => p.trackTitle) || players[0] || null;
    }

    // Resolved here, not from the window's own `screen`, which changes as the window maps.
    readonly property var dockScreen: {
        for (const screen of Quickshell.screens)
            if (screen.name === root.state.outputName) return screen;
        return null;
    }

    PanelWindow {
        id: window
        screen: root.dockScreen
        visible: root.state.visible && root.dockScreen !== null
        color: "transparent"
        anchors { top: true; left: true }
        margins { top: root.state.strip.y; left: root.state.strip.x }
        implicitWidth: root.state.strip.width
        implicitHeight: root.state.strip.height
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "boron-gamedock"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        DockView {
            anchors.fill: parent
            recording: dockRecording
            stats: dockStats
            player: root.player
        }
    }
}
