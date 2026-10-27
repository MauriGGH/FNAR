extends Control

## La oficina. Tres vistas separadas (izquierda, centro, derecha), con dos
## movimientos que no se pisan:
##
##   - **El mouse mueve la vista por dentro.** Cada vista se dibuja un poco más
##     grande que la pantalla y se desplaza hacia donde está el cursor, suave y
##     con una zona muerta en el centro. El mouse **nunca** cambia de vista,
##     aunque lo dejes pegado al borde.
##   - **A y D (o las flechas) cambian de vista.** Un toque y la cabeza gira a
##     la de al lado con el barrido de SWEEP_TIME y su desenfoque.
##
## Todo lo que se ve en una vista (zonas de clic, recortes de profes, siluetas,
## cortina, luz de la linterna) cuelga de su nodo Content, así que se mueve con
## la imagen sin que haya que moverlo aparte.
## Las zonas de clic salen de los JSON de data/ y el acercamiento a la PC
## encuadra la zona monitor_screen de la vista central.

signal door_toggled(is_closed: bool)
signal pc_requested()
signal breaker_requested()
signal server_room_requested()
## Picaron la baraja decomisada del escritorio.
signal uno_deck_requested()
signal phone_requested()
## La linterna se prendió o se apagó de verdad.
## Cambió de vista. La escucha el night.gd, que es quien tira el dado de Momo
## cada vez que la cabeza llega a la vista izquierda.
signal view_changed(view: int)

signal flashlight_changed(is_on: bool)
## Se intentó prender pero el cortaso de Audel la dejó muerta.
signal flashlight_failed()
signal notice_requested(text: String, duration: float)
## Un ruido que todavía no tiene audio. Va por su propia señal porque no se
## enseña en pantalla, al revés que notice_requested.
signal sound_noticed(text: String, duration: float)

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
## El shader de las vistas: lo único que hace es el desenfoque del giro. Se le
## pone también al tótem de la mesa, para que no se quede nítido mientras todo
## lo demás se mueve.
const VIEW_SHADER: String = "res://scenes/office/office_view.gdshader"
const BLACKOUT_OVERLAY: GDScript = preload("res://scenes/office/blackout_overlay.gd")
const FLASHLIGHT_OVERLAY: GDScript = preload("res://scenes/office/flashlight_overlay.gd")
const PHONE_LIGHT: GDScript = preload("res://scenes/office/phone_light.gd")
const TICKET_ENVELOPE: GDScript = preload("res://scenes/office/ticket_envelope.gd")
const SERGIO_ARRIVAL: GDScript = preload("res://scenes/office/sergio_arrival.gd")
const DOOR_SHUTTER: GDScript = preload("res://scenes/office/door_shutter.gd")
const OFFICE_LAYERS: GDScript = preload("res://scenes/office/office_layers.gd")
const UNO_DECK_SPOT: GDScript = preload("res://scenes/office/uno_deck_spot.gd")
const LOCK_LIGHT: GDScript = preload("res://scenes/office/lock_light.gd")
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
## La zona de la baraja decomisada, que solo se puede picar mientras su ticket
## esté vivo. Se enciende y se apaga con `set_uno_deck_clickable()`.
const UNO_DECK_ZONE: String = "uno_deck"

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
## Hasta dónde baja el haz, en normalizadas del contenido. El pasillo acaba a
## media altura, así que el borde de abajo caería justo en mitad de la imagen y
## se vería como una raya: se estira hasta pasarse del borde para que el corte
## quede fuera de lo que se ve.
const BEAM_BOTTOM: float = 1.4
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

## Cada vista se dibuja este factor más grande que la pantalla: ese 12 % de más
## es el margen por el que se mueve con el mouse.
const VIEW_SCALE: float = 1.12

## Cuánto se desplaza como mucho, en fracción de la pantalla. A lo ancho usa
## todo el margen; a lo alto, bastante menos, que si no marea.
const PAN_RANGE: Vector2 = Vector2(0.06, 0.02)
## La zona muerta del centro, en fracción de la media pantalla: dentro de ella
## la vista no se mueve, para que no tiemble con cada movimiento del mouse.
const PAN_DEAD_ZONE: float = 0.12
## Lo rápido que alcanza la posición que toca. Alto = sigue más al mouse.
const PAN_SMOOTHING: float = 7.0

