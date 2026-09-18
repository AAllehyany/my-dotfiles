import QtQuick

Item {
    id: root

    required property string workspaceText
    required property string timeText
    required property bool expanded
    required property var attention
    required property var workspaces

    signal activated()

    IslandHeader {
        anchors.fill: parent
        workspaceText: root.workspaceText
        workspaces: root.workspaces
        timeText: root.timeText
        expanded: root.expanded
        attention: root.attention
        onActivated: root.activated()
    }
}
