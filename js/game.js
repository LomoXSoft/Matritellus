/* Matritellus — prologue prototype. Plain script, needs THREE (global) and window.MAP (js/mapdata.js). */
(() => {
'use strict';
const M = window.MAP, N = M.nodes, [XMIN, XMAX, ZMIN, ZMAX] = M.bounds;
const $ = id => document.getElementById(id);
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const rand = (a, b) => a + Math.random() * (b - a);
const pick = a => a[Math.floor(Math.random() * a.length)];
const angLerp = (a, b, t) => a + ((((b - a + Math.PI) % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI) - Math.PI) * t;
const poi = name => M.pois.find(p => p.n.includes(name)) || { x: 0, z: 0 };

/* ================= renderer ================= */
const renderer = new THREE.WebGLRenderer({ canvas: $('view'), antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 1.5));
const scene = new THREE.Scene();
const SKY = 0xbfe3f2;
scene.background = new THREE.Color(SKY);
scene.fog = new THREE.Fog(SKY, 260, 1100);
const camera = new THREE.PerspectiveCamera(55, 1, 1, 1600);
scene.add(new THREE.HemisphereLight(0xffffff, 0xd8b98a, 0.95));
const sun = new THREE.DirectionalLight(0xfff1d6, 0.9); sun.position.set(-0.5, 1, 0.35); scene.add(sun);
function resize() { renderer.setSize(innerWidth, innerHeight, false); camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix(); }
addEventListener('resize', resize); resize();

const matCache = new Map();
const mat = (color, opts) => {
  const k = color + JSON.stringify(opts || 0);
  if (!matCache.has(k)) matCache.set(k, new THREE.MeshLambertMaterial(Object.assign({ color }, opts)));
  return matCache.get(k);
};

/* ================= road segments + spatial grids ================= */
const CELL = 40, gk = (cx, cz) => (cx + 512) * 4096 + (cz + 512);
const segs = [], segGrid = new Map(), colGrid = new Map();
const gridAdd = (grid, x0, z0, x1, z1, item) => {
  for (let cx = Math.floor(x0 / CELL); cx <= Math.floor(x1 / CELL); cx++)
    for (let cz = Math.floor(z0 / CELL); cz <= Math.floor(z1 / CELL); cz++) {
      const k = gk(cx, cz); let a = grid.get(k); if (!a) grid.set(k, a = []); a.push(item);
    }
};
for (const r of M.roads) for (let i = 0; i + 1 < r.p.length; i++) {
  const a = r.p[i] * 2, b = r.p[i + 1] * 2;
  const s = { ax: N[a], az: N[a + 1], bx: N[b], bz: N[b + 1], hw: r.w / 2, r, a: r.p[i] };
  segs.push(s);
  gridAdd(segGrid, Math.min(s.ax, s.bx) - 12, Math.min(s.az, s.bz) - 12, Math.max(s.ax, s.bx) + 12, Math.max(s.az, s.bz) + 12, s);
}
const sp = { x: 0, z: 0, d: 0 };
function segPoint(s, x, z) {
  const dx = s.bx - s.ax, dz = s.bz - s.az, L = dx * dx + dz * dz;
  const t = L ? clamp(((x - s.ax) * dx + (z - s.az) * dz) / L, 0, 1) : 0;
  sp.x = s.ax + t * dx; sp.z = s.az + t * dz; sp.d = Math.hypot(x - sp.x, z - sp.z); return sp.d;
}
/** nearest road at runtime (grid). Returns distance beyond the road edge (<=0 means on it) and sets roadHit. */
let roadHit = null;
function roadEdgeDist(x, z) {
  const list = segGrid.get(gk(Math.floor(x / CELL), Math.floor(z / CELL)));
  let best = 99; roadHit = null;
  if (list) for (const s of list) { const d = segPoint(s, x, z) - s.hw; if (d < best) { best = d; roadHit = s; } }
  return best;
}
/* road graph (no footpaths) and its biggest connected piece, so missions never point at an orphan service road */
const NODE_N = N.length / 2, adj = Array.from({ length: NODE_N }, () => []);
for (const r of M.roads) {
  if (r.k === 2) continue;
  const mult = r.k === 1 ? 2.2 : r.h.startsWith('motorway') ? 4 : r.h === 'service' ? 1.5 : 1;
  for (let i = 0; i + 1 < r.p.length; i++) { const a = r.p[i], b = r.p[i + 1], c = Math.hypot(N[a * 2] - N[b * 2], N[a * 2 + 1] - N[b * 2 + 1]) * mult; adj[a].push(b, c); adj[b].push(a, c); }
}
const mainComp = new Uint8Array(NODE_N);
{ const comp = new Int32Array(NODE_N).fill(-1); let bestId = -1, bestSize = 0;
  for (let i = 0; i < NODE_N; i++) { if (comp[i] >= 0 || !adj[i].length) continue; const st = [i]; comp[i] = i; let size = 0;
    while (st.length) { const u = st.pop(); size++; for (let k = 0; k < adj[u].length; k += 2) { const v = adj[u][k]; if (comp[v] < 0) { comp[v] = i; st.push(v); } } }
    if (size > bestSize) { bestSize = size; bestId = i; } }
  for (let i = 0; i < NODE_N; i++) mainComp[i] = comp[i] === bestId ? 1 : 0; }
const drivable = s => s.r.k === 0 && s.r.h !== 'motorway' && s.r.h !== 'motorway_link' && mainComp[s.a];
/** brute-force nearest road point (init time only) */
function nearestRoad(x, z, filter = drivable) {
  let best = null, bd = 1e9;
  for (const s of segs) { if (!filter(s)) continue; const d = segPoint(s, x, z); if (d < bd) { bd = d; best = { x: sp.x, z: sp.z, s, d }; } }
  const L = Math.hypot(best.s.bx - best.s.ax, best.s.bz - best.s.az) || 1;
  best.ux = (best.s.bx - best.s.ax) / L; best.uz = (best.s.bz - best.s.az) / L;
  return best;
}

/* colliders */
function addBoxCollider(x, z, w, d, rot) {
  const o = { t: 0, x, z, hw: w / 2, hd: d / 2, c: Math.cos(rot), s: Math.sin(rot) };
  const R = Math.hypot(o.hw, o.hd) + 4; gridAdd(colGrid, x - R, z - R, x + R, z + R, o);
}
function addCircleCollider(x, z, r) { const o = { t: 1, x, z, r }; gridAdd(colGrid, x - r - 4, z - r - 4, x + r + 4, z + r + 4, o); }
const hitN = { x: 0, z: 0 };
/** pushes circle p{x,z} radius r out of static geometry; true if it touched something (normal in hitN) */
function collide(p, r, boxesOnly) {
  const list = colGrid.get(gk(Math.floor(p.x / CELL), Math.floor(p.z / CELL)));
  let hit = false;
  if (list) for (const o of list) {
    if (o.t === 1) {
      if (boxesOnly) continue;
      const dx = p.x - o.x, dz = p.z - o.z, rr = r + o.r, d2 = dx * dx + dz * dz;
      if (d2 < rr * rr) { const d = Math.sqrt(d2) || 0.001; p.x = o.x + dx / d * rr; p.z = o.z + dz / d * rr; hitN.x = dx / d; hitN.z = dz / d; hit = true; }
      continue;
    }
    const dx = p.x - o.x, dz = p.z - o.z, lx = dx * o.c + dz * o.s, lz = -dx * o.s + dz * o.c;
    const ex = lx - clamp(lx, -o.hw, o.hw), ez = lz - clamp(lz, -o.hd, o.hd), d2 = ex * ex + ez * ez;
    if (d2 > r * r) continue;
    let nlx, nlz, pen;
    if (d2 > 1e-8) { const d = Math.sqrt(d2); nlx = ex / d; nlz = ez / d; pen = r - d; }
    else { const px = o.hw - Math.abs(lx), pz = o.hd - Math.abs(lz);
      if (px < pz) { nlx = Math.sign(lx) || 1; nlz = 0; pen = px + r; } else { nlx = 0; nlz = Math.sign(lz) || 1; pen = pz + r; } }
    const nx = nlx * o.c - nlz * o.s, nz = nlx * o.s + nlz * o.c;
    p.x += nx * pen; p.z += nz * pen; hitN.x = nx; hitN.z = nz; hit = true;
  }
  if (p.x < XMIN + 5) { p.x = XMIN + 5; hitN.x = 1; hitN.z = 0; hit = true; } if (p.x > XMAX - 5) { p.x = XMAX - 5; hitN.x = -1; hitN.z = 0; hit = true; }
  if (p.z < ZMIN + 5) { p.z = ZMIN + 5; hitN.x = 0; hitN.z = 1; hit = true; } if (p.z > ZMAX - 5) { p.z = ZMAX - 5; hitN.x = 0; hitN.z = -1; hit = true; }
  return hit;
}

/* ================= world meshes ================= */
function flatMesh(pos, idx, color, y) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  const nrm = new Float32Array(pos.length); for (let i = 1; i < nrm.length; i += 3) nrm[i] = 1;
  g.setAttribute('normal', new THREE.BufferAttribute(nrm, 3)); g.setIndex(idx);
  const m = new THREE.Mesh(g, new THREE.MeshLambertMaterial({ color, side: THREE.DoubleSide }));
  m.position.y = y; scene.add(m); return m;
}
function ribbon(filter, extra, color, y) {
  const pos = [], idx = [];
  for (const r of M.roads) {
    if (!filter(r)) continue;
    const hw = (r.w + extra) / 2;
    for (let i = 0; i < r.p.length; i++) {
      const ax = N[r.p[i] * 2], az = N[r.p[i] * 2 + 1];
      let b = pos.length / 3; pos.push(ax, 0, az);                    // round joint
      for (let k = 0; k < 8; k++) { const a = k * Math.PI / 4; pos.push(ax + Math.cos(a) * hw, 0, az + Math.sin(a) * hw); idx.push(b, b + 1 + k, b + 1 + (k + 1) % 8); }
      if (i + 1 === r.p.length) break;
      const bx = N[r.p[i + 1] * 2], bz = N[r.p[i + 1] * 2 + 1], dx = bx - ax, dz = bz - az, L = Math.hypot(dx, dz);
      if (L < 0.01) continue;
      const nx = -dz / L * hw, nz = dx / L * hw; b = pos.length / 3;
      pos.push(ax + nx, 0, az + nz, ax - nx, 0, az - nz, bx - nx, 0, bz - nz, bx + nx, 0, bz + nz); idx.push(b, b + 1, b + 2, b, b + 2, b + 3);
    }
  }
  return flatMesh(pos, idx, color, y);
}
{ // ground + land use
  const g = new THREE.Mesh(new THREE.PlaneGeometry(9000, 9000), mat(0xe3cf95)); g.rotation.x = -Math.PI / 2; scene.add(g);
  const AREA_COL = [0x9ccf6e, 0x74b98c, 0xb3bd62, 0xd3c486, 0xecd9a0, 0x6fc3e0];
  for (let k = 0; k < 6; k++) {
    const pos = [], idx = [];
    for (const a of M.areas) {
      if (a.k !== k) continue;
      const pts = []; for (let i = 0; i < a.p.length; i += 2) pts.push(new THREE.Vector2(a.p[i], a.p[i + 1]));
      const b = pos.length / 3; for (const p of pts) pos.push(p.x, 0, p.y);
      for (const t of THREE.ShapeUtils.triangulateShape(pts, [])) idx.push(b + t[0], b + t[1], b + t[2]);
    }
    if (idx.length) flatMesh(pos, idx, AREA_COL[k], k < 2 || k === 5 ? 0.06 : 0.03);
  }
  ribbon(r => r.k === 1, 0, 0xc9a66b, 0.09);                 // dirt tracks
  ribbon(r => r.k === 0, 3.2, 0xd9d2c4, 0.12);               // pavements
  ribbon(r => r.k === 2, 0, 0xe8dcc0, 0.15);                 // footpaths / plazas
  ribbon(r => r.k === 0, 0, 0x6f6a72, 0.18);                 // asphalt
}
{ // buildings
  const cv = document.createElement('canvas'); cv.width = cv.height = 256; const c = cv.getContext('2d');
  c.fillStyle = '#fff'; c.fillRect(0, 0, 256, 256);
  c.fillStyle = '#4667b5'; c.fillRect(0, 214, 256, 42);                              // añil skirting, very La Mancha
  const win = (x, y) => { c.fillStyle = '#7a5230'; c.fillRect(x - 4, y - 4, 52, 68); c.fillStyle = '#2f4a6b'; c.fillRect(x, y, 44, 60); c.fillStyle = '#7a5230'; c.fillRect(x + 20, y, 4, 60); c.fillStyle = '#333'; for (let i = 0; i < 5; i++) c.fillRect(x - 2 + i * 11, y + 30, 3, 32); c.fillRect(x - 4, y + 30, 52, 3); };
  win(30, 60); win(182, 60);
  c.fillStyle = '#6b4424'; c.fillRect(100, 132, 56, 124); c.fillStyle = '#4d2f16'; c.fillRect(126, 132, 4, 124); c.fillStyle = '#e8c04a'; c.fillRect(118, 196, 6, 6);
  const tex = new THREE.CanvasTexture(cv); tex.colorSpace = THREE.SRGBColorSpace; tex.anisotropy = 4;
  const n = M.boxes.length;
  const walls = new THREE.InstancedMesh(new THREE.BoxGeometry(1, 1, 1), new THREE.MeshLambertMaterial({ map: tex }), n);
  const rg = new THREE.BufferGeometry();   // gable roof prism, ridge along x
  const A = [-.5, 0, -.5], B = [.5, 0, -.5], C = [.5, 0, .5], D = [-.5, 0, .5], E = [-.5, 1, 0], F = [.5, 1, 0];
  rg.setAttribute('position', new THREE.Float32BufferAttribute([].concat(A, E, F, A, F, B, D, C, F, D, F, E, A, D, E, B, F, C), 3)); rg.computeVertexNormals();
  const roofs = new THREE.InstancedMesh(rg, new THREE.MeshLambertMaterial(), n);
  const WALLS = [0xfffaf0, 0xfffaf0, 0xfff3dc, 0xf7ead0, 0xffe9d6, 0xfdf0c8, 0xeaf2f5], ROOFS = [0xc9603a, 0xb9552f, 0xd4744a, 0xa84e2e];
  const d = new THREE.Object3D(), col = new THREE.Color();
  M.boxes.forEach((b, i) => {
    const [x, z, w, dp, rot, h, kind] = b;
    d.position.set(x, h / 2, z); d.rotation.set(0, -rot, 0); d.scale.set(w, h, dp); d.updateMatrix(); walls.setMatrixAt(i, d.matrix);
    walls.setColorAt(i, col.set(kind === 3 ? 0xd6d9dc : kind ? 0xecd9ae : pick(WALLS)));
    const flat = kind === 3;
    d.position.set(x, h, z); d.scale.set(w + 0.5, flat ? 0.5 : Math.min(3.4, Math.min(w, dp) * 0.32), dp + 0.5); d.updateMatrix(); roofs.setMatrixAt(i, d.matrix);
    roofs.setColorAt(i, col.set(flat ? 0x9aa3a8 : pick(ROOFS)));
    addBoxCollider(x, z, w, dp, rot);
    if (kind === 2 && w * dp > 250) {   // bell tower
      const t = new THREE.Mesh(new THREE.BoxGeometry(6, 26, 6), mat(0xe6cf9f)); t.position.set(x + Math.cos(rot) * (w / 2 - 3), 13, z + Math.sin(rot) * (w / 2 - 3)); t.rotation.y = -rot; scene.add(t);
      const cap = new THREE.Mesh(new THREE.ConeGeometry(4.6, 6, 4), mat(0x5d6470)); cap.position.set(t.position.x, 29, t.position.z); cap.rotation.y = -rot + Math.PI / 4; scene.add(cap);
    }
  });
  scene.add(walls, roofs);
}
{ // trees: 0 round, 1 olive, 2 cypress
  const T = M.trees, d = new THREE.Object3D();
  const trunk = new THREE.InstancedMesh(new THREE.CylinderGeometry(0.22, 0.32, 1, 6), mat(0x7a5536), T.length);
  const leaf = [new THREE.IcosahedronGeometry(1, 1), new THREE.IcosahedronGeometry(1, 1), new THREE.ConeGeometry(1, 1, 7)];
  const lcol = [0x6fb24c, 0x93a070, 0x3d7044], count = [0, 0, 0]; T.forEach(t => count[t[2]]++);
  const lm = leaf.map((g, k) => new THREE.InstancedMesh(g, mat(lcol[k]), Math.max(1, count[k])));
  const li = [0, 0, 0];
  T.forEach((t, i) => {
    const [x, z, k] = t, s = rand(0.8, 1.25), th = k === 0 ? 2.4 : k === 1 ? 1.3 : 1;
    d.rotation.set(0, rand(0, 6), 0);
    d.position.set(x, th / 2, z); d.scale.set(1, th, 1); d.updateMatrix(); trunk.setMatrixAt(i, d.matrix);
    if (k === 0) { d.position.set(x, 2.2 + 1.9 * s, z); d.scale.set(2.2 * s, 2.1 * s, 2.2 * s); }
    else if (k === 1) { d.position.set(x, 1.2 + 1.2 * s, z); d.scale.set(2 * s, 1.35 * s, 2 * s); }
    else { d.position.set(x, 0.6 + 3.6 * s, z); d.scale.set(1.1, 7.2 * s, 1.1); }
    d.updateMatrix(); lm[k].setMatrixAt(li[k]++, d.matrix);
    addCircleCollider(x, z, 0.45);
  });
  lm.forEach((m, k) => { m.count = count[k]; scene.add(m); }); scene.add(trunk);
}
// the windmill (Molino del Tío Genaro)
const MILL = poi('Molino'); let millBlades;
{
  const g = new THREE.Group(); g.position.set(MILL.x, 0, MILL.z);
  const body = new THREE.Mesh(new THREE.CylinderGeometry(3.6, 4.4, 9, 16), mat(0xfffaf0)); body.position.y = 4.5;
  const cap = new THREE.Mesh(new THREE.ConeGeometry(4.2, 3.6, 16), mat(0x4b4f58)); cap.position.y = 10.8;
  millBlades = new THREE.Group(); millBlades.position.set(0, 8.6, 4.3);
  for (let i = 0; i < 4; i++) { const b = new THREE.Mesh(new THREE.BoxGeometry(1.5, 8, 0.15), mat(0x8a6a48)); b.position.y = 4.4; const h = new THREE.Group(); h.rotation.z = i * Math.PI / 2; h.add(b); millBlades.add(h); }
  g.add(body, cap, millBlades); scene.add(g); addCircleCollider(MILL.x, MILL.z, 4.6);
}

/* ================= characters ================= */
const GEO = {
  body: new THREE.CylinderGeometry(0.3, 0.44, 0.75, 12), head: new THREE.SphereGeometry(0.5, 18, 14), ball: new THREE.SphereGeometry(1, 10, 8),
  shadow: new THREE.CircleGeometry(1, 16), cone: new THREE.ConeGeometry(1, 1, 10), cyl: new THREE.CylinderGeometry(1, 1, 1, 14), box: new THREE.BoxGeometry(1, 1, 1),
};
const shadowMat = new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.22, depthWrite: false });
function part(geo, color, x, y, z, sx, sy, sz) { const m = new THREE.Mesh(geo, mat(color)); m.position.set(x, y, z); m.scale.set(sx, sy === undefined ? sx : sy, sz === undefined ? sx : sz); return m; }
function makeChar(o) {
  const g = new THREE.Group(), inner = new THREE.Group(); g.add(inner);
  const skin = o.skin || 0xf6c9a0;
  inner.add(part(GEO.body, o.shirt, 0, 0.62, 0, 1));
  inner.add(part(GEO.head, skin, 0, 1.38, 0, 1));
  inner.add(part(GEO.ball, 0x2a1c14, -0.17, 1.42, 0.44, 0.065, 0.085, 0.05), part(GEO.ball, 0x2a1c14, 0.17, 1.42, 0.44, 0.065, 0.085, 0.05));
  inner.add(part(GEO.ball, 0xf59a8c, -0.3, 1.27, 0.37, 0.09, 0.06, 0.04), part(GEO.ball, 0xf59a8c, 0.3, 1.27, 0.37, 0.09, 0.06, 0.04));
  const fl = part(GEO.ball, o.shoes || 0x4a3424, -0.17, 0.13, 0.05, 0.15, 0.13, 0.2), fr = part(GEO.ball, o.shoes || 0x4a3424, 0.17, 0.13, 0.05, 0.15, 0.13, 0.2);
  const hl = part(GEO.ball, skin, -0.46, 0.68, 0, 0.12), hr = part(GEO.ball, skin, 0.46, 0.68, 0, 0.12);
  inner.add(fl, fr, hl, hr);
  const hair = o.hair === undefined ? 0x4a3424 : o.hair;
  if (hair !== null) inner.add(part(GEO.ball, hair, 0, 1.5, -0.06, 0.5, 0.42, 0.5));
  switch (o.hat) {
    case 'beret': inner.add(part(GEO.ball, 0x26262b, 0.04, 1.84, 0, 0.46, 0.13, 0.46), part(GEO.ball, 0x26262b, 0, 1.98, 0, 0.05)); break;
    case 'bun': inner.add(part(GEO.ball, hair, 0, 1.93, -0.12, 0.2)); break;
    case 'tricorn': inner.add(part(GEO.cyl, 0x1b1b1f, 0, 1.86, 0, 0.42, 0.22, 0.42), part(GEO.box, 0x1b1b1f, 0, 1.9, -0.36, 0.9, 0.34, 0.08)); break;
    case 'tophat': inner.add(part(GEO.cyl, 0x1b1b1f, 0, 1.84, 0, 0.56, 0.05, 0.56), part(GEO.cyl, 0x1b1b1f, 0, 2.08, 0, 0.34, 0.5, 0.34)); break;
    case 'cap': inner.add(part(GEO.ball, o.hatColor || 0xd9643a, 0, 1.62, 0, 0.5, 0.3, 0.5), part(GEO.box, o.hatColor || 0xd9643a, 0, 1.64, 0.5, 0.5, 0.05, 0.35)); break;
    case 'straw': inner.add(part(GEO.cyl, 0xe6c56a, 0, 1.8, 0, 0.78, 0.04, 0.78), part(GEO.cyl, 0xe6c56a, 0, 1.9, 0, 0.4, 0.22, 0.4)); break;
    case 'horns': inner.add(part(GEO.cone, 0x8a7a66, -0.25, 1.98, 0, 0.09, 0.4, 0.09), part(GEO.cone, 0x8a7a66, 0.25, 1.98, 0, 0.09, 0.4, 0.09), part(GEO.ball, 0xffffff, 0, 1.12, 0.42, 0.1, 0.2, 0.08)); break;
    case 'collar': inner.add(part(GEO.box, 0xffffff, 0, 0.98, 0.3, 0.16, 0.08, 0.06)); break;
  }
  const sh = new THREE.Mesh(GEO.shadow, shadowMat); sh.rotation.x = -Math.PI / 2; sh.position.y = 0.22; sh.scale.setScalar(0.55); g.add(sh);
  g.scale.setScalar(o.scale || 1); scene.add(g);
  return { g, inner, fl, fr, hl, hr, walk: 0 };
}
function animChar(c, moving, dt, speed) {
  c.walk += dt * (moving ? 9 + speed : 0);
  const s = moving ? Math.sin(c.walk) : 0;
  c.fl.position.z = 0.05 + s * 0.22; c.fr.position.z = 0.05 - s * 0.22;
  c.fl.position.y = 0.13 + Math.max(0, s) * 0.1; c.fr.position.y = 0.13 + Math.max(0, -s) * 0.1;
  c.hl.position.z = -s * 0.2; c.hr.position.z = s * 0.2;
  c.inner.position.y = moving ? Math.abs(Math.cos(c.walk)) * 0.07 : Math.sin(performance.now() / 420 + c.g.id) * 0.015;
}

