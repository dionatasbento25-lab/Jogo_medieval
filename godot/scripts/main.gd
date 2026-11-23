extends Node3D
## Cena principal: terreno, água, árvores, construções, aldeões, câmera e gestos.
## Porte de citybuilder/src/view.js + parte de main.js.

const MODES := {
	terrain = {fill = 0.0, lines = Vector3(0.35, 0.55, 0.85), name = "Terreno"},
	provinces = {fill = 0.85, lines = Vector3(0.9, 0.85, 1.0), name = "Províncias"},
	houses = {fill = 0.85, lines = Vector3(0.45, 1.0, 1.0), name = "Reinos"},
	regions = {fill = 0.85, lines = Vector3(0.2, 0.45, 1.0), name = "Regiões"},
}
const SPEED_MUL := [0.0, 1.0, 1.5, 2.0, 3.0, 4.0]
const DMIN := 16.0
const DMAX := 2600.0
const HOME := {yaw = 0.0, pitch = 1.15, dist = 2350.0}
const LF := Vector3(-0.52, 0.64, 0.56)

var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var ui: CanvasLayer
var terrain_mat: ShaderMaterial
var water_mat: ShaderMaterial
var build_mat: ShaderMaterial
var ghost_mat: ShaderMaterial
var tree_mat: ShaderMaterial
var vill_mat: ShaderMaterial
var look_img: Image
var look_tex: ImageTexture
var map_mode = "houses"
var sel_prov = -1

var yaw = 0.0
var pitch = 1.15
var dist = 2350.0
var target = Vector3.ZERO
var fly = null
var anim_t = 0.0
var ready_done = false

# ---------- inicialização ----------
func _ready() -> void:
	ui = preload("res://scripts/ui.gd").new(); ui.main = self; add_child(ui)
	ui.set_loading("Carregando o continente…")
	await get_tree().process_frame
	W.load_all()
	ui.set_loading("Erguendo o relevo…"); await get_tree().process_frame
	_setup_env(); _build_terrain(); _build_water()
	ui.set_loading("Conhecendo os 61 reinos…"); await get_tree().process_frame
	Dyn.setup()
	_build_trees(); _build_villagers(); _build_particles(); _build_straits()
	for t in M.TYPES: M.model(t, 1)
	Game.toast.connect(ui.toast); Game.float_text.connect(ui.float_text); Game.built.connect(_on_built); Game.spark.connect(spark)
	Game.buildings_changed.connect(func(): _bdirty = true; _tree_key = "")
	Dyn.logged.connect(_on_log)
	if "--autotest" in OS.get_cmdline_user_args(): Game.wipe_save()
	var loaded = Game.load_game()
	if loaded.is_empty():
		Game.build_world_castles(); ui.show_intro()
	else:
		var c: Array = loaded.cam
		if c.size() == 5: target = Vector3(c[0], 0, c[1]); dist = c[2]; yaw = c[3]; pitch = c[4]
		if loaded.away > 60: ui.show_back(loaded.away, loaded.gains)
	rebuild_political()
	ui.ready_game()
	ready_done = true
	ui.hide_loading()
	if "--autotest" in OS.get_cmdline_user_args(): _autotest()

func _setup_env() -> void:
	var we = WorldEnvironment.new(); env = Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.55, 0.66, 0.70)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.47, 0.53, 0.58); env.ambient_light_energy = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true; env.fog_mode = Environment.FOG_MODE_DEPTH; env.fog_light_color = Color(0.55, 0.66, 0.70); env.fog_density = 0.24
	we.environment = env; add_child(we)
	sun = DirectionalLight3D.new(); sun.light_color = Color(1.0, 0.91, 0.76); sun.light_energy = 1.1
	sun.shadow_enabled = true; sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS; sun.shadow_blur = 1.5
	add_child(sun); sun.look_at_from_position(Vector3.ZERO, -LF.normalized(), Vector3.UP)
	cam = Camera3D.new(); cam.fov = 60.0; add_child(cam); cam.current = true

