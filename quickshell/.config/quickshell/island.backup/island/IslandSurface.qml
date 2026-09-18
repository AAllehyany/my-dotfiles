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
        bottom: true
        left: true
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
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.edgeGap
            width: root.expanded ? Theme.expandedWidth : Theme.collapsedWidth
            height: root.expanded ? Theme.expandedHeight : Theme.collapsedHeight
            radius: root.expanded
                ? Theme.radiusIslandExpanded
                : Theme.radiusIslandCollapsed
            color: Theme.island
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
                timeText: root.timeText
                expanded: root.expanded
                onActivated: root.requestToggle(root.outputName)
            }

            IslandExpanded {
                z: 2
                x: Theme.space16
                y: Theme.headerHeight + Theme.space4
                width: parent.width - Theme.space32
                height: parent.height - y - Theme.space16
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
