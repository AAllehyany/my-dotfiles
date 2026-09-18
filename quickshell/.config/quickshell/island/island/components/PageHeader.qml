import QtQuick
import QtQuick.Layouts

import qs.theme

Item {
    id: root

    property string title: ""

    signal backRequested()

    implicitHeight: 28

    RowLayout {
        anchors.fill: parent

        spacing: Theme.space8

        Text {
            id: backText

            text: "<"

            color: backMouse.containsMouse
                ? Theme.accent
                : Theme.foreground

            font.family: Theme.fontFamily

            MouseArea {
                id: backMouse

                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.backRequested();
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationHover
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0

            text:  root.title.toUpperCase()

            color: Theme.foreground

            font.family: Theme.fontFamily

            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }
}
