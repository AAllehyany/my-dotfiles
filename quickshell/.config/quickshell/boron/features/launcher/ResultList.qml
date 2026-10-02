import QtQuick

ListView {
    id: root
    required property var rows
    property string viewKey: ""
    property int selectionIndex: 0
    property int rowHeight: 56
    property bool synchronizing: false
    property string appliedKey: ""
    property bool initialized: false
    property real pointerX: -1
    property real pointerY: -1

    model: ListModel { id: items; dynamicRoles: true }
    highlightFollowsCurrentItem: false
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    // Coalesce bindings so selection, query and mode settle before updating the view.
    onRowsChanged: update.restart()
    onViewKeyChanged: update.restart()
    onSelectionIndexChanged: currentIndex = selectionIndex
    Component.onCompleted: update.restart()
    Timer { id: update; interval: 0; onTriggered: root.synchronize() }

    function synchronize() {
        update.stop();
        const reset = !initialized || appliedKey !== viewKey;
        const oldIds = [];
        for (let i = 0; i < items.count; i++) oldIds.push(items.get(i).rowData.id);
        const top = Math.max(0, Math.min(oldIds.length - 1, Math.floor((contentY - originY) / rowHeight)));
        const offset = Math.max(0, contentY - originY - top * rowHeight);
        // Anchor to the top visible item, independently of keyboard selection.
        // If it disappears, use the next surviving neighbor, then the previous one.
        let anchor = -1;
        for (let i = top; i < oldIds.length && anchor < 0; i++) anchor = rows.findIndex(r => r.id === oldIds[i]);
        for (let i = top - 1; i >= 0 && anchor < 0; i--) anchor = rows.findIndex(r => r.id === oldIds[i]);

        synchronizing = true;
        for (let i = 0; i < rows.length; i++) {
            let found = -1;
            for (let j = i; j < items.count; j++) {
                if (items.get(j).rowData.id === rows[i].id) { found = j; break; }
            }
            if (found < 0) items.insert(i, {rowData: rows[i]});
            else {
                if (found !== i) items.move(found, i, 1);
                items.setProperty(i, "rowData", rows[i]);
            }
        }
        if (items.count > rows.length) items.remove(rows.length, items.count - rows.length);
        currentIndex = rows.length ? Math.min(selectionIndex, rows.length - 1) : -1;
        forceLayout();
        if (reset || !rows.length) positionViewAtBeginning();
        else {
            if (anchor < 0) anchor = Math.min(top, rows.length - 1);
            const desired = originY + anchor * rowHeight + offset;
            contentY = Math.max(originY, Math.min(desired, originY + Math.max(0, contentHeight - height)));
        }
        appliedKey = viewKey;
        initialized = true;
        synchronizing = false;
    }

    // Only explicit keyboard navigation may scroll to the selected result.
    function revealSelection() {
        if (update.running) synchronize();
        positionViewAtIndex(selectionIndex, ListView.Contain);
    }
}
