const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const search = vm.createContext({});
vm.runInContext(fs.readFileSync('core/Search.js', 'utf8'), search);
const rows = [{id:'other', title:'Terminal Tools'}, {id:'exact', title:'Terminal'}, {id:'fuzzy', title:'The Experimental Remote Manager And Launcher'}];
assert.equal(search.filter(rows, 'terminal')[0].id, 'exact');
assert.equal(search.filter(rows, 'trm')[0].id, 'exact');
assert.equal(search.filter(rows, 'zzzz').length, 0);
assert.equal(search.score('Terminal', 'TERMINAL'), 10000);
assert.equal(search.retainedIndex([{id:'b'}, {id:'a'}], 'a', 0), 1);
assert.equal(search.retainedIndex([{id:'b'}], 'gone', 9), 0);
const modes = [{id:'apps', aliases:[]}, {id:'devices', aliases:['wifi','bluetooth']}];
assert.equal(search.prefix('@wifi office', modes).id, 'devices');
assert.equal(search.prefix('@wifi office', modes).section, 'wifi');
assert.equal(search.prefix('@wifi office', modes).query, 'office');
assert.equal(search.prefix('@unknown test', modes), null);
assert.equal(search.prefix('email@example.org', modes), null);
const completionModes = [
    {id:'apps', label:'Applications', aliases:[]},
    {id:'devices', label:'Devices', aliases:['wifi','bluetooth'], aliasLabels:{wifi:'Devices · Wi-Fi'}},
    {id:'github', label:'GitHub', aliases:['gh']},
    {id:'jira-work', label:'Jira', aliases:['jira']}
];
assert.equal(search.completions('@', completionModes).length, 8);
assert.equal(search.completions('@', completionModes)[0].title, '@apps');
assert.equal(search.completions('@wi', completionModes)[0].title, '@wifi');
assert.equal(search.completions('@WI', completionModes)[0].section, 'wifi');
assert.equal(search.completions('@blu', completionModes)[0].modeId, 'devices');
assert.equal(search.completions('@blu', completionModes)[0].section, 'bluetooth');
assert.equal(search.completions('@gh', completionModes)[0].modeId, 'github');
assert.equal(search.completions('@jira', completionModes)[0].title, '@jira');
assert.equal(search.completions('@unknown', completionModes).length, 0);
assert.equal(search.completions('email@example.org', completionModes).length, 0);
assert.equal(search.completions('@wifi network', completionModes).length, 0);
assert.equal(search.completions('@wifi ', completionModes).length, 0);
assert.equal(search.completions('', completionModes).length, 0);
assert.equal(search.isModePrefix('@'), true);
assert.equal(search.isModePrefix('repo:owner/@name'), false);
console.log('Search, prefix routing and selection tests passed.');
