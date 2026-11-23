extends CanvasLayer
## Interface: recursos, calendário, objetivos, menu de construção, painéis, ficha dos reinos,
## crônica, rótulos flutuantes e tratamento dos toques. Porte de main.js + body.html + style.css.

var main
var placing = ""
var selected = 0
var mode = "select"
var MOBILE = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

var root: Control
var overlay: Control
var chips = {}
var date_lbl: Label
var play_btn: Button
var pips: Array = []
var goal_box: PanelContainer
var goal_txt: Label
var goal_prog: Label
var goal_bar: ColorRect
var goal_rew: Label
var toasts: VBoxContainer
var info: PanelContainer
var info_title: RichTextLabel
var info_body: RichTextLabel
var btn_up: Button
var btn_demo: Button
var prov_panel: PanelContainer
var prov_body: RichTextLabel
var prov_btns: HBoxContainer
var build_menu: PanelContainer
var build_cards = {}
var map_menu: PanelContainer
var confirm_bar: PanelContainer
var tools = {}
var tip: Label
var ghost_lbl: Label
var paused_tag: Label
var sheet: PanelContainer
var sheet_body: RichTextLabel
var loading: ColorRect
var load_lbl: Label
var modal: ColorRect
var region_lbls: Array = []
var floaters: Array = []
var bars = {}

const C_PANEL := Color("#1b2924ee")
const C_GOLD := Color("#f5da92")
const C_TEXT := Color("#f2e8cc")

# ---------- estilo ----------
var font: SystemFont
var serif: SystemFont
func _sb(bg: Color, border := Color(0.83, 0.75, 0.54, 0.45), r := 14, pad := 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new(); s.bg_color = bg; s.border_color = border; s.set_border_width_all(1); s.set_corner_radius_all(r)
	s.content_margin_left = pad; s.content_margin_right = pad; s.content_margin_top = pad * 0.7; s.content_margin_bottom = pad * 0.7
	s.shadow_color = Color(0, 0, 0, 0.45); s.shadow_size = 6; return s
func _theme() -> Theme:
	var emoji = SystemFont.new(); emoji.font_names = PackedStringArray(["Noto Color Emoji", "Apple Color Emoji", "Segoe UI Emoji"])
	font = SystemFont.new(); font.font_names = PackedStringArray(["Noto Sans", "Roboto", "Segoe UI", "DejaVu Sans", "Sans-Serif"]); font.fallbacks = [emoji]
	serif = SystemFont.new(); serif.font_names = PackedStringArray(["Cinzel", "Palatino Linotype", "Book Antiqua", "Georgia", "Noto Serif", "DejaVu Serif", "Serif"]); serif.font_weight = 700; serif.fallbacks = [emoji]
	var t = Theme.new(); t.default_font = font; t.default_font_size = 15
	t.set_color("font_color", "Label", C_TEXT); t.set_color("default_color", "RichTextLabel", C_TEXT)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var c = Color("#2a3a33") if st == "normal" else (Color("#36503f") if st == "hover" else (Color("#ad8b38aa") if st == "pressed" else Color("#2a3a33")))
		t.set_stylebox(st, "Button", _sb(c, Color(0.77, 0.72, 0.5, 0.5), 11, 9))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color("#efdfb9")); t.set_color("font_hover_color", "Button", Color.WHITE); t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_stylebox("panel", "PanelContainer", _sb(C_PANEL)); t.set_stylebox("panel", "Panel", _sb(C_PANEL))
	return t
func _label(txt := "", size := 15, col := C_TEXT, f: Font = null) -> Label:
	var l = Label.new(); l.text = txt; l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	if f: l.add_theme_font_override("font", f)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; return l
func _btn(txt: String, cb: Callable, size := 15, style := "") -> Button:
	var b = Button.new(); b.text = txt; b.add_theme_font_size_override("font_size", size); b.pressed.connect(cb); b.focus_mode = Control.FOCUS_NONE
	if style == "gold":
		for st in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(st, _sb(Color("#f0c050") if st != "pressed" else Color("#d9a03a"), Color("#9c7d48"), 11, 10))
		b.add_theme_color_override("font_color", Color("#3a2408")); b.add_theme_color_override("font_hover_color", Color("#2a1804")); b.add_theme_color_override("font_pressed_color", Color("#2a1804"))
	elif style == "red":
		for st in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(st, _sb(Color("#c9533f") if st != "pressed" else Color("#a33d2c"), Color("#7a2a1c"), 11, 10))
		b.add_theme_color_override("font_color", Color.WHITE)
	return b
func _rich(size := 14) -> RichTextLabel:
	var r = RichTextLabel.new(); r.bbcode_enabled = true; r.fit_content = true; r.scroll_active = false; r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size); r.add_theme_color_override("default_color", C_TEXT); r.mouse_filter = Control.MOUSE_FILTER_PASS; return r
func _panel(parent: Control, bg := C_PANEL) -> PanelContainer:
	var p = PanelContainer.new(); p.add_theme_stylebox_override("panel", _sb(bg)); parent.add_child(p); return p
func _anchor(c: Control, preset: int, margin := Vector2.ZERO) -> void:
	c.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE); c.position += margin

# ---------- construção da interface ----------
func _ready() -> void:
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.theme = _theme(); add_child(root)
	overlay = Control.new(); overlay.set_anchors_preset(Control.PRESET_FULL_RECT); overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(overlay)
	_build_top(); _build_goal(); _build_side(); _build_bottom(); _build_sheet(); _build_modal()
	toasts = VBoxContainer.new(); toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE; toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	toasts.set_anchors_preset(Control.PRESET_CENTER_TOP); toasts.position = Vector2(-260, 64); toasts.custom_minimum_size = Vector2(520, 0); root.add_child(toasts)
	loading = ColorRect.new(); loading.color = Color("#10231c"); loading.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(loading)
	var vb = VBoxContainer.new(); vb.set_anchors_preset(Control.PRESET_CENTER); vb.alignment = BoxContainer.ALIGNMENT_CENTER; loading.add_child(vb)
	vb.add_child(_label("⚜ REINOS 3D", 30, Color("#f9e5a9"), serif)); load_lbl = _label("Carregando…", 15, Color("#e9d9a8")); vb.add_child(load_lbl)
	for l in vb.get_children(): l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.position = Vector2(-160, -30); vb.custom_minimum_size = Vector2(320, 60)