# Recorrido dentro de una vista.
## Lo que hay que aguantar en el borde, ya sin recorrido, antes de que gire.

# Giro de cabeza entre vistas.
const SWEEP_TIME: float = 0.35
## Lo que se corre como mucho el desenfoque del giro, en píxeles de pantalla.
## Crece hasta la mitad del barrido y se apaga al llegar.
const MAX_SWEEP_BLUR_PIXELS: float = 70.0
## Y el del parallax, que es solo un roce cuando el mouse va rápido.
const MAX_PAN_BLUR_PIXELS: float = 5.0
## A qué velocidad del parallax (píxeles por segundo) ya está al máximo.
const PAN_BLUR_FULL_SPEED: float = 900.0

## Lo que tarda el acercamiento a la pantalla de la PC.
const ZOOM_TIME: float = 0.4

const DOOR_NOTICE: String = "[clang]"
const NOTICE_TIME: float = 1.6

## El golpe de la cortina al llegar abajo sacude un poco la vista.
const SHAKE_TIME: float = 0.3
const SHAKE_PIXELS: float = 5.0

## Las zonas en las que puede verse un profe. Ya no llevan etiqueta: solo
## sirven para saber a qué vista va su recorte.
const LAYER_ZONES: Array[String] = ["entrance_door", "front_glass", "ladder", "doorway"]

## **Aquí ya no se escribe quién está dónde.** Las etiquetas de presencia
## ("Mamador mirando por el cristal", "Barcosa golpeando la puerta") eran el
## apaño de cuando no existían los recortes; ahora están todos, así que a cada
## profe se le ve y punto. Lo que lo delata es su recorte, la cortina que
## tiembla, su silueta tras el cristal o lo que grita, no un renglón de texto.

## Puntos que siguen encendidos cuando se corta la corriente, por vista.
const BLACKOUT_SPOTS: Dictionary = {
	View.LEFT: [{"zone": "window", "radius": 110.0, "color": Color(0.62, 0.72, 0.95)}],
	View.CENTER: [{"zone": "lock_box", "radius": 34.0, "color": Color(0.3, 0.95, 0.45)}],
	View.RIGHT: [],
}


enum ViewState { PANNING, SWEEPING, ZOOMING_IN, ZOOMED, ZOOMING_OUT }
enum View { LEFT, CENTER, RIGHT }

var is_door_closed: bool = false
var is_interactive: bool = true
## Con el candado puesto no se gira ni se toca nada, pero **el parallax del
## mouse sigue**: es lo que mantiene la sensación de estar ahí. Lo usa el susto
## de Momo, que deja la vista izquierda tomada mientras suena su canción.
var is_locked: bool = false

var _state: ViewState = ViewState.PANNING
var _current_view: int = View.CENTER
## Lo desplazada que está cada vista respecto a su sitio centrado, de -1 a 1 en
## cada eje. Lo mueve el mouse y se suaviza para que no dé tirones.
var _pan: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
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
var ticket_envelope: Control = null
var uno_deck_spot: Control = null
var lock_light: Control = null
var sergio: SergioArrival = null
## true mientras haya que ignorar el botón del mouse que viene apretado de
## otra pantalla, hasta que se suelte.
var _swallow_click: bool = false
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
var _momo_layer: TextureRect = null
var _totem_layer: TextureRect = null
## Dónde va Sergio en el contenido de la vista central cuando no hay rescate.
## Durante el rescate sube al final, y de aquí sale el sitio al que vuelve.
var _sergio_index: int = 0


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
	_build_sergio()
	_build_layers()
	_build_ticket_envelope()
	_build_uno_deck()
	_build_lock_light()
	# Arranca apagada: la baraja solo se puede picar cuando llega su ticket.
	set_uno_deck_clickable(false)
	_build_photo_viewer()
	_build_momo()
	_build_totem()
	_build_blackout_overlays()
	_build_flashlight()
	_build_beam_widgets()
	_layout()
	resized.connect(_layout)

	for i: int in _view_nodes.size():
		_view_nodes[i].visible = i == _current_view
		_view_nodes[i].position = Vector2.ZERO

	_refresh_urena_photos()
	_refresh_door()


