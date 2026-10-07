extends Control

## El panel de pruebas. Se abre con F1 y solo existe si NightConfig.DEBUG_KEYS
## está en true; en la versión para jugar no se crea ni un botón.
##
## Cada botón llama a una función del juego: aquí no hay lógica de juego
## duplicada, solo los ganchos debug_* que ya tienen GameManager, PowerManager
## y cada profe. Si una mecánica cambia, el panel sigue funcionando.
##
## Mientras está abierto el juego se pausa, salvo que se marque "seguir
## corriendo" para ver cosas en vivo (un profe moviéndose, la energía bajando).

const WIDTH: float = 430.0
const BACKDROP: Color = Color(0.05, 0.06, 0.08, 0.88)
const EDGE: Color = Color(0.5, 0.56, 0.6, 0.6)

const TITLE_SIZE: int = 22
const SECTION_SIZE: int = 19
const LABEL_SIZE: int = 15
const BUTTON_SIZE: int = 15
const TEXT: Color = Color(0.88, 0.91, 0.94)
const DIM: Color = Color(0.64, 0.68, 0.72)
const SECTION_COLOR: Color = Color(0.56, 0.86, 0.95)

## Las causas que se pueden forzar en el game over.
const CAUSES: Array[String] = [
	"Barcosa", "Delito federal", "Ureña", "Rochis", "Come Trabas",
	"Juan.exe", "Armando Prompts", "Mago Eléctrico",
]

var is_open: bool = false

var _night: Node = null
var _column: VBoxContainer = null
var _keep_running: CheckBox = null
var _camera_states: Label = null
var _sections: Dictionary = {}  # título -> VBoxContainer del cuerpo


func _ready() -> void:
	# Con el árbol pausado el panel tiene que seguir respondiendo.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


## La escena de la noche se presenta y el panel se arma con sus nodos. Así no
## depende de current_scene, que todavía no está puesto en _ready().
func bind(night: Node) -> void:
	if not DebugKeys.is_enabled():
		return
	_night = night
	_build()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open or not DebugKeys.is_enabled():
		return
	is_open = true
	visible = true
	_apply_pause()
	_refresh_camera_states()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false


func _apply_pause() -> void:
	get_tree().paused = is_open and not _keep_running.button_pressed


func _process(_delta: float) -> void:
	if is_open and _camera_states != null and _camera_states.visible:
		_refresh_camera_states()


# --- Armado del panel ---------------------------------------------------------

func _build() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	backdrop.offset_right = WIDTH
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	scroll.offset_left = 10.0
	scroll.offset_right = WIDTH - 10.0
	scroll.offset_top = 10.0
	scroll.offset_bottom = -10.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 4)
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_column)

	_add_header()
	_build_night_section()
	_build_animatronic_sections()
	_build_events_section()
	_build_screens_section()
	_build_view_section()


func _add_header() -> void:
	var title: Label = Label.new()
	title.text = "PANEL DE PRUEBAS  (%s)" % DebugKeys.toggle_label()
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	title.add_theme_color_override("font_color", TEXT)
	_column.add_child(title)

	_keep_running = CheckBox.new()
	_keep_running.text = "Seguir corriendo (no pausar)"
	_keep_running.focus_mode = Control.FOCUS_NONE
	_keep_running.add_theme_font_size_override("font_size", LABEL_SIZE)
	_keep_running.add_theme_color_override("font_color", DIM)
	_keep_running.toggled.connect(func(_on: bool) -> void: _apply_pause())
	_column.add_child(_keep_running)


## Una sección plegable: su título es un botón que enseña u oculta el cuerpo.
func _section(title: String) -> VBoxContainer:
	var header: Button = Button.new()
	header.text = "▼  " + title
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.focus_mode = Control.FOCUS_NONE
	header.add_theme_font_size_override("font_size", SECTION_SIZE)
	header.add_theme_color_override("font_color", SECTION_COLOR)
	_column.add_child(header)

	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	_column.add_child(body)
	_sections[title] = body
	header.pressed.connect(func() -> void:
		body.visible = not body.visible
		header.text = ("▼  " if body.visible else "►  ") + title)
	return body


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", BUTTON_SIZE)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


## Varios botones cortos en una fila, para no hacer la lista eterna.
func _add_row(parent: Control, entries: Array) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	parent.add_child(row)
	for entry: Array in entries:
		var button: Button = Button.new()
		button.text = str(entry[0])
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", BUTTON_SIZE)
		button.pressed.connect(entry[1] as Callable)
		row.add_child(button)


func _add_check(parent: Control, text: String, pressed: bool, action: Callable) -> CheckBox:
	var check: CheckBox = CheckBox.new()
	check.text = text
	check.button_pressed = pressed
	check.focus_mode = Control.FOCUS_NONE
	check.add_theme_font_size_override("font_size", LABEL_SIZE)
	check.toggled.connect(action)
	parent.add_child(check)
	return check


func _add_label(parent: Control, text: String, color: Color = DIM) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", LABEL_SIZE)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