/* ================= cars ================= */
const CAR_SPECS = {
  panda:   { name: 'El Pandita',  max: 25, acc: 13, brake: 26, turn: 2.2, len: 3.6, wid: 1.8, body: 0.75, cab: 0.7, cabLen: 1.9, cabZ: -0.25, wheel: 0.36 },
  van:     { name: 'La Fragoneta', max: 22, acc: 10, brake: 22, turn: 1.9, len: 4.6, wid: 2.0, body: 1.5, cab: 0.0, cabLen: 0, cabZ: 0, wheel: 0.4 },
  tractor: { name: 'El Tractor de Genaro', max: 12, acc: 9, brake: 20, turn: 2.0, len: 3.4, wid: 1.9, body: 0.9, cab: 1.2, cabLen: 1.2, cabZ: -0.7, wheel: 0.5, offroad: true },
  tunero:  { name: 'El Tunero (do not ask)', max: 33, acc: 19, brake: 30, turn: 2.4, len: 4.0, wid: 1.85, body: 0.6, cab: 0.5, cabLen: 1.8, cabZ: -0.3, wheel: 0.36, spoiler: true },
};
const cars = [];
function makeCar(type, color, x, z, h) {
  const s = CAR_SPECS[type], g = new THREE.Group(), inner = new THREE.Group(); g.add(inner);
  const wy = s.wheel, by = wy + 0.15 + s.body / 2;
  inner.add(part(GEO.box, color, 0, by, 0, s.wid, s.body, s.len));
  if (s.cab) { inner.add(part(GEO.box, 0xcfe8f2, 0, by + s.body / 2 + s.cab / 2, s.cabZ, s.wid * 0.86, s.cab, s.cabLen)); inner.add(part(GEO.box, color, 0, by + s.body / 2 + s.cab + 0.05, s.cabZ, s.wid * 0.9, 0.1, s.cabLen + 0.1)); }
  else inner.add(part(GEO.box, 0xcfe8f2, 0, by + 0.3, s.len / 2 - 0.02, s.wid * 0.8, 0.5, 0.06));
  for (const sx of [-1, 1]) {
    inner.add(part(GEO.ball, 0xfff3a8, sx * s.wid * 0.3, by + 0.05, s.len / 2, 0.2, 0.2, 0.08));   // headlights = eyes
    inner.add(part(GEO.box, 0xd23b2e, sx * s.wid * 0.34, by + 0.05, -s.len / 2, 0.3, 0.16, 0.06));
    for (const sz of [-1, 1]) {
      const big = type === 'tractor' && sz < 0 ? 1.7 : 1;
      const w = part(GEO.cyl, 0x2b2b30, sx * (s.wid / 2), wy * big, sz * s.len * 0.32, wy * big, 0.3, wy * big); w.rotation.z = Math.PI / 2; inner.add(w);
    }
  }
  inner.add(part(GEO.box, 0x444448, 0, wy + 0.1, s.len / 2 + 0.05, s.wid * 0.9, 0.18, 0.12));
  if (s.spoiler) inner.add(part(GEO.box, 0x222226, 0, by + s.body / 2 + 0.45, -s.len / 2 + 0.2, s.wid, 0.06, 0.4), part(GEO.box, 0x222226, 0, by + s.body / 2 + 0.22, -s.len / 2 + 0.2, 0.1, 0.45, 0.1));
  if (type === 'tractor') inner.add(part(GEO.cyl, 0x333333, 0.5, by + 1, 0.9, 0.07, 1.1, 0.07));
  const rack = new THREE.Group(); rack.position.set(0, by + s.body / 2 + s.cab + 0.12, s.cab ? s.cabZ : -0.5); inner.add(rack);   // oil bottles ride on the roof
  const bottles = [];
  for (let i = 0; i < 6; i++) { const b = new THREE.Group(); b.add(part(GEO.cyl, 0xd8c53a, 0, 0.22, 0, 0.11, 0.44, 0.11), part(GEO.cyl, 0x5a7a1e, 0, 0.52, 0, 0.05, 0.18, 0.05)); b.position.set((i % 3 - 1) * 0.36, 0, (i < 3 ? -0.2 : 0.2)); b.visible = false; rack.add(b); bottles.push(b); }
  const sh = new THREE.Mesh(GEO.shadow, shadowMat); sh.rotation.x = -Math.PI / 2; sh.position.y = 0.22; sh.scale.set(s.wid * 0.75, s.len * 0.62, 1); g.add(sh);
  scene.add(g);
  const c = { type, spec: s, g, inner, bottles, x, z, h, vx: 0, vz: 0, r: s.wid * 0.6, off: s.len * 0.27 };
  g.position.set(x, 0, z); g.rotation.y = h; cars.push(c); return c;
}
function parkNear(x, z, shift, type, color) {
  const r = nearestRoad(x, z), flip = Math.random() < 0.5 ? 1 : -1, side = r.s.hw - 1.25;
  return makeCar(type, color, r.x + r.ux * shift - r.uz * side * flip, r.z + r.uz * shift + r.ux * side * flip, Math.atan2(r.ux, r.uz) + (flip > 0 ? 0 : Math.PI));
}

