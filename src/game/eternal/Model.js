﻿const hasEdge = (graph, v, w) => graph[v].includes(w);

const addEdge = (graph, v, w) => {
    graph[v].push(w);
    graph[w].push(v);
}

const graphFromEdges = (n, edges) => {
    const g = []
    for (let i = 0; i < n; i++)
        g.push([]);
    edges.forEach(({x, y}) => addEdge(g, x, y));
    return g;
}

const Map_dec = (map, key) => {
    const v = map.get(key) - 1;
    map.set(key, v);
    return v;
};

const minBy = (list, fn) => {
    let min = undefined;
    let bestScore = Infinity;
    let n = list.length;
    for (let i = 0; i < n; i++) {
        const x = list[i];
        const score = fn(x);
        if (score < bestScore) {
            bestScore = score;
            min = x;
        } 
    }
    return min;
};

const maxBy = (list, fn) => {
    let max = undefined;
    let bestScore = -Infinity;
    let n = list.length;
    for (let i = 0; i < n; i++) {
        const x = list[i];
        const score = fn(x);
        if (score > bestScore) {
            bestScore = score;
            max = x;
        } 
    }
    return max;
};


const countBy = (list, fn) => {
    let count = 0;
    let n = list.length;
    for (let i = 0; i < n; i++) {
        if (fn(list[i], i))
            count++;
    }
    return count;
};

const allDifferent = list => {
    let pred = null;
    const n = list.length;
    for (let i = 0; i < n; i++) {
        const x = list[i];
        if (x === pred)
            return false;
        pred = x;
    }
    return true;
};


function* sublists(n, k) {
    if (k === 0) {
        yield [];
    } else if (k <= n) {
        yield * sublists(n - 1, k);
        for (const l of sublists(n - 1, k - 1)) {
            yield l.concat(n - 1);
        }
    }
}

function* permutations(list) {
    if (list.length <= 1) {
        yield list;
    } else {
        for (let i = 0; i < list.length; i++) {
            for (const perm of permutations(list.slice(0, i).concat(list.slice(i + 1, list.length)))) {
                yield [list[i]].concat(perm);
            }
        }
    }
}



const makeArenaGraph = arena => {
    const adj = new Map();
    const reverseAdj = new Map();
    
    const confs = [...arena.AConfs(), ...arena.BConfs()];

    for (const conf of confs) {
        adj.set(conf.toString(), []);
        reverseAdj.set(conf.toString(), []);
    }

    for (const conf of confs) {
        for (const conf2 of arena.neighbors(conf)) {
            adj.get(conf.toString()).push(conf2);
            reverseAdj.get(conf2.toString()).push(conf);
        }
    }
    const attractor = computeAttractor(arena, adj, reverseAdj);
    return Object.assign({adj, reverseAdj, attractor}, arena);
}

const computeAttractor = (arena, adj, reverseAdj) => {
    const attractor = new Map();
    const deg = new Map();
    const stack = [];

    for (const conf of arena.BConfs()) {
        const nbor = adj.get(conf.toString());
        deg.set(conf.toString(), nbor.length);
        if (nbor.length === 0) { // final winning configurations for the attacker
            stack.push(conf);
            attractor.set(conf.toString(), 1);
        }
    }

    while (stack.length > 0) {
        const elem = stack.shift();
        const strelem = elem.toString();
        const elemval = attractor.get(strelem)
        for (const pred of reverseAdj.get(strelem)) {
            const rpred = pred.toString()
            if (!attractor.has(rpred) &&  (arena.isAConf(pred) || Map_dec(deg, rpred) === 0)) {
                attractor.set(rpred, elemval+1);
                stack.push(pred);
            }
        }
    }
    return attractor;
}

const answer = (arenaGraph, conf) => {
    const defs = arenaGraph.adj.get(conf.toString());
    return maxBy(defs, conf2 => arenaGraph.attractor.get(conf2.toString() || -1000));
}


function * multiMoves(graph, conf, i) {
    if (i === conf.length) {
        yield conf;
    } else {
        for (const conf2 of multiMoves(graph, conf, i + 1)) {
            yield conf2;
            for (const nbor of graph[conf2[i]]) {
                const conf3 = conf2.slice();
                conf3[i] = nbor;
                yield conf3;
            }
        }
    }
}
    
function * attackerPossibilities(graph, guards) {
    for (let attack = 0; attack < graph.length; attack++) {
        if (!guards.includes(attack)) {
            yield guards.concat(attack);
        }
    }
}
    
function * oneGuardPossibilities (graph, conf) {
    const attack = conf[conf.length - 1];
    const guards = conf.slice(0, conf.length - 1);
    
    for (let i = 0; i < guards.length; i++) {
        if (hasEdge(graph, guards[i], attack)) {
            const guards2 = guards.slice();
            guards2[i] = attack;
            guards2.sort((a, b) => a - b);
            yield guards2;
        }
    }
}
    
function * allGuardsPossibilities (graph, conf) {
    const gconf = conf.slice();
    const attack = gconf.pop();
    for (const conf2 of multiMoves(graph, gconf, 0)) {
        const conf3 = conf2.slice();
        conf3.sort((a, b) => a - b);
        if (allDifferent(conf3) && conf3.includes(attack)) {
            yield conf3;
        }
    }
}
    
const oneRules = {
    attackerPossibilities,
    guardsPossibilities: oneGuardPossibilities
};
    
const allRules = {
    attackerPossibilities,
    guardsPossibilities: allGuardsPossibilities
};
    
const makeRules = name => name === 'one' ? oneRules : allRules;

exports.guardsAnswerAux = nothing => just => edsgraph => guards => attack => {
    const ans = answer(edsgraph, guards.slice().sort((a, b) => a - b).concat(attack));
    if (!ans) {
        return nothing;
    }
    const perms = [...permutations(ans)];
    const fperms = perms.filter(x => x.every((guard, i) => guard === guards[i] || hasEdge(edsgraph.graph, guard, guards[i])))
    return just(minBy(fperms, l => countBy(l, (guard, i) => guard !== guards[i])))
};

exports.attackerAnswer = arenaGraph => conf => {
    const attacks = arenaGraph.adj.get(conf.toString())
    const minattack = minBy(attacks, attack => arenaGraph.attractor.get(attack.toString()) || 1000)
    return minattack[minattack.length-1];
}

exports.makeEDSAux = n => edges => rulesName => k => {
    const graph = graphFromEdges(n, edges)
    const rules = makeRules(rulesName)
    function* bconfs () {
        for (const conf of sublists(graph.length, k)) {
            for (let i = 0; i < n; i++) {
                if (!conf.includes(i)) {
                    yield conf.concat(i);
                }
            }
        }
    }

    const arena = {
        AConfs: (() => sublists(graph.length, k)),
        BConfs: bconfs,
        isAConf: (conf => conf.length === k),
        neighbors: (conf => conf.length === k
            ? rules.attackerPossibilities(graph, conf)
            : rules.guardsPossibilities(graph, conf)
        )
    };

    const arenaGraph = makeArenaGraph(arena);
    return Object.assign({graph}, arenaGraph);
};
