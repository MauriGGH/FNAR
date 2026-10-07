extends Control

## Pantalla de 6 AM: sobreviviste la noche y te pagan por las tareas que
## terminaste. De aquí se pasa al recorte de periódico de esa noche, y del
## recorte a la noche siguiente o al final del juego.

@onready var restart_button: Button = $RestartButton
@onready var tasks_label: Label = $TasksLabel
@onready var payment_label: Label = $PaymentLabel


func _ready() -> void:
	var done: int = GameManager.completed_task_count()
	var total: int = GameManager.night_tasks().size()
	tasks_label.text = "Tareas terminadas: %d de %d" % [done, total]
	payment_label.text = "Te pagan $%d" % GameManager.payment()
	restart_button.text = _button_text()
	restart_button.pressed.connect(_on_continue_pressed)
	restart_button.grab_focus()


func _button_text() -> String:
	if GameManager.is_custom_night:
		return "Volver a Extras"
	return "Continuar"


## La Custom Night no da recorte ni avanza la historia: vuelve a Extras.
func _on_continue_pressed() -> void:
	if GameManager.is_custom_night:
		get_tree().change_scene_to_file(Screens.EXTRAS_MENU)
		return
	var cleared: int = GameManager.current_night
	NewspaperScreen.pending_index = Newspapers.index_for_cleared_night(cleared)
	if cleared >= NightConfig.LAST_NIGHT:
		NewspaperScreen.next_scene = Screens.ENDING
	else:
		GameManager.prepare_night(cleared + 1)
		NewspaperScreen.next_scene = Screens.NIGHT_INTRO
	get_tree().change_scene_to_file(Screens.NEWSPAPER)
