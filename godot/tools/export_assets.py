#!/usr/bin/env python3
"""Extrai os dados do mapa "Reinos 3D — Reinos Independentes" (HTML) para o projeto Godot
e pré-calcula as texturas que a versão web gerava ao abrir (normais, mistura de terrenos,
padrões, fronteiras). Assim o jogo no celular abre bem mais rápido.

Uso:  python3 godot/tools/export_assets.py  [caminho/do/mapa.html]
Saída: godot/data/
"""
import base64, io, json, math, pathlib, re, sys
import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'citybuilder/assets/Reinos_3D_Reinos_Independentes.html'
OUT = ROOT / 'godot/data'
OUT.mkdir(parents=True, exist_ok=True)
html = SRC.read_text(encoding='utf-8')

def img(name):
    m = re.search(name + r"='data:image/(\w+);base64,([^']+)'", html)
    raw = base64.b64decode(m.group(2))
    return raw, m.group(1), Image.open(io.BytesIO(raw))

# ---------- dados políticos ----------
m = re.search(r'const FEUDAL=(\{.*?\});\n', html, re.S)
F = json.loads(m.group(1))
for k in F['houses']:   # mesma migração que o HTML faz ao abrir
    k['rank'] = 'reino'; k['liege'] = -1
    if k['name'].startswith('Casa Real de '): k['name'] = 'Reino de ' + k['name'][13:]
    elif k['name'].startswith('Casa '): k['name'] = 'Reino de ' + k['name'][5:]
(OUT / 'feudal.json').write_text(json.dumps(F, ensure_ascii=False), encoding='utf-8')

# ---------- mundo ----------
WX = 3072.0; WZ = float(round(3072 * 1748 / 2480)); HX, HZ = WX / 2, WZ / 2
PW, PH = 2048, 1024
raw, ext, alb = img('ALBEDO_SRC'); (OUT / 'albedo_jpg.dat').write_bytes(raw)
_, _, hm = img('HMAP_SRC'); hm = np.asarray(hm.convert('RGB')).astype(np.float64)
HMH, HMW = hm.shape[:2]
HM = (hm[..., 0] * 256 + hm[..., 1]) / 65535 * 200 - 40
CL = hm[..., 2].astype(np.uint8)
HM.astype('<f4').tofile(OUT / 'heights.bin'); CL.tofile(OUT / 'classes.bin')
_, _, pv = img('PROV_SRC'); pv = np.asarray(pv.convert('RGB')).astype(np.int32)
PID = (pv[..., 0] + pv[..., 1] * 256).astype(np.uint16)
PID.astype('<u2').tofile(OUT / 'provid.bin')
_, _, rv = img('RIVER_SRC'); RIV = np.asarray(rv.convert('L').resize((PW, PH), Image.BILINEAR)).astype(np.uint8)
RIV.tofile(OUT / 'river.bin')
meta = dict(WX=WX, WZ=WZ, HMW=HMW, HMH=HMH, PW=PW, PH=PH)

def htF(x, z):
    fx = np.clip((x + HX) / WX * (HMW - 1), 0, HMW - 1.001); fz = np.clip((z + HZ) / WZ * (HMH - 1), 0, HMH - 1.001)
    i = fx.astype(int); j = fz.astype(int); u = fx - i; v = fz - j
    return (HM[j, i] * (1 - u) + HM[j, i + 1] * u) * (1 - v) + (HM[j + 1, i] * (1 - u) + HM[j + 1, i + 1] * u) * v
def classAt(x, z):
    i = np.rint(np.clip((x + HX) / WX * (HMW - 1), 0, HMW - 1)).astype(int); j = np.rint(np.clip((z + HZ) / WZ * (HMH - 1), 0, HMH - 1)).astype(int)
    return CL[j, i]
def ss(a, b, t):
    q = np.clip((t - a) / (b - a), 0, 1); return q * q * (3 - 2 * q)
def hash2(x, z):
    n = np.sin(x * 127.1 + z * 311.7) * 43758.5453; return n - np.floor(n)
