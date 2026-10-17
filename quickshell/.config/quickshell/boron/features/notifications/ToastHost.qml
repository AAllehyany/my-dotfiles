import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"

// One tightly bounded surface per card: the desktop between cards stays clickable.
Variants {
    id: root
    required property var service
    model: service.toasts
    delegate: PanelWindow {
        id: window
        required property var modelData
        readonly property var record: modelData
        readonly property var targetScreen: root.service.screenFor(record.screenName)
        readonly property Item surface: card
        readonly property int position: root.service.toasts.filter(entry => entry.screenName === record.screenName).indexOf(record)
        property real bottomOffset: Theme.toastMargin + Math.max(0, position) * (Theme.toastHeight + Theme.toastSpacing)
        Behavior on bottomOffset { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
        screen: targetScreen
        visible: record.toastVisible && !!targetScreen
        color: "transparent"
        implicitWidth: Math.max(1, Math.min(Theme.toastWidth, (targetScreen ? targetScreen.width : Theme.toastWidth + 48) - Theme.toastMargin * 2))
        implicitHeight: Math.max(1, Math.min(Theme.toastHeight, (targetScreen ? targetScreen.height : Theme.toastHeight + 48) - Theme.toastMargin * 2))
        anchors { bottom: true; right: true }
        margins { bottom: bottomOffset; right: Theme.toastMargin }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "boron-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        ToastCard {
            id: card
            anchors.fill: parent
            record: window.record
            opacity: window.record.exiting ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.motion } }
            onActivated: root.service.activate(window.record.notificationId, "default")
            onDismissed: root.service.dismiss(window.record.notificationId)
        }
    }
}
