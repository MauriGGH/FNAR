extends Control

## La oficina. Tres vistas separadas (izquierda, centro, derecha). Al llevar el
## mouse a un borde, o con A y D, la cabeza gira a la vista de al lado con un
## barrido de 0.3 s y desenfoque horizontal. Cada vista es más ancha que la
## pantalla, así que antes de girar se puede recorrer un poco con el mouse.
## Las zonas de clic salen de los JSON de data/ y el acercamiento a la PC
## encuadra la zona monitor_screen de la vista central.

signal door_toggled(is_closed: bool)
signal pc_requested()
signal notice_requested(text: String, duration: float)

const CENTER_ZONES_PATH: String = "res://data/oficina_zonas.json"
const RIGHT_ZONES_PATH: String = "res://data/oficina_derecha_zonas.json"
const LEFT_ZONES_PATH: String = "res://data/oficina_izquierda_zonas.json"

## Vista derecha con la silla del cubículo 3 vacía: el Come Trabas ya se levantó.
const RIGHT_EMPTY_TEXTURE: Texture2D = preload("res://assets/art/office/oficina_derecha_vacia.png")

## El JSON de la vista central no trae el campo clickable, así que va aquí.
const CENTER_CLICKABLE: Array[String] = ["monitor", "lock_box", "phone", "flashlight"]

## Cada vista se dibuja este factor más grande que la pantalla. Lo que sobra a
## lo ancho es el recorrido del mouse; a cambio se recorta un poco arriba y abajo.
const VIEW_SCALE: float = 1.18

# Recorrido dentro de una vista.
const EDGE_MARGIN: float = 190.0
const MAX_PAN_SPEED: float = 700.0
const PAN_SMOOTHING: float = 9.0
## Lo que hay que aguantar en el borde, ya sin recorrido, antes de que gire.
const EDGE_HOLD_TIME: float = 0.22

# Giro de cabeza entre vistas.
const SWEEP_TIME: float = 0.3
## Desenfoque máximo a mitad del barrido, en fracción del ancho de la textura.
const MAX_SWEEP_BLUR: float = 0.028

## Lo que tarda el acercamiento a la pantalla de la PC.
const ZOOM_TIME: float = 0.4

# Corrección de color de la vista derecha, medida contra la central:
# le baja el cian (más rojo, menos verde) y la deja un poco más oscura.
const RIGHT_CHANNEL_GAIN: Vector3 = Vector3(1.14, 0.94, 1.0)
const RIGHT_SATURATION: float = 0.84
const RIGHT_BRIGHTNESS: float = 0.92

# La vista izquierda venía mucho más oscura que la central (luma 0.05 contra
# 0.12), así que el brillo es el valor grueso a mover aquí.
const LEFT_CHANNEL_GAIN: Vector3 = Vector3(1.14, 0.94, 1.0)
const LEFT_SATURATION: float = 0.84
const LEFT_BRIGHTNESS: float = 2.2

const PHONE_NOTICE: String = "[el teléfono no suena todavía]"
const FLASHLIGHT_NOTICE: String = "[la linterna todavía no funciona]"
const SERVER_ROOM_NOTICE: String = "[sala de servidores: próximamente]"
const BREAKER_NOTICE: String = "[breaker: próximamente]"
const NOTICE_TIME: float = 1.6

const PRESENCE_SIZE: Vector2 = Vector2(360.0, 34.0)
const DOOR_STATE_SIZE: Vector2 = Vector2(200.0, 28.0)

enum ViewState { PANNING, SWEEPING, ZOOMING_IN, ZOOMED, ZOOMING_OUT }
enum View { LEFT, CENTER, RIGHT }

var is_door_closed: bool = false
var is_interactive: bool = true

var _state: ViewState = ViewState.PANNING
var _current_view: int = View.CENTER
var _pan_offsets: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var _pan_speed: float = 0.0
var _edge_hold: float = 0.0
var _zones: Dictionary = {}  # id -> OfficeZone
var _view_tween: Tween = null
var _sweep_from: Control = null
var _sweep_to: Control = null
var _sweep_direction: int = 1

@onready var views: Control = $Views
@onready var left_view: Control = $Views/LeftView
@onready var center_view: Control = $Views/CenterView
@onready var right_view: Control = $Views/RightView
@onready var left_content: Control = $Views/LeftView/Content
@onready var center_content: Control = $Views/CenterView/Content
@onready var right_content: Control = $Views/RightView/Content
@onready var left_image: TextureRect = $Views/LeftView/Content/Background
@onready var center_image: TextureRect = $Views/CenterView/Content/Background
@onready var right_image: TextureRect = $Views/RightView/Content/Background

