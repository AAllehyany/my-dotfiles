import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../components"
import "../../core"
import "../../theme"

PanelWindow {
    id: window
    visible: CommandCenterState.visible
    implicitWidth: Theme.panelWidth
    implicitHeight: Theme.panelHeight
    color: "transparent"
    anchors.top: true
    margins.top: 96
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var activeAdapter: adapterLoader.item
    property var actionResult: null
    function takeFocus() {
        if (activeAdapter && activeAdapter.supportsSearch) search.takeFocus()
        else keyboardScope.forceActiveFocus()
    }

    onVisibleChanged: if (visible) Qt.callLater(takeFocus)
    Connections {
        target: CommandCenterState
        function onActiveModeChanged() { actionResult = null; Qt.callLater(window.takeFocus) }
        function onNavigationDepthChanged() { if (CommandCenterState.navigationDepth === 0) actionResult = null }
    }

    Loader {
        id: adapterLoader
        source: ModeRegistry.mode(CommandCenterState.activeMode).adapter
        onLoaded: if (window.visible) Qt.callLater(window.takeFocus)
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: Theme.radiusLg
        border.color: Theme.border
        border.width: Theme.borderWidth

        FocusScope {
            id: keyboardScope
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => keyboard.handle(event)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spaceLg
                spacing: Theme.spaceMd
                SearchField { id: search; Layout.fillWidth: true; visible: !window.activeAdapter || window.activeAdapter.supportsSearch }
                ModePicker { Layout.fillWidth: true }
                Divider { Layout.fillWidth: true }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ResultList {
                        id: results
                        anchors.fill: parent
                        visible: window.activeAdapter && !window.activeAdapter.customViewUrl && CommandCenterState.navigationDepth === 0
                        modeAdapter: window.activeAdapter
                        onShowActions: result => { window.actionResult = result; CommandCenterState.enter() }
                    }
                    Loader {
                        anchors.fill: parent
                        visible: active
                        active: window.activeAdapter && window.activeAdapter.customViewUrl.toString().length > 0
                        source: active ? window.activeAdapter.customViewUrl : ""
                    }
                    ActionView {
                        anchors.fill: parent
                        visible: CommandCenterState.navigationDepth > 0 && window.actionResult !== null
                        result: window.actionResult || ({ title: "", actions: [] })
                        modeAdapter: window.activeAdapter
                    }
                }
                Label { Layout.fillWidth: true; text: "↑/↓ navigate   Enter select   Tab modes   Esc back/clear/close"; color: Theme.textMuted; font.pixelSize: Theme.fontSmall }
            }
            KeyboardNavigation { id: keyboard; resultList: results; modeAdapter: window.activeAdapter }
        }
    }
}
