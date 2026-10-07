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

const STEPS_NOTICE: String = "[pasos]"
const STEPS_NOTICE_TIME: float = 1.2
## Lo que dura el destello blanco de la descarga.
const FLASH_TIME: float = 0.28

@onready var office: Control = $Office
@onready var camera_system: Control = $CameraSystem
@onready var pc_screen: Control = $PcScreen
@onready var animatronics_holder: Node = $Animatronics
@onready var clock_label: Label = $Hud/ClockLabel
@onready var night_label: Label = $Hud/NightLabel
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
@onready var server_room: Control = $ServerRoom
@onready var fade_overlay: ColorRect = $Hud/FadeOverlay
@onready var flash_overlay: ColorRect = $Hud/FlashOverlay

const ARMANDO_NOTICE: String = "[Armando borró tu progreso]"

var _animatronics: Array[Animatronic] = []
var _debug_shown: bool = false
var _come_trabas: ComeTrabas = null
var _audel: Audel = null
var _urena: Urena = null

# Teléfono: la llamada de la noche y la de Ureña.
var _nightly_call_left: float = 0.0
var _urena_call_at: float = -1.0
var _urena_call_ringing: bool = false


func _ready() -> void:
	_animatronics = _collect_animatronics()
	for animatronic: Animatronic in _animatronics:
		animatronic.made_noise.connect(notice_banner.show_notice)
		if animatronic is ComeTrabas:
			_come_trabas = animatronic as ComeTrabas
			# Al quedarse sin cuerda, la silla del cubículo 3 queda vacía.
			_come_trabas.music_stopped.connect(office.set_right_view_empty.bind(true))
		elif animatronic is Urena:
			_urena = animatronic as Urena
		elif animatronic is ArmandoPrompts:
			pc_screen.set_armando(animatronic as ArmandoPrompts)
		elif animatronic is Audel:
			_audel = animatronic as Audel
			_audel.cortaso_started.connect(cortaso_overlay.play)
			_audel.discharge_started.connect(_on_discharge)

	office.door_toggled.connect(_on_door_toggled)
	office.pc_requested.connect(pc_screen.open)
	office.notice_requested.connect(notice_banner.show_notice)
	office.breaker_requested.connect(breaker_panel.open)
	office.phone_requested.connect(phone_call.answer)
	office.flashlight_changed.connect(_on_flashlight_changed)
	office.flashlight_failed.connect(_on_flashlight_failed)

	phone_call.ring_tick.connect(_on_ring_tick)
	phone_call.ringing_started.connect(_on_ringing_started)
	phone_call.call_answered.connect(_on_call_answered)
	phone_call.call_missed.connect(_on_call_missed)
	phone_call.call_ended.connect(_on_call_ended)
	phone_call.answer_given.connect(_on_answer_given)
	office.server_room_requested.connect(_enter_server_room)
	server_room.closed.connect(_leave_server_room)
	server_room.notice_requested.connect(notice_banner.show_notice)
	breaker_panel.closed.connect(office.zoom_out)
	breaker_panel.lever_pulled.connect(_on_breaker_pulled)
	PowerManager.blackout_changed.connect(_on_blackout_changed)

	camera_system.set_animatronics(_animatronics)
	camera_system.opened.connect(_on_cameras_opened)
	camera_system.closed.connect(_on_cameras_closed)
	camera_system.camera_changed.connect(_on_camera_changed)
	camera_system.notice_requested.connect(notice_banner.show_notice)
	camera_bar.hovered.connect(_on_camera_bar_hovered)

	# La PC y las cámaras no pueden estar abiertas a la vez.
	pc_screen.opened.connect(camera_system.close)
	camera_system.opened.connect(pc_screen.close)
	# Al bajar la PC, la vista de la oficina regresa de su acercamiento.
	pc_screen.closed.connect(office.zoom_out)
	pc_screen.armando_won.connect(_on_armando_won)

	GameManager.night_started.connect(_on_night_started)
	GameManager.hour_changed.connect(_on_hour_changed)
	GameManager.night_won.connect(_on_night_won)
	GameManager.game_over.connect(_on_game_over)
	PowerManager.power_changed.connect(_on_power_changed)

	_apply_debug_shown()

	pause_menu.resumed.connect(_on_resumed)
	pause_menu.menu_requested.connect(_on_menu_requested)
	GameManager.start_night()