var door_presence_label: Label = null
var window_presence_label: Label = null
var door_state_label: Label = null

var _view_nodes: Array[Control] = []
var _content_nodes: Array[Control] = []
var _right_normal_texture: Texture2D = null


func _ready() -> void:
	clip_contents = true
	_view_nodes = [left_view, center_view, right_view]
	_content_nodes = [left_content, center_content, right_content]

	_right_normal_texture = right_image.texture
	_apply_view_grade(left_image, LEFT_CHANNEL_GAIN, LEFT_SATURATION, LEFT_BRIGHTNESS)
	_apply_view_grade(right_image, RIGHT_CHANNEL_GAIN, RIGHT_SATURATION, RIGHT_BRIGHTNESS)
	_build_zones(CENTER_ZONES_PATH, $Views/CenterView/Content/Zones, CENTER_CLICKABLE)
	_build_zones(RIGHT_ZONES_PATH, $Views/RightView/Content/Zones, [])
	_build_zones(LEFT_ZONES_PATH, $Views/LeftView/Content/Zones, [])
	_build_labels()
	_layout()
	resized.connect(_layout)

	for i: int in _view_nodes.size():
		_view_nodes[i].visible = i == _current_view
		_view_nodes[i].position = Vector2.ZERO

	set_door_presence("")
	set_window_presence("")
	_refresh_door()


## El night.gd apaga la interacción mientras las cámaras están arriba, para que
## la oficina no se mueva ni gire a espaldas del jugador.
func set_interactive(interactive: bool) -> void:
	is_interactive = interactive
	if not interactive:
		_pan_speed = 0.0
		_edge_hold = 0.0


# --- Colocación ---------------------------------------------------------------

## Cada vista ocupa la pantalla y recorta; su contenido es VIEW_SCALE más grande.
func _layout() -> void:
	views.position = Vector2.ZERO
	views.size = size
	var content_size: Vector2 = size * VIEW_SCALE
	for i: int in _view_nodes.size():
		_view_nodes[i].size = size
		_content_nodes[i].size = content_size
		if is_zero_approx(_pan_offsets[i]):
			_pan_offsets[i] = _pan_limit() * 0.5  # Arranca a la mitad del recorrido.
		_apply_content_position(i)
	_layout_zones()


## Lo más negativo que puede valer el recorrido horizontal de una vista.
func _pan_limit() -> float:
	return -(size.x * VIEW_SCALE - size.x)


func _content_top() -> float:
	return -(size.y * VIEW_SCALE - size.y) * 0.5


func _apply_content_position(index: int) -> void:
	_content_nodes[index].position = Vector2(_pan_offsets[index], _content_top())


func _layout_zones() -> void:
	var content_size: Vector2 = size * VIEW_SCALE
	for zone_id: String in _zones:
		var zone: OfficeZone = _zones[zone_id]
		zone.position = Vector2(
			zone.normalized_rect.position.x * content_size.x,
			zone.normalized_rect.position.y * content_size.y)
		zone.size = Vector2(
			zone.normalized_rect.size.x * content_size.x,
			zone.normalized_rect.size.y * content_size.y)
	# Separaciones distintas para que los dos textos no se toquen cuando
	# Barcosa está en la puerta y Mamador en el cristal a la vez.
	_place_above_zone(door_presence_label, "entrance_door", PRESENCE_SIZE, 6.0)
	_place_above_zone(window_presence_label, "front_glass", PRESENCE_SIZE, 16.0)
	_place_below_zone(door_state_label, "lock_box", DOOR_STATE_SIZE)


# --- Recorrido y giro ---------------------------------------------------------

func _process(delta: float) -> void:
	if _state != ViewState.PANNING or not is_interactive:
		return

	var mouse_x: float = get_local_mouse_position().x
	var direction: int = 0
	var target_speed: float = 0.0
	if mouse_x < EDGE_MARGIN:
		direction = -1
		target_speed = (1.0 - clampf(mouse_x, 0.0, EDGE_MARGIN) / EDGE_MARGIN) * MAX_PAN_SPEED
	elif mouse_x > size.x - EDGE_MARGIN:
		direction = 1
		var depth: float = clampf(mouse_x, 0.0, size.x) - (size.x - EDGE_MARGIN)
		target_speed = -depth / EDGE_MARGIN * MAX_PAN_SPEED

	_pan_speed = lerpf(_pan_speed, target_speed, 1.0 - exp(-delta * PAN_SMOOTHING))
	if direction == 0:
		_edge_hold = 0.0
		if absf(_pan_speed) >= 1.0:
			_move_current_content(delta)
		return

	# Primero se agota el recorrido de la vista; solo entonces gira la cabeza.
	var moved: bool = _move_current_content(delta)
	if moved:
		_edge_hold = 0.0
		return
	_edge_hold += delta
	if _edge_hold >= EDGE_HOLD_TIME:
		rotate_view(direction)


