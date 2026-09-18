import QtQuick
import "../../components"
import "../../core"
import "../../theme"

Column {
    id: root
    required property var result
    required property var modeAdapter
    spacing: Theme.spaceSm
    Label { text: result.title; font.pixelSize: Theme.fontTitle; font.weight: Theme.fontWeightStrong }
    Repeater {
        model: result.actions || []
        delegate: Rectangle {
            required property var modelData
            width: root.width; height: Theme.rowHeight; radius: Theme.radiusSm; color: Theme.surfaceSelected
            Label { anchors.centerIn: parent; text: modelData.icon ? modelData.icon + "  " + modelData.label : modelData.label }
            MouseArea { anchors.fill: parent; onClicked: root.modeAdapter.activate(root.result, modelData.actionId) }
        }
    }
    Label { text: "Escape returns to results"; color: Theme.textMuted; font.pixelSize: Theme.fontSmall }
}
