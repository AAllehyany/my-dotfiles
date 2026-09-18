import QtQuick
import "../../components"
import "../../core"
import "../../theme"

Surface {
    id: root
    property alias input: input
    implicitHeight: 48
    color: Theme.surface

    Label { anchors.left: parent.left; anchors.leftMargin: Theme.spaceMd; anchors.verticalCenter: parent.verticalCenter; text: "󰍉" }
    TextInput {
        id: input
        anchors { left: parent.left; leftMargin: 42; right: parent.right; rightMargin: Theme.spaceMd; verticalCenter: parent.verticalCenter }
        color: Theme.textPrimary
        selectionColor: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        clip: true
        text: CommandCenterState.query
        onTextEdited: { CommandCenterState.query = text; CommandCenterState.selectedIndex = 0 }
        Label { anchors.fill: parent; visible: input.text.length === 0; text: "Search or type a command…"; color: Theme.textMuted }
    }
    function takeFocus() { input.forceActiveFocus() }
}
