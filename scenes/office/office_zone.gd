class_name OfficeZone
extends Control

## Zona de clic invisible sobre la imagen de la oficina. Su rectángulo viene
## normalizado (0 a 1) de data/oficina_zonas.json, así que se recoloca solo si
## cambia la resolución. Con F3 se dibuja para poder revisarla.

signal clicked(zone_id: String)

const DEBUG_LINE_COLOR: Color = Color(0.3, 0.95, 0.55, 0.9)
const DEBUG_FILL_COLOR: Color = Color(0.3, 0.95, 0.55, 0.12)
const DEBUG_CLICKABLE_COLOR: Color = Color(1.0, 0.75, 0.2, 0.95)
const HOVER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.1)

var zone_id: String = ""
var description: String = ""
var normalized_rect: Rect2 = Rect2()
var is_clickable: bool = false
var debug_shown: bool = false

var _hovered: bool = false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Prende o apaga el clic en caliente. La foto de Ureña solo se puede clicar
## después de que la deje, así que su zona empieza apagada.
func set_clickable(clickable: bool) -> void:
	is_clickable = clickable
	mouse_filter = Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_debug_shown(shown: bool) -> void:
	debug_shown = shown
	queue_redraw()


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	clicked.emit(zone_id)
	accept_event()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	# Un brillo apenas visible donde se puede hacer clic, para que se note.
	if _hovered and is_clickable:
		draw_rect(rect, HOVER_COLOR)
	if not debug_shown:
		return
	draw_rect(rect, DEBUG_FILL_COLOR)
	draw_rect(rect, DEBUG_CLICKABLE_COLOR if is_clickable else DEBUG_LINE_COLOR, false, 2.0)
