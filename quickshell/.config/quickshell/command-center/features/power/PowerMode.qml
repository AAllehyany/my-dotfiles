import QtQuick

QtObject {
    readonly property string modeId: "power"
    readonly property bool supportsSearch: false
    readonly property url customViewUrl: ""
    readonly property var sourceResults: [
        { resultId: "lock", title: "Lock", subtitle: "Lock this session", icon: "󰌾", actions: [{ actionId: "run", label: "Lock" }] },
        { resultId: "logout", title: "Log out", subtitle: "End this session", icon: "󰍃", actions: [{ actionId: "run", label: "Log out" }] },
        { resultId: "restart", title: "Restart", subtitle: "Restart the computer", icon: "󰜉", actions: [{ actionId: "run", label: "Restart" }] },
        { resultId: "poweroff", title: "Power off", subtitle: "Shut down the computer", icon: "󰐥", actions: [{ actionId: "run", label: "Power off" }] }
    ]
    function results(query) { return sourceResults }
    function activate(result, actionId) { console.log("power placeholder:", result.resultId, actionId) }
}
