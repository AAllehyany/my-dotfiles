import QtQuick

import qs.theme

Item {
    id: root

    property real strength: 0.0

    property color activeColor: Theme.accent
    property color inactiveColor: Theme.line

    readonly property real normalizedStrength:
        Math.max(0.0, Math.min(1.0, root.strength))

    readonly property int activeBars:
        root.normalizedStrength <= 0
            ? 0
            : Math.ceil(root.normalizedStrength * 4)

    implicitWidth: 19
    implicitHeight: 12

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        spacing: 2

        Repeater {
            model: 4

            delegate: Rectangle {
                required property int index

                width: 3
                height: 3 + index * 3

                anchors.bottom: parent.bottom

                radius: 1

                color: index < root.activeBars
                    ? root.activeColor
                    : root.inactiveColor

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durationHover
                    }
                }
            }
        }
    }
}