func _build_top() -> void:
	var bar = HBoxContainer.new(); bar.set_anchors_preset(Control.PRESET_TOP_WIDE); bar.offset_left = 10; bar.offset_right = -10; bar.offset_top = 8
	bar.add_theme_constant_override("separation", 8); bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(bar)
	var brand = VBoxContainer.new(); brand.mouse_filter = Control.MOUSE_FILTER_IGNORE; bar.add_child(brand)
	brand.add_child(_label("⚜ REINOS 3D", 17, Color("#f9e5a9"), serif)); brand.add_child(_label("61 REINOS INDEPENDENTES", 9, Color("#bad3bc")))
	var clock = _panel(bar, Color("#1e2b26e6")); var ch = HBoxContainer.new(); ch.add_theme_constant_override("separation", 8); clock.add_child(ch)
	play_btn = _btn("▶", func(): Dyn.toggle(), 16); play_btn.custom_minimum_size = Vector2(36, 34); ch.add_child(play_btn)
	var dv = VBoxContainer.new(); dv.add_theme_constant_override("separation", 2); ch.add_child(dv)
	date_lbl = _label("1º de Janeiro, 1000", 14, Color("#f7e6b4"), serif); dv.add_child(date_lbl)
	var ph = HBoxContainer.new(); ph.add_theme_constant_override("separation", 4); dv.add_child(ph)
	for s in range(1, 6):
		var b = Button.new(); b.custom_minimum_size = Vector2(18, 9); b.focus_mode = Control.FOCUS_NONE; var sp = s
		b.pressed.connect(_on_pip.bind(sp))
		ph.add_child(b); pips.append(b)
	Dyn.changed.connect(_update_clock); _update_clock()
	var sp2 = Control.new(); sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE; bar.add_child(sp2)
	for k in [["gold", "🪙"], ["wood", "🌲"], ["stone", "🪨"], ["food", "🌾"], ["pop", "👥"], ["hap", "🙂"]]:
		var p = _panel(bar, Color("#22352ef2")); p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 5); p.add_child(h)
		var ic = _label(k[1], 20); h.add_child(ic)
		var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 0); h.add_child(v)
		var val = _label("0", 15, Color("#fff3cf")); var rate = _label("", 10, Color("#9fe08a")); v.add_child(val); v.add_child(rate)
		var fill = ColorRect.new(); fill.color = Color("#f0c050"); fill.custom_minimum_size = Vector2(0, 3); fill.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_child(fill)
		chips[k[0]] = {val = val, rate = rate, icon = ic, fill = fill}

func _on_pip(sp: int) -> void:
	Dyn.set_speed(sp)
	if Dyn.paused: Dyn.resume()
func _update_clock() -> void:
	date_lbl.text = Dyn.fmt_now(); play_btn.text = "▶" if Dyn.paused else "⏸"
	for i in pips.size():
		var on: bool = i < Dyn.speed
		pips[i].add_theme_stylebox_override("normal", _sb(Color("#e2b65a") if on and not Dyn.paused else (Color("#9b8a62") if on else Color("#ffffff22")), Color(0, 0, 0, 0), 2, 0))
	if paused_tag: paused_tag.visible = Dyn.paused and Game.S.kingdom >= 0

func _build_goal() -> void:
	goal_box = _panel(root, Color("#3a2c1aee")); goal_box.position = Vector2(10, 70); goal_box.custom_minimum_size = Vector2(270, 0)
	var v = VBoxContainer.new(); goal_box.add_child(v)
	var h = HBoxContainer.new(); v.add_child(h); h.add_child(_label("📜 OBJETIVO", 11, Color("#f2cf7a")))
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(sp); goal_prog = _label("", 11, Color.WHITE); h.add_child(goal_prog)
	goal_txt = _label("", 14); goal_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; goal_txt.custom_minimum_size = Vector2(250, 0); v.add_child(goal_txt)
	var bg = ColorRect.new(); bg.color = Color(0, 0, 0, 0.4); bg.custom_minimum_size = Vector2(250, 6); v.add_child(bg)
	goal_bar = ColorRect.new(); goal_bar.color = Color("#f0c050"); goal_bar.size = Vector2(0, 6); bg.add_child(goal_bar)
	goal_rew = _label("", 11, Color("#c1cdbd")); v.add_child(goal_rew)
	goal_box.gui_input.connect(_on_goal_input.bind(bg))
func _on_goal_input(e: InputEvent, bg: Control) -> void:
	if e is InputEventMouseButton and e.pressed:
		goal_txt.visible = not goal_txt.visible; goal_rew.visible = goal_txt.visible; bg.visible = goal_txt.visible

