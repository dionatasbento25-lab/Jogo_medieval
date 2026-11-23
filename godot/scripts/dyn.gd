extends Node
## Calendário (pausa e 5 velocidades) + personagens e dinastias dos 61 reinos.
## Porte do sistema "Tempo e calendário" e "Personagens e dinastias" do mapa original.

signal dia
signal mes
signal ano
signal changed          # data, pausa ou velocidade mudaram
signal logged(txt: String, important: bool)

const MESES := ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
const DIAS_MES := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
const MS_POR_DIA := [0, 1000, 500, 250, 110, 40]
const DOY := [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]

var d = 1
var m = 0
var y = 1000
var speed = 1
var paused = true
var acc = 0.0
var total_days = 0

func fmt_now() -> String: return "%d%s de %s, %d" % [d, "º" if d == 1 else "", MESES[m], y]
func pause() -> void: paused = true; changed.emit()
func resume() -> void: paused = false; acc = 0; changed.emit()
func toggle() -> void:
	if paused: resume()
	else: pause()
func set_speed(v: int) -> void: speed = clampi(v, 1, 5); changed.emit()

func _process(delta: float) -> void:
	if paused: return
	acc += minf(delta, 0.25) * 1000.0
	var step: float = MS_POR_DIA[speed]; var n = 0
	while acc >= step and n < 10:
		acc -= step; _next_day(); n += 1
	if n >= 10: acc = 0
	if n: changed.emit()

func _next_day() -> void:
	total_days += 1; d += 1; var nm_ = false; var ny = false
	if d > DIAS_MES[m]:
		d = 1; m += 1; nm_ = true
		if m > 11: m = 0; y += 1; ny = true
	dia.emit()
	if nm_: mes.emit(); _monthly()
	if ny: ano.emit(); _yearly(); log_msg("📜 Começa o ano %d" % y, -1, true)