func _tex(img: Image, mip := true) -> ImageTexture:
	if mip: img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _build_terrain() -> void:
	terrain_mat = ShaderMaterial.new(); terrain_mat.shader = preload("res://shaders/terrain.gdshader")
	var det = _tex(W.detail_img); var nrm = _tex(W.normals_img)
	terrain_mat.set_shader_parameter("albedo_tex", _tex(W.albedo_img)); terrain_mat.set_shader_parameter("nrm_tex", nrm)
	terrain_mat.set_shader_parameter("det_tex", det); terrain_mat.set_shader_parameter("splat_tex", _tex(W.splat_img))
	terrain_mat.set_shader_parameter("pat_tex", _tex(W.patterns_img)); terrain_mat.set_shader_parameter("bord_tex", _tex(W.borders_img))
	terrain_mat.set_shader_parameter("prov_tex", ImageTexture.create_from_image(Image.create_from_data(W.PW, W.PH, false, Image.FORMAT_RG8, W.PID)))
	look_img = Image.create(512, 1, false, Image.FORMAT_RGBA8); look_tex = ImageTexture.create_from_image(look_img)
	terrain_mat.set_shader_parameter("look_tex", look_tex)
	terrain_mat.set_shader_parameter("half_size", Vector2(W.HX, W.HZ)); terrain_mat.set_shader_parameter("tex_w", W.WX / 2048.0)
	water_mat = ShaderMaterial.new(); water_mat.shader = preload("res://shaders/water.gdshader")
	water_mat.set_shader_parameter("nrm_tex", nrm); water_mat.set_shader_parameter("det_tex", det); water_mat.set_shader_parameter("half_size", Vector2(W.HX, W.HZ))
	# blocos de 64x64 células (só os visíveis são desenhados pelo Godot)
	var CS = 64; var V = CS + 1; var idx = PackedInt32Array()
	for j in CS:
		for i in CS:
			var a = j * V + i; idx.append_array([a, a + V + 1, a + V, a, a + 1, a + V + 1])
	var Wn = W.NX + 1
	for cj in W.NZ / CS:
		for ci in W.NX / CS:
			var pos = PackedVector3Array(); var nor = PackedVector3Array(); pos.resize(V * V); nor.resize(V * V); var mx = -1e9
			for j in V:
				for i in V:
					var gi = ci * CS + i; var gj = cj * CS + j; var h: float = W.NH[gj * Wn + gi]
					var hl: float = W.NH[gj * Wn + maxi(gi - 1, 0)]; var hr: float = W.NH[gj * Wn + mini(gi + 1, W.NX)]
					var hd: float = W.NH[maxi(gj - 1, 0) * Wn + gi]; var hu: float = W.NH[mini(gj + 1, W.NZ) * Wn + gi]
					pos[j * V + i] = Vector3(-W.HX + gi * W.CX, h, -W.HZ + gj * W.CZ)
					nor[j * V + i] = Vector3(-(hr - hl) / (2 * W.CX), 1, -(hu - hd) / (2 * W.CZ)).normalized(); mx = maxf(mx, h)
			if mx < -0.5: continue
			var arr = []; arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = pos; arr[Mesh.ARRAY_NORMAL] = nor; arr[Mesh.ARRAY_INDEX] = idx
			var m = ArrayMesh.new(); m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			var mi = MeshInstance3D.new(); mi.mesh = m; mi.material_override = terrain_mat; add_child(mi)

func _build_water() -> void:
	var pm = PlaneMesh.new(); pm.size = Vector2(28000, 28000)
	var mi = MeshInstance3D.new(); mi.mesh = pm; mi.material_override = water_mat; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mi)

## Tabela de cores do mapa político: uma cor por província + marca (alfa) de terra/seu reino/selecionada.
func rebuild_political() -> void:
	var F = W.F; var hk: int = Game.S.kingdom
	look_img.set_pixel(0, 0, Color(0, 0, 0, 0))
	for p in W.NP:
		var hi = int(F.prov[p][2]); var c: Color
		match map_mode:
			"regions": c = W.region_colors[int(F.houses[hi].region)]
			"provinces":
				var b: Color = W.house_colors[hi]; var t = _h2(p * 1.7, 3.1) * 0.5 - 0.25; var jit = (_h2(p, 9.7) - 0.5) * 40.0 / 255.0
				c = Color(clampf(b.r * (1 + t) + jit, 0, 1), clampf(b.g * (1 + t) + jit, 0, 1), clampf(b.b * (1 + t) + jit, 0, 1))
			_: c = W.house_colors[hi]
		c.a = 1.0 if p == sel_prov else (150.0 / 255.0 if hi == hk else 128.0 / 255.0)
		look_img.set_pixel(p + 1, 0, c)
	look_tex.update(look_img)
func _h2(x: float, z: float) -> float:
	var n = sin(x * 127.1 + z * 311.7) * 43758.5453; return n - floor(n)
func set_map_mode(m: String) -> void: map_mode = m; rebuild_political()

