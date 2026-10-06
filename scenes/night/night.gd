extends Control

## Escena principal de una noche: junta la oficina, las cámaras, los profes y el
## HUD con los autoloads, y cambia a la pantalla de 6 AM o de game over.

const GAME_OVER_SCENE: String = "res://scenes/game_over/game_over.tscn"
const WIN_SCENE: String = "res://scenes/win_screen/win_screen.tscn"

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

var _animatronics: Array[Animatronic] = []
var _debug_shown: bool = false


func _ready() -> void:
	_animatronics = _collect_animatronics()
	for animatronic: Animatronic in _animatronics:
		animatronic.made_noise.connect(notice_banner.show_notice)

	office.door_toggled.connect(_on_door_toggled)
	office.pc_requested.connect(pc_screen.open)
	office.notice_requested.connect(notice_banner.show_notice)

	camera_system.set_animatronics(_animatronics)
	camera_system.opened.connect(_on_cameras_opened)
	camera_system.closed.connect(_on_cameras_closed)
	camera_system.camera_changed.connect(_on_camera_changed)
	camera_bar.hovered.connect(camera_system.toggle)

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
	if key == null or not key.pressed or key.echo or key.keycode != KEY_F3:
		return
	_debug_shown = not _debug_shown
	_apply_debug_shown()
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
	for animatronic: Animatronic in _animatronics:
		animatronic.start()


## Mientras no haya imágenes, la oficina dice por texto quién está en la
## puerta y quién en el cristal.
func _process(_delta: float) -> void:
	var at_door: String = ""
	var at_window: String = ""
	for animatronic: Animatronic in _animatronics:
		if at_door.is_empty():
			at_door = animatronic.door_presence()
		if at_window.is_empty():
			at_window = animatronic.window_presence()
	office.set_door_presence(at_door)
	office.set_window_presence(at_window)


func _on_hour_changed(_hour: int) -> void:
	clock_label.text = GameManager.hour_text()


func _on_power_changed(percent: float) -> void:
	power_label.text = "Energía: %d%%" % roundi(percent)
	usage_bars.set_level(PowerManager.usage_level())


## La puerta la necesitan la energía y los profes que llegan a ella.
func _on_door_toggled(is_closed: bool) -> void:
	PowerManager.set_door_closed(is_closed)
	for animatronic: Animatronic in _animatronics:
		animatronic.set_door_closed(is_closed)


func _on_cameras_opened() -> void:
	PowerManager.set_cameras_open(true)
	camera_bar.set_pointing_up(false)
	_update_watched_camera()


func _on_cameras_closed() -> void:
	PowerManager.set_cameras_open(false)
	camera_bar.set_pointing_up(true)
	_update_watched_camera()


func _on_camera_changed(_camera: int) -> void:
	_update_watched_camera()


## Les dice a los profes qué cámara está mirando el jugador: a algunos,
## como Barcosa, vigilarlos los frena.
func _update_watched_camera() -> void:
	var camera: int = camera_system.current_camera if camera_system.is_open else Rooms.NO_CAMERA
	for animatronic: Animatronic in _animatronics:
		animatronic.set_watched_camera(camera)


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
