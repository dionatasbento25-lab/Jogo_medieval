extends Node
## Modelos 3D em estilo "idle" (low-poly, cores vivas, formas robustas).
## Porte direto de citybuilder/src/models.js: cada modelo é montado uma vez em
## coordenadas locais (base em y=0, centro na origem) e guardado em cache.

class Geo:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()    # x = peça do aldeão, y = marcador (1 roupa, 2 cabelo)
	var uv2 := PackedVector2Array()   # x = sombra aplicada à cor da roupa/cabelo
	var part := 0.0
	var mark := 0.0
	var shade := 1.0

var G := Geo.new()
const TILE := 4.0

func col(x) -> Color:
	if x is Color: return x
	return Color.html(x)
func mixc(a: Color, b: Color, t: float) -> Color:
	t = clampf(t, 0, 1); return Color(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t)
func mulc(a: Color, k: float) -> Color: return Color(a.r * k, a.g * k, a.b * k)

func vert(p: Vector3, c: Color, nn: Vector3) -> void:
	G.v.append(p); G.c.append(c); G.n.append(nn); G.uv.append(Vector2(G.part, G.mark)); G.uv2.append(Vector2(G.shade, 0))
func tri(a: Vector3, b: Vector3, c3: Vector3, c: Color) -> void:
	var nn := (b - a).cross(c3 - a)
	nn = nn.normalized() if nn.length() > 0 else Vector3.UP
	vert(a, c, nn); vert(b, c, nn); vert(c3, c, nn)
func quad(a: Vector3, b: Vector3, c3: Vector3, d: Vector3, c: Color) -> void:
	tri(a, b, c3, c); tri(a, c3, d, c)

func box(x: float, y: float, z: float, w: float, h: float, d: float, cc, top = null) -> void:
	var c := col(cc); var tc := col(top) if top != null else c
	var a := Vector3(x - w / 2, y, z - d / 2); var b := Vector3(x + w / 2, y, z - d / 2); var c3 := Vector3(x + w / 2, y, z + d / 2); var e := Vector3(x - w / 2, y, z + d / 2)
	var A := a + Vector3(0, h, 0); var B := b + Vector3(0, h, 0); var C3 := c3 + Vector3(0, h, 0); var E := e + Vector3(0, h, 0)
	quad(a, b, B, A, c); quad(b, c3, C3, B, c); quad(c3, e, E, C3, c); quad(e, a, A, E, c); quad(A, B, C3, E, tc); quad(a, e, c3, b, c)

func bbox(x: float, y: float, z: float, w: float, h: float, d: float, cc, bev := 0.12, top = null) -> void:
	var c := col(cc); var tc := col(top) if top != null else mixc(c, Color.WHITE, 0.08)
	var b := minf(bev, minf(w / 3, minf(d / 3, h / 3)))
	box(x, y, z, w, h - b, d, c)
	var y1 := y + h - b; var y2 := y + h; var W := w / 2; var D := d / 2
	var P := func(px, py, pz): return Vector3(x + px, py, z + pz)
	quad(P.call(-W + b, y2, -D + b), P.call(-W + b, y2, D - b), P.call(W - b, y2, D - b), P.call(W - b, y2, -D + b), tc)
	quad(P.call(-W, y1, -D), P.call(-W + b, y2, -D + b), P.call(W - b, y2, -D + b), P.call(W, y1, -D), c)
	quad(P.call(W, y1, D), P.call(W - b, y2, D - b), P.call(-W + b, y2, D - b), P.call(-W, y1, D), c)
	quad(P.call(-W, y1, D), P.call(-W + b, y2, D - b), P.call(-W + b, y2, -D + b), P.call(-W, y1, -D), c)
	quad(P.call(W, y1, -D), P.call(W - b, y2, -D + b), P.call(W - b, y2, D - b), P.call(W, y1, D), c)

func cone(x: float, y: float, z: float, r: float, h: float, cc, sides := 8) -> void:
	var c := col(cc); var apex := Vector3(x, y + h, z)
	for j in sides:
		var a := j * TAU / sides; var b := (j + 1) * TAU / sides
		tri(Vector3(x + r * cos(a), y, z + r * sin(a)), Vector3(x + r * cos(b), y, z + r * sin(b)), apex, c)

func cyl(x: float, y: float, z: float, r: float, h: float, cc, sides := 10, top = null) -> void:
	var c := col(cc); var tc := col(top) if top != null else c
	for j in sides:
		var a := j * TAU / sides; var b := (j + 1) * TAU / sides
		var p0 := Vector3(x + r * cos(a), y, z + r * sin(a)); var p1 := Vector3(x + r * cos(b), y, z + r * sin(b))
		quad(p0, p0 + Vector3(0, h, 0), p1 + Vector3(0, h, 0), p1, c)
		tri(Vector3(x, y + h, z), p1 + Vector3(0, h, 0), p0 + Vector3(0, h, 0), tc)

func logm(x: float, y: float, z: float, r: float, ln: float, axis: String, cc, sides := 7) -> void:
	var c := col(cc); var en := mixc(c, col("#e8c27a"), 0.55)
	for j in sides:
		var a := j * TAU / sides; var b := (j + 1) * TAU / sides
		var P := func(t, ang): return Vector3(x + t, y + r * sin(ang), z + r * cos(ang)) if axis == "x" else Vector3(x + r * cos(ang), y + r * sin(ang), z + t)
		quad(P.call(-ln / 2, a), P.call(-ln / 2, b), P.call(ln / 2, b), P.call(ln / 2, a), c)
		var e1 := Vector3(x + ln / 2, y, z) if axis == "x" else Vector3(x, y, z + ln / 2)
		var e0 := Vector3(x - ln / 2, y, z) if axis == "x" else Vector3(x, y, z - ln / 2)
		tri(P.call(ln / 2, a), P.call(ln / 2, b), e1, en); tri(P.call(-ln / 2, b), P.call(-ln / 2, a), e0, en)

func roof(x: float, y: float, z: float, w: float, d: float, h: float, cc, gable = null) -> void:
	var c := col(cc); var gc := col(gable) if gable != null else mixc(c, Color.BLACK, 0.15)
	var a := Vector3(x - w / 2, y, z - d / 2); var b := Vector3(x + w / 2, y, z - d / 2); var c3 := Vector3(x + w / 2, y, z + d / 2); var e := Vector3(x - w / 2, y, z + d / 2)
	var r := Vector3(x, y + h, z - d / 2); var s := Vector3(x, y + h, z + d / 2)
	quad(a, e, s, r, c); quad(b, r, s, c3, c); tri(a, r, b, gc); tri(e, c3, s, gc)

