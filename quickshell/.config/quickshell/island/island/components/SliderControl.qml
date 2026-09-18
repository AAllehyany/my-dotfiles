import QtQuick
import qs.theme

Item {
    id: root

    property string label: ""
    property string iconText: ""
    property real value: 0
    property bool interactive: true
    property color trackColor: Theme.track
    property color progressColor: Theme.accent
    property color handleColor: Theme.foreground
    property bool labelInteractive: false


    signal labelActivated()
    signal valueChangedByUser(real value)
    signal iconActivated()

    implicitHeight: 48
    opacity: root.interactive ? 1 : 0.55

    Text {
        id: prefix

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: Theme.space4

        text: root.iconText + " //"
        color: prefixMouse.containsMouse
            ? Theme.accent
            : Theme.accentMuted

        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMeta
        font.weight: Font.Bold

        MouseArea {
            id: prefixMouse

            anchors.fill: parent
            enabled: root.interactive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: root.iconActivated()
        }
    }

    Text {
        id: labelText
        anchors.left: prefix.right
        anchors.leftMargin: Theme.space6
        anchors.top: prefix.top
        text: root.label.toUpperCase()
        color: labelMouse.containsMouse
                && root.labelInteractive
                    ? Theme.accent
                    : Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSecondary
        font.weight: Theme.fontWeightPrimary
        MouseArea {
          id: labelMouse

          anchors.fill: parent

          enabled: root.labelInteractive
          hoverEnabled: true

          cursorShape: root.labelInteractive
              ? Qt.PointingHandCursor
              : Qt.ArrowCursor

          onClicked: {
              root.labelActivated();
          }
        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationHover
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.top: prefix.top
        text: Math.round(Math.max(0, Math.min(1, root.value)) * 100) + "%"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSecondary
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.space8
        height: 3
        radius: 0
        color: root.trackColor 

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            color: root.progressColor
        }

        Rectangle {
            x: Math.max(0, Math.min(parent.width - width,
                parent.width * Math.max(0, Math.min(1, root.value)) - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 5
            height: sliderMouse.containsMouse && root.interactive ? 11 : 7
            color: root.handleColor

            Behavior on height {
                NumberAnimation { duration: Theme.durationHover; easing.type: Easing.OutCubic }
            }
        }
    }

    MouseArea {
        id: sliderMouse
        anchors.left: track.left
        anchors.right: track.right
        anchors.verticalCenter: track.verticalCenter
        height: 22
        enabled: root.interactive
        hoverEnabled: true
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
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
            root.valueChangedByUser(Math.max(0, Math.min(1, root.value + step)));
            wheel.accepted = true;
        }
    }
}