func _build_straits() -> void:
	var F = W.F; var FW: float = F.frame[0]; var FH: float = F.frame[1]
	var mesh = M.cached("straits", func():
		for sg in F.straits:
			var ax: float = sg[0] / FW * W.WX - W.HX; var az: float = sg[1] / FH * W.WZ - W.HZ; var bx: float = sg[2] / FW * W.WX - W.HX; var bz: float = sg[3] / FH * W.WZ - W.HZ
			var dx = bx - ax; var dz = bz - az; var L = maxf(Vector2(dx, dz).length(), 1.0); var ux = dx / L; var uz = dz / L; var ext = maxf(4.0, (12 - L) / 2 + 3)
			ax -= ux * ext; az -= uz * ext; L += 2 * ext; var px = -uz; var pz = ux; var t = 0.0
			while t < L:
				var t1 = minf(t + 2.6, L); var x0 = ax + ux * t; var z0 = az + uz * t; var x1 = ax + ux * t1; var z1 = az + uz * t1
				var y0 = maxf(W.mesh_h(x0, z0), 0) + 0.5; var y1 = maxf(W.mesh_h(x1, z1), 0) + 0.5
				for q in [[1.9, Color(.24, .17, .09), 0.0], [1.05, Color(.97, .91, .74), 0.06]]:
					var w: float = q[0]
					M.quad(Vector3(x0 - px * w, y0 + q[2], z0 - pz * w), Vector3(x0 + px * w, y0 + q[2], z0 + pz * w), Vector3(x1 + px * w, y1 + q[2], z1 + pz * w), Vector3(x1 - px * w, y1 + q[2], z1 - pz * w), q[1])
				t += 4.4)
	var mi = MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = _bmat(); add_child(mi)

func _bmat() -> ShaderMaterial:
	if build_mat == null: build_mat = ShaderMaterial.new(); build_mat.shader = preload("res://shaders/building.gdshader")
	return build_mat

# ---------- árvores perto da câmera ----------
const TREE_DIST := 430.0
const TTILE := 48.0
var tree_mm: Array = []
var _tile_cache = {}
var _tree_key = ""
func _build_trees() -> void:
	tree_mat = ShaderMaterial.new(); tree_mat.shader = preload("res://shaders/tree.gdshader"); tree_mat.set_shader_parameter("half_size", Vector2(W.HX, W.HZ))
	for m in [M.tree_dec(), M.tree_con()]:
		var mm = MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_custom_data = true; mm.use_colors = true; mm.mesh = m
		var mmi = MultiMeshInstance3D.new(); mmi.multimesh = mm; mmi.material_override = tree_mat; add_child(mmi); tree_mm.append(mm)
func _occ_near(x: float, z: float) -> bool:
	for o in [[0, 0], [-3.4, -3.4], [3.4, -3.4], [3.4, 3.4], [-3.4, 3.4], [0, 3.6], [0, -3.6], [3.6, 0], [-3.6, 0]]:
		if Game.occ.has(Game.tkey(int(floor((x + o[0]) / 4.0)), int(floor((z + o[1]) / 4.0)))): return true
	return false
func _tile_trees(ti: int, tj: int) -> Array:
	var key = Vector2i(ti, tj)
	if _tile_cache.has(key): return _tile_cache[key]
	var s: int = ((ti * 73856093) ^ (tj * 19349663) ^ 0x5bd1e995) & 0xFFFFFFFF
	var D = PackedFloat32Array(); var Cn = PackedFloat32Array()
	for k in 170:
		s = (s * 1664525 + 1013904223) & 0xFFFFFFFF; var x = (ti + s / 4294967296.0) * TTILE
		s = (s * 1664525 + 1013904223) & 0xFFFFFFFF; var z = (tj + s / 4294967296.0) * TTILE
		if absf(x) > W.HX - 4 or absf(z) > W.HZ - 4: continue
		var cl = W.class_at(x, z); var p = 0.0; var coldN = smoothstep(0.40, 0.06, (z + W.HZ) / W.WZ); var coni = 0.5 + 0.47 * coldN
		if cl == 3: p = 0.82
		elif cl == 2: p = 0.03 + 0.03 * coldN
		elif cl == 5: p = 0.13 if W.htF(x, z) < 48 else 0.0; coni = 0.95
		elif cl == 4: p = 0.004
		s = (s * 1664525 + 1013904223) & 0xFFFFFFFF
		if s / 4294967296.0 > p: continue
		var y = W.mesh_h(x, z)
		if y < 0.4 or W.river_at(x, z) > 50 or _occ_near(x, z): continue
		s = (s * 1664525 + 1013904223) & 0xFFFFFFFF; var sc = 0.75 + s / 4294967296.0 * 0.6
		s = (s * 1664525 + 1013904223) & 0xFFFFFFFF; var rot = s / 4294967296.0 * TAU
		s = (s * 1664525 + 1013904223) & 0xFFFFFFFF; var tn = 0.82 + s / 4294967296.0 * 0.32
		s = (s * 1664525 + 1013904223) & 0xFFFFFFFF
		var arr = Cn if s / 4294967296.0 < coni else D
		var c = cos(rot) * sc; var sn = sin(rot) * sc
		arr.append_array([c, 0, sn, x, 0, sc, 0, y - 0.2, -sn, 0, c, z, 1, 1, 1, 1, tn, 0, 0, 0])
	var out = [D, Cn]
	if _tile_cache.size() > 2500: _tile_cache.clear()
	_tile_cache[key] = out; return out
