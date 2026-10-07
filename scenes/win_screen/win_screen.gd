extends Control

## Pantalla de 6 AM: sobreviviste la noche y te pagan por las tareas que
## terminaste. De aquí se pasa al recorte de periódico de esa noche, y del
## recorte a la noche siguiente o al final del juego.

@onready var restart_button: Button = $RestartButton
@onready var tasks_label: Label = $TasksLabel
@onready var payment_label: Label = $PaymentLabel
@onready var six_am_roll: Control = $SixAmRoll

## Lo que se enseña solo cuando el rodillo de las 6 AM termina.
const CONTENT_NODES: Array[String] = [
	"TitleLabel", "SubtitleLabel", "TasksLabel", "PaymentLabel", "RestartButton",
]


func _ready() -> void:
	_set_content_visible(false)
	six_am_roll.finished.connect(_on_roll_finished)
	var done: int = GameManager.completed_task_count()
	var total: int = GameManager.night_tasks().size()
	tasks_label.text = "Tareas terminadas: %d de %d" % [done, total]
	payment_label.text = "Te pagan $%d" % GameManager.payment()
	restart_button.text = _button_text()
	restart_button.pressed.connect(_on_continue_pressed)


## El rodillo acabó: ya se puede ver cuánto te pagan.
func _on_roll_finished() -> void:
	_set_content_visible(true)
	restart_button.grab_focus()


func _set_content_visible(shown: bool) -> void:
	for node_name: String in CONTENT_NODES:
		var node: CanvasItem = get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.visible = shown


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
	# Después del recorte vienen las hojas que entregue esa noche: el recibo de
	# pago, y en la última también la carta de despido.
	var documents: Array[String] = []
	var receipt: String = Documents.for_cleared_night(cleared)
	if not receipt.is_empty():
		documents.append(receipt)
	var after: String = Screens.NIGHT_INTRO
	if cleared >= NightConfig.LAST_NIGHT:
		documents.append(Documents.DISMISSAL)
		after = Screens.ENDING
	else:
		GameManager.prepare_night(cleared + 1)
	NewspaperScreen.pending_documents = documents
	NewspaperScreen.next_scene = after
	LoadingScreen.go_to(get_tree(), Screens.NEWSPAPER)
