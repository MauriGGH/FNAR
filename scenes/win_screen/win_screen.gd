extends Control

## Pantalla de 6 AM: sobreviviste la noche y te pagan por las tareas que
## terminaste. Por ahora solo reinicia la misma noche.

const NIGHT_SCENE: String = "res://scenes/night/night.tscn"

@onready var restart_button: Button = $RestartButton
@onready var tasks_label: Label = $TasksLabel
@onready var payment_label: Label = $PaymentLabel


func _ready() -> void:
	var done: int = GameManager.completed_task_count()
	var total: int = GameManager.night_tasks().size()
	tasks_label.text = "Tareas terminadas: %d de %d" % [done, total]
	payment_label.text = "Te pagan $%d" % GameManager.payment()
	restart_button.pressed.connect(_on_restart_pressed)
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file(NIGHT_SCENE)
