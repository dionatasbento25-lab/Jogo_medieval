extends Node
## Castelos em estilo "livro de histórias": torres redondas de pedra com telhados cônicos,
## casas em enxaimel com reboco pastel, muralha curva com ameias, chaminés, hera e flores.
## Cada reino tem um castelo único, gerado a partir de uma semente do próprio reino
## (formato da muralha, torres, torre de menagem, casas, cores e bandeiras).
## O nível do castelo (1 a 5) acrescenta casas, altura e torres finas.

const STONES := ["#d6c39a", "#cdb98f", "#c9b99c", "#d4bf8a", "#c8b28f", "#c2b79c"]
const ROOFS := ["#c2693f", "#c2693f", "#b8583b", "#c27a48", "#a9473a", "#5d7392", "#7b5c49", "#6f7f4c", "#8c5c78"]
const PLASTERS := ["#b8c59b", "#e9ddc0", "#e6bcaa", "#dccb9f", "#c9d5bf", "#f0dab0", "#d7c2d8", "#bfd3d6"]
const TIMBER := "#5e4330"
const MORTAR_DARK := 0.9

var rs = 1
func _r() -> float:
	rs = (rs * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(rs) / 4294967296.0
func _rr(a: float, b: float) -> float: return a + (b - a) * _r()
func _pick(arr: Array): return arr[int(_r() * arr.size()) % arr.size()]
func _jit(c: Color, a := 0.045) -> Color:
	var k = 1.0 + (_r() - 0.5) * 2.0 * a; var w = (_r() - 0.5) * a * 0.5
	return Color(clampf(c.r * k + w, 0, 1), clampf(c.g * k + w * 0.8, 0, 1), clampf(c.b * k + w * 0.6, 0, 1))
func C(x) -> Color: return M.col(x)

## Aplica giro (em Y) e posição aos vértices criados por fn — permite montar peças em coordenadas locais.
func xform(origin: Vector3, ang: float, fn: Callable) -> void:
	var s0: int = M.G.v.size(); fn.call()
	var c = cos(ang); var s = sin(ang)
	for i in range(s0, M.G.v.size()):
		var p: Vector3 = M.G.v[i]; var n: Vector3 = M.G.n[i]
		M.G.v[i] = Vector3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c) + origin
		M.G.n[i] = Vector3(n.x * c + n.z * s, n.y, -n.x * s + n.z * c)

# ---------- peças de pedra ----------
## Cilindro de pedra com fiadas: cada bloco com um tom levemente diferente.
func stone_cyl(x: float, y: float, z: float, r: float, h: float, base: Color, sides := 12, row := 0.78, taper := 0.0) -> void:
	var rows = maxi(1, int(ceil(h / row)))
	for j in rows:
		var y0 = y + h * j / rows; var y1 = y + h * (j + 1) / rows
		var r0 = r - taper * j / rows; var r1 = r - taper * (j + 1) / rows; var off = 0.5 if j % 2 else 0.0
		for i in sides:
			var a0 = (i + off) * TAU / sides; var a1 = (i + 1 + off) * TAU / sides
			M.quad(Vector3(x + r0 * cos(a0), y0, z + r0 * sin(a0)), Vector3(x + r1 * cos(a0), y1, z + r1 * sin(a0)), Vector3(x + r1 * cos(a1), y1, z + r1 * sin(a1)), Vector3(x + r0 * cos(a1), y0, z + r0 * sin(a1)), _jit(base))
func disc(x: float, y: float, z: float, r: float, c: Color, sides := 14) -> void:
	for i in sides:
		var a0 = i * TAU / sides; var a1 = (i + 1) * TAU / sides
		M.tri(Vector3(x, y, z), Vector3(x + r * cos(a1), y, z + r * sin(a1)), Vector3(x + r * cos(a0), y, z + r * sin(a0)), c)
## Coroa de ameias sobre uma torre redonda (cornija mais larga + merlões)
func merlon_ring(x: float, y: float, z: float, r: float, stone: Color, n := 10) -> void:
	stone_cyl(x, y, z, r + 0.28, 0.45, mulc(stone, 0.95), 16, 0.45)
	disc(x, y + 0.45, z, r + 0.28, mulc(stone, 0.85), 16)
	for i in n:
		var a = (i + 0.5) * TAU / n
		xform(Vector3(x + cos(a) * (r + 0.1), y + 0.45, z + sin(a) * (r + 0.1)), -a + PI / 2, func(): M.box(0, 0, 0, r * 0.42, 0.72, 0.42, _jit(stone)))
