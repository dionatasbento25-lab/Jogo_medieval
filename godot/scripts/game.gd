extends Node
## Regras do city builder: economia, construções, população, empregos e rotina dos aldeões.
## Porte de citybuilder/src/game.js (a parte visual fica em main.gd).

signal toast(msg: String)
signal float_text(pos: Vector3, txt: String)
signal built(b: Dictionary)           # obra concluída (para confete e atualizar o modelo)
signal buildings_changed
signal spark(pos: Vector3)

const TILE := 4.0
const RES := ["gold", "wood", "stone", "food"]
const RICON := {gold = "🪙", wood = "🌲", stone = "🪨", food = "🌾"}
const DEF := {
	castle = {cost = [0, 0, 0], unlock = 1, desc = "O coração do reino. Abriga 6 aldeões, cobra impostos e envia os construtores."},
	house = {cost = [25, 35, 0], unlock = 1, desc = "Moradia para os aldeões. Mais casas = mais gente para trabalhar."},
	farm = {cost = [35, 30, 0], unlock = 1, job = "food", rate = 0.55, role = 3, desc = "Produz comida. Rende mais em planícies e perto de rios."},
	lumber = {cost = [30, 15, 0], unlock = 1, job = "wood", rate = 0.38, role = 1, desc = "Corta madeira. Precisa de floresta por perto: quanto mais mata, mais rende."},
	well = {cost = [20, 10, 25], unlock = 1, desc = "Água fresca deixa o povo mais feliz."},
	quarry = {cost = [50, 60, 0], unlock = 2, job = "stone", rate = 0.28, role = 2, desc = "Extrai pedra. Rende mais perto das montanhas."},
	warehouse = {cost = [60, 90, 20], unlock = 2, desc = "Aumenta a capacidade de armazenar recursos."},
	market = {cost = [120, 90, 40], unlock = 2, job = "gold", rate = 0.3, role = 0, shirt = 12, desc = "Comércio: gera ouro e alegra o povo."},
	tower = {cost = [90, 60, 110], unlock = 2, desc = "Vigia as fronteiras: o povo se sente seguro e fica mais feliz."},
	mine = {cost = [100, 80, 60], unlock = 3, job = "gold", rate = 0.26, role = 2, desc = "Extrai ouro. Só funciona perto de montanhas."},
	tavern = {cost = [160, 120, 80], unlock = 3, job = "happy", rate = 0.0, role = 0, shirt = 13, desc = "Cerveja e música: muita felicidade para o reino."},
}
const CASTLE_UP := [null, [200, 250, 80], [600, 500, 350], [1500, 1200, 1000], [4000, 3000, 2500]]
const BUILD_ORDER := ["house", "farm", "lumber", "well", "quarry", "warehouse", "market", "tower", "mine", "tavern"]
## Paleta de roupas (índice usado pelo shader dos aldeões): 0-3 profissões, 4-11 desocupados, 12 mercado, 13 taverna
const SHIRTS := ["#4a78c4", "#c8443a", "#7d766b", "#7fb24a", "#ff8a3d", "#d9a32a", "#3fa7a0", "#b8577a", "#7a8f3f", "#9a6cc8", "#d86a3a", "#5b7fa8", "#8a5bc2", "#f6efe0"]
const ROLE_SHIRT := {1: 1, 2: 2, 3: 3, 4: 4}
const SAVE_PATH := "user://reino.json"

var S = {}
var econ = {rate = {gold = 0.0, wood = 0.0, stone = 0.0, food = 0.0}, cap = 600.0, popCap = 0, hap = 60.0, jobs = 0, idle = 0, builders = 2}
var by_id = {}
var occ = {}
var vill: Array = []
var v_seq = 1
var world_castles: Array = []
var MAXV = 220
var game_time = 0.0

func _init() -> void: reset_state()
func reset_state() -> void:
	S = {res = {gold = 250.0, wood = 250.0, stone = 150.0, food = 80.0}, b = [], pop = 0, goal = 0, castle = 0, nextId = 1, saved = 0, growT = 0.0, kingdom = -1}
	by_id.clear(); occ.clear(); vill.clear()