func slab(a: Vector3, b: Vector3, c3: Vector3, d: Vector3, t: float, c: Color, side: Color) -> void:
	var dn := Vector3(0, -t, 0)
	quad(a, b, c3, d, c); quad(a + dn, d + dn, c3 + dn, b + dn, side)
	quad(a, a + dn, b + dn, b, side); quad(b, b + dn, c3 + dn, c3, side); quad(c3, c3 + dn, d + dn, d, side); quad(d, d + dn, a + dn, a, side)

func thick_roof(x: float, y: float, z: float, w: float, d: float, h: float, cc, wall = null, ov := 0.35, t := 0.28) -> void:
	var c := col(cc); var side := mixc(c, Color.BLACK, 0.28); var W := w / 2 + ov; var D := d / 2 + ov; var k := h / (w / 2); var ye := y - ov * k + t
	roof(x, y, z, w, d, h, wall if wall != null else mixc(c, Color.WHITE, 0.5))
	slab(Vector3(x - W, ye, z - D), Vector3(x - W, ye, z + D), Vector3(x, y + h + t, z + D), Vector3(x, y + h + t, z - D), t, c, side)
	slab(Vector3(x, y + h + t, z - D), Vector3(x, y + h + t, z + D), Vector3(x + W, ye, z + D), Vector3(x + W, ye, z - D), t, c, side)
	box(x, y + h + t * 0.6, z, 0.3, 0.3, 2 * D + 0.1, mixc(c, Color.BLACK, 0.12))

func pyramid(x: float, y: float, z: float, w: float, d: float, h: float, cc) -> void:
	var c := col(cc); var a := Vector3(x - w / 2, y, z - d / 2); var b := Vector3(x + w / 2, y, z - d / 2); var c3 := Vector3(x + w / 2, y, z + d / 2); var e := Vector3(x - w / 2, y, z + d / 2); var t := Vector3(x, y + h, z)
	tri(a, t, b, c); tri(b, t, c3, c); tri(c3, t, e, c); tri(e, t, a, c)

func ball(x: float, y: float, z: float, r: float, cc, sy := 1.0, rings := 4, sides := 8, shade := true) -> void:
	var c := col(cc)
	for j in rings:
		var a0 := -PI / 2 + j * PI / rings; var a1 := -PI / 2 + (j + 1) * PI / rings
		var occ: float = (0.82 + 0.22 * float(j) / max(1, rings - 1)) if shade else 1.0
		for i in sides:
			var t0 := i * TAU / sides; var t1 := (i + 1) * TAU / sides
			var Pt := func(a, t): return Vector3(x + r * cos(a) * cos(t), y + r * sy * sin(a), z + r * cos(a) * sin(t))
			quad(Pt.call(a0, t0), Pt.call(a1, t0), Pt.call(a1, t1), Pt.call(a0, t1), mulc(c, occ))

func bush(x: float, y: float, z: float, r: float, cc = "#4f9a3c") -> void:
	ball(x, y + r * 0.6, z, r, cc, 0.8, 3, 7); ball(x + r * 0.5, y + r * 0.45, z + r * 0.3, r * 0.6, mixc(col(cc), col("#a6d16a"), 0.25), 0.8, 3, 6)
func flowers(x: float, y: float, z: float, w: float, d: float) -> void:
	box(x, y, z, w, 0.35, d, "#7a5232"); var cs := ["#ff5d73", "#ffd23f", "#ffffff", "#b56cff"]; var n := maxi(2, int(round(w / 0.35)))
	for i in n:
		ball(x - w / 2 + 0.2 + i * (w - 0.4) / max(1, n - 1), y + 0.42, z, 0.13, cs[i % 4], 1, 2, 5, false)
func _posts(x0: float, z0: float, x1: float, z1: float, y: float) -> void:
	var L := Vector2(x1 - x0, z1 - z0).length(); var n := maxi(1, int(round(L / 1.3)))
	for i in n + 1:
		var t := float(i) / n; box(x0 + (x1 - x0) * t, y, z0 + (z1 - z0) * t, 0.18, 0.75, 0.18, "#9b6b3f")
	var cx := (x0 + x1) / 2; var cz := (z0 + z1) / 2
	if absf(x1 - x0) > absf(z1 - z0):
		box(cx, y + 0.45, cz, L, 0.1, 0.08, "#c08a55"); box(cx, y + 0.2, cz, L, 0.1, 0.08, "#c08a55")
	else:
		box(cx, y + 0.45, cz, 0.08, 0.1, L, "#c08a55"); box(cx, y + 0.2, cz, 0.08, 0.1, L, "#c08a55")
func fence(x: float, z: float, w: float, d: float, y := 0.0, gap := 0.0) -> void:
	var W := w / 2; var D := d / 2
	_posts(-W + x, -D + z, W + x, -D + z, y); _posts(-W + x, -D + z, -W + x, D + z, y); _posts(W + x, -D + z, W + x, D + z, y)
	if gap > 0: _posts(-W + x, D + z, x - gap / 2, D + z, y); _posts(x + gap / 2, D + z, W + x, D + z, y)
	else: _posts(-W + x, D + z, W + x, D + z, y)
func barrel(x: float, y: float, z: float, r := 0.32, h := 0.75) -> void:
	cyl(x, y, z, r, h, "#a5693a", 8, "#c48a52"); cyl(x, y + 0.12, z, r + 0.02, 0.08, "#5b5b62", 8); cyl(x, y + h - 0.2, z, r + 0.02, 0.08, "#5b5b62", 8)
func crate(x: float, y: float, z: float, s := 0.6, cc = "#c28a4d") -> void:
	box(x, y, z, s, s, s, cc); box(x, y + s * 0.45, z, s + 0.02, s * 0.1, s + 0.02, mixc(col(cc), Color.BLACK, 0.25))
func sack(x: float, y: float, z: float, cc = "#e3cf9d") -> void:
	ball(x, y + 0.28, z, 0.3, cc, 1.1, 3, 6); box(x, y + 0.55, z, 0.18, 0.12, 0.18, mixc(col(cc), Color.BLACK, 0.2))
func window_f(x: float, y: float, z: float, face: String, w := 0.6, h := 0.7) -> void:
	var fr := "#f6efe0"; var gl := "#36506b"; var t := 0.08; var s := 1.0 if face[1] == "+" else -1.0
	if face[0] == "z":
		box(x, y, z + s * 0.02, w + 0.16, h + 0.16, t, fr); box(x, y + 0.08, z + s * 0.07, w, h, t, gl); box(x, y + 0.08 + h / 2 - 0.04, z + s * 0.1, w, 0.07, t, fr); box(x, y - 0.06, z + s * 0.12, w + 0.3, 0.12, 0.22, fr)
	else:
		box(x + s * 0.02, y, z, t, h + 0.16, w + 0.16, fr); box(x + s * 0.07, y + 0.08, z, t, h, w, gl); box(x + s * 0.1, y + 0.08 + h / 2 - 0.04, z, t, 0.07, w, fr); box(x + s * 0.12, y - 0.06, z, 0.22, 0.12, w + 0.3, fr)