func mulc(c: Color, k: float) -> Color: return Color(c.r * k, c.g * k, c.b * k)
## Telhado cônico com beiral alargado, faixas de telhas e ponteira
func cone_roof(x: float, y: float, z: float, r: float, h: float, roof: Color, sides := 14, gold := false) -> void:
	var eave = r * 1.22; var y1 = y + h * 0.1; var r1 = r * 0.98
	for i in sides:
		var a0 = i * TAU / sides; var a1 = (i + 1) * TAU / sides; var c = _jit(mulc(roof, 0.9))
		M.quad(Vector3(x + eave * cos(a0), y - 0.15, z + eave * sin(a0)), Vector3(x + r1 * cos(a0), y1, z + r1 * sin(a0)), Vector3(x + r1 * cos(a1), y1, z + r1 * sin(a1)), Vector3(x + eave * cos(a1), y - 0.15, z + eave * sin(a1)), c)
		M.tri(Vector3(x + eave * cos(a0), y - 0.15, z + eave * sin(a0)), Vector3(x + eave * cos(a1), y - 0.15, z + eave * sin(a1)), Vector3(x, y - 0.05, z), mulc(roof, 0.5))
	var bands = 6
	for b in bands:
		var t0 = float(b) / bands; var t1 = float(b + 1) / bands
		var ya = y1 + (h - h * 0.1) * t0; var yb = y1 + (h - h * 0.1) * t1; var ra = r1 * (1 - t0); var rb = r1 * (1 - t1)
		var shade = 1.0 if b % 2 == 0 else 0.92
		for i in sides:
			var a0 = i * TAU / sides; var a1 = (i + 1) * TAU / sides; var c = _jit(mulc(roof, shade), 0.05)
			if b == bands - 1: M.tri(Vector3(x + ra * cos(a0), ya, z + ra * sin(a0)), Vector3(x, yb, z), Vector3(x + ra * cos(a1), ya, z + ra * sin(a1)), c)
			else: M.quad(Vector3(x + ra * cos(a0), ya, z + ra * sin(a0)), Vector3(x + rb * cos(a0), yb, z + rb * sin(a0)), Vector3(x + rb * cos(a1), yb, z + rb * sin(a1)), Vector3(x + ra * cos(a1), ya, z + ra * sin(a1)), c)
	M.cyl(x, y + h - 0.1, z, 0.06, 0.9, "#4a3a2c", 5)
	M.ball(x, y + h + 0.85, z, 0.16, "#f2c13a" if gold else "#8a7a5a", 1, 3, 6, false)
## Janela em arco (escura, com moldura de pedra) numa superfície de torre redonda
func tower_window(x: float, y: float, z: float, r: float, a: float, stone: Color) -> void:
	xform(Vector3(x + cos(a) * (r - 0.02), y, z + sin(a) * (r - 0.02)), -a + PI / 2, func():
		M.box(0, 0, 0, 0.62, 1.0, 0.12, mulc(stone, 0.8)); M.box(0, 0.08, 0.05, 0.42, 0.78, 0.1, "#2c2622"); M.ball(0, 0.86, 0.05, 0.21, "#2c2622", 0.6, 2, 6, false)
		M.box(0, -0.05, 0.08, 0.7, 0.1, 0.18, mulc(stone, 0.85)))
func ivy(x: float, y: float, z: float, r: float, a: float, h: float) -> void:
	for k in int(h / 0.35):
		var aa = a + _rr(-0.18, 0.18)
		M.ball(x + cos(aa) * (r + 0.05), y + k * 0.35 + _rr(0, 0.2), z + sin(aa) * (r + 0.05), _rr(0.16, 0.26), _jit(C("#5c8a3e"), 0.12), 0.7, 2, 4, false)
