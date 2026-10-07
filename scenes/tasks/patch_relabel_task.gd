class_name PatchRelabelTask
extends Control

## Tarea "Reetiquetar dos cables del patch panel". Dos cámaras aparecen sin
## señal y, de pasada, la hoja del rack trae sus dos renglones intercambiados:
## seguir la hoja da chispa, así que hay que probar el otro puerto.
##
## Es la única tarea que se hace en la sala de servidores, y mientras estás
## ahí la oficina se queda sin vigilar. Eso es parte del precio.

signal completed()

const HINT: String = "La hoja miente en esos dos renglones: si un puerto da chispa, el cable va en el de la otra camara."

var task_id: String = ""
var is_completed: bool = false

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
	is_completed = true
	status_label.text = "LISTO: los dos cables quedaron en su puerto."
	completed.emit()