# --- Noche --------------------------------------------------------------------

func _build_night_section() -> void:
	var body: VBoxContainer = _section("Noche")
	_add_label(body, "Saltar a la noche (reinicia la noche):")
	var nights: Array = []
	for n: int in range(1, NightConfig.LAST_NIGHT + 1):
		nights.append([str(n), func() -> void: _go_to_night(n)])
	_add_row(body, nights)

	_add_row(body, [
		["+1 hora", GameManager.debug_skip_hour],
		["5:59 AM", GameManager.debug_go_to_last_minute],
		["Ganar", GameManager.debug_win_night],
	])
	_add_label(body, "Energía:")
	_add_row(body, [
		["100 %", func() -> void: PowerManager.debug_set_power(100.0)],
		["5 %", func() -> void: PowerManager.debug_set_power(5.0)],
		["0 %", func() -> void: PowerManager.debug_set_power(0.0)],
	])
	_add_check(body, "Energía infinita", PowerManager.is_infinite,
		func(_on: bool) -> void: PowerManager.toggle_infinite())
	_add_check(body, "Horas cortas (modo prueba)", GameManager.force_short_hours,
		func(on: bool) -> void: GameManager.force_short_hours = on)


func _go_to_night(night: int) -> void:
	close()
	GameManager.prepare_night(night)
	get_tree().change_scene_to_file(Screens.NIGHT)


# --- Un apartado por profe ----------------------------------------------------

func _build_animatronic_sections() -> void:
	if _night == null or not _night.has_method("animatronics"):
		return
	for animatronic: Animatronic in _night.animatronics():
		_build_animatronic_section(animatronic)


func _build_animatronic_section(animatronic: Animatronic) -> void:
	var body: VBoxContainer = _section(animatronic.display_name)
	body.visible = false  # Plegado al abrir, para que quepa todo.

	_add_check(body, "Activo", animatronic.is_active,
		func(on: bool) -> void: animatronic.debug_set_active(on))

	var level_label: Label = _add_label(body, "Nivel de IA: %d" % animatronic.ai_level, TEXT)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0
	slider.max_value = Nights.MAX_AI_LEVEL
	slider.step = 1
	slider.value = animatronic.ai_level
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(value: float) -> void:
		animatronic.ai_level = int(value)
		level_label.text = "Nivel de IA: %d" % animatronic.ai_level)
	body.add_child(slider)

	# Mandarlo a cualquier cuarto de su ruta.
	if not animatronic.route.is_empty():
		var rooms: OptionButton = OptionButton.new()
		rooms.focus_mode = Control.FOCUS_NONE
		rooms.add_theme_font_size_override("font_size", BUTTON_SIZE)
		for i: int in animatronic.route.size():
			rooms.add_item("%d. %s" % [i, Rooms.display_name(animatronic.route[i])], i)
		rooms.select(0)
		body.add_child(rooms)
		_add_button(body, "Mandarlo a ese cuarto", func() -> void:
			animatronic.debug_activate()
			animatronic.move_to_step(rooms.get_selected_id()))

	_add_row(body, [
		["Acecho", animatronic.debug_force_stalk],
		["Atacar", animatronic.debug_force_attack],
	])
	_add_button(body, "Ver su jumpscare", func() -> void: _play_jumpscare(animatronic))


func _play_jumpscare(animatronic: Animatronic) -> void:
	close()
	# Si había otro puesto, se corta: así se pueden ver uno tras otro.
	_night.jumpscare.stop_now()
	if animatronic.game_over_cause() == Mamador.GAME_OVER_CAUSE:
		_night.jumpscare.play_mamador()
		return
	_night.jumpscare.play(animatronic.jumpscare_id())


# --- Eventos ------------------------------------------------------------------

func _build_events_section() -> void:
	var body: VBoxContainer = _section("Eventos")
	body.visible = false
	_add_label(body, "Llamada de Ureña, con esta insinuación:")
	var lines: OptionButton = OptionButton.new()
	lines.focus_mode = Control.FOCUS_NONE
	lines.add_theme_font_size_override("font_size", BUTTON_SIZE)
	lines.add_item("Al azar", -1)
	for i: int in UrenaQuestions.count():
		# El texto completo no cabe en el panel, así que va recortado.
		lines.add_item("%d. %s" % [i + 1, UrenaQuestions.line_text(i).substr(0, 34)], i)
	lines.select(0)
	body.add_child(lines)
	_add_button(body, "Llamar", func() -> void:
		close()
		_night.debug_urena_call(lines.get_selected_id()))
	_add_button(body, "Llamada de inicio de noche", func() -> void:
		close()
		_night.debug_night_call())
	_add_button(body, "Pantalla de Armando", func() -> void:
		close()
		var armando: ArmandoPrompts = _find(ArmandoPrompts) as ArmandoPrompts
		if armando != null:
			armando.force_takeover())
	_add_button(body, "Cortaso del Mago (susto)", func() -> void:
		close()
		var audel: Audel = _find(Audel) as Audel
		if audel != null:
			audel.debug_force_cortaso())
	_add_button(body, "Descarga del pararrayos", func() -> void:
		var audel: Audel = _find(Audel) as Audel
		if audel != null:
			audel.debug_activate()
			audel.cause_discharge())
	_add_button(body, "Apagón (energía a 0)", func() -> void:
		close()
		PowerManager.debug_set_power(0.0))

	_add_label(body, "Sucesos raros de las cámaras:")
	for camera: int in AmbientEvents.CAMERAS:
		var events: Array = AmbientEvents.EVENTS.get(camera, [])
		if events.is_empty():
			_add_button(body, "CAM %02d · parpadeo" % camera, func() -> void:
				_night.camera_system.debug_play_ambient(camera, -1))
			continue
		for index: int in events.size():
			var name: String = str(events[index].get("state", ""))
			_add_button(body, "CAM %02d · %s" % [camera, name], func() -> void:
				_night.camera_system.debug_play_ambient(camera, index))

	_add_label(body, "Tickets:")
	_add_row(body, [
		["Nuevo", func() -> void: GameManager.debug_arrive_next_ticket()],
		["Vencer uno", func() -> void: GameManager.debug_expire_next_ticket()],
	])