func _update_trees() -> void:
	if dist > TREE_DIST:
		if _tree_key != "":
			for mm in tree_mm: mm.instance_count = 0
		_tree_key = ""; return
	var R = clampf(dist * 1.9 + 60, 140, 380 if OS.has_feature("mobile") else 520)
	var fw = -cam.global_basis.z; var fl = maxf(Vector2(fw.x, fw.z).length(), 0.001)
	var cx = target.x + fw.x / fl * R * 0.35; var cz = target.z + fw.z / fl * R * 0.35
	var ci = int(round(cx / TTILE)); var cj = int(round(cz / TTILE)); var key = "%d|%d|%d" % [ci, cj, int(round(R / 40))]
	if key == _tree_key: return
	_tree_key = key
	var n = int(ceil(R / TTILE)); var lst = []
	for j in range(-n, n + 1):
		for i in range(-n, n + 1):
			var dd = Vector2(i, j).length() * TTILE
			if dd <= R + TTILE * 0.7: lst.append([dd, ci + i, cj + j])
	lst.sort_custom(func(a, b): return a[0] < b[0])
	var D = PackedFloat32Array(); var Cn = PackedFloat32Array(); var cap = 9000 if OS.has_feature("mobile") else 18000
	for e in lst:
		if (D.size() + Cn.size()) / 20 >= cap: break
		var t = _tile_trees(e[1], e[2]); D.append_array(t[0]); Cn.append_array(t[1])
	for k in 2:
		var buf: PackedFloat32Array = D if k == 0 else Cn
		tree_mm[k].instance_count = buf.size() / 20
		if buf.size(): tree_mm[k].buffer = buf

# ---------- aldeões ----------
var vill_mm: MultiMesh
func _build_villagers() -> void:
	vill_mat = ShaderMaterial.new(); vill_mat.shader = preload("res://shaders/villager.gdshader")
	var pal = PackedVector3Array()
	for h in Game.SHIRTS: var c = Color.html(h); pal.append(Vector3(c.r, c.g, c.b))
	vill_mat.set_shader_parameter("shirts", pal)
	vill_mm = MultiMesh.new(); vill_mm.transform_format = MultiMesh.TRANSFORM_3D; vill_mm.use_custom_data = true; vill_mm.use_colors = true; vill_mm.mesh = M.villager()
	var mmi = MultiMeshInstance3D.new(); mmi.multimesh = vill_mm; mmi.material_override = vill_mat; add_child(mmi)
func _upload_villagers() -> void:
	if dist > 650: vill_mm.instance_count = 0; return
	var buf = PackedFloat32Array(); var R = dist * 2.2 + 120
	for v in Game.vill:
		if v.hidden or absf(v.x - target.x) > R or absf(v.z - target.z) > R: continue
		var c = cos(v.yaw); var s = sin(v.yaw); var y = Game.villager_y(v)
		buf.append_array([c, 0, s, v.x, 0, 1, 0, y, -s, 0, c, v.z, 1, 1, 1, 1, v.ph, v.mode + 4 * v.role + 32 * v.carry, v.shirt, v.hair])
	vill_mm.instance_count = buf.size() / 20
	if buf.size(): vill_mm.buffer = buf

# ---------- partículas (faíscas dos construtores e confete) ----------
var part_mm: MultiMesh
var parts: Array = []
func _build_particles() -> void:
	var sh = Shader.new()
	sh.code = "shader_type spatial;render_mode unshaded,cull_disabled;varying vec3 c;void vertex(){c=INSTANCE_CUSTOM.rgb;}void fragment(){ALBEDO=c;}"
	var mat = ShaderMaterial.new(); mat.shader = sh
	var bm = BoxMesh.new(); bm.size = Vector3(0.3, 0.06, 0.22)
	part_mm = MultiMesh.new(); part_mm.transform_format = MultiMesh.TRANSFORM_3D; part_mm.use_custom_data = true; part_mm.use_colors = true; part_mm.mesh = bm
	var mmi = MultiMeshInstance3D.new(); mmi.multimesh = part_mm; mmi.material_override = mat; mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mmi)
func spark(p: Vector3) -> void:
	if parts.size() > 400 or dist > 700: return
	parts.append({p = p, v = Vector3(randf_range(-1, 1), 2 + randf() * 2, randf_range(-1, 1)), t = 0.5, c = Color(1, 0.83, 0.3), r = 0.0, s = 0.6})
func confetti(b: Dictionary) -> void:
	if dist > 700: return
	var cols = [Color("#ff5d73"), Color("#ffd23f"), Color("#4fb3ff"), Color("#7cc35a"), Color("#b56cff")]
	for k in 40:
		parts.append({p = Vector3(b.x, b.y + M.HEIGHT[b.type] * 0.8, b.z), v = Vector3(randf_range(-4.5, 4.5), 4 + randf() * 6, randf_range(-4.5, 4.5)), t = 1.6 + randf(), c = cols[k % 5], r = randf() * 6, s = 1.0})