/* ================= key places ================= */
const CHURCH = poi('Divino Salvador'), COOP = poi('Labradores'), KIOSK = poi('Kiosko'), TOWNHALL = poi('Ayuntamiento de'), PLAZA = poi('Plaza del Ayuntamiento'), TANATORIO = poi('Tanatorio'), FERIAL = poi('Recinto Ferial');
const START = nearestRoad(CHURCH.x, CHURCH.z);
const PT_A = nearestRoad(COOP.x, COOP.z), PT_B = nearestRoad(KIOSK.x, KIOSK.z);

/* ================= route finding (one Dijkstra from the target, then follow pointers) ================= */
const nodeGrid = new Map();
for (let i = 0; i < NODE_N; i++) if (mainComp[i]) { const k = gk(Math.floor(N[i * 2] / CELL), Math.floor(N[i * 2 + 1] / CELL)); let a = nodeGrid.get(k); if (!a) nodeGrid.set(k, a = []); a.push(i); }
const route = { dist: new Float64Array(NODE_N), next: new Int32Array(NODE_N), tx: 0, tz: 0, active: false, pts: [] };
function nearestNode(x, z, needReach) {
  let best = -1, bd = 1e9; const cx = Math.floor(x / CELL), cz = Math.floor(z / CELL);
  for (let ring = 1; ring <= 6 && best < 0; ring++)
    for (let ax = -ring; ax <= ring; ax++) for (let az = -ring; az <= ring; az++) {
      const l = nodeGrid.get(gk(cx + ax, cz + az)); if (!l) continue;
      for (const i of l) { if (needReach && route.dist[i] === Infinity) continue; const d = (N[i * 2] - x) ** 2 + (N[i * 2 + 1] - z) ** 2; if (d < bd) { bd = d; best = i; } }
    }
  return best;
}
function setRouteTarget(x, z) {
  route.tx = x; route.tz = z; route.active = true; route.dist.fill(Infinity); route.next.fill(-1);
  const src = nearestNode(x, z, false); if (src < 0) return;
  const heap = [[0, src]]; route.dist[src] = 0;
  const push = e => { let i = heap.push(e) - 1; while (i > 0) { const p = (i - 1) >> 1; if (heap[p][0] <= heap[i][0]) break; [heap[p], heap[i]] = [heap[i], heap[p]]; i = p; } };
  const pop = () => { const top = heap[0], last = heap.pop(); if (heap.length) { heap[0] = last; let i = 0; for (;;) { let l = i * 2 + 1, r = l + 1, m = i; if (l < heap.length && heap[l][0] < heap[m][0]) m = l; if (r < heap.length && heap[r][0] < heap[m][0]) m = r; if (m === i) break; [heap[m], heap[i]] = [heap[i], heap[m]]; i = m; } } return top; };
  while (heap.length) {
    const [d, u] = pop(); if (d > route.dist[u]) continue;
    const a = adj[u];
    for (let i = 0; i < a.length; i += 2) { const v = a[i], nd = d + a[i + 1]; if (nd < route.dist[v]) { route.dist[v] = nd; route.next[v] = u; push([nd, v]); } }
  }
}
function updateRoute(x, z) {
  route.pts.length = 0; if (!route.active) return;
  let n = nearestNode(x, z, true), guard = 0;
  while (n >= 0 && guard++ < 600) { route.pts.push(N[n * 2], N[n * 2 + 1]); n = route.next[n]; }
  route.pts.push(route.tx, route.tz);
}