## La linterna se mantiene con Ctrl o con el clic izquierdo sostenido sobre el
## cristal, y solo sirve mirando al frente. El cono sigue al mouse: el pasillo
## está a oscuras y solo se ve lo que queda dentro del haz.
func _update_flashlight(delta: float) -> void:
	var allowed: bool = is_interactive and not is_locked \
		and _state == ViewState.PANNING and _current_view == View.CENTER
	# El clic heredado de la pantalla que se acaba de cerrar no cuenta.
	if _swallow_click and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_swallow_click = false
	var wants_on: bool = false
	if allowed:
		wants_on = debug_force_flashlight or Input.is_key_pressed(Controls.FLASHLIGHT_KEY)
		if not wants_on and not _swallow_click \
				and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
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
	# Crece un poco por los lados y por arriba, como siempre...
	var extra: Vector2 = hallway.size * (BEAM_MARGIN - 1.0) * 0.5
	var grown: Rect2 = hallway.grow_individual(extra.x, extra.y, extra.x, 0.0)
	# ...y por abajo se sale de la pantalla, para no dejar la raya.
	grown.size.y = maxf(BEAM_BOTTOM - grown.position.y, grown.size.y)
	_beam_center = grown.get_center()
	_beam_half = grown.size * 0.5


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
## El susto de Momo: no se gira ni se toca nada, pero la vista sigue
## respondiendo al mouse. Al soltarlo, el clic que venga se ignora hasta que se
## levante el botón, igual que al volver de una pantalla acercada.
func set_locked(locked: bool) -> void:
	is_locked = locked
	if not locked:
		_swallow_click = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


# --- El tótem sobre el escritorio ---------------------------------------------

## Mientras se trae encima, el tótem se ve de pie sobre la mesa. Cuelga del
## Content de la vista central, como todo lo demás, así que se mueve con el
## mismo parallax, se desenfoca con el giro y se apaga con el apagón sin que
## haya que tocarlo aparte. Va **encima de todo**: es lo que está más cerca.
func _build_totem() -> void:
	_totem_layer = TextureRect.new()
	_totem_layer.name = "Totem"
	_totem_layer.texture = Sergio.texture(Sergio.TOTEM_ICON)
	_totem_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_totem_layer.stretch_mode = TextureRect.STRETCH_SCALE
	# Es pixel art, como el del rescate: nada de suavizado.
	_totem_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_totem_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_totem_layer.modulate = Sergio.TOTEM_DESK_LIGHT
	_totem_layer.visible = false
	if ResourceLoader.exists(VIEW_SHADER):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load(VIEW_SHADER)
		_totem_layer.material = material
	center_content.add_child(_totem_layer)
	_layout_totem()


## Lo coloca donde apoya, con el alto medido y guardando la forma del recorte.
func _layout_totem() -> void:
	if _totem_layer == null:
		return
	var content: Vector2 = center_content.size
	var height: float = content.y * Sergio.TOTEM_DESK_HEIGHT
	var texture: Texture2D = _totem_layer.texture
	var ratio: float = 1.0
	if texture != null and texture.get_height() > 0:
		ratio = float(texture.get_width()) / float(texture.get_height())
	var box: Vector2 = Vector2(height * ratio, height)
	_totem_layer.size = box
	# El punto medido es donde se apoya: el centro de su base.
	_totem_layer.position = Vector2(
		content.x * Sergio.TOTEM_DESK_AT.x - box.x * 0.5,
		content.y * Sergio.TOTEM_DESK_AT.y - box.y)


## Lo enseña o lo esconde. Lo pide el night.gd con la señal del GameManager, la
## misma que enciende su ícono en la esquina del HUD.
func set_totem_on_desk(carried: bool) -> void:
	if _totem_layer != null:
		_totem_layer.visible = carried


# --- El susto de Momo ---------------------------------------------------------

