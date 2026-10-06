extends Control

## Sistema de 12 cámaras a pantalla completa. Se abre y cierra pasando el mouse
## por la barra de abajo o con Espacio. Encima del "video" van la estática, las
## líneas de escaneo, la viñeta y las esquinas del visor.

signal opened()
signal closed()
signal camera_changed(camera: int)

const MINIMAP_DATA_PATH: String = "res://data/minimapa_camaras.json"
## Imagen de un estado de cámara: basta agregar el png para que funcione.
const CAMERA_IMAGE_FORMAT: String = "res://assets/art/cameras/cam%02d_%s.png"
## Si falta la imagen de un estado, se usa la imagen base de esa cámara y se
## pone la etiqueta de texto encima. Así se pueden ir agregando de a poco.
const BASE_STATES: Array[String] = ["etapa0", "vacia", "base"]
const DEFAULT_CAMERA: int = 1

# Estática: medio segundo fuerte al cambiar de cámara y luego de reposo.
const STATIC_IDLE: float = 0.07
const STATIC_STRONG: float = 0.7
const STRONG_STATIC_TIME: float = 0.5

# Interferencia: cuando un profe entra o sale de la cámara que se está viendo,
# la imagen se tapa de estática y el estado nuevo recién se ve al aclararse.
const INTERFERENCE_MIN_TIME: float = 0.5
const INTERFERENCE_MAX_TIME: float = 1.0
const STATIC_INTERFERENCE: float = 0.95
## Parte del tiempo que la estática se queda tapando antes de empezar a aclarar.
const INTERFERENCE_HOLD_RATIO: float = 0.65

const REC_BLINK_TIME: float = 0.55
## Estática fija de una cámara sin señal, y el parpadeo de su cartel.
const NO_SIGNAL_STATIC: float = 0.55
const NO_SIGNAL_BLINK_TIME: float = 0.7
## Color del botón del minimapa de una cámara caída.
const BUTTON_DOWN: Color = Color(0.3, 0.3, 0.31, 0.85)
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
var _interference_active: bool = false
var _come_trabas: ComeTrabas = null
var _winding: bool = false
var _image_cache: Dictionary = {}  # ruta -> Texture2D, o null si no existe
var _camera_signature: String = ""

@onready var feed_image: TextureRect = $FeedImage
@onready var static_overlay: ColorRect = $StaticOverlay
@onready var camera_name_label: Label = $CameraNameLabel
@onready var rec_dot: ColorRect = $RecDot
@onready var no_signal_label: Label = $NoSignalLabel
@onready var fallback_label: Label = $FallbackLabel
@onready var debug_label: Label = $DebugOccupantsLabel
@onready var minimap_frame: Control = $Minimap
@onready var minimap_scale: Control = $Minimap/MinimapScale
@onready var minimap_buttons: Control = $Minimap/MinimapScale/CameraButtons
## Todo el recuadro es el botón que se mantiene presionado.
@onready var wind_control: Button = $WindControl
@onready var wind_gauge: Control = $WindControl/WindGauge


func _ready() -> void:
	visible = false
	_set_static_strength(STATIC_IDLE)
	_start_rec_blink()
	_build_minimap_buttons()
	feed_image.visible = false
	no_signal_label.visible = false
	wind_control.visible = false
	GameManager.patch_panel.camera_restored.connect(_on_camera_restored)
	wind_control.keep_pressed_outside = true  # Soltar fuera del botón no se traba.
	wind_control.button_down.connect(_on_wind_button_down)
	wind_control.button_up.connect(_on_wind_button_up)
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
		if animatronic is ComeTrabas:
			_come_trabas = animatronic as ComeTrabas
			_come_trabas.wind_changed.connect(_on_wind_changed)


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open or PowerManager.is_blackout or GameManager.is_in_server_room:
		return  # Sin corriente, las cámaras no prenden.
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
	_interference_active = false
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
	_camera_signature = _signature_of(current_camera)
	_refresh_camera_content()
	_refresh_wind_control()
	_refresh_minimap_highlight()


## Lo que define si la cámara "cambió": el estado que reportan los profes más
## quiénes están en la habitación. Si cambia cualquiera de los dos mientras la
## estás viendo, entra la interferencia.
func _signature_of(camera: int) -> String:
	var room: String = Rooms.room_of_camera(camera)
	var names: PackedStringArray = PackedStringArray()
	for animatronic: Animatronic in _animatronics:
		if animatronic.current_room == room:
			names.append(animatronic.display_name)
	names.sort()
	return "%d|%s|%s" % [camera, _state_of(camera), "/".join(names)]


## El primer profe que tenga algo que decir de esta cámara define el estado.
func _state_of(camera: int) -> String:
	for animatronic: Animatronic in _animatronics:
		var state: String = animatronic.camera_state_for(camera)
		if not state.is_empty():
			return state
	return ""


## Busca la imagen del estado. Si no existe, usa la imagen base de la cámara y
## deja la etiqueta de texto encima; si tampoco hay base, queda el fondo gris.
func _refresh_camera_content() -> void:
	var room: String = Rooms.room_of_camera(current_camera)
	# Sin señal no se ve nada: estática fija y el cartel parpadeando.
	if GameManager.patch_panel.is_camera_down(current_camera):
		feed_image.visible = false
		fallback_label.visible = false
		no_signal_label.visible = true
		_set_static_strength(NO_SIGNAL_STATIC)
		_refresh_occupants(room)
		return
	no_signal_label.visible = false
	var state: String = _state_of(current_camera)
	var texture: Texture2D = _camera_texture(current_camera, state)
	var is_exact: bool = texture != null
	if not is_exact:
		texture = _base_texture(current_camera, state)

	feed_image.texture = texture
	feed_image.visible = texture != null
	_refresh_fallback_label(state, is_exact, room)
	_refresh_occupants(room)


