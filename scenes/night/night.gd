extends Control

## Escena principal de una noche: junta la oficina, las cámaras, los profes y el
## HUD con los autoloads, y cambia a la pantalla de 6 AM o de game over.


## Lo que muestra el HUD con la energía infinita de depuración puesta.
const INFINITE_POWER_TEXT: String = "ENERGÍA ∞ (debug)"

const BREAKER_NOTICE: String = "[clac]"
const BREAKER_NOTICE_TIME: float = 1.2

const FLASHLIGHT_CLICK: String = "[clic]"
const FLASHLIGHT_DEAD: String = "[la linterna no enciende]"
const NOTICE_TIME_DEAD: float = 1.8
const RING_NOTICE: String = "[ring]"
const NOTICE_SHORT: float = 0.9
## Lo que suena el teléfono de Ureña antes de matarte.
const URENA_RING_TIME: float = 8.0
## De cada 100 noches con Ureña activo, en cuántas llama.
const URENA_CALL_CHANCE: int = 60
## Desde esta noche puede llamar hasta dos veces.
const URENA_TWO_CALLS_FROM_NIGHT: int = 5

const STEPS_NOTICE: String = "[pasos]"
const STEPS_NOTICE_TIME: float = 1.2
## Lo que dura el destello blanco de la descarga.
const FLASH_TIME: float = 0.28

@onready var office: Control = $Office
@onready var camera_system: Control = $CameraSystem
@onready var pc_screen: Control = $PcScreen
@onready var animatronics_holder: Node = $Animatronics
@onready var clock_label: Label = $Hud/TopRight/ClockLabel
@onready var night_label: Label = $Hud/TopRight/NightLabel
@onready var power_label: Label = $Hud/PowerLabel
@onready var usage_bars: Control = $Hud/UsageBars
@onready var camera_bar: Control = $Hud/CameraBar
@onready var notice_banner: Label = $Hud/NoticeBanner
@onready var warning_icon: Control = $Hud/WarningIcon
@onready var cortaso_overlay: Control = $Hud/CortasoOverlay
@onready var breaker_panel: Control = $BreakerPanel
@onready var phone_call: Control = $Hud/PhoneCall
@onready var debug_help: Label = $Hud/DebugHelp
@onready var pause_menu: Control = $Hud/PauseMenu
@onready var jumpscare: Control = $Hud/JumpscareOverlay
@onready var blackout_death: Control = $Hud/BlackoutDeath
@onready var hallucinations: Control = $Hud/HallucinationOverlay
@onready var call_subtitles: Control = $Hud/CallSubtitles
@onready var voice_line: Control = $Hud/VoiceLine
@onready var distant: Node = $DistantSounds
@onready var controls_card: Control = $Hud/ControlsCard
@onready var wasted_screen: WastedScreen = $Hud/WastedScreen
@onready var mod_menu: Control = $Hud/ModMenu
@onready var server_room: Control = $ServerRoom
@onready var uno_desk: UnoDesk = $UnoDesk
@onready var fade_overlay: ColorRect = $Hud/FadeOverlay
@onready var flash_overlay: ColorRect = $Hud/FlashOverlay

const ARMANDO_NOTICE: String = "[Armando borró tu progreso]"
const URENA_SNUB_NOTICE: String = "[Ureña se quedó esperando]"
## La causa cuando el apagón te alcanza. Es cosa del Mago, no de la energía.
const NO_CALL_NOTICE: String = "[esta noche no tiene guion de llamada]"
const BLACKOUT_CAUSE: String = "Mago Eléctrico"
const BLACKOUT_JUMPSCARE: String = "audel"
## Cada cuánto se repinta el contador de tickets.
const TICKET_REFRESH_TIME: float = 0.25

## Quién suena de lejos al cambiar de cuarto. Barcosa va aparte: el suyo solo
## cuenta cuando sale del salón B, que es cuando arranca a correr.
const DISTANT_ON_MOVE: Dictionary = {
	"mamador": "mamador_pasos",
	"armando": "armando_modem",
}
## Lo que suena **junto** con lo de arriba, en el mismo movimiento: a Mamador
## se le oye el llavero con los pasos.
const DISTANT_WITH_MOVE: Dictionary = {
	"mamador": "llavero",
}
const BARCOSA_HOME: String = "salon_b"
const SERGIO_RESCUE: GDScript = preload("res://scenes/night/sergio_rescue.gd")
const MOMO_EVENT: GDScript = preload("res://scenes/night/momo_event.gd")
## Lo que mide el ícono del tótem en la esquina del HUD.
const TOTEM_ICON_SIZE: Vector2 = Vector2(52.0, 80.0)

## El HUD reducido de las pantallas acercadas: la mitad de grande. Los tamaños
## normales son los de la escena y se repiten aquí para poder volver a ellos.
const HUD_COMPACT_FACTOR: float = 0.5
const HUD_SIZES: Array[Array] = [
	["Hud/TopRight/ClockLabel", 86], ["Hud/TopRight/NightLabel", 34],
	["Hud/PowerLabel", 40],
]
const HUD_COLUMN_LEFT: float = -380.0
const HUD_COLUMN_BOTTOM: float = 210.0

var _animatronics: Array[Animatronic] = []
var _debug_shown: bool = false
var _come_trabas: ComeTrabas = null
var _audel: Audel = null
var _urena: Urena = null
var _rochis: Rochis = null

# Teléfono: la llamada de la noche y la de Ureña.
var _nightly_call_left: float = 0.0
## A qué hora le toca la llamada rara de esta noche, y cuál es. En −1 es que
## ya pasó y no vuelve: es una por noche.
var _mencho_call_at: float = -1.0
## De quién te salvó Sergio, para mandarlo a su sitio al acabar.
var _rescued_from: String = ""
var momo_event: MomoEvent = null
## Momo sale una vez por noche como mucho.
var _momo_used: bool = false
var sergio_rescue: SergioRescue = null
var totem_icon: TextureRect = null
var _random_call_id: String = ""
## Las horas a las que va a llamar esta noche, de la más temprana a la última.
var _urena_calls_at: PackedFloat32Array = PackedFloat32Array()
var _ticket_elapsed: float = 0.0
## Dónde estaba cada profe la última vez, para saber cuándo se movió, y en qué
## etapa iba Rochis, para el rechinido de su silla.
var _last_rooms: Dictionary = {}
var _last_rochis_stage: int = -1
## Salió de la sala de servidores pidiendo el monitor: se abre al llegar.
var _open_cameras_on_return: bool = false