func GOALS() -> Array:
	return [
		{t = "Escolha o seu reino e erga o castelo", f = func(): return 1 if castle_l() else 0, n = 1, r = [0, 100, 0]},
		{t = "Construa 2 casas", f = func(): return count_b("house"), n = 2, r = [60, 0, 0]},
		{t = "Construa uma fazenda", f = func(): return count_b("farm"), n = 1, r = [0, 50, 0]},
		{t = "Construa um lenhador", f = func(): return count_b("lumber"), n = 1, r = [50, 0, 0]},
		{t = "Alcance 12 habitantes", f = func(): return S.pop, n = 12, r = [80, 0, 60]},
		{t = "Evolua o castelo ao nível 2", f = func(): return 1 if castle_l() >= 2 else 0, n = 1, r = [150, 0, 0]},
		{t = "Construa uma pedreira", f = func(): return count_b("quarry"), n = 1, r = [0, 80, 0]},
		{t = "Construa um mercado", f = func(): return count_b("market"), n = 1, r = [0, 0, 100]},
		{t = "Melhore uma casa ao nível 3", f = func(): return 1 if S.b.any(func(b): return b.type == "house" and b.level >= 3) else 0, n = 1, r = [200, 0, 0]},
		{t = "Alcance 30 habitantes", f = func(): return S.pop, n = 30, r = [300, 0, 0]},
		{t = "Construa um armazém", f = func(): return count_b("warehouse"), n = 1, r = [0, 150, 0]},
		{t = "Evolua o castelo ao nível 3", f = func(): return 1 if castle_l() >= 3 else 0, n = 1, r = [0, 0, 300]},
		{t = "Construa uma mina de ouro", f = func(): return count_b("mine"), n = 1, r = [0, 200, 0]},
		{t = "Construa uma taverna", f = func(): return count_b("tavern"), n = 1, r = [400, 0, 0]},
		{t = "Deixe o povo 85% feliz", f = func(): return int(econ.hap), n = 85, r = [300, 300, 300]},
		{t = "Alcance 60 habitantes", f = func(): return S.pop, n = 60, r = [800, 0, 0]},
		{t = "Evolua o castelo ao nível 5", f = func(): return 1 if castle_l() >= 5 else 0, n = 1, r = [2000, 2000, 2000]},
	]
var goals: Array = []
func _ready() -> void: goals = GOALS()

# ---------- utilidades ----------
func tkey(i: int, j: int) -> int: return (i + 600) * 2000 + (j + 600)
func count_b(t: String) -> int:
	var n = 0
	for b in S.b:
		if b.type == t and b.state == "done": n += 1
	return n
func castle_b():
	return by_id.get(S.castle) if S.castle else null
func castle_l() -> int:
	var c = castle_b(); return c.level if c and c.state == "done" else 0
func cost_of(t: String, level: int):
	if t == "castle": return CASTLE_UP[level] if level < CASTLE_UP.size() else null
	var k = pow(1.7, level - 1); var out = []
	for c in DEF[t].cost: out.append(int(round(c * k / 5.0)) * 5)
	return out
func can_pay(c) -> bool: return c != null and S.res.gold >= c[0] and S.res.wood >= c[1] and S.res.stone >= c[2]
func pay(c: Array) -> void: S.res.gold -= c[0]; S.res.wood -= c[1]; S.res.stone -= c[2]
func work_time(t: String, level: int) -> float: return M.TYPES[t].time * (1.0 + 0.6 * (level - 1))
func slots_of(b: Dictionary) -> int:
	var d: Dictionary = DEF[b.type]
	if not d.has("job") or b.state != "done": return 0
	if b.type == "tavern": return 1 + int(b.level / 2)
	return 1 + b.level
static func fmt(n: float) -> String:
	if n >= 1e5: return "%dk" % int(n / 1000)
	if n >= 1e4: return "%.1fk" % (n / 1000.0)
	return str(int(n))

# ---------- território: as províncias do seu reino ----------
func in_terr(x: float, z: float, k: int) -> bool: return k >= 0 and W.owner_at(x, z) == k
func frac_around(x: float, z: float, r: float, set_: Array) -> float:
	var n = 0; var k = 0; var dz = -r
	while dz <= r:
		var dx = -r
		while dx <= r:
			if dx * dx + dz * dz <= r * r:
				k += 1
				if set_.has(W.class_at(x + dx, z + dz)): n += 1
			dx += 6
		dz += 6
	return float(n) / maxi(1, k)
func efficiency(t: String, x: float, z: float) -> Dictionary:
	match t:
		"farm":
			var c = W.class_at(x, z); var e = 0.55 if c == 4 else (0.8 if c == 3 else 1.0)
			if frac_around(x, z, 26, [1]) > 0 or frac_around(x, z, 22, [0]) > 0.05: e += 0.25
			return {e = e, need = true}
		"lumber":
			var f = frac_around(x, z, 40, [3]); return {e = clampf(0.25 + f * 2.4, 0.25, 1.6), need = f > 0.03, why = "Precisa de floresta por perto"}
		"quarry":
			var f = frac_around(x, z, 46, [5, 6]); return {e = clampf(0.35 + f * 2.6, 0.35, 1.6), need = f > 0.02, why = "Precisa de montanhas por perto"}
		"mine":
			var f = frac_around(x, z, 40, [5, 6]); return {e = clampf(0.45 + f * 2.2, 0.45, 1.7), need = f > 0.07, why = "A mina precisa ficar ao pé de uma montanha"}
	return {e = 1.0, need = true}
