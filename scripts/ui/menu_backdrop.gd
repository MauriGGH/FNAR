class_name MenuBackdrop
extends Control

## El fondo de los menús: la foto del pasillo con el guardia. Casi siempre se ve
## el cuadro 0; cada pocos segundos aparece de golpe uno de los otros tres por
## un instante, con un golpe de estática, como el Freddy del menú de los juegos
## originales. Encima, líneas de escaneo y un parpadeo leve.
##
## Se mete con MenuBackdrop.build(pantalla), igual que antes, para no tocar las
## pantallas que ya lo usaban.

const BACKGROUND_PATH: String = "res://assets/art/menu/menu_fondo_%d"
## Si falta el arte del menú, se usa una cámara, que siempre existe.
const FALLBACK_PATH: String = "res://assets/art/cameras/cam13_vacia"
## Cuántos cuadros alternativos hay además del 0.
const FLASH_FRAMES: int = 3

## Cada cuánto salta uno de los otros cuadros y lo que se queda.
const MIN_GAP: float = 4.0
const MAX_GAP: float = 9.0
const MIN_FLASH: float = 0.1
const MAX_FLASH: float = 0.25

## Lo oscuro que se pone encima, para que el texto se lea.
const DIM: Color = Color(0.0, 0.0, 0.02, 0.62)
## La estática de reposo y la del golpe.
const STATIC_IDLE: float = 0.08
const STATIC_FLASH: float = 0.42

var _frames: Array[Texture2D] = []
var _picture: TextureRect = null
var _static_layer: ColorRect = null
var _next_flash: float = 0.0
var _flash_left: float = 0.0


## Mete el fondo como primeros hijos de una pantalla y lo devuelve.
static func build(parent: Control) -> MenuBackdrop:
	var backdrop: MenuBackdrop = MenuBackdrop.new()
	backdrop.name = "Backdrop"
	parent.add_child(backdrop)
	parent.move_child(backdrop, 0)
	return backdrop


func _ready() -> void:
	# Con anclas y márgenes a la vez: puesto ya dentro del árbol, solo las
	# anclas dejarían el nodo de tamaño cero.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_frames()
	_build_layers()
	_next_flash = randf_range(MIN_GAP, MAX_GAP)


## El cuadro 0 y los otros tres. Si no hay nada, se cae a una cámara.
func _load_frames() -> void:
	for index: int in FLASH_FRAMES + 1:
		var texture: Texture2D = GameAssets.load_texture(BACKGROUND_PATH % index)
		if texture != null:
			_frames.append(texture)
	if _frames.is_empty():
		var fallback: Texture2D = GameAssets.load_texture(FALLBACK_PATH)
		if fallback != null:
			_frames.append(fallback)


func _build_layers() -> void:
	if not _frames.is_empty():
		_picture = TextureRect.new()
		_picture.name = "Picture"
		_picture.texture = _frames[0]
		_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
		_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_picture)

	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_static_layer = ScreenFx.add_static(self, STATIC_IDLE)
	ScreenFx.add_scanlines(self)


func _process(delta: float) -> void:
	# Sin cuadros alternativos no hay nada que alternar.
	if _picture == null or _frames.size() < 2:
		return
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_end_flash()
		return
	_next_flash -= delta
	if _next_flash <= 0.0:
		_start_flash()


## Uno de los otros cuadros, de golpe y con más estática.
func _start_flash() -> void:
	_picture.texture = _frames[randi_range(1, _frames.size() - 1)]
	_flash_left = randf_range(MIN_FLASH, MAX_FLASH)
	ScreenFx.set_static_strength(_static_layer, STATIC_FLASH)


func _end_flash() -> void:
	_picture.texture = _frames[0]
	_flash_left = 0.0
	_next_flash = randf_range(MIN_GAP, MAX_GAP)
	ScreenFx.set_static_strength(_static_layer, STATIC_IDLE)


## Para el menú de pruebas: provoca el golpe sin esperar.
func debug_flash_now() -> void:
	if _picture != null and _frames.size() > 1 and _flash_left <= 0.0:
		_start_flash()