## Su foto es del tamaño de la vista y va **encima de todo lo de la izquierda**:
## sustituye lo que hubiera ahí (los recortes de los profes, las etiquetas) sin
## tocarlo, y como cuelga del mismo Content se mueve con el mismo parallax.
func _build_momo() -> void:
	_momo_layer = TextureRect.new()
	_momo_layer.name = "Momo"
	_momo_layer.texture = Momo.texture(Momo.VIEW_IMAGE)
	_momo_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_momo_layer.stretch_mode = TextureRect.STRETCH_SCALE
	_momo_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_momo_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_momo_layer.visible = false
	left_content.add_child(_momo_layer)


## Pone o quita su foto. Al quitarla, la vista vuelve a estar como estaba y el
## acercamiento se deshace.
func set_momo_active(active: bool) -> void:
	if _momo_layer != null:
		_momo_layer.visible = active
	if not active:
		set_momo_zoom(Momo.ZOOM_FROM)


## Lo acercada que va la vista izquierda. El pivote es el punto donde está
## Momo, así que se acerca **a él** y no al centro de la foto.
func set_momo_zoom(amount: float) -> void:
	left_content.pivot_offset = left_content.size * Momo.ZOOM_AT
	left_content.scale = Vector2.ONE * amount


func set_interactive(interactive: bool) -> void:
	is_interactive = interactive
	# Al volver de una pantalla acercada, el botón del mouse puede seguir
	# apretado (es el clic con el que se salió): hasta que se suelte, la
	# oficina lo ignora. Si no, ese mismo clic prendería la linterna.
	if interactive:
		_swallow_click = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


# --- Colocación ---------------------------------------------------------------

## Cada vista ocupa la pantalla y recorta; su contenido es VIEW_SCALE más grande.
func _layout() -> void:
	views.position = Vector2.ZERO
	views.size = size
	var content_size: Vector2 = size * VIEW_SCALE
	for i: int in _view_nodes.size():
		_view_nodes[i].size = size
		_content_nodes[i].size = content_size
		_apply_content_position(i)
	_layout_zones()
	_layout_totem()


## Lo más negativo que puede valer el recorrido horizontal de una vista.
func _content_top() -> float:
	return -(size.y * VIEW_SCALE - size.y) * 0.5


## Dónde cae el contenido de una vista: el sitio centrado, más lo que el mouse
## lo haya desplazado. El contenido se mueve al revés que la mirada.
func _apply_content_position(index: int) -> void:
	_content_nodes[index].position = _content_origin() - Vector2(
		_pan[index].x * size.x * PAN_RANGE.x,
		_pan[index].y * size.y * PAN_RANGE.y)


## El sitio de una vista sin desplazar: centrada, recortando parejo.
func _content_origin() -> Vector2:
	return Vector2(-(size.x * VIEW_SCALE - size.x) * 0.5, _content_top())


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
	if ticket_envelope != null:
		ticket_envelope.position = Vector2.ZERO
		ticket_envelope.size = content_size
		ticket_envelope.set_target(zone_rect("monitor_screen"))
	if sergio != null:
		sergio.position = Vector2.ZERO
		sergio.size = content_size
	if lock_light != null:
		lock_light.position = Vector2.ZERO
		lock_light.size = content_size
	# La baraja ocupa justo su zona de clic, que es donde está medida.
	if uno_deck_spot != null:
		var spot: Rect2 = zone_rect(UNO_DECK_ZONE)
		uno_deck_spot.position = spot.position
		uno_deck_spot.size = spot.size


## La llegada de Sergio: encima de la cortina y debajo de los profes del
## cristal, porque él está al otro lado, en la recepción.
func _build_sergio() -> void:
	sergio = SERGIO_ARRIVAL.new()
	sergio.name = "SergioArrival"
	center_content.add_child(sergio)
	_sergio_index = sergio.get_index()