func door(x: float, y: float, z: float, w := 0.9, h := 1.5, cc = "#7b4a2a") -> void:
	box(x, y, z, w + 0.2, h + 0.12, 0.12, "#5a3a22"); box(x, y, z + 0.05, w, h, 0.12, cc); box(x + w * 0.3, y + h * 0.45, z + 0.13, 0.1, 0.1, 0.06, "#e2b64b")
func flagpole(x: float, y: float, z: float, h: float) -> void:
	cyl(x, y, z, 0.07, h, "#6b5137", 5); ball(x, y + h + 0.05, z, 0.12, "#ffd34d", 1, 2, 6, false)

# ---------- construções ----------
const PAL := {wall = "#f3e3c3", wall2 = "#e9d2a8", timber = "#8a5a36", roofR = "#d9553f", roofO = "#e98a3a", roofB = "#4a78c4", roofG = "#4f9a55", stone = "#b9b6ad", stone2 = "#9c9a93", stoneD = "#7d7c78", wood = "#b07a48", woodD = "#7a5232", gold = "#f3c43c", path = "#d8c39a"}

func m_house(L: int) -> void:
	var sz := 4.6 if L >= 3 else 4.0; var wh := 2.2 if L >= 3 else 2.5; var b5 := 1.0 if L >= 5 else 0.0
	if L >= 5: bbox(0, 0, 0, sz + 0.3, 1.1, 3.7, PAL.stone, 0.1)
	bbox(0, b5, -0.2, sz, wh, 3.4, PAL.wall, 0.08)
	for s in [-1, 1]: box(s * (sz / 2 - 0.05), 0, 1.5, 0.22, wh, 0.16, PAL.timber)
	box(0, wh - 0.18, 1.52, sz, 0.2, 0.16, PAL.timber)
	door(-0.6, b5, 1.45); window_f(0.9, b5 + 0.9, 1.47, "z+"); window_f(sz / 2, b5 + 0.9, -0.2, "x+", 0.55, 0.6); window_f(-sz / 2, b5 + 0.9, -0.2, "x-", 0.55, 0.6)
	var top := b5 + wh
	if L >= 3:
		bbox(0, top, -0.2, sz + 0.35, 1.9, 3.7, PAL.wall2, 0.06)
		for s in [-1, 0, 1]: box(s * (sz / 2), top, 1.66, 0.2, 1.9, 0.14, PAL.timber)
		window_f(-0.9, top + 0.6, 1.7, "z+", 0.55, 0.6); window_f(0.9, top + 0.6, 1.7, "z+", 0.55, 0.6); top += 1.9
	thick_roof(0, top, -0.2, sz + 0.2, 3.6, 2.3 if L >= 3 else 2.0, PAL.roofB if L >= 4 else PAL.roofR, PAL.wall2)
	if L >= 2:
		box(1.1, top + 0.4, -1.0, 0.6, 1.9, 0.6, PAL.stone2); box(1.1, top + 2.2, -1.0, 0.75, 0.18, 0.75, PAL.stoneD); flowers(0.9, b5 + 0.35, 1.85, 1.1, 0.3)
		fence(0, 0.2, 7.4, 7.2, 0, 1.6)
	if L >= 4:
		bbox(-3.0, 0, -1.6, 1.6, 1.7, 1.8, PAL.wall, 0.06); thick_roof(-3.0, 1.7, -1.6, 1.6, 1.8, 0.9, PAL.roofB, PAL.wall2, 0.2, 0.18); bush(2.8, 0, 2.6, 0.6)
	if L >= 5: flagpole(2.9, 0, -2.9, 3.6)
	bush(-2.6, 0, 2.7, 0.5)

func m_farm(L: int) -> void:
	var rows := 7 if L >= 3 else 5; var fw := 13.0 if L >= 3 else 9.0; var x0 := -2.0 if L >= 3 else -3.5
	for r in rows:
		var z := -6 + r * 1.25; box(x0, 0, z, fw, 0.18, 0.9, "#8d6239")
		var n := int(round(fw / 0.9))
		for k in n:
			var x := x0 - fw / 2 + 0.45 + k * 0.9; var ht := 0.55 + _h2(r * 7 + k, L) * 0.25
			box(x, 0.18, z, 0.5, ht, 0.5, "#d9b23d" if (r + k) % 3 == 0 else "#e8c351", "#f4d56b")
	var bx := 4.6 if L >= 3 else 4.2; var bz := 4.4 if L >= 3 else 2.2
	bbox(bx, 0, bz, 3.6, 2.4, 3.4, "#c8443a", 0.1)
	for s in [-1, 1]: box(bx + s * 1.0, 0, bz + 1.71, 0.14, 2.4, 0.1, "#f6efe0")
	box(bx, 2.3, bz + 1.72, 3.6, 0.14, 0.1, "#f6efe0"); box(bx, 0, bz + 1.72, 1.4, 1.7, 0.1, "#8f2e27"); box(bx, 0, bz + 1.78, 1.4, 0.12, 0.1, "#f6efe0")
	box(bx, 0, bz + 1.8, 0.1, 1.7, 0.08, "#f6efe0")
	thick_roof(bx, 2.4, bz, 3.6, 3.4, 1.6, "#6b4a3a", "#c8443a", 0.25, 0.2)
	if L >= 2:
		var mx := -5.6; var mz := 4.6
		cyl(mx, 0, mz, 1.25, 0.4, PAL.stone2, 10); cyl(mx, 0.4, mz, 1.05, 3.8, "#f1e6cf", 10); cone(mx, 4.2, mz, 1.35, 1.6, PAL.roofR, 10); door(mx, 0.4, mz + 1.0, 0.6, 1.0)
	if L >= 3:
		for p in [[6.4, -1.2], [5.2, -2.6]]: cyl(p[0], 0, p[1], 0.6, 0.8, "#e8c351", 8, "#f4d56b")
	if L >= 4: cyl(-1.8, 0, 5.6, 1, 3.4, "#d9d4c9", 10); cone(-1.8, 3.4, 5.6, 1.15, 1, "#4a78c4", 10)
	if L >= 5:
		box(-6.5, 0, -6.6, 0.12, 1.8, 0.12, PAL.woodD); box(-6.5, 1.2, -6.6, 1.1, 0.12, 0.12, PAL.woodD); ball(-6.5, 1.95, -6.6, 0.28, "#e3cf9d"); cone(-6.5, 2.1, -6.6, 0.45, 0.4, "#d9b23d")
	fence(0, 0, 15.4, 15.4, 0, 2.5)

