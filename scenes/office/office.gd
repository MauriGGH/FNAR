extends Control

## La oficina. Tres vistas separadas (izquierda, centro, derecha). Todo se
## mueve **solo con A y D o con las flechas**, nunca con el mouse: manteniendo
## una de ellas la vista se desplaza hacia ese lado a velocidad constante (con
## un arranque y un frenado cortos), y cuando llega al borde de la vista y
## sigues manteniendo, la cabeza gira a la vista de al lado con el barrido de
## SWEEP_TIME y su desenfoque. Cada vista es más ancha que la pantalla: lo que
## sobra a los lados es ese recorrido.
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

## Las cuatro fotos de la vista central: a oscuras y alumbrada, con la puerta
## abierta y con la cortina ya abajo. Se cambian de par en par cuando la
## cortina termina de bajar o empieza a subir.
const CENTER_DARK: String = "res://assets/art/office/oficina_centro_oscura"
const CENTER_LIT: String = "res://assets/art/office/oficina_centro"
const CENTER_DARK_CLOSED: String = "res://assets/art/office/oficina_centro_oscura_cerrada"
const CENTER_LIT_CLOSED: String = "res://assets/art/office/oficina_centro_cerrada"
const BLACKOUT_OVERLAY: GDScript = preload("res://scenes/office/blackout_overlay.gd")
const FLASHLIGHT_OVERLAY: GDScript = preload("res://scenes/office/flashlight_overlay.gd")
const PHONE_LIGHT: GDScript = preload("res://scenes/office/phone_light.gd")
const DOOR_SHUTTER: GDScript = preload("res://scenes/office/door_shutter.gd")
const OFFICE_LAYERS: GDScript = preload("res://scenes/office/office_layers.gd")
const PHOTO_VIEWER: GDScript = preload("res://scenes/office/photo_viewer.gd")
const ARMANDO_EYE: GDScript = preload("res://scenes/office/armando_eye.gd")

## Nombre de cada vista en los archivos de recorte: layers/centro_urena.png.
const VIEW_LAYER_NAMES: Array[String] = ["izquierda", "centro", "derecha"]
## La foto que deja Ureña es un recorte del tamaño de la vista central, ya
## colocado sobre el escritorio, así que va como capa fija. Si alguna vez hay
## varias, se llamarán urena_foto_2, urena_foto_3... y se van encimando.
const URENA_PHOTO_LAYER: String = "urena_foto"

## El JSON de la vista central no trae el campo clickable, así que va aquí.
const CENTER_CLICKABLE: Array[String] = ["monitor", "lock_box", "phone", "flashlight"]

## La zona del cristal, que es por donde se asoman los del pasillo.
const GLASS_ZONE: String = "front_glass"
## La puerta de entrada, al fondo del pasillo. También la alumbra la linterna.
const GLASS_DOOR_ZONE: String = "entrance_door"

## La luz de la linterna, en normalizadas de la vista central. No se apunta:
## cubre toda la franja del pasillo (el recuadro de los seis recortes juntos,
## medido en data/office_layers.gd) crecida este tanto, con el borde
## difuminado para que no se vea ninguna línea dura.
const BEAM_MARGIN: float = 1.12
const BEAM_SOFTNESS: float = 0.14
## Lo rápido que entra y sale la luz al prender y apagar.
const BEAM_FADE_SPEED: float = 16.0
## El parpadeo del foco: cuánto baja y a qué velocidades. Son dos ondas de
## periodos que no encajan, así que no se le nota el compás.
const FLICKER_DEPTH: float = 0.07
const FLICKER_HZ_A: float = 11.0
const FLICKER_HZ_B: float = 27.3
## Cuántas fotos puede llegar a dejar en una noche.
const MAX_URENA_PHOTOS: int = 4
## La zona de clic de la foto, que solo se enciende cuando ya la dejó.
const URENA_PHOTO_ZONE: String = "urena_photo"

## Cada vista se dibuja este factor más grande que la pantalla. Lo que sobra a
## lo ancho es el recorrido lateral; a cambio se recorta un poco arriba y abajo.
const VIEW_SCALE: float = 1.18