func snap_pos(t: String, px: float, pz: float) -> Dictionary:
	var n: int = M.TYPES[t].size; var i0 = int(round(px / TILE - n / 2.0)); var j0 = int(round(pz / TILE - n / 2.0))
	return {i0 = i0, j0 = j0, x = (i0 + n / 2.0) * TILE, z = (j0 + n / 2.0) * TILE}

func check(t: String, px: float, pz: float, ignore_id := 0, owner := -99) -> Dictionary:
	var K: int = S.kingdom if owner == -99 else owner
	var n: int = M.TYPES[t].size; var sp = snap_pos(t, px, pz); var x: float = sp.x; var z: float = sp.z; var S2 = n * TILE / 2.0
	var res = {ok = false, x = x, z = z, i0 = sp.i0, j0 = sp.j0, why = "", e = 1.0, y = 0.0, minH = 0.0}
	if absf(x) > W.HX - 40 or absf(z) > W.HZ - 40: res.why = "Longe demais"; return res
	if t == "castle" and owner == -99 and S.castle and ignore_id != S.castle: res.why = "O reino já tem um castelo"; return res
	for j in range(sp.j0, sp.j0 + n):
		for i in range(sp.i0, sp.i0 + n):
			var o = occ.get(tkey(i, j))
			if o and o != ignore_id: res.why = "Espaço ocupado"; return res
	var mn = 1e9; var mx = -1e9; var st = minf(4.0, S2); var dz = -S2
	while dz <= S2 + 0.01:
		var dx = -S2
		while dx <= S2 + 0.01:
			var xx = x + dx; var zz = z + dz
			if W.is_water(xx, zz): res.why = "Não dá para construir na água"; return res
			var c = W.class_at(xx, zz)
			if c == 6 or (c == 5 and t != "mine" and t != "tower"): res.why = "Terreno montanhoso demais"; return res
			var h = W.mesh_h(xx, zz); mn = minf(mn, h); mx = maxf(mx, h)
			dx += st
		dz += st
	if mx - mn > 1.4 + n * 0.4: res.why = "Terreno inclinado demais"; return res
	for p in [[-1, -1], [1, -1], [1, 1], [-1, 1], [0, 0]]:
		if not in_terr(x + p[0] * S2, z + p[1] * S2, K):
			res.why = "Escolha um reino primeiro" if K < 0 else "Fora das províncias do seu reino"; return res
	var ef = efficiency(t, x, z); res.e = ef.e
	if not ef.need: res.why = ef.why; return res
	res.ok = true; res.y = mx + 0.15; res.minH = mn; return res

# ---------- construções ----------
func occupy(b: Dictionary, on: bool) -> void:
	var n: int = M.TYPES[b.type].size
	for j in range(b.j0, b.j0 + n):
		for i in range(b.i0, b.i0 + n):
			if on: occ[tkey(i, j)] = b.id
			else: occ.erase(tkey(i, j))
	buildings_changed.emit()
func add_building(o: Dictionary) -> Dictionary:
	var b = {level = 1, state = "site", prog = 0.0, upg = false, popT = 0.0, rot = 0, workers = 0, rate = 0.0}
	b.merge(o, true)
	if not b.has("id") or not b.id: b.id = S.nextId; S.nextId += 1
	S.nextId = maxi(S.nextId, b.id + 1)
	var n: int = M.TYPES[b.type].size; var sp = snap_pos(b.type, b.x, b.z); b.i0 = sp.i0; b.j0 = sp.j0; b.x = sp.x; b.z = sp.z
	b.e = efficiency(b.type, b.x, b.z).e
	var mn = 1e9; var mx = -1e9; var S2 = n * TILE / 2.0; var dz = -S2
	while dz <= S2 + 0.01:
		var dx = -S2
		while dx <= S2 + 0.01:
			var h = maxf(W.mesh_h(b.x + dx, b.z + dz), 0); mn = minf(mn, h); mx = maxf(mx, h); dx += 2
		dz += 2
	b.y = mx + 0.15; b.minH = mn
	if not b.has("work"): b.work = work_time(b.type, b.level)
	S.b.append(b); by_id[b.id] = b; occupy(b, true)
	if b.type == "castle": S.castle = b.id
	prep_spots(b); return b
func remove_building(b: Dictionary) -> void:
	occupy(b, false); S.b.erase(b); by_id.erase(b.id)
	if S.castle == b.id: S.castle = 0
	for v in vill:
		if v.job == b.id: v.job = 0; v.task = null
		if v.home == b.id: v.home = 0
		if v.site == b.id: v.site = 0; v.task = null
	buildings_changed.emit()