func m_lumber(L: int) -> void:
	var cx := -1.2; var cz := -1.4
	for i in 5:
		var cc := "#9a643a" if i % 2 else "#a8703f"
		logm(cx, 0.25 + i * 0.45, cz - 1.5, 0.24, 4.4, "x", cc); logm(cx, 0.25 + i * 0.45, cz + 1.5, 0.24, 4.4, "x", cc)
		logm(cx - 2.0, 0.25 + i * 0.45, cz, 0.24, 3.4, "z", "#93603a"); logm(cx + 2.0, 0.25 + i * 0.45, cz, 0.24, 3.4, "z", "#93603a")
	box(cx, 0, cz, 3.8, 2.2, 2.8, "#7b5233"); door(cx, 0, cz + 1.55, 0.8, 1.4, "#5a3a22"); window_f(cx + 1.2, 1.0, cz + 1.62, "z+", 0.5, 0.5)
	thick_roof(cx, 2.3, cz, 4.5, 3.4, 1.6, PAL.roofG, "#93603a", 0.3, 0.25); box(cx + 1.3, 2.6, cz - 0.6, 0.5, 1.4, 0.5, PAL.stone2)
	var n := 3 if L >= 2 else 2
	for r in n:
		for k in n + 1 - r: logm(3.0, 0.28 + r * 0.48, -2.6 + k * 0.52 + r * 0.26, 0.25, 2.6, "x", "#a8703f")
	cyl(2.6, 0, 2.4, 0.45, 0.6, "#8b5a33", 8, "#e0b071"); box(2.75, 0.6, 2.35, 0.08, 0.8, 0.08, "#6b4a2e"); box(2.75, 1.2, 2.5, 0.07, 0.3, 0.35, "#c9ccd1")
	if L >= 3:
		for s in [-1, 1]: box(-3.6, 0, 2.4 + s * 0.5, 0.15, 0.8, 0.15, PAL.woodD)
		logm(-3.6, 0.85, 2.4, 0.22, 1.8, "z", "#a8703f"); box(-3.6, 0.85, 1.8, 0.02, 0.9, 0.3, "#c9ccd1")
	if L >= 4:
		box(1.0, 0.5, 4.0, 2.0, 0.5, 1.2, PAL.wood)
		for s in [-1, 1]: logm(1.0 + s * 0.8, 0.4, 4.0, 0.4, 0.12, "z", "#6b4a2e", 8)
		box(-0.4, 0.7, 4.0, 1.2, 0.08, 0.08, PAL.woodD)
		for i in 3: logm(1.0, 1.15, 3.7 + i * 0.32, 0.15, 1.8, "x", "#c08a55")
	if L >= 5:
		for i in 4: box(4.6, i * 0.3, 1.2, 1.8, 0.25, 1.2, "#d9a066" if i % 2 else "#c98f56")
	bush(-4.6, 0, -4.4, 0.7, "#3f8a3a"); bush(4.6, 0, -4.6, 0.55, "#3f8a3a")

func m_quarry(L: int) -> void:
	ball(-2.8, 0, -3.0, 2.0, PAL.stone2, 0.75, 3, 7); ball(-1.0, 0, -3.8, 1.4, PAL.stone, 0.8, 3, 6); ball(-4.2, 0, -1.6, 1.1, PAL.stoneD, 0.8, 3, 6)
	bbox(2.4, 0, -2.6, 2.8, 1.9, 2.4, "#d8cdb4", 0.08); door(2.4, 0, -1.35, 0.8, 1.3, "#5a3a22"); thick_roof(2.4, 1.9, -2.6, 2.8, 2.4, 1.1, PAL.roofB, "#d8cdb4", 0.25, 0.2)
	var piles := 3 if L >= 3 else 2
	for p in piles:
		var px := -2.4 + p * 2.6; var pz := 2.6
		for r in 2:
			for k in 2 - r: bbox(px + k * 0.75 - 0.37 + r * 0.37, r * 0.6, pz, 0.7, 0.6, 0.7, PAL.stone if p % 2 else "#cfccc4", 0.08)
	if L >= 2: box(3.8, 0, 2.2, 0.3, 4.2, 0.3, PAL.woodD); box(3.8, 0, 2.2, 1.4, 0.3, 1.4, PAL.wood)
	if L >= 4:
		box(0, 0, 4.6, 5, 0.12, 0.6, "#8b7a66")
		for i in 5: box(-2 + i, 0.12, 4.6, 0.15, 0.08, 0.8, PAL.woodD)
	if L >= 5: bbox(-4.4, 0, 2.6, 1.4, 2.2, 1.4, PAL.stone, 0.1); ball(-4.4, 2.4, 2.6, 0.4, PAL.gold, 1, 3, 6)

func m_mine(L: int) -> void:
	ball(0, 0, -1.6, 4.2, "#8f877a", 0.7, 4, 9); ball(-2.8, 0, -2.6, 2.4, "#a39a8a", 0.8, 3, 7); ball(2.9, 0, -2.2, 2.6, "#7d766b", 0.75, 3, 7)
	box(0, 0, 1.2, 2.2, 2.3, 1.0, "#1d1a18")
	for s in [-1, 1]: box(s * 1.15, 0, 1.75, 0.3, 2.4, 0.3, PAL.woodD)
	box(0, 2.3, 1.75, 2.7, 0.35, 0.36, PAL.woodD)
	for i in 5: box(0, 0.05, 2.4 + i * 0.8, 1.4, 0.1, 0.22, PAL.woodD)
	for s in [-1, 1]: box(s * 0.5, 0.15, 4.0, 0.08, 0.08, 4.4, "#8c8f96")
	box(0, 0.35, 3.6, 1.3, 0.8, 1.6, "#5b5f66"); box(0, 1.0, 3.6, 1.36, 0.1, 1.66, "#3e4147")
	for k in 5: ball(-0.35 + k * 0.18, 1.1, 3.3 + (k % 3) * 0.3, 0.22, PAL.gold, 1, 2, 6, false)
	for s in [-1, 1]:
		for t in [-1, 1]: cyl(s * 0.62, 0.18, 3.6 + t * 0.5, 0.2, 0.1, "#2e3036", 6)
	if L >= 2: box(1.6, 0, 2.2, 0.12, 1.8, 0.12, PAL.woodD); box(1.6, 1.6, 2.35, 0.35, 0.4, 0.35, "#ffcf5a")
	if L >= 3:
		box(-3.2, 0, 3.0, 1.0, 0.8, 1.0, "#5b5f66")
		for k in 3: ball(-3.4 + k * 0.2, 0.85, 3.0, 0.2, PAL.gold, 1, 2, 6, false)
	if L >= 4: bbox(3.4, 0, 3.2, 2, 1.6, 1.8, "#d8cdb4", 0.06); thick_roof(3.4, 1.6, 3.2, 2, 1.8, 0.9, PAL.roofO, "#d8cdb4", 0.2, 0.18)
	if L >= 5: flagpole(-1.8, 2.6, -0.4, 2.4)