## El recorrido lateral: a cuántos píxeles por segundo se desplaza la vista
## manteniendo A o D, y lo que tarda en arrancar y en frenar.
const PAN_SPEED: float = 420.0
const PAN_RAMP: float = 12.0
## Cuánto hay que seguir manteniendo, ya tocando el borde, para que gire.
const EDGE_HOLD_TIME: float = 0.18

# Recorrido dentro de una vista.
## Lo que hay que aguantar en el borde, ya sin recorrido, antes de que gire.

# Giro de cabeza entre vistas.
const SWEEP_TIME: float = 0.35
## Desenfoque máximo a mitad del barrido, en fracción del ancho de la textura.
const MAX_SWEEP_BLUR: float = 0.028

## Lo que tarda el acercamiento a la pantalla de la PC.
const ZOOM_TIME: float = 0.4

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
## Dónde queda el contenido de cada vista. Arranca centrado y se mueve con A
## y D; el mouse no lo toca.
var _pan_offsets: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
## La velocidad de ahora mismo (se acerca suave a la que toca) y lo que lleva
## apretado contra el borde.
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
## La foto del pasillo iluminada, que solo se ve dentro del cono.
@onready var center_lit: TextureRect = $Views/CenterView/Content/LitImage
@onready var right_image: TextureRect = $Views/RightView/Content/Background

var door_state_label: Label = null

var _presence_labels: Dictionary = {}  # id de zona -> Label
var _blackout_overlays: Array[Control] = []
var _zoom_view: int = View.CENTER
var _zoom_request: String = ""
var _flashlight_on: bool = false
## La zona que alumbra, fija sobre el pasillo, y cuánta luz hay ahora mismo
## (sube y baja suave al prender y apagar, con el parpadeo del foco encima).
var _beam_center: Vector2 = Vector2(0.5, 0.5)
var _beam_half: Vector2 = Vector2(0.3, 0.3)
var _beam_level: float = 0.0
var _beam_strength: float = 0.0
var _flicker_time: float = 0.0
## Depuración: la linterna fija encendida, desde el menú de pruebas.
var debug_force_flashlight: bool = false
var _urena_photos: int = 0

var flashlight_overlay: Control = null
var phone_light: Control = null
var door_shutter: Control = null
var photo_viewer: Control = null
## El puntito del ojo de Armando, solo en la vista central.
var armando_eye: Control = null
var _layers: Array[Control] = []
## Las siluetas de los que andan al otro lado del cristal. Van en su propia
## capa, debajo de la cortina, para que la lámina las tape al bajar.
var _silhouettes: Control = null
var _shake_left: float = 0.0

var _view_nodes: Array[Control] = []
var _content_nodes: Array[Control] = []
var _right_normal_texture: Texture2D = null


func _ready() -> void:
	clip_contents = true
	_view_nodes = [left_view, center_view, right_view]
	_content_nodes = [left_content, center_content, right_content]

	_right_normal_texture = right_image.texture
	_build_zones(CENTER_ZONES_PATH, $Views/CenterView/Content/Zones, CENTER_CLICKABLE)
	_build_zones(RIGHT_ZONES_PATH, $Views/RightView/Content/Zones, [])
	_build_zones(LEFT_ZONES_PATH, $Views/LeftView/Content/Zones, [])
	# El orden importa, y es: fondo → siluetas → cortina → profes del cristal →
	# etiquetas. Así, con la cortina abajo, tapa a quien esté al otro lado de la
	# puerta (la silueta de Barcosa), pero no a los que están pegados al cristal.
	# La capa de oscuridad se crea después de todo eso, así que la cortina y las
	# siluetas también se apagan cuando se va la luz.
	_build_silhouettes()
	_build_door_shutter()
	_build_layers()
	_build_labels()
	_build_photo_viewer()
	_build_blackout_overlays()
	_build_flashlight()
	_build_beam_widgets()
	_layout()
	resized.connect(_layout)

	for i: int in _view_nodes.size():
		_view_nodes[i].visible = i == _current_view
		_view_nodes[i].position = Vector2.ZERO

	for entry: Dictionary in PRESENCE_ZONES:
		set_zone_presence(str(entry["zone"]), "")
	_refresh_urena_photos()
	_refresh_door()


