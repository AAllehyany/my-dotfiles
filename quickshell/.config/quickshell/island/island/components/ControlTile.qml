import QtQuick
import qs.theme

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string iconText: ""
    property bool active: false

    signal activated()

    radius: Theme.radiusControl
    color: {
        if (root.active)
            return Theme.tileActive;
        if (hoverArea.containsMouse && root.enabled)
            return Theme.tileHover;
        return Theme.tile;
    }
    border.width: Theme.borderWidth
    border.color: root.active || (hoverArea.containsMouse && root.enabled)
        ? Theme.accentMuted
        : Theme.line
    opacity: root.enabled ? 1 : 0.52

    Behavior on color { ColorAnimation { duration: Theme.durationHover } }
    Behavior on border.color { ColorAnimation { duration: Theme.durationHover } }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: root.active ? Theme.accent : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.durationHover } }
    }

    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: Theme.space10
        anchors.top: parent.top
        anchors.topMargin: Theme.space10
        text: root.iconText
        color: root.active ? Theme.accent : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMeta
        font.weight: Font.Bold
    }

    Text {
        anchors.left: icon.right
        anchors.leftMargin: Theme.space8
        anchors.right: parent.right
        anchors.rightMargin: Theme.space10
        anchors.top: parent.top
        anchors.topMargin: Theme.space8
        text: root.title.toUpperCase()
        elide: Text.ElideRight
        color: root.active ? Theme.accent : Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizePrimary
        font.weight: Theme.fontWeightPrimary
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Theme.space10
        anchors.right: parent.right
        anchors.rightMargin: Theme.space10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.space8
        text: root.subtitle.toUpperCase()
        elide: Text.ElideRight
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMeta
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