/* ================= audio ================= */
let AC = null, engOsc, engGain;
function audioInit() {
  if (AC) return;
  try {
    AC = new (window.AudioContext || window.webkitAudioContext)();
    engOsc = AC.createOscillator(); engOsc.type = 'sawtooth'; engGain = AC.createGain(); engGain.gain.value = 0;
    const lp = AC.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 420;
    engOsc.connect(lp).connect(engGain).connect(AC.destination); engOsc.start();
  } catch (e) { AC = null; }
}
function beep(freq, dur = 0.08, type = 'square', vol = 0.05, slide = 0) {
  if (!AC) return;
  const o = AC.createOscillator(), g = AC.createGain(), t = AC.currentTime;
  o.type = type; o.frequency.setValueAtTime(freq, t); if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(30, freq + slide), t + dur);
  g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  o.connect(g).connect(AC.destination); o.start(t); o.stop(t + dur + 0.02);
}
function noise(dur = 0.3, vol = 0.25) {
  if (!AC) return;
  const b = AC.createBuffer(1, AC.sampleRate * dur, AC.sampleRate), d = b.getChannelData(0);
  for (let i = 0; i < d.length; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / d.length) ** 2;
  const s = AC.createBufferSource(), g = AC.createGain(); g.gain.value = vol; s.buffer = b; s.connect(g).connect(AC.destination); s.start();
}
const jingle = (notes, step = 0.11) => notes.forEach((f, i) => setTimeout(() => beep(f, 0.16, 'triangle', 0.09), i * step * 1000));

/* ================= game state ================= */
const G = {
  phase: 'title', paused: false, time: 0, clock: 8 * 60,
  timer: 0, bottles: 0, saffron: 0, bumped: 0, crashes: 0, retries: 0,
  inCar: null, camYaw: Math.PI, shake: 0, dialog: null, target: null, mapOpen: false,
};
window.G = G;   // handy for poking at the prototype from the console
const player = Object.assign(makeChar({ shirt: 0xe8553d, hair: 0x5a3a22, hat: 'cap', hatColor: 0x3b5fa8 }), { x: START.x - START.uz * (START.s.hw + 1), z: START.z + START.ux * (START.s.hw + 1), h: 0 });
collide(player, 0.45);
G.camYaw = Math.atan2(START.ux, START.uz);   // look along the street we wake up on

const pacaCar = parkNear(CHURCH.x, CHURCH.z, 9, 'panda', 0xf3e2b3);
parkNear(COOP.x, COOP.z, -12, 'van', 0xf4f4f0);
parkNear(MILL.x, MILL.z, 6, 'tractor', 0xc8372d);
parkNear(FERIAL.x, FERIAL.z, 4, 'tunero', 0x7d3fc4);
parkNear(PLAZA.x, PLAZA.z, 14, 'panda', 0x5fa8d3);
{ const CC = [0xd9643a, 0x7fb069, 0xe6c229, 0x8d99ae, 0xef8fa9, 0x2a9d8f, 0xffffff, 0x3d405b];
  const res = segs.filter(s => s.r.h === 'residential' && Math.hypot(s.ax, s.az) < 900);
  for (let i = 0; i < 16; i++) { const s = pick(res); parkNear(s.ax, s.az, 2, Math.random() < 0.2 ? 'van' : 'panda', pick(CC)); } }

/* ---------- NPCs ---------- */
const npcs = [];
function addNpc(def, px, pz, shift = 0) {
  const r = nearestRoad(px, pz, s => s.r.h !== 'motorway');
  const side = ((px - r.x) * -r.uz + (pz - r.z) * r.ux) >= 0 ? 1 : -1;
  const n = Object.assign(makeChar(def.look), def, { x: r.x + r.ux * shift - r.uz * (r.s.hw + 1.1) * side, z: r.z + r.uz * shift + r.ux * (r.s.hw + 1.1) * side, h: rand(0, 6), state: 'idle', t: rand(0, 3), vy: 0, y: 0, vx: 0, vz: 0, spin: 0, li: 0 });
  collide(n, 0.45); n.hx = n.x; n.hz = n.z; npcs.push(n); return n;
}
const OUCH = ['¡Ay! My good hip!', 'I felt my ancestors.', 'Right in the pension!', '¡Me cago en…! …sorry, Father.', 'Tell my wife… nothing. She knows.', "That's it, I'm haunting you.", 'Not again, it’s only Tuesday!', 'I’ve had worse at the fiestas.', 'My lawyer is my cousin. Be afraid.', '¡Que te den, guapo!'];
const SHOVE = ['¡Eh! Easy!', 'I’m walking here. Slowly. On purpose.', 'Honk like a person!', 'Personal space, criatura.'];
const GENERIC = [
  ['Lovely morning. Statistically somebody dies today. Not it!'],
  ['My doctor said to cut out salt, wine and my husband.', 'I’m starting with the husband.'],
  ['They say money can’t buy happiness.', 'Then explain saffron. Checkmate.'],
  ['I’m not saying the mayor is corrupt.', 'I’m saying his dog has a pool.'],
  ['You drive like my late uncle.', 'That’s why he’s late.'],
  ['Forty years I’ve lived on this street.', 'I know which of you are natural blondes.'],
  ['The village has two speeds: siesta and funeral.', 'Both have snacks, to be fair.'],
  ['I gave up drinking for Lent once.', 'Worst forty minutes of my life.'],
  ['My grandson is an “influencer”.', 'In my day we called that unemployed with a ring light.'],
  ['If you see my husband, tell him dinner’s at nine.', 'If you see his girlfriend, tell her it’s at eight. I’m curious.'],
];
const P_PACA = addNpc({ name: 'Abuela Paca', pitch: 520, look: { shirt: 0x7b5ea7, hair: 0xd9d9de, hat: 'bun', scale: 0.92 } }, player.x + 2, player.z + 3);
P_PACA.x = player.x + START.ux * 3.5; P_PACA.z = player.z + START.uz * 3.5; collide(P_PACA, 0.45); P_PACA.hx = P_PACA.x; P_PACA.hz = P_PACA.z; P_PACA.still = true;
P_PACA.lines = () => G.phase === 'intro' ? [
  'Ay, niño. You look like a boiled sock. Good, you’re awake.',
  'Your cousin Eusebio’s bar has run out of olive oil. A bar in La Mancha with no oil is just a room where men wait to die.',
  'Drive to the Cooperativa, up the north-east road. Loli has six bottles for you.',
  'Then take them to the kiosk in the Plaza del Ayuntamiento. Once they’re loaded you have TWO minutes before the breakfast crowd riots.',
  'Last time they ate a chair. Take my car — the cream one. The brakes are mostly an opinion.',
] : G.phase === 'toA' ? ['Why are you still here? The Cooperativa. North-east. Follow the yellow line on your little map, genius.'] :
  G.phase === 'toB' ? ['THE PLAZA, criatura! I will write you out of the will. It’s a short will. It’s a ham.'] :
  ['You did fine. Don’t let it go to your head, there’s plenty of room in there.', 'Tomorrow I’ll need a favour involving the cemetery. Wear dark colours.'];
const P_LOLI = addNpc({ name: 'Loli (Cooperativa)', pitch: 440, look: { shirt: 0x7d8f3a, hair: 0x2a1c14, hat: 'cap', hatColor: 0x7d8f3a } }, PT_A.x, PT_A.z, 5);
P_LOLI.still = true;
P_LOLI.lines = () => G.phase === 'toB' ? ['Go, GO. Every second you stand here, a tostada goes dry and an old man loses hope.'] :
  ['Welcome to the Cooperativa. Extra virgin. Unlike most of this town.', 'We press the olives until they confess.'];
const P_EUSEBIO = addNpc({ name: 'Eusebio (the kiosk)', pitch: 300, look: { shirt: 0xffffff, hair: 0x2a1c14, skin: 0xe9b58c } }, PT_B.x, PT_B.z, -5);
P_EUSEBIO.still = true;
P_EUSEBIO.lines = () => G.phase === 'done' || G.phase === 'free' ? ['Peace is restored. Nobody ate furniture. I may cry, but I’m on shift.'] :
  ['No oil, no tostadas, no peace.', 'A man asked for BUTTER this morning. I have called the Guardia Civil.'];