func _ready() -> void:
	# La noche arranca **en silencio**: no solo los bucles, también lo que haya
	# quedado colgando de la pantalla anterior (el grito del game over, el
	# despertador de las 6 AM). Su propio ambiente lo pone ella enseguida.
	AudioManager.stop_all()
	_style_hud()
	_build_sergio_rescue()
	_build_momo()
	_animatronics = _collect_animatronics()
	for animatronic: Animatronic in _animatronics:
		# Los ruidos de los profes son apaños de audio, no avisos: no se leen.
		animatronic.made_noise.connect(notice_banner.show_sound)
		animatronic.said_line.connect(voice_line.say)
		if animatronic is Barcosa:
			(animatronic as Barcosa).door_knocked.connect(office.shake_curtain)
		if animatronic is ComeTrabas:
			_come_trabas = animatronic as ComeTrabas
			# Al quedarse sin cuerda, la silla del cubículo 3 queda vacía y la
			# cajita musical se calla: por eso el jugador se da cuenta.
			_come_trabas.music_stopped.connect(office.set_right_view_empty.bind(true))
			_come_trabas.music_stopped.connect(_on_music_box_stopped)
		elif animatronic is Urena:
			_urena = animatronic as Urena
		elif animatronic is Rochis:
			_rochis = animatronic as Rochis
		elif animatronic is ArmandoPrompts:
			pc_screen.set_armando(animatronic as ArmandoPrompts)
		elif animatronic is Audel:
			_audel = animatronic as Audel
			_audel.cortaso_started.connect(_on_cortaso_started)
			_audel.discharge_started.connect(_on_discharge)

	office.door_toggled.connect(_on_door_toggled)
	office.pc_requested.connect(pc_screen.open)
	office.notice_requested.connect(notice_banner.show_notice)
	office.sound_noticed.connect(notice_banner.show_sound)
	office.breaker_requested.connect(breaker_panel.open)
	office.breaker_requested.connect(_set_hud_compact.bind(true))
	office.phone_requested.connect(phone_call.answer)
	office.flashlight_changed.connect(_on_flashlight_changed)
	office.flashlight_failed.connect(_on_flashlight_failed)

	phone_call.ring_tick.connect(_on_ring_tick)
	phone_call.ringing_started.connect(_on_ringing_started)
	phone_call.call_answered.connect(_on_call_answered)
	phone_call.call_missed.connect(_on_call_missed)
	phone_call.urena_snubbed.connect(_on_urena_snubbed)
	phone_call.snub_line.connect(_on_snub_line)
	phone_call.call_ended.connect(_on_call_ended)
	phone_call.recording_started.connect(_on_recording_started)
	phone_call.mencho_started.connect(_on_mencho_started)
	call_subtitles.finished.connect(phone_call.end_recording)
	phone_call.answer_given.connect(_on_answer_given)
	office.server_room_requested.connect(_enter_server_room)
	server_room.closed.connect(_leave_server_room)
	# En las pantallas acercadas el HUD se achica, que si no el reloj se come
	# la hoja de etiquetado y el marco del monitor.
	server_room.closed.connect(_set_hud_compact.bind(false))
	server_room.cameras_requested.connect(_on_server_cameras_requested)
	server_room.notice_requested.connect(notice_banner.show_notice)
	# La baraja decomisada: el acercamiento lo lleva la oficina y la mesa es
	# una capa encima, igual que el tablero del breaker.
	uno_desk.bind(GameManager.uno_deck)
	office.bind_uno_deck(GameManager.uno_deck)
	office.uno_deck_requested.connect(uno_desk.open)
	office.uno_deck_requested.connect(_set_hud_compact.bind(true))
	uno_desk.closed.connect(office.zoom_out)
	uno_desk.closed.connect(_set_hud_compact.bind(false))
	if not GameManager.uno_deck.changed.is_connected(_refresh_uno_deck):
		GameManager.uno_deck.changed.connect(_refresh_uno_deck)
	_refresh_uno_deck()
	breaker_panel.closed.connect(office.zoom_out)
	breaker_panel.closed.connect(_set_hud_compact.bind(false))
	breaker_panel.lever_pulled.connect(_on_breaker_pulled)
	PowerManager.blackout_changed.connect(_on_blackout_changed)
	PowerManager.power_depleted.connect(_on_power_depleted)
	blackout_death.strike.connect(_on_blackout_strike)
	jumpscare.finished.connect(_on_jumpscare_finished)
	wasted_screen.finished.connect(_on_jumpscare_finished)

	camera_system.set_animatronics(_animatronics)
	camera_system.opened.connect(_on_cameras_opened)
	camera_system.closed.connect(_on_cameras_closed)
	camera_system.camera_changed.connect(_on_camera_changed)
	# Los avisos de las cámaras de ambiente ("[una sombra entre los coches]")
	# son **ruidos y cosas que ya se ven en la imagen**: van a la consola, no
	# a la banda de avisos. Lo que el jugador tiene que leer ya se lo dice el
	# suceso con su propia imagen y su parpadeo.
	camera_system.notice_requested.connect(notice_banner.show_sound)
	camera_bar.hovered.connect(_on_camera_bar_hovered)

	# La PC y las cámaras no pueden estar abiertas a la vez.
	pc_screen.opened.connect(camera_system.close)
	camera_system.opened.connect(pc_screen.close)
	# Al bajar la PC, la vista de la oficina regresa de su acercamiento.
	pc_screen.closed.connect(office.zoom_out)
	pc_screen.opened.connect(_set_hud_compact.bind(true))
	pc_screen.closed.connect(_set_hud_compact.bind(false))
	pc_screen.armando_won.connect(_on_armando_won)

	GameManager.ticket_arrived.connect(_on_ticket_arrived)
	office.view_changed.connect(_on_view_changed)
	GameManager.night_started.connect(_on_night_started)
	GameManager.hour_changed.connect(_on_hour_changed)
	GameManager.night_won.connect(_on_night_won)
	GameManager.sergio_rescued.connect(_on_sergio_rescued)
	GameManager.totem_changed.connect(_on_totem_changed)
	GameManager.game_over.connect(_on_game_over)
	PowerManager.power_changed.connect(_on_power_changed)

	_apply_debug_shown()

	pause_menu.resumed.connect(_on_resumed)
	pause_menu.menu_requested.connect(_on_menu_requested)
	pause_menu.controls_requested.connect(_on_controls_requested)
	GameManager.start_night()
	# El panel se arma después de arrancar la noche: hasta aquí los profes no
	# tienen ruta, y el panel la necesita para su lista de cuartos.
	mod_menu.bind(self)
	# El tutorial, solo la primera vez que alguien juega la noche 1.
	if GameManager.current_night == 1 and not GameManager.is_custom_night \
			and not SaveGame.tutorial_seen:
		SaveGame.mark_tutorial_seen()
		controls_card.open(true)
	# El ambiente de la oficina y del pasillo suena toda la noche.
	AudioManager.play_loop(Sounds.OFFICE_AMBIENCE)
	AudioManager.play_loop(Sounds.HALLWAY_AMBIENCE)


