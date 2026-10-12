extends Control

## Las 6 AM: el reloj con el rodillo y nada más. Cuando el rodillo acaba se
## pasa solo al recorte de periódico de esa noche, y del recorte al recibo de
## pago, que es donde se ve cuánto te pagaron.

@onready var six_am_roll: Control = $SixAmRoll


func _ready() -> void:
	# Los bucles de la pantalla anterior se cortan aquí: un ambiente colgado
	# es lo que se oye encima del nuevo.
	AudioManager.stop_all_loops()
	six_am_roll.finished.connect(_on_roll_finished)


## El rodillo acabó: sigue la noche como corresponda.
func _on_roll_finished() -> void:
	# Ganar una Custom Night, la que sea, te vale la carta de despido. No da
	# recorte ni recibo: vuelve a Extras.
	if GameManager.is_custom_night:
		DocumentScreen.show_documents(get_tree(), [Documents.DISMISSAL], Screens.EXTRAS_MENU)
		return

	var cleared: int = GameManager.current_night
	NewspaperScreen.pending_index = Newspapers.index_for_cleared_night(cleared)
	# El recibo de pago se queda con los números de la noche que se acabó,
	# porque preparar la siguiente los borra.
	PaymentScreen.setup(cleared, GameManager.completed_task_count(),
		GameManager.night_tasks().size(), GameManager.payment())

	# Las hojas que entrega esa noche salen después del recibo.
	var documents: Array[String] = []
	var receipt: String = Documents.for_cleared_night(cleared)
	if not receipt.is_empty():
		documents.append(receipt)

	var after: String = Screens.NIGHT_INTRO
	if cleared >= NightConfig.LAST_NIGHT:
		after = Screens.ENDING
	else:
		GameManager.prepare_night(cleared + 1)

	# 6 AM → recorte → recibo → las hojas de la noche → lo siguiente.
	NewspaperScreen.pending_documents = []
	NewspaperScreen.next_scene = Screens.PAYMENT
	PaymentScreen.pending_documents = documents
	PaymentScreen.next_scene = after
	LoadingScreen.go_to(get_tree(), Screens.NEWSPAPER)
