extends Control

## Los profes que se ven en una vista de la oficina, como recortes con fondo
## transparente de assets/art/office/layers/. Cada recorte es del tamaño de
## su vista, así que se dibuja encima tal cual y ya cae donde le toca.
##
## Los que solo se ven con la linterna (Ureña, Juan.exe y Armando pegados al
## cristal) se revelan nada más dentro de la zona que alumbra el haz.
## Si falta el recorte de alguien, no se dibuja nada y se queda su etiqueta
## de presencia de siempre, que es lo que hay mientras no haya arte.

## La carpeta de los recortes. Los de los profes llevan el nombre de su vista
## delante (centro_urena); los fijos van con su nombre tal cual (urena_foto).
const LAYERS_DIR: String = "res://assets/art/office/layers/%s"

## Nombre de la vista en el archivo del recorte.
@export var view_name: String = "centro"

## Quién se ve ahora: cada entrada es {"slug": String, "lit_only": bool}.
var _present: Array[Dictionary] = []
## Recortes que no dependen de ningún profe y se quedan puestos, como la foto
## que deja Ureña. Van por su nombre completo, sin el de la vista.
var _pinned: PackedStringArray = PackedStringArray()
## slug -> Texture2D, o null si ese recorte no existe. Se busca una sola vez.
var _cache: Dictionary = {}
## La zona que alumbra la linterna, en coordenadas del contenido.
var _lit_rect: Rect2 = Rect2()
var _is_lit: bool = false


## Le dice quiénes están a la vista en esta vista de la oficina.
func set_present(present: Array[Dictionary]) -> void:
	_present = present
	queue_redraw()


## Los recortes fijos de esta vista, por nombre de archivo.
func set_pinned(file_names: PackedStringArray) -> void:
	_pinned = file_names
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
	return _texture_named("%s_%s" % [view_name, slug])


## Un recorte por su nombre de archivo, sin extensión.
func _texture_named(file_name: String) -> Texture2D:
	if not _cache.has(file_name):
		# Se guarda incluso si no existe, para no buscarlo en cada cuadro.
		_cache[file_name] = GameAssets.load_texture(LAYERS_DIR % file_name)
	return _cache[file_name]


## true si existe ese recorte fijo.
func has_pinned(file_name: String) -> bool:
	return _texture_named(file_name) != null


func _draw() -> void:
	# Primero lo que ya está puesto en la escena, debajo de los profes.
	for file_name: String in _pinned:
		var pinned: Texture2D = _texture_named(file_name)
		if pinned != null:
			draw_texture_rect(pinned, Rect2(Vector2.ZERO, size), false)
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