func to_world(b: Dictionary, lx: float, lz: float) -> Vector2:
	var a: float = b.rot * PI / 2; var c = cos(a); var s = sin(a)
	return Vector2(b.x + lx * c + lz * s, b.z - lx * s + lz * c)
func door_of(b: Dictionary) -> Vector2:
	var S2: float = M.TYPES[b.type].size * TILE / 2.0
	return to_world(b, 0.0 if b.type == "castle" else -0.3, S2 + 0.9)
func _h2(x: float, z: float) -> float:
	var n = sin(x * 127.1 + z * 311.7) * 43758.5453; return n - floor(n)
func prep_spots(b: Dictionary) -> void:
	var sp: Array = []; var T: String = b.type
	if T == "farm":
		for k in 14: sp.append(to_world(b, -7.5 + _h2(b.id, k) * 8.5 + (1.0 if b.level >= 3 else 0.0), -6 + _h2(k, b.id) * 7))
	elif T in ["lumber", "quarry", "mine"]:
		var set_ = [3] if T == "lumber" else [5, 6]; var R = 40 if T == "lumber" else 46; var found = []
		for dz in range(-R, R + 1, 5):
			for dx in range(-R, R + 1, 5):
				var x: float = b.x + dx; var z: float = b.z + dz; var d = Vector2(dx, dz).length()
				if d > R or d < 12: continue
				if not set_.has(W.class_at(x, z)) or W.is_water(x, z): continue
				if occ.get(tkey(int(floor(x / TILE)), int(floor(z / TILE)))): continue
				if T != "lumber" and W.mesh_h(x, z) > b.y + 14: continue
				found.append([d, Vector2(x, z)])
		found.sort_custom(func(p, q): return p[0] < q[0])
		for f in found.slice(0, 24): sp.append(f[1])
		if T != "lumber":
			for p in [[-1.8, -1.2], [-3.2, 0.2], [0, 2.6], [-1, -4.4]]: sp.append(to_world(b, p[0], p[1]))
		if sp.is_empty():
			for k in 6:
				var a = k / 6.0 * TAU; sp.append(Vector2(b.x + cos(a) * 9, b.z + sin(a) * 9))
	else:
		var S2: float = M.TYPES[T].size * TILE / 2.0
		for k in 8:
			var a = k / 8.0 * TAU; sp.append(Vector2(b.x + cos(a) * (S2 + 1.2), b.z + sin(a) * (S2 + 1.2)))
	b.spots = sp

# ---------- castelos dos outros reinos ----------
func find_spot(t: String, x0: float, z0: float, owner: int, max_r := 90.0):
	var r = 0.0
	while r <= max_r:
		var n = 1 if r == 0 else maxi(8, int(round(r * 1.2)))
		for k in n:
			var a = float(k) / n * TAU; var c = check(t, x0 + cos(a) * r, z0 + sin(a) * r, 0, owner)
			if c.ok: return c
		r += 4
	return null
func castle_spot_for(h: int):
	var seat = W.anchor_of(int(W.F.houses[h].seat)); var c = find_spot("castle", seat.x, seat.y, h, 140)
	if c: return c
	for i in W.NP:
		if int(W.F.prov[i][2]) == h:
			var a = W.anchor_of(i); c = find_spot("castle", a.x, a.y, h, 100)
			if c: return c
	return null
func build_world_castles() -> void:
	for w in world_castles:
		for t in w.tiles: occ.erase(t)
	world_castles.clear()
	for i in W.F.houses.size():
		if i == S.kingdom: continue
		var h: Dictionary = W.F.houses[i]; var c = castle_spot_for(i)
		if c == null: continue
		var n: int = M.TYPES.castle.size; var b = {type = "castle", x = c.x, z = c.z, y = c.y, minH = c.minH, rot = (i * 7) % 4, level = clampi(1 + int(h.n / 4), 1, 4), house = i, tiles = []}
		for j in range(c.j0, c.j0 + n):
			for q in range(c.i0, c.i0 + n):
				var t = tkey(q, j); occ[t] = -1 - i; b.tiles.append(t)
		world_castles.append(b)
	buildings_changed.emit()