## Mueve el contenido de la vista actual. Devuelve false si ya topó.
func _move_current_content(delta: float) -> bool:
	var before: float = _pan_offsets[_current_view]
	var after: float = clampf(before + _pan_speed * delta, _pan_limit(), 0.0)
	if is_equal_approx(before, after):
		return false
	_pan_offsets[_current_view] = after
	_apply_content_position(_current_view)
	return true


## Gira a la vista de al lado: -1 hacia la izquierda, 1 hacia la derecha.
func rotate_view(direction: int) -> void:
	if _state != ViewState.PANNING:
		return
	var target: int = _current_view + direction
	if target < 0 or target >= _view_nodes.size():
		return

	_state = ViewState.SWEEPING
	_pan_speed = 0.0
	_edge_hold = 0.0
	_sweep_direction = direction
	_sweep_from = _view_nodes[_current_view]
	_sweep_to = _view_nodes[target]
	_sweep_to.visible = true
	_sweep_to.position.x = direction * size.x

	if _view_tween != null and _view_tween.is_valid():
		_view_tween.kill()
	# EASE_IN_OUT con seno: arranca y frena suave, como un giro de cabeza.
	_view_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_view_tween.tween_method(_apply_sweep, 0.0, 1.0, SWEEP_TIME)
	_view_tween.tween_callback(_on_sweep_finished.bind(target))


func _apply_sweep(progress: float) -> void:
	_sweep_from.position.x = -_sweep_direction * progress * size.x
	_sweep_to.position.x = _sweep_direction * (1.0 - progress) * size.x
	# El desenfoque sigue la velocidad del barrido: máximo justo a la mitad.
	_set_blur(sin(progress * PI) * MAX_SWEEP_BLUR)


func _on_sweep_finished(target: int) -> void:
	_sweep_from.visible = false
	_sweep_from.position.x = 0.0
	_sweep_to.position.x = 0.0
	_current_view = target
	_set_blur(0.0)
	_state = ViewState.PANNING


func _set_blur(amount: float) -> void:
	for image: TextureRect in [left_image, center_image, right_image]:
		var material: ShaderMaterial = image.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("blur_amount", amount)


func _apply_view_grade(image: TextureRect, gain: Vector3, saturation: float, brightness: float) -> void:
	var material: ShaderMaterial = image.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("channel_gain", gain)
	material.set_shader_parameter("saturation", saturation)
	material.set_shader_parameter("brightness", brightness)


## Cuando el Come Trabas se levanta, la silla del cubículo 3 queda vacía.
func set_right_view_empty(is_empty: bool) -> void:
	right_image.texture = RIGHT_EMPTY_TEXTURE if is_empty else _right_normal_texture


func _unhandled_input(event: InputEvent) -> void:
	if not is_interactive or _state != ViewState.PANNING:
		return
	if event.is_action_pressed("turn_left"):
		rotate_view(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("turn_right"):
		rotate_view(1)
		get_viewport().set_input_as_handled()


# --- Acercamiento a la PC -----------------------------------------------------

## Encuadra la pantalla del monitor y, al terminar, pide abrir la PC.
func zoom_to_pc() -> void:
	if _state != ViewState.PANNING:
		return
	var target: Rect2 = zone_rect("monitor_screen")
	if target.size.x <= 0.0 or target.size.y <= 0.0:
		pc_requested.emit()
		return
	_state = ViewState.ZOOMING_IN
	_pan_speed = 0.0
	var factor: float = maxf(size.x / target.size.x, size.y / target.size.y)
	var target_position: Vector2 = size * 0.5 - target.get_center() * factor
	_tween_content(target_position, Vector2(factor, factor), _on_zoom_in_finished)


## Vuelve la vista a donde estaba antes del acercamiento.
func zoom_out() -> void:
	if _state == ViewState.PANNING or _state == ViewState.ZOOMING_OUT:
		return
	_state = ViewState.ZOOMING_OUT
	_tween_content(Vector2(_pan_offsets[View.CENTER], _content_top()), Vector2.ONE, _on_zoom_out_finished)


func _tween_content(target_position: Vector2, target_scale: Vector2, on_finished: Callable) -> void:
	if _view_tween != null and _view_tween.is_valid():
		_view_tween.kill()
	_view_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_view_tween.tween_property(center_content, "position", target_position, ZOOM_TIME)
	_view_tween.parallel().tween_property(center_content, "scale", target_scale, ZOOM_TIME)
	_view_tween.tween_callback(on_finished)


func _on_zoom_in_finished() -> void:
	_state = ViewState.ZOOMED
	pc_requested.emit()


func _on_zoom_out_finished() -> void:
	_state = ViewState.PANNING


# --- Zonas --------------------------------------------------------------------

func _build_zones(path: String, holder: Control, default_clickable: Array[String]) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir " + path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Las zonas de la oficina no tienen un JSON válido: " + path)
		return

	var zones: Dictionary = (parsed as Dictionary).get("zones", {})
	for zone_id: String in zones:
		var data: Dictionary = zones[zone_id]
		var zone: OfficeZone = OfficeZone.new()
		zone.name = zone_id
		zone.zone_id = zone_id
		zone.description = str(data.get("desc", ""))
		zone.normalized_rect = Rect2(
			float(data.get("x", 0.0)), float(data.get("y", 0.0)),
			float(data.get("w", 0.0)), float(data.get("h", 0.0)))
		# El JSON de la derecha trae clickable; el de la central no.
		zone.is_clickable = bool(data.get("clickable", zone_id in default_clickable))
		# Las zonas de referencia no deben robarle el clic a las de verdad.
		zone.mouse_filter = Control.MOUSE_FILTER_STOP if zone.is_clickable else Control.MOUSE_FILTER_IGNORE
		zone.clicked.connect(_on_zone_clicked)
		holder.add_child(zone)
		_zones[zone_id] = zone