func _step_particles(dt: float) -> void:
	var buf = PackedFloat32Array(); var i = parts.size() - 1
	while i >= 0:
		var q: Dictionary = parts[i]; q.t -= dt
		if q.t <= 0: parts.remove_at(i); i -= 1; continue
		q.v.y -= (9.0 if q.s < 1 else 7.0) * dt; q.v.x *= 0.98; q.v.z *= 0.98; q.p += q.v * dt; q.r += dt * 8
		q.p.y = maxf(q.p.y, W.ground(q.p.x, q.p.z) + 0.05)
		var sc: float = q.s * (q.t * 2 if q.s < 1 else 1.0); var c = cos(q.r) * sc; var s = sin(q.r) * sc
		buf.append_array([c, 0, s, q.p.x, 0, sc, 0, q.p.y, -s, 0, c, q.p.z, 1, 1, 1, 1, q.c.r, q.c.g, q.c.b, 1]); i -= 1
	part_mm.instance_count = buf.size() / 20
	if buf.size(): part_mm.buffer = buf

# ---------- construções (nós 3D) ----------
var bnodes = {}
var world_nodes: Array = []
var _bdirty = true
func _make_mi(mesh: Mesh, parent: Node3D) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = _bmat(); parent.add_child(mi); return mi
func _foundation(b: Dictionary, parent: Node3D) -> void:
	var dep: float = b.y - b.minH + 0.6; var f = _make_mi(M.foundation(b.type), parent); f.position.y = -dep - 0.05; f.scale.y = dep
func _sync_buildings() -> void:
	_bdirty = false
	var alive = {}
	for b in Game.S.b:
		alive[b.id] = true
		var key = "%s|%d|%s|%s|%d" % [b.state, b.level, b.upg, b.type, b.rot]
		var e = bnodes.get(b.id)
		if e and e.key == key: continue
		if e: e.node.queue_free()
		var n = Node3D.new(); n.position = Vector3(b.x, b.y, b.z); add_child(n)
		var root = Node3D.new(); root.rotation.y = b.rot * PI / 2; n.add_child(root)
		_foundation(b, n)
		var ent = {node = n, key = key, model = null, scaf = null, fx = {flags = [], smoke = [], mill = [], crane = []}}
		if b.state == "site":
			_make_mi(M.plot(b.type), root); _make_mi(M.site(b.type), n)
			ent.model = _make_mi(M.model(b.type, 1), root); ent.scaf = _make_mi(M.scaffold(b.type), n)
		else:
			ent.model = _make_mi(M.model(b.type, b.level), root)
			if b.upg: ent.scaf = _make_mi(M.scaffold(b.type, true), n)
			var fx = M.fx_of(b.type, b.level)
			for p in fx.flags: var mi = _make_mi(M.flag(), root); mi.position = p - Vector3(0, 0.75, 0); ent.fx.flags.append(mi)
			for p in fx.mill: var mi = _make_mi(M.blade(), root); mi.position = p; ent.fx.mill.append(mi)
			for p in fx.crane: var mi = _make_mi(M.crane_arm(), root); mi.position = p; ent.fx.crane.append(mi)
			for p in fx.smoke:
				for k in 4: var mi = _make_mi(M.puff(), root); mi.position = p; mi.set_meta("base", p); mi.set_meta("k", k); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; ent.fx.smoke.append(mi)
		bnodes[b.id] = ent
	for id in bnodes.keys():
		if not alive.has(id): bnodes[id].node.queue_free(); bnodes.erase(id)
	# castelos dos outros reinos
	if world_nodes.size() != Game.world_castles.size() or (world_nodes.size() and world_nodes[0].get_meta("k") != Game.S.kingdom):
		for n in world_nodes: n.queue_free()
		world_nodes.clear()
		for w in Game.world_castles:
			var n = Node3D.new(); n.position = Vector3(w.x, w.y, w.z); n.set_meta("k", Game.S.kingdom); add_child(n)
			_foundation(w, n); var mi = _make_mi(M.model("castle", w.level), n); mi.rotation.y = w.rot * PI / 2; world_nodes.append(n)
