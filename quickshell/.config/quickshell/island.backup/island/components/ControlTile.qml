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
    opacity: root.enabled ? 1 : 0.62

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationHover
        }
    }

    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: Theme.space16
        anchors.top: parent.top
        anchors.topMargin: Theme.space12
        text: root.iconText
        color: root.active ? Theme.accent : Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 18
    }

    Text {
        anchors.left: icon.right
        anchors.leftMargin: Theme.space12
        anchors.right: parent.right
        anchors.rightMargin: Theme.space12
        anchors.top: parent.top
        anchors.topMargin: Theme.space12
        text: root.title
        elide: Text.ElideRight
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizePrimary
        font.weight: Theme.fontWeightPrimary
    }

    Text {
        anchors.left: icon.right
        anchors.leftMargin: Theme.space12
        anchors.right: parent.right
        anchors.rightMargin: Theme.space12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.space12
        text: root.subtitle
        elide: Text.ElideRight
        color: Theme.secondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSecondary
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
