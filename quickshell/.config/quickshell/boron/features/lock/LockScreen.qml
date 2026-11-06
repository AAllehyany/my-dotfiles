import QtQuick
import "../../theme"

// One monitor's lock screen. Every monitor shows the glitching lock and the date; only the
// monitor named by state.inputScreen shows the password field. Any monitor accepts typing.
Item {
    id: root
    required property var state
    property string screenName: ""
    property string wallpaper: ""
    readonly property bool hasInput: !state.inputScreen || state.inputScreen === screenName
    readonly property real iconSize: Math.min(512, height * 0.47)

    focus: true
    Keys.onPressed: event => { event.accepted = root.state.handleKey(event); }
    Component.onCompleted: forceActiveFocus()

    BlurredWallpaper { anchors.fill: parent; path: root.wallpaper }

    MouseArea {
        anchors.fill: parent
        onPressed: {
            root.state.inputScreen = root.screenName;
            root.forceActiveFocus();
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 28
        opacity: root.state.fade

        GlitchIcon {
            objectName: "lockIcon"
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.iconSize
            height: root.iconSize
            intensity: root.state.glitch
            tint: root.state.tintColor
            flash: root.state.flash
            open: root.state.shackleOpen
            running: root.state.active
        }

        Row {
            objectName: "lockDate"
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 22
            Text {
                text: root.state.dateText
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 64
                font.letterSpacing: 6
            }
            Text {
                text: "·"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 64
            }
            Text {
                text: root.state.timeText
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 64
                font.letterSpacing: 6
            }
        }

        Item { width: 1; height: 4 }

        Rectangle {
            id: field
            objectName: "lockInput"
            visible: root.hasInput
            anchors.horizontalCenter: parent.horizontalCenter
            width: 420
            height: 56
            color: Theme.surface
            border.width: 1
            border.color: root.state.phase === "failed" ? Theme.danger
                : root.state.buffer ? Theme.accent : Theme.border
            transform: Translate { id: shakeOffset }

            Text {
                anchors.left: parent.left
                anchors.right: cursor.left
                anchors.leftMargin: 20
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: "•".repeat(root.state.buffer.length)
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 22
                font.letterSpacing: 4
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignLeft
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.state.buffer
                text: root.state.phase === "checking" ? "checking…"
                    : root.state.phase === "unlocking" ? "unlocked" : "password"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            // Square block cursor, Boron style.
            Rectangle {
                id: cursor
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: 22
                color: Theme.accent
                visible: !root.state.busy
                SequentialAnimation on opacity {
                    running: root.state.active && !root.state.busy
                    loops: Animation.Infinite
                    NumberAnimation { to: 0; duration: 0 }
                    PauseAnimation { duration: 530 }
                    NumberAnimation { to: 1; duration: 0 }
                    PauseAnimation { duration: 530 }
                }
            }

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shakeOffset; property: "x"; to: -18; duration: 40 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 16; duration: 60 }
                NumberAnimation { target: shakeOffset; property: "x"; to: -12; duration: 60 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 8; duration: 60 }
                NumberAnimation { target: shakeOffset; property: "x"; to: -4; duration: 60 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 60 }
            }
            Connections {
                target: root.state
                function onShake() { shakeAnim.restart(); }
            }
        }

        Text {
            objectName: "lockStatus"
            visible: root.hasInput
            anchors.horizontalCenter: parent.horizontalCenter
            // Fixed size: Column skips zero-width items, so an empty status would shift the layout.
            width: field.width
            height: Theme.fontSize * 2
            horizontalAlignment: Text.AlignHCenter
            text: root.state.message
            color: root.state.phase === "failed" ? Theme.danger : Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }
}
