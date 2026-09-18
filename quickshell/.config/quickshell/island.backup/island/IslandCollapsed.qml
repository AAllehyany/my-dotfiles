import QtQuick

Item {
    id: root

    required property string workspaceText
    required property string timeText
    required property bool expanded

    signal activated()

    IslandHeader {
        anchors.fill: parent
        workspaceText: root.workspaceText
        timeText: root.timeText
        expanded: root.expanded
        onActivated: root.activated()
    }
}
