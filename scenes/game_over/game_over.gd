extends Control

## Pantalla de game over: muestra la causa guardada en el GameManager
## y permite volver a empezar la noche.

const NIGHT_SCENE: String = "res://scenes/night/night.tscn"

@onready var cause_label: Label = $CauseLabel
@onready var retry_button: Button = $RetryButton


func _ready() -> void:
	cause_label.text = GameManager.last_game_over_cause
	retry_button.pressed.connect(_on_retry_pressed)
	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file(NIGHT_SCENE)