# ---------- economia ----------
func compute_econ() -> void:
	var cl = castle_l(); var cap = 600.0 + 400 * maxi(0, cl - 1); var pop_cap = 0; var hap = 55.0
	for b in S.b:
		if b.state != "done": continue
		var L: int = b.level
		match b.type:
			"castle": pop_cap += 6
			"house": pop_cap += 4 + 2 * (L - 1); hap += 1 if L >= 4 else 0
			"warehouse": cap += 500 * L
			"well": hap += 3 + 2 * L
			"market": hap += 2 * L
			"tavern": hap += 8 + 5 * L
			"tower": hap += 2 + 2 * L
	if S.res.food <= 0: hap -= 35
	if S.pop > pop_cap: hap -= 10
	econ.hap = clampf(hap, 0, 100); econ.cap = cap; econ.popCap = pop_cap; econ.builders = 1 + maxi(1, cl)
	var posts = S.b.filter(func(b): return slots_of(b) > 0)
	var need: bool = S.res.food < 40 or econ.rate.food < 0
	posts.sort_custom(func(a, c):
		if need and (a.type == "farm") != (c.type == "farm"): return a.type == "farm"
		return a.id < c.id)
	for b in posts: b.workers = 0
	var free: int = S.pop; var any = true
	while free > 0 and any:
		any = false
		for b in posts:
			if free <= 0: break
			if b.workers < slots_of(b): b.workers += 1; free -= 1; any = true
	econ.jobs = S.pop - free; econ.idle = free
	var hf = 0.75 + 0.5 * econ.hap / 100.0
	var r = {gold = 0.4 + 0.25 * maxi(0, cl - 1) + 0.025 * S.pop, wood = 0.0, stone = 0.0, food = -0.11 * S.pop}
	if not cl: r.gold = 0.0
	for b in posts:
		var d: Dictionary = DEF[b.type]
		if not d.has("job") or d.job == "happy": continue
		b.rate = d.rate * (1 + 0.35 * (b.level - 1)) * b.e * hf; r[d.job] += b.rate * b.workers
	econ.rate = r
func sim_econ(dt: float) -> void:
	for k in RES: S.res[k] = clampf(S.res[k] + econ.rate[k] * dt, 0, econ.cap)
	if castle_l() and S.pop < econ.popCap and S.res.food > 3:
		S.growT += dt * (0.45 + econ.hap / 100.0)
		if S.growT >= 5: S.growT = 0; S.pop += 1; spawn_villager(false); compute_econ()
	if S.pop > econ.popCap: S.pop = econ.popCap; trim_villagers()

# ---------- aldeões ----------
func spawn_villager(builder: bool, at = null) -> Dictionary:
	var c = castle_b(); var p: Vector2 = at if at != null else (door_of(c) if c else Vector2.ZERO)
	var v = {id = v_seq, x = p.x + randf_range(-1, 1), z = p.y + randf_range(-1, 1), yaw = 0.0, ph = randf() * 6, mode = 0, role = 4 if builder else 0, carry = 0,
		builder = builder, job = 0, home = 0, site = 0, task = null, hidden = false, shirt = 4 if builder else 4 + (v_seq * 5) % 8, hair = randf(), trips = 0.0,
		side = 1.0 if randf() < 0.5 else -1.0, speed = 2.6 + randf() * 0.7, from = 0, t0 = 4.0}
	v_seq += 1; vill.append(v); return v
func trim_villagers() -> void:
	var n = vill.filter(func(v): return not v.builder).size(); var i = vill.size() - 1
	while i >= 0 and n > S.pop:
		if not vill[i].builder: vill.remove_at(i); n -= 1
		i -= 1
func sync_villagers() -> void:
	var civ = vill.filter(func(v): return not v.builder).size()
	while civ < mini(S.pop, MAXV): spawn_villager(false); civ += 1
	trim_villagers()
	var bl = vill.filter(func(v): return v.builder).size(); var want: int = econ.builders if castle_b() else 0
	while bl < want: spawn_villager(true); bl += 1
	while bl > want:
		for i in vill.size():
			if vill[i].builder: vill.remove_at(i); break
		bl -= 1
func assign_roles() -> void:
	var houses = {}
	for b in S.b:
		if b.state == "done" and (b.type == "house" or b.type == "castle"):
			houses[b.id] = {cap = 6 if b.type == "castle" else 4 + 2 * (b.level - 1), n = 0}
	var civs = vill.filter(func(v): return not v.builder)
	for v in civs:
		if v.home:
			var h = houses.get(v.home)
			if h and h.n < h.cap: h.n += 1
			else: v.home = 0
	for v in civs:
		if not v.home:
			for id in houses:
				if houses[id].n < houses[id].cap: houses[id].n += 1; v.home = id; break
	var want = {}
	for b in S.b:
		if b.workers: want[b.id] = b.workers
	for v in civs:
		if v.job:
			var n: int = want.get(v.job, 0)
			if n > 0: want[v.job] = n - 1
			else: v.job = 0; v.task = null
	for v in civs:
		if not v.job:
			for id in want:
				if want[id] > 0: v.job = id; want[id] -= 1; v.task = null; v.trips = 0.0; break
	for v in civs:
		var b = by_id.get(v.job); var d = DEF[b.type] if b else null
		v.role = d.role if d else 0
		v.shirt = (d.shirt if d.has("shirt") else ROLE_SHIRT.get(d.role, 4 + v.id % 8)) if d else 4 + v.id % 8

