extends Control

## Escena principal de una noche: junta la oficina, las cámaras, los profes y el
## HUD con los autoloads, y cambia a la pantalla de 6 AM o de game over.

const GAME_OVER_SCENE: String = "res://scenes/game_over/game_over.tscn"
const WIN_SCENE: String = "res://scenes/win_screen/win_screen.tscn"

## Lo que muestra el HUD con la energía infinita de depuración puesta.
const INFINITE_POWER_TEXT: String = "ENERGÍA ∞ (debug)"

const BREAKER_NOTICE: String = "[clac]"
const BREAKER_NOTICE_TIME: float = 1.2

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
@onready var server_room: Control = $ServerRoom
@onready var fade_overlay: ColorRect = $Hud/FadeOverlay
@onready var flash_overlay: ColorRect = $Hud/FlashOverlay

var _animatronics: Array[Animatronic] = []
var _debug_shown: bool = false
var _come_trabas: ComeTrabas = null
var _audel: Audel = null


func _ready() -> void:
	_animatronics = _collect_animatronics()
	for animatronic: Animatronic in _animatronics:
		animatronic.made_noise.connect(notice_banner.show_notice)
		if animatronic is ComeTrabas:
			_come_trabas = animatronic as ComeTrabas
			# Al quedarse sin cuerda, la silla del cubículo 3 queda vacía.
			_come_trabas.music_stopped.connect(office.set_right_view_empty.bind(true))
		elif animatronic is Audel:
			_audel = animatronic as Audel
			_audel.cortaso_started.connect(cortaso_overlay.play)
			_audel.discharge_started.connect(_on_discharge)

	office.door_toggled.connect(_on_door_toggled)
	office.pc_requested.connect(pc_screen.open)
	office.notice_requested.connect(notice_banner.show_notice)
	office.breaker_requested.connect(breaker_panel.open)
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
	camera_bar.hovered.connect(_on_camera_bar_hovered)

	# La PC y las cámaras no pueden estar abiertas a la vez.
	pc_screen.opened.connect(camera_system.close)
	camera_system.opened.connect(pc_screen.close)
	# Al bajar la PC, la vista de la oficina regresa de su acercamiento.
	pc_screen.closed.connect(office.zoom_out)

	GameManager.night_started.connect(_on_night_started)
	GameManager.hour_changed.connect(_on_hour_changed)
	GameManager.night_won.connect(_on_night_won)
	GameManager.game_over.connect(_on_game_over)
	PowerManager.power_changed.connect(_on_power_changed)

	_apply_debug_shown()

	GameManager.start_night()


## F3 prende y apaga la depuración: la etiqueta de las cámaras y las zonas
## de clic de la oficina.
func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F3:
			_debug_shown = not _debug_shown
			_apply_debug_shown()
		KEY_F8:
			PowerManager.toggle_infinite()
		_:
			return
	get_viewport().set_input_as_handled()


## Un solo interruptor: la etiqueta de los profes y las zonas de clic.
func _apply_debug_shown() -> void:
	camera_system.set_debug_visible(_debug_shown)
	office.set_zones_visible(_debug_shown)


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
	for animatronic: Animatronic in _animatronics:
		animatronic.start()


## Mientras no haya imágenes, la oficina dice por texto quién se ve en cada
## zona: la puerta, el cristal y la escalera.
func _process(_delta: float) -> void:
	for zone_id: String in office.presence_zone_ids():
		var text: String = ""
		for animatronic: Animatronic in _animatronics:
			text = animatronic.zone_presence(zone_id)
			if not text.is_empty():
				break
		office.set_zone_presence(zone_id, text)
	# El aviso de la cuerda se ve esté donde esté el jugador, como en FNAF 2.
	warning_icon.set_level(0 if _come_trabas == null else _come_trabas.warning_level())


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


func _on_night_won(_night: int) -> void:
	_end_night()
	get_tree().change_scene_to_file(WIN_SCENE)


func _on_game_over(_cause: String) -> void:
	_end_night()
	get_tree().change_scene_to_file(GAME_OVER_SCENE)


## Deja de gastar energía y congela a los profes antes de cambiar de pantalla.
func _end_night() -> void:
	set_process(false)
	camera_system.close()
	pc_screen.close()
	for animatronic: Animatronic in _animatronics:
		animatronic.stop()
