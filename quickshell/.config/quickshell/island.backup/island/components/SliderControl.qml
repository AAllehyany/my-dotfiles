import QtQuick
import qs.theme

Item {
    id: root

    property string label: ""
    property string iconText: ""
    property real value: 0
    property bool interactive: true

    signal valueChangedByUser(real value)
    signal iconActivated()

    implicitHeight: 56
    opacity: root.interactive ? 1 : 0.68

    Text {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        text: root.iconText
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        id: labelText
        anchors.left: icon.right
        anchors.leftMargin: Theme.space12
        anchors.top: parent.top
        anchors.topMargin: Theme.space4
        text: root.label
        color: Theme.secondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSecondary
    }

    Rectangle {
        id: track
        anchors.left: labelText.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.space8
        height: 6
        radius: 3
        color: Theme.track

        Rectangle {
            width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
    }

    MouseArea {
        anchors.fill: track
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor

        function setFromMouse(mouseX) {
            const next = Math.max(0, Math.min(1, mouseX / width));
            root.valueChangedByUser(next);
        }

        onPressed: mouse => setFromMouse(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                setFromMouse(mouse.x);
        }
    }
}