## Desde la pausa se puede volver a ver el recuadro de controles. Ahí el juego
## ya está pausado, así que el reloj no hace falta pararlo aparte.
func _on_controls_requested() -> void:
	pause_menu.close()
	controls_card.open(false)


## Escape pausa la noche, salvo que ya lo esté usando otra cosa: la PC, el
## breaker, la sala de servidores o la foto de Ureña abierta. El reloj y los
## profes se detienen porque se pausa el árbol entero.
func _escape_is_taken() -> bool:
	if controls_card.is_open:
		return true  # Escape cierra el recuadro, no abre la pausa.
	if pc_screen.is_open or GameManager.is_in_server_room:
		return true
	if breaker_panel.visible:
		return true
	if momo_event != null and momo_event.is_playing:
		return true  # Con Momo en pantalla no se puede ni pausar.
	return office.photo_viewer != null and office.photo_viewer.is_open


func _on_resumed() -> void:
	get_tree().paused = false


func _on_menu_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(Screens.MAIN_MENU)


## Un solo interruptor: la ayuda de teclas, la etiqueta de los profes y las
## zonas de clic de la oficina.
func _apply_debug_shown() -> void:
	camera_system.set_debug_visible(_debug_shown)
	office.set_zones_visible(_debug_shown)
	debug_help.visible = false  # La ayuda vive ahora en el panel de pruebas.


## La lista de profes, para el panel de pruebas.
func animatronics() -> Array[Animatronic]:
	return _animatronics


## El panel de pruebas: que suene la llamada de esta noche sin esperar.
func debug_night_call() -> void:
	if not NightCalls.has_call(GameManager.current_night):
		notice_banner.show_sound(NO_CALL_NOTICE, NOTICE_SHORT)
		return
	phone_call.queue_recording(GameManager.current_night, NightCalls.RING_TIME)


## Contestaron: arrancan el audio y los subtítulos de abajo.
func _on_recording_started(night: int) -> void:
	call_subtitles.play(night)


## Contestaron la llamada rara: su audio con su único renglón de subtítulo.
func _on_mencho_started() -> void:
	call_subtitles.play_call(_random_call_id, NightCalls.MENCHO_SUBTITLES)


## Para el panel de pruebas: que llame ahora mismo. Con un id se pide una en
## concreto; sin él, la que le tocó a esta noche.
func debug_mencho_call(call_id: String = "") -> void:
	if phone_call.is_ringing or phone_call.is_open:
		return
	if not call_id.is_empty():
		_random_call_id = call_id
	if _random_call_id.is_empty():
		_random_call_id = Sounds.MENCHO_CALL
	_mencho_call_at = -1.0
	phone_call.queue_mencho(NightCalls.MENCHO_RING_TIME)




## Los profes son hijos del nodo Animatronics, así se agregan sin tocar código.
## La capa del rescate (el susto congelado y el tótem) y el ícono del tótem en
## la esquina. Se arman por código para no llenar la escena de nodos que casi
## nunca se ven.
func _build_sergio_rescue() -> void:
	var hud: CanvasLayer = $Hud
	sergio_rescue = SERGIO_RESCUE.new()
	sergio_rescue.name = "SergioRescue"
	hud.add_child(sergio_rescue)
	sergio_rescue.sergio_requested.connect(_on_sergio_requested)
	# El tótem y el final los manda el reloj de la pista del rescate, no la
	# oficina: ella solo dibuja el haz y a Sergio cuando se le pide.
	sergio_rescue.totem_done.connect(_on_totem_finished)
	sergio_rescue.finished.connect(_on_sergio_left)

	totem_icon = TextureRect.new()
	totem_icon.name = "TotemIcon"
	totem_icon.texture = Sergio.texture(Sergio.TOTEM_ICON)
	totem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	totem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	totem_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	totem_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	totem_icon.visible = false
	totem_icon.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	totem_icon.offset_left = -TOTEM_ICON_SIZE.x - 28.0
	totem_icon.offset_top = -TOTEM_ICON_SIZE.y - 28.0
	totem_icon.offset_right = -28.0
	totem_icon.offset_bottom = -28.0
	hud.add_child(totem_icon)


## El HUD, reducido o normal. En la oficina va grande, como en los juegos
## originales; en las pantallas acercadas (la PC, el tablero, la sala) se queda
## **a la mitad**, para no taparles nada: el reloj y la noche arriba a la
## derecha, la energía abajo a la izquierda.
func _set_hud_compact(compact: bool) -> void:
	var factor: float = HUD_COMPACT_FACTOR if compact else 1.0
	for entry: Array in HUD_SIZES:
		var label: Label = get_node_or_null(str(entry[0])) as Label
		if label != null:
			label.add_theme_font_size_override("font_size",
				maxi(10, roundi(float(entry[1]) * factor)))
	var column: Control = get_node_or_null("Hud/TopRight") as Control
	if column != null:
		# La columna se angosta con la letra, para que no quede un hueco.
		column.offset_left = HUD_COLUMN_LEFT * factor
		column.offset_bottom = HUD_COLUMN_BOTTOM * factor


