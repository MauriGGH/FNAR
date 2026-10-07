class_name MenuBackdrop
extends RefCounted

## El fondo provisional de los menús: una imagen de cámara con estática
## encima, mientras no exista el arte propio. Se arma por código para no
## repetir los mismos nodos en cada pantalla.

## De dónde sale el fondo. Es una de las cámaras, así que ya existe.
const BACKGROUND_PATH: String = "res://assets/art/cameras/cam13_vacia"
const STATIC_SHADER: String = "res://scenes/camera_system/camera_static.gdshader"
## Lo oscuro que se pone encima, para que el texto se lea.
const DIM: Color = Color(0.0, 0.0, 0.02, 0.62)
const STATIC_STRENGTH: float = 0.12


## Mete el fondo como primeros hijos de una pantalla.
static func build(parent: Control) -> void:
	var texture: Texture2D = GameAssets.load_texture(BACKGROUND_PATH)
	if texture != null:
		var image: TextureRect = TextureRect.new()
		image.name = "Backdrop"
		image.texture = texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.set_anchors_preset(Control.PRESET_FULL_RECT)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(image)

	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dim)

	# La misma estática de las cámaras, muy suave.
	if ResourceLoader.exists(STATIC_SHADER):
		var noise: ColorRect = ColorRect.new()
		noise.name = "Static"
		noise.set_anchors_preset(Control.PRESET_FULL_RECT)
		noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load(STATIC_SHADER)
		material.set_shader_parameter("strength", STATIC_STRENGTH)
		noise.material = material
		parent.add_child(noise)
