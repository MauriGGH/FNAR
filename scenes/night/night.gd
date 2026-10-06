extends Control

## Escena principal de una noche: junta la oficina, las cámaras, los profes y el
## HUD con los autoloads, y cambia a la pantalla de 6 AM o de game over.

const GAME_OVER_SCENE: String = "res://scenes/game_over/game_over.tscn"
const WIN_SCENE: String = "res://scenes/win_screen/win_screen.tscn"

@onready var office: Control = $Office
@onready var camera_system: Control = $CameraSystem
@onready var animatronics_holder: Node = $Animatronics
@onready var clock_label: Label = $Hud/ClockLabel
@onready var night_label: Label = $Hud/NightLabel
@onready var power_label: Label = $Hud/PowerLabel
@onready var usage_bars: Control = $Hud/UsageBars
@onready var camera_bar: Control = $Hud/CameraBar


func _ready() -> void:
	office.door_toggled.connect(PowerManager.set_door_closed)

	camera_system.set_animatronics(_collect_animatronics())
	camera_system.opened.connect(_on_cameras_opened)
	camera_system.closed.connect(_on_cameras_closed)
	camera_bar.hovered.connect(camera_system.toggle)

	GameManager.night_started.connect(_on_night_started)
	GameManager.hour_changed.connect(_on_hour_changed)
	GameManager.night_won.connect(_on_night_won)
	GameManager.game_over.connect(_on_game_over)
	PowerManager.power_changed.connect(_on_power_changed)

	GameManager.start_night()


## Los profes son hijos del nodo Animatronics, así se agregan sin tocar código.
func _collect_animatronics() -> Array[Animatronic]:
	var found: Array[Animatronic] = []
	for child: Node in animatronics_holder.get_children():
		if child is Animatronic:
			found.append(child as Animatronic)
	return found


func _on_night_started(night: int) -> void:
	night_label.text = "Noche %d" % night
	for animatronic: Animatronic in _collect_animatronics():
		animatronic.start()


func _on_hour_changed(_hour: int) -> void:
	clock_label.text = GameManager.hour_text()


func _on_power_changed(percent: float) -> void:
	power_label.text = "Energía: %d%%" % roundi(percent)
	usage_bars.set_level(PowerManager.usage_level())


func _on_cameras_opened() -> void:
	PowerManager.set_cameras_open(true)
	camera_bar.set_pointing_up(false)


func _on_cameras_closed() -> void:
	PowerManager.set_cameras_open(false)
	camera_bar.set_pointing_up(true)


func _on_night_won(_night: int) -> void:
	_end_night()
	get_tree().change_scene_to_file(WIN_SCENE)


func _on_game_over(_cause: String) -> void:
	_end_night()
	get_tree().change_scene_to_file(GAME_OVER_SCENE)


## Deja de gastar energía y congela a los profes antes de cambiar de pantalla.
func _end_night() -> void:
	camera_system.close()
	for animatronic: Animatronic in _collect_animatronics():
		animatronic.stop()