## El HUD va en VT323, como todo lo que sale de una pantalla o un aparato: el
## reloj grande arriba a la derecha, la noche debajo y la energía abajo a la
## izquierda. Los tamaños están en la escena; aquí solo se pone la fuente.
func _style_hud() -> void:
	for label: Label in [clock_label, night_label, power_label]:
		if label != null:
			label.add_theme_font_override("font", Fonts.terminal())


func _collect_animatronics() -> Array[Animatronic]:
	var found: Array[Animatronic] = []
	for child: Node in animatronics_holder.get_children():
		if child is Animatronic:
			found.append(child as Animatronic)
	return found


func _on_night_started(night: int) -> void:
	night_label.text = "NOCHE %d" % night
	_momo_used = false
	office.set_right_view_empty(false)
	_schedule_calls(night)
	for animatronic: Animatronic in _animatronics:
		animatronic.start()


## Quién se ve en cada vista de la oficina. Si ya existe su recorte PNG, se
## dibuja el recorte; si no, se queda la etiqueta de texto de siempre.
func _process(delta: float) -> void:
	pause_menu.blocked = _escape_is_taken()
	# Con el susto de Momo encima el juego entero está parado: aquí no corre
	# nada, ni el teléfono, ni los tickets, ni los sonidos lejanos.
	if momo_event != null and momo_event.is_playing:
		return
	_refresh_tickets(delta)
	_process_calls(delta)
	_refresh_office_presence()
	_update_glass_beams(delta)
	_track_distant_sounds()
	_refresh_music_box()
	# El aviso de la cuerda se ve esté donde esté el jugador, como en FNAF 2.
	warning_icon.set_level(0 if _come_trabas == null else _come_trabas.warning_level())


# --- Tickets ------------------------------------------------------------------

## Llegó un ticket: suena el aviso y sale su nombre en el banner.
func _on_ticket_arrived(index: int) -> void:
	var tasks: Array = GameManager.night_tasks()
	if index < 0 or index >= tasks.size():
		return
	# El aviso es sutil, como en los juegos originales: el "ping" y nada más.
	# Con la PC abierta, una notificación de sistema dentro del escritorio;
	# con la PC cerrada, el sobrecito parpadeando sobre el monitor.
	if str(tasks[index].get("type", "")) == Tasks.TYPE_UNO_DECK:
		GameManager.uno_deck.make_available()
	AudioManager.play(Sounds.TICKET)
	if pc_screen.is_open:
		pc_screen.show_ticket_toast()
	else:
		office.blink_ticket()
	_refresh_tickets(0.0, true)


## El contador de tickets **ya no vive en el HUD de la oficina**: se consulta
## dentro de la PC, en la barra de abajo del escritorio y en la ventana de
## Tareas. Aquí solo se le avisa a la PC de que se repinte.
func _refresh_tickets(delta: float, force: bool = false) -> void:
	_ticket_elapsed += delta
	if not force and _ticket_elapsed < TICKET_REFRESH_TIME:
		return
	_ticket_elapsed = 0.0
	if pc_screen.is_open:
		pc_screen.refresh_tickets()


## Quién se ve en cada vista de la oficina. **Solo recortes**: si a alguien le
## faltara el suyo no se dibuja nada, que es mejor que escribir su nombre.
func _refresh_office_presence() -> void:
	# Una lista por vista, tipada, como la pide la capa de recortes.
	var by_view: Dictionary = {}
	for view: int in office.view_count():
		by_view[view] = [] as Array[Dictionary]
	for zone_id: String in office.layer_zone_ids():
		var view: int = office.view_of_zone(zone_id)
		# Hay que recorrer a todos, no quedarse con el primero: en el cristal
		# pueden coincidir Mamador, Ureña, Juan y Armando, y sus recortes ya
		# vienen colocados para no encimarse.
		for animatronic: Animatronic in _animatronics:
			if not animatronic.is_in_zone(zone_id):
				continue
			var slug: String = animatronic.image_slug()
			if slug.is_empty() or not office.has_layer(view, slug):
				continue
			by_view[view].append({
				"slug": slug,
				"lit_only": animatronic.needs_flashlight(zone_id),
			})
	_add_glass_silhouettes(by_view)
	for view: int in office.view_count():
		office.set_view_present(view, by_view[view])


## Los que andan al otro lado del cristal (la recepción y el tramo de
## pasillo_sur que se ve desde la oficina) se dibujan como silueta al fondo, en
## su propia capa debajo de la cortina. Pueden verse varios a la vez: cada
## silueta tiene su sitio y no se encima con las demás.
## Si todavía no existe su `layers/silueta_<id>.png`, no se dibuja nada.
func _add_glass_silhouettes(by_view: Dictionary) -> void:
	var center: Array[Dictionary] = by_view[office.glass_view()]
	var silhouettes: Array[Dictionary] = []
	for animatronic: Animatronic in _animatronics:
		if not animatronic.is_active:
			continue
		if not OfficeLayers.is_glass_room(animatronic.current_room):
			continue
		if not animatronic.shows_silhouette():
			continue
		var slug: String = animatronic.image_slug()
		if slug.is_empty():
			continue
		# Si ya se está dibujando entero pegado al cristal, la silueta sobra.
		var already: bool = center.any(func(entry: Dictionary) -> bool:
			return str(entry.get("slug", "")) == slug)
		if already:
			continue
		silhouettes.append({"slug": slug, "lit_only": false, "silhouette": true})
	office.set_silhouettes(silhouettes)


## Cada cuadro: la linterna alumbra el pasillo entero, así que a todos los que
## estén en el cristal les sube el susto a la vez.
func _update_glass_beams(delta: float) -> void:
	var is_lit: bool = office.is_flashlight_on()
	var armando_at_glass: bool = false
	for animatronic: Animatronic in _animatronics:
		var stalker: GlassStalker = animatronic as GlassStalker
		if stalker == null or not stalker.is_active:
			continue
		if stalker is ArmandoPrompts and stalker.is_at_glass():
			armando_at_glass = true
		stalker.update_beam(is_lit, delta)
	office.set_armando_at_glass(armando_at_glass)


