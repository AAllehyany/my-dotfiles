import QtQuick

// Inert tray/menu interfaces: no desktop service or application is contacted.
QtObject {
    id: fixture
    property string id: "fixture"
    property string title: "Fixture"
    property string tooltipTitle: ""
    property string tooltipDescription: "Fixture only"
    property string icon: ""
    property bool onlyMenu: false
    readonly property bool hasMenu: !!menu
    property int quitCount: 0
    property int openCount: 0
    property int liveOpeners: 0
    property QtObject quitEntry: QtObject {
        property string text: "&Quit…"
        property bool enabled: true
        property bool isSeparator: false
        property bool hasChildren: false
        signal triggered()
        onTriggered: fixture.quitCount++
    }
    property QtObject menu: QtObject { property var entries: [fixture.quitEntry] }
    property Component openerComponent: Component {
        QtObject {
            property var menu: null
            readonly property var children: ({values: menu ? menu.entries : []})
            Component.onCompleted: fixture.liveOpeners++
            Component.onDestruction: { if (fixture) fixture.liveOpeners--; }
        }
    }
    function activate() { openCount++; }
}
