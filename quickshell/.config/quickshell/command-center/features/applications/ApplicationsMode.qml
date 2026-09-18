import QtQuick

QtObject {
    readonly property string modeId: "applications"
    readonly property bool supportsSearch: true
    readonly property url customViewUrl: ""
    readonly property var sourceResults: [
        { resultId: "terminal", title: "Terminal", subtitle: "Open a terminal", icon: "󰆍", actions: [{ actionId: "open", label: "Open" }, { actionId: "details", label: "Show details" }] },
        { resultId: "browser", title: "Web Browser", subtitle: "Browse the web", icon: "󰖟", actions: [{ actionId: "open", label: "Open" }] },
        { resultId: "files", title: "Files", subtitle: "Browse local files", icon: "󰉋", actions: [{ actionId: "open", label: "Open" }] },
        { resultId: "editor", title: "Text Editor", subtitle: "Edit a document", icon: "󰅩", actions: [{ actionId: "open", label: "Open" }] }
    ]
    function results(query) {
        const needle = query.trim().toLowerCase()
        return needle.length === 0 ? sourceResults : sourceResults.filter(result =>
            result.title.toLowerCase().includes(needle) || result.subtitle.toLowerCase().includes(needle))
    }
    function activate(result, actionId) { console.log("application placeholder:", result.resultId, actionId) }
}
