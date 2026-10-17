import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    id: root
    required property var record
    signal activated()
    signal dismissed()
    implicitWidth: Theme.toastWidth
    implicitHeight: Theme.toastHeight
    color: Theme.surface
    border.color: record.critical ? Theme.danger : Theme.border
    clip: true
    MouseArea {
        anchors.fill: parent
        onClicked: root.activated()
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
    RowLayout {
        anchors { fill: parent; margins: 16; rightMargin: 40 }
        spacing: 12
        NotificationImage {
            image: root.record.image
            appIcon: root.record.appIcon
            visible: available
            Layout.alignment: Qt.AlignVCenter
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            Text {
                Layout.fillWidth: true
                text: root.record.title
                textFormat: Text.PlainText
                color: Theme.text
                font.family: Theme.font; font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: !!text
                text: root.record.body
                textFormat: Text.PlainText
                color: Theme.muted
                font.family: Theme.font; font.pixelSize: Theme.small
                wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
            }
        }
    }
    Button {
        objectName: "toastDismiss"
        anchors { top: parent.top; right: parent.right; margins: 4 }
        width: 30; height: 30
        text: "×"
        Accessible.name: "Dismiss notification"
        focusPolicy: Qt.NoFocus
        background: Rectangle { color: parent.hovered ? Theme.selection : "transparent" }
        contentItem: Text { text: "×"; color: Theme.muted; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        onClicked: root.dismissed()
    }
}
