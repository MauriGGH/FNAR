extends Control

## Pantalla de game over: muestra la causa guardada en el GameManager, y deja
## repetir la misma noche o volver al menú.

@onready var cause_label: Label = $CauseLabel
@onready var retry_button: Button = $RetryButton


func _ready() -> void:
	cause_label.text = GameManager.last_game_over_cause
	retry_button.pressed.connect(_on_retry_pressed)
	retry_button.grab_focus()
	_add_menu_button()


## El botón de volver al menú se crea aquí para no tocar la escena.
func _add_menu_button() -> void:
	var menu: Button = UiButton.make("Volver al menú")
	menu.custom_minimum_size = Vector2(300.0, 48.0)
	menu.size = Vector2(300.0, 48.0)
	menu.position = Vector2((size.x - 300.0) * 0.5, retry_button.position.y + 64.0)
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(Screens.MAIN_MENU))
	add_child(menu)


## Repetir la noche que se estaba jugando, con su misma configuración.
func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file(
		Screens.NIGHT_INTRO if not GameManager.is_custom_night else Screens.NIGHT)