func _go_to(v: Dictionary, x: float, z: float, then: Dictionary) -> void:
	v.task = {k = "walk", x = x, z = z, then = then, life = 0.0}; v.mode = 1
func _wander(v: Dictionary, p: Vector2, r: float) -> void:
	var a = randf() * TAU; var d = r * 0.4 + randf() * r
	_go_to(v, p.x + cos(a) * d, p.y + sin(a) * d, {k = "idle", t = 1.5 + randf() * 3})
func _pick(arr: Array): return arr[randi() % arr.size()]
func _think(v: Dictionary) -> void:
	var c = castle_b()
	if c == null: v.task = {k = "idle", t = 1.0}; return
	if v.builder:
		if v.site and not by_id.has(v.site): v.site = 0
		if not v.site:
			var best = null; var bn = 1 << 30
			for b in S.b:
				if not (b.state == "site" or b.upg): continue
				var n = vill.filter(func(u): return u.site == b.id).size()
				if n < bn: bn = n; best = b
			if best: v.site = best.id
		if v.site:
			var b: Dictionary = by_id[v.site]; var r: float = M.TYPES[b.type].size * TILE / 2.0 * 0.95; var a = randf() * TAU
			_go_to(v, b.x + cos(a) * r, b.z + sin(a) * r, {k = "build", t = 3 + randf() * 2, face = Vector2(b.x, b.z)}); return
		_wander(v, door_of(c), 6); return
	var job = by_id.get(v.job); var home = by_id.get(v.home)
	if job and job.state == "done":
		var T: String = job.type
		if v.trips >= 3 and home and randf() < 0.6:
			v.trips = 0.0; var hd = door_of(home); _go_to(v, hd.x, hd.y, {k = "rest", t = 4 + randf() * 4}); return
		if T in ["farm", "lumber", "quarry", "mine"]:
			var s: Vector2 = _pick(job.spots); var item = 1 if T == "lumber" else (2 if T == "quarry" else (3 if T == "farm" else 4))
			_go_to(v, s.x, s.y, {k = "work", t = 3.5 + randf() * 2.5, after = {k = "carry", to = job.id, item = item}}); return
		var s2: Vector2 = _pick(job.spots); _go_to(v, s2.x, s2.y, {k = "idle", t = 4 + randf() * 5, face = Vector2(job.x, job.z)}); v.trips += 0.5; return
	if home and randf() < 0.25:
		var hd = door_of(home); _go_to(v, hd.x, hd.y, {k = "rest", t = 5 + randf() * 6}); return
	var hubs = S.b.filter(func(b): return b.state == "done" and b.type in ["market", "well", "castle", "tavern"])
	var hub = _pick(hubs) if hubs.size() else c
	_wander(v, door_of(hub), 7)
func _start(v: Dictionary, t) -> void:
	v.task = t; v.mode = 0
	if t == null: return
	if not t.has("t"): t.t = 0.0
	if t.k == "work" or t.k == "build":
		v.mode = 2; v.t0 = t.t
	if t.has("face"): v.yaw = atan2(t.face.x - v.x, t.face.y - v.z)
	if t.k == "rest": v.hidden = true
	if t.k == "carry":
		var b = by_id.get(t.to)
		if b == null: v.task = null; return
		v.carry = t.item; var d = door_of(b); _go_to(v, d.x, d.y, {k = "deliver", to = b.id})
func _hit(x: float, z: float, goal, from) -> bool:
	var id = occ.get(tkey(int(floor(x / TILE)), int(floor(z / TILE))))
	return id != null and id != goal and id != from
