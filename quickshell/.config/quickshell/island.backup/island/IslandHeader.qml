import QtQuick
import qs.island.components
import qs.theme

Item {
    id: root

    required property string workspaceText
    required property string timeText
    required property bool expanded

    signal activated()

    WorkspaceIndicator {
        anchors.left: parent.left
        anchors.leftMargin: Theme.space16
        anchors.verticalCenter: parent.verticalCenter
        text: root.workspaceText
    }

    Clock {
        anchors.right: parent.right
        anchors.rightMargin: Theme.space16
        anchors.verticalCenter: parent.verticalCenter
        text: root.timeText
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
