class_name ScreenCapture
extends Node

## Recorre todas las pantallas del juego y guarda una captura de cada una en
## user://capturas/<nombre>.png. Lo arranca el botón "Capturar todas" del panel
## de pruebas (F1 → Pantallas).
##
## Se cuelga de la raíz del árbol, no de una escena, porque va cambiando de
## escena: si viviera dentro de una, el primer cambio se lo llevaría.
##
## Cada entrada dice cómo se llama el archivo, qué escena abrir, qué hay que
## dejar preparado antes (los datos que las pantallas leen de sus static) y qué
## hay que abrir después, ya con la escena montada.

## Avisa cuando acabó, con cuántas guardó.
signal finished(count: int)

const DIR: String = "user://capturas"
## Lo que se espera a que una pantalla se monte y se dibuje, antes de la foto.
const SETTLE_FRAMES: int = 4
## Lo que se espera de más en las que tienen animación de entrada.
const DEFAULT_WAIT: float = 0.35

var _saved: int = 0


## Lo mete en la raíz y arranca. La escena actual da igual: al acabar deja el
## menú principal.
static func run(tree: SceneTree) -> ScreenCapture:
	var tool: ScreenCapture = ScreenCapture.new()
	tool.name = "ScreenCapture"
	tree.root.add_child(tool)
	return tool


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()


## La carpeta de verdad, para decírsela al jugador por consola.
static func folder() -> String:
	return ProjectSettings.globalize_path(DIR)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	# Sin pausa y sin ratón capturado, o las pantallas no se montan bien.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("[capturas] empieza, van a %s" % folder())
	for entry: Dictionary in _entries():
		await _capture(entry)
	print("[capturas] %d pantallas guardadas en %s" % [_saved, folder()])
	finished.emit(_saved)
	get_tree().change_scene_to_file(Screens.MAIN_MENU)
	queue_free()


## Abre una pantalla, espera a que se vea y la guarda.
##
## Lo de despausar en cada pantalla no es un detalle: la pausa de la noche y el
## panel de pruebas dejan el árbol pausado, y **cambiar de escena no lo
## despausa**. Sin esto, todo lo que viene después de esas dos sale en blanco,
## porque los tweens de entrada (los fundidos del recibo y de los documentos)
## no corren con el árbol parado.
func _capture(entry: Dictionary) -> void:
	get_tree().paused = false
	var prepare: Variant = entry.get("prepare")
	if prepare is Callable:
		(prepare as Callable).call()
	get_tree().change_scene_to_file(str(entry["scene"]))
	for _i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	var scene: Node = get_tree().current_scene
	var setup: Variant = entry.get("setup")
	if setup is Callable and scene != null:
		(setup as Callable).call(scene)
	await get_tree().create_timer(float(entry.get("wait", DEFAULT_WAIT)),
		true, false, true).timeout
	# La foto se toma con el cuadro ya dibujado. Sin ventana (en las pruebas
	# headless) ese aviso no llega nunca, así que ahí no se espera.
	if not _is_headless():
		await RenderingServer.frame_post_draw
	_save(str(entry["name"]))


## true si el juego corre sin ventana, que es solo en las pruebas.
static func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


func _save(file_name: String) -> void:
	var texture: ViewportTexture = get_viewport().get_texture()
	var image: Image = texture.get_image() if texture != null else null
	if image == null:
		push_warning("[capturas] %s: no se pudo leer la pantalla" % file_name)
		return
	var path: String = "%s/%s.png" % [DIR, file_name]
	if image.save_png(path) != OK:
		push_warning("[capturas] no se pudo guardar %s" % path)
		return
	_saved += 1
	print("[capturas] %s" % path)


