class_name LoadingScreen
extends Control

## La pantalla de carga entre el menú, las noches y los periódicos: negro con
## estática leve y una frase del lore al azar. Dura lo mismo siempre, porque las
## escenas cargan rápido y lo que se busca es el corte, no esperar de verdad.
##
## Nadie la instancia a mano: se entra con go_to(), que deja apuntado a dónde ir
## después porque change_scene_to_file no deja pasar datos.

## La escena que toca después de la carga.
static var next_scene: String = Screens.MAIN_MENU

const HOLD: float = 1.1
const FADE_OUT: float = 0.25
const STATIC_STRENGTH: float = 0.05
const LINE_SIZE: int = 22
const LINE_COLOR: Color = Color(0.74, 0.74, 0.7)
## La frase va en la parte baja, como los consejos de los juegos originales.
const LINE_TOP: float = 0.72


## El único camino de entrada: deja la escena apuntada y cambia a la carga.
static func go_to(tree: SceneTree, scene_path: String) -> void:
	next_scene = scene_path
	tree.change_scene_to_file(Screens.LOADING)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	ScreenFx.add_static(self, STATIC_STRENGTH)
	_build_line()

	var tween: Tween = create_tween()
	tween.tween_interval(HOLD)
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(_continue)


func _build_line() -> void:
	var label: Label = Label.new()
	label.text = LoadingLines.random_line()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Fonts.apply(label, Fonts.typewriter(), LINE_SIZE)
	label.add_theme_color_override("font_color", LINE_COLOR)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_left = 80.0
	label.offset_right = -80.0
	label.offset_top = size.y * LINE_TOP
	label.offset_bottom = label.offset_top + 90.0
	add_child(label)


func _continue() -> void:
	get_tree().change_scene_to_file(next_scene)
