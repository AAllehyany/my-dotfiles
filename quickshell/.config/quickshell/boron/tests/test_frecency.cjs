const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const f = vm.createContext({});
vm.runInContext(fs.readFileSync('core/Frecency.js', 'utf8'), f);
const same = (a, b, m) => assert.equal(JSON.stringify(a), JSON.stringify(b), m);
const day = 24 * 60 * 60 * 1000;
const now = 100 * day;

assert.equal(f.score(undefined, now), 0);
assert.equal(f.score({count: 4, last: now}, now), 4);
assert.equal(f.score({count: 4, last: now - 7 * day}, now), 2);

let h = {};
h = f.record(h, 'a', now);
h = f.record(h, 'a', now);
const before = JSON.stringify(h);
const h2 = f.record(h, 'b', now);
assert.equal(JSON.stringify(h), before, 'record does not mutate its input');
same(h2.a, {count: 2, last: now});
same(h2.b, {count: 1, last: now});

// Recent single launch beats a stale frequent one after enough decay.
const mixed = {old: {count: 8, last: now - 30 * day}, fresh: {count: 1, last: now}, gone: {count: 50, last: now}};
same((f.top(mixed, ['old', 'fresh', 'never'], 5, now)), ['fresh', 'old']);
same((f.top(mixed, ['old', 'fresh'], 1, now)), ['fresh']);

let big = {};
for (let i = 0; i < 10; i++) big = f.record(big, 'app' + i, now + i, 5);
assert.equal(Object.keys(big).length, 5);
assert.ok(big.app9 && !big.app0, 'prune keeps the most recent entries');

assert.equal(f.forget({a: {count: 1, last: 1}}, 'a').a, undefined);
same(f.parse('not json'), {});
same(f.parse('[1]'), {});
same(f.parse('{"a":{"count":2,"last":5},"b":{"count":"x"},"c":null}'), {a: {count: 2, last: 5}});
console.log('Frecency tests passed.');
