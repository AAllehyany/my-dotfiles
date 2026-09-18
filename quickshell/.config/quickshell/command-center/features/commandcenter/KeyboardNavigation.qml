import QtQuick
import "../../core"

Item {
    id: root
    required property var resultList
    required property var modeAdapter
    function handle(event) {
        if (event.key === Qt.Key_Escape) CommandCenterState.escape()
        else if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && event.modifiers & Qt.ControlModifier))
            CommandCenterState.moveSelection(1, resultList.items.length)
        else if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier))
            CommandCenterState.moveSelection(-1, resultList.items.length)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) resultList.activateSelected()
        else if (event.key === Qt.Key_Tab) CommandCenterState.selectMode(
            ModeRegistry.cycle(CommandCenterState.activeMode, event.modifiers & Qt.ShiftModifier ? -1 : 1))
        else return
        event.accepted = true
    }
}
