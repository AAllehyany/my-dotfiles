import QtQuick

QtObject {
    id: root
    property int id: 0
    property bool tracked: false
    property bool lastGeneration: false
    property string summary: "Fixture notification"
    property string body: "A notification body"
    property string appName: "Fixture app"
    property string appIcon: ""
    property string image: ""
    property int urgency: 1
    property var hints: ({})
    property var actions: []
    property bool resident: false
    property bool dismissed: false
    property bool expired: false
    signal closed(int reason)
    signal transientChanged()
    function dismiss() { dismissed = true; tracked = false; closed(2); }
    function expire() { expired = true; tracked = false; closed(1); }
}
