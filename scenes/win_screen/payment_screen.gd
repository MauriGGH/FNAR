class_name PaymentScreen
extends Control

## El recibo de pago de la noche: la hoja ya viene impresa en
## assets/art/screens/pago_noche.png y el código solo escribe encima lo de esa
## partida (el nombre, la noche, las tareas y el importe) más la nota a mano del
## coordinador. Las posiciones salen de data/pantallas_campos.json.
##
## Sale después del recorte de periódico. Igual que el periódico y los
## documentos, quien la abre deja apuntado a dónde se va después, porque
## change_scene_to_file no deja pasar datos.

const IMAGE: String = "res://assets/art/screens/pago_noche"

## Lo de esa noche, puesto antes de cambiar de escena. Se guarda aquí porque
## para cuando se ve el recibo ya se preparó la noche siguiente y el
## GameManager tiene otros números.
static var night: int = 1
static var tasks_done: int = 0
static var tasks_total: int = 0
static var amount: int = 0
## Las hojas que se entregan después del recibo, si esa noche lleva alguna.
static var pending_documents: Array[String] = []
static var next_scene: String = Screens.MAIN_MENU

## La nota a mano, según cómo le fue con las tareas.
const NOTE_ALL: String = "¡Buen trabajo!"
const NOTE_SOME: String = "Mañana te esperamos"
const NOTE_NONE: String = "¿Viniste a dormir?"

const HINT_TEXT: String = "clic para continuar"
const HINT_SIZE: int = 17
const HINT_COLOR: Color = Color(0.7, 0.72, 0.74, 0.85)
const FADE_IN: float = 0.5
## Lo que hay que esperar antes de poder pasar, para que no se salte sin leer.
const MIN_READ_TIME: float = 0.8

var _texture: Texture2D = null
var _can_continue: bool = false
var _labels: Array[Label] = []


## Guarda lo de la noche que se acabó, antes de preparar la siguiente.
static func setup(cleared_night: int, done: int, total: int, paid: int) -> void:
	night = cleared_night
	tasks_done = done
	tasks_total = total
	amount = paid


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_texture = GameAssets.load_texture(IMAGE)
	_build_sheet()
	_build_hint()
	_layout()
	resized.connect(_layout)
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN)
	tween.tween_interval(MIN_READ_TIME)
	tween.tween_callback(_allow_continue)


func _build_sheet() -> void:
	# La hoja, a pantalla completa. Si falta la imagen se ve el papel vacío,
	# pero los textos siguen en su sitio.
	var sheet: TextureRect = TextureRect.new()
	sheet.texture = _texture
	sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet.stretch_mode = TextureRect.STRETCH_SCALE
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)

	_add_field(ScreenFields.PAYMENT_NAME, SaveGame.player_name)
	_add_field(ScreenFields.PAYMENT_NIGHT, "Noche %d" % night)
	_add_field(ScreenFields.PAYMENT_TASKS, "%d de %d" % [tasks_done, tasks_total])
	_add_field(ScreenFields.PAYMENT_AMOUNT, "$%.2f" % float(amount))
	_add_field(ScreenFields.PAYMENT_NOTE, _note_text())


## Lo que escribió el coordinador al margen: depende de las tareas.
func _note_text() -> String:
	if tasks_done <= 0:
		return NOTE_NONE
	if tasks_total > 0 and tasks_done >= tasks_total:
		return NOTE_ALL
	return NOTE_SOME


## Un texto encima de la hoja, en el campo que le toca. La colocación de verdad
## la hace _layout, que es la que conoce el tamaño de la ventana.
func _add_field(field_id: String, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = ScreenFields.alignment(field_id)
	label.add_theme_color_override("font_color", ScreenFields.color(field_id))
	label.set_meta("field", field_id)
	add_child(label)
	_labels.append(label)


func _layout() -> void:
	for label: Label in _labels:
		var field_id: String = str(label.get_meta("field", ""))
		var font_size: int = ScreenFields.font_size(field_id, size.y)
		Fonts.apply(label, ScreenFields.font(field_id), font_size)
		var at: Vector2 = ScreenFields.position(field_id, size)
		var width: float = ScreenFields.width(field_id, size)
		if width <= 0.0:
			width = label.get_minimum_size().x
		# En los campos alineados a la derecha, la x medida es el borde derecho.
		if ScreenFields.alignment(field_id) == HORIZONTAL_ALIGNMENT_RIGHT:
			at.x -= width
		label.size = Vector2(width, float(font_size) * 1.6)
		label.position = at
		label.rotation = ScreenFields.rotation(field_id)


func _build_hint() -> void:
	var label: Label = Label.new()
	label.text = HINT_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Fonts.apply(label, Fonts.typewriter(), HINT_SIZE)
	label.add_theme_color_override("font_color", HINT_COLOR)
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -46.0
	label.offset_bottom = -18.0
	add_child(label)


func _allow_continue() -> void:
	_can_continue = true


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed:
		_continue()
		accept_event()


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo \
			and key.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		_continue()
		get_viewport().set_input_as_handled()


func _continue() -> void:
	if not _can_continue:
		return
	_can_continue = false
	if pending_documents.is_empty():
		get_tree().change_scene_to_file(next_scene)
		return
	var documents: Array[String] = pending_documents.duplicate()
	pending_documents = []
	DocumentScreen.show_documents(get_tree(), documents, next_scene)
