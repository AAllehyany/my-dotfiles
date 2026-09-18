import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../theme"

GridLayout {
    columns: 2
    rowSpacing: Theme.spaceMd
    columnSpacing: Theme.spaceMd
    property var controls: [
        ["󰖩", "Wi-Fi", "Connected"], ["󰂯", "Bluetooth", "On"],
        ["󰕾", "Audio", "65%"], ["󰃟", "Brightness", "80%"]
    ]
    Repeater {
        model: parent.controls
        delegate: Surface {
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 92
            Column {
                anchors.fill: parent; anchors.margins: Theme.spaceMd; spacing: Theme.spaceSm
                Label { text: modelData[0] + "  " + modelData[1]; font.weight: Theme.fontWeightStrong }
                Label { text: modelData[2]; color: Theme.textMuted; font.pixelSize: Theme.fontSmall }
            }
        }
    }
    Label { Layout.columnSpan: 2; text: "Representative controls — service integration follows in a later phase"; color: Theme.textMuted }
}