addNpc({ name: 'Don Anselmo', pitch: 250, look: { shirt: 0x222226, hair: 0xcfcfd4, hat: 'collar' }, lines: [
  ['Bless you, my child. Confession is on Thursdays. Bring snacks — yours tend to run long.'],
  ['I have buried half this town.', 'The other half owes me money.'],
  ['God sees everything.', 'Luckily He’s not in the neighbourhood WhatsApp group.'],
] }, CHURCH.x, CHURCH.z, -8);
addNpc({ name: 'Cabo Ramírez', pitch: 210, look: { shirt: 0x3f6b45, hair: 0x2a1c14, hat: 'tricorn' }, lines: [
  ['Seatbelt, citizen. It’s not for your safety.', 'It keeps the body in one place for the paperwork.'],
  ['I pulled over a tractor doing 12 in a 50. The driver was drunk.', 'So was the tractor.'],
  ['If you must run somebody over, pick somebody I dislike.', 'I’ll send you a list. It’s alphabetical.'],
] }, TOWNHALL.x, TOWNHALL.z, 0);
addNpc({ name: 'Maruja', pitch: 600, look: { shirt: 0xef8fa9, hair: 0xb5651d, hat: 'bun' }, lines: [
  ['I don’t gossip, cariño. I archive.'],
  ['Your mother says you’re “finding yourself”.', 'At your age your father had already lost himself twice.'],
  ['See the baker? Third husband. The first two are “in Cuenca”.', 'Nobody goes to Cuenca for that long.'],
] }, PLAZA.x, PLAZA.z, 7);
addNpc({ name: 'Venancio (undertaker)', pitch: 180, look: { shirt: 0x2b2b33, hair: 0x111111, hat: 'tophat', skin: 0xeadfd6 }, lines: [
  ['Driving fast today? Lovely. Here’s my card.', 'It’s also a coupon.'],
  ['Business is slow. Everybody here is too stubborn to die.'],
  ['I measure people with my eyes. You’re a medium.', 'Don’t take it personally. Take it eventually.'],
] }, TANATORIO.x, TANATORIO.z, 0);
addNpc({ name: 'Tío Genaro', pitch: 230, look: { shirt: 0x8a6a48, hair: 0xe0e0e0, hat: 'beret', skin: 0xe2ab80 }, lines: [
  ['Yes, it’s a windmill. No, you can’t fight it.', 'A gentleman from out of town tried once. We still find bits of lance.'],
  ['The wind is free.', 'That’s only because the government hasn’t found where it lives.'],
  ['Take the tractor if you like. She’s slow, but she’s never been wrong.'],
] }, MILL.x, MILL.z + 9, 3);
addNpc({ name: 'Kevin-José (age 8)', pitch: 780, look: { shirt: 0xf2b632, hair: 0x2a1c14, scale: 0.68 }, lines: [
  ['I’m not lost. I’m unsupervised. It’s different and it’s legal.'],
  ['My abuelo says the saffron is worth more than me.', 'He checked. Twice.'],
  ['When I grow up I want to be a notary.', 'They’re the only ones who win at funerals.'],
] }, FERIAL.x, FERIAL.z, 0);
addNpc({ name: 'A Goat', pitch: 150, look: { shirt: 0xf4f1e8, skin: 0xf4f1e8, hair: null, hat: 'horns', shoes: 0x3a3a3a, scale: 0.8 }, lines: [
  ['Beeeh.'], ['Beeeeeh.'], ['…the things I have seen in those fields at night, hombre.', 'Beeeh.'],
] }, MILL.x + 30, MILL.z + 20, -6);
{ // anonymous neighbours
  const SH = [0xd9643a, 0x3b5fa8, 0x7fb069, 0xe6c229, 0xef8fa9, 0x2a9d8f, 0x9d4edd, 0xf4f1e8], HA = [0x2a1c14, 0x5a3a22, 0xd9d9de, 0xb5651d, 0x111111], HATS = [undefined, undefined, 'beret', 'bun', 'cap', 'straw'];
  const NAMES = ['A Neighbour', 'Somebody’s Cousin', 'Retired Gentleman', 'Lady with Opinions', 'Man Avoiding His Wife', 'Local Expert on Everything'];
  const res = segs.filter(s => (s.r.h === 'residential' || s.r.h === 'tertiary') && Math.hypot(s.ax + 50, s.az) < 850);
  for (let i = 0; i < 46; i++) { const s = pick(res); addNpc({ name: pick(NAMES), pitch: rand(200, 650), look: { shirt: pick(SH), hair: pick(HA), hat: pick(HATS), hatColor: pick(SH), skin: pick([0xf6c9a0, 0xe9b58c, 0xd49a6a, 0xfbd7b5]) }, lines: GENERIC }, s.ax, s.az, rand(-4, 4)); }
}

/* ---------- saffron flowers (the collectible) ---------- */
const flowers = [];
{ const res = segs.filter(s => s.r.k !== 0 || s.r.h === 'residential');
  for (let i = 0; i < 40; i++) {
    const s = pick(res), side = Math.random() < 0.5 ? 1 : -1, L = Math.hypot(s.bx - s.ax, s.bz - s.az) || 1;
    const p = { x: s.ax - (s.bz - s.az) / L * (s.hw + 1) * side, z: s.az + (s.bx - s.ax) / L * (s.hw + 1) * side }; collide(p, 0.4);
    const g = new THREE.Group(); g.add(part(GEO.cyl, 0x5f9c4a, 0, 0.3, 0, 0.03, 0.6, 0.03));
    for (let k = 0; k < 5; k++) { const pt = part(GEO.ball, 0x9b5de5, Math.cos(k * 1.257) * 0.12, 0.66, Math.sin(k * 1.257) * 0.12, 0.11, 0.2, 0.11); g.add(pt); }
    g.add(part(GEO.ball, 0xe63946, 0, 0.74, 0, 0.05, 0.13, 0.05)); g.position.set(p.x, 0.15, p.z); scene.add(g); flowers.push({ g, x: p.x, z: p.z });
  } }

/* ---------- mission markers ---------- */
function makeBeacon(x, z, color) {
  const g = new THREE.Group(); g.position.set(x, 0, z);
  const m = new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.32, depthWrite: false, side: THREE.DoubleSide });
  const col = new THREE.Mesh(new THREE.CylinderGeometry(4.5, 4.5, 70, 20, 1, true), m); col.position.y = 35;
  const ring = new THREE.Mesh(new THREE.RingGeometry(4.4, 5.6, 28), new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.85, side: THREE.DoubleSide, depthWrite: false })); ring.rotation.x = -Math.PI / 2; ring.position.y = 0.3;
  g.add(col, ring); g.visible = false; scene.add(g); return g;
}
const beacon = makeBeacon(0, 0, 0xffc21a);
const arrow = new THREE.Mesh(new THREE.ConeGeometry(0.55, 1.5, 4).rotateX(Math.PI / 2), new THREE.MeshBasicMaterial({ color: 0xffc21a })); arrow.scale.set(0.7, 0.25, 0.7); arrow.visible = false; scene.add(arrow);
function setTarget(t) {
  G.target = t; beacon.visible = !!t && !t.npc;
  if (t) { beacon.position.set(t.x, 0, t.z); setRouteTarget(t.x, t.z); } else { route.active = false; route.pts.length = 0; }
}

/* ================= HUD helpers ================= */
const hud = { obj: $('objText'), prompt: $('prompt'), toast: $('toast'), street: $('street') };
let toastT = 0;
function toast(msg, dur = 3) { hud.toast.textContent = msg; hud.toast.classList.remove('hidden'); toastT = dur; }
function objective(msg) { hud.obj.textContent = msg; }
function drawBottles() { const el = $('bottles'); el.innerHTML = ''; for (let i = 0; i < 6; i++) { const b = document.createElement('i'); if (i >= G.bottles) b.className = 'broken'; el.appendChild(b); } cars.forEach(c => c.bottles.forEach((b, i) => b.visible = c === G.inCar && G.phase === 'toB' && i < G.bottles)); }
const bubbles = [];
function bark(ent, text, dur = 2.6) {
  let b = bubbles.find(b => b.ent === ent);
  if (!b) { b = { ent, el: document.createElement('div') }; b.el.className = 'bubble'; $('bubbles').appendChild(b.el); bubbles.push(b); }
  b.el.textContent = text; b.t = dur;
}
const v3 = new THREE.Vector3();
function updateBubbles(dt) {
  for (let i = bubbles.length - 1; i >= 0; i--) {
    const b = bubbles[i]; b.t -= dt;
    if (b.t <= 0) { b.el.remove(); bubbles.splice(i, 1); continue; }
    v3.set(b.ent.x, (b.ent.y || 0) + 2.3 * b.ent.g.scale.y, b.ent.z).project(camera);
    const vis = v3.z < 1 && Math.abs(v3.x) < 1.1 && Math.abs(v3.y) < 1.1;
    b.el.style.display = vis ? '' : 'none';
    if (vis) { b.el.style.left = ((v3.x + 1) / 2 * innerWidth) + 'px'; b.el.style.top = ((1 - v3.y) / 2 * innerHeight) + 'px'; }
  }
}

/* ---------- dialog ---------- */
function say(name, lines, pitch, onDone) {
  G.dialog = { name, lines, i: 0, shown: 0, pitch: pitch || 400, onDone, cool: 0.25 };
  $('dName').textContent = name; $('dText').textContent = ''; $('dialog').classList.remove('hidden'); hud.prompt.classList.add('hidden');
}
function dialogAdvance() {
  const d = G.dialog; if (!d || d.cool > 0) return;
  const line = d.lines[d.i];
  if (d.shown < line.length) { d.shown = line.length; $('dText').textContent = line; return; }
  d.i++; d.shown = 0; d.cool = 0.12;
  if (d.i >= d.lines.length) { G.dialog = null; $('dialog').classList.add('hidden'); if (d.onDone) d.onDone(); } else $('dText').textContent = '';
}
function updateDialog(dt) {
  const d = G.dialog; if (!d) return; d.cool -= dt;
  const line = d.lines[d.i]; if (d.shown >= line.length) return;
  const before = Math.floor(d.shown); d.shown = Math.min(line.length, d.shown + dt * 42);
  if (Math.floor(d.shown) !== before) { $('dText').textContent = line.slice(0, Math.floor(d.shown)); const ch = line[Math.floor(d.shown) - 1]; if (ch && /[a-záéíóúñ]/i.test(ch) && Math.floor(d.shown) % 2 === 0) beep(d.pitch * (0.85 + (ch.charCodeAt(0) % 7) * 0.05), 0.05, 'square', 0.03); }
}

