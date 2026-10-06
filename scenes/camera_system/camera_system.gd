extends Control

## Sistema de 12 cámaras a pantalla completa. Se abre y cierra pasando el mouse
## por la barra de abajo o con Espacio. Encima del "video" van la estática, las
## líneas de escaneo, la viñeta y las esquinas del visor.

signal opened()
signal closed()
signal camera_changed(camera: int)

const MINIMAP_DATA_PATH: String = "res://data/minimapa_camaras.json"
const DEFAULT_CAMERA: int = 1

# Estática: medio segundo fuerte al cambiar de cámara y luego de reposo.
const STATIC_IDLE: float = 0.07
const STATIC_STRONG: float = 0.7
const STRONG_STATIC_TIME: float = 0.5

const REC_BLINK_TIME: float = 0.55
## Cada cuánto se repinta la etiqueta de depuración.
const DEBUG_REFRESH_TIME: float = 0.2

# Botones del minimapa: grises con borde claro, verde el de la cámara actual.
const BUTTON_IDLE: Color = Color(0.21, 0.22, 0.25, 0.85)
const BUTTON_HOVER: Color = Color(0.34, 0.36, 0.4, 0.9)
const BUTTON_ACTIVE: Color = Color(0.1, 0.62, 0.25, 0.95)
const BUTTON_BORDER: Color = Color(0.86, 0.88, 0.9, 0.8)
const BUTTON_FONT_SIZE: int = 13

var is_open: bool = false
var current_camera: int = DEFAULT_CAMERA

var _animatronics: Array[Animatronic] = []
var _camera_buttons: Dictionary = {}  # número de cámara -> Button
var _map_size: Vector2 = Vector2(640.0, 440.0)
var _static_tween: Tween = null
var _debug_elapsed: float = 0.0

@onready var static_overlay: ColorRect = $StaticOverlay
@onready var camera_name_label: Label = $CameraNameLabel
@onready var rec_dot: ColorRect = $RecDot
@onready var debug_label: Label = $DebugOccupantsLabel
@onready var minimap_frame: Control = $Minimap
@onready var minimap_scale: Control = $Minimap/MinimapScale
@onready var minimap_buttons: Control = $Minimap/MinimapScale/CameraButtons


func _ready() -> void:
	visible = false
	_set_static_strength(STATIC_IDLE)
	_start_rec_blink()
	_build_minimap_buttons()
	minimap_frame.resized.connect(_fit_minimap)
	_fit_minimap()


## F3: el night.gd prende y apaga la depuración de todos a la vez.
func set_debug_visible(is_debug_visible: bool) -> void:
	debug_label.visible = is_debug_visible


## El night.gd le pasa la lista de profes para poder decir quién está en cada cámara.
func set_animatronics(animatronics: Array[Animatronic]) -> void:
	_animatronics = animatronics
	for animatronic: Animatronic in _animatronics:
		animatronic.moved.connect(_on_animatronic_moved)


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_refresh_view()
	_play_strong_static()
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	closed.emit()


## Cambia de cámara; la estática fuerte solo se repite si de verdad cambió.
func switch_to_camera(camera: int) -> void:
	if camera == current_camera:
		return
	current_camera = camera
	_refresh_view()
	_play_strong_static()
	camera_changed.emit(current_camera)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_cameras"):
		toggle()
		get_viewport().set_input_as_handled()


# --- Vista --------------------------------------------------------------------

func _refresh_view() -> void:
	var room: String = Rooms.room_of_camera(current_camera)
	camera_name_label.text = "CAM %02d  %s" % [current_camera, Rooms.display_name(room).to_upper()]
	_refresh_occupants(room)
	_refresh_minimap_highlight()


## Etiqueta de depuración: quién hay en la habitación que se está viendo, en qué
## anda cada profe y si el pasillo está reservado. La reemplazarán los sprites.
func _refresh_occupants(room: String) -> void:
	var here: PackedStringArray = PackedStringArray()
	for animatronic: Animatronic in _animatronics:
		if animatronic.current_room == room:
			here.append(animatronic.display_name)

	var lines: PackedStringArray = PackedStringArray()
	lines.append("[F3] aqui: " + (", ".join(here) if not here.is_empty() else "nadie"))
	for animatronic: Animatronic in _animatronics:
		var info: String = animatronic.debug_text()
		if not info.is_empty():
			lines.append("%s: %s" % [animatronic.display_name, info])
	lines.append("pasillo: " + ("libre" if GameManager.is_hallway_free() else "ocupado"))
	debug_label.text = "\n".join(lines)