## La linterna se mantiene con Ctrl o con el clic izquierdo sostenido sobre el
## cristal, y solo sirve mirando al frente. El cono sigue al mouse: el pasillo
## está a oscuras y solo se ve lo que queda dentro del haz.
func _update_flashlight(delta: float) -> void:
	var allowed: bool = is_interactive and _state == ViewState.PANNING and _current_view == View.CENTER
	var wants_on: bool = false
	if allowed:
		wants_on = debug_force_flashlight or Input.is_key_pressed(Controls.FLASHLIGHT_KEY)
		if not wants_on and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			wants_on = zone_rect(GLASS_ZONE).has_point(center_content.get_local_mouse_position())

	if wants_on != _flashlight_on:
		# Si el cortaso del Mago la dejó muerta, ni se prende: el pasillo se
		# queda a oscuras, que es parte del castigo.
		if wants_on and PowerManager.is_flashlight_disabled:
			flashlight_failed.emit()
		else:
			_flashlight_on = wants_on
			flashlight_changed.emit(_flashlight_on)

	_update_beam(delta)


## Sube y baja la luz, le pone el parpadeo del foco y se la pasa a la foto
## iluminada y a las capas. La zona no cambia: es siempre el pasillo entero.
func _update_beam(delta: float) -> void:
	var target: float = 1.0 if _flashlight_on else 0.0
	if not is_equal_approx(_beam_level, target):
		_beam_level = lerpf(_beam_level, target, 1.0 - exp(-delta * BEAM_FADE_SPEED))
		if absf(_beam_level - target) < 0.004:
			_beam_level = target
	_flicker_time += delta
	# El parpadeo solo afecta a lo que se ve: para el juego la linterna está
	# encendida o apagada, nunca a medias.
	var flicker: float = 0.5 + 0.5 * sin(TAU * FLICKER_HZ_A * _flicker_time) \
		* sin(TAU * FLICKER_HZ_B * _flicker_time)
	_beam_strength = _beam_level * (1.0 - FLICKER_DEPTH * flicker)
	_apply_beam()


## Dónde cae la luz: el pasillo entero, un poco crecido. Se recalcula con el
## layout y no en cada cuadro, porque no se mueve.
func _update_beam_area() -> void:
	var hallway: Rect2 = OfficeLayers.hallway_rect()
	if hallway.size.x <= 0.0:
		return
	# La puerta está al fondo del pasillo, a la izquierda de donde se paran los
	# profes: si no se mete en la cuenta, la cortina nunca se alumbra.
	var door: Rect2 = _normalized_zone(GLASS_DOOR_ZONE)
	if door.size.x > 0.0:
		hallway = hallway.merge(door)
	_beam_center = hallway.get_center()
	_beam_half = hallway.size * 0.5 * BEAM_MARGIN


func _apply_beam() -> void:
	var aspect: float = 1.78
	if center_content.size.y > 0.0:
		aspect = center_content.size.x / center_content.size.y
	var material: ShaderMaterial = center_lit.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("beam_center", _beam_center)
		material.set_shader_parameter("beam_half", _beam_half)
		material.set_shader_parameter("beam_softness", BEAM_SOFTNESS)
		material.set_shader_parameter("beam_strength", _beam_strength)
		material.set_shader_parameter("aspect", aspect)
	for layer: Control in _layers:
		layer.set_beam(_beam_center, _beam_half, BEAM_SOFTNESS, _beam_strength)
	if _silhouettes != null:
		_silhouettes.set_beam(_beam_center, _beam_half, BEAM_SOFTNESS, _beam_strength)
	if door_shutter != null:
		door_shutter.set_beam(_beam_center, _beam_half, BEAM_SOFTNESS, _beam_strength)
	if armando_eye != null:
		armando_eye.set_lit(is_flashlight_on())
	if flashlight_overlay != null:
		flashlight_overlay.set_beam_area(_beam_center, _beam_half, _beam_strength)