func _build_side() -> void:
	# painel da construção selecionada
	info = _panel(root); info.set_anchors_preset(Control.PRESET_TOP_RIGHT); info.custom_minimum_size = Vector2(310, 0); info.position = Vector2(-320, 70); info.visible = false
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 6); info.add_child(v)
	var h = HBoxContainer.new(); v.add_child(h); info_title = _rich(17); info_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(info_title)
	h.add_child(_btn("✕", close_info, 13))
	info_body = _rich(13); info_body.custom_minimum_size = Vector2(290, 0); info_body.meta_clicked.connect(_on_meta); v.add_child(info_body)
	var acts = HBoxContainer.new(); acts.add_theme_constant_override("separation", 8); v.add_child(acts)
	btn_up = _btn("⬆ Melhorar", _on_upgrade, 14, "gold"); btn_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL; acts.add_child(btn_up)
	btn_demo = _btn("🗑 Demolir", _on_demolish, 14, "red"); btn_demo.size_flags_horizontal = Control.SIZE_EXPAND_FILL; acts.add_child(btn_demo)
	# ficha da província
	prov_panel = _panel(root); prov_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT); prov_panel.custom_minimum_size = Vector2(310, 0); prov_panel.position = Vector2(-320, 70); prov_panel.visible = false
	var pv = VBoxContainer.new(); pv.add_theme_constant_override("separation", 6); prov_panel.add_child(pv)
	prov_body = _rich(13); prov_body.custom_minimum_size = Vector2(290, 0); pv.add_child(prov_body)
	prov_btns = HBoxContainer.new(); prov_btns.add_theme_constant_override("separation", 6); pv.add_child(prov_btns)
	# controles da câmera
	var ctr = VBoxContainer.new(); ctr.set_anchors_preset(Control.PRESET_CENTER_RIGHT); ctr.position = Vector2(-58, -110); ctr.add_theme_constant_override("separation", 8); root.add_child(ctr)
	for b in [["+", func(): main.zoom(0.7)], ["−", func(): main.zoom(1.43)], ["📜", open_chronicle], ["⌂", func(): main.go_home()]]:
		var bt = _btn(b[0], b[1], 20); bt.custom_minimum_size = Vector2(46, 46); ctr.add_child(bt)

func _build_bottom() -> void:
	tip = _label("👑 Toque numa província para ver qual reino a governa", 13); tip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); tip.position = Vector2(12, -36); root.add_child(tip)
	paused_tag = _label("Pausado", 16, Color("#f2e2b8"), serif); paused_tag.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); paused_tag.position = Vector2(-36, -122); paused_tag.visible = false; root.add_child(paused_tag)
	ghost_lbl = _label("", 14); ghost_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); ghost_lbl.position = Vector2(-140, -190); ghost_lbl.visible = false; root.add_child(ghost_lbl)
	var tb = _panel(root, Color("#1d2c27ed")); tb.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); tb.position = Vector2(-190, -78)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 6); tb.add_child(h)
	for t in [["select", "☝\nExplorar"], ["build", "🔨\nConstruir"], ["demolish", "🗑\nDemolir"], ["map", "🗺\nMapa"]]:
		var key: String = t[0]; var b = _btn(t[1], func(): _on_tool(key), 13); b.custom_minimum_size = Vector2(84, 58); h.add_child(b); tools[key] = b
	build_menu = _panel(root, Color("#1d2c27f2")); build_menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); build_menu.visible = false
	var sc = ScrollContainer.new(); sc.custom_minimum_size = Vector2(820, 128); sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; build_menu.add_child(sc)
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 7); sc.add_child(row)
	for t in Game.BUILD_ORDER:
		var T: Dictionary = M.TYPES[t]; var tt: String = t
		var b = Button.new(); b.custom_minimum_size = Vector2(98, 116); b.focus_mode = Control.FOCUS_NONE; b.pressed.connect(func(): start_placing(tt))
		for st in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(st, _sb(Color("#f2e6c8") if st != "pressed" else Color("#e0cc9c"), Color("#9c7d48"), 12, 6))
		var v = VBoxContainer.new(); v.set_anchors_preset(Control.PRESET_FULL_RECT); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.alignment = BoxContainer.ALIGNMENT_CENTER; b.add_child(v)
		var ic = _label(T.icon, 28); var nm = _label(T.name, 12, Color("#3a2a18")); var cs = _rich(11); cs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cs.add_theme_color_override("default_color", Color("#3a2a18")); cs.custom_minimum_size = Vector2(92, 0)
		for l in [ic, nm]: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(ic); v.add_child(nm); v.add_child(cs); row.add_child(b); build_cards[t] = {btn = b, cs = cs}
	map_menu = _panel(root, Color("#1d2c27f2")); map_menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); map_menu.visible = false
	var mh = HBoxContainer.new(); mh.add_theme_constant_override("separation", 6); map_menu.add_child(mh)
	for m in [["terrain", "🗺\nTerreno"], ["provinces", "🧩\nProvíncias"], ["houses", "👑\nReinos"], ["regions", "🧭\nRegiões"]]:
		var mk: String = m[0]; var b = _btn(m[1], func(): main.set_map_mode(mk); map_menu.visible = false; toast("Mapa: " + main.MODES[mk].name), 13); b.custom_minimum_size = Vector2(88, 58); mh.add_child(b)
	confirm_bar = _panel(root, Color("#1d2c27f2")); confirm_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); confirm_bar.visible = false
	var ch = HBoxContainer.new(); ch.add_theme_constant_override("separation", 8); confirm_bar.add_child(ch)
	ch.add_child(_btn("⟲ Girar", rotate_ghost, 15)); ch.add_child(_btn("✔ Construir", confirm_place, 16, "gold")); ch.add_child(_btn("✕", func(): set_mode("select"), 15, "red"))

func _build_sheet() -> void:
	sheet = _panel(root, Color("#16231ef5")); sheet.set_anchors_preset(Control.PRESET_CENTER); sheet.custom_minimum_size = Vector2(620, 520); sheet.position = Vector2(-310, -260); sheet.visible = false
	var v = VBoxContainer.new(); sheet.add_child(v)
	var h = HBoxContainer.new(); v.add_child(h); var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(sp); h.add_child(_btn("✕", func(): sheet.visible = false, 14))
	var sc = ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; v.add_child(sc)
	sheet_body = _rich(14); sheet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sheet_body.meta_clicked.connect(_on_meta); sc.add_child(sheet_body)

func _build_modal() -> void:
	modal = ColorRect.new(); modal.color = Color(0, 0, 0, 0.5); modal.set_anchors_preset(Control.PRESET_FULL_RECT); modal.visible = false; root.add_child(modal)