func flower_clump(x: float, y: float, z: float) -> void:
	M.ball(x, y + 0.15, z, 0.3, _jit(C("#5f9445"), 0.1), 0.6, 2, 5, false)
	var cs = ["#f4a6c0", "#ffffff", "#b48ad8", "#f6d36b", "#e97b8a"]
	for k in 3: M.ball(x + _rr(-0.25, 0.25), y + 0.32, z + _rr(-0.25, 0.25), 0.09, _pick(cs), 1, 2, 4, false)

## Torre redonda completa. kind: 0 telhado cônico, 1 ameias, 2 ameias + torrinha com cone.
func round_tower(x: float, z: float, r: float, h: float, kind: int, st: Color, roof: Color, gold: bool, fx: Dictionary) -> void:
	stone_cyl(x, 0, z, r + 0.12, 0.8, mulc(st, 0.88), 14, 0.4)
	stone_cyl(x, 0.8, z, r, h - 0.8, st, 12, 0.78, r * 0.06)
	var wa = atan2(z, x)
	tower_window(x, h * 0.55, z, r * 0.96, wa, st)
	if h > 6: tower_window(x, h * 0.28, z, r * 0.98, wa + 0.9, st)
	if _r() < 0.55: ivy(x, 0.3, z, r, wa + _rr(-1.2, 1.2), h * _rr(0.3, 0.6))
	if kind == 0:
		cone_roof(x, h, z, r * 1.08, r * _rr(2.0, 2.8), roof, 14, gold); fx.tops.append(Vector3(x, h + r * 2.4, z))
	else:
		merlon_ring(x, h, z, r * 0.96, st)
		disc(x, h + 0.02, z, r * 0.95, mulc(st, 0.75), 14)
		if kind == 2:
			var r2 = r * 0.45; stone_cyl(x, h, z, r2, 2.4, mulc(st, 1.03), 10, 0.6)
			cone_roof(x, h + 2.4, z, r2 * 1.15, r2 * 3.2, roof, 10, gold); fx.tops.append(Vector3(x, h + 2.4 + r2 * 3.5, z))
		else: fx.flags.append(Vector3(x, h + 0.45, z))

## Trecho de muralha entre dois pontos (blocos de pedra, passadiço e ameias do lado de fora)
func wall_seg(a: Vector2, b: Vector2, h: float, t: float, st: Color) -> void:
	var L := a.distance_to(b); var mid = (a + b) / 2; var ang = atan2(b.y - a.y, b.x - a.x)
	var out = Vector2(-sin(ang), cos(ang))      # normal; decide qual lado é "fora" (longe do centro)
	var sgn = 1.0 if mid.dot(out) > 0 else -1.0
	xform(Vector3(mid.x, 0, mid.y), -ang, func():
		var rows = maxi(1, int(round(h / 0.78))); var bw = 1.6
		for j in rows:
			var y0 = h * j / rows; var y1 = h * (j + 1) / rows; var off = bw * 0.5 if j % 2 else 0.0; var xs = -L / 2 - off
			while xs < L / 2:
				var x0 = maxf(xs, -L / 2); var x1 = minf(xs + bw, L / 2)
				if x1 > x0:
					for side in [-1.0, 1.0]:
						var zz = side * t / 2
						M.quad(Vector3(x0, y0, zz), Vector3(x0, y1, zz), Vector3(x1, y1, zz), Vector3(x1, y0, zz), _jit(st))
				xs += bw
		M.box(0, h - 0.02, 0, L, 0.1, t, mulc(st, 0.78))
		var oz = sgn * (t / 2 - 0.2); var n = maxi(2, int(L / 1.05))
		for k in n:
			var xx = -L / 2 + (k + 0.5) * L / n
			M.box(xx, h, oz, 0.62, 0.68, 0.42, _jit(st))
		M.box(0, h, -oz * 0.9, L, 0.35, 0.22, mulc(st, 0.9))
		# hera e flores ao pé da muralha (lado de fora)
		for k in int(L / 4.5):
			var xx = _rr(-L / 2 + 0.8, L / 2 - 0.8)
			if _r() < 0.5:
				for q in int(_rr(2, 6)): M.ball(xx + _rr(-0.4, 0.4), 0.3 + q * 0.38, sgn * (t / 2 + 0.06), _rr(0.16, 0.26), _jit(C("#5c8a3e"), 0.12), 0.7, 2, 4, false)
			flower_clump(xx + _rr(-0.6, 0.6), 0, sgn * (t / 2 + 0.45)))

