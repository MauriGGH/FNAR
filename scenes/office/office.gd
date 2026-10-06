extends Control

## Oficina placeholder: fondo gris, el cristal al frente, la puerta de entrada
## al fondo y el botón de la PC. Avisa de lo que hace el jugador con señales;
## no toca la energía ni a los profes directamente.

signal door_toggled(is_closed: bool)
signal pc_requested()

const DOOR_OPEN_COLOR: Color = Color(0.12, 0.12, 0.15)
const DOOR_CLOSED_COLOR: Color = Color(0.72, 0.52, 0.14)

var is_door_closed: bool = false

@onready var door_rect: ColorRect = $DoorRect
@onready var door_state_label: Label = $DoorStateLabel
@onready var door_button: Button = $DoorButton
@onready var door_presence_label: Label = $DoorPresenceLabel
@onready var window_presence_label: Label = $WindowPresenceLabel
@onready var pc_button: Button = $PcButton


func _ready() -> void:
	door_button.pressed.connect(_on_door_button_pressed)
	pc_button.pressed.connect(pc_requested.emit)
	set_door_presence("")
	set_window_presence("")
	_refresh_door()


## Quién se ve en la puerta, mientras no haya imágenes. Vacío = nadie.
func set_door_presence(text: String) -> void:
	_set_presence(door_presence_label, text)


## Quién se ve asomado al cristal. Vacío = nadie.
func set_window_presence(text: String) -> void:
	_set_presence(window_presence_label, text)


func _set_presence(label: Label, text: String) -> void:
	label.text = text
	label.visible = not text.is_empty()


func _on_door_button_pressed() -> void:
	is_door_closed = not is_door_closed
	_refresh_door()
	door_toggled.emit(is_door_closed)


func _refresh_door() -> void:
	door_rect.color = DOOR_CLOSED_COLOR if is_door_closed else DOOR_OPEN_COLOR
	door_state_label.text = "PUERTA: CERRADA" if is_door_closed else "PUERTA: ABIERTA"
	door_button.text = "Abrir puerta" if is_door_closed else "Cerrar puerta"