## Mientras corre el rescate, la oficina se queda sin nadie: **se esconden
## todos los recortes de profes, las siluetas y el ojo de Armando**. Si uno
## estaba pegado al cristal o asomado al marco, se dibujaba delante del haz y
## de Sergio, que es justo lo que no puede pasar.
##
## Y Sergio sube al final del contenido, por encima de la oscuridad y del cono
## de la linterna: su haz es una luz, no algo a lo que haya que alumbrar. Al
## acabar, todo vuelve a donde estaba y el night.gd repinta quién se ve.
func set_rescue_active(active: bool) -> void:
	for layer: Control in _layers:
		layer.visible = not active
	if _silhouettes != null:
		_silhouettes.visible = not active
	if armando_eye != null:
		armando_eye.visible = not active
	if sergio != null:
		center_content.move_child(sergio,
			center_content.get_child_count() - 1 if active else _sergio_index)


## El sobrecito del ticket, encima de la pantalla del monitor. Va en el
## contenido de la vista central, así que se mueve con la vista.
func _build_ticket_envelope() -> void:
	ticket_envelope = TICKET_ENVELOPE.new()
	ticket_envelope.name = "TicketEnvelope"
	center_content.add_child(ticket_envelope)


## La baraja decomisada sobre la mesa. Como el tótem, cuelga del Content de la
## vista central: parallax, desenfoque del giro y apagón le llegan solos.
func _build_uno_deck() -> void:
	uno_deck_spot = UNO_DECK_SPOT.new()
	uno_deck_spot.name = "UnoDeck"
	center_content.add_child(uno_deck_spot)


## El foquito de la chapa, que es lo que dice si la puerta está abierta o
## cerrada ahora que no hay letrero.
func _build_lock_light() -> void:
	lock_light = LOCK_LIGHT.new()
	lock_light.name = "LockLight"
	center_content.add_child(lock_light)


## La noche le pasa el modelo de la baraja: la capa se dibuja sola a partir de
## él, sin que nadie tenga que decirle qué enseñar.
func bind_uno_deck(model: UnoDeckModel) -> void:
	if uno_deck_spot != null:
		uno_deck_spot.bind(model)


## La baraja se puede picar solo mientras su ticket esté vivo.
func set_uno_deck_clickable(can_click: bool) -> void:
	if _zones.has(UNO_DECK_ZONE):
		(_zones[UNO_DECK_ZONE] as OfficeZone).set_clickable(can_click)


## Llegó un ticket y la PC está cerrada: el sobre parpadea sobre el monitor.
func blink_ticket() -> void:
	if ticket_envelope != null:
		ticket_envelope.blink()


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


## El parallax del mouse: la vista se desplaza hacia donde está el cursor, sin
## pasar de PAN_RANGE y con una zona muerta en el centro. Nunca cambia de
## vista: para eso están A y D.
func _update_pan(delta: float) -> void:
	# Mientras la cabeza gira o la vista se acerca a algo, manda el tween: si
	# el parallax siguiera escribiendo la posición, se pelearían.
	if _state != ViewState.PANNING:
		return
	# Con el candado el parallax sigue: lo que se bloquea es girar y tocar.
	var wanted: Vector2 = _wanted_pan() if (is_interactive or is_locked) \
		else Vector2.ZERO
	var eased: float = 1.0 - exp(-delta * PAN_SMOOTHING)
	var before: Vector2 = _pan[_current_view]
	for i: int in _content_nodes.size():
		# Las vistas que no se ven también se van colocando, para que al girar
		# la nueva ya esté donde toca y no dé un salto.
		_pan[i] = _pan[i].lerp(wanted, eased)
	_apply_content_position(_current_view)
	_apply_pan_blur(before, delta)


## Un roce de desenfoque cuando el mouse mueve la vista rápido. Es mucho más
## suave que el del giro: se nota al barrer de un lado a otro y nada más.
func _apply_pan_blur(before: Vector2, delta: float) -> void:
	if delta <= 0.0:
		return
	# Lo que se movió la vista este cuadro, ya en píxeles de pantalla.
	var moved: float = absf(_pan[_current_view].x - before.x) * size.x * PAN_RANGE.x
	var speed: float = moved / delta
	var blur: float = minf(speed / PAN_BLUR_FULL_SPEED, 1.0) * MAX_PAN_BLUR_PIXELS
	_set_blur(blur)


