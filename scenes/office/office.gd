extends Control

## Oficina placeholder: fondo gris y una puerta que se abre y se cierra.
## Avisa del estado de la puerta con una señal; no toca la energía directamente.

signal door_toggled(is_closed: bool)

const DOOR_OPEN_COLOR: Color = Color(0.12, 0.12, 0.15)
const DOOR_CLOSED_COLOR: Color = Color(0.72, 0.52, 0.14)

var is_door_closed: bool = false

const NOTICE_TIME: float = 2.0

@onready var door_rect: ColorRect = $DoorRect
@onready var door_state_label: Label = $DoorStateLabel
@onready var door_button: Button = $DoorButton
@onready var notice_label: Label = $NoticeLabel
@onready var notice_timer: Timer = $NoticeTimer


func _ready() -> void:
	door_button.pressed.connect(_on_door_button_pressed)
	notice_timer.timeout.connect(_on_notice_timeout)
	notice_label.visible = false
	_refresh_door()


## Aviso provisional de ruido, por ejemplo "[pasos corriendo]".
## Cada aviso nuevo reemplaza al anterior y reinicia el tiempo.
func show_notice(text: String, duration: float = NOTICE_TIME) -> void:
	notice_label.text = text
	notice_label.visible = true
	notice_timer.start(maxf(duration, 0.1))


func _on_notice_timeout() -> void:
	notice_label.visible = false


func _on_door_button_pressed() -> void:
	is_door_closed = not is_door_closed
	_refresh_door()
	door_toggled.emit(is_door_closed)


func _refresh_door() -> void:
	door_rect.color = DOOR_CLOSED_COLOR if is_door_closed else DOOR_OPEN_COLOR
	door_state_label.text = "PUERTA: CERRADA" if is_door_closed else "PUERTA: ABIERTA"
	door_button.text = "Abrir puerta" if is_door_closed else "Cerrar puerta"