/* ---------- mission flow ---------- */
function startDay() {
  audioInit(); $('title').classList.add('hidden'); $('hud').classList.remove('hidden');
  G.phase = 'intro'; objective('Talk to Abuela Paca (she’s right there, glaring).'); setTarget({ x: P_PACA.x, z: P_PACA.z, npc: true });
  toast('Day 0 · Madridejos, Toledo', 4); bark(P_PACA, '¡Niño! Come here!', 6); jingle([523, 659, 784]);
}
function talkTo(n) {
  const face = Math.atan2(player.x - n.x, player.z - n.z); n.h = face; player.h = face + Math.PI;
  if (n === P_PACA && G.phase === 'intro') return say(n.name, n.lines(), n.pitch, () => { G.phase = 'toA'; objective('Drive to the Cooperativa and collect the oil.'); setTarget({ x: PT_A.x, z: PT_A.z }); toast('Take the cream car — E to get in'); });
  const set = typeof n.lines === 'function' ? n.lines() : n.lines[n.li++ % n.lines.length];
  say(n.name, set, n.pitch);
}
function arriveA() {
  G.phase = 'loading'; if (G.inCar) { G.inCar.vx = G.inCar.vz = 0; }
  say(P_LOLI.name, ['You’re Paca’s grandchild? She said you’d look disappointing. Spot on.', 'Six bottles of the good stuff, on the roof. Yes, the roof. It’s tradition and also we lost the boxes.', 'Every crash breaks a bottle. Two minutes to the Plaza del Ayuntamiento. ¡Venga, venga!'], P_LOLI.pitch, beginRun);
}
function beginRun() {
  G.phase = 'toB'; G.timer = 120; G.bottles = 6; G.runCrashes = 0; drawBottles();
  $('timer').classList.remove('hidden'); objective('Get the oil to the kiosk in Plaza del Ayuntamiento!'); setTarget({ x: PT_B.x, z: PT_B.z }); jingle([392, 523, 659, 784]);
  if (!G.inCar) toast('On foot? Brave. Stupid, but brave.');
}
function failRun(why) {
  G.phase = 'failed'; G.retries++; noise(0.5, 0.2); beep(220, 0.5, 'sawtooth', 0.08, -150);
  $('failTitle').textContent = why === 'time' ? 'The breakfast crowd rioted' : 'That was the last bottle';
  $('failText').textContent = why === 'time' ? 'They have eaten two chairs and are eyeing Eusebio. Abuela has been informed. She is “not angry, just loud”.' : 'The street smells delicious. A pensioner has slipped on it and is suing the concept of gravity.';
  $('fail').classList.remove('hidden');
}
function retryRun() {
  $('fail').classList.add('hidden');
  const c = G.inCar || pacaCar; if (!G.inCar) enterCar(c);
  c.x = PT_A.x; c.z = PT_A.z; c.h = Math.atan2(PT_A.ux, PT_A.uz); c.vx = c.vz = 0; G.camYaw = c.h; beginRun();
}
function arriveB() {
  G.phase = 'done'; drawBottles(); $('timer').classList.add('hidden'); setTarget(null); jingle([523, 659, 784, 1047, 784, 1047], 0.13);
  if (G.inCar) { G.inCar.vx *= 0.2; G.inCar.vz *= 0.2; }
  const used = 120 - G.timer, n = G.bottles;
  say(P_EUSEBIO.name, [n === 6 ? 'Six out of six?! I’d hug you, but I’ve seen how you drive.' : n >= 3 ? `${n} bottles. The rest are “with God”, I assume. Fine. FINE.` : `${n} bottle${n > 1 ? 's' : ''}. One tostada per customer and we pray.`,
    'You saved breakfast. In this town that makes you basically a saint. A cheap one, but still.'], P_EUSEBIO.pitch, () => showEnd(used));
}
function showEnd(used) {
  const n = G.bottles, score = n * 2 - G.bumped * 0.5 + (used < 75 ? 3 : used < 100 ? 1 : 0);
  $('rank').textContent = score >= 13 ? 'Rank: Hijo Predilecto de Madridejos' : score >= 8 ? 'Rank: Acceptable Disappointment' : 'Rank: Family Shame (But With Oil)';
  const rows = [['Delivery time', `${Math.floor(used / 60)}:${String(Math.floor(used % 60)).padStart(2, '0')}`], ['Bottles that survived', `${n} / 6`], ['Neighbours bumped', G.bumped], ['Saffron picked', `${G.saffron} (≈ ${G.saffron * 6} €)`], ['Retries', G.retries]];
  $('stats').innerHTML = rows.map(r => `<tr><td>${r[0]}</td><td>${r[1]}</td></tr>`).join('');
  $('endNote').textContent = G.bumped === 0 ? 'Nobody was harmed. Venancio the undertaker is “a bit disappointed, honestly”.' : G.bumped < 4 ? 'A few neighbours are bruised. They’ll bring it up at every wedding until you die.' : 'The health centre has named a waiting room after you.';
  $('end').classList.remove('hidden');
}
function freeRoam() { $('end').classList.add('hidden'); G.phase = 'free'; objective('Day’s over. Roam, gossip, pick saffron, test the brakes.'); }

/* ---------- cars: enter / exit / physics ---------- */
function enterCar(c) { G.inCar = c; player.g.visible = false; $('speedo').classList.remove('hidden'); $('carName').textContent = c.spec.name; beep(180, 0.08, 'square', 0.05); drawBottles(); }
function exitCar() {
  const c = G.inCar; if (Math.hypot(c.vx, c.vz) > 3) return toast('Maybe stop the car first, Rambo.', 1.6);
  for (const side of [1, -1]) {
    const p = { x: c.x + Math.cos(c.h) * 1.9 * side, z: c.z - Math.sin(c.h) * 1.9 * side };
    if (!collide(p, 0.45) || side === -1) { player.x = p.x; player.z = p.z; break; }
  }
  player.h = c.h; player.g.visible = true; G.inCar = null; c.vx = c.vz = 0; $('speedo').classList.add('hidden'); drawBottles(); beep(140, 0.08, 'square', 0.05);
}
function crash(c, impact) {
  G.shake = Math.min(1, impact / 14); noise(0.25 + impact / 60, Math.min(0.35, 0.08 + impact / 50));
  if (c === G.inCar && G.phase === 'toB' && impact > 7) {
    const lost = Math.min(G.bottles, impact > 15 ? 2 : 1); G.bottles -= lost; G.crashes++; drawBottles(); beep(1400, 0.2, 'triangle', 0.08, -900);
    if (G.bottles > 0) toast(pick([`A bottle has died. ${G.bottles} left.`, `Crunch. ${G.bottles} left. The road is now a salad.`, `${G.bottles} left. Abuela felt that one.`])); else failRun('oil');
  }
}
const cp = { x: 0, z: 0 };
function updateCar(c, dt, thr, steer, hand) {
  const fx = Math.sin(c.h), fz = Math.cos(c.h), rx = -fz, rz = fx;
  let vf = c.vx * fx + c.vz * fz, vl = c.vx * rx + c.vz * rz;
  const onRoad = c.spec.offroad || roadEdgeDist(c.x, c.z) < 1.6;
  const maxV = c.spec.max * (onRoad ? 1 : 0.55);
  if (thr > 0) { if (vf < maxV) vf += c.spec.acc * dt * (vf < 0 ? 2 : 1); }
  else if (thr < 0) { if (vf > 0.5) vf -= c.spec.brake * dt; else if (vf > -maxV * 0.4) vf -= c.spec.acc * 0.7 * dt; }
  vf -= vf * ((onRoad ? 0.22 : 1.0) + (thr === 0 ? 0.55 : 0)) * dt;
  if (Math.abs(vf) > maxV) vf -= (vf - Math.sign(vf) * maxV) * 2.5 * dt;
  if (hand) vf -= Math.sign(vf) * Math.min(Math.abs(vf), 10 * dt);
  vl *= Math.exp(-(hand ? 1.6 : onRoad ? 7.5 : 4.5) * dt);
  const spd = Math.abs(vf);
  c.h += steer * c.spec.turn * Math.min(1, spd / 5) * (1 - Math.min(0.5, spd / 70)) * (vf >= 0 ? 1 : -1) * (hand ? 1.35 : 1) * dt;
  c.vx = fx * vf + rx * vl; c.vz = fz * vf + rz * vl;
  c.x += c.vx * dt; c.z += c.vz * dt;
  for (const o of [c.off, -c.off]) {          // two circles: nose and tail
    cp.x = c.x + Math.sin(c.h) * o; cp.z = c.z + Math.cos(c.h) * o; const ox = cp.x, oz = cp.z;
    if (collide(cp, c.r)) bounce(c, cp.x - ox, cp.z - oz, hitN.x, hitN.z);
    for (const d of cars) { if (d === c) continue; const dx = cp.x - d.x, dz = cp.z - d.z, rr = c.r + d.r + 0.5, d2 = dx * dx + dz * dz;
      if (d2 < rr * rr) { const dd = Math.sqrt(d2) || 0.01, nx = dx / dd, nz = dz / dd; const imp = -(c.vx * nx + c.vz * nz); d.vx += -nx * Math.max(0, imp) * 0.5; d.vz += -nz * Math.max(0, imp) * 0.5; bounce(c, nx * (rr - dd), nz * (rr - dd), nx, nz); } }
    for (const n of npcs) { if (n.state === 'fly' || n.state === 'down') continue; const dx = n.x - cp.x, dz = n.z - cp.z; if (dx * dx + dz * dz > (c.r + 0.5) ** 2) continue;
      const v = Math.hypot(c.vx, c.vz);
      if (v > 4.5) { n.state = 'fly'; n.vx = c.vx * 0.9 + dx; n.vz = c.vz * 0.9 + dz; n.vy = 5 + v * 0.35; n.spin = rand(6, 14) * (Math.random() < 0.5 ? -1 : 1); if (c === G.inCar) { G.bumped++; $('bumped').textContent = G.bumped; G.shake = 0.35; } noise(0.15, 0.15); beep(500, 0.25, 'sine', 0.07, 500); bark(n, pick(OUCH), 3.5); c.vx *= 0.93; c.vz *= 0.93; }
      else { const d = Math.hypot(dx, dz) || 0.01; n.x = cp.x + dx / d * (c.r + 0.55); n.z = cp.z + dz / d * (c.r + 0.55); if (v > 1 && !bubbles.find(b => b.ent === n)) bark(n, pick(SHOVE), 1.8); } }
  }
  c.g.position.set(c.x, 0, c.z); c.g.rotation.y = c.h;
  c.inner.rotation.z = angLerp(c.inner.rotation.z, clamp(vl * 0.03, -0.12, 0.12), 0.2); c.inner.rotation.x = clamp(-(vf - (c.pvf || 0)) / Math.max(dt, 0.001) * 0.0025, -0.06, 0.06); c.pvf = vf;
}
function bounce(c, px, pz, nx, nz) {
  c.x += px; c.z += pz; const imp = -(c.vx * nx + c.vz * nz);
  if (imp > 0) { c.vx += nx * imp * 1.25; c.vz += nz * imp * 1.25; if (imp > 3.5 && (c.crashCool || 0) <= 0) { crash(c, imp); c.crashCool = 0.35; } }
}

