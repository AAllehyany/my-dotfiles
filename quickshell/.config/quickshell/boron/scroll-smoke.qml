// Real ListView regression tests with fixture data and an offscreen Qt window.
import QtQuick
import Quickshell
import "features/launcher"
import "core/Search.js" as Search

ShellRoot {
    id: test
    property int step: 0
    property var rows: Array.from({length: 40}, (_, i) => ({id: "device:" + i, title: "Device " + i, subtitle: "Available"}))
    property int selection: 3
    property string selectionId: "device:3"
    property real expectedY: 0
    property var previousDelegate: null
    onRowsChanged: selection = Search.retainedIndex(rows, selectionId, selection)
    function check(condition, message) {
        if (!condition) {
            ticks.stop();
            throw new Error("SCROLL SMOKE FAILED: " + message);
        }
    }
    function topId() { return rows[Math.round((list.contentY - list.originY - 13) / 56)].id; }
    Window {
        width: 400; height: 224; visible: true
        ResultList {
            id: list
            anchors.fill: parent
            rows: test.rows
            viewKey: "devices:wifi"
            selectionIndex: test.selection
            delegate: Rectangle {
                required property var rowData
                required property int index
                width: list.width; height: 56
                Text { text: parent.rowData.title + " " + parent.rowData.subtitle }
            }
        }
    }
    Timer {
        id: ticks
        interval: 120; running: true; repeat: true
        onTriggered: {
            switch (test.step++) {
            case 0:
                list.contentY = list.originY + 17 * 56 + 13;
                break;
            case 1:
                test.expectedY = list.contentY;
                test.previousDelegate = list.itemAtIndex(17);
                test.rows = test.rows.map(r => Object.assign({}, r, {subtitle: "Updated signal strength"}));
                break;
            case 2:
                check(Math.abs(list.contentY - test.expectedY) < 1, "status refresh preserves exact scroll offset");
                check(list.itemAtIndex(17) === test.previousDelegate, "status refresh preserves delegates");
                check(list.itemAtIndex(17).rowData.subtitle === "Updated signal strength", "status updates still render");
                test.rows = [{id: "new", title: "Discovered device"}].concat(test.rows);
                break;
            case 3:
                check(topId() === "device:17", "insertion above viewport retains visible anchor");
                check(test.rows[test.selection].id === "device:3", "selection identity survives insertion");
                // Reorder selected item out of the viewport. Selection must not pull the scroll with it.
                test.rows = test.rows.filter(r => r.id !== "device:3").concat([test.rows.find(r => r.id === "device:3")]);
                break;
            case 4:
                check(topId() === "device:17", "reordering selected result does not jump the viewport");
                test.rows = test.rows.filter(r => r.id !== "device:17");
                break;
            case 5:
                check(topId() === "device:18", "removed anchor falls forward to surviving neighbor");
                test.expectedY = list.contentY;
                test.rows = test.rows.concat([{id: "last", title: "Another discovered device"}]);
                break;
            case 6:
                check(Math.abs(list.contentY - test.expectedY) < 1, "append does not move viewport");
                test.selection = test.rows.length - 1;
                list.revealSelection();
                break;
            case 7:
                check(list.contentY >= list.contentHeight - list.height - 1, "explicit keyboard navigation reveals selection");
                list.viewKey = "devices:bluetooth";
                break;
            case 8:
                check(Math.abs(list.contentY - list.originY) < 1, "switching tabs starts at the top");
                test.rows = [];
                break;
            case 9:
                check(list.count === 0, "empty refresh is safe");
                test.rows = [{id: "returning", title: "Device returned"}];
                break;
            case 10:
                check(list.count === 1 && Math.abs(list.contentY - list.originY) < 1, "repopulation stays within bounds");
                console.warn("SCROLL SMOKE PASSED");
                Qt.quit();
            }
        }
    }
}
