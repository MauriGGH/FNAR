extends Control

## Escena principal de una noche: junta la oficina con el HUD y los autoloads,
## y cambia a la pantalla de 6 AM o de game over cuando toca.

const GAME_OVER_SCENE: String = "res://scenes/game_over/game_over.tscn"
const WIN_SCENE: String = "res://scenes/win_screen/win_screen.tscn"

@onready var office: Control = $Office
@onready var clock_label: Label = $Hud/ClockLabel
@onready var power_label: Label = $Hud/PowerLabel


func _ready() -> void:
	office.door_toggled.connect(PowerManager.set_door_closed)
	GameManager.hour_changed.connect(_on_hour_changed)
	GameManager.night_won.connect(_on_night_won)
	GameManager.game_over.connect(_on_game_over)
	PowerManager.power_changed.connect(_on_power_changed)
	GameManager.start_night()


func _on_hour_changed(_hour: int) -> void:
	clock_label.text = GameManager.hour_text()


func _on_power_changed(percent: float) -> void:
	power_label.text = "ENERGÍA: %d %%" % roundi(percent)


func _on_night_won(_night: int) -> void:
	get_tree().change_scene_to_file(WIN_SCENE)


func _on_game_over(_cause: String) -> void:
	get_tree().change_scene_to_file(GAME_OVER_SCENE)
