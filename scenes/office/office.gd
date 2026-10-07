extends Control

## La oficina. Tres vistas separadas (izquierda, centro, derecha). Al llevar el
## mouse a un borde, o con A y D, la cabeza gira a la vista de al lado con un
## barrido de 0.3 s y desenfoque horizontal. Cada vista es más ancha que la
## pantalla, así que antes de girar se puede recorrer un poco con el mouse.
## Las zonas de clic salen de los JSON de data/ y el acercamiento a la PC
## encuadra la zona monitor_screen de la vista central.

signal door_toggled(is_closed: bool)
signal pc_requested()
signal breaker_requested()
signal server_room_requested()
signal phone_requested()
## La linterna se prendió o se apagó de verdad.
signal flashlight_changed(is_on: bool)
## Se intentó prender pero el cortaso de Audel la dejó muerta.
signal flashlight_failed()
signal notice_requested(text: String, duration: float)

const CENTER_ZONES_PATH: String = "res://data/oficina_zonas.json"
const RIGHT_ZONES_PATH: String = "res://data/oficina_derecha_zonas.json"
const LEFT_ZONES_PATH: String = "res://data/oficina_izquierda_zonas.json"

## Vista derecha con la silla del cubículo 3 vacía: el Come Trabas ya se levantó.
const RIGHT_EMPTY_TEXTURE: Texture2D = preload("res://assets/art/office/oficina_derecha_vacia.png")
const BLACKOUT_OVERLAY: GDScript = preload("res://scenes/office/blackout_overlay.gd")
const FLASHLIGHT_OVERLAY: GDScript = preload("res://scenes/office/flashlight_overlay.gd")
const PHONE_LIGHT: GDScript = preload("res://scenes/office/phone_light.gd")
const DOOR_SHUTTER: GDScript = preload("res://scenes/office/door_shutter.gd")
const OFFICE_LAYERS: GDScript = preload("res://scenes/office/office_layers.gd")

## Máscara de oclusión de la puerta: los pedazos de la foto que están más
## cerca de la cámara que la puerta (el mueble de la recepción, su base y los
## perfiles del cristal) y que por lo tanto tapan la lámina de la cortina.
## La genera tools/make_door_occluder.py; si no está, no pasa nada.
const DOOR_OCCLUDER_PATH: String = "res://assets/art/office/layers/oclusor_puerta"

## Nombre de cada vista en los archivos de recorte: layers/centro_urena.png.
const VIEW_LAYER_NAMES: Array[String] = ["izquierda", "centro", "derecha"]
## La foto que deja Ureña es un recorte del tamaño de la vista central, ya
## colocado sobre el escritorio, así que va como capa fija. Si alguna vez hay
## varias, se llamarán urena_foto_2, urena_foto_3... y se van encimando.
const URENA_PHOTO_LAYER: String = "urena_foto"

## El JSON de la vista central no trae el campo clickable, así que va aquí.
const CENTER_CLICKABLE: Array[String] = ["monitor", "lock_box", "phone", "flashlight"]

## La zona del cristal, que es lo que alumbra la linterna.
const GLASS_ZONE: String = "front_glass"
## Cuántas fotos puede llegar a dejar en una noche.
const MAX_URENA_PHOTOS: int = 4

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

# La vista izquierda viene mucho más oscura que la central (luma 0.040 contra
# 0.119) y con menos cian que la derecha, así que lleva poco ajuste de canal y
# un brillo alto. Medido: deja luma 0.117 y verde/rojo 1.25 (la central, 1.23).
const LEFT_CHANNEL_GAIN: Vector3 = Vector3(1.06, 0.96, 1.0)
const LEFT_SATURATION: float = 0.92
const LEFT_BRIGHTNESS: float = 2.95

# La vista derecha vacía se renderizó aparte y salió más cian que la normal
# (verde/rojo 1.75 contra 1.65), así que lleva su propia corrección.
const RIGHT_EMPTY_CHANNEL_GAIN: Vector3 = Vector3(1.26, 0.93, 0.99)
const RIGHT_EMPTY_SATURATION: float = 0.9
const RIGHT_EMPTY_BRIGHTNESS: float = 0.98

const FLASHLIGHT_NOTICE: String = "[sostén Ctrl o el clic sobre el cristal]"
const DOOR_NOTICE: String = "[clang]"
const NOTICE_TIME: float = 1.6

