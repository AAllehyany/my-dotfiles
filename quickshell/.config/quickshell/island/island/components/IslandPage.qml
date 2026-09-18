import QtQuick

import qs.theme

Item {
    id: root

    property string title: ""

    property bool empty: false
    property string emptyText: "NO RESULTS"

    property Component emptyState: null
    property Component footer: null

    default property alias content: contentHost.data

    signal backRequested()

    PageHeader {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        title: root.title

        onBackRequested: {
            root.backRequested();
        }
    }

    Rectangle {
        id: separator

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: Theme.space8

        height: 1

        color: Theme.line
    }

    Item {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: separator.bottom
        anchors.topMargin: Theme.space8

        anchors.bottom: footerLoader.active
            ? footerLoader.top
            : parent.bottom

        anchors.bottomMargin: footerLoader.active
            ? Theme.space8
            : 0

        Item {
            id: contentHost

            anchors.fill: parent

            visible: !root.empty
        }

        Loader {
            anchors.fill: parent

            active: root.empty

            sourceComponent: root.emptyState !== null
                ? root.emptyState
                : defaultEmptyState
        }
    }

    Loader {
        id: footerLoader

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        active: root.footer !== null
        sourceComponent: root.footer

        height: active && item
            ? item.implicitHeight
            : 0
    }

    Component {
        id: defaultEmptyState

        Text {
            text: root.emptyText

            color: Theme.muted
            font.family: Theme.fontFamily

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
