import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.theme

PanelWindow {
    id: window

    visible: LauncherState.opened
    focusable: visible

    color: "transparent"
    surfaceFormat.opaque: false

    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "command-center"
    WlrLayershell.layer: WlrLayer.Overlay

    onVisibleChanged: {
        if (visible) {
            keyboardScope.forceActiveFocus();
        }
    }

    FocusScope {
        id: keyboardScope

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: {
            LauncherState.close();
        }

        Rectangle {
            id: launcherSurface

            width: Math.min(720, parent.width - Theme.spacing.xxl * 2)
            height: 460

            anchors {
                top: parent.top
                topMargin: 120
                horizontalCenter: parent.horizontalCenter
            }

            radius: Theme.radius.none
            color: Theme.palette.surface

            border.width: 1
            border.color: Theme.palette.border

            Text {
                anchors.centerIn: parent

                text: "The Lab"

                color: Theme.palette.text

                font {
                    family: Theme.typography.family
                    pixelSize: Theme.typography.heading
                }
            }
        }
    }
}