func _animate_buildings(t: float) -> void:
	for b in Game.S.b:
		var e = bnodes.get(b.id)
		if e == null: continue
		var m: MeshInstance3D = e.model
		if b.state == "site":
			m.scale = Vector3(1, maxf(0.03, b.prog), 1)
			if e.scaf: e.scaf.visible = b.prog < 0.97; e.scaf.scale = Vector3(1, clampf(b.prog * 1.4, 0.15, 1.0), 1)
			continue
		if b.popT > 0:
			var k: float = 1 - b.popT / 0.55; var sq = 1 + sin(k * PI * 2.5) * 0.12 * (1 - k); m.scale = Vector3(sq, 1 / sq, sq)
		else: m.scale = Vector3.ONE
		if e.scaf: e.scaf.scale = Vector3(1, 0.3 + 0.7 * b.prog, 1)
		var near: bool = Vector2(b.x - target.x, b.z - target.z).length() < 260 + dist * 0.6 and dist < 700
		if not near: continue
		for f in e.fx.flags: f.rotation.y = sin(t * 2.2 + b.id + f.position.x) * 0.45 + 0.6
		for f in e.fx.mill: f.rotation.z = t * 1.4 + b.id
		for f in e.fx.crane: f.rotation.y = sin(t * 0.4 + b.id) * 1.2
		for f in e.fx.smoke:
			var u: float = fmod(t * 0.32 + f.get_meta("k") / 4.0 + b.id * 0.13, 1.0); var s = (0.35 + u * 0.9) * (1 - u * 0.4); var bp: Vector3 = f.get_meta("base")
			f.position = bp + Vector3(u * 1.4, u * 3.2, u * 0.5); f.scale = Vector3.ONE * s
func _on_log(t: String, imp: bool) -> void:
	if imp: ui.toast(t)
func _on_built(b: Dictionary) -> void:
	_bdirty = true; confetti(b)

# ---------- prévia (fantasma) da construção ----------
var ghost = null
var ghost_node: Node3D
var ghost_rot = 0
func update_ghost(t: String, px: float, pz: float) -> void:
	var c = Game.check(t, px, pz); var k = "%s%f,%f,%d%s" % [t, c.x, c.z, ghost_rot, c.ok]
	if ghost and ghost.k == k: return
	ghost = c; ghost.k = k; ghost.type = t
	if ghost_node: ghost_node.queue_free()
	if ghost_mat == null: ghost_mat = ShaderMaterial.new(); ghost_mat.shader = preload("res://shaders/building.gdshader")
	ghost_mat.set_shader_parameter("tint", Color(0.35, 1, 0.45, 0.42) if c.ok else Color(1, 0.3, 0.25, 0.5))
	var y: float = c.y if c.ok else maxf(W.mesh_h(c.x, c.z), 0) + 0.15
	ghost_node = Node3D.new(); ghost_node.position = Vector3(c.x, y, c.z); add_child(ghost_node)
	var mi = MeshInstance3D.new(); mi.mesh = M.model(t, 1); mi.material_override = ghost_mat; mi.rotation.y = ghost_rot * PI / 2; ghost_node.add_child(mi)
	ui.ghost_info(c, t)
func clear_ghost() -> void:
	ghost = null
	if ghost_node: ghost_node.queue_free(); ghost_node = null

# ---------- câmera ----------
func eff_pitch() -> float: return maxf(pitch, pitch + (1.32 - pitch) * smoothstep(500, 2200, dist))
func _update_cam() -> void:
	var ty = maxf(W.mesh_h(target.x, target.z), 0)
	target.y += (ty - target.y) * 0.3 if absf(ty - target.y) > 0.05 else (ty - target.y)
	var p = eff_pitch()
	var eye = target + Vector3(sin(yaw) * cos(p), sin(p), cos(yaw) * cos(p)) * dist
	var gy = maxf(W.mesh_h(eye.x, eye.z), 0) + 6
	if eye.y < gy: eye.y = gy
	cam.near = maxf(0.4, dist * 0.012); cam.far = dist * 4 + 3000
	cam.look_at_from_position(eye, target, Vector3.UP)
	sun.directional_shadow_max_distance = clampf(dist * 2.6, 60, 1400)
	env.fog_enabled = dist < 900
	env.fog_depth_begin = dist * 2.2 + 250; env.fog_depth_end = env.fog_depth_begin + dist * 3 + 900
func fly_to(x: float, z: float, d: float, p = null, y = null) -> void:
	fly = {k = 0.0, a = {t = target, d = dist, p = pitch, y = yaw}, b = {t = Vector3(x, 0, z), d = d, p = p if p != null else pitch, y = y if y != null else yaw}}
func _step_fly(dt: float) -> void:
	if fly == null: return
	fly.k = minf(1, fly.k + dt / 1.6); var k: float = fly.k; var e = 2 * k * k if k < 0.5 else 1 - pow(-2 * k + 2, 2) / 2
	target.x = lerpf(fly.a.t.x, fly.b.t.x, e); target.z = lerpf(fly.a.t.z, fly.b.t.z, e); dist = lerpf(fly.a.d, fly.b.d, e); pitch = lerpf(fly.a.p, fly.b.p, e); yaw = lerpf(fly.a.y, fly.b.y, e)
	if fly.k >= 1: fly = null
func zoom(f: float) -> void: fly = null; dist = clampf(dist * f, DMIN, DMAX)
func go_home() -> void:
	var c = Game.castle_b()
	if c: fly_to(c.x, c.z, 140, 0.95, 0.0)
	else: fly_to(0, 0, HOME.dist, HOME.pitch, 0.0)