## Casa em enxaimel (porta virada para +z), montada em coordenadas locais
func tf_house(w: float, d: float, floors: int, plaster: Color, roof: Color, st: Color, fx: Dictionary, origin: Vector3, ang: float, turret: bool) -> void:
	var tm = C(TIMBER)
	xform(origin, ang, func():
		M.box(0, 0, 0, w + 0.1, 0.55, d + 0.1, mulc(st, 0.9))
		var y = 0.55; var fh = 2.15
		for f in floors:
			var ww = w + f * 0.25; var dd = d + f * 0.25
			M.box(0, y, 0, ww, fh, dd, plaster)
			# vigas: cantos, linhas de piso, montantes e diagonais nas duas fachadas e laterais
			for sx in [-1, 1]:
				for sz in [-1, 1]: M.box(sx * (ww / 2 - 0.07), y, sz * (dd / 2 - 0.07), 0.16, fh, 0.16, tm)
			M.box(0, y + fh - 0.14, 0, ww + 0.04, 0.16, dd + 0.04, tm)
			M.box(0, y, 0, ww + 0.03, 0.14, dd + 0.03, tm)
			for sz in [-1, 1]:
				var zf: float = sz * (dd / 2 + 0.03); var n = maxi(1, int(ww / 1.1))
				for k in range(1, n):
					var xx = -ww / 2 + k * ww / n; M.box(xx, y, zf, 0.12, fh, 0.05, tm)
				# diagonais em X nos painéis das pontas
				var px = ww / 2 - 0.45
				for sx in [-1, 1]:
					var x0: float = sx * px; var hw = 0.3
					M.quad(Vector3(x0 - hw, y + 0.15, zf), Vector3(x0 - hw + 0.12, y + 0.15, zf), Vector3(x0 + hw, y + fh - 0.2, zf), Vector3(x0 + hw - 0.12, y + fh - 0.2, zf), tm)
			for sx in [-1, 1]:
				var xf: float = sx * (ww / 2 + 0.03); var n = maxi(1, int(dd / 1.1))
				for k in range(1, n): M.box(xf, y, -dd / 2 + k * dd / n, 0.05, fh, 0.12, tm)
			# janelas
			var nw = maxi(1, int(ww / 1.4))
			for k in nw:
				var xx = -ww / 2 + (k + 0.5) * ww / nw
				if f == 0 and absf(xx) < 0.6: continue
				_window(xx, y + 0.75, dd / 2 + 0.04)
			_window(0, y + 0.75, -dd / 2 - 0.04, true)
			y += fh
		M.door(0, 0.55, d / 2 + 0.06, 0.8, 1.5, "#6b4228")
		var wr = w + (floors - 1) * 0.25; var dr = d + (floors - 1) * 0.25
		M.thick_roof(0, y, 0, wr, dr, wr * _rr(0.95, 1.2), roof, plaster, 0.32, 0.22)
		# chaminé
		var cx = wr * 0.25 * (1 if _r() < 0.5 else -1)
		M.box(cx, y + 0.3, -dr * 0.2, 0.45, wr * 0.75 + 0.6, 0.45, mulc(st, 0.85)); M.box(cx, y + wr * 0.75 + 0.9, -dr * 0.2, 0.55, 0.12, 0.55, mulc(st, 0.7))
		fx.smoke.append(Vector3(cx, y + wr * 0.75 + 1.1, -dr * 0.2))
		if turret:
			var tx = w / 2 + 0.1; var tz = d / 2 - 0.1
			M.cyl(tx, 0.55 + 1.2, tz, 0.55, y - 0.55, plaster, 10); M.box(tx, 0.55 + 1.2, tz, 0.14, 0.14, 0.14, tm)
			for k in 3: M.cyl(tx, 0.55 + 1.2 + k * 1.0, tz, 0.57, 0.1, tm, 10)
			cone_roof(tx, y + 1.2, tz, 0.62, 2.0, roof, 10)
		)
	# coordenadas da chaminé no espaço do castelo
	var c = cos(ang); var s = sin(ang); var p: Vector3 = fx.smoke[fx.smoke.size() - 1]
	fx.smoke[fx.smoke.size() - 1] = Vector3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c) + origin
