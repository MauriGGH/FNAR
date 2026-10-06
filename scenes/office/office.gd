extends Control

## Oficina placeholder: fondo gris y una puerta que se abre y se cierra.
## Avisa del estado de la puerta con una señal; no toca la energía directamente.

signal door_toggled(is_closed: bool)

const DOOR_OPEN_COLOR: Color = Color(0.12, 0.12, 0.15)
const DOOR_CLOSED_COLOR: Color = Color(0.72, 0.52, 0.14)

var is_door_closed: bool = false

@onready var door_rect: ColorRect = $DoorRect
@onready var door_state_label: Label = $DoorStateLabel
@onready var door_button: Button = $DoorButton


func _ready() -> void:
	door_button.pressed.connect(_on_door_button_pressed)
	_refresh_door()


func _on_door_button_pressed() -> void:
	is_door_closed = not is_door_closed
	_refresh_door()
	door_toggled.emit(is_door_closed)


func _refresh_door() -> void:
	door_rect.color = DOOR_CLOSED_COLOR if is_door_closed else DOOR_OPEN_COLOR
	door_state_label.text = "PUERTA: CERRADA" if is_door_closed else "PUERTA: ABIERTA"
	door_button.text = "Abrir puerta" if is_door_closed else "Cerrar puerta"
