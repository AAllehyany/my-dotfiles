import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../components"

Rectangle {
    id: root
    property var notificationService: null
    property bool notificationsEnabled: true
    signal notificationsRequested()
    implicitHeight: 36
    color: Theme.surface

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 18; rightMargin: 16 }
        spacing: 16

        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.accent
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            text: Qt.formatDateTime(clock.date, "dddd, d MMM yyyy")
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.small
        }
        ActionButton {
            objectName: "notificationCenterButton"
            visible: !!root.notificationService
            enabled: root.notificationsEnabled
            implicitHeight: 28
            text: "NOTIFS" + (root.notificationService && root.notificationService.unreadCount ? " · " + root.notificationService.unreadCount : "")
            Accessible.name: "Notifications, " + (root.notificationService ? root.notificationService.unreadCount : 0) + " unread"
            onClicked: root.notificationsRequested()
        }
    }
}
