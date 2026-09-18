import QtQuick

QtObject {
    readonly property string modeId: "tray"
    readonly property bool supportsSearch: true
    readonly property url customViewUrl: ""
    readonly property var sourceResults: [
        { resultId: "updates", title: "Software Updates", subtitle: "No updates pending", icon: "󰏔", actions: [{ actionId: "open", label: "Open" }] },
        { resultId: "clipboard", title: "Clipboard Manager", subtitle: "Tray placeholder", icon: "󰅌", actions: [{ actionId: "open", label: "Open" }] }
    ]
    function results(query) {
        const needle = query.trim().toLowerCase()
        return sourceResults.filter(result => result.title.toLowerCase().includes(needle))
    }
    function activate(result, actionId) { console.log("tray placeholder:", result.resultId, actionId) }
}
