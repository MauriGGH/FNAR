extends Label

## Aviso provisional de ruido, por ejemplo "[pasos corriendo]". Vive en el HUD,
## así que se ve igual en la oficina, en las cámaras y en la PC.
## Cada aviso nuevo reemplaza al anterior y reinicia el tiempo.

const DEFAULT_TIME: float = 2.0

@onready var timer: Timer = $Timer


func _ready() -> void:
	visible = false
	timer.timeout.connect(_on_timeout)


func show_notice(text_to_show: String, duration: float = DEFAULT_TIME) -> void:
	text = text_to_show
	visible = true
	timer.start(maxf(duration, 0.1))


func _on_timeout() -> void:
	visible = false