## La cajita de la botarga, como en FNAF 2: **solo se oye con la CAM 4 en
## pantalla**. En la oficina no se oye nada... salvo cuando le queda poca
## cuerda: ahí entra muy bajita y con eco por el bus Lejos, como aviso de que
## hay que ir a dársela.
func _refresh_music_box() -> void:
	if _come_trabas == null or not _come_trabas.is_active:
		AudioManager.stop(Sounds.MUSIC_BOX)
		AudioManager.stop(Sounds.MUSIC_BOX_WARNING)
		return
	# Conforme se queda sin cuerda, la cajita se va quedando grave y lenta.
	var pitch: float = _come_trabas.music_pitch()
	var watching: bool = camera_system.is_open \
		and camera_system.current_camera == Rooms.camera_of(ComeTrabas.ROOM)
	if watching:
		AudioManager.stop(Sounds.MUSIC_BOX_WARNING)
		AudioManager.play_loop(Sounds.MUSIC_BOX)
		AudioManager.set_pitch(Sounds.MUSIC_BOX, pitch)
		return
	AudioManager.stop(Sounds.MUSIC_BOX)
	# Fuera de la CAM 4 solo se oye el aviso, y solo con poca cuerda.
	if _come_trabas.wind <= ComeTrabas.WARNING_THRESHOLD:
		AudioManager.play_loop(Sounds.MUSIC_BOX_WARNING)
		AudioManager.set_pitch(Sounds.MUSIC_BOX_WARNING, pitch)
	else:
		AudioManager.stop(Sounds.MUSIC_BOX_WARNING)


## Mira quién se movió desde el cuadro anterior y suelta su sonido lejano.
## Se hace aquí y no en cada profe para no llenarlos de señales: lo único que
## hace falta saber es en qué cuarto están, y eso ya es público.
func _track_distant_sounds() -> void:
	for animatronic: Animatronic in _animatronics:
		var slug: String = animatronic.image_slug()
		if slug.is_empty() or not animatronic.is_active:
			continue
		var room: String = animatronic.current_room
		var before: String = str(_last_rooms.get(slug, ""))
		if before != room:
			_last_rooms[slug] = room
			if not before.is_empty():
				_on_profe_moved(slug, before)
	# Rochis no cambia de cuarto: lo que cambia es su etapa en la silla.
	if _rochis != null and _rochis.is_active and _rochis.stage != _last_rochis_stage:
		if _last_rochis_stage >= 0:
			distant.play_for("rochis", Sounds.FAR_ROCHIS_CHAIR)
		_last_rochis_stage = _rochis.stage
	distant.refresh_room_loops(_animatronics)


func _on_profe_moved(slug: String, _from_room: String) -> void:
	# Los pasos de Barcosa los lleva él mismo, en bucle y durante toda su
	# carrera, así que aquí no hay nada que hacer con él.
	if slug == "barcosa":
		return
	var sound_id: String = str(DISTANT_ON_MOVE.get(slug, ""))
	if sound_id.is_empty():
		return
	if not distant.play_for(slug, sound_id):
		return
	# Lo que va pegado a ese movimiento suena con él, sin sortear otra vez.
	var together: String = str(DISTANT_WITH_MOVE.get(slug, ""))
	if not together.is_empty():
		AudioManager.play(together)


func _on_hour_changed(_hour: int) -> void:
	clock_label.text = GameManager.hour_text()


func _on_power_changed(percent: float) -> void:
	power_label.text = INFINITE_POWER_TEXT if PowerManager.is_infinite else "ENERGÍA %d%%" % roundi(percent)
	usage_bars.set_level(PowerManager.usage_level())


## La puerta la necesitan la energía y los profes que llegan a ella.
func _on_door_toggled(is_closed: bool) -> void:
	PowerManager.set_door_closed(is_closed)
	AudioManager.play(Sounds.DOOR_SHUTTER)
	for animatronic: Animatronic in _animatronics:
		animatronic.set_door_closed(is_closed)


func _on_cameras_opened() -> void:
	PowerManager.set_cameras_open(true)
	AudioManager.play_loop(Sounds.CAMERA_STATIC)
	AudioManager.play(Sounds.CAMERA_BLIP)
	camera_bar.set_pointing_up(false)
	# Con las cámaras arriba la oficina se queda quieta: si no, el mouse en el
	# borde la haría girar a espaldas del jugador.
	office.set_interactive(false)
	_update_watched_camera()


func _on_cameras_closed() -> void:
	PowerManager.set_cameras_open(false)
	AudioManager.stop(Sounds.CAMERA_STATIC)
	camera_bar.set_pointing_up(true)
	office.set_interactive(true)
	_update_watched_camera()


func _on_camera_changed(_camera: int) -> void:
	AudioManager.play(Sounds.CAMERA_BLIP)
	_update_watched_camera()


## Les dice a los profes qué cámara está mirando el jugador: a algunos,
## como Barcosa, vigilarlos los frena.
func _update_watched_camera() -> void:
	var camera: int = camera_system.current_camera if camera_system.is_open else Rooms.NO_CAMERA
	for animatronic: Animatronic in _animatronics:
		animatronic.set_watched_camera(camera)


# --- Linterna -----------------------------------------------------------------

func _on_flashlight_changed(is_on: bool) -> void:
	PowerManager.set_flashlight_on(is_on)
	AudioManager.play(Sounds.FLASHLIGHT_CLICK)
	notice_banner.show_sound(FLASHLIGHT_CLICK, NOTICE_SHORT)
	for animatronic: Animatronic in _animatronics:
		animatronic.set_flashlight_on(is_on)


func _on_flashlight_failed() -> void:
	notice_banner.show_notice(FLASHLIGHT_DEAD, NOTICE_TIME_DEAD)


# --- Teléfono -----------------------------------------------------------------

