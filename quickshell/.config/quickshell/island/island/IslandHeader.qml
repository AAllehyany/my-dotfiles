import QtQuick
import qs.island.components
import qs.theme

Item {
    id: root

    required property string workspaceText
    required property string timeText
    required property bool expanded
    required property var workspaces
    required property var attention
    readonly property bool showAttention:
        !root.expanded
        && root.attention !== null
        && root.attention !== undefined

    readonly property string attentionText:
        root.showAttention
            ? root.attention.label + " // " + root.attention.valueText
            : ""
    signal activated()

    Rectangle {
        id: activityMark
        visible: false
        anchors.left: parent.left
        anchors.leftMargin: Theme.space10
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: root.expanded ? 14 : 8
        radius: 1
        color: Theme.accent

        Behavior on height {
            NumberAnimation { duration: Theme.durationHover; easing.type: Easing.OutCubic }
        }
    }
    Row {
        id: workspaceDots

        anchors.left: activityMark.right
        anchors.verticalCenter: parent.verticalCenter

        spacing: 6

        visible: !root.expanded

        opacity: root.showAttention ? 0 : 1

        Repeater {
            model: root.workspaces

            delegate: Rectangle {
                required property var modelData

                readonly property bool active: modelData.is_active

                width: active ? 11 : 4
                height: 4
                radius: 2

                color: active
                    ? Theme.accent
                    : Theme.workspaceInactive

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durationHover
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durationHover
                    }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationHover
            }
        }
    }
    Text {
        visible: root.expanded
        id: workspace
        anchors.left: activityMark.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.workspaceText.replace(" · ", " // ").toUpperCase()
        color: headerMouse.containsMouse || root.expanded ? Theme.accent : Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizePrimary
        font.weight: Theme.fontWeightPrimary

        opacity: root.showAttention ? 0 : 1
        Behavior on color { ColorAnimation { duration: Theme.durationHover } }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationHover
                easing.type: Easing.OutCubic
            }
        }
    }

    Text {
        id: attentionText

        anchors.left: activityMark.right
        anchors.leftMargin: Theme.space8
        anchors.verticalCenter: parent.verticalCenter

        text: root.attentionText
        color: Theme.accent

        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizePrimary
        font.weight: Theme.fontWeightPrimary

        opacity: root.showAttention ? 1 : 0

        transform: Translate {
            y: root.showAttention ? 0 : 3

            Behavior on y {
                NumberAnimation {
                    duration: Theme.durationHover
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationHover
                easing.type: Easing.OutCubic
            }
        }
    }
    Text {
        id: separator
        anchors.left: workspace.right
        anchors.leftMargin: Theme.space8
        anchors.verticalCenter: parent.verticalCenter
        text: "//"
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMeta
        visible: root.expanded
        opacity: root.expanded ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.durationHover } }
    }

    Text {
        anchors.left: separator.right
        anchors.leftMargin: Theme.space8
        anchors.verticalCenter: parent.verticalCenter
        text: "CONTROL"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMeta
        visible: root.expanded
        opacity: root.expanded ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.durationHover } }
    }

    Clock {
        anchors.right: parent.right
        anchors.rightMargin: Theme.space12
        anchors.verticalCenter: parent.verticalCenter
        text: root.timeText
        color: headerMouse.containsMouse ? Theme.accent : Theme.foreground

        Behavior on color { ColorAnimation { duration: Theme.durationHover } }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: root.expanded ? Theme.lineStrong : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.durationStandard } }
    }

    MouseArea {
        id: headerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