## Rectángulo de una zona en píxeles, dentro del contenido de su vista.
func zone_rect(zone_id: String) -> Rect2:
	if not _zones.has(zone_id):
		return Rect2()
	var zone: OfficeZone = _zones[zone_id]
	return Rect2(zone.position, zone.size)


## F3: dibuja todas las zonas de las tres vistas para poder revisarlas.
func set_zones_visible(is_visible: bool) -> void:
	for zone_id: String in _zones:
		(_zones[zone_id] as OfficeZone).set_debug_shown(is_visible)


func _on_zone_clicked(zone_id: String) -> void:
	match zone_id:
		"monitor":
			zoom_to_pc()
		"lock_box":
			_toggle_door()
		"phone":
			notice_requested.emit(PHONE_NOTICE, NOTICE_TIME)
		"flashlight":
			notice_requested.emit(FLASHLIGHT_NOTICE, NOTICE_TIME)
		"server_room":
			notice_requested.emit(SERVER_ROOM_NOTICE, NOTICE_TIME)
		"breaker":
			notice_requested.emit(BREAKER_NOTICE, NOTICE_TIME)


# --- Puerta y presencias ------------------------------------------------------

func _toggle_door() -> void:
	is_door_closed = not is_door_closed
	_refresh_door()
	door_toggled.emit(is_door_closed)


func _refresh_door() -> void:
	door_state_label.text = "CHAPA CERRADA" if is_door_closed else "CHAPA ABIERTA"
	door_state_label.modulate = Color(1.0, 0.75, 0.2) if is_door_closed else Color(0.65, 0.7, 0.7)


## Quién se ve en la puerta de entrada. Vacío = nadie.
func set_door_presence(text: String) -> void:
	_set_presence(door_presence_label, text)


## Quién se ve asomado al cristal. Vacío = nadie.
func set_window_presence(text: String) -> void:
	_set_presence(window_presence_label, text)


func _set_presence(label: Label, text: String) -> void:
	label.text = text
	label.visible = not text.is_empty()


# --- Etiquetas creadas por código --------------------------------------------
# Van pegadas a su zona de la vista central, así que se recolocan con ella.

func _build_labels() -> void:
	door_presence_label = _make_label(22, Color(0.98, 0.45, 0.4))
	window_presence_label = _make_label(22, Color(0.98, 0.62, 0.35))
	door_state_label = _make_label(19, Color(0.65, 0.7, 0.7))
	center_content.add_child(door_presence_label)
	center_content.add_child(window_presence_label)
	center_content.add_child(door_state_label)


func _make_label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	# Contorno negro para que el texto se lea sobre la foto oscura.
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	return label


func _place_above_zone(label: Label, zone_id: String, label_size: Vector2, gap: float) -> void:
	if label == null:
		return
	var rect: Rect2 = zone_rect(zone_id)
	label.size = label_size
	label.position = Vector2(rect.get_center().x - label_size.x * 0.5, rect.position.y - label_size.y - gap)


func _place_below_zone(label: Label, zone_id: String, label_size: Vector2) -> void:
	if label == null:
		return
	var rect: Rect2 = zone_rect(zone_id)
	label.size = label_size
	label.position = Vector2(rect.get_center().x - label_size.x * 0.5, rect.end.y + 4.0)