func step_villager(v: Dictionary, dt: float, cam_target: Vector3, cam_dist: float) -> void:
	if v.task == null:
		_think(v)
		if v.task and v.task.k != "walk": _start(v, v.task)
	var t = v.task
	if t == null: return
	if t.k == "walk":
		var dx: float = t.x - v.x; var dz: float = t.z - v.z; var d = sqrt(dx * dx + dz * dz)
		if d < 0.35: v.mode = 0; _start(v, t.then); return
		var ux = dx / d; var uz = dz / d; var sp: float = v.speed * dt
		var goal = occ.get(tkey(int(floor(t.x / TILE)), int(floor(t.z / TILE))))
		if _hit(v.x + ux * 1.6, v.z + uz * 1.6, goal, v.from):
			for a in [0.9, 1.5, 2.2]:
				var ca = cos(a * v.side); var sa = sin(a * v.side); var nx = ux * ca - uz * sa; var nz = ux * sa + uz * ca
				if not _hit(v.x + nx * 1.6, v.z + nz * 1.6, goal, v.from): ux = nx; uz = nz; break
		v.x += ux * minf(sp, d); v.z += uz * minf(sp, d)
		var ty = atan2(ux, uz); var dy = wrapf(ty - v.yaw, -PI, PI); v.yaw += dy * minf(1, dt * 10)
		v.ph = fmod(v.ph + sp * 2.7, TAU * 8); v.mode = 1; t.life += dt
		if t.life > 40: v.task = null
		return
	v.ph = fmod(v.ph + dt * (4.2 if v.mode == 2 else 2.0), TAU * 8); t.t -= dt
	if t.k == "build":
		var b = by_id.get(v.site)
		if b == null or not (b.state == "site" or b.upg): v.task = null; v.site = 0; v.mode = 0; return
		if randf() < dt * 1.2: spark.emit(Vector3(v.x + sin(v.yaw) * 0.8, W.ground(v.x, v.z) + 0.9, v.z + cos(v.yaw) * 0.8))
		if t.t <= 0: v.task = null
		return
	if t.t > 0: return
	v.hidden = false
	if t.k == "work": _start(v, t.after); return
	if t.k == "deliver":
		var b = by_id.get(t.to)
		if b:
			var d: Dictionary = DEF[b.type]; var amt: float = b.rate * v.t0 * 2.4
			if amt > 0 and Vector2(b.x - cam_target.x, b.z - cam_target.z).length() < 280 + cam_dist * 0.6:
				float_text.emit(Vector3(b.x, b.y + M.HEIGHT[b.type] * 0.7, b.z), "+%d %s" % [maxi(1, int(round(amt))), RICON[d.job]])
		v.carry = 0; v.trips += 1; v.from = t.to; v.task = null; return
	v.from = 0; v.task = null
func villager_y(v: Dictionary) -> float:
	var id = occ.get(tkey(int(floor(v.x / TILE)), int(floor(v.z / TILE))))
	if id and id > 0 and by_id.has(id): return by_id[id].y + 0.2
	return maxf(W.mesh_h(v.x, v.z), 0) + 0.02

# ---------- obras ----------
func sim_build(dt: float) -> void:
	for b in S.b:
		if b.popT > 0: b.popT = maxf(0, b.popT - dt)
		if not (b.state == "site" or b.upg): continue
		var here = 0
		for v in vill:
			if v.builder and v.site == b.id and v.task and v.task.k == "build": here += 1
		var solo: bool = b.type == "castle" and b.state == "site"
		b.prog = minf(1, b.prog + (here + (1 if solo else 0)) / b.work * dt)
		if b.prog >= 1: finish_build(b)
func finish_build(b: Dictionary) -> void:
	var was_site: bool = b.state == "site"; b.state = "done"; b.prog = 0.0
	if b.upg: b.level += 1; b.upg = false
	b.popT = 0.55; b.e = efficiency(b.type, b.x, b.z).e; prep_spots(b)
	for v in vill:
		if v.site == b.id: v.site = 0; v.task = null
	toast.emit("%s %s %s" % [M.TYPES[b.type].icon, M.TYPES[b.type].name, "construída!" if was_site else "melhorada para o nível %d!" % b.level])
	if b.type == "castle" and was_site: toast.emit("🏰 Seu castelo está de pé! Construa casas e fazendas.")
	built.emit(b); compute_econ(); sync_villagers(); assign_roles(); buildings_changed.emit(); save()
func place_building(t: String, c: Dictionary, rot: int):
	var cost = [0, 0, 0] if t == "castle" else cost_of(t, 1)
	if not can_pay(cost): toast.emit("Recursos insuficientes"); return null
	pay(cost); var b = add_building({type = t, x = c.x, z = c.z, rot = rot})
	compute_econ(); sync_villagers(); save(); return b
func upgrade_building(b: Dictionary) -> void:
	if b.state != "done" or b.upg: return
	if b.level >= M.TYPES[b.type].max: toast.emit("Nível máximo"); return
	var c = cost_of(b.type, b.level if b.type == "castle" else b.level + 1)
	if b.type != "castle" and b.level >= castle_l() + 1 and b.type != "well": toast.emit("Evolua o castelo primeiro"); return
	if c.max() > econ.cap: toast.emit("Capacidade insuficiente — construa Armazéns 📦"); return
	if not can_pay(c): toast.emit("Recursos insuficientes"); return
	pay(c); b.upg = true; b.prog = 0.0; b.work = work_time(b.type, b.level + 1); toast.emit("🔨 Melhoria iniciada"); buildings_changed.emit(); save()
