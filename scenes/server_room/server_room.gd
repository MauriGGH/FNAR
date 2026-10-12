extends Control

## La sala de servidores: el rack con el patch panel y la hoja de etiquetado.
## Mientras el guardia está aquí no vigila la oficina, así que las cámaras y la
## PC no se pueden usar. Se sale con un **clic fuera del rack**, con Escape o
## con S, y **esas tres salidas funcionan siempre**: este Control se queda la tecla antes que nadie.
## Si se pulsa la tecla del monitor, se sale primero y el monitor se abre ya en
## la oficina; así no queda un monitor abierto detrás de la sala, que era lo que
## dejaba el juego trabado.
## El fondo está listo para usar assets/art/office/sala_servidores.png en
## cuanto exista; hasta entonces es el ambiente oscuro dibujado.

signal closed()
signal notice_requested(text: String, duration: float)
## Pidió el monitor estando aquí. No se puede abrir desde la sala, así que
## primero se sale a la oficina y allá se abre.
signal cameras_requested()

## Sin extensión: vale png, jpg o jpeg.
const BACKGROUND_PATH: String = "res://assets/art/office/sala_servidores"

var is_open: bool = false

@onready var background: TextureRect = $Background
@onready var patch_panel: Control = $PatchPanel
var _exit_hint: ExitHint = null


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	patch_panel.notice_requested.connect(notice_requested.emit)
	_exit_hint = ExitHint.build(self)
	_load_background()


## Si todavía no hay imagen de la sala, se queda el dibujo del patch panel.
func _load_background() -> void:
	background.texture = GameAssets.load_texture(BACKGROUND_PATH)
	background.visible = background.texture != null


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	if _exit_hint != null:
		_exit_hint.show_once("server_room")


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	# Que no se quede nada a medias: un cable agarrado o un botón presionado
	# seguirían comiéndose el mouse al volver.
	if patch_panel.has_method("cancel_drag"):
		patch_panel.cancel_drag()
	closed.emit()


## Se sale con Escape, con S o **dando clic fuera del rack**. Ya no hay botón.
## Va en _input porque este Control está en STOP y se quedaría con los botones
## del mouse antes de llegar a _unhandled_input.
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT \
			and not patch_panel.active_rect().has_point(click.position):
		close()
		get_viewport().set_input_as_handled()
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == Controls.PAUSE_KEY or key.keycode == KEY_S:
		close()
		get_viewport().set_input_as_handled()
		return
	# La tecla del monitor: se sale y de eso se encarga la noche.
	if event.is_action_pressed("toggle_cameras"):
		cameras_requested.emit()
		close()
		get_viewport().set_input_as_handled()
