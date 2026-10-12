class_name ScreenFx
extends RefCounted

## Las capas de "tele vieja" que varias pantallas comparten: la estática (los
## ocho cuadros de StaticFrames) y las líneas de escaneo. Se arman por código para no repetir los
## mismos nodos en cada escena, y porque el menú necesita subirle y bajarle la
## estática en marcha.

const SCANLINES_SHADER: String = "res://scenes/ui/scanlines.gdshader"

const STATIC_NODE: String = "ScreenStatic"
const SCANLINES_NODE: String = "Scanlines"


## Mete una capa de estática encima de lo que ya haya y la devuelve, para poder
## cambiarle la fuerza después.
static func add_static(parent: Control, strength: float) -> StaticFrames:
	if parent == null:
		return null
	var layer: StaticFrames = StaticFrames.new()
	layer.name = STATIC_NODE
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(layer)
	layer.set_strength(strength)
	return layer


## Las líneas de escaneo y el parpadeo. Van al final, encima de todo.
static func add_scanlines(parent: Control) -> ColorRect:
	return _add_layer(parent, SCANLINES_NODE, SCANLINES_SHADER, {})


## Cambia la fuerza de una capa de estática ya puesta.
static func set_static_strength(layer: StaticFrames, strength: float) -> void:
	if layer != null:
		layer.set_strength(strength)


static func _add_layer(parent: Control, node_name: String, shader_path: String,
		parameters: Dictionary) -> ColorRect:
	if parent == null or not ResourceLoader.exists(shader_path):
		return null
	var layer: ColorRect = ColorRect.new()
	layer.name = node_name
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load(shader_path)
	for key: String in parameters:
		material.set_shader_parameter(key, parameters[key])
	layer.material = material
	parent.add_child(layer)
	return layer