# --- Pantallas ----------------------------------------------------------------

func _build_screens_section() -> void:
	var body: VBoxContainer = _section("Pantallas")
	body.visible = false
	_add_button(body, "6 AM (pantalla de pago)", func() -> void:
		close()
		get_tree().change_scene_to_file(Screens.WIN))

	_add_label(body, "Game over con esta causa:")
	var causes: OptionButton = OptionButton.new()
	causes.focus_mode = Control.FOCUS_NONE
	causes.add_theme_font_size_override("font_size", BUTTON_SIZE)
	for i: int in CAUSES.size():
		causes.add_item(CAUSES[i], i)
	causes.select(0)
	body.add_child(causes)
	_add_button(body, "Provocar ese game over", func() -> void:
		close()
		GameManager.trigger_game_over(CAUSES[causes.get_selected_id()]))

	_add_label(body, "Periódicos:")
	var papers: Array = []
	for i: int in Newspapers.count():
		papers.append([str(i), func() -> void: _show_newspaper(i)])
		if papers.size() == 4:
			_add_row(body, papers)
			papers = []
	if not papers.is_empty():
		_add_row(body, papers)

	_add_button(body, "Intro de noche", func() -> void:
		close()
		get_tree().change_scene_to_file(Screens.NIGHT_INTRO))
	_add_button(body, "Pantalla final", func() -> void:
		close()
		get_tree().change_scene_to_file(Screens.ENDING))
	_add_button(body, "Extras con todo desbloqueado", _unlock_everything)


func _show_newspaper(index: int) -> void:
	close()
	SaveGame.unlock_newspaper(index)
	NewspaperScreen.pending_index = index
	NewspaperScreen.next_scene = Screens.MAIN_MENU
	get_tree().change_scene_to_file(Screens.NEWSPAPER)


## Abre todo lo que se desbloquea jugando, para poder revisar Extras.
func _unlock_everything() -> void:
	close()
	SaveGame.night_reached = NightConfig.LAST_NIGHT
	for i: int in Newspapers.count():
		SaveGame.unlock_newspaper(i)
	for character_id: String in Extras.DOSSIER_IDS:
		SaveGame.unlock_dossier(character_id)
	for cause: String in CAUSES:
		SaveGame.unlock_jumpscare(cause)
	get_tree().change_scene_to_file(Screens.EXTRAS_MENU)


# --- Vista --------------------------------------------------------------------

func _build_view_section() -> void:
	var body: VBoxContainer = _section("Vista")
	_add_check(body, "Ver zonas de clic", false,
		func(on: bool) -> void: _night.office.set_zones_visible(on))
	_add_check(body, "Ver etiquetas de estado", false,
		func(on: bool) -> void: _night.camera_system.set_debug_visible(on))
	var show_states: CheckBox = _add_check(body, "Ver el estado de cada cámara", false,
		func(on: bool) -> void:
			_camera_states.visible = on
			_refresh_camera_states())
	show_states.set_pressed_no_signal(false)
	_camera_states = _add_label(body, "", TEXT)
	_camera_states.visible = false


## La lista de las 13 cámaras con el estado que reporta cada una ahora mismo.
func _refresh_camera_states() -> void:
	if _camera_states == null or not _camera_states.visible or _night == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	for camera: int in range(1, Rooms.CAMERA_COUNT + 1):
		var state: String = _night.camera_system.camera_state_of(camera)
		lines.append("CAM %02d  %s" % [camera, state if not state.is_empty() else "-"])
	_camera_states.text = "\n".join(lines)


func _find(type: Variant) -> Animatronic:
	if _night == null or not _night.has_method("animatronics"):
		return null
	for animatronic: Animatronic in _night.animatronics():
		if is_instance_of(animatronic, type):
			return animatronic
	return null