## El golpe de la cortina al llegar abajo sacude un poco la vista.
const SHAKE_TIME: float = 0.3
const SHAKE_PIXELS: float = 5.0

## Zonas sobre las que se ponen etiquetas de presencia, con su color y su
## separación. El profe decide qué dice en cada una con zone_presence().
const PRESENCE_ZONES: Array[Dictionary] = [
	{"zone": "entrance_door", "color": Color(0.98, 0.45, 0.4), "gap": 6.0},
	{"zone": "front_glass", "color": Color(0.98, 0.62, 0.35), "gap": 16.0},
	{"zone": "ladder", "color": Color(0.6, 0.85, 1.0), "gap": 6.0},
	{"zone": "cubicles_side", "color": Color(0.82, 0.6, 0.98), "gap": 6.0},
	{"zone": "doorway", "color": Color(0.82, 0.6, 0.98), "gap": 6.0},
]

## Puntos que siguen encendidos cuando se corta la corriente, por vista.
const BLACKOUT_SPOTS: Dictionary = {
	View.LEFT: [{"zone": "window", "radius": 110.0, "color": Color(0.62, 0.72, 0.95)}],
	View.CENTER: [{"zone": "lock_box", "radius": 34.0, "color": Color(0.3, 0.95, 0.45)}],
	View.RIGHT: [],
}

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

var door_state_label: Label = null

var _presence_labels: Dictionary = {}  # id de zona -> Label
var _blackout_overlays: Array[Control] = []
var _zoom_view: int = View.CENTER
var _zoom_request: String = ""
var _flashlight_on: bool = false
var _urena_photos: int = 0

var flashlight_overlay: Control = null
var phone_light: Control = null
var door_shutter: Control = null
var door_occluder: TextureRect = null
var _layers: Array[Control] = []
var _shake_left: float = 0.0

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
	# El orden importa: la cortina y su caja van sobre la foto, encima de
	# ellas la máscara de oclusión (lo que está delante de la puerta), después
	# los recortes de los profes del cristal y al final las etiquetas de
	# presencia, para que se lean con la cortina cerrada. La capa de oscuridad
	# se crea después de todo eso, así que la cortina y la máscara también se
	# apagan cuando se va la luz.
	_build_door_shutter()
	_build_door_occluder()
	_build_layers()
	_build_labels()
	_build_blackout_overlays()
	_build_flashlight()
	_layout()
	resized.connect(_layout)

	for i: int in _view_nodes.size():
		_view_nodes[i].visible = i == _current_view
		_view_nodes[i].position = Vector2.ZERO

	for entry: Dictionary in PRESENCE_ZONES:
		set_zone_presence(str(entry["zone"]), "")
	_refresh_door()


## La linterna se mantiene con Ctrl o con el clic izquierdo sostenido sobre el
## cristal, y solo sirve mirando al frente.
func _update_flashlight() -> void:
	var allowed: bool = is_interactive and _state == ViewState.PANNING and _current_view == View.CENTER
	var wants_on: bool = false
	if allowed:
		wants_on = Input.is_key_pressed(KEY_CTRL)
		if not wants_on and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			wants_on = zone_rect(GLASS_ZONE).has_point(center_content.get_local_mouse_position())

	if wants_on == _flashlight_on:
		return
	# Si el cortaso de Audel la dejó muerta, ni se prende.
	if wants_on and PowerManager.is_flashlight_disabled:
		flashlight_failed.emit()
		return
	_flashlight_on = wants_on
	# Los que solo se ven alumbrados aparecen y desaparecen con el haz.
	for layer: Control in _layers:
		layer.set_lit(_flashlight_on, zone_rect(GLASS_ZONE))
	flashlight_overlay.set_on(_flashlight_on)
	flashlight_changed.emit(_flashlight_on)


## Quién se ve en una zona, y el foquito del teléfono.
func set_phone_ringing(ringing: bool) -> void:
	if phone_light != null:
		phone_light.set_ringing(ringing)


## Un timbrazo: el foquito pega su destello y el teléfono tiembla.
func pulse_phone_ring() -> void:
	if phone_light != null:
		phone_light.pulse()


## Durante la llamada la pantallita se queda encendida, fija y más tenue.
func set_phone_in_call(in_call: bool) -> void:
	if phone_light != null:
		phone_light.set_in_call(in_call)