func awning(x: float, y: float, z: float, w: float, d: float, c1: Color, c2: Color) -> void:
	var n := 6
	for i in n:
		var xx := x - w / 2 + (i + 0.5) * w / n; var cc := c1 if i % 2 else c2
		quad(Vector3(xx - w / n / 2, y + 0.5, z - d / 2), Vector3(xx - w / n / 2, y, z + d / 2), Vector3(xx + w / n / 2, y, z + d / 2), Vector3(xx + w / n / 2, y + 0.5, z - d / 2), cc)
		box(xx, y - 0.28, z + d / 2, w / n, 0.3, 0.05, cc)
func stall(x: float, z: float, c1: String, goods: Array) -> void:
	for s in [-1, 1]:
		for t in [-1, 1]: box(x + s * 1.1, 0, z + t * 0.7, 0.14, 1.9, 0.14, PAL.woodD)
	box(x, 0.75, z + 0.3, 2.3, 0.18, 0.9, PAL.wood); box(x, 0, z + 0.3, 2.2, 0.75, 0.85, "#9a643a")
	awning(x, 1.9, z, 2.6, 1.9, col(c1), col("#f6efe0"))
	for k in 4: ball(x - 0.75 + k * 0.5, 1.05, z + 0.4, 0.18, goods[k % goods.size()], 1, 2, 6, false)
func m_market(L: int) -> void:
	box(0, 0, 0, 11.4, 0.12, 11.4, "#d9c7a0")
	for i in 4:
		for j in 4:
			if (i + j) % 2: box(-4.3 + i * 2.86, 0.12, -4.3 + j * 2.86, 2.7, 0.04, 2.7, "#cbb98f")
	stall(-2.8, -2.6, "#d9553f", ["#ff5d4f", "#ffd23f", "#7cc35a"]); stall(2.8, -2.6, "#4a78c4", ["#e98a3a", "#b56cff", "#ffffff"])
	if L >= 2: stall(-2.8, 2.4, "#4f9a55", ["#d9b23d", "#a07a4f", "#ff5d4f"])
	if L >= 3: stall(2.8, 2.4, "#8a5bc2", ["#f3c43c", "#7cc35a", "#e98a3a"])
	cyl(0, 0.12, 0, 1.1, 0.5, PAL.stone, 10, "#5fb0d6"); cyl(0, 0.5, 0, 0.22, 1.0, PAL.stone, 8); cyl(0, 1.4, 0, 0.5, 0.18, PAL.stone, 8, "#5fb0d6")
	for k in (6 if L >= 4 else 3): crate(-5 + k * 0.8, 0.12, 5, 0.55, "#c28a4d" if k % 2 else "#a5733f")
	if L >= 5: flagpole(-5, 0.12, -5, 4); flagpole(5, 0.12, -5, 4)
	if L >= 2: sack(4.8, 0.12, 4.8)

func m_tavern(L: int) -> void:
	bbox(0, 0, -0.8, 6.2, 2.4, 5, PAL.stone, 0.08); door(0, 0, 1.72, 1.1, 1.7, "#7b4a2a"); window_f(-1.9, 0.9, 1.75, "z+", 0.7, 0.7); window_f(1.9, 0.9, 1.75, "z+", 0.7, 0.7)
	bbox(0, 2.4, -0.8, 6.6, 2.0, 5.4, PAL.wall, 0.06)
	for s in [-1, -0.33, 0.33, 1]: box(s * 3.2, 2.4, 1.92, 0.2, 2.0, 0.14, PAL.timber)
	box(0, 2.4, 1.94, 6.6, 0.18, 0.14, PAL.timber); window_f(-1.6, 2.9, 1.98, "z+", 0.6, 0.6); window_f(1.6, 2.9, 1.98, "z+", 0.6, 0.6)
	thick_roof(0, 4.4, -0.8, 6.8, 5.6, 2.4, PAL.roofO, PAL.wall2, 0.35, 0.28); box(-2, 5.3, -2, 0.7, 2.2, 0.7, PAL.stone2)
	box(1.2, 2.6, 2.6, 0.1, 0.1, 1.4, PAL.woodD); box(1.2, 1.7, 3.2, 0.08, 0.8, 0.9, "#e3cf9d"); ball(1.2, 2.1, 3.26, 0.18, "#c8443a", 1, 2, 5, false)
	barrel(-3.6, 0, 2.4); barrel(-3.2, 0, 3.2)
	if L >= 2: barrel(-3.6, 0.75, 2.8)
	if L >= 3:
		box(2.6, 0, 4.2, 1.8, 0.85, 0.9, PAL.wood)
		for s in [-1, 1]: box(2.6, 0, 4.2 + s * 0.9, 1.8, 0.45, 0.3, PAL.woodD)
	if L >= 4: bbox(4.2, 0, -1.8, 2, 2, 2.4, PAL.wall, 0.06); thick_roof(4.2, 2, -1.8, 2, 2.4, 1, PAL.roofO, PAL.wall2, 0.2, 0.18)
	if L >= 5: flagpole(-4.4, 0, -3.6, 4.4)

func m_warehouse(L: int) -> void:
	var w := 8.0 if L >= 3 else 7.0; var d := 6.2 if L >= 3 else 5.4
	bbox(0, 0, -0.8, w, 3.2, d, "#a8703f", 0.1)
	for i in 5: box(-w / 2 + i * w / 4, 0, -0.8 + d / 2 + 0.02, 0.2, 3.2, 0.1, "#7a5232")
	box(0, 1.6, -0.8 + d / 2 + 0.03, w, 0.16, 0.1, "#7a5232"); box(0, 0, -0.8 + d / 2 + 0.06, 2.2, 2.4, 0.1, "#6b4228"); box(0, 1.2, -0.8 + d / 2 + 0.12, 2.2, 0.12, 0.06, "#3a2a1c")
	thick_roof(0, 3.2, -0.8, w, d, 2.2, "#7a5f8a", "#a8703f", 0.35, 0.28)
	for k in 3 + L: crate(-3.4 + (k % 5) * 0.75, 0.6 if k > 4 else 0.0, 3.4 + (k % 2) * 0.1, 0.6, "#c28a4d" if k % 2 else "#d8a868")
	for k in mini(L, 4): sack(2.4 + k * 0.65, 0, 3.6)
	if L >= 4: barrel(4.6, 0, 1.8); barrel(4.6, 0, 2.6)

