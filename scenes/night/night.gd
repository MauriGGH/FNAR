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
@onready var ticket_label: Label = $Hud/TicketLabel
@onready var ticket_chime: AudioStreamPlayer = $Hud/TicketChime
@onready var jumpscare: Control = $Hud/JumpscareOverlay
@onready var blackout_death: Control = $Hud/BlackoutDeath
@onready var mod_menu: Control = $Hud/ModMenu
@onready var server_room: Control = $ServerRoom
@onready var fade_overlay: ColorRect = $Hud/FadeOverlay
@onready var flash_overlay: ColorRect = $Hud/FlashOverlay

const ARMANDO_NOTICE: String = "[Armando borró tu progreso]"
const URENA_SNUB_NOTICE: String = "[Ureña se quedo esperando...]"
## La causa cuando el apagón te alcanza. Es cosa del Mago, no de la energía.
const NO_CALL_NOTICE: String = "[esta noche no tiene guion de llamada]"
const BLACKOUT_CAUSE: String = "Mago Eléctrico"
const BLACKOUT_JUMPSCARE: String = "audel"
const TICKET_NOTICE: String = "[ticket nuevo: %s]"
const TICKET_EXPIRED_NOTICE: String = "[se te vencio un ticket]"
## Cada cuánto se repinta el contador de tickets.
const TICKET_REFRESH_TIME: float = 0.25

var _animatronics: Array[Animatronic] = []
var _debug_shown: bool = false
var _come_trabas: ComeTrabas = null
var _audel: Audel = null
var _urena: Urena = null

# Teléfono: la llamada de la noche y la de Ureña.
var _nightly_call_left: float = 0.0
## Las horas a las que va a llamar esta noche, de la más temprana a la última.
var _urena_calls_at: PackedFloat32Array = PackedFloat32Array()
var _ticket_elapsed: float = 0.0


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
			_audel.cortaso_started.connect(_on_cortaso_started)
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
	phone_call.urena_snubbed.connect(_on_urena_snubbed)
	phone_call.snub_line.connect(_on_snub_line)
	phone_call.call_ended.connect(_on_call_ended)
	phone_call.answer_given.connect(_on_answer_given)
	office.server_room_requested.connect(_enter_server_room)
	server_room.closed.connect(_leave_server_room)
	server_room.notice_requested.connect(notice_banner.show_notice)
	breaker_panel.closed.connect(office.zoom_out)
	breaker_panel.lever_pulled.connect(_on_breaker_pulled)
	PowerManager.blackout_changed.connect(_on_blackout_changed)
	PowerManager.power_depleted.connect(_on_power_depleted)
	blackout_death.strike.connect(_on_blackout_strike)
	jumpscare.finished.connect(_on_jumpscare_finished)

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

	GameManager.ticket_arrived.connect(_on_ticket_arrived)
	GameManager.ticket_expired.connect(_on_ticket_expired)
	GameManager.night_started.connect(_on_night_started)
	GameManager.hour_changed.connect(_on_hour_changed)
	GameManager.night_won.connect(_on_night_won)
	GameManager.game_over.connect(_on_game_over)
	PowerManager.power_changed.connect(_on_power_changed)

	_apply_debug_shown()

	pause_menu.resumed.connect(_on_resumed)
	pause_menu.menu_requested.connect(_on_menu_requested)
	GameManager.start_night()
	# El panel se arma después de arrancar la noche: hasta aquí los profes no
	# tienen ruta, y el panel la necesita para su lista de cuartos.
	mod_menu.bind(self)


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


## Un solo interruptor: la ayuda de teclas, la etiqueta de los profes y las
## zonas de clic de la oficina.
func _apply_debug_shown() -> void:
	camera_system.set_debug_visible(_debug_shown)
	office.set_zones_visible(_debug_shown)
	debug_help.visible = false  # La ayuda vive ahora en el panel de pruebas.


## La lista de profes, para el panel de pruebas.
func animatronics() -> Array[Animatronic]:
	return _animatronics


## El panel de pruebas dispara la llamada de inicio de noche. Si esa noche no
## tiene guion escrito, avisa en vez de quedarse callado.
func debug_night_call() -> void:
	var lines: PackedStringArray = NightCalls.for_night(GameManager.current_night)
	if lines.is_empty():
		notice_banner.show_notice(NO_CALL_NOTICE, NOTICE_SHORT)
		return
	phone_call.queue_message(lines, NightCalls.RING_TIME)


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
	_refresh_tickets(delta)
	_process_calls(delta)
	_refresh_office_presence()
	# El aviso de la cuerda se ve esté donde esté el jugador, como en FNAF 2.
	warning_icon.set_level(0 if _come_trabas == null else _come_trabas.warning_level())


# --- Tickets ------------------------------------------------------------------

