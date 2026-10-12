extends Label

## La banda de avisos del HUD. Vive en el HUD, así que se ve igual en la
## oficina, en las cámaras y en la PC. Cada aviso nuevo reemplaza al anterior y
## reinicia el tiempo.
##
## Hay dos clases de aviso y no se tratan igual:
##   - **show_notice()**: lo que el jugador tiene que saber (un ticket nuevo,
##     que la linterna murió). Se ve siempre.
##   - **show_sound()**: el apaño de cuando un sonido todavía no está grabado,
##     tipo "[pasos corriendo]". **No se enseña nunca en pantalla**: con el
##     panel de pruebas encendido sale por consola y ya. El jugador tiene que
##     oír el ruido, no leerlo.

const DEFAULT_TIME: float = 2.0

@onready var timer: Timer = $Timer


func _ready() -> void:
	visible = false
	timer.timeout.connect(_on_timeout)


func show_notice(text_to_show: String, duration: float = DEFAULT_TIME) -> void:
	text = text_to_show
	visible = true
	timer.start(maxf(duration, 0.1))


## Un ruido que todavía no tiene audio. Nunca se dibuja.
func show_sound(text_to_show: String, _duration: float = DEFAULT_TIME) -> void:
	if DebugKeys.is_enabled():
		print("[ruido] %s" % text_to_show)


func _on_timeout() -> void:
	visible = false