func _window(x: float, y: float, z: float, back := false) -> void:
	var s = -1.0 if back else 1.0
	M.box(x, y, z, 0.62, 0.78, 0.06, "#f2e7cf"); M.box(x, y + 0.08, z + s * 0.03, 0.46, 0.62, 0.06, "#3b4d5f"); M.box(x, y + 0.36, z + s * 0.06, 0.46, 0.06, 0.05, "#f2e7cf")
	M.box(x, y - 0.12, z + s * 0.08, 0.7, 0.14, 0.22, "#7a5232")
	M.ball(x - 0.18, y - 0.0, z + s * 0.16, 0.1, "#e97b8a", 1, 2, 5, false); M.ball(x + 0.15, y - 0.0, z + s * 0.16, 0.1, "#f6d36b", 1, 2, 5, false)

## Torre de menagem: 0 redonda larga com torre fina e agulha, 1 quadrada com ameias e torrinhas, 2 redonda alta com cone
func keep(x: float, z: float, h: float, kind: int, st: Color, roof: Color, banner: Color, gold: bool, fx: Dictionary) -> void:
	if kind == 1:
		var w = 5.2; var d = 4.6
		xform(Vector3(x, 0, z), 0.0, func():
			for side in 4:
				var ln = w if side % 2 == 0 else d; var rows = int(h / 0.62)
				for j in rows:
					var y0 = h * j / rows; var y1 = h * (j + 1) / rows; var nb = int(ln / 1.2)
					for k in nb:
						var a0 = -ln / 2 + k * ln / nb; var a1 = a0 + ln / nb; var off = (w / 2 if side % 2 == 1 else d / 2) * (1 if side < 2 else -1)
						if side % 2 == 0: M.quad(Vector3(a0, y0, off), Vector3(a0, y1, off), Vector3(a1, y1, off), Vector3(a1, y0, off), _jit(st))
						else: M.quad(Vector3(off, y0, a0), Vector3(off, y1, a0), Vector3(off, y1, a1), Vector3(off, y0, a1), _jit(st))
			M.box(0, h - 0.05, 0, w + 0.5, 0.4, d + 0.5, mulc(st, 0.9))
			for k in 7:
				var xx = -w / 2 + k * w / 6
				M.box(xx, h + 0.35, d / 2 + 0.1, 0.5, 0.7, 0.4, _jit(st)); M.box(xx, h + 0.35, -d / 2 - 0.1, 0.5, 0.7, 0.4, _jit(st))
			for k in 6:
				var zz = -d / 2 + k * d / 5
				M.box(w / 2 + 0.1, h + 0.35, zz, 0.4, 0.7, 0.5, _jit(st)); M.box(-w / 2 - 0.1, h + 0.35, zz, 0.4, 0.7, 0.5, _jit(st))
			M.box(0, h + 0.3, 0, w, 0.06, d, mulc(st, 0.7))
			M.thick_roof(0, h + 0.3, 0, w * 0.7, d * 0.7, 2.2, roof, mulc(st, 1.05), 0.2, 0.2)
			for k in 3: _window(-w / 2 + (k + 0.5) * w / 3, h * 0.6, d / 2 + 0.02)
			M.door(0, 0, d / 2 + 0.04, 1.3, 2.2, "#5e3b22")
			M.box(-w * 0.28, h * 0.25, d / 2 + 0.06, 0.8, h * 0.4, 0.06, banner); M.box(w * 0.28, h * 0.25, d / 2 + 0.06, 0.8, h * 0.4, 0.06, banner))
		for sx in [-1, 1]:
			var tx: float = x + sx * 2.7; var tz = z + 2.4
			stone_cyl(tx, h - 1.5, tz, 0.65, 2.3, st, 10); cone_roof(tx, h + 0.8, tz, 0.75, 2.6, roof, 10, gold)
		fx.flags.append(Vector3(x, h + 2.5, z)); return
	var r = 2.5 if kind == 0 else 1.9
	stone_cyl(x, 0, z, r + 0.15, 1.0, mulc(st, 0.88), 18, 0.5)
	stone_cyl(x, 1.0, z, r, h - 1.0, st, 16, 0.78, r * 0.05)
	for k in 3: tower_window(x, h * (0.3 + k * 0.22), z, r * 0.97, PI / 2 + (k - 1) * 0.55, st)
	xform(Vector3(x, 0, z + r - 0.02), 0.0, func(): M.door(0, 0, 0, 1.2, 2.1, "#5e3b22"))
	xform(Vector3(x + cos(PI / 2 + 1.2) * r, h * 0.35, z + sin(PI / 2 + 1.2) * r), -(PI / 2 + 1.2) + PI / 2, func(): M.box(0, 0, 0.02, 0.9, h * 0.45, 0.05, banner); M.ball(0, h * 0.45 - 0.4, 0.06, 0.18, "#f2c13a", 1, 2, 6, false))
	if kind == 0:
		merlon_ring(x, h, z, r * 0.95, st, 12); disc(x, h + 0.02, z, r * 0.94, mulc(st, 0.75), 16)
		var r2 = 1.05; stone_cyl(x - 0.5, h, z - 0.4, r2, 4.2, mulc(st, 1.04), 12)
		tower_window(x - 0.5, h + 2.2, z - 0.4, r2 * 0.95, PI / 2, st)
		cone_roof(x - 0.5, h + 4.2, z - 0.4, r2 * 1.15, 4.0, roof, 12, gold); fx.flags.append(Vector3(x - 0.5, h + 8.6, z - 0.4))
	else:
		cone_roof(x, h, z, r * 1.08, r * 2.9, roof, 16, gold); fx.flags.append(Vector3(x, h + r * 3.1, z))

