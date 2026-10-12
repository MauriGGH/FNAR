class_name StaticFrames
extends TextureRect

## La estática de la tele, con los ocho cuadros de
## `assets/art/screens/static/estatica_0..7.png`. Antes era un shader que
## generaba ruido por código; estos cuadros son de 480x270 y se estiran con
## filtro nearest, así que el grano queda gordo y pixelado, como en FNAF.
##
## Cada capa de estática lleva su propia opacidad: fuerte en un golpe de
## cámara, apenas visible de fondo en el menú. Se pone con `set_strength()`.
##
## Para que dos capas a la vez no vayan sincronizadas, cada una arranca en un
## cuadro al azar.

const FRAME_PATH: String = "res://assets/art/screens/static/estatica_%d.png"
const FRAME_COUNT: int = 8
## A cuántos cuadros por segundo cicla. 24 es lo bastante rápido para que
## hierva y lo bastante lento para que se vea analógico.
const FRAMES_PER_SECOND: float = 24.0

## Los ocho cuadros se cargan una vez para todas las capas.
static var _frames: Array[Texture2D] = []

var _index: int = 0
var _left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	# Nearest: el grano tiene que verse cuadrado, no emborronado.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_frames()
	if _frames.is_empty():
		return
	_index = randi() % _frames.size()
	_left = 1.0 / FRAMES_PER_SECOND
	texture = _frames[_index]


static func _load_frames() -> void:
	if not _frames.is_empty():
		return
	for i: int in FRAME_COUNT:
		var frame: Texture2D = GameAssets.load_texture(
			(FRAME_PATH % i).trim_suffix(".png"))
		if frame != null:
			_frames.append(frame)


## Lo visible que está, de 0 a 1.
## Cuántos cuadros se pudieron cargar. La usa el panel de pruebas.
static func frame_count() -> int:
	_load_frames()
	return _frames.size()


func set_strength(strength: float) -> void:
	modulate.a = clampf(strength, 0.0, 1.0)
	visible = modulate.a > 0.002


func _process(delta: float) -> void:
	if _frames.size() < 2 or modulate.a <= 0.002:
		return
	_left -= delta
	if _left > 0.0:
		return
	_left += 1.0 / FRAMES_PER_SECOND
	_index = (_index + 1) % _frames.size()
	texture = _frames[_index]