func m_tower(L: int) -> void:
	var h := 6.5 + L * 0.9
	bbox(0, 0, 0, 4.2, 1.0, 4.2, PAL.stoneD, 0.12); cyl(0, 0.9, 0, 1.8, h, PAL.stone, 10)
	for i in 10:
		var a := i / 10.0 * TAU; box(cos(a) * 1.9, h + 0.9, sin(a) * 1.9, 0.55, 0.6, 0.55, PAL.stone2)
	cyl(0, h + 0.9, 0, 2.05, 0.35, PAL.stone2, 10); cone(0, h + 1.3, 0, 2.15, 2.8, "#d9a32a" if L >= 4 else PAL.roofB, 10)
	door(0, 0.9, 1.75, 0.8, 1.3); window_f(0, h * 0.6, 1.82, "z+", 0.4, 0.7); window_f(1.82, h * 0.4, 0, "x+", 0.4, 0.7)

func m_well(_L: int) -> void:
	cyl(0, 0, 0, 1.0, 0.9, PAL.stone, 10, "#3c6f8f"); cyl(0, 0.9, 0, 1.05, 0.15, PAL.stone2, 10)
	for s in [-1, 1]: box(s * 0.85, 0.9, 0, 0.16, 1.6, 0.16, PAL.woodD)
	box(0, 2.35, 0, 2.0, 0.12, 0.12, PAL.woodD); roof(0, 2.4, 0, 2.3, 1.5, 0.8, PAL.roofR); box(0, 1.6, 0, 0.3, 0.35, 0.3, "#8b5a33"); flowers(0, 0, 1.55, 1.4, 0.3)

func m_castle(L: int) -> void:
	var R := 9.5; var wallH := 4.2 + L * 0.25; var tH := 6.5 + L * 0.5
	bbox(0, 0, 0, 23.4, 0.6, 23.4, PAL.stoneD, 0.2)
	for s in [-1, 1]: bbox(0, 0.6, s * R, 2 * R, wallH, 1.6, PAL.stone, 0.08); bbox(s * R, 0.6, 0, 1.6, wallH, 2 * R, PAL.stone, 0.08)
	for i in range(-4, 5):
		for s in [-1, 1]: box(i * 2.1, 0.6 + wallH, s * R, 0.9, 0.75, 1.7, PAL.stone2); box(s * R, 0.6 + wallH, i * 2.1, 1.7, 0.75, 0.9, PAL.stone2)
	for a in [-1, 1]:
		for b in [-1, 1]:
			cyl(a * R, 0.6, b * R, 2.0, tH, PAL.stone, 10)
			for i in 8:
				var q := i / 8.0 * TAU; box(a * R + cos(q) * 2.1, 0.6 + tH, b * R + sin(q) * 2.1, 0.6, 0.6, 0.6, PAL.stone2)
			cone(a * R, 0.6 + tH + 0.3, b * R, 2.4, 3.4, "#d9a32a" if L >= 5 else PAL.roofB, 10); window_f(a * R, 0.6 + tH * 0.6, b * R + 2.02, "z+", 0.35, 0.6)
	bbox(0, 0.6, R + 0.6, 5.2, wallH + 1.2, 2.4, PAL.stone2, 0.1); box(0, 0.6, R + 1.85, 2.4, 3.0, 0.2, "#3a2a1c")
	for i in 4: box(-0.9 + i * 0.6, 0.6, R + 1.95, 0.1, 3.0, 0.08, "#2a2a2e")
	for s in [-1, 1]: cyl(s * 2.6, 0.6, R + 0.6, 1.1, wallH + 2.4, PAL.stone, 8); cone(s * 2.6, 0.6 + wallH + 2.4, R + 0.6, 1.4, 2, PAL.roofR, 8)
	var kH := 7.5 + L * 1.1
	bbox(0, 0.6, -1.2, 8, kH, 7, "#d9d3c4", 0.15)
	for i in range(-3, 4): box(i * 1.1, 0.6 + kH, 2.3, 0.7, 0.7, 0.7, PAL.stone2); box(i * 1.1, 0.6 + kH, -4.7, 0.7, 0.7, 0.7, PAL.stone2)
	for i in range(-2, 3): box(4, 0.6 + kH, -1.2 + i * 1.1, 0.7, 0.7, 0.7, PAL.stone2); box(-4, 0.6 + kH, -1.2 + i * 1.1, 0.7, 0.7, 0.7, PAL.stone2)
	thick_roof(0, 0.6 + kH + 0.7, -1.2, 6.8, 5.8, 3.2, "#d9a32a" if L >= 5 else PAL.roofR, "#d9d3c4", 0.3, 0.3)
	door(0, 0.6, 2.32, 1.6, 2.4, "#7b4a2a")
	for s in [-1, 1]: window_f(s * 2.4, 0.6 + kH * 0.55, 2.32, "z+", 0.6, 1.0); window_f(s * 2.4, 0.6 + kH * 0.25, 2.32, "z+", 0.6, 1.0)
	for s in [-1, 1]:
		box(s * 1.3, 0.6 + kH * 0.45, 2.34, 0.9, 2.2, 0.08, "#2f5fb8"); pyramid(s * 1.3, 0.6 + kH * 0.45 - 0.01, 2.34, 0.9, 0.09, -0.5, "#2f5fb8"); box(s * 1.3, 0.6 + kH * 0.45 + 1.4, 2.36, 0.4, 0.4, 0.06, "#ffd34d")
	if L >= 2: cyl(3.4, 0.6 + kH, -3.8, 1.0, 3.2, PAL.stone, 8); cone(3.4, 0.6 + kH + 3.2, -3.8, 1.3, 2.2, PAL.roofB, 8)
	if L >= 3: bush(-6, 0.6, 5, 0.9); bush(6, 0.6, 5.2, 0.8); bush(-6, 0.6, -6, 0.8)
	if L >= 4: bbox(-5.4, 0.6, -5.6, 4, 2.4, 3.2, PAL.wall, 0.06); thick_roof(-5.4, 3, -5.6, 4, 3.2, 1.4, PAL.roofR, PAL.wall2, 0.25, 0.2)

func m_site(S: float) -> void:
	var s := S / 2 - 0.4
	for a in [-1, 1]:
		for b in [-1, 1]: box(a * s, 0, b * s, 0.22, 1.0, 0.22, "#c08a55"); box(a * s, 0.9, b * s, 0.3, 0.14, 0.3, "#ff8a3d")