## La llamada de la noche suena a los pocos segundos. La de Ureña, si toca,
## en un momento al azar entre las 2 y las 4 AM.
func _schedule_calls(night: int) -> void:
	# Si esa noche no tiene guion, el teléfono no suena.
	_nightly_call_left = NightCalls.CALL_DELAY if NightCalls.has_call(night) else -1.0
	# La llamada rara entra todas las noches, una sola vez, entre la 1 y las
	# 5 AM. La noche 1 es siempre la del Mencho; desde la 2 se sortea.
	_random_call_id = NightCalls.random_call(night)
	_mencho_call_at = NightCalls.mencho_hour() if not _random_call_id.is_empty() else -1.0
	_urena_calls_at.clear()
	phone_call.reset_urena_lines()
	if _urena == null or not _urena.is_active:
		return
	if randi_range(1, 100) > URENA_CALL_CHANCE:
		return
	# En las noches altas puede llamar dos veces, siempre entre 2 y 4 AM.
	var calls: int = 2 if night >= URENA_TWO_CALLS_FROM_NIGHT else 1
	for i: int in calls:
		_urena_calls_at.append(randf_range(2.0, 4.0))
	_urena_calls_at.sort()


func _process_calls(delta: float) -> void:
	if _nightly_call_left > 0.0:
		_nightly_call_left -= delta
		if _nightly_call_left <= 0.0:
			phone_call.queue_recording(GameManager.current_night, NightCalls.RING_TIME)
		return
	# El teléfono es uno: si está sonando o abierto, lo que toque espera.
	if phone_call.is_ringing or phone_call.is_open:
		return
	if _mencho_call_at >= 0.0 and GameManager.night_progress() >= _mencho_call_at:
		_mencho_call_at = -1.0
		phone_call.queue_mencho(NightCalls.MENCHO_RING_TIME)
		return
	if _urena_calls_at.is_empty() or GameManager.night_progress() < _urena_calls_at[0]:
		return
	_urena_calls_at.remove_at(0)
	trigger_urena_call()


## Tecla 2, y también la llamada de la noche cuando le toca.
## El panel de pruebas puede pedir una insinuación concreta por su índice;
## con -1 va al azar, como en el juego.
func debug_urena_call(index: int = -1) -> void:
	if phone_call.is_ringing or phone_call.is_open:
		return
	if index < 0:
		trigger_urena_call()
		return
	var line: Dictionary = UrenaQuestions.line(index)
	if line.is_empty():
		return
	phone_call.queue_urena_call([line] as Array[Dictionary], URENA_RING_TIME)


func trigger_urena_call() -> void:
	if phone_call.is_ringing or phone_call.is_open:
		return
	# Las que ya salieron esta noche no se repiten.
	phone_call.queue_urena_call(UrenaQuestions.pick(phone_call.used_urena_lines()), URENA_RING_TIME)


func _on_ringing_started(_seconds: float) -> void:
	office.set_phone_ringing(true)
	AudioManager.play_loop(Sounds.PHONE_RING)


func _on_ring_tick() -> void:
	notice_banner.show_sound(RING_NOTICE, NOTICE_SHORT)
	office.pulse_phone_ring()


func _on_call_answered() -> void:
	office.set_phone_ringing(false)
	AudioManager.stop(Sounds.PHONE_RING)
	office.set_phone_in_call(true)


## Si no contestas la de Ureña, te mata. La de la noche es opcional.
## No contestar ya no mata a nadie. Si era Ureña, se ofende, y eso lo cobra
## _on_urena_snubbed.
func _on_call_missed() -> void:
	office.set_phone_ringing(false)
	AudioManager.stop(Sounds.PHONE_RING)
	office.set_phone_in_call(false)


## Lo que dice por el altavoz tras colgarle, para que se lea además de oírse.
func _on_snub_line(text: String) -> void:
	notice_banner.show_notice("[Ureña: %s]" % text, NOTICE_TIME_DEAD)


## Le colgaron o no le contestaron: deja la foto y se pone más agresivo por
## una hora de juego.
func _on_urena_snubbed() -> void:
	office.add_urena_photo()
	GameManager.add_ai_boost(Nights.URENA, Nights.URENA_SNUB_BOOST, Nights.URENA_SNUB_HOURS)
	notice_banner.show_notice(URENA_SNUB_NOTICE, NOTICE_SHORT)


func _on_call_ended() -> void:
	office.set_phone_ringing(false)
	office.set_phone_in_call(false)


## Armando se apareció en la pantalla y el jugador no lo echó a tiempo: su
## progreso ya se borró en la PC, aquí se cobra la energía.
func _on_armando_won() -> void:
	PowerManager.drain(ArmandoPrompts.TAKEOVER_POWER_COST)
	notice_banner.show_notice(ARMANDO_NOTICE, NOTICE_SHORT)


## Esquivar con educación no cuesta nada. Seguirle el juego o contestarle
## grosero cuestan energía, y solo seguirle el juego le deja una foto encima
## del escritorio.
func _on_answer_given(kind: int) -> void:
	if UrenaQuestions.costs_power(kind):
		PowerManager.drain(UrenaQuestions.WRONG_ANSWER_POWER_COST)
	if UrenaQuestions.leaves_photo(kind):
		office.add_urena_photo()


## La barra de cámaras no hace nada si el guardia no está en la oficina.
func _on_camera_bar_hovered() -> void:
	if GameManager.is_in_server_room:
		return
	if momo_event != null and momo_event.is_playing:
		return
	camera_system.toggle()


## La sala de servidores: fundido de 1 s con "[pasos]" a la mitad.
func _enter_server_room() -> void:
	if GameManager.is_in_server_room:
		return
	camera_system.close()
	pc_screen.close()
	notice_banner.show_sound(STEPS_NOTICE, STEPS_NOTICE_TIME)
	fade_overlay.play()
	await fade_overlay.midpoint_reached
	GameManager.is_in_server_room = true
	office.visible = false
	# La barra de cámaras se esconde: allá no sirve de nada y confunde.
	camera_bar.visible = false
	_set_hud_compact(true)
	server_room.open()


## Pidió el monitor desde la sala: se sale y, ya en la oficina, se abre.
func _on_server_cameras_requested() -> void:
	_open_cameras_on_return = true