## Pega una foto de Ureña sobre el escritorio. Las fotos se quedan.
func add_urena_photo() -> void:
	if _urena_photos >= MAX_URENA_PHOTOS:
		return
	_urena_photos += 1
	_refresh_urena_photos()


## Cuántas fotos lleva pegadas, para la etiqueta de depuración.
func urena_photo_count() -> int:
	return _urena_photos


## Enseña los recortes de las fotos que ya dejó. La primera es urena_foto; de
## la segunda en adelante solo salen si existe su archivo.
func _refresh_urena_photos() -> void:
	if _layers.size() <= View.CENTER:
		return
	var layer: Control = _layers[View.CENTER]
	var names: PackedStringArray = PackedStringArray()
	for i: int in _urena_photos:
		var file_name: String = URENA_PHOTO_LAYER if i == 0 else "%s_%d" % [URENA_PHOTO_LAYER, i + 1]
		if layer.has_pinned(file_name):
			names.append(file_name)
	layer.set_pinned(names)


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
	# Separaciones distintas para que los textos no se toquen cuando hay
	# varios profes a la vista al mismo tiempo.
	for entry: Dictionary in PRESENCE_ZONES:
		_place_above_zone(_presence_labels[entry["zone"]], str(entry["zone"]),
			PRESENCE_SIZE, float(entry["gap"]))
	_place_below_zone(door_state_label, "lock_box", DOOR_STATE_SIZE)
	_layout_blackout_overlays()
	_layout_flashlight()


## El haz sale de abajo al centro, como si lo sostuviera el guardia.
func _layout_flashlight() -> void:
	var content_size: Vector2 = size * VIEW_SCALE
	if flashlight_overlay != null:
		flashlight_overlay.position = Vector2.ZERO
		flashlight_overlay.size = content_size
		flashlight_overlay.set_beam(zone_rect(GLASS_ZONE),
			Vector2(content_size.x * 0.5, content_size.y))
	for layer: Control in _layers:
		layer.position = Vector2.ZERO
		layer.size = content_size
		layer.set_lit(_flashlight_on, zone_rect(GLASS_ZONE))
	if door_occluder != null:
		door_occluder.position = Vector2.ZERO
		door_occluder.size = content_size
	if door_shutter != null:
		door_shutter.position = Vector2.ZERO
		door_shutter.size = content_size
		door_shutter.set_door_rect(zone_rect("entrance_door"))
	if phone_light != null:
		# Cubre todo el contenido: así el foquito y la pantallita se colocan
		# con las mismas normalizadas de las zonas y escalan con la vista.
		phone_light.position = Vector2.ZERO
		phone_light.size = content_size
		phone_light.set_background(center_image.texture)
		phone_light.set_phone_rect(zone_rect("phone"))


## Las capas de oscuridad cubren todo el contenido y sus puntos de luz van
## sobre las zonas que les tocan.
func _layout_blackout_overlays() -> void:
	var content_size: Vector2 = size * VIEW_SCALE
	for i: int in _blackout_overlays.size():
		var overlay: Control = _blackout_overlays[i]
		overlay.position = Vector2.ZERO
		overlay.size = content_size
		var spots: Array[Dictionary] = []
		for spot: Dictionary in BLACKOUT_SPOTS.get(i, []):
			var rect: Rect2 = zone_rect(str(spot["zone"]))
			if rect.size.x <= 0.0:
				continue
			spots.append({
				"position": rect.get_center(),
				"radius": float(spot["radius"]),
				"color": spot["color"],
			})
		overlay.set_spots(spots)


# --- Recorrido y giro ---------------------------------------------------------

func _process(delta: float) -> void:
	_update_shake(delta)
	_update_flashlight()
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
## La imagen vacía trae su propio color, así que el ajuste también cambia.
func set_right_view_empty(is_empty: bool) -> void:
	right_image.texture = RIGHT_EMPTY_TEXTURE if is_empty else _right_normal_texture
	if is_empty:
		_apply_view_grade(right_image, RIGHT_EMPTY_CHANNEL_GAIN, RIGHT_EMPTY_SATURATION, RIGHT_EMPTY_BRIGHTNESS)
	else:
		_apply_view_grade(right_image, RIGHT_CHANNEL_GAIN, RIGHT_SATURATION, RIGHT_BRIGHTNESS)


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
	_zoom_to_zone("monitor_screen", View.CENTER, "pc")


