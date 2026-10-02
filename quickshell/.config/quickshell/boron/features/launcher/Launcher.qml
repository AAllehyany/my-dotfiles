import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: window
    required property var state
    readonly property Item surface: view.surface
    screen: state.targetScreen
    visible: state.opened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "boron-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    LauncherView { id: view; anchors.fill: parent; state: window.state }
}