/* ================= input ================= */
const keys = {};
addEventListener('keydown', e => {
  if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space', 'Tab'].includes(e.code)) e.preventDefault();
  if (e.repeat) return; keys[e.code] = true; audioInit();
  if (G.phase === 'title') { if (e.code === 'Enter' || e.code === 'Space') startDay(); return; }
  if (G.phase === 'failed') { if (e.code === 'Enter') retryRun(); return; }
  if (e.code === 'KeyP' || e.code === 'Escape') { if (G.mapOpen) return toggleMap(false); G.paused = !G.paused; $('pause').classList.toggle('hidden', !G.paused); return; }
  if (G.paused) return;
  if (e.code === 'KeyM' || e.code === 'Tab') return toggleMap(!G.mapOpen);
  if (G.dialog) { if (e.code === 'KeyE' || e.code === 'Enter' || e.code === 'Space') dialogAdvance(); return; }
  if (e.code === 'KeyE' && !$('end').classList.contains('hidden') === false) interact();
});
addEventListener('keyup', e => { keys[e.code] = false; });
addEventListener('blur', () => { for (const k in keys) keys[k] = false; });
$('startBtn').onclick = () => { audioInit(); startDay(); };
$('resumeBtn').onclick = () => { G.paused = false; $('pause').classList.add('hidden'); };
$('retryBtn').onclick = retryRun; $('roamBtn').onclick = freeRoam; $('replayBtn').onclick = () => location.reload();
$('dialog').onclick = dialogAdvance;
let drag = null;
$('view').addEventListener('pointerdown', e => { drag = e.clientX; });
addEventListener('pointerup', () => { drag = null; });
addEventListener('pointermove', e => { if (drag !== null && !G.inCar) { G.camYaw -= (e.clientX - drag) * 0.006; drag = e.clientX; } });

let near = null;   // what E would do right now
function findInteraction() {
  near = null; if (G.inCar) return;
  let bd = 3.2 ** 2;
  for (const n of npcs) { if (n.state === 'fly' || n.state === 'down') continue; const d = (n.x - player.x) ** 2 + (n.z - player.z) ** 2; if (d < bd) { bd = d; near = { npc: n }; } }
  if (G.phase === 'intro' && (P_PACA.x - player.x) ** 2 + (P_PACA.z - player.z) ** 2 < 4.5 ** 2) near = { npc: P_PACA };   // the quest giver wins ties
  if (!near) { bd = 4 ** 2; for (const c of cars) { const d = (c.x - player.x) ** 2 + (c.z - player.z) ** 2; if (d < bd) { bd = d; near = { car: c }; } } }
}
function interact() {
  if (G.inCar) return exitCar();
  if (near && near.npc) talkTo(near.npc); else if (near && near.car) enterCar(near.car);
}

/* ================= minimap / big map ================= */
const MS = 0.5, mapCv = document.createElement('canvas'); mapCv.width = Math.ceil((XMAX - XMIN) * MS); mapCv.height = Math.ceil((ZMAX - ZMIN) * MS);
{ const c = mapCv.getContext('2d'); c.fillStyle = '#e9d9a6'; c.fillRect(0, 0, mapCv.width, mapCv.height);
  const AC2 = ['#a9d383', '#86c79e', '#c3cb7c', '#d9cb92', '#eedfae', '#7fcbe6'];
  for (const a of M.areas) { c.fillStyle = AC2[a.k]; c.beginPath(); for (let i = 0; i < a.p.length; i += 2) c.lineTo((a.p[i] - XMIN) * MS, (a.p[i + 1] - ZMIN) * MS); c.fill(); }
  c.lineCap = c.lineJoin = 'round';
  for (const pass of [1, 2, 0]) for (const r of M.roads) { if (r.k !== pass) continue;
    c.strokeStyle = pass === 0 ? '#fffdf6' : pass === 1 ? '#cdb07a' : '#f3ead2'; c.lineWidth = Math.max(pass === 0 ? 2.2 : 1, r.w * MS * 0.8);
    c.beginPath(); for (const i of r.p) c.lineTo((N[i * 2] - XMIN) * MS, (N[i * 2 + 1] - ZMIN) * MS); c.stroke(); }
  c.fillStyle = '#c9a27a'; for (const b of M.boxes) if (b[6]) c.fillRect((b[0] - XMIN) * MS - b[2] * MS / 2, (b[1] - ZMIN) * MS - b[3] * MS / 2, b[2] * MS, b[3] * MS);
}
const mm = $('minimap').getContext('2d');
function drawMapMarkers(c, tx, px, pz, ph) {   // tx: world -> canvas
  if (route.pts.length > 2) { c.strokeStyle = '#f2a900'; c.lineWidth = 4; c.lineJoin = 'round'; c.beginPath(); let p = tx(px, pz); c.moveTo(p[0], p[1]); for (let i = 0; i < route.pts.length; i += 2) { p = tx(route.pts[i], route.pts[i + 1]); c.lineTo(p[0], p[1]); } c.stroke(); }
  c.fillStyle = '#7b5ea7'; for (const car of cars) { const p = tx(car.x, car.z); c.fillRect(p[0] - 2, p[1] - 2, 4, 4); }
  if (G.target) { const p = tx(G.target.x, G.target.z); c.fillStyle = '#f2a900'; c.strokeStyle = '#4a3424'; c.lineWidth = 2; c.beginPath(); c.arc(p[0], p[1], 7 + Math.sin(G.time * 5) * 1.5, 0, 7); c.fill(); c.stroke(); }
  const p = tx(px, pz); c.save(); c.translate(p[0], p[1]); c.rotate(Math.PI - ph); c.fillStyle = '#e8553d'; c.strokeStyle = '#fff'; c.lineWidth = 2; c.beginPath(); c.moveTo(0, -9); c.lineTo(6.5, 7); c.lineTo(0, 3.5); c.lineTo(-6.5, 7); c.closePath(); c.fill(); c.stroke(); c.restore();
}
function drawMinimap(px, pz, ph) {
  const R = 150, W = 200, k = W / (2 * R);
  mm.fillStyle = '#e3cf95'; mm.fillRect(0, 0, W, W);
  mm.drawImage(mapCv, (px - R - XMIN) * MS, (pz - R - ZMIN) * MS, 2 * R * MS, 2 * R * MS, 0, 0, W, W);
  drawMapMarkers(mm, (x, z) => { let dx = (x - px) * k, dz = (z - pz) * k; const d = Math.hypot(dx, dz); if (d > 92) { dx *= 92 / d; dz *= 92 / d; } return [100 + dx, 100 + dz]; }, px, pz, ph);
  mm.fillStyle = '#4a3424'; mm.font = '800 14px sans-serif'; mm.textAlign = 'center'; mm.fillText('N', 100, 16);
}
const big = $('bigmap');
function toggleMap(on) { G.mapOpen = on; big.classList.toggle('hidden', !on); }
function drawBigMap(px, pz, ph) {
  const s = Math.min((innerWidth * 0.92) / mapCv.width, (innerHeight * 0.86) / mapCv.height); const w = Math.floor(mapCv.width * s), h = Math.floor(mapCv.height * s);
  if (big.width !== w) { big.width = w; big.height = h; }
  const c = big.getContext('2d'); c.drawImage(mapCv, 0, 0, w, h);
  drawMapMarkers(c, (x, z) => [(x - XMIN) * MS * s, (z - ZMIN) * MS * s], px, pz, ph);
  c.fillStyle = '#4a3424'; c.font = '700 12px sans-serif'; c.textAlign = 'center';
  for (const p of [[CHURCH, 'Iglesia'], [PLAZA, 'Plaza del Ayuntamiento'], [COOP, 'Cooperativa'], [MILL, 'Molino del Tío Genaro'], [FERIAL, 'Recinto Ferial']]) c.fillText(p[1], (p[0].x - XMIN) * MS * s, (p[0].z - ZMIN) * MS * s - 8);
}