## Lo mismo con el tablero del breaker, en la vista izquierda.
func zoom_to_breaker() -> void:
	_zoom_to_zone("breaker", View.LEFT, "breaker")


## Acerca la vista a una zona y, al terminar, avisa qué se pidió abrir.
func _zoom_to_zone(zone_id: String, view: int, request: String) -> void:
	if _state != ViewState.PANNING or _current_view != view:
		return
	_zoom_request = request
	_zoom_view = view
	var target: Rect2 = zone_rect(zone_id)
	if target.size.x <= 0.0 or target.size.y <= 0.0:
		_emit_zoom_request()
		return
	_state = ViewState.ZOOMING_IN
	_pan_speed = 0.0
	var factor: float = maxf(size.x / target.size.x, size.y / target.size.y)
	var target_position: Vector2 = size * 0.5 - target.get_center() * factor
	_tween_content(target_position, Vector2(factor, factor), _on_zoom_in_finished)


func _emit_zoom_request() -> void:
	if _zoom_request == "breaker":
		breaker_requested.emit()
	else:
		pc_requested.emit()


## Vuelve la vista a donde estaba antes del acercamiento.
func zoom_out() -> void:
	if _state == ViewState.PANNING or _state == ViewState.ZOOMING_OUT:
		return
	_state = ViewState.ZOOMING_OUT
	_tween_content(Vector2(_pan_offsets[_zoom_view], _content_top()), Vector2.ONE, _on_zoom_out_finished)


func _tween_content(target_position: Vector2, target_scale: Vector2, on_finished: Callable) -> void:
	if _view_tween != null and _view_tween.is_valid():
		_view_tween.kill()
	var content: Control = _content_nodes[_zoom_view]
	_view_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_view_tween.tween_property(content, "position", target_position, ZOOM_TIME)
	_view_tween.parallel().tween_property(content, "scale", target_scale, ZOOM_TIME)
	_view_tween.tween_callback(on_finished)


func _on_zoom_in_finished() -> void:
	_state = ViewState.ZOOMED
	_emit_zoom_request()


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
		"flashlight":
			notice_requested.emit(FLASHLIGHT_NOTICE, NOTICE_TIME)
		"phone":
			phone_requested.emit()
		"server_room":
			server_room_requested.emit()
		"breaker":
			zoom_to_breaker()


# --- Puerta y presencias ------------------------------------------------------

func _toggle_door() -> void:
	is_door_closed = not is_door_closed
	_refresh_door()
	if is_door_closed:
		# La cortina pega contra el piso: ruido y sacudida.
		notice_requested.emit(DOOR_NOTICE, NOTICE_TIME)
		shake()
	door_toggled.emit(is_door_closed)


func _refresh_door() -> void:
	if door_shutter != null:
		door_shutter.set_closed(is_door_closed)
	door_state_label.text = "CHAPA CERRADA" if is_door_closed else "CHAPA ABIERTA"
	door_state_label.modulate = Color(1.0, 0.75, 0.2) if is_door_closed else Color(0.65, 0.7, 0.7)


## Las zonas que llevan etiqueta de presencia, para que el night.gd las recorra.
func presence_zone_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for entry: Dictionary in PRESENCE_ZONES:
		ids.append(str(entry["zone"]))
	return ids


## Quién se ve en una zona. Vacío = nadie.
func set_zone_presence(zone_id: String, text: String) -> void:
	if not _presence_labels.has(zone_id):
		return
	var label: Label = _presence_labels[zone_id]
	label.text = text
	label.visible = not text.is_empty()


# --- Etiquetas creadas por código --------------------------------------------
# Van pegadas a su zona de la vista central, así que se recolocan con ella.

func _build_labels() -> void:
	for entry: Dictionary in PRESENCE_ZONES:
		var label: Label = _make_label(22, entry["color"])
		_presence_labels[entry["zone"]] = label
		_content_for_zone(str(entry["zone"])).add_child(label)
	door_state_label = _make_label(19, Color(0.65, 0.7, 0.7))
	center_content.add_child(door_state_label)


## En qué vista vive una zona. Las de la izquierda y la derecha salen de sus
## propios JSON, así que se reconocen por ahí.
func _content_for_zone(zone_id: String) -> Control:
	if not _zones.has(zone_id):
		return center_content
	return (_zones[zone_id] as OfficeZone).get_parent().get_parent() as Control


