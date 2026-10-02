import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"

Rectangle {
    implicitHeight: 36
    color: Theme.surface

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 18; rightMargin: 16 }
        spacing: 16

        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.accent
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            text: Qt.formatDateTime(clock.date, "dddd, d MMM yyyy")
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.small
        }
    }
}
