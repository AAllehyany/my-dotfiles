import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: root
    property bool destructive: false
    property bool selected: false
    implicitHeight: 34
    implicitWidth: Math.max(70, contentItem.implicitWidth + 24)
    font.family: Theme.font
    font.pixelSize: Theme.small
    contentItem: Text {
        text: root.text
        font: root.font
        color: !root.enabled ? Theme.muted : root.destructive ? Theme.danger : root.selected ? Theme.accent : Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        color: root.selected || root.down || root.hovered ? Theme.selection : Theme.raised
        border.color: root.selected || root.activeFocus ? Theme.accent : Theme.border
    }
}
