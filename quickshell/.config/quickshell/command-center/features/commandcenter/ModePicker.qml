import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../core"
import "../../theme"

RowLayout {
    spacing: Theme.spaceSm
    Repeater {
        model: ModeRegistry.modes
        delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: Theme.modeRowHeight
            radius: Theme.radiusSm
            color: CommandCenterState.activeMode === modelData.id ? Theme.surfaceSelected : "transparent"
            Label { anchors.centerIn: parent; text: modelData.icon + "  " + modelData.label; font.pixelSize: Theme.fontSmall }
            MouseArea { anchors.fill: parent; onClicked: CommandCenterState.selectMode(modelData.id) }
        }
    }
}
