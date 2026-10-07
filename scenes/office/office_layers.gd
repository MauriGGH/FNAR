extends Control

## Los profes que se ven en una vista de la oficina, como recortes con fondo
## transparente de assets/art/office/layers/. Cada recorte es del tamaño de
## su vista, así que se dibuja encima tal cual y ya cae donde le toca.
##
## Los que solo se ven con la linterna (Ureña, Juan.exe y Armando pegados al
## cristal) se revelan nada más dentro de la zona que alumbra el haz.
## Si falta el recorte de alguien, no se dibuja nada y se queda su etiqueta
## de presencia de siempre, que es lo que hay mientras no haya arte.

## Carpeta y formato del nombre: layers/<vista>_<profe>, sin extensión.
const LAYERS_PATH: String = "res://assets/art/office/layers/%s_%s"

## Nombre de la vista en el archivo del recorte.
@export var view_name: String = "centro"

## Quién se ve ahora: cada entrada es {"slug": String, "lit_only": bool}.
var _present: Array[Dictionary] = []
## slug -> Texture2D, o null si ese recorte no existe. Se busca una sola vez.
var _cache: Dictionary = {}
## La zona que alumbra la linterna, en coordenadas del contenido.
var _lit_rect: Rect2 = Rect2()
var _is_lit: bool = false


## Le dice quiénes están a la vista en esta vista de la oficina.
func set_present(present: Array[Dictionary]) -> void:
	_present = present
	queue_redraw()


## El haz de la linterna: dentro de este rectángulo se revela a los que solo
## se ven alumbrados.
func set_lit(is_lit: bool, lit_rect: Rect2) -> void:
	_is_lit = is_lit
	_lit_rect = lit_rect
	queue_redraw()


## true si existe el recorte de ese profe para esta vista. Lo usa el night.gd
## para saber si todavía hace falta la etiqueta de presencia.
func has_layer(slug: String) -> bool:
	return _texture_for(slug) != null


func _texture_for(slug: String) -> Texture2D:
	if not _cache.has(slug):
		# Se guarda incluso si no existe, para no buscarlo en cada cuadro.
		_cache[slug] = GameAssets.load_texture(LAYERS_PATH % [view_name, slug])
	return _cache[slug]


func _draw() -> void:
	for entry: Dictionary in _present:
		var texture: Texture2D = _texture_for(str(entry.get("slug", "")))
		if texture == null:
			continue
		if not bool(entry.get("lit_only", false)):
			draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
			continue
		# Solo con la linterna, y solo el pedazo que cae dentro del haz.
		if not _is_lit or _lit_rect.size.x <= 0.0 or _lit_rect.size.y <= 0.0:
			continue
		var factor: Vector2 = texture.get_size() / size
		draw_texture_rect_region(texture, _lit_rect,
			Rect2(_lit_rect.position * factor, _lit_rect.size * factor))