## Escape pausa la noche, salvo que ya lo esté usando otra cosa: la PC, el
## breaker, la sala de servidores o la foto de Ureña abierta. El reloj y los
## profes se detienen porque se pausa el árbol entero.
func _escape_is_taken() -> bool:
	if pc_screen.is_open or GameManager.is_in_server_room:
		return true
	if breaker_panel.visible:
		return true
	return office.photo_viewer != null and office.photo_viewer.is_open


func _on_resumed() -> void:
	get_tree().paused = false


func _on_menu_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(Screens.MAIN_MENU)


## Las teclas de depuración salen de data/debug_keys.gd, así que con
## DEBUG_KEYS en false ninguna responde.
func _unhandled_input(event: InputEvent) -> void:
	if DebugKeys.matches(event, DebugKeys.HELP):
		_debug_shown = not _debug_shown
		_apply_debug_shown()
	elif DebugKeys.matches(event, DebugKeys.INFINITE_POWER):
		PowerManager.toggle_infinite()
	elif DebugKeys.matches(event, DebugKeys.URENA_CALL):
		trigger_urena_call()
	else:
		return
	get_viewport().set_input_as_handled()


## Un solo interruptor: la ayuda de teclas, la etiqueta de los profes y las
## zonas de clic de la oficina.
func _apply_debug_shown() -> void:
	camera_system.set_debug_visible(_debug_shown)
	office.set_zones_visible(_debug_shown)
	debug_help.visible = _debug_shown and DebugKeys.DEBUG_KEYS
	if debug_help.visible:
		debug_help.text = "\n".join(DebugKeys.help_lines())


## Los profes son hijos del nodo Animatronics, así se agregan sin tocar código.
func _collect_animatronics() -> Array[Animatronic]:
	var found: Array[Animatronic] = []
	for child: Node in animatronics_holder.get_children():
		if child is Animatronic:
			found.append(child as Animatronic)
	return found


func _on_night_started(night: int) -> void:
	night_label.text = "Noche %d" % night
	office.set_right_view_empty(false)
	_schedule_calls(night)
	for animatronic: Animatronic in _animatronics:
		animatronic.start()


## Quién se ve en cada vista de la oficina. Si ya existe su recorte PNG, se
## dibuja el recorte; si no, se queda la etiqueta de texto de siempre.
func _process(delta: float) -> void:
	pause_menu.blocked = _escape_is_taken()
	_process_calls(delta)
	_refresh_office_presence()
	# El aviso de la cuerda se ve esté donde esté el jugador, como en FNAF 2.
	warning_icon.set_level(0 if _come_trabas == null else _come_trabas.warning_level())


## Por cada zona de presencia busca al primer profe que se vea ahí. Con
## recorte va a la capa de su vista; sin recorte, a su etiqueta.
func _refresh_office_presence() -> void:
	# Una lista por vista, tipada, como la pide la capa de recortes.
	var by_view: Dictionary = {}
	for view: int in office.view_count():
		by_view[view] = [] as Array[Dictionary]
	for zone_id: String in office.presence_zone_ids():
		var view: int = office.view_of_zone(zone_id)
		var label: String = ""
		for animatronic: Animatronic in _animatronics:
			if not animatronic.is_in_zone(zone_id):
				continue
			var slug: String = animatronic.image_slug()
			if not slug.is_empty() and office.has_layer(view, slug):
				by_view[view].append({
					"slug": slug,
					"lit_only": animatronic.needs_flashlight(zone_id),
				})
			else:
				label = animatronic.zone_presence(zone_id)
			break
		office.set_zone_presence(zone_id, label)
	for view: int in office.view_count():
		office.set_view_present(view, by_view[view])


func _on_hour_changed(_hour: int) -> void:
	clock_label.text = GameManager.hour_text()


func _on_power_changed(percent: float) -> void:
	power_label.text = INFINITE_POWER_TEXT if PowerManager.is_infinite else "Energía: %d%%" % roundi(percent)
	usage_bars.set_level(PowerManager.usage_level())


## La puerta la necesitan la energía y los profes que llegan a ella.
func _on_door_toggled(is_closed: bool) -> void:
	PowerManager.set_door_closed(is_closed)
	for animatronic: Animatronic in _animatronics:
		animatronic.set_door_closed(is_closed)


func _on_cameras_opened() -> void:
	PowerManager.set_cameras_open(true)
	camera_bar.set_pointing_up(false)
	# Con las cámaras arriba la oficina se queda quieta: si no, el mouse en el
	# borde la haría girar a espaldas del jugador.
	office.set_interactive(false)
	_update_watched_camera()


