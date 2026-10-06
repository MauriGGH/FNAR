extends Control

## La oficina. Tres vistas en fila (izquierda, centro, derecha) que se deslizan
## al acercar el mouse a los bordes, como en FNAF. Arranca en el centro, que es
## la única con imagen de verdad; las otras dos son placeholders.
## Las zonas de clic salen de data/oficina_zonas.json y el acercamiento a la PC
## encuadra la zona monitor_screen.

signal door_toggled(is_closed: bool)
signal pc_requested()
signal notice_requested(text: String, duration: float)

const ZONES_PATH: String = "res://data/oficina_zonas.json"

## Zonas que responden al clic. Las demás solo sirven de referencia.
const CLICKABLE_ZONES: Array[String] = ["monitor", "lock_box", "phone", "flashlight"]

# Deslizamiento de la panorámica.
const EDGE_MARGIN: float = 190.0
const MAX_PAN_SPEED: float = 950.0
const PAN_SMOOTHING: float = 9.0

## Lo que tarda el acercamiento a la pantalla de la PC.
const ZOOM_TIME: float = 0.4

const PHONE_NOTICE: String = "[el teléfono no suena todavía]"
const FLASHLIGHT_NOTICE: String = "[la linterna todavía no funciona]"
const NOTICE_TIME: float = 1.6

const PRESENCE_SIZE: Vector2 = Vector2(360.0, 34.0)
const DOOR_STATE_SIZE: Vector2 = Vector2(200.0, 28.0)

enum ViewState { PANNING, ZOOMING_IN, ZOOMED, ZOOMING_OUT }

var is_door_closed: bool = false

var _state: ViewState = ViewState.PANNING
var _pan_offset: float = 0.0
var _pan_speed: float = 0.0
var _zoom_tween: Tween = null
var _zones: Dictionary = {}  # id -> OfficeZone

@onready var pan: Control = $Pan
@onready var left_view: Control = $Pan/LeftView
@onready var center_view: Control = $Pan/CenterView
@onready var right_view: Control = $Pan/RightView
@onready var zones_holder: Control = $Pan/CenterView/Zones

var door_presence_label: Label = null
var window_presence_label: Label = null
var door_state_label: Label = null


func _ready() -> void:
	clip_contents = true
	_build_zones()
	_build_labels()
	_layout()
	resized.connect(_layout)
	_pan_offset = -size.x  # Arranca en la vista del centro.
	pan.position.x = _pan_offset
	set_door_presence("")
	set_window_presence("")
	_refresh_door()


# --- Panorámica ---------------------------------------------------------------

## Coloca las tres vistas en fila y recoloca las zonas y las etiquetas.
func _layout() -> void:
	pan.size = Vector2(size.x * 3.0, size.y)
	left_view.position = Vector2.ZERO
	left_view.size = size
	center_view.position = Vector2(size.x, 0.0)
	center_view.size = size
	right_view.position = Vector2(size.x * 2.0, 0.0)
	right_view.size = size
	_layout_zones()


## Mientras el mouse está cerca de un borde, la vista se desliza hacia ese lado.
## La velocidad crece conforme se acerca al borde y se suaviza con un lerp.
func _process(delta: float) -> void:
	if _state != ViewState.PANNING:
		return
	var mouse_x: float = get_local_mouse_position().x
	var target_speed: float = 0.0
	if mouse_x < EDGE_MARGIN:
		target_speed = (1.0 - clampf(mouse_x, 0.0, EDGE_MARGIN) / EDGE_MARGIN) * MAX_PAN_SPEED
	elif mouse_x > size.x - EDGE_MARGIN:
		var depth: float = clampf(mouse_x, 0.0, size.x) - (size.x - EDGE_MARGIN)
		target_speed = -depth / EDGE_MARGIN * MAX_PAN_SPEED

	_pan_speed = lerpf(_pan_speed, target_speed, 1.0 - exp(-delta * PAN_SMOOTHING))
	if absf(_pan_speed) < 1.0:
		return
	_pan_offset = clampf(_pan_offset + _pan_speed * delta, -2.0 * size.x, 0.0)
	pan.position.x = _pan_offset


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
	var center_in_pan: Vector2 = center_view.position + target.get_center()
	var target_position: Vector2 = size * 0.5 - center_in_pan * factor
	_tween_view(target_position, Vector2(factor, factor), _on_zoom_in_finished)


## Vuelve la vista a donde estaba antes del acercamiento.
func zoom_out() -> void:
	if _state == ViewState.PANNING or _state == ViewState.ZOOMING_OUT:
		return
	_state = ViewState.ZOOMING_OUT
	_tween_view(Vector2(_pan_offset, 0.0), Vector2.ONE, _on_zoom_out_finished)


func _tween_view(target_position: Vector2, target_scale: Vector2, on_finished: Callable) -> void:
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_zoom_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_zoom_tween.tween_property(pan, "position", target_position, ZOOM_TIME)
	_zoom_tween.parallel().tween_property(pan, "scale", target_scale, ZOOM_TIME)
	_zoom_tween.tween_callback(on_finished)


func _on_zoom_in_finished() -> void:
	_state = ViewState.ZOOMED
	pc_requested.emit()


func _on_zoom_out_finished() -> void:
	_state = ViewState.PANNING


# --- Zonas --------------------------------------------------------------------

func _build_zones() -> void:
	var file: FileAccess = FileAccess.open(ZONES_PATH, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir " + ZONES_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Las zonas de la oficina no tienen un JSON válido: " + ZONES_PATH)
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
		zone.is_clickable = zone_id in CLICKABLE_ZONES
		# Las zonas de referencia no deben robarle el clic a las de verdad.
		zone.mouse_filter = Control.MOUSE_FILTER_STOP if zone.is_clickable else Control.MOUSE_FILTER_IGNORE
		zone.clicked.connect(_on_zone_clicked)
		zones_holder.add_child(zone)
		_zones[zone_id] = zone


func _layout_zones() -> void:
	# El contenedor de zonas ya llena la vista por sus anclas; solo se
	# recolocan las zonas de dentro, que van en píxeles.
	for zone_id: String in _zones:
		var zone: OfficeZone = _zones[zone_id]
		zone.position = Vector2(zone.normalized_rect.position.x * size.x, zone.normalized_rect.position.y * size.y)
		zone.size = Vector2(zone.normalized_rect.size.x * size.x, zone.normalized_rect.size.y * size.y)
	# Separaciones distintas para que los dos textos no se toquen cuando
	# Barcosa está en la puerta y Mamador en el cristal a la vez.
	_place_above_zone(door_presence_label, "entrance_door", PRESENCE_SIZE, 6.0)
	_place_above_zone(window_presence_label, "front_glass", PRESENCE_SIZE, 16.0)
	_place_below_zone(door_state_label, "lock_box", DOOR_STATE_SIZE)


## Rectángulo de una zona en píxeles, dentro de la vista del centro.
func zone_rect(zone_id: String) -> Rect2:
	if not _zones.has(zone_id):
		return Rect2()
	var zone: OfficeZone = _zones[zone_id]
	return Rect2(zone.position, zone.size)


## F3: dibuja todas las zonas para poder revisarlas.
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
# Van pegadas a su zona, así que se construyen cuando ya existen las zonas.

func _build_labels() -> void:
	door_presence_label = _make_label(22, Color(0.98, 0.45, 0.4))
	window_presence_label = _make_label(22, Color(0.98, 0.62, 0.35))
	door_state_label = _make_label(19, Color(0.65, 0.7, 0.7))
	center_view.add_child(door_presence_label)
	center_view.add_child(window_presence_label)
	center_view.add_child(door_state_label)


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
