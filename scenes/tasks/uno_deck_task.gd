class_name UnoDeckTask
extends Control

## Tarjeta de la tarea "Inventariar material decomisado". Aquí no se juega
## nada: la baraja está en el escritorio de la oficina y es ahí donde se
## acomoda. Esta ventana solo dice cómo va y cobra al terminar.
##
## **No tiene barra de espera**: lo que tarda es acomodar 24 cartas, no un
## servicio levantándose.

signal completed()

const INSTRUCTIONS: String = "Llegó la baraja que le decomisaron a un grupo de primero. Hay que inventariarla.\n\nEstá en tu escritorio, a la derecha del teclado: pícala y acomoda las 24 cartas en cuatro montones por color, del 0 al 5.\n\nOjo: mientras esté afuera, para Mamador es como tener abierta la ventana de Claudio."
const HINT: String = "Cada montón solo acepta el número que sigue. Y si oyes el llavero, guarda la baraja antes de que llegue al cristal."
const DONE_TEXT: String = "LISTO: 24 de 24, cuatro montones en orden."

var task_id: String = ""
var is_completed: bool = false

@onready var instructions_label: Label = $InstructionsLabel
@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	instructions_label.text = INSTRUCTIONS
	if not GameManager.uno_deck.changed.is_connected(_refresh):
		GameManager.uno_deck.changed.connect(_refresh)
	_refresh()


## Esta tarea no se hace en la PC, así que el asistente tampoco la resuelve.
func hint() -> String:
	return HINT


func _refresh() -> void:
	if is_completed:
		return
	var deck: UnoDeckModel = GameManager.uno_deck
	if deck.is_solved:
		is_completed = true
		status_label.text = DONE_TEXT
		completed.emit()
		return
	status_label.text = "%d de %d acomodadas.%s" % [deck.placed_count(), UnoDeck.TOTAL,
		"  (afuera)" if deck.is_out else "  (guardada)"]