## La etiqueta provisional: solo sale cuando la imagen no es la del estado.
func _refresh_fallback_label(state: String, is_exact: bool, room: String) -> void:
	if is_exact:
		fallback_label.visible = false
		return
	var parts: PackedStringArray = PackedStringArray()
	if not state.is_empty():
		parts.append(state)
	for animatronic: Animatronic in _animatronics:
		if animatronic.current_room == room:
			parts.append(animatronic.display_name)
	fallback_label.visible = not parts.is_empty()
	if fallback_label.visible:
		fallback_label.text = "[sin imagen] " + " - ".join(parts)


func _camera_texture(camera: int, state: String) -> Texture2D:
	if state.is_empty():
		return null
	return _load_texture(CAMERA_IMAGE_FORMAT % [camera, state])


## La imagen base de la cámara, la que sirve de respaldo.
func _base_texture(camera: int, state: String) -> Texture2D:
	for base: String in BASE_STATES:
		if base == state:
			continue
		var texture: Texture2D = _load_texture(CAMERA_IMAGE_FORMAT % [camera, base])
		if texture != null:
			return texture
	return null


func _load_texture(path: String) -> Texture2D:
	if _image_cache.has(path):
		return _image_cache[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	_image_cache[path] = texture  # Se guarda incluso si no existe, para no buscar dos veces.
	return texture


# --- Cuerda del Come Trabas ---------------------------------------------------

## El control de la cuerda solo sale en la cámara donde está la botarga.
func _refresh_wind_control() -> void:
	var should_show: bool = false
	if _come_trabas != null and _come_trabas.is_active and not _come_trabas.is_attacking:
		should_show = current_camera == Rooms.camera_of(_come_trabas.current_room)
	wind_control.visible = should_show
	if should_show:
		_on_wind_changed(_come_trabas.wind)


## El porcentaje exacto no se enseña: solo el reloj de pastel. El número sale
## únicamente en la etiqueta de depuración de F3.
func _on_wind_changed(percent: float) -> void:
	wind_gauge.set_percent(percent)


func _on_wind_button_down() -> void:
	_winding = true


func _on_wind_button_up() -> void:
	_winding = false


## Se le da cuerda solo mientras el botón esté apretado Y su cámara esté arriba:
## bajar las cámaras o cambiar de cámara deja de dar cuerda.
func _apply_winding() -> void:
	if _come_trabas == null:
		return
	_come_trabas.set_winding(_winding and is_open and wind_control.visible)


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
	_apply_winding()
	if not is_open or _interference_active:
		return
	_refresh_wind_control()
	if no_signal_label.visible:
		no_signal_label.modulate.a = 1.0 if fmod(_blink_elapsed(), NO_SIGNAL_BLINK_TIME * 2.0) < NO_SIGNAL_BLINK_TIME else 0.1
		_set_static_strength(NO_SIGNAL_STATIC)
	_debug_elapsed += delta
	if _debug_elapsed < DEBUG_REFRESH_TIME:
		return
	_debug_elapsed = 0.0
	# El estado cambia sin que nadie se mueva (la cuerda bajando, Barcosa
	# asomándose), así que la firma se revisa sola.
	check_camera_change()
	if debug_label.visible:
		_refresh_occupants(Rooms.room_of_camera(current_camera))


## Cualquier cambio en la cámara que se está viendo tapa la imagen: que un
## profe entre o salga, y también que cambie de estado sin moverse (la botarga
## despertando, Barcosa asomándose).
func _on_animatronic_moved(_from_room: String, _to_room: String) -> void:
	check_camera_change()


func check_camera_change() -> void:
	if not is_open or _interference_active:
		return
	var signature: String = _signature_of(current_camera)
	if signature == _camera_signature:
		return
	_camera_signature = signature
	_play_interference()


## Tapa la imagen con estática fuerte entre 0.5 y 1 s. Al aclararse, y solo
## entonces, se muestra el estado nuevo de la cámara.
func _play_interference() -> void:
	var material: ShaderMaterial = static_overlay.material as ShaderMaterial
	if material == null:
		return
	if _static_tween != null and _static_tween.is_valid():
		_static_tween.kill()
	_interference_active = true
	material.set_shader_parameter("strength", STATIC_INTERFERENCE)
	var duration: float = randf_range(INTERFERENCE_MIN_TIME, INTERFERENCE_MAX_TIME)
	_static_tween = create_tween()
	_static_tween.tween_interval(duration * INTERFERENCE_HOLD_RATIO)
	_static_tween.tween_property(material, "shader_parameter/strength", STATIC_IDLE,
		duration * (1.0 - INTERFERENCE_HOLD_RATIO))
	_static_tween.tween_callback(_on_interference_cleared)


## Al reconectar el cable en la sala de servidores, la cámara vuelve.
func _on_camera_restored(_camera: int) -> void:
	_refresh_minimap_highlight()
	if is_open:
		_camera_signature = ""  # Fuerza el repaso: la imagen cambió.


## La descarga llena de estática todas las cámaras y repinta el minimapa.
func on_discharge() -> void:
	_refresh_minimap_highlight()
	if not is_open:
		return
	_camera_signature = _signature_of(current_camera)
	_play_interference()


func _on_interference_cleared() -> void:
	_interference_active = false
	_refresh_camera_content()


## Reloj propio para los parpadeos, sin guardar otra variable.
func _blink_elapsed() -> float:
	return Time.get_ticks_msec() / 1000.0


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
	_interference_active = false
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
		if GameManager.patch_panel.is_camera_down(camera):
			_paint_button(button, BUTTON_DOWN, false)
			continue
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
