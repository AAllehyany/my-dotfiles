import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme

PanelWindow {
    id: root

    required property var modelData
    required property bool expanded
    required property string timeText
    required property string workspaceText
    required property var workspaces

    required property var attention
    readonly property string outputName: modelData.name

    signal requestToggle(string outputName)
    signal requestClose()

    reloadableId: "island-surface"
    screen: modelData
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    focusable: root.expanded

    anchors {
        top: true
        left: true
        bottom: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-island"

    // Collapsed: only the visible island receives pointer input.
    // Expanded: the whole transparent host receives input so a click outside
    // the island can close it. The visible surface remains the same object.
    mask: Region {
        id: inputMask
        item: root.expanded ? inputPlane : islandSurface
        radius: root.expanded ? 0 : islandSurface.radius
    }

    onExpandedChanged: {
        inputMask.changed();

        if (root.expanded) {
            Qt.callLater(function() {
                keyScope.forceActiveFocus();
            });
        } else {
            keyScope.focus = false;
        }
    }

    Item {
        id: inputPlane
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            enabled: root.expanded
            onClicked: root.requestClose()
        }

        FocusScope {
            id: keyScope
            anchors.fill: parent
            focus: root.expanded

            Keys.onPressed: event => {
                if (root.expanded && event.key === Qt.Key_Escape) {
                    root.requestClose();
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            id: islandSurface
            z: 10
            anchors.left: parent.left
            anchors.leftMargin: Theme.edgeGap
            y: Theme.edgeGap
            width: root.expanded ? Theme.expandedWidth : Theme.collapsedWidth
            height: root.expanded ? Theme.expandedHeight : Theme.collapsedHeight
            color: Theme.island
            border.width: Theme.borderWidth
            border.color: root.expanded ? Theme.lineStrong : Theme.line
            clip: true

            onXChanged: inputMask.changed()
            onYChanged: inputMask.changed()
            onWidthChanged: inputMask.changed()
            onHeightChanged: inputMask.changed()

            Behavior on width {
                NumberAnimation {
                    duration: Theme.durationIsland
                    easing.type: Theme.easingIsland
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Theme.durationIsland
                    easing.type: Theme.easingIsland
                }
            }

            Behavior on radius {
                NumberAnimation {
                    duration: Theme.durationStandard
                    easing.type: Easing.OutCubic
                }
            }

            // Swallow clicks on otherwise empty surface space so click-away only
            // fires for the transparent area outside the island.
            MouseArea {
                anchors.fill: parent
                z: 0
            }

            IslandCollapsed {
                z: 2
                width: parent.width
                height: root.expanded ? Theme.headerHeight : Theme.collapsedHeight
                workspaceText: root.workspaceText
                workspaces: root.workspaces
                timeText: root.timeText
                expanded: root.expanded
                attention: root.attention
                onActivated: root.requestToggle(root.outputName)
            }

            IslandExpanded {
                z: 2
                x: Theme.space12
                y: Theme.headerHeight + Theme.space10
                width: parent.width - Theme.space24
                height: parent.height - y - Theme.space12
                expanded: root.expanded

                opacity: root.expanded ? 1 : 0
                transform: Translate {
                    y: root.expanded ? 0 : 8

                    Behavior on y {
                        NumberAnimation {
                            duration: Theme.durationStandard
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationStandard
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