func m_scaffold(S: float, h: float) -> void:
	var s := S / 2 - 0.1
	for a in [-1, 0, 1]:
		for b in [-1, 1]: box(a * s, 0, b * s, 0.16, h, 0.16, "#c9925a"); box(b * s, 0, a * s, 0.16, h, 0.16, "#c9925a")
	var y := 1.4
	while y < h:
		for b in [-1, 1]: box(0, y, b * s, 2 * s, 0.12, 0.5, "#a8743f"); box(b * s, y, 0, 0.5, 0.12, 2 * s, "#a8743f")
		y += 1.6
func m_plot(S: float, cc: String) -> void:
	bbox(0, -0.05, 0, S - 0.2, 0.25, S - 0.2, cc, 0.12, cc)

func _h2(x: float, z: float) -> float:
	var n := sin(x * 127.1 + z * 311.7) * 43758.5453
	return n - floor(n)

const TYPES := {
	castle = {name = "Castelo", icon = "🏰", size = 6, max = 5, time = 5.0, plot = "#b8c08a"},
	house = {name = "Casa", icon = "🏠", size = 2, max = 5, time = 6.0, plot = "#8fcf68"},
	farm = {name = "Fazenda", icon = "🌾", size = 4, max = 5, time = 8.0, plot = "#b99a63"},
	lumber = {name = "Lenhador", icon = "🪓", size = 3, max = 5, time = 7.0, plot = "#86bd5e"},
	quarry = {name = "Pedreira", icon = "⛏️", size = 3, max = 5, time = 10.0, plot = "#bdb59f"},
	mine = {name = "Mina de Ouro", icon = "💰", size = 3, max = 5, time = 14.0, plot = "#a99d86"},
	market = {name = "Mercado", icon = "🏪", size = 3, max = 5, time = 14.0, plot = "#c9b78e"},
	tavern = {name = "Taverna", icon = "🍺", size = 3, max = 5, time = 16.0, plot = "#8fcf68"},
	warehouse = {name = "Armazém", icon = "📦", size = 3, max = 5, time = 10.0, plot = "#a9c27a"},
	tower = {name = "Torre de Vigia", icon = "🗼", size = 2, max = 5, time = 14.0, plot = "#a9b08e"},
	well = {name = "Poço", icon = "⛲", size = 1, max = 3, time = 4.0, plot = "#8fcf68"},
}
const HEIGHT := {castle = 20, house = 8, farm = 7, lumber = 5, quarry = 5, mine = 5, market = 4, tavern = 8, warehouse = 6, tower = 12, well = 3}

func _model_fn(t: String, L: int) -> void:
	match t:
		"castle": m_castle(L)
		"house": m_house(L)
		"farm": m_farm(L)
		"lumber": m_lumber(L)
		"quarry": m_quarry(L)
		"mine": m_mine(L)
		"market": m_market(L)
		"tavern": m_tavern(L)
		"warehouse": m_warehouse(L)
		"tower": m_tower(L)
		"well": m_well(L)

var _cache := {}
func begin() -> void:
	G = Geo.new()
func finish() -> ArrayMesh:
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = G.v; arr[Mesh.ARRAY_NORMAL] = G.n; arr[Mesh.ARRAY_COLOR] = G.c
	arr[Mesh.ARRAY_TEX_UV] = G.uv; arr[Mesh.ARRAY_TEX_UV2] = G.uv2
	var m := ArrayMesh.new(); m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr); G = Geo.new(); return m

## Modelo completo (lote + construção) de um tipo e nível.
func model(t: String, L: int) -> ArrayMesh:
	var k := t + str(L)
	if _cache.has(k): return _cache[k]
	begin(); m_plot(TYPES[t].size * TILE, TYPES[t].plot); _model_fn(t, L)
	var m := finish(); _cache[k] = m; return m
func cached(key: String, fn: Callable) -> ArrayMesh:
	if _cache.has(key): return _cache[key]
	begin(); fn.call(); var m := finish(); _cache[key] = m; return m
func plot(t: String) -> ArrayMesh: return cached("plot" + t, func(): m_plot(TYPES[t].size * TILE, TYPES[t].plot))
func site(t: String) -> ArrayMesh: return cached("site" + t, func(): m_site(TYPES[t].size * TILE))
func scaffold(t: String, up := false) -> ArrayMesh:
	var n: float = TYPES[t].size * TILE
	return cached("scaf" + t + str(up), func(): m_scaffold(n - (0.2 if up else 0.6), HEIGHT[t] * (0.9 if up else 0.75)))
func foundation(t: String) -> ArrayMesh:
	var n: float = TYPES[t].size * TILE
	return cached("found" + t, func(): box(0, 0, 0, n - 0.3, 1, n - 0.3, "#8a9a5a"))

# ---------- peças animadas ----------
func blade() -> ArrayMesh:
	return cached("blade", func():
		cyl(0, -0.2, 0, 0.3, 0.4, "#6b5137", 8)
		for k in 4:
			var a := k * PI / 2; var c := cos(a); var s := sin(a)
			var P := func(r, w): return Vector3(c * r - s * w, s * r + c * w, 0)
			quad(P.call(0.3, -0.12), P.call(3.2, -0.12), P.call(3.2, 0.12), P.call(0.3, 0.12), col("#6b5137"))
			quad(P.call(0.9, 0.12), P.call(3.1, 0.12), P.call(3.1, 0.85), P.call(0.9, 0.85), col("#f6efe0" if k % 2 else "#e6dcc4")))
func flag(c := Color("#2f5fb8")) -> ArrayMesh: return cached("flag" + c.to_html(false), func(): box(0.65, 0, 0, 1.3, 0.75, 0.05, c); box(0.7, 0.22, 0.03, 0.36, 0.32, 0.03, "#ffd34d"))
func puff() -> ArrayMesh: return cached("puff", func(): ball(0, 0, 0, 0.5, "#f4f1ea", 1, 3, 6, false))
func crane_arm() -> ArrayMesh: return cached("crane", func(): box(1.4, 0, 0, 3.6, 0.22, 0.22, "#7a5232"); box(3, -0.9, 0, 0.05, 1.0, 0.05, "#3a2a1c"); bbox(3, -1.4, 0, 0.55, 0.5, 0.55, "#b9b6ad", 0.06))
func spark() -> ArrayMesh: return cached("spark", func(): box(0, 0, 0, 0.18, 0.18, 0.18, "#ffd34d"))

