import QtQuick
import "../../components"
import "../../theme"

Rectangle {
    id: root
    required property var result
    property bool selected: false
    signal chosen()
    implicitHeight: Theme.rowHeight
    radius: Theme.radiusSm
    color: selected ? Theme.surfaceSelected : "transparent"
    Label { id: icon; anchors.left: parent.left; anchors.leftMargin: Theme.spaceMd; anchors.verticalCenter: parent.verticalCenter; text: root.result.icon; font.pixelSize: Theme.iconMd }
    Column {
        anchors { left: icon.right; leftMargin: Theme.spaceMd; right: parent.right; rightMargin: Theme.spaceMd; verticalCenter: parent.verticalCenter }
        Label { width: parent.width; text: root.result.title; font.weight: Theme.fontWeightStrong }
        Label { width: parent.width; text: root.result.subtitle; color: Theme.textMuted; font.pixelSize: Theme.fontSmall }
    }
    MouseArea { anchors.fill: parent; onClicked: root.chosen() }
}
