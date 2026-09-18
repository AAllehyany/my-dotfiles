pragma Singleton
import QtQuick

QtObject {
    // The window only consumes this metadata and the adapter contract; mode behavior lives elsewhere.
    readonly property var modes: [
        { id: "applications", label: "Applications", icon: "󰀻", adapter: Qt.resolvedUrl("../features/applications/ApplicationsMode.qml") },
        { id: "system", label: "System", icon: "󰒓", adapter: Qt.resolvedUrl("../features/system/SystemMode.qml") },
        { id: "tray", label: "Tray", icon: "󰍜", adapter: Qt.resolvedUrl("../features/tray/TrayMode.qml") },
        { id: "power", label: "Power", icon: "󰐥", adapter: Qt.resolvedUrl("../features/power/PowerMode.qml") },
        { id: "calculator", label: "Calculator", icon: "󰃬", adapter: Qt.resolvedUrl("../features/calculator/CalculatorMode.qml") }
    ]
    function mode(modeId) {
        for (let i = 0; i < modes.length; ++i) if (modes[i].id === modeId) return modes[i]
        return modes[0]
    }
    function indexOf(modeId) {
        for (let i = 0; i < modes.length; ++i) if (modes[i].id === modeId) return i
        return 0
    }
    function cycle(modeId, delta) {
        const index = (indexOf(modeId) + delta + modes.length) % modes.length
        return modes[index].id
    }
}