def save_rgba(a, name):
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).save(OUT / name, format='PNG')  # .dat: o Godot não reimporta

# nós da malha do terreno (513 x 321) — idênticos à versão web
NX, NZ = 512, 320
gi, gj = np.meshgrid(np.arange(NX + 1), np.arange(NZ + 1))
NH = htF(-HX + gi * (WX / NX), -HZ + gj * (WZ / NZ))
NH.astype('<f4').tofile(OUT / 'nodeh.bin'); meta.update(NX=NX, NZ=NZ)

# normais + oclusão + profundidade rasa (1024x512)
W, H = 1024, 512
jj, ii = np.meshgrid(np.arange(H), np.arange(W), indexing='ij')
z = -HZ + (jj + .5) / H * WZ; x = -HX + (ii + .5) / W * WX; h = htF(x, z); e = 3
dx = (htF(x + e, z) - htF(x - e, z)) / (2 * e); dz = (htF(x, z + e) - htF(x, z - e)) / (2 * e); il = 1 / np.sqrt(1 + dx * dx + dz * dz)
D = [(1, 0), (-1, 0), (0, 1), (0, -1), (.7, .7), (-.7, .7), (.7, -.7), (-.7, -.7)]
a1 = sum(htF(x + p * 9, z + q * 9) for p, q in D) / 8; a2 = sum(htF(x + p * 30, z + q * 30) for p, q in D) / 8
ao = np.clip(1 + (h - a1) * .06 + (h - a2) * .02, .62, 1.08)
save_rgba(np.dstack([(-dx * il * .5 + .5) * 255, (-dz * il * .5 + .5) * 255, ao / 1.1 * 255, np.clip((h + 40) / 50, 0, 1) * 255]), 'normals_png.dat')

# mistura de terrenos: R grama, G areia, B rocha, A neve
MAP = np.array([[0, 1, 0, 0], [1, 0, 0, 0], [1, 0, 0, 0], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]], float)
w = np.zeros((H, W, 4))
for b in (-1, 0, 1):
    for a in (-1, 0, 1):
        c = classAt(x + a * 3.2, z + b * 3.2); c = np.where(c < 7, c, 2); w += MAP[c] * (1 if (a or b) else 2)
beach = (h > -1) & (h < 1.6); w[..., 1] += np.where(beach, (1 - ss(.8, 1.6, h)) * 6, 0)
w /= np.maximum(w.sum(-1, keepdims=True), 1e-6)
save_rgba(w * 255, 'splat_png.dat')

# padrões ladrilháveis (256²): grama, dunas, rocha, neve
N = 256
def ph(i, j, p, s): return hash2(((i % p) + p) % p + .13 * p + s, ((j % p) + p) % p - .71 * p - s)
def pn(X, Y, p, s=0):
    i = np.floor(X); j = np.floor(Y); u = X - i; v = Y - j; u = u * u * (3 - 2 * u); v = v * v * (3 - 2 * v)
    return (ph(i, j, p, s) * (1 - u) + ph(i + 1, j, p, s) * u) * (1 - v) + (ph(i, j + 1, p, s) * (1 - u) + ph(i + 1, j + 1, p, s) * u) * v
def fb(X, Y, ps, s):
    v = 0; t = 0; a = 1
    for p in ps: v = v + a * pn(X * p / N, Y * p / N, p, s); t += a; a *= .55
    return v / t
