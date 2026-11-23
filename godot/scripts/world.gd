extends Node
## Dados do continente: relevo, biomas, províncias, rios e reinos.
## Mesmas coordenadas da versão web: x para leste, z para o sul, y para cima.

const CLASS_NAMES := ["Mar / lago", "Rio", "Planície", "Floresta", "Deserto / estepe", "Montanha", "Neve"]
var WX := 3072.0
var WZ := 2165.0
var HX := 1536.0
var HZ := 1082.5
var HMW := 1024
var HMH := 683
var PW := 2048
var PH := 1024
var NX := 512
var NZ := 320
var CX := 6.0
var CZ := 6.77

var HM: PackedFloat32Array     # alturas (HMW x HMH)
var CL: PackedByteArray        # classe do terreno
var NH: PackedFloat32Array     # alturas dos nós da malha (NX+1 x NZ+1)
var PID: PackedByteArray       # id da província (u16, little-endian) PW x PH
var RIV: PackedByteArray       # máscara dos rios PW x PH
var F: Dictionary              # dados políticos (províncias, reinos, regiões, vizinhanças)
var NP := 0
var NEIGH: Array = []          # [[vizinha, tipo], ...] por província
var house_colors: Array = []
var region_colors: Array = []

var albedo_img: Image
var normals_img: Image
var splat_img: Image
var patterns_img: Image
var detail_img: Image
var borders_img: Image

func _bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes("res://data/" + path)

func _png(path: String) -> Image:
	var im := Image.new()
	im.load_png_from_buffer(_bytes(path))
	return im

func load_all() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/meta.json"))
	WX = meta.WX; WZ = meta.WZ; HX = WX / 2.0; HZ = WZ / 2.0
	HMW = int(meta.HMW); HMH = int(meta.HMH); PW = int(meta.PW); PH = int(meta.PH); NX = int(meta.NX); NZ = int(meta.NZ)
	CX = WX / NX; CZ = WZ / NZ
	HM = _bytes("heights.bin").to_float32_array()
	CL = _bytes("classes.bin")
	NH = _bytes("nodeh.bin").to_float32_array()
	PID = _bytes("provid.bin")
	RIV = _bytes("river.bin")
	F = JSON.parse_string(FileAccess.get_file_as_string("res://data/feudal.json"))
	NP = F.ids.size()
	NEIGH = []
	for i in NP: NEIGH.append([])
	var adj: Array = F.adj
	var adjT: Array = F.adjT
	for k in range(0, adj.size(), 2):
		var a := int(adj[k]); var b := int(adj[k + 1]); var t := int(adjT[k / 2])
		NEIGH[a].append([b, t]); NEIGH[b].append([a, t])
	for h in F.houses: house_colors.append(Color.html(h.color))
	for r in F.regions: region_colors.append(Color.html(r.color))
	albedo_img = Image.new(); albedo_img.load_jpg_from_buffer(_bytes("albedo_jpg.dat"))
	normals_img = _png("normals_png.dat")
	splat_img = _png("splat_png.dat")
	patterns_img = _png("patterns_png.dat")
	detail_img = _png("detail_png.dat")
	borders_img = _png("borders_png.dat")

# ---------- consultas ----------
func htF(x: float, z: float) -> float:
	var fx := clampf((x + HX) / WX * (HMW - 1), 0.0, HMW - 1.001)
	var fz := clampf((z + HZ) / WZ * (HMH - 1), 0.0, HMH - 1.001)
	var i := int(fx); var j := int(fz); var u := fx - i; var v := fz - j; var k := j * HMW + i
	return (HM[k] * (1 - u) + HM[k + 1] * u) * (1 - v) + (HM[k + HMW] * (1 - u) + HM[k + HMW + 1] * u) * v

func class_at(x: float, z: float) -> int:
	var i := int(round(clampf((x + HX) / WX * (HMW - 1), 0, HMW - 1)))
	var j := int(round(clampf((z + HZ) / WZ * (HMH - 1), 0, HMH - 1)))
	return CL[j * HMW + i]

## Altura exatamente como a malha desenhada (objetos não flutuam nem afundam)
func mesh_h(x: float, z: float) -> float:
	var fx := clampf((x + HX) / CX, 0.0, NX - 0.001)
	var fz := clampf((z + HZ) / CZ, 0.0, NZ - 0.001)
	var i := int(fx); var j := int(fz); var u := fx - i; var v := fz - j; var W := NX + 1; var k := j * W + i
	if u + v < 1.0:
		return NH[k] + (NH[k + 1] - NH[k]) * u + (NH[k + W] - NH[k]) * v
	return NH[k + W + 1] + (NH[k + W] - NH[k + W + 1]) * (1 - u) + (NH[k + 1] - NH[k + W + 1]) * (1 - v)

func ground(x: float, z: float) -> float:
	return maxf(mesh_h(x, z), 0.0) + 0.12

func is_water(x: float, z: float) -> bool:
	return class_at(x, z) <= 1 or mesh_h(x, z) < 0.3

func prov_at(x: float, z: float) -> int:
	var i := int(floor((x + HX) / WX * PW)); var j := int(floor((z + HZ) / WZ * PH))
	if i < 0 or j < 0 or i >= PW or j >= PH: return -1
	var k := (j * PW + i) * 2
	return PID[k] + PID[k + 1] * 256 - 1

func river_at(x: float, z: float) -> int:
	var i := clampi(int(floor((x + HX) / WX * PW)), 0, PW - 1); var j := clampi(int(floor((z + HZ) / WZ * PH)), 0, PH - 1)
	return RIV[j * PW + i]

func owner_at(x: float, z: float) -> int:
	var p := prov_at(x, z)
	return -1 if p < 0 else int(F.prov[p][2])

func anchor_of(i: int) -> Vector2:
	var pr: Array = F.prov[i]
	return Vector2(pr[3] / F.frame[0] * WX - HX, pr[4] / F.frame[1] * WZ - HZ)

func house(i: int) -> Dictionary:
	return F.houses[i]

func cold_at(x: float, z: float) -> float:
	var lat := (z + HZ) / WZ
	return smoothstep(0.40, 0.06, lat)
