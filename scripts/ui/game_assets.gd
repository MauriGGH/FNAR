class_name GameAssets
extends RefCounted

## Busca imágenes por nombre, sin extensión, y acepta .png, .jpg y .jpeg, para
## que el arte se pueda entregar en el formato que convenga a cada pieza.
## Todo el juego pide sus imágenes por aquí.

const IMAGE_EXTENSIONS: Array[String] = [".png", ".jpg", ".jpeg"]


## Ruta real de una imagen, o cadena vacía si no está en ningún formato.
static func find_texture_path(base_path: String) -> String:
	for extension: String in IMAGE_EXTENSIONS:
		var path: String = base_path + extension
		if ResourceLoader.exists(path):
			return path
	return ""


static func has_texture(base_path: String) -> bool:
	return not find_texture_path(base_path).is_empty()


## Carga la imagen con la primera extensión que exista, o null.
static func load_texture(base_path: String) -> Texture2D:
	var path: String = find_texture_path(base_path)
	if path.is_empty():
		return null
	return load(path) as Texture2D