Y, X = np.meshgrid(np.arange(N), np.arange(N), indexing='ij'); X = X.astype(float); Y = Y.astype(float)
g = hash2(X * .91 + 3, Y * 1.13 - 7); clump = fb(X, Y, [8, 16], 1)
grass = np.clip(.18 + fb(X, Y, [16, 32, 64], 2) * .55 + g * .32 - ss(.62, .8, clump) * .25, 0, 1)
dune = .5 + .5 * np.sin((Y + fb(X, Y, [4, 8], 3) * 40) * math.pi * 2 / 16); sand = np.clip(.25 + dune * .35 + fb(X, Y, [32, 64], 4) * .25 + g * .18, 0, 1)
rr = 1 - np.abs(fb(X, Y, [8, 16, 32], 5) * 2 - 1)
rock = np.clip(.15 + fb(X, Y, [16, 32, 64], 6) * .5 + rr ** 6 * .45, 0, 1) * (1 - .45 * (1 - np.abs(fb(X, Y, [16], 8) * 2 - 1)) ** 14)
snow = np.clip(.55 + fb(X, Y, [8, 16, 32], 7) * .35 + g * .1, 0, 1)
save_rgba(np.dstack([grass, sand, rock, snow]) * 255, 'patterns_png.dat')
# ruído de detalhe (256², tons de cinza)
def ph1(i, j, p): return hash2(((i % p) + p) % p + .13 * p, ((j % p) + p) % p - .71 * p)
def pn1(X, Y, p):
    i = np.floor(X); j = np.floor(Y); u = X - i; v = Y - j; u = u * u * (3 - 2 * u); v = v * v * (3 - 2 * v)
    return (ph1(i, j, p) * (1 - u) + ph1(i + 1, j, p) * u) * (1 - v) + (ph1(i, j + 1, p) * (1 - u) + ph1(i + 1, j + 1, p) * u) * v
s_ = sum(wt * pn1(X * p / N, Y * p / N, p) for p, wt in [(4, .3), (8, .25), (16, .2), (32, .15), (64, .1)]) + .1 * hash2(X * .91, Y * 1.13)
Image.fromarray((np.clip((s_ - .5) * 1.7 + .5, 0, 1) * 255).astype(np.uint8), 'L').save(OUT / 'detail_png.dat', format='PNG')

# fronteiras: distância exata até a mediatriz das sementes vizinhas (província, reino, região) + rio no alfa
FW, FH = F['frame']; K = (PW / FW) * 16
prov = F['prov']; SX = np.array([p[0] for p in prov]); SY = np.array([p[1] for p in prov]); HO = np.array([p[2] for p in prov])
RE = np.array([F['houses'][hh]['region'] for hh in HO])
NP = len(prov); ADJ = [[] for _ in range(NP)]; A = F['adj']
for k in range(0, len(A), 2): ADJ[A[k]].append(A[k + 1]); ADJ[A[k + 1]].append(A[k])
out = np.full((PH, PW, 4), 255.0); out[..., 3] = RIV
jy, ix = np.nonzero(PID)
ids = PID[jy, ix].astype(int) - 1
fx = (ix + .5) * FW / PW - .5; fy = (jy + .5) * FH / PH - .5
dp = np.full(ids.shape, 99.0); dh = dp.copy(); dr = dp.copy()
order = np.argsort(ids); bounds = np.searchsorted(ids[order], np.arange(NP + 1))
for a in range(NP):
    sel = order[bounds[a]:bounds[a + 1]]
    if not len(sel): continue
    px, py = fx[sel], fy[sel]; da2 = (px - SX[a]) ** 2 + (py - SY[a]) ** 2
    lp = np.full(len(sel), 99.0); lh = lp.copy(); lr = lp.copy()
    for q in ADJ[a]:
        dd = ((px - SX[q]) ** 2 + (py - SY[q]) ** 2 - da2) / (2 * math.hypot(SX[q] - SX[a], SY[q] - SY[a]))
        lp = np.minimum(lp, dd)
        if HO[q] != HO[a]: lh = np.minimum(lh, dd)
        if RE[q] != RE[a]: lr = np.minimum(lr, dd)
    dp[sel], dh[sel], dr[sel] = lp, lh, lr
out[jy, ix, 0] = np.clip(dp * K, 0, 255); out[jy, ix, 1] = np.clip(dh * K, 0, 255); out[jy, ix, 2] = np.clip(dr * K, 0, 255)
save_rgba(out, 'borders_png.dat')
(OUT / 'meta.json').write_text(json.dumps(meta))
print('ok', OUT, meta)