## Hacia dónde tira el mouse, de -1 a 1 en cada eje, ya con la zona muerta
## descontada. (0, 0) es la vista centrada.
func _wanted_pan() -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ZERO
	var mouse: Vector2 = get_local_mouse_position()
	return Vector2(
		_axis(mouse.x / size.x * 2.0 - 1.0),
		_axis(mouse.y / size.y * 2.0 - 1.0))


## Un eje: dentro de la zona muerta no se mueve, y de ahí al borde sube hasta 1.
func _axis(value: float) -> float:
	var amount: float = clampf(absf(value), 0.0, 1.0)
	if amount <= PAN_DEAD_ZONE:
		return 0.0
	var scaled: float = (amount - PAN_DEAD_ZONE) / (1.0 - PAN_DEAD_ZONE)
	return signf(value) * scaled


## Gira a la vista de al lado: -1 hacia la izquierda, 1 hacia la derecha.
func rotate_view(direction: int) -> void:
	if _state != ViewState.PANNING:
		return
	var target: int = _current_view + direction
	if target < 0 or target >= _view_nodes.size():
		return

	_state = ViewState.SWEEPING
	# La vista nueva ya viene colocada donde apunta el mouse, así que entra sin
	# saltos; solo hay que asegurarse de aplicarlo antes de que se vea.
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
	_set_blur(sin(progress * PI) * MAX_SWEEP_BLUR_PIXELS)


func _on_sweep_finished(target: int) -> void:
	_sweep_from.visible = false
	_sweep_from.position.x = 0.0
	_sweep_to.position.x = 0.0
	_current_view = target
	_set_blur(0.0)
	_state = ViewState.PANNING
	view_changed.emit(_current_view)


## El desenfoque se pide en píxeles de pantalla; los shaders lo quieren en
## fracción del ancho de la imagen, que es la vista entera a VIEW_SCALE.
##
## Va para **todo lo que se ve**, no solo para el fondo: la foto iluminada, los
## recortes de los profes, las siluetas y la cortina. Cada uno tiene su propio
## material, así que se recorre la vista entera y se le pone el parámetro al
## que lo tenga (los que no, lo ignoran).
func _set_blur(pixels: float) -> void:
	# Los píxeles se cuentan sobre una pantalla de 1920 de ancho, no sobre el
	# tamaño interno de la vista: así se ve igual en cualquier resolución.
	var amount: float = pixels / (OfficeLayers.REFERENCE_WIDTH * VIEW_SCALE)
	for content: Control in _content_nodes:
		_blur_subtree(content, amount)


func _blur_subtree(node: Node, amount: float) -> void:
	var item: CanvasItem = node as CanvasItem
	if item != null:
		var material: ShaderMaterial = item.material as ShaderMaterial
		if material != null:
			# El fondo usa office_view y el resto flashlight_reveal: cada uno
			# se queda con el suyo y descarta el otro.
			material.set_shader_parameter("blur_amount", amount)
			material.set_shader_parameter("motion_blur", amount)
	for child: Node in node.get_children():
		_blur_subtree(child, amount)


## Para las capturas: deja el giro clavado a la mitad (o donde se le diga) en
## vez de dejarlo correr, para poder fotografiarlo siempre igual.
func debug_hold_sweep(progress: float = 0.5, direction: int = 1) -> void:
	if _state != ViewState.PANNING:
		return
	var target: int = _current_view + direction
	if target < 0 or target >= _view_nodes.size():
		target = _current_view - direction
	if target < 0 or target >= _view_nodes.size():
		return
	_state = ViewState.SWEEPING
	_apply_content_position(target)
	_sweep_direction = signi(target - _current_view)
	_sweep_from = _view_nodes[_current_view]
	_sweep_to = _view_nodes[target]
	_sweep_to.visible = true
	if _view_tween != null and _view_tween.is_valid():
		_view_tween.kill()
	_apply_sweep(clampf(progress, 0.0, 1.0))