func _on_cameras_closed() -> void:
	PowerManager.set_cameras_open(false)
	camera_bar.set_pointing_up(true)
	office.set_interactive(true)
	_update_watched_camera()


func _on_camera_changed(_camera: int) -> void:
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
	notice_banner.show_notice(FLASHLIGHT_CLICK, NOTICE_SHORT)
	for animatronic: Animatronic in _animatronics:
		animatronic.set_flashlight_on(is_on)


func _on_flashlight_failed() -> void:
	notice_banner.show_notice(FLASHLIGHT_DEAD, NOTICE_TIME_DEAD)


# --- Teléfono -----------------------------------------------------------------

## La llamada de la noche suena a los pocos segundos. La de Ureña, si toca,
## en un momento al azar entre las 2 y las 4 AM.
func _schedule_calls(night: int) -> void:
	_nightly_call_left = Calls.NIGHTLY_CALL_DELAY
	_urena_call_at = -1.0
	_urena_call_ringing = false
	if _urena == null or not _urena.is_active:
		return
	if randi_range(1, 100) > URENA_CALL_CHANCE:
		return
	_urena_call_at = randf_range(2.0, 4.0)


func _process_calls(delta: float) -> void:
	if _nightly_call_left > 0.0:
		_nightly_call_left -= delta
		if _nightly_call_left <= 0.0:
			phone_call.queue_message(Calls.for_night(GameManager.current_night), Calls.NIGHTLY_RING_TIME)
		return
	if _urena_call_at >= 0.0 and GameManager.night_progress() >= _urena_call_at:
		_urena_call_at = -1.0
		trigger_urena_call()


## Tecla 2, y también la llamada de la noche cuando le toca.
func trigger_urena_call() -> void:
	if phone_call.is_ringing or phone_call.is_open:
		return
	_urena_call_ringing = true
	phone_call.queue_urena_call(UrenaQuestions.pick(), URENA_RING_TIME)


func _on_ringing_started(_seconds: float) -> void:
	office.set_phone_ringing(true)


func _on_ring_tick() -> void:
	notice_banner.show_notice(RING_NOTICE, NOTICE_SHORT)
	office.pulse_phone_ring()


func _on_call_answered() -> void:
	office.set_phone_ringing(false)
	office.set_phone_in_call(true)


## Si no contestas la de Ureña, te mata. La de la noche es opcional.
func _on_call_missed() -> void:
	office.set_phone_ringing(false)
	office.set_phone_in_call(false)
	if not _urena_call_ringing:
		return
	_urena_call_ringing = false
	GameManager.trigger_game_over(Urena.GAME_OVER_CAUSE)


func _on_call_ended() -> void:
	_urena_call_ringing = false
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
	camera_system.toggle()


## La sala de servidores: fundido de 1 s con "[pasos]" a la mitad.
func _enter_server_room() -> void:
	if GameManager.is_in_server_room:
		return
	camera_system.close()
	pc_screen.close()
	notice_banner.show_notice(STEPS_NOTICE, STEPS_NOTICE_TIME)
	fade_overlay.play()
	await fade_overlay.midpoint_reached
	GameManager.is_in_server_room = true
	office.visible = false
	# La barra de cámaras se esconde: allá no sirve de nada y confunde.
	camera_bar.visible = false
	server_room.open()


func _leave_server_room() -> void:
	notice_banner.show_notice(STEPS_NOTICE, STEPS_NOTICE_TIME)
	fade_overlay.play()
	await fade_overlay.midpoint_reached
	GameManager.is_in_server_room = false
	office.visible = true
	camera_bar.visible = true
	office.zoom_out()


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
	notice_banner.show_notice(BREAKER_NOTICE, BREAKER_NOTICE_TIME)


## Sin corriente se apagan las cámaras y la PC, y la oficina se oscurece.
## La chapa de la puerta sigue, porque está en el no-break.
func _on_blackout_changed(is_blackout: bool) -> void:
	office.set_blackout(is_blackout)
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
	if not GameManager.is_custom_night:
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
	for animatronic: Animatronic in _animatronics:
		if animatronic.game_over_cause() != cause:
			continue
		SaveGame.unlock_dossier(animatronic.image_slug())
		SaveGame.unlock_jumpscare(cause)
		break
	get_tree().change_scene_to_file(Screens.GAME_OVER)


## Deja de gastar energía y congela a los profes antes de cambiar de pantalla.
func _end_night() -> void:
	set_process(false)
	camera_system.close()
	pc_screen.close()
	for animatronic: Animatronic in _animatronics:
		animatronic.stop()
