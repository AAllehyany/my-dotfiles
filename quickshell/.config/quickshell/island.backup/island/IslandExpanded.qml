import QtQuick
import qs.island.components
import qs.theme

Item {
    id: root

    required property bool expanded

    enabled: root.expanded
    visible: opacity > 0.001

    Column {
        width: parent.width
        spacing: Theme.space12

        Row {
            width: parent.width
            spacing: Theme.space12

            ControlTile {
                width: (parent.width - parent.spacing) / 2
                height: 72
                title: "Wi-Fi"
                subtitle: "Phase 3 placeholder"
                iconText: "W"
                enabled: false
            }

            ControlTile {
                width: (parent.width - parent.spacing) / 2
                height: 72
                title: "Bluetooth"
                subtitle: "Phase 3 placeholder"
                iconText: "B"
                enabled: false
            }
        }

        SliderControl {
            width: parent.width
            label: "Volume"
            iconText: "V"
            value: 0.72
            interactive: false
        }

        SliderControl {
            width: parent.width
            label: "Brightness"
            iconText: "☀"
            value: 0.55
            interactive: false
        }

        Rectangle {
            width: parent.width
            height: 52
            radius: Theme.radiusControl
            color: Theme.tile

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.space16
                anchors.verticalCenter: parent.verticalCenter
                text: "Battery — Phase 4"
                color: Theme.secondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSecondary
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: Theme.space16
                anchors.verticalCenter: parent.verticalCenter
                text: "Balanced"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSecondary
            }
        }
    }
}