func _show_modal(icon: String, title: String, text: String, btn: String, cb: Callable) -> void:
	for c in modal.get_children(): c.queue_free()
	var p = _panel(modal, Color("#f2e6c8")); p.set_anchors_preset(Control.PRESET_CENTER); p.custom_minimum_size = Vector2(430, 0)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 10); p.add_child(v)
	for l in [_label(icon, 52), _label(title, 24, Color("#3a2a18"), serif)]: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l)
	var r = _rich(15); r.add_theme_color_override("default_color", Color("#3a2a18")); r.text = "[center]" + text + "[/center]"; r.custom_minimum_size = Vector2(400, 0); v.add_child(r)
	var b = _btn(btn, func(): modal.visible = false; cb.call(), 17, "gold"); b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; v.add_child(b)
	modal.visible = true
	await get_tree().process_frame; p.position = (root.size - p.size) / 2

# ---------- API usada pela cena ----------
func set_loading(t: String) -> void: if load_lbl: load_lbl.text = t
func hide_loading() -> void:
	var tw = create_tween(); tw.tween_property(loading, "modulate:a", 0.0, 0.4); tw.tween_callback(loading.queue_free)
func show_intro() -> void:
	_show_modal("👑", "Escolha o seu reino", "O continente está dividido em [b]61 reinos independentes[/b], cada um com suas províncias, sua capital e sua dinastia.\n\nToque numa província e em [b]“Governar este reino”[/b]. Seu castelo será erguido na capital e você poderá construir em todas as províncias do seu reino.\n\n[color=#6a5536][font_size=12]Arraste para mover • pinça para aproximar • dois dedos (ou botão direito) giram[/font_size][/color]", "Escolher no mapa", func(): tip.text = "👑 Toque numa província do reino que você quer governar"; toast("Toque numa província e depois em “Governar este reino”"))
func show_back(away: float, gains: Dictionary) -> void:
	var h = int(away / 3600); var m = int(fmod(away, 3600) / 60); var g = ""
	for k in Game.RES:
		if gains.get(k, 0) >= 1: g += "%s +%s   " % [Game.RICON[k], Game.fmt(gains[k])]
	_show_modal("👑", "Bem-vindo de volta!", "Você ficou fora por [b]%s%d min[/b].\nSeu povo continuou trabalhando:\n\n[font_size=18][b]%s[/b][/font_size]" % ["%dh " % h if h else "", m, g], "Coletar", func(): pass)
func ready_game() -> void:
	_update_hud(); _build_region_labels(); _update_clock()

func toast(msg: String) -> void:
	var p = _panel(toasts, Color("#10261bf0")); p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l = _label(msg, 14, Color("#f9e7b7")); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	while toasts.get_child_count() > 3: toasts.get_child(0).free()
	var tw = create_tween(); tw.tween_interval(2.6); tw.tween_property(p, "modulate:a", 0.0, 0.4); tw.tween_callback(p.queue_free)

func float_text(pos: Vector3, txt: String) -> void:
	if floaters.size() > 40: return
	var l = _label(txt, 17, Color("#fff6d0")); l.add_theme_color_override("font_outline_color", Color("#6a4a12")); l.add_theme_constant_override("outline_size", 6)
	l.visible = false; overlay.add_child(l); floaters.append({p = pos, l = l, t = 0.0})

func ghost_info(c: Dictionary, t: String) -> void:
	var d: Dictionary = Game.DEF[t]
	var ef = " • Rendimento %d%%" % int(c.e * 100) if d.has("job") and d.job != "happy" else ""
	ghost_lbl.text = (M.TYPES[t].name + ef) if c.ok else ("⛔ " + c.why)
	ghost_lbl.add_theme_color_override("font_color", C_TEXT if c.ok else Color("#ff9b85")); ghost_lbl.visible = true

# ---------- modos e construção ----------
func _on_tool(k: String) -> void:
	if k == "select": set_mode("select"); build_menu.visible = false
	elif k == "build":
		if Game.S.kingdom < 0: toast("👑 Primeiro toque numa província e escolha o seu reino"); return
		build_menu.visible = not build_menu.visible; map_menu.visible = false
		if build_menu.visible: _render_menu(); close_info()
	elif k == "demolish": set_mode("demolish"); build_menu.visible = false
	elif k == "map": map_menu.visible = not map_menu.visible; build_menu.visible = false
	_layout_bottom()
func set_mode(m: String) -> void:
	mode = m
	if m != "build": placing = ""; main.clear_ghost(); confirm_bar.visible = false; ghost_lbl.visible = false; main.rebuild_political()
	tip.text = "🗑 Toque numa construção para demolir (devolve 50%)" if m == "demolish" else ("🏗 Escolha um local dentro das províncias do seu reino" if m == "build" else "☝ Toque numa construção para ver detalhes e melhorar")
	for k in tools: tools[k].add_theme_stylebox_override("normal", _sb(Color("#ad8b3860") if k == m else Color("#2a3a33"), Color("#d4b765") if k == m else Color(0.77, 0.72, 0.5, 0.5), 11, 9))
	_layout_bottom()
func start_placing(t: String) -> void:
	var d: Dictionary = Game.DEF[t]
	if Game.castle_l() < d.unlock: toast("🔒 Requer castelo nível %d" % d.unlock); return
	if not Game.can_pay(Game.cost_of(t, 1)): toast("Recursos insuficientes")
	placing = t; set_mode("build"); build_menu.visible = false
	tip.text = "🏗 %s %s: %s" % [M.TYPES[t].icon, M.TYPES[t].name, "toque no mapa para posicionar" if MOBILE else "clique no mapa para construir • R gira"]
	var c = Game.castle_b()
	if c and main.dist > 220: main.fly_to(c.x, c.z, 170, 0.95)
	_layout_bottom()
func confirm_place() -> void:
	var g = main.ghost
	if g == null or placing == "": return
	if not g.ok: toast("⛔ " + g.why); return
	var t = placing; var b = Game.place_building(t, g, main.ghost_rot)
	if b == null: return
	main.clear_ghost(); confirm_bar.visible = false; ghost_lbl.visible = false
	if not Game.can_pay(Game.cost_of(t, 1)): set_mode("select")
	_layout_bottom()