/* ================= main loop ================= */
const camPos = new THREE.Vector3(START.x, 60, START.z + 80), camLook = new THREE.Vector3(START.x, 0, START.z);
let last = performance.now(), routeT = 0, streetT = 0;
function frame(now) {
  const dt = clamp((now - last) / 1000, 0, 0.05); last = now;
  if (G.paused) return;
  G.time += dt; millBlades.rotation.z += dt * 0.6;

  if (G.phase === 'title') {
    const a = G.time * 0.12; camera.position.set(CHURCH.x + Math.sin(a) * 120, 55, CHURCH.z + Math.cos(a) * 120); camera.lookAt(CHURCH.x, 6, CHURCH.z);
    renderer.render(scene, camera); return;
  }
  const frozen = !!G.dialog || G.phase === 'failed' || !$('end').classList.contains('hidden');
  const ix = frozen ? 0 : (keys.KeyD ? 1 : 0) - (keys.KeyA ? 1 : 0), iy = frozen ? 0 : (keys.KeyW || keys.ArrowUp ? 1 : 0) - (keys.KeyS || keys.ArrowDown ? 1 : 0);
  const cl = frozen ? 0 : (keys.ArrowLeft ? 1 : 0) - (keys.ArrowRight ? 1 : 0);


  // --- player / car ---
  let px, pz, ph, speed = 0;
  if (G.inCar) {
    const c = G.inCar; c.crashCool = (c.crashCool || 0) - dt;
    updateCar(c, dt, iy, -ix + cl, !frozen && keys.Space);
    px = player.x = c.x; pz = player.z = c.z; ph = c.h; speed = Math.hypot(c.vx, c.vz);
    const rev = (c.vx * Math.sin(c.h) + c.vz * Math.cos(c.h)) < -1.5;
    G.camYaw = angLerp(G.camYaw, c.h + (rev ? Math.PI : 0), 1 - Math.exp(-(rev ? 2 : 4) * dt));
    $('kmh').textContent = Math.round(speed * 3.6);
  } else {
    G.camYaw += cl * 2.2 * dt;
    const fx = Math.sin(G.camYaw), fz = Math.cos(G.camYaw), mx = fx * iy - fz * ix, mz = fz * iy + fx * ix, ml = Math.hypot(mx, mz);
    if (ml > 0) {
      speed = keys.ShiftLeft || keys.ShiftRight ? 9 : 5.2;
      player.x += mx / ml * speed * dt; player.z += mz / ml * speed * dt; player.h = angLerp(player.h, Math.atan2(mx, mz), 1 - Math.exp(-14 * dt));
    }
    collide(player, 0.45);
    for (const c of cars) for (const o of [c.off, -c.off]) { const qx = c.x + Math.sin(c.h) * o, qz = c.z + Math.cos(c.h) * o, dx = player.x - qx, dz = player.z - qz, rr = c.r + 0.4, d = Math.hypot(dx, dz); if (d < rr && d > 0) { player.x = qx + dx / d * rr; player.z = qz + dz / d * rr; } }
    for (const n of npcs) { const dx = player.x - n.x, dz = player.z - n.z, d = Math.hypot(dx, dz); if (d < 0.85 && d > 0 && n.state !== 'fly') { player.x = n.x + dx / d * 0.85; player.z = n.z + dz / d * 0.85; } }
    px = player.x; pz = player.z; ph = player.h;
    player.g.position.set(px, 0, pz); player.g.rotation.y = ph; animChar(player, ml > 0, dt, speed);
    for (let i = flowers.length - 1; i >= 0; i--) { const f = flowers[i]; if ((f.x - px) ** 2 + (f.z - pz) ** 2 < 1.6) { scene.remove(f.g); flowers.splice(i, 1); G.saffron++; $('saffron').textContent = G.saffron; jingle([880, 1175], 0.07); toast(pick(['Saffron! Worth more than you, by weight.', 'Saffron. Don’t tell the neighbours.', 'Saffron acquired. Technically somebody’s. Finders keepers.']), 2); } }
  }
  // parked cars that got shoved keep sliding a bit
  for (const c of cars) { if (c === G.inCar) continue; if (Math.abs(c.vx) + Math.abs(c.vz) > 0.05) updateCar(c, dt, 0, 0, true); }

  // --- NPCs ---
  for (const n of npcs) {
    if ((n.x - px) ** 2 + (n.z - pz) ** 2 > 220 ** 2 && n.state !== 'fly') { n.g.visible = false; continue; }
    n.g.visible = true;
    if (n.state === 'fly') {
      n.vy -= 22 * dt; n.y += n.vy * dt; n.x += n.vx * dt; n.z += n.vz * dt; n.inner.rotation.x += n.spin * dt;
      if (collide(n, 0.45)) { n.vx *= -0.3; n.vz *= -0.3; }
      if (n.y <= 0 && n.vy < 0) { n.y = 0; if (n.vy < -6) { n.vy *= -0.35; n.vx *= 0.5; n.vz *= 0.5; noise(0.08, 0.08); } else { n.state = 'down'; n.t = 2.6; n.inner.rotation.x = -Math.PI / 2; n.inner.position.y = 0.35; } }
    } else if (n.state === 'down') {
      n.t -= dt; if (n.t <= 0) { n.state = 'idle'; n.t = 1; n.inner.rotation.x = 0; n.hx = n.x; n.hz = n.z; }
    } else {
      const dP = Math.hypot(px - n.x, pz - n.z), watching = dP < 4.5 && !G.inCar;
      if (watching || n.still) { if (dP < 9) n.h = angLerp(n.h, Math.atan2(px - n.x, pz - n.z), 1 - Math.exp(-6 * dt)); animChar(n, false, dt, 0); }
      else if (n.state === 'walk') {
        const dx = n.tx - n.x, dz = n.tz - n.z, d = Math.hypot(dx, dz); n.t -= dt;
        if (d < 0.3 || n.t <= 0) { n.state = 'idle'; n.t = rand(1.5, 5); }
        else { n.x += dx / d * 1.3 * dt; n.z += dz / d * 1.3 * dt; n.h = angLerp(n.h, Math.atan2(dx, dz), 1 - Math.exp(-8 * dt)); collide(n, 0.45); }
        animChar(n, true, dt, 0);
      } else { n.t -= dt; animChar(n, false, dt, 0); if (n.t <= 0) { n.state = 'walk'; n.t = 6; const a = rand(0, 6.28), r = rand(2, 9); n.tx = n.hx + Math.cos(a) * r; n.tz = n.hz + Math.sin(a) * r; } }
    }
    n.g.position.set(n.x, n.y, n.z); n.g.rotation.y = n.h;
  }
  P_PACA.x = P_PACA.hx; P_PACA.z = P_PACA.hz;   // mission-critical people don't wander off

  // --- mission checks ---
  if (G.phase === 'intro') { G.target.x = P_PACA.x; G.target.z = P_PACA.z; }
  if (G.phase === 'toA' && (px - PT_A.x) ** 2 + (pz - PT_A.z) ** 2 < 7.5 ** 2) arriveA();
  if (G.phase === 'toB') {
    G.timer -= dt; const t = Math.max(0, G.timer);
    $('timerVal').textContent = Math.floor(t / 60) + ':' + String(Math.floor(t % 60)).padStart(2, '0'); $('timer').classList.toggle('low', t < 20);
    if (t < 10 && Math.floor(t) !== Math.floor(t + dt)) beep(880, 0.07, 'square', 0.05);
    if ((px - PT_B.x) ** 2 + (pz - PT_B.z) ** 2 < 8 ** 2) arriveB(); else if (G.timer <= 0) failRun('time');
  }

  // --- route + guide arrow ---
  routeT -= dt; if (routeT <= 0) { routeT = 0.5; updateRoute(px, pz); }
  arrow.visible = !!G.target;
  if (G.target) {
    let ax = G.target.x, az = G.target.z;
    if (Math.hypot(ax - px, az - pz) > 45 && route.pts.length > 2) { let acc = 0, lx = px, lz = pz; for (let i = 0; i < route.pts.length; i += 2) { acc += Math.hypot(route.pts[i] - lx, route.pts[i + 1] - lz); lx = route.pts[i]; lz = route.pts[i + 1]; if (acc > 28) break; } ax = lx; az = lz; }
    arrow.position.set(px, (G.inCar ? 3.6 : 2.9) + Math.sin(G.time * 4) * 0.15, pz); arrow.rotation.y = angLerp(arrow.rotation.y, Math.atan2(ax - px, az - pz), 1 - Math.exp(-8 * dt));
    beacon.children[1].scale.setScalar(1 + Math.sin(G.time * 4) * 0.08);
  }

  // --- camera ---
  const dist = G.inCar ? 10.5 + speed * 0.12 : 7.5, height = G.inCar ? 5 + speed * 0.05 : 7;
  // keep a clear line of sight: how far back can the camera sit before a building gets in the way?
  const clearTo = yaw => { let t = 0.2; for (; t <= 1.001; t += 0.2) { cp.x = px - Math.sin(yaw) * dist * t; cp.z = pz - Math.cos(yaw) * dist * t; const ox = cp.x, oz = cp.z; collide(cp, 0.6, true); if (Math.abs(cp.x - ox) + Math.abs(cp.z - oz) > 0.01) break; } return t - 0.2; };
  let pull = clearTo(G.camYaw);
  if (pull < 0.99 && !G.inCar && !cl && drag === null)       // on foot: swing round to the nearest open angle
    for (const o of [0.45, -0.45, 0.9, -0.9, 1.4, -1.4, 2, -2, 2.6, -2.6, 3.14]) if (clearTo(G.camYaw + o) > 0.99) { G.camYaw += Math.sign(o) * Math.min(Math.abs(o), 3.2 * dt); break; }
  G.pull = G.pull === undefined ? pull : G.pull + (Math.max(0.35, pull) - G.pull) * (1 - Math.exp(-6 * dt));
  v3.set(px - Math.sin(G.camYaw) * dist * G.pull, height + (1 - G.pull) * 9, pz - Math.cos(G.camYaw) * dist * G.pull);
  camPos.lerp(v3, 1 - Math.exp(-(G.inCar ? 9 : 7) * dt)); camLook.lerp(v3.set(px, 1.6, pz), 1 - Math.exp(-14 * dt));
  G.shake = Math.max(0, G.shake - dt * 2.2);
  camera.position.set(camPos.x + (Math.random() - 0.5) * G.shake, camPos.y + (Math.random() - 0.5) * G.shake, camPos.z + (Math.random() - 0.5) * G.shake);
  camera.lookAt(camLook); camera.updateMatrixWorld(); camera.matrixWorldInverse.copy(camera.matrixWorld).invert();

  // --- HUD ---
  findInteraction();
  const pr = G.dialog || frozen ? null : G.inCar ? (speed < 3 ? 'E — get out' : null) : near && near.npc ? `E — talk to ${near.npc.name}` : near && near.car ? `E — drive ${near.car.spec.name}` : null;
  hud.prompt.classList.toggle('hidden', !pr); if (pr) hud.prompt.textContent = pr;
  if (toastT > 0) { toastT -= dt; if (toastT <= 0) hud.toast.classList.add('hidden'); }
  streetT -= dt; if (streetT <= 0) { streetT = 0.4; hud.street.textContent = roadEdgeDist(px, pz) < 6 && roadHit && roadHit.r.n ? roadHit.r.n : ''; }
  updateDialog(dt); updateBubbles(dt);
  drawMinimap(px, pz, G.inCar ? ph : player.h); if (G.mapOpen) drawBigMap(px, pz, ph);
  if (AC) { engGain.gain.value = G.inCar ? 0.025 + Math.min(0.03, speed * 0.0015) : 0; engOsc.frequency.value = 45 + speed * 5.5; }

  renderer.render(scene, camera);
}
G.tick = frame; G.npcs = npcs; G.route = route; G.cars = cars; G.player = player; G.A = PT_A; G.B = PT_B;  // lets tests step the simulation by hand
(function loop(now) { requestAnimationFrame(loop); frame(now); })(performance.now());
})();