## true mientras la linterna alumbra. Como ya no se apunta, vale igual para
## todos los que estén en el pasillo.
func is_flashlight_on() -> bool:
	return _flashlight_on


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
	# Sin foto puesta no hay nada que abrir.
	if _zones.has(URENA_PHOTO_ZONE):
		var zone: OfficeZone = _zones[URENA_PHOTO_ZONE]
		zone.set_clickable(not names.is_empty() and photo_viewer != null and photo_viewer.has_photo())


## El night.gd apaga la interacción mientras las cámaras están arriba: así ni se
## gira la cabeza ni se prende la linterna desde detrás del monitor. Al volver,
## la vista es la misma que se dejó.
func set_interactive(interactive: bool) -> void:
	is_interactive = interactive


# --- Colocación ---------------------------------------------------------------

## Cada vista ocupa la pantalla y recorta; su contenido es VIEW_SCALE más grande.
func _layout() -> void:
	views.position = Vector2.ZERO
	views.size = size
	var content_size: Vector2 = size * VIEW_SCALE
	for i: int in _view_nodes.size():
		_view_nodes[i].size = size
		_content_nodes[i].size = content_size
		# Arranca centrada: cada vista es más ancha que la pantalla y lo que
		# sobra a los lados es el recorrido.
		if is_zero_approx(_pan_offsets[i]):
			_pan_offsets[i] = _pan_limit() * 0.5
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
		flashlight_overlay.set_origin(Vector2(content_size.x * 0.5, content_size.y))
	# La foto iluminada va anclada al contenido en la escena, así que se estira
	# sola: ponerle el tamaño a mano solo saca el aviso de Godot.
	_update_beam_area()
	if _silhouettes != null:
		_silhouettes.position = Vector2.ZERO
		_silhouettes.size = content_size
	for layer: Control in _layers:
		layer.position = Vector2.ZERO
		layer.size = content_size
	if armando_eye != null:
		armando_eye.position = Vector2.ZERO
		armando_eye.size = content_size
	_apply_beam()
	if door_shutter != null:
		door_shutter.position = Vector2.ZERO
		door_shutter.size = content_size
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
	if photo_viewer != null and photo_viewer.is_open:
		return  # Mirando la foto: ni se mueve la vista ni se prende la linterna.
	_update_flashlight(delta)
	_update_pan(delta)


## El recorrido lateral. Mantener A o D mueve la vista a ese lado a velocidad
## constante, con un arranque y un frenado cortos. Al tocar el borde y seguir
## manteniendo, la cabeza gira a la vista de al lado.
func _update_pan(delta: float) -> void:
	if not is_interactive or _state != ViewState.PANNING:
		_pan_speed = 0.0
		_edge_hold = 0.0
		return
	var direction: int = 0
	if Input.is_action_pressed("turn_right"):
		direction += 1
	if Input.is_action_pressed("turn_left"):
		direction -= 1

	# La velocidad se acerca a la que toca en vez de saltar: eso es el arranque
	# y el frenado. El contenido se mueve al revés que la mirada.
	var target: float = -float(direction) * PAN_SPEED
	_pan_speed = lerpf(_pan_speed, target, 1.0 - exp(-delta * PAN_RAMP))
	if direction == 0:
		_edge_hold = 0.0
		if absf(_pan_speed) >= 1.0:
			_move_content(delta)
		return

	# Primero se agota el recorrido de la vista; solo entonces gira la cabeza.
	if _move_content(delta):
		_edge_hold = 0.0
		return
	_edge_hold += delta
	if _edge_hold >= EDGE_HOLD_TIME:
		_edge_hold = 0.0
		rotate_view(direction)


