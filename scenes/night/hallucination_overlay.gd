extends Control

## La capa de las alucinaciones. Tira el dado cada pocos segundos y, cuando sale,
## enseña un solo cuadro durante una décima o dos con un golpe grave. No tiene
## consecuencias: ni quita energía, ni mata, ni hay nada que hacer.
##
## Los números y los cuadros están en data/hallucinations.gd.

## Salió una. Lo usa el menú de pruebas para enseñar cuál fue.
signal shown(kind: String)

var _roll_left: float = Hallucinations.ROLL_INTERVAL
var _gap_left: float = 0.0
var _visible_left: float = 0.0
var _kind: String = ""
var _dossier: Texture2D = null


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if _visible_left > 0.0:
		_visible_left -= delta
		if _visible_left <= 0.0:
			_hide()
		return
	if _gap_left > 0.0:
		_gap_left -= delta
	if not GameManager.is_night_active:
		return
	_roll_left -= delta
	if _roll_left > 0.0:
		return
	_roll_left = Hallucinations.ROLL_INTERVAL
	_roll()


## El dado de cada intervalo. No sale nada si todavía no toca por noche o si la
## anterior fue hace poco.
func _roll() -> void:
	if _gap_left > 0.0:
		return
	var chance: float = Hallucinations.chance_for_night(GameManager.current_night)
	if chance <= 0.0 or randf() > chance:
		return
	show_one()


## Enseña un cuadro. Sin id, elige uno de los que valgan ahora mismo.
func show_one(kind: String = "") -> void:
	var chosen: String = kind if not kind.is_empty() \
		else Hallucinations.pick(PowerManager.is_pc_open)
	if chosen.is_empty():
		return
	_kind = chosen
	if _kind == Hallucinations.DOSSIER:
		_dossier = _random_dossier()
	_visible_left = randf_range(Hallucinations.MIN_TIME, Hallucinations.MAX_TIME)
	_gap_left = Hallucinations.MIN_GAP
	visible = true
	AudioManager.play(Sounds.LOW_HIT)
	queue_redraw()
	shown.emit(_kind)


func _hide() -> void:
	_visible_left = 0.0
	_kind = ""
	visible = false


func _random_dossier() -> Texture2D:
	var ids: Array[String] = Extras.DOSSIER_IDS
	return Extras.dossier_texture(ids[randi() % ids.size()])


func _draw() -> void:
	match _kind:
		Hallucinations.PHOTO:
			_draw_photo()
		Hallucinations.IMPRESSIVE:
			_draw_impressive()
		Hallucinations.COSTUME:
			_draw_costume()
		Hallucinations.DOSSIER:
			_draw_dossier()


## La foto de la esposa de Rochis, recortada de la capa de la CAM 3 y agrandada
## hasta llenar la pantalla.
func _draw_photo() -> void:
	var texture: Texture2D = GameAssets.load_texture(Hallucinations.PHOTO_IMAGE)
	if texture == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0))
	var source: Rect2 = Rect2(
		Hallucinations.PHOTO_REGION.position * texture.get_size(),
		Hallucinations.PHOTO_REGION.size * texture.get_size())
	draw_texture_rect_region(texture, _cover_rect(source.size), source)


## El texto rojo encima del monitor. Solo se pide con la PC abierta.
func _draw_impressive() -> void:
	var font: Font = Fonts.terminal()
	if font == null:
		return
	var font_size: int = Hallucinations.IMPRESSIVE_SIZE
	var text: String = Hallucinations.IMPRESSIVE_TEXT
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at: Vector2 = Vector2((size.x - width) * 0.5, size.y * 0.5)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size,
		8, Color(0.0, 0.0, 0.0, 0.9))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size,
		Hallucinations.IMPRESSIVE_COLOR)


## La botarga, sentada en la silla: su jumpscare muy oscurecido.
func _draw_costume() -> void:
	var texture: Texture2D = GameAssets.load_texture(Hallucinations.COSTUME_IMAGE)
	if texture == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0))
	var shade: float = 1.0 - Hallucinations.COSTUME_DARKEN
	draw_texture_rect(texture, _cover_rect(texture.get_size()), false,
		Color(shade, shade, shade, 1.0))


## Un expediente con tu nombre donde iba el del profe.
func _draw_dossier() -> void:
	if _dossier == null:
		return
	draw_texture_rect(_dossier, Rect2(Vector2.ZERO, size), false)
	# El parche tapa el nombre impreso y encima va el del jugador.
	var patch: Rect2 = Rect2(
		Hallucinations.DOSSIER_NAME_PATCH.position * size,
		Hallucinations.DOSSIER_NAME_PATCH.size * size)
	draw_rect(patch, Hallucinations.DOSSIER_PAPER)
	var font: Font = Fonts.typewriter()
	if font == null:
		return
	var font_size: int = Hallucinations.dossier_name_size(size.y)
	var at: Vector2 = Hallucinations.DOSSIER_NAME_AT * size
	draw_string(font, at + Vector2(0.0, font.get_ascent(font_size)),
		GameManager.player_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size,
		Hallucinations.DOSSIER_INK)


## El rectángulo donde pintar algo de ese tamaño para que llene la pantalla sin
## deformarse, recortando lo que sobre.
func _cover_rect(source_size: Vector2) -> Rect2:
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return Rect2(Vector2.ZERO, size)
	var scale: float = maxf(size.x / source_size.x, size.y / source_size.y)
	var final_size: Vector2 = source_size * scale
	return Rect2((size - final_size) * 0.5, final_size)


# --- Depuración ---------------------------------------------------------------

## Para el menú de pruebas: salta la espera entre alucinaciones.
func debug_clear_gap() -> void:
	_gap_left = 0.0