func clamp_target() -> void: target.x = clampf(target.x, -W.HX, W.HX); target.z = clampf(target.z, -W.HZ, W.HZ)

# ---------- raios e seleção ----------
func pick_plane(sp: Vector2, py: float):
	var o = cam.project_ray_origin(sp); var d = cam.project_ray_normal(sp)
	if d.y > -0.0005: return null
	var t = (py - o.y) / d.y
	return Vector2(o.x + d.x * t, o.z + d.z * t) if t > 0 else null
func pick_ground(sp: Vector2):
	var o = cam.project_ray_origin(sp); var d = cam.project_ray_normal(sp)
	if d.y > -0.0005: return null
	var t = (target.y - o.y) / d.y; var px = o.x + d.x * t; var pz = o.z + d.z * t
	for j in 8:
		var h = maxf(W.mesh_h(px, pz), 0); t = (h - o.y) / d.y; px = o.x + d.x * t; pz = o.z + d.z * t
	return {x = px, z = pz, t = t}
func pick_building(sp: Vector2):
	var o = cam.project_ray_origin(sp); var d = cam.project_ray_normal(sp); var best = null; var bt = 1e9
	for b in Game.S.b:
		var h: float = M.TYPES[b.type].size * 2.0; var H: float = M.HEIGHT[b.type]
		var aabb = AABB(Vector3(b.x - h, b.minH - 1, b.z - h), Vector3(2 * h, b.y + H - b.minH + 1, 2 * h))
		var hit = aabb.intersects_ray(o, d)
		if hit != null:
			var t = (hit - o).length()
			if t < bt: bt = t; best = b
	var g = pick_ground(sp)
	if best and g and g.t < bt - 1:
		var id = Game.occ.get(Game.tkey(int(floor(g.x / 4.0)), int(floor(g.z / 4.0))))
		return Game.by_id.get(id) if id and id > 0 else null
	return best
func to_screen(p: Vector3):
	if cam.is_position_behind(p): return null
	return cam.unproject_position(p)

# ---------- gestos (toque e mouse) ----------
var touches = {}
var moved = false
var down_pos = Vector2.ZERO
var gesture = null
var multi = false
var mbtn = 0
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			fly = null; touches[ev.index] = ev.position
			if touches.size() == 1: moved = false; multi = false; down_pos = ev.position
			else: multi = true; moved = true
			gesture = null
		else:
			touches.erase(ev.index); gesture = null
			if touches.is_empty():
				if not moved and not multi: ui.tap(ev.position)
			else: down_pos = touches.values()[0]; moved = true
	elif ev is InputEventScreenDrag:
		var prev: Vector2 = touches.get(ev.index, ev.position); touches[ev.index] = ev.position
		if touches.size() == 1:
			if (ev.position - down_pos).length() > 7: moved = true
			if not moved: return
			_pan(prev, ev.position)
		elif touches.size() >= 2:
			var ks = touches.keys(); var a: Vector2 = touches[ks[0]]; var b: Vector2 = touches[ks[1]]
			var mid = (a + b) / 2; var dd = maxf((a - b).length(), 1); var ang = atan2(b.y - a.y, b.x - a.x)
			if gesture:
				dist = clampf(dist * gesture.d / dd, DMIN, DMAX); yaw -= wrapf(ang - gesture.ang, -PI, PI)
				pitch = clampf(pitch + (mid.y - gesture.my) * 0.005, 0.35, 1.45); _pan(gesture.mid, mid)
			gesture = {d = dd, ang = ang, mid = mid, my = mid.y}
	elif ev is InputEventMouseButton and ev.device != InputEvent.DEVICE_ID_EMULATION:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed: zoom(0.88)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed: zoom(1.13)
		elif ev.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			if ev.pressed: fly = null; mbtn = ev.button_index; moved = false; down_pos = ev.position
			else:
				if not moved and ev.button_index == MOUSE_BUTTON_LEFT: ui.tap(ev.position)
				mbtn = 0
	elif ev is InputEventMouseMotion and ev.device != InputEvent.DEVICE_ID_EMULATION:
		if mbtn == 0: ui.hover(ev.position); return
		if (ev.position - down_pos).length() > 7: moved = true
		if not moved: return
		if mbtn == MOUSE_BUTTON_RIGHT or ev.shift_pressed:
			yaw -= ev.relative.x * 0.007; pitch = clampf(pitch + ev.relative.y * 0.006, 0.35, 1.45)
		else: _pan(ev.position - ev.relative, ev.position)
	elif ev is InputEventMagnifyGesture: zoom(1.0 / ev.factor)
	elif ev is InputEventPanGesture: zoom(1.0 + ev.delta.y * 0.05)
func _pan(a: Vector2, b: Vector2) -> void:
	var pa = pick_plane(a, target.y); var pb = pick_plane(b, target.y)
	if pa != null and pb != null: target.x += pa.x - pb.x; target.z += pa.y - pb.y; clamp_target()