## Mete a esos profes en el tramo de pasillo que se ve desde la oficina, por
## el mismo camino que usarían jugando: se les mueve a ese paso de su ruta y el
## night.gd hace el resto. Así la captura comprueba la cadena entera, no solo
## que la capa de siluetas sepa dibujar.
func _send_to_hallway(scene: Node, slugs: Array, flashlight: bool) -> void:
	if not scene.has_method("animatronics"):
		return
	# Con la linterna se ven en penumbra; sin ella no se tiene que ver nada,
	# y esa es justo la captura que interesa comprobar.
	scene.office.debug_force_flashlight = flashlight
	for animatronic: Animatronic in scene.animatronics():
		if not animatronic.image_slug() in slugs:
			continue
		animatronic.debug_activate()
		var step: int = Array(animatronic.route).find(HALLWAY_ROOM)
		if step >= 0:
			animatronic.move_to_step(step)


## El cuarto del pasillo que se ve por el cristal.
const HALLWAY_ROOM: String = "pasillo_sur"


# --- La lista de pantallas ----------------------------------------------------

## Todas las pantallas del juego, en el orden en que las ve el jugador. Las
## capas que viven dentro de la noche (pausa, opciones, cámaras, PC, sala de
## servidores, panel de pruebas) se abren con su setup sobre la misma escena.
func _entries() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"name": "01_menu_principal", "scene": Screens.MAIN_MENU, "wait": 0.5},
		{"name": "02_menu_opciones", "scene": Screens.MAIN_MENU, "wait": 0.5,
			"setup": func(scene: Node) -> void: scene._options_panel.open()},
		{"name": "03_borrar_partida", "scene": Screens.MAIN_MENU, "wait": 0.4,
			"setup": func(scene: Node) -> void: scene._confirm.ask(
				"¿Borrar todo el progreso?", "Se pierden las noches y los extras.")},
		{"name": "04_solicitud_empleo", "scene": Screens.NAME_ENTRY, "wait": 0.4},
		{"name": "05_pantalla_de_carga", "scene": Screens.LOADING, "wait": 0.4,
			"prepare": func() -> void: LoadingScreen.next_scene = Screens.MAIN_MENU},
		{"name": "06_intro_de_noche", "scene": Screens.NIGHT_INTRO, "wait": 1.0,
			"prepare": func() -> void: GameManager.prepare_night(1)},
	]
	list.append_array(_night_entries())
	list.append_array(_end_of_night_entries())
	list.append_array(_extras_entries())
	return list


## La noche y todo lo que se abre encima de ella.
func _night_entries() -> Array[Dictionary]:
	return [
		{"name": "10_oficina", "scene": Screens.NIGHT, "wait": 1.0,
			"prepare": func() -> void: GameManager.prepare_night(1)},
		{"name": "11_oficina_pausa", "scene": Screens.NIGHT, "wait": 0.5,
			"setup": func(scene: Node) -> void: scene.pause_menu.open()},
		{"name": "12_oficina_opciones", "scene": Screens.NIGHT, "wait": 0.5,
			"setup": func(scene: Node) -> void:
				scene.pause_menu.open()
				scene.pause_menu._options.open()},
		{"name": "13_recuadro_controles", "scene": Screens.NIGHT, "wait": 0.5,
			"setup": func(scene: Node) -> void: scene.controls_card.open(false)},
		{"name": "14_camaras", "scene": Screens.NIGHT, "wait": 1.2,
			"setup": func(scene: Node) -> void: scene.camera_system.open()},
		{"name": "15_pc_escritorio", "scene": Screens.NIGHT, "wait": 1.2,
			"setup": func(scene: Node) -> void: scene.pc_screen.open()},
		{"name": "16_sala_de_servidores", "scene": Screens.NIGHT, "wait": 1.0,
			"setup": func(scene: Node) -> void: scene.server_room.open()},
		{"name": "17_panel_de_pruebas", "scene": Screens.NIGHT, "wait": 0.6,
			"setup": func(scene: Node) -> void: scene.mod_menu.open()},
		# Las dos de comprobar: que las siluetas se dibujan de verdad cuando
		# alguien entra al pasillo, y cómo se ve el giro a media vuelta.
		{"name": "18a_siluetas_sin_linterna", "scene": Screens.NIGHT, "wait": 1.2,
			"setup": func(scene: Node) -> void: _send_to_hallway(scene,
				["mamador", "urena"], false)},
		{"name": "18b_siluetas_con_linterna", "scene": Screens.NIGHT, "wait": 1.6,
			"setup": func(scene: Node) -> void: _send_to_hallway(scene,
				["mamador", "urena"], true)},
		{"name": "18c_giro_a_la_mitad", "scene": Screens.NIGHT, "wait": 1.0,
			"setup": func(scene: Node) -> void: scene.office.debug_hold_sweep(0.5)},
		{"name": "18_tablero_breaker", "scene": Screens.NIGHT, "wait": 1.0,
			"setup": func(scene: Node) -> void: scene.breaker_panel.open()},
		{"name": "19_jumpscare", "scene": Screens.NIGHT, "wait": 0.7,
			"setup": func(scene: Node) -> void: scene.jumpscare.play("barcosa")},
		{"name": "19b_pantalla_wasted", "scene": Screens.NIGHT, "wait": 2.0,
			"setup": func(scene: Node) -> void: scene.wasted_screen.play(
				JumpscareOverlay.mamador_image(), JumpscareOverlay.mamador_text(), true)},
	]


