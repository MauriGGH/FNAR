extends Control

## Un recorte de otra imagen encimado sobre el video de la cámara, escalado al
## tamaño en pantalla. Lo usa la cortina de la puerta en la CAM 2: el mismo
## rectángulo normalizado sirve para sacarlo de la imagen y para ponerlo en su
## sitio, porque el video llena toda la pantalla.

var _texture: Texture2D = null
var _region: Rect2 = Rect2()


## Enseña un pedazo de una imagen. region va normalizada de 0 a 1.
func show_region(texture: Texture2D, region: Rect2) -> void:
	_texture = texture
	_region = region
	visible = texture != null and region.size.x > 0.0 and region.size.y > 0.0
	queue_redraw()


func hide_region() -> void:
	_texture = null
	visible = false
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	var image_size: Vector2 = _texture.get_size()
	draw_texture_rect_region(_texture,
		Rect2(_region.position * size, _region.size * size),
		Rect2(_region.position * image_size, _region.size * image_size))
