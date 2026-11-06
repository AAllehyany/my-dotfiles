// Launch history ranking. Shared by the launcher and the Node test runner; no Qt dependencies.
// history: {id: {count, last}} with `last` in milliseconds since the epoch.
var HALF_LIFE = 7 * 24 * 60 * 60 * 1000;

function score(entry, now) {
    if (!entry || !entry.count) return 0;
    const age = Math.max(0, now - (entry.last || 0));
    return entry.count * Math.pow(0.5, age / HALF_LIFE);
}

function prune(history, max, now) {
    const ids = Object.keys(history);
    if (ids.length <= max) return history;
    const kept = {};
    ids.sort((a, b) => score(history[b], now) - score(history[a], now) || a.localeCompare(b))
        .slice(0, max).forEach(id => kept[id] = history[id]);
    return kept;
}

// Returns a new history object; the input is not modified.
function record(history, id, now, max) {
    const next = Object.assign({}, history);
    const previous = next[id] || {count: 0, last: 0};
    next[id] = {count: previous.count + 1, last: now};
    return prune(next, max || 200, now);
}

function forget(history, id) {
    const next = Object.assign({}, history);
    delete next[id];
    return next;
}

// Ids from `available` with history, best first.
function top(history, available, n, now) {
    return available.filter(id => score(history[id], now) > 0)
        .sort((a, b) => score(history[b], now) - score(history[a], now) || a.localeCompare(b))
        .slice(0, n);
}

// Normalize stored JSON, dropping malformed entries.
function parse(text) {
    let raw;
    try { raw = JSON.parse(text); } catch (e) { return {}; }
    const out = {};
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) return out;
    for (const id of Object.keys(raw)) {
        const e = raw[id];
        if (e && Number.isFinite(e.count) && e.count > 0 && Number.isFinite(e.last)) out[id] = {count: e.count, last: e.last};
    }
    return out;
}