func _leave_server_room() -> void:
	notice_banner.show_sound(STEPS_NOTICE, STEPS_NOTICE_TIME)
	fade_overlay.play()
	await fade_overlay.midpoint_reached
	GameManager.is_in_server_room = false
	office.visible = true
	camera_bar.visible = true
	# Se vuelve siempre a un estado limpio: la oficina responde y el monitor
	# está abajo, pase lo que pase dentro de la sala.
	office.set_interactive(true)
	office.zoom_out()
	if _open_cameras_on_return:
		_open_cameras_on_return = false
		camera_system.open()


## La descarga del pararrayos: destello blanco y estática en todas las cámaras.
func _on_discharge(_cameras: PackedInt32Array) -> void:
	camera_system.on_discharge()
	flash_overlay.visible = true
	flash_overlay.color.a = 0.85
	var tween: Tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.0, FLASH_TIME)
	tween.tween_callback(func() -> void: flash_overlay.visible = false)


## El breaker: "[clac]", el temblor lo hace el tablero, y la oficina a oscuras.
func _on_breaker_pulled() -> void:
	AudioManager.play(Sounds.BREAKER_LEVER)
	notice_banner.show_sound(BREAKER_NOTICE, BREAKER_NOTICE_TIME)


## Sin corriente se apagan las cámaras y la PC, y la oficina se oscurece.
## La chapa de la puerta sigue, porque está en el no-break.
# --- Apagón, susto y jumpscares -----------------------------------------------

## El cortaso: primero el susto del Mago y después la estática de siempre.
func _on_cortaso_started() -> void:
	jumpscare.play_scare()
	cortaso_overlay.play()


## Se acabó la energía: la noche sigue a oscuras y el Mago viene a cobrar.
# --- El rescate de Sergio -----------------------------------------------------

## Sergio paró una muerte. Mientras dura la escena, el reloj se detiene y los
## profes se quedan quietos; al acabar, el que atacaba vuelve a su sitio, la
## energía sube un 10 % y la noche sigue donde estaba.
func _on_sergio_rescued(cause: String) -> void:
	_rescued_from = cause
	GameManager.set_clock_held(true)
	for animatronic: Animatronic in _animatronics:
		animatronic.set_process(false)
	var jumpscare_id: String = ""
	for animatronic: Animatronic in _animatronics:
		if animatronic.game_over_cause() == cause:
			jumpscare_id = animatronic.jumpscare_id()
			break
	sergio_rescue.play(jumpscare_id)


## Se acabó el congelado: que baje Sergio en su haz de luz, en la oficina.
func _on_sergio_requested() -> void:
	office.show_center_view()
	office.sergio.play()


## El tótem terminó de girar: Sergio se desvanece mientras suena la cola de la
## música.
func _on_totem_finished() -> void:
	office.sergio.fade_out()


## Se acabó la pista del rescate: se reparte lo que deja Sergio —el profe a su
## sitio, energía de vuelta— y la noche sigue donde estaba.
func _on_sergio_left() -> void:
	for animatronic: Animatronic in _animatronics:
		animatronic.set_process(true)
		if animatronic.game_over_cause() == _rescued_from:
			animatronic.go_home()
	_rescued_from = ""
	PowerManager.restore(Sergio.POWER_BACK)
	GameManager.set_clock_held(false)
	GameManager.end_rescue()


## El tótem, cuando se trae encima: de pie sobre el escritorio de la oficina y,
## además, su ícono en la esquina del HUD, que es lo único que se ve desde las
## otras vistas o con la PC abierta.
func _on_totem_changed(has_it: bool) -> void:
	if totem_icon != null:
		totem_icon.visible = has_it
	office.set_totem_on_desk(has_it)


# --- El susto de Momo ---------------------------------------------------------

func _build_momo() -> void:
	momo_event = MOMO_EVENT.new()
	momo_event.name = "MomoEvent"
	$Hud.add_child(momo_event)
	momo_event.view_requested.connect(func() -> void: office.set_momo_active(true))
	momo_event.zoom_changed.connect(office.set_momo_zoom)
	momo_event.finished.connect(_on_momo_finished)


## Cada vez que la cabeza llega a una vista se tira el dado: si es la izquierda,
## es de noche 2 o más alta, no ha salido ya esta noche y no hay ningún susto en
## curso, Momo tiene un 6 % de aparecer.
func _on_view_changed(view: int) -> void:
	if view != office.View.LEFT or _momo_used:
		return
	if GameManager.current_night < Momo.FROM_NIGHT:
		return
	if not _is_calm():
		return
	if randi_range(1, 100) > Momo.CHANCE:
		return
	start_momo()


## ¿Está todo tranquilo? Con otro susto encima, Momo no entra: dos sustos a la
## vez no se entienden y además se pelearían por el audio.
func _is_calm() -> bool:
	if momo_event.is_playing or jumpscare.is_playing:
		return false
	if blackout_death.is_running or sergio_rescue.is_playing:
		return false
	return GameManager.is_night_active and not GameManager.is_rescuing


## Momo toma la vista izquierda: **el juego se para por completo** y solo se oye
## su canción. Al acabar sigue todo donde estaba, sin muerte y sin coste.
func start_momo() -> void:
	if momo_event.is_playing:
		return
	_momo_used = true
	camera_system.close()
	pc_screen.close()
	GameManager.set_clock_held(true)
	PowerManager.set_draining(false)
	for animatronic: Animatronic in _animatronics:
		animatronic.set_process(false)
	phone_call.set_process(false)
	office.set_locked(true)
	# El ambiente y la llamada se quedan quietos donde iban, no se cortan.
	AudioManager.set_paused_except([Sounds.MOMO_SONG], true)
	momo_event.play()


func _on_momo_finished() -> void:
	office.set_momo_active(false)
	office.set_locked(false)
	AudioManager.set_paused_except([], false)
	for animatronic: Animatronic in _animatronics:
		animatronic.set_process(true)
	phone_call.set_process(true)
	PowerManager.set_draining(true)
	GameManager.set_clock_held(false)


