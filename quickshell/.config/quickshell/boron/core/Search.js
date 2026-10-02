// Shared by the launcher and the Node test runner; no Qt dependencies.
function score(text, query) {
    text = String(text || "").toLowerCase();
    query = String(query || "").trim().toLowerCase();
    if (!query) return 1;
    if (text === query) return 10000;
    if (text.startsWith(query)) return 8000 - text.length;
    const at = text.indexOf(query);
    if (at >= 0) return 6000 - at;
    let pos = -1, gaps = 0;
    for (const c of query) {
        const next = text.indexOf(c, pos + 1);
        if (next < 0) return 0;
        gaps += next - pos - 1;
        pos = next;
    }
    return Math.max(1, 1000 - gaps - text.length);
}
function filter(rows, query) {
    return rows.map(row => ({row: row, score: Math.max(score(row.title, query),
        score(row.keywords || row.subtitle, query) * 0.6)}))
        .filter(x => x.score > 0)
        .sort((a, b) => b.score - a.score || a.row.title.localeCompare(b.row.title) || a.row.id.localeCompare(b.row.id))
        .map(x => x.row);
}
function retainedIndex(rows, id, previous) {
    const index = rows.findIndex(r => r.id === id);
    return index >= 0 ? index : Math.max(0, Math.min(previous, rows.length - 1));
}
function prefix(text, modes) {
    const match = /^@([\w-]+)\s([\s\S]*)$/.exec(text);
    if (!match) return null;
    const alias = match[1].toLowerCase();
    const mode = modes.find(m => m.id === alias || (m.aliases || []).includes(alias));
    return mode ? {id: mode.id, query: match[2], section: ["wifi", "bluetooth"].includes(alias) ? alias : ""} : null;
}

function isModePrefix(text) {
    return /^@[\w-]*$/.test(text);
}

function completions(text, modes) {
    if (!isModePrefix(text)) return [];
    const query = text.slice(1).toLowerCase();
    const seen = new Set();
    const matches = [];
    for (const mode of modes) {
        for (const name of [mode.id].concat(mode.aliases || [])) {
            if (seen.has(name) || !name.toLowerCase().startsWith(query)) continue;
            seen.add(name);
            matches.push({
                id: "prefix:" + name, title: "@" + name,
                subtitle: (mode.aliasLabels || {})[name] || mode.label + (name !== mode.id ? " · Alias for @" + mode.id : ""),
                modeId: mode.id, section: ["wifi", "bluetooth"].includes(name) ? name : "",
                completion: name
            });
        }
    }
    // Keep registry order for equal matches, including on Qt JS engines with unstable sort.
    return matches.filter(row => row.completion.toLowerCase() === query)
        .concat(matches.filter(row => row.completion.toLowerCase() !== query));
}