## El cierre de la noche: 6 AM, periódico, recibo, hojas, game over y final.
func _end_of_night_entries() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"name": "20_seis_am", "scene": Screens.WIN, "wait": 2.2,
			"prepare": func() -> void: GameManager.prepare_night(5)},
		{"name": "21_periodico", "scene": Screens.NEWSPAPER, "wait": 1.3,
			"prepare": func() -> void:
				NewspaperScreen.pending_index = 1
				NewspaperScreen.pending_documents = []
				NewspaperScreen.next_scene = Screens.MAIN_MENU},
		{"name": "22_recibo_de_pago", "scene": Screens.PAYMENT, "wait": 1.3,
			"prepare": func() -> void:
				PaymentScreen.setup(5, 3, 4, 225)
				PaymentScreen.pending_documents = []
				PaymentScreen.next_scene = Screens.MAIN_MENU},
	]
	for document_id: String in Documents.IDS:
		list.append({"name": "23_documento_%s" % document_id, "scene": Screens.DOCUMENT,
			"wait": 1.3,
			"prepare": func() -> void:
				DocumentScreen.queue = []
				DocumentScreen.pending_document = document_id
				DocumentScreen.next_scene = Screens.MAIN_MENU})
	list.append_array([
		{"name": "24_game_over", "scene": Screens.GAME_OVER, "wait": 2.4,
			"prepare": func() -> void:
				# La pantalla lee estas dos: la causa a máquina y de qué cámara
				# salió quien te atrapó.
				GameManager.last_game_over_cause = "Te atrapó Barcosa"
				GameManager.last_game_over_slug = "barcosa"},
		{"name": "25_final_del_juego", "scene": Screens.ENDING, "wait": 0.6},
	])
	return list


## Extras y Custom Night. Cada pestaña de Extras va aparte.
func _extras_entries() -> Array[Dictionary]:
	var sections: Array[Array] = [
		["30_extras_expedientes", 0], ["31_extras_periodicos", 1],
		["32_extras_documentos", 2], ["33_extras_jumpscares", 3],
	]
	var list: Array[Dictionary] = []
	for entry: Array in sections:
		var index: int = int(entry[1])
		list.append({"name": str(entry[0]), "scene": Screens.EXTRAS_MENU, "wait": 0.6,
			"setup": func(scene: Node) -> void: scene._show_section(index)})
	list.append({"name": "34_custom_night", "scene": Screens.CUSTOM_NIGHT, "wait": 0.6})
	return list
