extends Control

## Pantalla de 6 AM: sobreviviste la noche. Por ahora solo reinicia la misma noche.

const NIGHT_SCENE: String = "res://scenes/night/night.tscn"

@onready var restart_button: Button = $RestartButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file(NIGHT_SCENE)