## Portão: arco escuro com portas de madeira e duas torrinhas
## Bloco retangular de pedra (faces com blocos de tons variados), base em y=0
func stone_box(w: float, h: float, d: float, st: Color) -> void:
	var rows = maxi(1, int(round(h / 0.78)))
	for side in 4:
		var ln = w if side % 2 == 0 else d; var off = (d / 2 if side % 2 == 0 else w / 2) * (1 if side < 2 else -1); var nb = maxi(1, int(round(ln / 1.4)))
		for j in rows:
			var y0 = h * j / rows; var y1 = h * (j + 1) / rows
			for k in nb:
				var a0 = -ln / 2 + k * ln / nb; var a1 = a0 + ln / nb
				if side % 2 == 0: M.quad(Vector3(a0, y0, off), Vector3(a0, y1, off), Vector3(a1, y1, off), Vector3(a1, y0, off), _jit(st))
				else: M.quad(Vector3(off, y0, a0), Vector3(off, y1, a0), Vector3(off, y1, a1), Vector3(off, y0, a1), _jit(st))
	M.box(0, h - 0.02, 0, w, 0.04, d, mulc(st, 0.8))
func gatehouse(p: Vector2, ang: float, h: float, st: Color, roof: Color, fx: Dictionary) -> void:
	xform(Vector3(p.x, 0, p.y), ang, func():
		var w = 3.6; var d = 1.9; var gh = h + 1.3
		stone_box(w, gh, d, st)
		M.box(0, 0, d / 2 + 0.01, 1.7, 2.4, 0.06, "#2a2420"); M.ball(0, 2.4, d / 2 + 0.01, 0.85, "#2a2420", 0.7, 2, 8, false)
		M.box(0, 0, d / 2 + 0.05, 1.5, 2.2, 0.06, "#6b4228")
		for k in 4: M.box(-0.56 + k * 0.37, 0, d / 2 + 0.1, 0.06, 2.2, 0.04, "#3c2a1c")
		for k in 5: M.box(-w / 2 + 0.3 + k * (w - 0.6) / 4, gh, d / 2 - 0.2, 0.5, 0.65, 0.4, _jit(st))
		# caminho de pedras do lado de fora
		for k in 6: M.box(_rr(-0.3, 0.3), 0.02, d / 2 + 0.8 + k * 0.75, _rr(0.9, 1.3), 0.06, 0.6, _jit(C("#bdb19a"), 0.1)))
	var c = cos(ang); var s = sin(ang)
	for sx in [-1.0, 1.0]:
		var lx: float = sx * 2.1; var wx = p.x + lx * c; var wz = p.y - lx * s
		stone_cyl(wx, 0, wz, 0.85, h + 2.2, st, 12); cone_roof(wx, h + 2.2, wz, 0.95, 2.6, roof, 12)
		fx.tops.append(Vector3(wx, h + 4.8, wz))

