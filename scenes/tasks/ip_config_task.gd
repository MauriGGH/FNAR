class_name IpConfigTask
extends Control

## Tarea "Configurar IPs": cada equipo necesita una IP y no se puede repetir
## ninguna. En cuanto los cuatro tienen una IP distinta, la tarea se termina.

signal completed()

const UNASSIGNED_TEXT: String = "( sin asignar )"
const NAME_WIDTH: float = 210.0
const SELECTOR_WIDTH: float = 230.0

var task_id: String = ""
var is_completed: bool = false

var _computers: PackedStringArray = PackedStringArray()
var _ips: PackedStringArray = PackedStringArray()
var _selectors: Array[OptionButton] = []

@onready var rows: VBoxContainer = $Rows
@onready var status_label: Label = $StatusLabel


## Arma la tarea con los equipos y las IPs que trae data/tasks.gd.
func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	_computers = PackedStringArray(data.get("computers", []))
	_ips = PackedStringArray(data.get("ips", []))

	for child: Node in rows.get_children():
		child.queue_free()
	_selectors.clear()

	for i: int in _computers.size():
		var row: HBoxContainer = HBoxContainer.new()
		var name_label: Label = Label.new()
		name_label.text = _computers[i]
		name_label.custom_minimum_size = Vector2(NAME_WIDTH, 0.0)
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 18)
		var selector: OptionButton = OptionButton.new()
		selector.custom_minimum_size = Vector2(SELECTOR_WIDTH, 0.0)
		selector.focus_mode = Control.FOCUS_NONE
		selector.add_theme_font_size_override("font_size", 18)
		selector.add_item(UNASSIGNED_TEXT)
		for ip: String in _ips:
			selector.add_item(ip)
		selector.item_selected.connect(_on_item_selected)
		row.add_child(name_label)
		row.add_child(selector)
		rows.add_child(row)
		_selectors.append(selector)

	_refresh_status()


## Lo que hace el Asistente IA: reparte una IP a cada equipo, en orden.
func solve() -> void:
	for i: int in mini(_selectors.size(), _ips.size()):
		_selectors[i].select(i + 1)
	_refresh_status()


func _on_item_selected(_index: int) -> void:
	_refresh_status()


## Revisa el estado y, si está bien, da la tarea por terminada.
func _refresh_status() -> void:
	if is_completed:
		return

	var chosen: Array[int] = []
	var missing: int = 0
	for selector: OptionButton in _selectors:
		var selected: int = selector.get_selected()
		if selected <= 0:
			missing += 1
		else:
			chosen.append(selected)

	var repeated: String = _find_repeated(chosen)
	if not repeated.is_empty():
		status_label.text = "IP repetida: " + repeated
		return
	if missing > 0:
		status_label.text = "Faltan %d equipos por configurar" % missing
		return

	is_completed = true
	status_label.text = "LISTO: configuración correcta"
	for selector: OptionButton in _selectors:
		selector.disabled = true
	completed.emit()


## Devuelve la primera IP que aparece dos veces, o cadena vacía si no hay.
func _find_repeated(chosen: Array[int]) -> String:
	var seen: Dictionary = {}
	for value: int in chosen:
		if seen.has(value):
			return _ips[value - 1]
		seen[value] = true
	return ""