## Cuando el Come Trabas se levanta, la silla del cubículo 3 queda vacía. Las
## dos fotos ya vienen con su color final, así que solo se cambia la textura.
func set_right_view_empty(is_empty: bool) -> void:
	right_image.texture = RIGHT_EMPTY_TEXTURE if is_empty else _right_normal_texture


# --- Acercamiento a la PC -----------------------------------------------------

## Encuadra la pantalla del monitor y, al terminar, pide abrir la PC.
## Un toque de A o D (o de las flechas) cambia a la vista de al lado. El mouse
## no cambia de vista nunca: solo mueve la que ya está puesta.
func _unhandled_input(event: InputEvent) -> void:
	if not is_interactive or is_locked or _state != ViewState.PANNING:
		return
	if event.is_action_pressed("turn_left"):
		rotate_view(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("turn_right"):
		rotate_view(1)
		get_viewport().set_input_as_handled()


func zoom_to_pc() -> void:
	_zoom_to_zone("monitor_screen", View.CENTER, "pc")


## Lo mismo con el tablero del breaker, en la vista izquierda.
func zoom_to_breaker() -> void:
	_zoom_to_zone("breaker", View.LEFT, "breaker")


## Y con la baraja decomisada. El acercamiento no va a la baraja sino al
## **encuadre del escritorio** (`desk`): la baraja ocupa un pedacito de la foto
## y acercarse a ella sola sería ampliarla dieciocho veces.
func zoom_to_uno_deck() -> void:
	_zoom_to_zone("desk", View.CENTER, "uno")


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
	var factor: float = maxf(size.x / target.size.x, size.y / target.size.y)
	var target_position: Vector2 = size * 0.5 - target.get_center() * factor
	_tween_content(target_position, Vector2(factor, factor), _on_zoom_in_finished)


func _emit_zoom_request() -> void:
	match _zoom_request:
		"breaker":
			breaker_requested.emit()
		"uno":
			uno_deck_requested.emit()
		_:
			pc_requested.emit()


## Vuelve la vista a donde estaba antes del acercamiento.
func zoom_out() -> void:
	if _state == ViewState.PANNING or _state == ViewState.ZOOMING_OUT:
		return
	_state = ViewState.ZOOMING_OUT
	# Vuelve a donde estaba la vista, con su desplazamiento del mouse.
	var back: Vector2 = _content_origin() - Vector2(
		_pan[_zoom_view].x * size.x * PAN_RANGE.x,
		_pan[_zoom_view].y * size.y * PAN_RANGE.y)
	_tween_content(back, Vector2.ONE, _on_zoom_out_finished)


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
	if is_locked:
		return  # Con el susto de Momo encima no se abre nada.
	match zone_id:
		"monitor":
			zoom_to_pc()
		"lock_box":
			_toggle_door()
		"phone":
			phone_requested.emit()
		"server_room":
			server_room_requested.emit()
		UNO_DECK_ZONE:
			zoom_to_uno_deck()
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
		sound_noticed.emit(DOOR_NOTICE, NOTICE_TIME)
		shake()
	door_toggled.emit(is_door_closed)


## El estado de la puerta **no se escribe en ningún lado**: se ve en el foco
## de la chapa (verde abierta, rojo cerrada) y en la cortina misma.
func _refresh_door() -> void:
	if door_shutter != null:
		door_shutter.set_closed(is_door_closed)
	if lock_light != null:
		lock_light.set_closed(is_door_closed)


## Las zonas donde puede aparecer un profe, para que el night.gd las recorra.
func layer_zone_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for zone_id: String in LAYER_ZONES:
		if _zones.has(zone_id):
			ids.append(zone_id)
	return ids


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


## Deja la vista central puesta de golpe, sin barrido. Lo usa el rescate de
## Sergio: su escena pasa ahí y da igual para dónde estuviera mirando.
func show_center_view() -> void:
	if _view_tween != null and _view_tween.is_valid():
		_view_tween.kill()
	_state = ViewState.PANNING
	_current_view = View.CENTER
	for i: int in _view_nodes.size():
		_view_nodes[i].visible = i == _current_view
		_view_nodes[i].position = Vector2.ZERO
	_apply_content_position(_current_view)
	_set_blur(0.0)


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