# ---------- castelo completo ----------
var _cache = {}
func _seed_for(k: int) -> int: return (k + 7) * 2654435761 % 4294967296
func model(k: int, L: int) -> ArrayMesh:
	var key = "%d_%d" % [k, L]
	if _cache.has(key): return _cache[key].mesh
	_build(k, L); return _cache[key].mesh
func fx(k: int, L: int) -> Dictionary:
	var key = "%d_%d" % [k, L]
	if not _cache.has(key): _build(k, L)
	return _cache[key].fx
func banner_color(k: int) -> Color:
	return Color.html(W.F.houses[k].color) if k >= 0 and k < W.F.houses.size() else Color("#2f5fb8")

func _build(k: int, L: int) -> void:
	rs = _seed_for(k)
	var st = C(_pick(STONES)); var roof = C(_pick(ROOFS)); var roof2 = C(_pick(ROOFS)); var banner = banner_color(k)
	var plasters = []
	for i in 3: plasters.append(C(_pick(PLASTERS)))
	var gold = L >= 5
	var N := int(_rr(5, 8.99)); var R := 9.4; var wallH := _rr(2.5, 3.1) + L * 0.12
	var tower_kinds = []
	for i in N: tower_kinds.append(0 if _r() < 0.5 else (1 if _r() < 0.6 else 2))
	var keep_kind = int(_r() * 3) % 3; var keep_h = _rr(7.5, 9.5) + L * 0.9
	var keep_pos = Vector2(_rr(-1.8, 1.8), _rr(-3.6, -2.2))
	var pts = []
	var a0 = PI / 2 - PI / N
	for i in N:
		var a = a0 + i * TAU / N + (_rr(-0.12, 0.12) if i > 1 else 0.0)
		var rr = R * (_rr(0.84, 1.0) if i > 1 else 0.97)
		pts.append(Vector2(cos(a) * rr, sin(a) * rr))
	var fxd = {flags = [], smoke = [], tops = []}
	M.begin()
	M.m_plot(24.0, "#86a861")
	# pátio de pedras irregulares
	var pv = C("#cbbf9f")
	for ring in 3:
		var r0 = R * 0.95 * ring / 3.0; var r1 = R * 0.95 * (ring + 1) / 3.0; var sides = 8 + ring * 8
		for i in sides:
			var b0 = i * TAU / sides; var b1 = (i + 1) * TAU / sides
			M.quad(Vector3(cos(b0) * r0, 0.22, sin(b0) * r0), Vector3(cos(b1) * r0, 0.22, sin(b1) * r0), Vector3(cos(b1) * r1, 0.22, sin(b1) * r1), Vector3(cos(b0) * r1, 0.22, sin(b0) * r1), _jit(pv, 0.08))
	# muralha
	for i in N:
		var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % N]
		if i == 0:
			var mid = (a + b) / 2; var dir = (b - a).normalized(); var gl = 1.9
			wall_seg(a, mid - dir * gl, wallH, 1.1, st); wall_seg(mid + dir * gl, b, wallH, 1.1, st)
			gatehouse(mid, -atan2(dir.y, dir.x), wallH, st, roof, fxd)
		else: wall_seg(a, b, wallH, 1.1, st)
	# torres nos cantos
	for i in N:
		var p: Vector2 = pts[i]; var kind: int = tower_kinds[i]; var tr = _rr(1.25, 1.75); var th = wallH + _rr(2.2, 4.2) + L * 0.35
		round_tower(p.x, p.y, tr, th, kind, st, roof if _r() < 0.75 else roof2, gold, fxd)
	# torre de menagem
	keep(keep_pos.x, keep_pos.y, keep_h, keep_kind, st, roof, banner, gold, fxd)
	# casas em enxaimel ao longo da muralha, com as portas viradas para o pátio
	var nh = mini(2 + L, 7); var placed = []
	var tries = 0
	while placed.size() < nh and tries < 60:
		tries += 1
		var a = _rr(0, TAU); var rr = _rr(R * 0.5, R * 0.66); var pos = Vector2(cos(a) * rr, sin(a) * rr)
		if pos.distance_to(keep_pos) < 5.0: continue
		if pos.y > 3.0 and absf(pos.x) < 2.6: continue    # caminho do portão
		var ok = true
		for q in placed:
			if pos.distance_to(q) < 3.9: ok = false; break
		if not ok: continue
		placed.append(pos)
		var w = _rr(2.6, 3.4); var d = _rr(2.3, 2.9); var floors = 2 if (_r() < 0.6 or L >= 3) else 1
		var face = atan2(-pos.x, -pos.y)
		tf_house(w, d, floors, _pick(plasters), roof if _r() < 0.7 else roof2, st, fxd, Vector3(pos.x, 0.22, pos.y), face, _r() < 0.25 + L * 0.05)
	# flores e arbustos no pátio
	for i in 6 + L * 2:
		var a = _rr(0, TAU); var rr = _rr(1.5, R * 0.8); var p = Vector2(cos(a) * rr, sin(a) * rr)
		if p.distance_to(keep_pos) > 3.2: flower_clump(p.x, 0.22, p.y)
	if L >= 3: M.cyl(1.2, 0.22, 1.0, 0.8, 0.7, st, 12, "#5fa6c8")
	var mesh = M.finish()
	# bandeiras: nos pontos mais altos
	var flags: Array = fxd.flags.duplicate()
	fxd.tops.sort_custom(func(p, q): return p.y > q.y)
	for i in mini(2 + int(L / 2), fxd.tops.size()): flags.append(fxd.tops[i])
	_cache["%d_%d" % [k, L]] = {mesh = mesh, fx = {flags = flags, smoke = fxd.smoke, mill = [], crane = []}}