## Las etapas cambian sin que nadie se mueva, así que la etiqueta se repinta sola.
func _process(delta: float) -> void:
	if not is_open or not debug_label.visible:
		return
	_debug_elapsed += delta
	if _debug_elapsed < DEBUG_REFRESH_TIME:
		return
	_debug_elapsed = 0.0
	_refresh_occupants(Rooms.room_of_camera(current_camera))


func _on_animatronic_moved(_from_room: String, _to_room: String) -> void:
	if is_open:
		_refresh_occupants(Rooms.room_of_camera(current_camera))


func _set_static_strength(value: float) -> void:
	var material: ShaderMaterial = static_overlay.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("strength", value)


## Golpe de estática al cambiar de cámara: fuerte y se va bajando en 0.5 s.
func _play_strong_static() -> void:
	var material: ShaderMaterial = static_overlay.material as ShaderMaterial
	if material == null:
		return
	if _static_tween != null and _static_tween.is_valid():
		_static_tween.kill()
	material.set_shader_parameter("strength", STATIC_STRONG)
	_static_tween = create_tween()
	_static_tween.tween_property(material, "shader_parameter/strength", STATIC_IDLE, STRONG_STATIC_TIME)


## El punto rojo de "grabando" parpadea sin parar.
func _start_rec_blink() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(rec_dot, "modulate:a", 0.15, REC_BLINK_TIME)
	tween.tween_property(rec_dot, "modulate:a", 1.0, REC_BLINK_TIME)


# --- Minimapa -----------------------------------------------------------------

## Crea un botón por cada entrada de data/minimapa_camaras.json, con su
## posición, tamaño y etiqueta tal cual vienen en el archivo.
func _build_minimap_buttons() -> void:
	var file: FileAccess = FileAccess.open(MINIMAP_DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir " + MINIMAP_DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("El minimapa no tiene un JSON válido: " + MINIMAP_DATA_PATH)
		return

	var data: Dictionary = parsed
	_map_size = _to_vector2(data.get("map_size", [640, 440]), Vector2(640.0, 440.0))
	var button_size: Vector2 = _to_vector2(data.get("button_size", [40, 18]), Vector2(40.0, 18.0))

	for entry: Dictionary in data.get("cameras", []):
		var camera: int = int(entry.get("id", 0))
		if camera == Rooms.NO_CAMERA:
			continue
		var button: Button = Button.new()
		button.text = str(entry.get("label", "CAM %02d" % camera))
		button.tooltip_text = str(entry.get("place", Rooms.display_name(Rooms.room_of_camera(camera))))
		button.clip_text = true
		button.focus_mode = Control.FOCUS_NONE  # Para que Espacio no lo "pulse".
		button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
		_paint_button(button, BUTTON_IDLE, false)
		button.pressed.connect(switch_to_camera.bind(camera))
		minimap_buttons.add_child(button)
		# El tamaño va después de entrar al árbol, ya sin el mínimo del tema.
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		button.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		button.size = button_size
		_camera_buttons[camera] = button

	_refresh_minimap_highlight()


## Escala la imagen y los botones juntos para que quepan en el hueco del minimapa.
func _fit_minimap() -> void:
	if _map_size.x <= 0.0 or _map_size.y <= 0.0:
		return
	minimap_scale.size = _map_size
	var factor: float = minf(minimap_frame.size.x / _map_size.x, minimap_frame.size.y / _map_size.y)
	minimap_scale.scale = Vector2(factor, factor)


## Pinta de verde el botón de la cámara que se está viendo.
func _refresh_minimap_highlight() -> void:
	for camera: int in _camera_buttons:
		var button: Button = _camera_buttons[camera]
		var is_active: bool = camera == current_camera
		_paint_button(button, BUTTON_ACTIVE if is_active else BUTTON_IDLE, is_active)


## El tema por defecto de Godot le pone un tamaño mínimo a los botones; con los
## márgenes de contenido en cero respetan el tamaño exacto que pide el JSON.
func _paint_button(button: Button, color: Color, is_active: bool) -> void:
	button.add_theme_stylebox_override("normal", _make_box(color))
	button.add_theme_stylebox_override("hover", _make_box(BUTTON_ACTIVE if is_active else BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _make_box(BUTTON_ACTIVE))
	button.add_theme_stylebox_override("disabled", _make_box(color))
	button.add_theme_stylebox_override("focus", _make_box(Color(0.0, 0.0, 0.0, 0.0)))


func _make_box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_border_width_all(1)
	box.border_color = BUTTON_BORDER
	box.set_content_margin_all(0.0)
	return box


func _to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	var array: Array = value as Array
	if array == null or array.size() < 2:
		return fallback
	return Vector2(float(array[0]), float(array[1]))
