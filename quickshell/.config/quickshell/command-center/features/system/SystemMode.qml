import QtQuick

QtObject {
    readonly property string modeId: "system"
    readonly property bool supportsSearch: false
    readonly property url customViewUrl: Qt.resolvedUrl("SystemView.qml")
    function results(query) { return [] }
    function activate(result, actionId) {}
}