## Versão simplificada para ver de longe (poucos polígonos, mesmas cores e silhueta)
func far_model(k: int, L: int) -> ArrayMesh:
	return M.cached("castlefar_%d_%d" % [k, L], func():
		rs = _seed_for(k)
		var st = C(_pick(STONES)); var roof = C(_pick(ROOFS)); _pick(ROOFS)
		for i in 3: _pick(PLASTERS)
		var N := int(_rr(5, 8.99)); var R := 9.4; var wallH := _rr(2.5, 3.1) + L * 0.12
		var kinds = []
		for i in N: kinds.append(0 if _r() < 0.5 else (1 if _r() < 0.6 else 2))
		var kk = int(_r() * 3) % 3; var kh = _rr(7.5, 9.5) + L * 0.9; var kp = Vector2(_rr(-1.8, 1.8), _rr(-3.6, -2.2))
		var pts = []; var a0 = PI / 2 - PI / N
		for i in N:
			var a = a0 + i * TAU / N + (_rr(-0.12, 0.12) if i > 1 else 0.0); var rr = R * (_rr(0.84, 1.0) if i > 1 else 0.97); pts.append(Vector2(cos(a) * rr, sin(a) * rr))
		M.m_plot(24.0, "#86a861")
		for i in N:
			var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % N]; var mid = (a + b) / 2
			xform(Vector3(mid.x, 0, mid.y), -atan2(b.y - a.y, b.x - a.x), func(): M.box(0, 0, 0, a.distance_to(b), wallH + 0.5, 1.1, st))
			var tr = 1.5; var th = wallH + 3.2 + L * 0.35
			M.cyl(a.x, 0, a.y, tr, th, st, 7)
			if kinds[i] == 0: M.cone(a.x, th, a.y, tr * 1.25, tr * 2.4, roof, 7)
		M.cyl(kp.x, 0, kp.y, 2.4, kh, st, 8); M.cone(kp.x, kh, kp.y, 2.7, 6.5, roof, 8)
		for i in mini(2 + L, 7):
			var a = i * TAU / 7.0 + 0.4; var p = Vector2(cos(a), sin(a)) * R * 0.58
			if p.distance_to(kp) > 4.5: M.box(p.x, 0, p.y, 3, 3.5, 2.6, C("#e3d6b8")); M.roof(p.x, 3.5, p.y, 3.3, 2.9, 2.4, roof))