func rotate_ghost() -> void:
	main.ghost_rot = (main.ghost_rot + 1) % 4
	if main.ghost: var x: float = main.ghost.x; var z: float = main.ghost.z; main.ghost = null; main.update_ghost(placing, x, z)
func _render_menu() -> void:
	var cl = Game.castle_l()
	for t in build_cards:
		var e: Dictionary = build_cards[t]; var d: Dictionary = Game.DEF[t]; var c: Array = Game.cost_of(t, 1); var locked: bool = cl < d.unlock
		e.btn.modulate = Color(0.6, 0.6, 0.6, 0.75) if locked else (Color(1, 1, 1, 0.85) if not Game.can_pay(c) else Color.WHITE)
		e.cs.text = "[center][color=#7a5a30]🔒 Castelo nv. %d[/color][/center]" % d.unlock if locked else "[center]" + cost_bb(c, "#3a2a18") + "[/center]"
func cost_bb(c: Array, ok_col := "#f2e8cc") -> String:
	var s = ""
	for i in 3:
		if c[i]: s += "[color=%s]%s%s[/color] " % [ok_col if Game.S.res[Game.RES[i]] >= c[i] else "#c43a2a", Game.RICON[Game.RES[i]], Game.fmt(c[i])]
	return s if s else "grátis"
func _layout_bottom() -> void:
	await get_tree().process_frame
	for p in [build_menu, map_menu, confirm_bar]:
		if p.visible: p.position = Vector2((root.size.x - p.size.x) / 2, root.size.y - p.size.y - 88)

# ---------- painel da construção ----------
func close_info() -> void: info.visible = false; selected = 0
func select(b) -> void:
	selected = b.id if b else 0
	if b == null: close_info(); return
	prov_panel.visible = false; _refresh_info(); info.visible = true; build_menu.visible = false
func _stars(n: int, m: int) -> String:
	var s = ""
	for i in range(1, m + 1): s += "★" if i <= n else "☆"
	return s
var _sig = ""
func _refresh_info(soft := false) -> void:
	var b = Game.by_id.get(selected)
	if b == null: close_info(); return
	var T: Dictionary = M.TYPES[b.type]; var d: Dictionary = Game.DEF[b.type]; var L: int = b.level; var rows = []
	if b.state == "site": rows.append("[color=#c1cdbd]Em construção… %d%% — toque no canteiro para ajudar![/color]" % int(b.prog * 100))
	else:
		if b.type == "castle":
			var fh: Dictionary = W.F.houses[Game.S.kingdom]; var Lr: Dictionary = Dyn.leader(Game.S.kingdom)
			rows.append("[b]%s[/b] • %d províncias" % [fh.name, fh.n])
			rows.append("Monarca: [b]%s %s[/b] (%d anos)" % [Dyn.title(Lr), Dyn.nm(Lr), Dyn.age(Lr)])
			rows.append("Impostos: [b]+%.1f 🪙/s[/b] • Moradia: [b]6[/b]" % (0.4 + 0.25 * (L - 1) + 0.025 * Game.S.pop))
			rows.append("Construtores: [b]%d[/b]   [url=h:%d][color=#e8c773]👑 Ver a dinastia[/color][/url]" % [Game.econ.builders, Game.S.kingdom])
			var nx = []
			for t in Game.BUILD_ORDER:
				if Game.DEF[t].unlock == L + 1: nx.append(M.TYPES[t].icon + " " + M.TYPES[t].name)
			if nx.size(): rows.append("[color=#c1cdbd]Próximo nível libera: %s[/color]" % ", ".join(nx))
		if b.type == "house": rows.append("Moradores: [b]%d/%d[/b]" % [Game.vill.filter(func(v): return v.home == b.id).size(), 4 + 2 * (L - 1)])
		if d.has("job") and d.job != "happy":
			rows.append("Produção: [b]+%.2f %s/s[/b]" % [b.rate * b.workers, Game.RICON[d.job]])
			rows.append("Trabalhadores: [b]%d/%d[/b] • Rendimento do terreno: [b]%d%%[/b]" % [b.workers, Game.slots_of(b), int(b.e * 100)])
		match b.type:
			"tavern": rows.append("Felicidade: [b]+%d%%[/b] • Atendentes: %d/%d" % [8 + 5 * L, b.workers, Game.slots_of(b)])
			"well": rows.append("Felicidade: [b]+%d%%[/b]" % (3 + 2 * L))
			"market": rows.append("Felicidade: [b]+%d%%[/b]" % (2 * L))
			"warehouse": rows.append("Capacidade extra: [b]+%d[/b]" % (500 * L))
			"tower": rows.append("Felicidade: [b]+%d%%[/b] (segurança)" % (2 + 2 * L))
		if b.upg: rows.append("[color=#c1cdbd]Melhorando para o nível %d… %d%%[/color]" % [L + 1, int(b.prog * 100)])
	var can_up: bool = b.state == "done" and not b.upg and L < T.max
	var c = Game.cost_of(b.type, L if b.type == "castle" else L + 1) if can_up else null
	var sig = "%d|%s|%d|%s|%d|%d|%d|%s|%d" % [b.id, b.state, L, b.upg, int(b.prog * 100), b.workers, int(b.rate * 100), can_up and Game.can_pay(c), Game.S.pop]
	if soft and sig == _sig: return
	_sig = sig
	info_title.text = "%s %s [color=#ffd34d][font_size=13]%s[/font_size][/color]" % [T.icon, T.name, _stars(L, T.max)]
	info_body.text = "[color=#d8d2bd][font_size=12]%s[/font_size][/color]\n" % d.desc + "\n".join(rows)
	btn_up.visible = can_up
	if can_up: btn_up.text = "⬆ Melhorar  " + _plain_cost(c); btn_up.modulate = Color.WHITE if Game.can_pay(c) else Color(0.75, 0.75, 0.75)
	btn_demo.visible = b.type != "castle"
func _plain_cost(c: Array) -> String:
	var s = ""
	for i in 3:
		if c[i]: s += "%s%s " % [Game.RICON[Game.RES[i]], Game.fmt(c[i])]
	return s
