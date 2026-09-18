import QtQuick
import "../../components"
import "../../core"
import "../../theme"

Item {
    id: root
    required property var modeAdapter
    property var items: modeAdapter ? modeAdapter.results(CommandCenterState.query) : []
    signal showActions(var result)
    onItemsChanged: if (CommandCenterState.selectedIndex >= items.length) CommandCenterState.selectedIndex = Math.max(0, items.length - 1)
    function activateSelected() {
        if (!items.length) return
        const result = items[CommandCenterState.selectedIndex]
        if (result.actions && result.actions.length > 1) showActions(result)
        else modeAdapter.activate(result, result.actions && result.actions.length ? result.actions[0].actionId : "default")
    }
    ListView {
        anchors.fill: parent
        spacing: Theme.spaceXs
        clip: true
        model: root.items
        currentIndex: CommandCenterState.selectedIndex
        delegate: ResultRow {
            required property var modelData
            width: ListView.view.width
            result: modelData
            selected: index === CommandCenterState.selectedIndex
            onChosen: { CommandCenterState.selectedIndex = index; root.activateSelected() }
        }
    }
    Label { anchors.centerIn: parent; visible: root.items.length === 0; text: "No results"; color: Theme.textMuted }
}