## Pontos de efeitos animados (bandeiras, fumaça, moinho, guindaste) em coordenadas locais
func fx_of(t: String, L: int) -> Dictionary:
	var o := {flags = [], smoke = [], mill = [], crane = []}
	match t:
		"castle":
			var R := 9.5; var tH := 6.5 + L * 0.5
			for a in [-1, 1]:
				for c in [-1, 1]: o.flags.append(Vector3(a * R, 0.6 + tH + 3.7, c * R))
			o.flags.append(Vector3(0, 0.6 + 7.5 + L * 1.1 + 0.7 + 3.5, -1.2))
		"tower": o.flags.append(Vector3(0, 6.5 + L * 0.9 + 4.1, 0))
		"house":
			var top := (1.0 if L >= 5 else 0.0) + (2.2 + 1.9 if L >= 3 else 2.5)
			if L >= 2: o.smoke.append(Vector3(1.1, top + 2.6, -1.0))
			if L >= 5: o.flags.append(Vector3(2.9, 3.5, -2.9))
		"tavern":
			o.smoke.append(Vector3(-2, 7.7, -2))
			if L >= 5: o.flags.append(Vector3(-4.4, 4.3, -3.6))
		"lumber": o.smoke.append(Vector3(0.1, 4.2, -2.0))
		"farm":
			if L >= 2: o.mill.append(Vector3(-5.6, 4.7, 5.75))
		"quarry":
			if L >= 2: o.crane.append(Vector3(3.8, 4.2, 2.2))
		"market":
			if L >= 5: o.flags.append(Vector3(-5, 4.0, -5)); o.flags.append(Vector3(5, 4.0, -5))
		"mine":
			if L >= 5: o.flags.append(Vector3(-1.8, 4.9, -0.4))
	return o

# ---------- árvores ----------
func tree_dec() -> ArrayMesh:
	return cached("treeD", func(): box(0, -0.3, 0, 0.42, 3.3, 0.42, "#7a5a3a"); ball(0, 4.0, 0, 2.05, "#4f9a42", 0.82, 3, 6); ball(0.9, 3.3, 0.4, 1.25, "#5aa548", 0.85, 3, 6); ball(-0.7, 3.6, -0.5, 1.1, "#438a3a", 0.85, 3, 6))
func tree_con() -> ArrayMesh:
	return cached("treeC", func():
		box(0, -0.3, 0, 0.36, 2.9, 0.36, "#6f5236")
		for j in 3: cone(0, 1.3 + j * 1.15, 0, 1.95 - j * 0.42, 3.2 - j * 0.3, mulc(mixc(col("#2f6b40"), col("#64a05a"), j * 0.15), 0.85 + j * 0.1), 7))

# ---------- aldeão articulado ----------
## uv.x = peça + 10*acessório. Peças: 0 corpo, 1/2 pernas, 3/4 braços.
## Acessórios: 1 machado, 2 picareta, 3 enxada, 4 martelo, 5 fardo, 6 chapéu de palha. uv.y: 1 roupa, 2 cabelo.
func villager() -> ArrayMesh:
	return cached("villager", func():
		var SKIN := "#f2c29b"; var PANTS := "#5a4636"; var SHOE := "#3b2a20"
		G.part = 1; box(-0.14, 0, 0, 0.24, 0.62, 0.26, PANTS); box(-0.14, 0, 0.05, 0.26, 0.14, 0.36, SHOE)
		G.part = 2; box(0.14, 0, 0, 0.24, 0.62, 0.26, PANTS); box(0.14, 0, 0.05, 0.26, 0.14, 0.36, SHOE)
		G.part = 0; G.mark = 1; G.shade = 1; bbox(0, 0.56, 0, 0.66, 0.66, 0.42, "#ffffff", 0.08); G.mark = 0
		box(0, 0.62, 0, 0.68, 0.12, 0.44, "#6b4a2e"); box(0, 0.66, 0.225, 0.14, 0.1, 0.02, "#e2b64b")
		bbox(0, 1.18, 0, 0.24, 0.1, 0.24, SKIN, 0.03)
		ball(0, 1.56, 0, 0.36, SKIN, 1, 4, 8)
		G.mark = 2; G.shade = 1; ball(0, 1.66, -0.03, 0.38, "#ffffff", 0.72, 3, 8, false); G.shade = 0.9; box(0, 1.4, -0.2, 0.5, 0.3, 0.2, "#ffffff"); G.mark = 0; G.shade = 1
		box(-0.12, 1.56, 0.33, 0.07, 0.1, 0.04, "#2a1d17"); box(0.12, 1.56, 0.33, 0.07, 0.1, 0.04, "#2a1d17"); box(0, 1.46, 0.35, 0.06, 0.06, 0.04, "#e3a07f")
		box(-0.2, 1.45, 0.31, 0.08, 0.05, 0.02, "#f29a9a"); box(0.2, 1.45, 0.31, 0.08, 0.05, 0.02, "#f29a9a")
		G.part = 3; G.mark = 1; G.shade = 0.92; box(-0.42, 0.7, 0, 0.17, 0.5, 0.2, "#ffffff"); G.mark = 0; box(-0.42, 0.6, 0, 0.16, 0.14, 0.16, SKIN)
		G.part = 4; G.mark = 1; box(0.42, 0.7, 0, 0.17, 0.5, 0.2, "#ffffff"); G.mark = 0; G.shade = 1; box(0.42, 0.6, 0, 0.16, 0.14, 0.16, SKIN)
		G.part = 14; box(0.42, 0.6, 0.35, 0.07, 0.07, 0.75, "#7a5232"); box(0.42, 0.62, 0.7, 0.07, 0.32, 0.2, "#c9ccd1")
		G.part = 24; box(0.42, 0.6, 0.35, 0.07, 0.07, 0.75, "#7a5232"); box(0.42, 0.62, 0.72, 0.06, 0.08, 0.55, "#9aa0a8"); box(0.42, 0.62, 0.72, 0.5, 0.08, 0.08, "#9aa0a8")
		G.part = 34; box(0.42, 0.6, 0.4, 0.06, 0.06, 0.95, "#9b6b3f"); box(0.42, 0.5, 0.86, 0.3, 0.18, 0.05, "#9aa0a8")
		G.part = 44; box(0.42, 0.6, 0.3, 0.07, 0.07, 0.55, "#7a5232"); box(0.42, 0.6, 0.6, 0.18, 0.18, 0.28, "#6c7078")
		G.part = 50; bbox(0, 0.95, 0.42, 0.62, 0.42, 0.42, "#ffffff", 0.08)
		G.part = 60; cyl(0, 1.86, 0, 0.62, 0.06, "#e8cf7a", 10); cone(0, 1.9, 0, 0.36, 0.32, "#e2c464", 10)
		G.part = 0)