var _demo_sure = false
func _on_upgrade() -> void:
	var b = Game.by_id.get(selected)
	if b: Game.upgrade_building(b); _refresh_info()
func _on_demolish() -> void:
	var b = Game.by_id.get(selected)
	if b == null: return
	if not _demo_sure:
		_demo_sure = true; btn_demo.text = "Confirmar?"
		get_tree().create_timer(2.5).timeout.connect(func(): _demo_sure = false; btn_demo.text = "🗑 Demolir"); return
	_demo_sure = false; btn_demo.text = "🗑 Demolir"; Game.demolish(b); close_info()

# ---------- províncias e reinos ----------
func _dot(c: String) -> String: return "[color=%s]■[/color] " % c
func open_province(sp: Vector2) -> void:
	var p = main.pick_ground(sp)
	if p == null: return
	var id = W.prov_at(p.x, p.z)
	if id < 0: prov_panel.visible = false; main.sel_prov = -1; main.rebuild_political(); return
	main.sel_prov = id; main.rebuild_political()
	var pr: Array = W.F.prov[id]; var hi = int(pr[2]); var h: Dictionary = W.F.houses[hi]; var rg: Dictionary = W.F.regions[int(h.region)]
	var cnt = [0, 0, 0, 0, 0]
	for nb in W.NEIGH[id]: cnt[nb[1]] += 1
	var n_land: int = cnt[0] + cnt[1] + cnt[2]; var Lr: Dictionary = Dyn.leader(hi); var mine: bool = hi == Game.S.kingdom
	var extra = []
	if cnt[1]: extra.append("%d com rio" % cnt[1])
	if cnt[2]: extra.append("%d por estreito" % cnt[2])
	var sea = []
	if cnt[3]: sea.append("%d por travessia" % cnt[3])
	if cnt[4]: sea.append("%d além-mar" % cnt[4])
	var t = "[font_size=17][color=#f5da92][b]🧩 Província %s[/b][/color][/font_size]\n" % String(W.F.ids[id]).trim_prefix("TRT").lstrip("0")
	t += _dot(h.color) + "[b][color=#fee3a0]%s[/color][/b]%s\n" % [h.name, "  [color=#ffe7a8](seu reino)[/color]" if mine else ""]
	t += "[color=#c1cdbd][font_size=12]%d províncias%s[/font_size][/color]\n" % [h.n, " · [b]capital do reino[/b]" if int(h.seat) == id else ""]
	t += "Região: %s%s\nMonarca: [b][color=#fee3a0]%s %s (%d)[/color][/b]\n" % [_dot(rg.color), rg.name, Dyn.title(Lr), Dyn.nm(Lr), Dyn.age(Lr)]
	t += "Vizinhas por terra: [b]%d[/b]%s\n" % [n_land, " [color=#c1cdbd](%s)[/color]" % ", ".join(extra) if extra.size() else ""]
	if sea.size(): t += "[color=#c1cdbd]🚢 Pelo mar: %s[/color]\n" % " · ".join(sea)
	t += "[color=#c1cdbd][font_size=12]%s · %d m[/font_size][/color]" % [W.CLASS_NAMES[W.class_at(p.x, p.z)], int(maxf(W.mesh_h(p.x, p.z), 0) * 10)]
	prov_body.text = t
	for c in prov_btns.get_children(): c.queue_free()
	if Game.S.kingdom < 0: prov_btns.add_child(_btn("👑 Governar", func(): _choose(hi), 14, "gold"))
	prov_btns.add_child(_btn("📍 Ir até", func(): var a = W.anchor_of(id); main.fly_to(a.x, a.y, minf(main.dist, 320)), 13))
	prov_btns.add_child(_btn("👑 Reino", func(): prov_panel.visible = false; open_house(hi), 13))
	prov_btns.add_child(_btn("✕", func(): _close_prov(), 13))
	prov_panel.visible = true; info.visible = false
func _close_prov() -> void:
	prov_panel.visible = false
	if main.sel_prov >= 0: main.sel_prov = -1; main.rebuild_political()
func _choose(h: int) -> void:
	var b = Game.choose_kingdom(h)
	if b == null: return
	_close_prov(); main.sel_prov = -1; main.rebuild_political(); main.fly_to(b.x, b.z, 130, 0.9); set_mode("select"); _update_clock()

func _person(c: Dictionary, rel: String, h: int, heir_id: int) -> String:
	var a = Dyn.age(c); var tags = ""
	if c.id == heir_id: tags += " [bgcolor=#c99a3c55][color=#ffe7a8] herdeiro [/color][/bgcolor]"
	if Dyn.is_leader(c): tags += " [bgcolor=#7a5a2499][color=#ffeec4] líder [/color][/bgcolor]"
	if c.dyn != h: tags += " [color=#d8d2bd](%s %s)[/color]" % ["nascido" if c.s == "M" else "nascida", Dyn.H[c.dyn].surname]
	var at = Dyn.att_shown(c); var atts = ""
	for i in 4: atts += "%s %d  " % [Dyn.ATT_IC[i], at[i]]
	var sex = "[color=#8fb7e0]♂[/color]" if c.s == "M" else "[color=#e3a2c0]♀[/color]"
	var head = "%s [b]%s[/b]%s [color=#c1cdbd]%s · %s[/color]%s" % [sex, Dyn.nm(c), " †" if not c.alive else "", rel, ("morreu aos %d" % a) if not c.alive else ("%d anos" % a), tags]
	var tr = " · ".join(c.tr) if c.tr.size() else ("criança" if a < 16 and c.alive else "")
	var line = "%s\n   [font_size=12][color=#cfd8cc]%s[/color][color=#e6cf8f]%s[/color][/font_size]" % [head, atts, tr]
	return ("[color=#ffffff88]%s[/color]" % line if not c.alive else line) + "\n"
