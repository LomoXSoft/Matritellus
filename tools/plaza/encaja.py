"""Fit the camera of a photograph to points of a hand-built place's own frame (x along its front, y up from its floor,
z out of the front), so the game can be photographed from the same place. (The same tool as tools/petril/encaja.py,
with the prefix of the view's name as an option: pz_ for the Plaza del Ayuntamiento, pt_ for the Petril.)

    python encaja.py name W H  "X,Y,Z,px,py" ...  [--start x,y,z,tx,ty,tz,fov] [--fix-fov F] [--pp] [--level] [--eye H] [--prefijo pz]

W, H: the size of the picture's content in pixels; px, py are measured in that content.
--pp     the middle of the lens is not the middle of the picture (a cropped or shifted photograph): fit it too
--level  the camera was held level (uprights stay upright in the picture): pitch 0
--eye H  the camera was H metres over the floor of the square
Prints the residual of each point, and writes vistas/<name>.json: the --vistas entry (pt_name:x,z,h,tx,tz,th,fov,
with Godot's vertical fov for a 1280x720 picture) and the piece of that picture which is the photograph.
No roll: the camera is held level sideways, as Camera3D.look_at leaves it."""
import sys, math, json, os
import numpy as np

RW, RH = 1280.0, 720.0          # the game's own pictures

def axes(yaw, pitch):
    f = np.array([math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch)])
    r = np.cross(f, np.array([0.0, 1.0, 0.0])); r /= np.linalg.norm(r)
    return f, r, np.cross(r, f)

def project(par, P):
    f, r, u = axes(par[3], par[4])
    v = P - par[0:3]
    zc = v @ f
    return np.stack([par[6] + par[5] * (v @ r) / zc, par[7] - par[5] * (v @ u) / zc], axis=1)

def fit(P, Q, par, free, rounds=600):
    par = np.array(par, dtype=float)
    lam = 1e-2
    def res(p): return (project(p, P) - Q).ravel()
    r = res(par); best = r @ r
    for _ in range(rounds):
        J = np.zeros((r.size, len(free)))
        for k, i in enumerate(free):
            d = np.zeros(8); h = 1e-5 * max(1.0, abs(par[i])); d[i] = h
            J[:, k] = (res(par + d) - r) / h
        A = J.T @ J; g = J.T @ r
        try: step = np.linalg.solve(A + lam * np.diag(np.diag(A) + 1e-9), -g)
        except np.linalg.LinAlgError: lam *= 10; continue
        trial = par.copy(); trial[free] += step
        rt = res(trial)
        if np.all(np.isfinite(rt)) and rt @ rt < best:
            par, r, best = trial, rt, rt @ rt; lam = max(lam / 3.0, 1e-8)
        else:
            lam = min(lam * 4.0, 1e8)
    return par, r

if __name__ == '__main__':
    a = sys.argv[1:]
    name, W, H = a[0], float(a[1]), float(a[2])
    pts = []; start = None; fix = None; pp = False; level = False; eye = None; prefix = 'pz'
    i = 3
    while i < len(a):
        if a[i] == '--start': start = [float(v) for v in a[i + 1].split(',')]; i += 2; continue
        if a[i] == '--fix-fov': fix = float(a[i + 1]); i += 2; continue
        if a[i] == '--eye': eye = float(a[i + 1]); i += 2; continue
        if a[i] == '--prefijo': prefix = a[i + 1]; i += 2; continue
        if a[i] == '--pp': pp = True; i += 1; continue
        if a[i] == '--level': level = True; i += 1; continue
        pts.append([float(v) for v in a[i].split(',')]); i += 1
    pts = np.array(pts); P = pts[:, 0:3]; Q = pts[:, 3:5]
    if start is None:
        mid = P.mean(axis=0); start = [mid[0], 1.6, mid[2] + 18.0, mid[0], mid[1], mid[2], 46.0]
    d = np.array(start[3:6]) - np.array(start[0:3]); d /= np.linalg.norm(d)
    fov0 = fix if fix is not None else start[6]
    par0 = [start[0], start[1], start[2], math.atan2(d[0], -d[2]), 0.0 if level else math.asin(d[1]), (H / 2.0) / math.tan(math.radians(fov0) / 2.0), W / 2.0, H / 2.0]
    if eye is not None: par0[1] = eye
    free = [0, 2, 3] + ([] if eye is not None else [1]) + ([] if level else [4]) + ([] if fix is not None else [5]) + ([6, 7] if pp else [])
    par, r = fit(P, Q, par0, free)
    rr = r.reshape(-1, 2)
    for k in range(len(P)):
        print('  (%6.2f,%6.2f,%6.2f) -> (%6.1f,%6.1f)   off (%5.1f,%5.1f)' % (P[k, 0], P[k, 1], P[k, 2], Q[k, 0], Q[k, 1], rr[k, 0], rr[k, 1]))
    C = par[0:3]; F, cx, cy = par[5], par[6], par[7]
    f, _r, _u = axes(par[3], par[4])
    T = C + f * 20.0
    s = min(RW / 2.0 / max(cx, W - cx), RH / 2.0 / max(cy, H - cy))       # game pixels for each pixel of the photograph
    fov = 2.0 * math.degrees(math.atan((RH / 2.0) / (F * s)))
    crop = [RW / 2.0 - cx * s, RH / 2.0 - cy * s, RW / 2.0 + (W - cx) * s, RH / 2.0 + (H - cy) * s]
    print('rms %.2f px   camera (%.2f, %.2f, %.2f)  yaw %.1f  pitch %.1f  F %.0f px  middle (%.0f, %.0f)' % (math.sqrt((r @ r) / len(P)), C[0], C[1], C[2], math.degrees(par[3]), math.degrees(par[4]), F, cx, cy))
    view = '%s_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f' % (prefix, name, C[0], C[2], C[1], T[0], T[2], T[1], fov)
    print(view, ' crop', [round(v, 1) for v in crop])
    here = os.path.dirname(os.path.abspath(__file__))
    os.makedirs(os.path.join(here, 'vistas'), exist_ok=True)
    json.dump({'view': view, 'crop': crop, 'size': [W, H]}, open(os.path.join(here, 'vistas', '%s.json' % name), 'w'))