## Para el panel de pruebas: monta el rescate con el primer profe activo que
## pueda matar, sin esperar a que te atrape de verdad.
func debug_sergio_rescue() -> void:
	if GameManager.is_rescuing:
		return
	var cause: String = ""
	for animatronic: Animatronic in _animatronics:
		var their_cause: String = animatronic.game_over_cause()
		if their_cause.is_empty() or their_cause == Mamador.GAME_OVER_CAUSE:
			continue
		cause = their_cause
		if animatronic.is_active:
			break
	if cause.is_empty():
		return
	GameManager.give_totem()
	GameManager.trigger_game_over(cause)


## Y la maquinita, en el nivel que se le pida. Como es una pantalla completa,
## al salir de ella la noche vuelve a empezar: es un botón de pruebas.
func debug_open_minigame(level: int, part_c: bool = false) -> void:
	ArcadeScreen.pending_level = level
	ArcadeScreen.pending_part_c = part_c
	ArcadeScreen.next_scene = Screens.NIGHT
	get_tree().paused = false
	get_tree().change_scene_to_file(Screens.ARCADE)


func _on_power_depleted() -> void:
	if not GameManager.is_night_active:
		return
	camera_system.close()
	pc_screen.close()
	# Lo que se oye justo al apagarse todo, antes de que empiece la oscuridad.
	# La frase abre la secuencia del apagón: la oscuridad no pasa a la cajita
	# musical hasta que se acaba de decir (son 6 s y la oscuridad puede durar
	# solo 3, así que antes se encimaban).
	AudioManager.begin_sequence(Sounds.SEQ_BLACKOUT)
	AudioManager.play_in_sequence(Sounds.SEQ_BLACKOUT, Sounds.BLACKOUT_LINE)
	blackout_death.start()


## Llegó el salto del apagón.
func _on_blackout_strike() -> void:
	if not GameManager.is_night_active:
		return
	GameManager.trigger_game_over(BLACKOUT_CAUSE)


## El salto terminó: ahora sí se cambia a la pantalla de game over.
func _on_jumpscare_finished() -> void:
	get_tree().change_scene_to_file(Screens.GAME_OVER)


func _on_blackout_changed(is_blackout: bool) -> void:
	office.set_blackout(is_blackout)
	# Sin corriente no hay lámparas ni ventilador: el zumbido se va con la luz.
	if is_blackout:
		AudioManager.stop(Sounds.OFFICE_AMBIENCE)
	elif GameManager.is_night_active:
		AudioManager.play_loop(Sounds.OFFICE_AMBIENCE)
	if not is_blackout:
		return
	camera_system.close()
	pc_screen.close()
	if _audel != null:
		_audel.on_blackout()


## Pasó la noche: se guarda el avance, se abren las fichas de los profes que
## estuvieron activos y se deja apuntado el recorte que toca.
func _on_night_won(night: int) -> void:
	_end_night()
	blackout_death.cancel()
	if GameManager.is_custom_night:
		# La Custom Night no da recorte ni avanza la historia, pero ganarla con
		# los ocho en 20 vale una estrella en el menú.
		if GameManager.is_custom_night_maxed():
			SaveGame.mark_custom_mastered()
		SaveGame.mark_challenge_won(GameManager.custom_challenge)
	else:
		SaveGame.mark_night_cleared(night)
		SaveGame.unlock_newspaper(Newspapers.index_for_cleared_night(night))
		_unlock_night_dossiers()
	get_tree().change_scene_to_file(Screens.WIN)


## Abre las fichas de los profes que estuvieron activos esta noche. Se mira
## el nivel de la noche y no is_active, porque _end_night() ya los paró.
func _unlock_night_dossiers() -> void:
	for animatronic: Animatronic in _animatronics:
		var slug: String = animatronic.image_slug()
		if slug.is_empty():
			continue
		var key: String = animatronic.ai_key()
		# Los que no usan la tabla (la botarga) están activos toda la noche.
		if key.is_empty() or GameManager.ai_level_for(key) > 0:
			SaveGame.unlock_dossier(slug)


## Te atraparon: se abre la ficha y el jumpscare de quien fue.
func _on_game_over(cause: String) -> void:
	_end_night()
	blackout_death.cancel()
	var jumpscare_id: String = BLACKOUT_JUMPSCARE if cause == BLACKOUT_CAUSE else ""
	var caption: String = ""
	# El apagón es cosa del Mago, aunque no se le haya visto venir.
	GameManager.last_game_over_slug = BLACKOUT_JUMPSCARE if cause == BLACKOUT_CAUSE else ""
	for animatronic: Animatronic in _animatronics:
		if not animatronic.owns_cause(cause):
			continue
		SaveGame.unlock_dossier(animatronic.image_slug())
		GameManager.last_game_over_slug = animatronic.image_slug()
		jumpscare_id = animatronic.jumpscare_id()
		caption = animatronic.jumpscare_caption()
		break
	SaveGame.unlock_jumpscare(cause)
	# Mamador no salta: su final es la pantalla de WASTED.
	if cause == Mamador.GAME_OVER_CAUSE or cause == Mamador.GAMBLING_CAUSE:
		wasted_screen.play(JumpscareOverlay.mamador_image(),
			JumpscareOverlay.mamador_text(cause), true)
		return
	if jumpscare_id.is_empty():
		get_tree().change_scene_to_file(Screens.GAME_OVER)
		return
	jumpscare.play(jumpscare_id, caption)


## La baraja aparece o desaparece del escritorio: lo único que hay que mover
## es si su zona se puede picar, porque el dibujo lo lleva la propia capa.
func _refresh_uno_deck() -> void:
	office.set_uno_deck_clickable(GameManager.uno_deck.is_available)


## La botarga se quedó sin cuerda: la cajita musical se calla y por eso el
## jugador se da cuenta.
func _on_music_box_stopped() -> void:
	AudioManager.stop(Sounds.MUSIC_BOX)
	AudioManager.stop(Sounds.MUSIC_BOX_WARNING)


## Deja de gastar energía y congela a los profes antes de cambiar de pantalla.
func _end_night() -> void:
	set_process(false)
	camera_system.close()
	pc_screen.close()
	hallucinations.set_process(false)
	call_subtitles.mute()
	voice_line.stop()
	distant.stop_all()
	controls_card.close_card()
	wasted_screen.stop()
	uno_desk.close()
	AudioManager.stop_all()
	for animatronic: Animatronic in _animatronics:
		animatronic.stop()