## Llegó un ticket: suena el aviso y sale su nombre en el banner.
func _on_ticket_arrived(index: int) -> void:
	var tasks: Array = GameManager.night_tasks()
	if index < 0 or index >= tasks.size():
		return
	ticket_chime.play()
	notice_banner.show_notice(TICKET_NOTICE % str(tasks[index].get("title", "tarea")), NOTICE_SHORT)
	_refresh_tickets(0.0, true)


## Se venció: cuesta energía y Mamador se pone más agresivo por una hora.
func _on_ticket_expired(_index: int) -> void:
	PowerManager.drain(Nights.TICKET_POWER_COST)
	GameManager.add_ai_boost(Nights.MAMADOR, Nights.TICKET_MAMADOR_BOOST, Nights.TICKET_BOOST_HOURS)
	notice_banner.show_notice(TICKET_EXPIRED_NOTICE, NOTICE_SHORT)
	_refresh_tickets(0.0, true)


## El contador de la esquina: cuántos tickets llevas y cuánto le queda al más
## urgente. Mientras no llegue ninguno no se enseña nada.
func _refresh_tickets(delta: float, force: bool = false) -> void:
	_ticket_elapsed += delta
	if not force and _ticket_elapsed < TICKET_REFRESH_TIME:
		return
	_ticket_elapsed = 0.0
	var arrived: int = GameManager.arrived_ticket_count()
	if arrived <= 0:
		ticket_label.text = ""
		return
	var done: int = GameManager.paid_task_count()
	var text: String = "TICKETS %d/%d" % [done, arrived]
	var left: float = GameManager.next_ticket_seconds_left()
	if left >= 0.0:
		text += " · %d:%02d restante" % [int(left) / 60, int(left) % 60]
	ticket_label.text = text


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
		# Hay que recorrer a todos, no quedarse con el primero: en el cristal
		# pueden coincidir Mamador, Ureña, Juan y Armando, y sus recortes ya
		# vienen colocados para no encimarse.
		for animatronic: Animatronic in _animatronics:
			if not animatronic.is_in_zone(zone_id):
				continue
			var slug: String = animatronic.image_slug()
			if not slug.is_empty() and office.has_layer(view, slug):
				by_view[view].append({
					"slug": slug,
					"lit_only": animatronic.needs_flashlight(zone_id),
				})
				continue
			# Sin recorte se queda su etiqueta; si hay varios, la del primero.
			if label.is_empty():
				label = animatronic.zone_presence(zone_id)
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
	# Si esa noche no tiene guion, el teléfono no suena.
	_nightly_call_left = NightCalls.CALL_DELAY if NightCalls.has_call(night) else -1.0
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
			phone_call.queue_message(NightCalls.for_night(GameManager.current_night), NightCalls.RING_TIME)
		return
	if _urena_calls_at.is_empty() or GameManager.night_progress() < _urena_calls_at[0]:
		return
	# Si justo está sonando otra cosa, esta llamada se espera al siguiente paso.
	if phone_call.is_ringing or phone_call.is_open:
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


func _on_ring_tick() -> void:
	notice_banner.show_notice(RING_NOTICE, NOTICE_SHORT)
	office.pulse_phone_ring()


func _on_call_answered() -> void:
	office.set_phone_ringing(false)
	office.set_phone_in_call(true)


## Si no contestas la de Ureña, te mata. La de la noche es opcional.
## No contestar ya no mata a nadie. Si era Ureña, se ofende, y eso lo cobra
## _on_urena_snubbed.
func _on_call_missed() -> void:
	office.set_phone_ringing(false)
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
# --- Apagón, susto y jumpscares -----------------------------------------------

## El cortaso: primero el susto del Mago y después la estática de siempre.
func _on_cortaso_started() -> void:
	jumpscare.play_scare()
	cortaso_overlay.play()


## Se acabó la energía: la noche sigue a oscuras y el Mago viene a cobrar.
func _on_power_depleted() -> void:
	if not GameManager.is_night_active:
		return
	camera_system.close()
	pc_screen.close()
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
	blackout_death.cancel()
	var jumpscare_id: String = BLACKOUT_JUMPSCARE if cause == BLACKOUT_CAUSE else ""
	for animatronic: Animatronic in _animatronics:
		if animatronic.game_over_cause() != cause:
			continue
		SaveGame.unlock_dossier(animatronic.image_slug())
		jumpscare_id = animatronic.jumpscare_id()
		break
	SaveGame.unlock_jumpscare(cause)
	# Mamador no salta: su pantalla es la de los militares.
	if cause == Mamador.GAME_OVER_CAUSE:
		jumpscare.play_mamador()
		return
	if jumpscare_id.is_empty():
		get_tree().change_scene_to_file(Screens.GAME_OVER)
		return
	jumpscare.play(jumpscare_id)


## Deja de gastar energía y congela a los profes antes de cambiar de pantalla.
func _end_night() -> void:
	set_process(false)
	camera_system.close()
	pc_screen.close()
	for animatronic: Animatronic in _animatronics:
		animatronic.stop()