# =====================================================================
# PERSONAGENS E DINASTIAS
# =====================================================================
var NM: Array = "Afonso Aldric Alarico Álvaro Amaury Anselmo Arnaldo Artur Audemar Baldero Baltasar Bermudo Bernardo Bertrand Boemundo Bruno Caio Casimiro Cedric Cipriano Clóvis Conrado Dagoberto Damião Dário Desidério Diogo Dorian Duarte Edmundo Egas Elric Emeric Eudes Evrard Fabrício Fernão Filipe Florian Fradique Frederico Fulco Gaspar Gastão Gaufrido Gerardo Gervásio Gilberto Godofredo Gonçalo Gualter Guilherme Gunter Haroldo Heitor Henrique Hilário Horácio Hugo Humberto Inácio Isidoro Ivo Jaime Joran Jordão Julião Leandro Leonel Leopoldo Lotário Lourenço Lucano Luís Magno Mâncio Manfredo Marcos Martim Mateus Mauro Mendo Merovino Nicolau Norberto Nuno Odo Olavo Ordonho Orlando Osberto Osric Otão Paio Pascoal Pelaio Percival Raimundo Ramiro Randolfo Raul Reinaldo Ricardo Roberto Rodrigo Rogério Rolando Romualdo Rui Sancho Sebastião Sesnando Severo Sigeberto Silvestre Simão Soeiro Tancredo Teobaldo Teodorico Tibério Tristão Ubaldo Ulrico Urbano Valério Vasco Venâncio Vicente Vidal Vilfredo Vímara Vivaldo Wolfram Zacarias Aldren Bran Caedmon Corvin Eldric Faramond Garrick Hadrian Ivor Jarlath Kaelen Leoric Malcor Nerion Orrin Perrin Roderic Soren Taric Varric Wendel Ysmar Brennar Cassian Darion Edwin Falk Galen Halvar Ingram Joscelin Lothar Marek Niall Oswin Piers Quillan Raoul Sigurd Theron Valen Wystan Ewald Gideon Jasper Kenric Lysander Mordren Norwin Osmund Rainer Stellan Torvald Ulf Viggo Warin Aymeric Bastien Corentin Dreux Enguerrand Fulbert Gauvain Hamelin Ismael Jocelin Lambert Odilon Philibert Renaud Thibault Ysambert".split(" ")
var NF: Array = "Adelaide Adosinda Aldonça Alienor Alix Amélia Arsenda Aurélia Beatriz Berengária Berta Branca Brígida Brunilda Catarina Cecília Clara Clotilde Constança Dulce Elvira Ermesinda Ermengarda Estefânia Eufémia Eulália Flamínia Florência Gelvira Genoveva Gertrudes Gisela Godiva Gontrode Guiomar Hedviges Helena Hermínia Hildegarda Ida Inês Irene Isabel Isolda Joana Júlia Leonor Letícia Lúcia Mafalda Margarida Marina Matilde Mécia Melisenda Odília Paterna Petronila Filipa Raquel Rosamunda Sancha Sibila Sofia Teresa Urraca Velasquita Violante Viviana Yolanda Aelis Calia Delphine Elowen Gwenna Honora Ilsa Jessamine Kaela Liora Maelis Nerys Odessa Perrine Quenna Seren Talia Úrsula Vesna Wren Ysolde Alys Brynn Cerys Eira Freya Ginevra Hester Imogen Katrin Mirela Oriane Rosalind Selene Tamsin Una Valeska Wilhelmina Yvaine Aveline Blanchefleur Clémence Douce Fleur Gisla Heloísa Isaure Jehanne Laure Mahaut Nicolette Oriabel Pernelle Richeut Tiphaine Yselda Ada Brunhilde Celestina Dorotea Edite Faustina Graciosa Iolanda Juliana Lavínia Madalena Olímpia Prisca Rosalinda Severina Tecla Valentina Zenóbia Aldegunda Basília Cândida Domitila Escolástica Fausta Gualdrada Hortênsia Justa Leocádia Marcela Orosia Plácida Quitéria Rufina Sabina Tarsila Vitória".split(" ")
const ROM := ["", "", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
const TRAITS := [["Bravo", "Covarde"], ["Ambicioso", "Contente"], ["Justo", "Arbitrário"], ["Cruel", "Compassivo"], ["Diligente", "Preguiçoso"], ["Ganancioso", "Generoso"], ["Honesto", "Ardiloso"], ["Paciente", "Impulsivo"], ["Devoto", "Cínico"]]
const TMOD := {"Bravo": [0, 2, 0, 0], "Covarde": [0, -2, 0, 1], "Ambicioso": [1, 1, 1, 1], "Contente": [0, 0, 1, -1], "Justo": [1, 0, 1, -1], "Arbitrário": [-1, 0, -1, 1], "Cruel": [-1, 1, 0, 1], "Compassivo": [1, -1, 0, -1], "Diligente": [1, 0, 2, 0], "Preguiçoso": [-1, -1, -1, -1], "Ganancioso": [-1, 0, 2, 0], "Generoso": [2, 0, -1, 0], "Honesto": [1, 0, 0, -2], "Ardiloso": [0, 0, 0, 3], "Paciente": [0, 1, 1, 0], "Impulsivo": [0, 1, -1, 0], "Devoto": [1, 0, 0, 0], "Cínico": [0, 0, 0, 1]}
const ATT := ["Diplomacia", "Marcial", "Administração", "Intriga"]
const ATT_IC := ["🗣", "⚔", "💰", "🗡"]

var C: Array = []        # personagens: Dictionary {id,n,s,dyn,court,bd,pai,mae,cj,kids,alive,dd,att,tr,hp,matri,reg,cause}
var H: Array = []        # reinos: {i, leader, surname}
var LOG: Array = []      # crônica: {day, txt, h}
var ever_used = {}
var live_name = {}
var past_leaders = {}
var heir_cache = {}
var s0: int = 20251103
var T0 = 0
var ready_ = false

func R() -> float:
	s0 = (s0 * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(s0) / 4294967296.0
func Rnd() -> float: return randf()

func _grow_names() -> void:
	var P = "Al Bel Cor Dar El Fen Gal Hal Is Jor Kal Lor Mar Nor Or Per Ral Ser Tor Ul Val Ves Aur Bran Cel Del Ed Fer Gor Hel Ir Lan Mor Os Rav Sil Tal Ven Wal Yr".split(" ")
	var SM = "ric mund bert win dor ran ald ion mar ven gar los rin thos wald".split(" ")
	var SF = "ia wen ra lis ena dis ira elle ys ine ora issa wyn ette".split(" ")
	for pair in [[NM, SM], [NF, SF]]:
		var arr: Array = pair[0]; var seen = {}
		for x in arr: seen[x] = true
		var done = false
		for p in P:
			if done: break
			for s in pair[1]:
				var n: String = p + s
				var triple = false
				for k in n.length() - 2:
					if n[k] == n[k + 1] and n[k] == n[k + 2]: triple = true
				if triple: continue
				n = n[0] + n.substr(1).to_lower()
				if not seen.has(n): seen[n] = true; arr.append(n)
				if arr.size() >= 520: done = true; break

func take_name(n: String) -> String:
	ever_used[n] = true; live_name[n] = live_name.get(n, 0) + 1; return n
func release_name(n: String) -> void:
	var k: int = live_name.get(n, 1) - 1
	if k <= 0: live_name.erase(n)
	else: live_name[n] = k
func pick_name(sex: String, r: Callable) -> String:
	var L: Array = NM if sex == "M" else NF
	for t in 40:
		var n: String = L[int(r.call() * L.size())]
		if not ever_used.has(n): return take_name(n)
	for n in L:
		if not ever_used.has(n): return take_name(n)
	for t in 60:
		var n: String = L[int(r.call() * L.size())]
		if not live_name.has(n): return take_name(n)
	for n in L:
		if not live_name.has(n): return take_name(n)
	return take_name(L[int(r.call() * L.size())])

func nm(c: Dictionary) -> String: return c.n + ((" " + (ROM[c.reg] if c.reg < ROM.size() else str(c.reg))) if c.get("reg", 1) > 1 else "")
func day_of(dd: int, mm: int, yy: int) -> int: return (yy - 1000) * 365 + DOY[mm - 1] + (dd - 1)
func date_of(day: int) -> Array:
	var yy = 1000 + int(floor(day / 365.0)); var r = day - (yy - 1000) * 365; var mm = 0
	while mm < 11 and r >= DOY[mm + 1]: mm += 1
	return [r - DOY[mm] + 1, mm + 1, yy]
func fmt_date(day: int) -> String:
	var t = date_of(day); return "%d%s de %s, %d" % [t[0], "º" if t[0] == 1 else "", MESES[t[1] - 1], t[2]]
func today() -> int: return day_of(d, m + 1, y)
func age(c: Dictionary, t := -999999) -> int:
	if t == -999999: t = today()
	return int(floor(float((t if c.alive else c.dd) - c.bd) / 365.0))
func full_name(c: Dictionary) -> String: return nm(c) + " " + H[c.dyn].surname
func title(c: Dictionary) -> String: return "Rei" if c.s == "M" else "Rainha"
func is_leader(c: Dictionary) -> bool: return H[c.dyn].leader == c.id
func leader(h: int) -> Dictionary: return C[H[h].leader]

func give_traits(c: Dictionary, r: Callable) -> void:
	c.tr = []
	var pairs: Array = TRAITS.duplicate()
	# embaralha como o sort aleatório da versão web
	for i in range(pairs.size() - 1, 0, -1):
		var j = int(r.call() * (i + 1)); var tmp = pairs[i]; pairs[i] = pairs[j]; pairs[j] = tmp
	var n = 2 if r.call() < 0.55 else (1 if r.call() < 0.85 else 3)
	for i in n:
		var t: String = pairs[i][0 if r.call() < 0.5 else 1]
		c.tr.append(t); var md: Array = TMOD[t]
		for k in 4: c.att[k] = clampi(c.att[k] + md[k], 0, 20)

func mk(o: Dictionary) -> Dictionary:
	var c = {id = C.size(), pai = -1, mae = -1, cj = -1, kids = [], alive = true, dd = 0, att = [0, 0, 0, 0], tr = [], hp = 90.0, matri = false, reg = 1, cause = ""}
	c.merge(o, true); C.append(c); return c
func born_years_ago(a: float, r: Callable) -> int: return T0 - int(round(a * 365 + r.call() * 364))
func base_att(r: Callable, bonus := 0) -> Array:
	var a = []
	for k in 4: a.append(clampi(int(round(3 + r.call() * 7 + (r.call() - 0.5) * 3)) + bonus, 1, 16))
	return a
func adult(o: Dictionary, r: Callable, bonus := 0) -> Dictionary:
	var c = mk(o); c.att = base_att(r, bonus); give_traits(c, r); c.hp = round(60 + r.call() * 40 - maxf(0, age(c, T0) - 45) * 1.2); return c
func child(o: Dictionary, r: Callable) -> Dictionary:
	var c = mk(o); c.att = base_att(r)
	if age(c, T0) >= 16: give_traits(c, r)
	c.hp = round(75 + r.call() * 25); return c
func marry(a: Dictionary, b: Dictionary) -> void: a.cj = b.id; b.cj = a.id
func add_kid(f, mo, k: Dictionary) -> void:
	k.pai = f.id if f else -1; k.mae = mo.id if mo else -1
	if f: f.kids.append(k.id)
	if mo: mo.kids.append(k.id)

func gen_house(h: Dictionary) -> void:
	var r = Callable(self, "R"); var fh: Dictionary = W.F.houses[h.i]
	var la = 40 + int(r.call() * 14); var fem = r.call() < 0.07
	var fa = la + 22 + int(r.call() * 12); var ma = la + 18 + int(r.call() * 10)
	var father = adult({n = pick_name("M", r), s = "M", dyn = h.i, court = h.i, bd = born_years_ago(fa, r)}, r)
	var mother = adult({n = pick_name("F", r), s = "F", dyn = int(r.call() * H.size()), court = h.i, bd = born_years_ago(ma, r)}, r)
	marry(father, mother)
	var father_alive = not fem and la < 38 and r.call() < 0.35; var mother_alive = la < 46 and r.call() < 0.45
	if not father_alive: father.alive = false; father.dd = T0 - int(r.call() * 365 * maxi(1, mini(15, la - 16))); mother.cj = -1
	if not mother_alive:
		mother.alive = false; mother.dd = T0 - int(r.call() * 365 * maxi(1, la - 15))
		if father.alive: father.cj = -1
	var L = adult({n = pick_name("F" if fem else "M", r), s = "F" if fem else "M", dyn = h.i, court = h.i, bd = born_years_ago(la, r)}, r, 1); add_kid(father, mother, L)
	var nsib = int(r.call() * 4)
	for k in nsib:
		var sa = la - 1 - int(r.call() * 9)
		if sa < 1: continue
		var sex = "F" if fem else ("M" if r.call() < 0.5 else "F")
		var o = {n = pick_name(sex, r), s = sex, dyn = h.i, court = h.i, bd = born_years_ago(sa, r)}
		var sb = adult(o, r) if sa >= 16 else child(o, r); add_kid(father, mother, sb)
		if sa < 45 and r.call() < 0.15: sb.alive = false; sb.dd = T0 - int(r.call() * 365 * 3)
	if la >= 18 and r.call() < 0.88:
		var reg = fh.region; var cand = []; var others = []
		for x in H:
			if x.i != h.i:
				others.append(x)
				if W.F.houses[x.i].region == reg: cand.append(x)
		var pool = cand if cand.size() and r.call() < 0.6 else others
		var od: int = pool[int(r.call() * pool.size())].i
		var sex = "M" if fem else "F"; var sa = la + int(r.call() * 8) - 2 if fem else maxi(16, la - int(r.call() * 11))
		var Sp = adult({n = pick_name(sex, r), s = sex, dyn = od, court = h.i, bd = born_years_ago(sa, r)}, r); marry(L, Sp)
		if fem: L.matri = true; Sp.matri = true
		var wife_age = la if fem else sa; var max_kids = maxi(0, mini(6, int((mini(wife_age, 44) - 17) / 2.6)))
		var n = int(r.call() * (max_kids + 1))
		if wife_age >= 24 and n == 0 and r.call() < 0.6: n = 1
		var ages = {}
		for k in n:
			var a = int(r.call() * maxi(1, wife_age - 17))
			if ages.has(a): continue
			ages[a] = true
		var al = ages.keys(); al.sort(); al.reverse()
		for a in al:
			var sex2 = "M" if r.call() < 0.5 else "F"; var o = {n = pick_name(sex2, r), s = sex2, dyn = h.i, court = h.i, bd = born_years_ago(a, r)}
			var kid = adult(o, r) if a >= 16 else child(o, r)
			if fem: add_kid(Sp, L, kid)
			else: add_kid(L, Sp, kid)
			if a < 6 and r.call() < 0.08: kid.alive = false; kid.dd = T0 - int(r.call() * 300)
		if r.call() < 0.06: Sp.alive = false; Sp.dd = T0 - int(r.call() * 365 * 4); L.cj = -1
	h.leader = L.id

func setup() -> void:
	_grow_names(); T0 = day_of(1, 1, 1000)
	for i in W.F.houses.size(): H.append({i = i, leader = -1, surname = String(W.F.houses[i].name).trim_prefix("Reino de ")})
	for h in H: gen_house(h)
	for c in C:
		if not c.alive: release_name(c.n)
	for h in H: past_leaders[h.i] = [h.leader]
	ready_ = true

# ---------- herança: primogenitura com preferência masculina ----------
func _by_age(ids: Array) -> Array:
	var a = []
	for i in ids: a.append(C[i])
	a.sort_custom(func(p, q): return p.bd < q.bd)
	return a
func _line_heir(p: Dictionary, h: int, male_only: bool, ex: int, seen: Dictionary):
	for c in _by_age(p.kids):
		if seen.has(c.id): continue
		seen[c.id] = true
		if male_only and c.s == "F": continue
		if c.alive and c.dyn == h and c.id != ex: return c
		var r = _line_heir(c, h, male_only, ex, seen)
		if r: return r
	return null
func heir_of(h: int, exclude := -2):
	var L: Dictionary = C[H[h].leader]; var ex: int = exclude if exclude != -2 else L.id
	for male_only in [true, false]:
		var r = _line_heir(L, h, male_only, ex, {})
		if r: return r
		var anc = L
		for up in 4:
			var pid = -1
			if anc.pai >= 0 and C[anc.pai].dyn == h: pid = anc.pai
			elif anc.mae >= 0 and C[anc.mae].dyn == h: pid = anc.mae
			if pid < 0: break
			anc = C[pid]
			r = _line_heir(anc, h, male_only, ex, {L.id: true})
			if r: return r
			if anc.alive and anc.dyn == h and anc.id != ex and (not male_only or anc.s == "M"): return anc
		var best = null
		for c in C:
			if c.alive and c.dyn == h and c.id != ex and c.s == ("M" if male_only else "F"):
				if best == null or c.bd < best.bd: best = c
		if best: return best
	return null
func heir_for(h: int):
	if not heir_cache.has(h): heir_cache[h] = heir_of(h)
	return heir_cache[h]

func log_msg(txt: String, h: int, important: bool) -> void:
	LOG.push_front({day = today(), txt = txt, h = h})
	if LOG.size() > 250: LOG.pop_back()
	logged.emit(txt, important)

func _set_reg(h: int, c: Dictionary) -> void:
	var k = 0
	for id in past_leaders[h]:
		if C[id].n == c.n: k += 1
	c.reg = k + 1; past_leaders[h].append(c.id)

func _mort(a: int) -> float:
	if a < 1: return 0.07
	if a < 6: return 0.025
	if a < 16: return 0.007
	if a < 40: return 0.009
	if a < 50: return 0.018
	if a < 60: return 0.035
	if a < 70: return 0.075
	if a < 80: return 0.15
	return 0.3

func die(c: Dictionary, cause: String) -> void:
	release_name(c.n); c.alive = false; c.dd = today(); c.cause = cause
	if c.cj >= 0: C[c.cj].cj = -1
	var h: int = c.dyn; var was_leader: bool = H[h].leader == c.id
	var hf = heir_for(h); var was_heir: bool = not was_leader and hf != null and hf.id == c.id
	heir_cache.clear()
	if was_leader:
		var nx = heir_of(h, c.id); var extra = ""
		if nx == null:
			var r = Callable(self, "Rnd")
			nx = mk({n = pick_name("M", r), s = "M", dyn = h, court = h, bd = today() - int(round((26 + randf() * 16) * 365))})
			nx.att = base_att(r); give_traits(nx, r); nx.hp = 85.0; extra = " (um parente distante reivindica o trono)"
		if nx.court != h: nx.court = h
		H[h].leader = nx.id; _set_reg(h, nx)
		if nx.s == "F":
			nx.matri = true
			if nx.cj >= 0: C[nx.cj].matri = true
			var keep = {}
			for x in H:
				var hy = heir_of(x.i)
				if hy: keep[hy.id] = true
			var adopt = func(k: int, self_ref: Callable) -> void:
				var cc: Dictionary = C[k]
				if not cc.alive or keep.has(cc.id) or is_leader(cc) or cc.dyn == h: return
				cc.dyn = h
				if cc.cj < 0 or cc.s == "M": cc.court = h
				for kk in cc.kids: self_ref.call(kk, self_ref)
			for k in nx.kids: adopt.call(k, adopt)
		heir_cache.clear()
		log_msg("⚰ Morreu %s %s (%d anos). %s %s assume o trono%s." % [title(c), full_name(c), age(c), title(nx), nm(nx), extra], h, true)
	elif was_heir:
		log_msg("⚰ Morreu %s, herdeiro(a) do reino (%d anos)." % [full_name(c), age(c)], h, false)

func _monthly() -> void:
	if not ready_: return
	var t = today(); var alive = C.filter(func(c): return c.alive)
	for c in alive:
		var a = age(c, t); var hpF = 3.0 if c.hp < 30 else (1.5 if c.hp < 60 else 1.0)
		var p = 1.0 - pow(1.0 - minf(0.9, _mort(a) * hpF), 1.0 / 12.0)
		if randf() < p: die(c, "doença infantil" if a < 6 else ("velhice" if a > 60 else "doença"))
	var live = C.filter(func(c): return c.alive); var cnt = []
	cnt.resize(H.size()); cnt.fill(0)
	for c in live: cnt[c.court] += 1
	for mo in live:
		if mo.s != "F" or mo.cj < 0: continue
		var f: Dictionary = C[mo.cj]
		if not f.alive: continue
		var a = age(mo, t)
		if a < 16 or a > 45: continue
		var fert = 1.0 if a < 30 else (0.6 if a < 38 else 0.25); var crowd = 0.15 if cnt[mo.court] > 22 else (0.5 if cnt[mo.court] > 15 else 1.0)
		if randf() > 0.016 * fert * crowd: continue
		var sex = "M" if randf() < 0.5 else "F"; var dy: int = mo.dyn if mo.matri else f.dyn
		var k = mk({n = pick_name(sex, Callable(self, "Rnd")), s = sex, dyn = dy, court = mo.court, bd = t, hp = 80.0 + randi() % 20})
		k.att = base_att(Callable(self, "Rnd")); add_kid(f, mo, k); heir_cache.clear()
		if is_leader(f) or is_leader(mo):
			var par: Dictionary = f if is_leader(f) else mo
			log_msg("👶 Nasceu %s %s, %s de %s %s." % [k.n, H[dy].surname, "filho" if sex == "M" else "filha", title(par), nm(par)], dy, false)
		if randf() < 0.02: die(mo, "parto")
	var brides = live.filter(func(c): return c.alive and c.s == "F" and c.cj < 0 and age(c, t) >= 16 and age(c, t) <= 44)
	var heir_set = {}
	for h in H:
		var x = heir_for(h.i)
		if x: heir_set[x.id] = true
	var keyP = func(c): return is_leader(c) or heir_set.has(c.id)
	for g in live:
		if not g.alive or g.s != "M" or g.cj >= 0: continue
		var a = age(g, t); var kp: bool = keyP.call(g)
		if a < 18 or a > (60 if kp else 48) or randf() > (0.15 if kp else 0.035): continue
		var reg = W.F.houses[g.dyn].region; var best = null; var bs = -1.0
		for k in 12:
			if brides.is_empty(): break
			var b: Dictionary = brides[randi() % brides.size()]; var ba = age(b, t)
			if b.cj >= 0 or b.dyn == g.dyn or absi(ba - a) > (25 if kp else 14) or (not kp and ba > 35): continue
			if kp and keyP.call(b): continue
			var sc = (2.0 if W.F.houses[b.dyn].region == reg else 1.0) + randf()
			if sc > bs: bs = sc; best = b
		if best == null: continue
		marry(g, best)
		if keyP.call(best): g.court = best.court; g.matri = true; best.matri = true
		else: best.court = g.court; best.matri = false; g.matri = false
		heir_cache.clear()
		var hg = heir_for(g.dyn)
		if is_leader(g) or is_leader(best) or (hg and hg.id == g.id): log_msg("💍 Casamento: %s e %s." % [full_name(g), full_name(best)], g.dyn, false)

func _yearly() -> void:
	if not ready_: return
	var t = today()
	for c in C:
		if not c.alive: continue
		var a = age(c, t)
		if a == 16 and c.tr.is_empty(): give_traits(c, Callable(self, "Rnd"))
		if a > 40: c.hp = maxf(5, c.hp - randf() * (a - 35) / 6.0)
		else: c.hp = minf(100, c.hp + 3)
		if randf() < 0.03:
			c.hp = maxf(5, c.hp - 25 - randf() * 20)
			if is_leader(c): log_msg("🤒 %s %s adoeceu gravemente." % [title(c), full_name(c)], c.dyn, false)

func att_shown(c: Dictionary) -> Array:
	var a = age(c); var out = []
	for v in c.att: out.append(v if a >= 16 else int(round(v * maxf(0, a) / 16.0)))
	return out
func alive_count() -> int:
	var n = 0
	for c in C:
		if c.alive: n += 1
	return n
