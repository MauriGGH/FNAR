extends Control

## Los profes que se ven en una vista de la oficina, como recortes con fondo
## transparente de assets/art/office/layers/. Cada recorte es del tamaño de su
## vista, así que se pone encima tal cual y ya cae donde le toca.
##
## Cada recorte es un TextureRect propio, no un dibujo en _draw(), porque en la
## vista central cada uno lleva su propia máscara del cono de la linterna: los
## que solo existen con luz desaparecen fuera del haz, y los que se ven siempre
## (Mamador, Barcosa, el Mago) se pintan apagados fuera y a todo brillo dentro.
##
## Si falta el recorte de alguien, no se pone nada y se queda su etiqueta de
## presencia, que es lo que hay mientras no haya arte.

const LAYERS_DIR: String = "res://assets/art/office/layers/%s"
const REVEAL_SHADER: String = "res://scenes/office/flashlight_reveal.gdshader"

## Nombre de la vista en el archivo del recorte.
@export var view_name: String = "centro"
## Solo la vista central tiene linterna; en las otras los recortes van tal cual.
@export var uses_flashlight: bool = false

var _present: Array[Dictionary] = []
var _pinned: PackedStringArray = PackedStringArray()
## slug -> Texture2D, o null si ese recorte no existe. Se busca una sola vez.
var _cache: Dictionary = {}
## slug -> el material de su recorte, para moverle el haz sin rearmar nada.
var _materials: Dictionary = {}

var _beam_center: Vector2 = Vector2(0.5, 0.5)
var _beam_radius: float = 0.0
var _beam_strength: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Le dice quiénes están a la vista. Cada entrada es {"slug", "lit_only"}.
func set_present(present: Array[Dictionary]) -> void:
	if _same_present(present):
		return
	_present = present
	_rebuild()


## Los recortes fijos de esta vista, por nombre de archivo.
func set_pinned(file_names: PackedStringArray) -> void:
	if _pinned == file_names:
		return
	_pinned = file_names
	_rebuild()


## El cono de la linterna, en coordenadas normalizadas de la vista.
func set_beam(center: Vector2, radius: float, strength: float) -> void:
	_beam_center = center
	_beam_radius = radius
	_beam_strength = strength
	_apply_beam()


## true si existe el recorte de ese profe para esta vista. Lo usa el night.gd
## para saber si todavía hace falta la etiqueta de presencia.
func has_layer(slug: String) -> bool:
	return _texture_for(slug) != null


func has_pinned(file_name: String) -> bool:
	return _texture_named(file_name) != null


# --- Montaje ------------------------------------------------------------------

func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_materials.clear()
	# Primero lo que ya está puesto en la escena, debajo de los profes.
	for file_name: String in _pinned:
		_add_picture(_texture_named(file_name), "", false)
	for entry: Dictionary in _present:
		var slug: String = str(entry.get("slug", ""))
		_add_picture(_texture_for(slug), slug, bool(entry.get("lit_only", false)))
	_apply_beam()


## Un recorte. En la vista central le cuelga su máscara del cono; en las otras
## va tal cual, porque ahí no hay linterna.
func _add_picture(texture: Texture2D, slug: String, lit_only: bool) -> void:
	if texture == null:
		return
	var picture: TextureRect = TextureRect.new()
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	if not uses_flashlight or slug.is_empty():
		return
	var material: ShaderMaterial = _make_material(lit_only, slug)
	if material != null:
		picture.material = material
		_materials[slug] = material


## El material del cono para ese profe. Los que se ven siempre se quedan
## apagados fuera del haz; los demás desaparecen.
func _make_material(lit_only: bool, slug: String) -> ShaderMaterial:
	if not ResourceLoader.exists(REVEAL_SHADER):
		return null
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load(REVEAL_SHADER)
	var always: bool = not lit_only and OfficeLayers.is_always_visible(slug)
	material.set_shader_parameter("base_alpha", 1.0 if always else 0.0)
	material.set_shader_parameter("base_brightness",
		OfficeLayers.DIM_BRIGHTNESS if always else 1.0)
	return material


func _apply_beam() -> void:
	for slug: Variant in _materials:
		var material: ShaderMaterial = _materials[slug] as ShaderMaterial
		material.set_shader_parameter("beam_center", _beam_center)
		material.set_shader_parameter("beam_radius", _beam_radius)
		material.set_shader_parameter("beam_strength", _beam_strength)
		material.set_shader_parameter("aspect", _aspect())


func _aspect() -> float:
	return size.x / size.y if size.y > 0.0 else 1.78


## true si la lista es la misma que ya está puesta: así no se rearma en cada
## cuadro, que sería tirar y crear nodos sesenta veces por segundo.
func _same_present(present: Array[Dictionary]) -> bool:
	if present.size() != _present.size():
		return false
	for i: int in present.size():
		if present[i].get("slug", "") != _present[i].get("slug", ""):
			return false
		if present[i].get("lit_only", false) != _present[i].get("lit_only", false):
			return false
	return true


func _texture_for(slug: String) -> Texture2D:
	return _texture_named("%s_%s" % [view_name, slug])


## Un recorte por su nombre de archivo, sin extensión.
func _texture_named(file_name: String) -> Texture2D:
	if not _cache.has(file_name):
		# Se guarda incluso si no existe, para no buscarlo en cada cuadro.
		_cache[file_name] = GameAssets.load_texture(LAYERS_DIR % file_name)
	return _cache[file_name]
