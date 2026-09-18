import QtQuick

QtObject {
    readonly property string modeId: "calculator"
    readonly property bool supportsSearch: true
    readonly property url customViewUrl: Qt.resolvedUrl("CalculatorView.qml")
    function results(query) { return [] }
    function activate(result, actionId) {}
}