## Mueve el contenido de la vista actual. Devuelve false si ya topó.
func _move_content(delta: float) -> bool:
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
	# La vista nueva entra por el lado por el que vienes, para que el recorrido
	# siga donde lo dejaste en vez de dar un salto.
	_pan_offsets[target] = 0.0 if direction > 0 else _pan_limit()
	_apply_content_position(target)
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


## Cuando el Come Trabas se levanta, la silla del cubículo 3 queda vacía. Las
## dos fotos ya vienen con su color final, así que solo se cambia la textura.
func set_right_view_empty(is_empty: bool) -> void:
	right_image.texture = RIGHT_EMPTY_TEXTURE if is_empty else _right_normal_texture


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


## El rectángulo de una zona en normalizadas de su vista, que es como se mide
## todo lo del haz.
func _normalized_zone(zone_id: String) -> Rect2:
	var content_size: Vector2 = center_content.size
	if content_size.x <= 0.0 or content_size.y <= 0.0:
		return Rect2()
	var rect: Rect2 = zone_rect(zone_id)
	return Rect2(rect.position / content_size, rect.size / content_size)


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
		URENA_PHOTO_ZONE:
			photo_viewer.open()


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
		# Solo la central tiene linterna: ahí cada recorte lleva su máscara.
		layer.uses_flashlight = i == View.CENTER
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_nodes[i].add_child(layer)
		_layers.append(layer)


## Las siluetas del otro lado del cristal, en su propia capa debajo de la
## cortina. Es la vista central y nada más: en las otras no hay cristal.
func _build_silhouettes() -> void:
	_silhouettes = OFFICE_LAYERS.new()
	_silhouettes.name = "Silhouettes"
	_silhouettes.view_name = VIEW_LAYER_NAMES[View.CENTER]
	_silhouettes.uses_flashlight = true
	_silhouettes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_content.add_child(_silhouettes)


## El night.gd le dice quién se ve de silueta. Cada entrada es {"slug"}.
func set_silhouettes(present: Array[Dictionary]) -> void:
	if _silhouettes != null:
		_silhouettes.set_present(present)


## Un golpe de Barcosa en la puerta: la lámina tiembla.
func shake_curtain() -> void:
	if door_shutter != null:
		door_shutter.shake()


## El ojo de Armando, lo único que se ve de él con la linterna apagada.
func _build_beam_widgets() -> void:
	armando_eye = ARMANDO_EYE.new()
	armando_eye.name = "ArmandoEye"
	center_content.add_child(armando_eye)


## El night.gd le dice si Armando está pegado al cristal, para el puntito.
func set_armando_at_glass(present: bool) -> void:
	if armando_eye != null:
		armando_eye.set_present(present)


## Quiénes se ven en cada vista. El night.gd lo arma con los profes presentes;
## cada entrada es {"slug": String, "lit_only": bool}.
func set_view_present(view: int, present: Array[Dictionary]) -> void:
	if view < 0 or view >= _layers.size():
		return
	_layers[view].set_present(present)


## La vista donde está el cristal, que es la central. La pide el night.gd para
## meter ahí las siluetas sin tener que saberse el nombre de la zona.
func glass_view() -> int:
	return view_of_zone(GLASS_ZONE)


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


## La foto en grande vive fuera de las vistas: ocupa toda la pantalla y no se
## mueve con el giro de la cabeza.
func _build_photo_viewer() -> void:
	photo_viewer = PHOTO_VIEWER.new()
	photo_viewer.name = "PhotoViewer"
	photo_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(photo_viewer)


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
	door_shutter.closed_changed.connect(_on_shutter_closed_changed)
	center_content.add_child(door_shutter)


## La cortina terminó de bajar (o empezó a subir): la vista central cambia a
## las fotos que ya la traen pintada, o vuelve a las normales.
func _on_shutter_closed_changed(closed: bool) -> void:
	center_image.texture = GameAssets.load_texture(
		CENTER_DARK_CLOSED if closed else CENTER_DARK)
	center_lit.texture = GameAssets.load_texture(
		CENTER_LIT_CLOSED if closed else CENTER_LIT)
	if phone_light != null:
		phone_light.set_background(center_image.texture)


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
