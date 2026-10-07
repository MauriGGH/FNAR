class_name PatchRelabelTask
extends Control

## Tarea "Reetiquetar dos cables del patch panel". Dos cámaras aparecen sin
## señal y, de pasada, la hoja del rack trae sus dos renglones intercambiados:
## seguir la hoja da chispa, así que hay que probar el otro puerto.
##
## Es la única tarea que se hace en la sala de servidores, y mientras estás
## ahí la oficina se queda sin vigilar. Eso es parte del precio.

signal completed()

## El paso que tarda de esta tarea y lo que dice al acabar.
const WAIT_TEXT: String = "Esperando que las camaras vuelvan a dar senal"
const DONE_TEXT: String = "LISTO: los dos cables quedaron en su puerto."

const HINT: String = "La hoja miente en esos dos renglones: si un puerto da chispa, el cable va en el de la otra camara."

var task_id: String = ""
var is_completed: bool = false
var _wait: TaskWaitBar = null

@onready var instructions_label: Label = $InstructionsLabel
@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	var affected: PackedInt32Array = GameManager.patch_panel.cause_relabel()
	GameManager.patch_panel.camera_restored.connect(_on_camera_restored)
	instructions_label.text = "%s\n\nVe a la sala de servidores (vista derecha) y vuelve a conectar sus cables.\nOjo: la hoja del rack trae esos dos renglones intercambiados." % _cameras_text(affected)
	_refresh()


## Esta tarea no se hace en la PC, así que ni el asistente puede resolverla:
## hay que ir al rack. La pista solo avisa de la trampa de la hoja.
func hint() -> String:
	return HINT


func _cameras_text(affected: PackedInt32Array) -> String:
	if affected.is_empty():
		return "No hay camaras que reetiquetar ahora mismo."
	var names: PackedStringArray = PackedStringArray()
	for camera: int in affected:
		names.append("CAM %02d" % camera)
	return "Quedaron sin senal: " + ", ".join(names)


func _on_camera_restored(_camera: int) -> void:
	_refresh()


func _refresh() -> void:
	if is_completed:
		return
	var model: PatchPanelModel = GameManager.patch_panel
	var left: int = 0
	for camera: int in model.swapped_sheet:
		if model.is_camera_down(camera):
			left += 1
	if left > 0:
		status_label.text = "Faltan %d cable(s) por reconectar." % left
		return
	if model.swapped_sheet.is_empty():
		status_label.text = "Nada que reetiquetar."
		return
	_begin_wait()
	return

# --- El paso que tarda --------------------------------------------------------

## La barra se crea la primera vez que hace falta y se pone arriba del estado.
func _wait_bar() -> TaskWaitBar:
	if _wait == null:
		_wait = TaskWaitBar.new()
		_wait.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_wait.offset_top = -112.0
		_wait.offset_bottom = -68.0
		_wait.finished.connect(_on_wait_finished)
		add_child(_wait)
	return _wait


## Lo de "hacer" ya está: ahora hay que esperar, y la barra solo corre con la
## PC arriba.
func _begin_wait() -> void:
	if is_completed or _wait_bar().is_running or _wait_bar().is_done:
		return
	status_label.text = "%s..." % WAIT_TEXT
	_wait_bar().start(WAIT_TEXT)


func _on_wait_finished() -> void:
	is_completed = true
	status_label.text = DONE_TEXT
	completed.emit()
