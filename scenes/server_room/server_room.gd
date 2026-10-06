extends Control

## La sala de servidores: el rack con el patch panel y la hoja de etiquetado.
## Mientras el guardia está aquí no vigila la oficina, así que las cámaras y la
## PC no se pueden usar. Se sale con el botón, con Escape o con S.
## El fondo está listo para usar assets/art/office/sala_servidores.png en
## cuanto exista; hasta entonces es el ambiente oscuro dibujado.

signal closed()
signal notice_requested(text: String, duration: float)

const BACKGROUND_PATH: String = "res://assets/art/office/sala_servidores.png"

var is_open: bool = false

@onready var background: TextureRect = $Background
@onready var patch_panel: Control = $PatchPanel
@onready var exit_button: Button = $ExitButton


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	exit_button.pressed.connect(close)
	patch_panel.notice_requested.connect(notice_requested.emit)
	_load_background()


## Si todavía no hay imagen de la sala, se queda el dibujo del patch panel.
func _load_background() -> void:
	if not ResourceLoader.exists(BACKGROUND_PATH):
		background.visible = false
		return
	background.texture = load(BACKGROUND_PATH) as Texture2D
	background.visible = background.texture != null


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	closed.emit()


## Escape y S salen. Va en _input porque este Control está en STOP y se
## quedaría con los botones del mouse antes de llegar a _unhandled_input.
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE or key.keycode == KEY_S:
		close()
		get_viewport().set_input_as_handled()