## Una capa de recortes por vista, debajo de las etiquetas de presencia: si
## algún día existe el recorte, la etiqueta se apaga sola desde el night.gd.
func _build_layers() -> void:
	_layers.clear()
	for i: int in _content_nodes.size():
		var layer: Control = OFFICE_LAYERS.new()
		layer.name = "Layers"
		layer.view_name = VIEW_LAYER_NAMES[i]
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_nodes[i].add_child(layer)
		_layers.append(layer)


## Quiénes se ven en cada vista. El night.gd lo arma con los profes presentes;
## cada entrada es {"slug": String, "lit_only": bool}.
func set_view_present(view: int, present: Array[Dictionary]) -> void:
	if view < 0 or view >= _layers.size():
		return
	_layers[view].set_present(present)


## En qué vista vive una zona, como índice de View.
func view_of_zone(zone_id: String) -> int:
	var content: Control = _content_for_zone(zone_id)
	var index: int = _content_nodes.find(content)
	return index if index >= 0 else View.CENTER


## Cuántas vistas hay, para que el night.gd las recorra.
func view_count() -> int:
	return _layers.size()


## true si ya existe el recorte de ese profe para esa vista.
func has_layer(view: int, slug: String) -> bool:
	if view < 0 or view >= _layers.size():
		return false
	return _layers[view].has_layer(slug)


## La máscara de oclusión: va justo encima de la cortina, así que la lámina
## baja por detrás del mueble y de los perfiles del cristal.
func _build_door_occluder() -> void:
	var texture: Texture2D = GameAssets.load_texture(DOOR_OCCLUDER_PATH)
	if texture == null:
		return  # Todavía no se ha generado: la cortina se dibuja como antes.
	door_occluder = TextureRect.new()
	door_occluder.name = "DoorOccluder"
	door_occluder.texture = texture
	door_occluder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	door_occluder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_content.add_child(door_occluder)


## Sacude la vista un momento. Lo usa el golpe de la cortina.
func shake() -> void:
	_shake_left = SHAKE_TIME


func _update_shake(delta: float) -> void:
	if _shake_left <= 0.0:
		return
	_shake_left = maxf(_shake_left - delta, 0.0)
	var amount: float = _shake_left / SHAKE_TIME * SHAKE_PIXELS
	views.position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
	if _shake_left <= 0.0:
		views.position = Vector2.ZERO


## La cortina de la puerta vive en la vista central, debajo de las etiquetas
## de presencia: así Barcosa golpeando se sigue leyendo con la cortina abajo.
func _build_door_shutter() -> void:
	door_shutter = DOOR_SHUTTER.new()
	door_shutter.name = "DoorShutter"
	door_shutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_content.add_child(door_shutter)


## La linterna y el foquito del teléfono viven en la vista central.
func _build_flashlight() -> void:
	flashlight_overlay = FLASHLIGHT_OVERLAY.new()
	flashlight_overlay.name = "Flashlight"
	flashlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_content.add_child(flashlight_overlay)

	phone_light = PHONE_LIGHT.new()
	phone_light.name = "PhoneLight"
	phone_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone_light.visible = false
	center_content.add_child(phone_light)


## Una capa de oscuridad por vista, con sus puntos de luz.
func _build_blackout_overlays() -> void:
	_blackout_overlays.clear()
	for i: int in _content_nodes.size():
		var overlay: Control = BLACKOUT_OVERLAY.new()
		overlay.name = "Blackout"
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_nodes[i].add_child(overlay)
		_blackout_overlays.append(overlay)


## El night.gd avisa aquí cuando la corriente se corta o vuelve.
func set_blackout(blackout: bool) -> void:
	for overlay: Control in _blackout_overlays:
		overlay.set_blackout(blackout)


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
	# Las zonas pegadas a un borde dejarían la etiqueta fuera del contenido.
	var limit: float = maxf(size.x * VIEW_SCALE - label_size.x, 0.0)
	label.position = Vector2(
		clampf(rect.get_center().x - label_size.x * 0.5, 0.0, limit),
		rect.position.y - label_size.y - gap)


func _place_below_zone(label: Label, zone_id: String, label_size: Vector2) -> void:
	if label == null:
		return
	var rect: Rect2 = zone_rect(zone_id)
	label.size = label_size
	label.position = Vector2(rect.get_center().x - label_size.x * 0.5, rect.end.y + 4.0)
