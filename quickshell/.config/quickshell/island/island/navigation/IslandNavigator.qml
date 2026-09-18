import QtQuick
import QtQuick.Controls.Basic

import qs.theme

StackView {
    id: root

    clip: true

    readonly property bool canGoBack: root.depth > 1

    function open(page): void {
        root.pushItem(page);
    }

    function goBack(): void {
        if (root.canGoBack)
            root.popCurrentItem();
    }

    function reset(): void {
        while (root.depth > 1)
            root.popCurrentItem(StackView.Immediate);
    }

    pushEnter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "x"
                from: 12
                to: 0
                duration: Theme.durationStandard
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.durationStandard
            }
        }
    }

    pushExit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "x"
                from: 0
                to: -8
                duration: Theme.durationStandard
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Theme.durationStandard
            }
        }
    }

    popEnter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "x"
                from: -8
                to: 0
                duration: Theme.durationStandard
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.durationStandard
            }
        }
    }

    popExit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "x"
                from: 0
                to: 12
                duration: Theme.durationStandard
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Theme.durationStandard
            }
        }
    }
}
