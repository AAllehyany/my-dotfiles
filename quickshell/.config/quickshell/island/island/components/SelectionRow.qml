import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool selected: false

    signal activated()

    implicitHeight: 40

    color: "transparent"
    radius: 2

    border.width: 1
    border.color:
        root.selected || hitArea.containsMouse
            ? Theme.accent
            : Theme.line

    RowLayout {
        anchors.fill: parent


        anchors.leftMargin: Theme.space12
        anchors.rightMargin: Theme.space12

        spacing: Theme.space8

        Text {
            id: titleText

            // Similar to flex-grow: 1
            Layout.fillWidth: true

            // Similar to min-width: 0 in a CSS flex child.
            // Allows this item to actually shrink and elide.
            Layout.minimumWidth: 0

            Layout.alignment: Qt.AlignVCenter

            text: root.selected
                ? "> " + root.title
                : "  " + root.title

            color: root.selected
                ? Theme.accent
                : Theme.foreground

            font.family: Theme.fontFamily

            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }

        Text {
            id: subtitleText

            Layout.alignment: Qt.AlignVCenter

            text: root.subtitle

            color: root.selected
                ? Theme.accent
                : Theme.foreground

            opacity: 0.65

            font.family: Theme.fontFamily
        }
    }

    MouseArea {
        id: hitArea

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.activated();
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.durationHover
        }
    }
}
