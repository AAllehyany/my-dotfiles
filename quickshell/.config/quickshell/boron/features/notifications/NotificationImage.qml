import QtQuick
import Quickshell

Item {
    id: root
    property string image: ""
    property string appIcon: ""
    property int size: 40
    readonly property bool available: picture.status === Image.Ready || fallback.status === Image.Ready
    implicitWidth: available ? size : 0
    implicitHeight: size
    Image {
        id: picture
        anchors.fill: parent
        source: root.image
        sourceSize.width: root.size; sourceSize.height: root.size
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
    }
    Image {
        id: fallback
        anchors.fill: parent
        source: !root.appIcon ? "" : root.appIcon.startsWith("/") || root.appIcon.includes(":") ? root.appIcon : Quickshell.iconPath(root.appIcon, true)
        sourceSize.width: root.size; sourceSize.height: root.size
        fillMode: Image.PreserveAspectFit
        visible: picture.status !== Image.Ready && status === Image.Ready
    }
}