func open_house(h: int) -> void:
	var fh: Dictionary = W.F.houses[h]; var L: Dictionary = Dyn.leader(h); var heir = Dyn.heir_for(h); var rg: Dictionary = W.F.regions[int(fh.region)]
	var heir_id: int = heir.id if heir else -1; var seen = {L.id: true}
	var grp = func(title: String, lst: Array) -> String:
		var rows = ""
		for x in lst:
			if x == null or seen.has(x.c.id): continue
			seen[x.c.id] = true; rows += _person(x.c, x.rel, h, heir_id)
		return ("\n[color=#d9c387][font_size=12]%s[/font_size][/color]\n%s" % [title.to_upper(), rows]) if rows else ""
	var C = Dyn.C; var kids = []; var grand = []; var par = []; var sibs = []; var court = []
	for i in L.kids: kids.append(C[i])
	for k in kids:
		for i in k.kids:
			if C[i].alive: grand.append(C[i])
	for i in [L.pai, L.mae]:
		if i >= 0: par.append(C[i])
	var sid = {}
	for p in par:
		for i in p.kids:
			if i != L.id and not sid.has(i): sid[i] = true; sibs.append(C[i])
	for c in C:
		if c.alive and c.court == h: court.append(c)
	var at = Dyn.att_shown(L); var atts = ""
	for i in 4: atts += "%s [b]%d[/b] %s    " % [Dyn.ATT_IC[i], at[i], Dyn.ATT[i]]
	var t = "%s[font_size=19][color=#f5da92][b]%s[/b][/color][/font_size]\n[color=#c1cdbd][font_size=12]Reino independente · %d províncias · Região: %s[/font_size][/color]\n\n" % [_dot(fh.color), fh.name, fh.n, rg.name]
	t += "[color=#c1cdbd]%s[/color]\n[font_size=20][color=#fbe6ae][b]%s[/b][/color][/font_size]\n[color=#c1cdbd][font_size=12]%d anos · %s em %s[/font_size][/color]\n%s\n" % [Dyn.title(L), Dyn.full_name(L), Dyn.age(L), "nascido" if L.s == "M" else "nascida", Dyn.fmt_date(L.bd), atts]
	t += "[color=#e6cf8f]%s[/color] · Saúde %d%%\n" % [" · ".join(L.tr) if L.tr.size() else "—", int(L.hp)]
	t += "Herdeiro(a): %s\n" % (("[b]%s[/b] [color=#c1cdbd](%d anos)[/color]" % [Dyn.nm(heir), Dyn.age(heir)]) if heir else "[b]nenhum[/b] [color=#c1cdbd]— o reino corre risco![/color]")
	t += grp.call("Cônjuge", [{c = C[L.cj], rel = "esposa" if L.s == "M" else "marido"}] if L.cj >= 0 else [])
	t += grp.call("Filhos", kids.map(func(c): return {c = c, rel = "filho" if c.s == "M" else "filha"}))
	t += grp.call("Netos", grand.map(func(c): return {c = c, rel = "neto" if c.s == "M" else "neta"}))
	t += grp.call("Pais", par.map(func(c): return {c = c, rel = "pai" if c.s == "M" else "mãe"}))
	t += grp.call("Irmãos", sibs.map(func(c): return {c = c, rel = "irmão" if c.s == "M" else "irmã"}))
	t += grp.call("Outros na corte", court.map(func(c): return {c = c, rel = "parente" if c.dyn == h else "cônjuge de parente"}))
	sheet_body.text = t; sheet.visible = true; _center_sheet()
func open_chronicle() -> void:
	var t = "[font_size=19][color=#f5da92][b]📜 Crônica dos Reinos[/b][/color][/font_size]\n[color=#c1cdbd][font_size=12]%d nobres vivos nos 61 reinos[/font_size][/color]\n\n" % Dyn.alive_count()
	if Dyn.LOG.is_empty(): t += "[color=#c1cdbd]Nada aconteceu ainda. Solte o tempo (▶) para a história começar.[/color]"
	for e in Dyn.LOG:
		t += "[color=#c1cdbd][font_size=11]%s[/font_size][/color]\n%s%s\n\n" % [Dyn.fmt_date(e.day), e.txt, ("  [url=h:%d][color=#e8c773][font_size=11]ver reino[/font_size][/color][/url]" % e.h) if e.h >= 0 else ""]
	sheet_body.text = t; sheet.visible = true; _center_sheet()
func _center_sheet() -> void:
	var w = minf(620, root.size.x - 20); var h = minf(560, root.size.y - 80)
	sheet.custom_minimum_size = Vector2(w, h); sheet.size = Vector2(w, h); sheet.position = Vector2((root.size.x - w) / 2, 60)
func _on_meta(meta) -> void:
	var s = str(meta)
	if s.begins_with("h:"): open_house(int(s.substr(2)))

# ---------- toques ----------
func tap(pos: Vector2) -> void:
	map_menu.visible = false
	if mode == "build" and placing != "":
		var g = main.pick_ground(pos)
		if g == null: return
		if MOBILE:
			var sp = Game.snap_pos(placing, g.x, g.z)
			if main.ghost and main.ghost.ok and absf(sp.x - main.ghost.x) < 0.1 and absf(sp.z - main.ghost.z) < 0.1: confirm_place(); return
			main.update_ghost(placing, g.x, g.z); confirm_bar.visible = true; _layout_bottom(); return
		main.update_ghost(placing, g.x, g.z); confirm_place(); return
	var b = main.pick_building(pos)
	if mode == "demolish":
		if b:
			if b.type == "castle": toast("O castelo não pode ser demolido"); return
			select(b)
		return
	if b:
		if b.state == "site" or b.upg:
			b.prog = minf(1, b.prog + 0.04)
			for k in 5: main.spark(Vector3(b.x + randf_range(-3, 3), b.y + 1, b.z + randf_range(-3, 3)))
			if b.prog >= 1: Game.finish_build(b)
		select(b); return
	close_info(); open_province(pos)