func demolish(b: Dictionary) -> void:
	if b.type == "castle": toast.emit("O castelo não pode ser demolido"); return
	var c: Array = cost_of(b.type, b.level)
	for i in 3: S.res[RES[i]] += round(c[i] * 0.5)
	remove_building(b); toast.emit("🗑 Demolido (50% devolvido)"); compute_econ(); sync_villagers(); assign_roles(); save()

# ---------- escolha do reino ----------
func choose_kingdom(h: int):
	if S.kingdom >= 0: return null
	S.kingdom = h; var c = castle_spot_for(h)
	if c == null: S.kingdom = -1; toast.emit("Não há espaço plano para o castelo neste reino. Escolha outro."); return null
	build_world_castles(); var b = place_building("castle", c, 0)
	toast.emit("👑 Você agora governa o %s!" % W.F.houses[h].name); Dyn.resume(); save(); return b

# ---------- objetivos ----------
var warn_t = -99.0
func check_goals() -> void:
	if castle_l() and econ.rate.food < 0 and S.res.food < 40 and game_time - warn_t > 45:
		warn_t = game_time; toast.emit("🌾 A comida está acabando! Construa ou melhore fazendas.")
	if S.goal >= goals.size(): return
	var g: Dictionary = goals[S.goal]
	if g.f.call() >= g.n:
		for i in 3: S.res[RES[i]] += g.r[i]
		S.goal += 1; toast.emit("📜 Objetivo concluído: %s!" % g.t)

# ---------- passo da simulação ----------
var _econ_t = 0.0
var _assign_t = 0.0
var _save_t = 0.0
func sim_step(dt: float, cam_target: Vector3, cam_dist: float) -> void:
	game_time += dt
	_econ_t += dt
	if _econ_t > 0.5: _econ_t = 0; compute_econ(); check_goals()
	sim_econ(dt); sim_build(dt)
	for v in vill: step_villager(v, dt, cam_target, cam_dist)
	_assign_t += dt
	if _assign_t > 1.5: _assign_t = 0; sync_villagers(); assign_roles()
	_save_t += dt
	if _save_t > 8: _save_t = 0; save()

# ---------- salvar / carregar ----------
var cam_state = []
func save() -> void:
	if not S.castle: return
	S.saved = Time.get_unix_time_from_system()
	var bl = []
	for b in S.b: bl.append({id = b.id, type = b.type, x = b.x, z = b.z, rot = b.rot, level = b.level, state = b.state, prog = b.prog, upg = b.upg, work = b.work})
	var data = {kingdom = S.kingdom, res = S.res, pop = S.pop, goal = S.goal, castle = S.castle, nextId = S.nextId, saved = S.saved, growT = S.growT, b = bl, cam = cam_state}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data))
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH): return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY or not d.has("b") or d.b.is_empty() or int(d.get("kingdom", -1)) < 0: return {}
	S.kingdom = int(d.kingdom); build_world_castles()
	for k in RES: S.res[k] = float(d.res.get(k, 0))
	S.pop = int(d.pop); S.goal = int(d.goal); S.nextId = int(d.nextId); S.growT = float(d.get("growT", 0))
	for o in d.b:
		add_building({id = int(o.id), type = o.type, x = float(o.x), z = float(o.z), rot = int(o.rot), level = int(o.level), state = o.state, prog = float(o.prog), upg = bool(o.upg), work = float(o.work)})
	S.castle = int(d.castle); compute_econ(); compute_econ()
	var away = clampf(Time.get_unix_time_from_system() - float(d.get("saved", 0)), 0, 4 * 3600)
	var gains = {}
	if away > 60:
		for k in RES:
			var r: float = econ.rate[k]; gains[k] = r * away * 0.5 if r > 0 else 0.0; S.res[k] = clampf(S.res[k] + gains[k], 0, econ.cap)
		for b in S.b:
			if b.state == "site" or b.upg:
				b.prog = minf(1, b.prog + away / b.work * 0.5)
				if b.prog >= 1:
					b.state = "done"; b.prog = 0.0
					if b.upg: b.level += 1; b.upg = false
	compute_econ(); sync_villagers(); assign_roles()
	var done = S.b.filter(func(b): return b.state == "done")
	for v in vill:
		if done.size():
			var dd = door_of(_pick(done)); v.x = dd.x + randf_range(-2, 2); v.z = dd.y + randf_range(-2, 2)
	Dyn.resume(); buildings_changed.emit()
	return {away = away, gains = gains, cam = d.get("cam", [])}
func wipe_save() -> void:
	if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(SAVE_PATH)