# ---------- laço principal ----------
func _process(delta: float) -> void:
	if not ready_done: return
	var dt = minf(delta, 0.5); anim_t += dt
	_step_fly(dt)
	_update_cam()
	var rem: float = 0.0 if Dyn.paused else dt * SPEED_MUL[Dyn.speed]
	while rem > 1e-4:
		var s = minf(0.1, rem); Game.sim_step(s, target, dist); rem -= s
	Game.cam_state = [target.x, target.z, dist, yaw, pitch]
	if _bdirty: _sync_buildings()
	_animate_buildings(anim_t)
	_update_trees()
	_upload_villagers(); _step_particles(dt)
	var M_: Dictionary = MODES[map_mode]
	terrain_mat.set_shader_parameter("time", anim_t); water_mat.set_shader_parameter("time", anim_t)
	terrain_mat.set_shader_parameter("fill", M_.fill * (0.25 + 0.53 * smoothstep(150, 1300, dist)))
	terrain_mat.set_shader_parameter("lines", M_.lines)
	terrain_mat.set_shader_parameter("pix", 2 * tan(PI / 6) / maxf(1, get_viewport().get_visible_rect().size.y))
	terrain_mat.set_shader_parameter("det_far", maxf(240, dist * 1.5))
	var g = ghost
	terrain_mat.set_shader_parameter("grid", Vector4(g.x if g else 0.0, g.z if g else 0.0, 42.0 if (ui.placing != "" and g) else 0.0, 1.0 if ui.placing != "" else 0.0))
	var sb = Game.by_id.get(ui.selected)
	terrain_mat.set_shader_parameter("sel", Vector4(sb.x, sb.z, M.TYPES[sb.type].size * 2.0 + 0.6, 0) if sb else Vector4.ZERO)
	ui.frame(dt)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED: Game.save()

# ---------- teste automático (godot -- --autotest): escolhe um reino, constrói e tira fotos ----------
func _autotest() -> void:
	var out := "user://"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	Game.wipe_save()
	await get_tree().create_timer(0.5).timeout
	_shot(out + "/g0.png")
	ui.modal.visible = false
	var b = Game.choose_kingdom(0)
	print("castle ", b != null)
	for i in 80: Game.sim_step(0.1, target, dist)
	Game.S.res.gold = 3000; Game.S.res.wood = 3000; Game.S.res.stone = 3000; Game.econ.cap = 9999
	var c = Game.castle_b()
	for t in ["house", "house", "farm", "lumber", "house", "well", "house", "market"]:
		var done = false
		for r in range(16, 80, 3):
			if done: break
			for k in 24:
				var a := k / 24.0 * TAU; var ck = Game.check(t, c.x + cos(a) * r, c.z + sin(a) * r)
				if ck.ok:
					Game.place_building(t, ck, k % 4); Game.S.res.gold = 3000; Game.S.res.wood = 3000; Game.S.res.stone = 3000; done = true; break
	for bb in Game.S.b:
		if bb.state == "site": bb.prog = 1.0; Game.finish_build(bb)
	for i in 600: Game.sim_step(0.1, target, dist)
	print("buildings ", Game.S.b.map(func(x): return x.type + ":" + x.state), " pop ", Game.S.pop, " vill ", Game.vill.size(), " date ", Dyn.fmt_now())
	target = Vector3(c.x, 0, c.z + 8); dist = 95; pitch = 0.85; yaw = 0.3; fly = null
	await get_tree().create_timer(1.5).timeout
	_shot(out + "/g1.png")
	target = Vector3(c.x + 6, 0, c.z + 16); dist = 34; pitch = 0.55; yaw = 0.4
	await get_tree().create_timer(1.0).timeout
	_shot(out + "/g2.png")
	await get_tree().create_timer(0.3).timeout
	ui._on_tool("build")
	await get_tree().create_timer(0.6).timeout
	_shot(out + "/g5.png")
	await get_tree().create_timer(0.3).timeout
	ui.start_placing("farm"); fly = null; target = Vector3(c.x + 20, 0, c.z + 30); dist = 90; pitch = 0.9
	update_ghost("farm", c.x + 22, c.z + 34)
	await get_tree().create_timer(0.8).timeout
	_shot(out + "/g6.png")
	await get_tree().create_timer(0.3).timeout
	ui.set_mode("select")
	target = Vector3(c.x, 0, c.z); dist = 1600; pitch = 1.2; yaw = 0
	await get_tree().create_timer(1.0).timeout
	ui.open_province(get_viewport().get_visible_rect().size / 2)
	await get_tree().create_timer(0.5).timeout
	_shot(out + "/g3.png")
	ui.open_house(Game.S.kingdom)
	await get_tree().create_timer(0.5).timeout
	_shot(out + "/g4.png")
	print("FPS ", Engine.get_frames_per_second())
	get_tree().quit()
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path); print("shot ", path)