func hover(pos: Vector2) -> void:
	if placing != "" and not MOBILE:
		var g = main.pick_ground(pos)
		if g: main.update_ghost(placing, g.x, g.z)
func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo): return
	match ev.keycode:
		KEY_R: rotate_ghost()
		KEY_ESCAPE: set_mode("select"); build_menu.visible = false; close_info(); sheet.visible = false; _close_prov()
		KEY_B: _on_tool("build")
		KEY_SPACE: Dyn.toggle()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5: Dyn.set_speed(ev.keycode - KEY_0)

# ---------- quadro a quadro ----------
var _hud_t = 0.0
func frame(dt: float) -> void:
	_hud_t += dt
	if _hud_t > 0.25: _hud_t = 0; _update_hud()
	_update_overlays(dt)
func _update_hud() -> void:
	var S: Dictionary = Game.S; var e: Dictionary = Game.econ
	for k in Game.RES:
		chips[k].val.text = Game.fmt(S.res[k]); var r: float = e.rate[k]
		chips[k].rate.text = ("+" if r >= 0 else "") + ("%.1f" % r if absf(r) < 10 else str(int(r))) + "/s"
		chips[k].rate.add_theme_color_override("font_color", Color("#ff8f7a") if r < -0.001 else Color("#9fe08a"))
		chips[k].fill.custom_minimum_size.x = clampf(S.res[k] / e.cap, 0, 1) * 60
	chips.pop.val.text = "%d/%d" % [S.pop, e.popCap]; chips.pop.rate.text = ("%d livres" % e.idle) if e.idle else "todos ocupados"; chips.pop.fill.visible = false
	chips.hap.val.text = "%d%%" % int(e.hap); chips.hap.rate.text = "Capacidade: " + Game.fmt(e.cap); chips.hap.fill.visible = false
	chips.hap.icon.text = "😄" if e.hap >= 80 else ("🙂" if e.hap >= 55 else ("😐" if e.hap >= 35 else "😟"))
	if build_menu.visible: _render_menu()
	if selected: _refresh_info(true)
	if S.goal < Game.goals.size():
		var g: Dictionary = Game.goals[S.goal]; var v = mini(g.n, g.f.call())
		goal_txt.text = g.t; goal_prog.text = "%d/%d" % [v, g.n] if g.n > 1 else ""; goal_bar.size.x = 250.0 * v / g.n
		var rw = ""
		for i in 3:
			if g.r[i]: rw += Game.RICON[Game.RES[i]] + str(g.r[i]) + " "
		goal_rew.text = "Prêmio: " + rw
	else:
		goal_txt.text = "Todos os objetivos concluídos! Seu reino é lendário 👑"; goal_prog.text = ""; goal_bar.size.x = 250; goal_rew.text = ""
	paused_tag.visible = Dyn.paused and S.kingdom >= 0
func _build_region_labels() -> void:
	for r in W.F.regions:
		var l = _label(String(r.name).to_upper(), 16, Color("#f6e7bf"), serif); l.add_theme_color_override("font_outline_color", Color("#2a1c0b")); l.add_theme_constant_override("outline_size", 7)
		overlay.add_child(l)
		region_lbls.append({l = l, x = r.lbl[0] / W.F.frame[0] * W.WX - W.HX, z = r.lbl[1] / W.F.frame[1] * W.WZ - W.HZ, size = r.lbl[2] * W.WX / W.F.frame[0]})
func _update_overlays(dt: float) -> void:
	var a = smoothstep(650, 1100, main.dist)
	for L in region_lbls:
		var y = maxf(W.mesh_h(L.x, L.z), 0) + 4; var p = main.to_screen(Vector3(L.x, y, L.z))
		L.l.visible = a > 0 and p != null
		if not L.l.visible: continue
		var px: float = L.size / maxf(1, (main.cam.global_position - Vector3(L.x, y, L.z)).length() * tan(PI / 6)) * root.size.y * 0.5
		L.l.add_theme_font_size_override("font_size", int(clampf(px * 0.1, 11, 26))); L.l.modulate.a = a
		L.l.position = p - L.l.size / 2
	var i = floaters.size() - 1
	while i >= 0:
		var f: Dictionary = floaters[i]; f.t += dt
		if f.t > 1.6 or main.dist > 650: f.l.queue_free(); floaters.remove_at(i); i -= 1; continue
		var p = main.to_screen(f.p + Vector3(0, f.t * 2.5, 0))
		f.l.visible = p != null
		if p != null: f.l.position = p - f.l.size / 2; f.l.modulate.a = 1.0 if f.t < 1.1 else 1.0 - (f.t - 1.1) / 0.5
		i -= 1
	var seen = {}
	if main.dist < 900:
		for b in Game.S.b:
			if not (b.state == "site" or b.upg): continue
			seen[b.id] = true; var e = bars.get(b.id)
			if e == null:
				var bg = Panel.new(); bg.add_theme_stylebox_override("panel", _sb(Color("#1b2622dd"), Color("#f6efe0"), 7, 0)); bg.custom_minimum_size = Vector2(66, 13); bg.size = Vector2(66, 13); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var fill = ColorRect.new(); fill.color = Color("#f0b040"); fill.position = Vector2(2, 2); fill.size = Vector2(0, 9); bg.add_child(fill)
				var ic = _label("🔨", 15); ic.position = Vector2(68, -6); bg.add_child(ic); overlay.add_child(bg); e = {bg = bg, fill = fill, ic = ic}; bars[b.id] = e
			var p = main.to_screen(Vector3(b.x, b.y + M.HEIGHT[b.type] + 2, b.z))
			e.bg.visible = p != null
			if p != null:
				e.bg.position = p - Vector2(33, 6); e.fill.size.x = 62 * b.prog
				var nb: bool = (b.type == "castle" and b.state == "site") or Game.vill.any(func(v): return v.site == b.id and v.task and v.task.k == "build")
				e.ic.text = "🔨" if nb else "⏳"
	for id in bars.keys():
		if not seen.has(id): bars[id].bg.queue_free(); bars.erase(id)
