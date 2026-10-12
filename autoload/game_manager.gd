extends Node

## Autoload. Lleva el reloj de la noche y decide victoria o game over.
## Todo lo demás se entera por señales; nadie llama a nadie de forma rígida.

signal night_started(night: int)
signal hour_changed(hour: int)  # 0 = 12 AM ... 6 = 6 AM
signal night_won(night: int)
signal game_over(cause: String)
signal task_completed(task_id: String)
## Llegó un ticket nuevo (índice en night_tasks). Los tickets ya no vencen: se
## quedan en la lista hasta que el jugador los termina.
signal ticket_arrived(index: int)
signal ai_window_changed(is_open: bool)

## El nombre del guardia. Por ahora es una constante; la pantalla para
## escribirlo llega con el menú (hito 6), y entonces player_name cambiará.
const PLAYER_NAME: String = "Guardia"

var player_name: String = PLAYER_NAME
var current_night: int = 1
var current_hour: int = NightConfig.START_HOUR
var is_night_active: bool = false
## El reloj parado sin pausar el juego: lo usa el tutorial de la noche 1, que
## deja jugar pero no deja que se gaste la noche leyendo.
var is_clock_held: bool = false
var last_game_over_cause: String = ""
## El id del profe que te atrapó (image_slug()). Lo usa la pantalla de game over
## para enseñar la cámara de donde salió. Vacío si no fue nadie en concreto.
var last_game_over_slug: String = ""
## La ventana del Asistente IA sigue abierta aunque el jugador baje la PC:
## es justo lo que delata al guardia ante Mamador.
var is_ai_window_open: bool = false
## El tótem de Sergio: se gana en el minijuego de la maquinita y se gasta en un
## rescate. **Solo uno a la vez y solo por esta noche.**
var has_totem: bool = false
## true mientras corre el rescate: nadie más puede matar en ese rato.
var is_rescuing: bool = false
## Sergio entra una sola vez por noche, con tótem o con suerte.
var _sergio_used: bool = false

var _hour_elapsed: float = 0.0
# Quién tiene reservado el pasillo ahora mismo, o null si está libre.
var _hallway_holder: Node = null
# Ids de las tareas que el jugador ya terminó esta noche.
var _completed_tasks: Dictionary = {}
# Las tareas de la noche se sortean una sola vez, al empezar.
var _night_tasks: Array = []
## Estado de cada ticket, en el mismo orden que _night_tasks:
## {"at": hora en que llega, "arrived": bool}
var _tickets: Array[Dictionary] = []
## Subidas temporales de nivel de IA: clave del profe -> horas que le quedan.
var _ai_boosts: Dictionary = {}

## El patch panel de la sala de servidores: qué puerto le toca a cada cámara y
## cuáles tumbó una descarga de Audel. Es estado de la noche, como las tareas.
var patch_panel: PatchPanelModel = PatchPanelModel.new()
## Mientras el guardia está en la sala de servidores no vigila la oficina.
var is_in_server_room: bool = false

## Custom Night: cuando está activa, los niveles de IA salen de aquí en vez
## de la tabla de data/nights.gd. La clave es la del profe (Nights.BARCOSA...).
## El panel de pruebas puede forzar horas cortas en caliente, sin recompilar.
var force_short_hours: bool = false

var is_custom_night: bool = false
var custom_levels: Dictionary = {}
## El reto de Custom Night que se está jugando, si es que hay uno. Vacío cuando
## el jugador puso los niveles a mano.
var custom_challenge: String = ""
## Con cuánta energía arranca la noche. Solo el reto del apagón la cambia.
var start_power: float = NightConfig.MAX_POWER


func _ready() -> void:
	PowerManager.power_depleted.connect(_on_power_depleted)


## Arranca la noche desde las 12 AM con la energía llena.
## Deja lista la noche que se va a jugar, sin arrancarla: la pantalla de
## "12:00 AM / Noche N" va antes, y es night.tscn la que llama a start_night().
func prepare_night(night: int) -> void:
	current_night = clampi(night, 1, NightConfig.LAST_NIGHT)
	is_custom_night = false
	custom_levels.clear()
	custom_challenge = ""
	start_power = NightConfig.MAX_POWER


## Deja lista una Custom Night con los niveles que eligió el jugador.
func prepare_custom_night(levels: Dictionary, challenge_id: String = "") -> void:
	current_night = NightConfig.LAST_NIGHT
	is_custom_night = true
	custom_levels = levels.duplicate()
	custom_challenge = challenge_id
	start_power = CustomChallenges.start_power(challenge_id) if not challenge_id.is_empty() \
		else NightConfig.MAX_POWER


## Para el reloj o lo suelta, sin tocar el resto del juego. Lo usa el recuadro
## de controles de la noche 1: se puede mirar y moverse, pero no se gasta la
## noche leyendo.
func set_clock_held(held: bool) -> void:
	is_clock_held = held


## true si esta Custom Night lleva los ocho profes en 20. Es lo que vale la
## tercera estrella del menú.
func is_custom_night_maxed() -> bool:
	if not is_custom_night:
		return false
	for key: String in Nights.ALL_KEYS:
		if int(custom_levels.get(key, 0)) < Nights.MAX_AI_LEVEL:
			return false
	return true


## El nivel que le toca a un profe esta noche: el de la tabla, o el que eligió
## el jugador si es Custom Night.
func ai_level_for(key: String) -> int:
	if is_custom_night:
		return clampi(int(custom_levels.get(key, 0)), 0, Nights.MAX_AI_LEVEL)
	return Nights.ai_level(current_night, key)


func start_night(night: int = current_night) -> void:
	current_night = night
	current_hour = NightConfig.START_HOUR
	_hour_elapsed = 0.0
	is_clock_held = false
	last_game_over_cause = ""
	last_game_over_slug = ""
	_hallway_holder = null
	_completed_tasks.clear()
	_night_tasks = Tasks.pick_for_night(current_night)
	_build_tickets()
	_ai_boosts.clear()
	patch_panel.reset_for_night()
	is_in_server_room = false
	is_ai_window_open = false
	has_totem = false
	is_rescuing = false
	_sergio_used = false
	totem_changed.emit(false)
	is_night_active = true
	PowerManager.reset(start_power)
	PowerManager.set_draining(true)
	night_started.emit(current_night)
	hour_changed.emit(current_hour)


## Sergio rescató al guardia: la noche sigue. Lo escucha el night.gd para
## montar toda la escena (el susto congelado, el haz, el tótem).
signal sergio_rescued(cause: String)
## Cambió si el guardia trae el tótem encima. Lo escucha el HUD, que enseña su
## ícono en la esquina.
signal totem_changed(has_it: bool)

## Termina la noche con una causa de muerte, por ejemplo "Te quedaste sin energía".
## Antes de matar se le pregunta a Sergio: si él entra, aquí no pasa nada.
func trigger_game_over(cause: String) -> void:
	if not is_night_active:
		return
	if is_rescuing:
		return  # Ya hay un rescate corriendo: nadie más mata mientras tanto.
	if _try_sergio_rescue(cause):
		return
	is_night_active = false
	PowerManager.set_draining(false)
	last_game_over_cause = cause
	game_over.emit(cause)


# --- Tareas y pago ------------------------------------------------------------

## Tareas que pide la noche actual, sorteadas al empezar.
# --- Tickets ------------------------------------------------------------------

## Reparte los tickets de la noche: el primero casi al empezar y los demás
## hasta las 5 AM, cada uno con su plazo.
func _build_tickets() -> void:
	_tickets.clear()
	var times: PackedFloat32Array = Nights.ticket_times(current_night, _night_tasks.size())
	for i: int in _night_tasks.size():
		var at: float = times[i] if i < times.size() else Nights.LAST_TICKET_AT
		_tickets.append({"at": at, "arrived": false})


## true si ese ticket ya llegó. Las tareas que no han llegado no se pueden
## abrir todavía.
func is_ticket_arrived(index: int) -> bool:
	if index < 0 or index >= _tickets.size():
		return false
	return bool(_tickets[index]["arrived"])


## Cuántos tickets han llegado ya, para el contador de la oficina.
func arrived_ticket_count() -> int:
	var count: int = 0
	for ticket: Dictionary in _tickets:
		if bool(ticket["arrived"]):
			count += 1
	return count


## Los tickets que van llegando, según el reloj de la noche. No vencen: una vez
## que llega uno se queda en la lista hasta que el jugador lo termina.
func _process_tickets() -> void:
	var now: float = night_progress()
	for i: int in _tickets.size():
		var ticket: Dictionary = _tickets[i]
		if bool(ticket["arrived"]):
			continue
		if now >= float(ticket["at"]):
			ticket["arrived"] = true
			ticket_arrived.emit(i)


# --- Subidas temporales de nivel ----------------------------------------------

## Le sube el nivel a un profe por unas horas de juego. Lo usan el ticket
## vencido (Mamador) y el desaire a Ureña.
func add_ai_boost(key: String, amount: int, hours: float) -> void:
	if key.is_empty() or amount <= 0:
		return
	_ai_boosts[key] = {"amount": amount, "left": hours}


## Lo que tiene de más un profe ahora mismo.
func ai_boost(key: String) -> int:
	if not _ai_boosts.has(key):
		return 0
	return int(_ai_boosts[key]["amount"])


func _process_ai_boosts(delta: float) -> void:
	if _ai_boosts.is_empty():
		return
	var hours: float = delta / NightConfig.hour_duration()
	for key: String in _ai_boosts.keys():
		_ai_boosts[key]["left"] = float(_ai_boosts[key]["left"]) - hours
		if float(_ai_boosts[key]["left"]) <= 0.0:
			_ai_boosts.erase(key)


# --- Sergio y el tótem --------------------------------------------------------

## ¿Puede Sergio parar esta muerte? Con tótem siempre; sin él, solo en las
## noches altas y con suerte. Mamador no se interrumpe: su final no es un
## jumpscare, es la pantalla de WASTED.
func _try_sergio_rescue(cause: String) -> bool:
	if _sergio_used or cause == Mamador.GAME_OVER_CAUSE:
		return false
	var lucky: bool = current_night >= Sergio.RANDOM_FROM_NIGHT \
		and randi_range(1, 100) <= Sergio.RANDOM_CHANCE
	if not has_totem and not lucky:
		return false
	_sergio_used = true
	has_totem = false
	is_rescuing = true
	totem_changed.emit(false)
	sergio_rescued.emit(cause)
	return true


## Terminó la escena del rescate: se vuelve a poder morir.
func end_rescue() -> void:
	is_rescuing = false


## Ganó el minijuego: se queda con el tótem. Solo uno.
func give_totem() -> void:
	if has_totem:
		return
	has_totem = true
	totem_changed.emit(true)


func night_tasks() -> Array:
	return _night_tasks


func complete_task(task_id: String) -> void:
	if _completed_tasks.has(task_id):
		return
	_completed_tasks[task_id] = true
	task_completed.emit(task_id)


func is_task_completed(task_id: String) -> bool:
	return _completed_tasks.has(task_id)


func completed_task_count() -> int:
	return _completed_tasks.size()


## Lo que le pagan al guardia por las tareas que terminó.
## Cuántas tareas cuentan para el pago: terminadas y sin que se venciera su
## ticket. Una que se terminó después del plazo no se paga.
## Se paga por cada tarea terminada. Antes los tickets vencidos no contaban;
## ahora no vencen, así que cuenta todo lo que se haya completado.
func paid_task_count() -> int:
	var count: int = 0
	for i: int in _night_tasks.size():
		if is_task_completed(str(_night_tasks[i].get("id", ""))):
			count += 1
	return count


func payment() -> int:
	return paid_task_count() * Tasks.PAYMENT_PER_TASK


## La PC avisa aquí cuando se abre o se cierra la ventana del asistente.
func set_ai_window_open(is_open: bool) -> void:
	if is_ai_window_open == is_open:
		return
	is_ai_window_open = is_open
	ai_window_changed.emit(is_ai_window_open)


# --- Reserva del pasillo ------------------------------------------------------
# El pasillo es de uno a la vez: si Barcosa lo está usando, Mamador espera,
# y al revés. Quien lo reserva es el responsable de liberarlo al terminar.

## Intenta reservar el pasillo. Devuelve false si ya lo tiene otro profe.
func reserve_hallway(holder: Node) -> bool:
	if _hallway_holder != null and _hallway_holder != holder:
		return false
	_hallway_holder = holder
	return true


## Libera el pasillo, pero solo si de verdad lo tenía este profe.
func release_hallway(holder: Node) -> void:
	if _hallway_holder == holder:
		_hallway_holder = null


func is_hallway_free() -> bool:
	return _hallway_holder == null


func hallway_holder() -> Node:
	return _hallway_holder


## Qué tan avanzada va la noche, en horas con decimales: 2.5 son las 2:30 AM.
## Lo usa el teléfono para sonar entre las 2 y las 4.
func night_progress() -> float:
	return float(current_hour) + clampf(_hour_elapsed / NightConfig.hour_duration(), 0.0, 1.0)


## Texto del reloj para el HUD: la hora 0 se muestra como 12 AM.
func hour_text() -> String:
	var hour: int = 12 if current_hour == 0 else current_hour
	return "%d AM" % hour


# --- Ganchos del panel de pruebas ---------------------------------------------

## Adelanta el reloj una hora, sin saltarse los avisos de hora.
func debug_skip_hour() -> void:
	if current_hour >= NightConfig.END_HOUR:
		return
	_hour_elapsed = NightConfig.hour_duration()


## Deja el reloj justo antes de las 6 AM, para probar el final de la noche.
func debug_go_to_last_minute() -> void:
	current_hour = NightConfig.END_HOUR - 1
	_hour_elapsed = NightConfig.hour_duration() * 0.98
	hour_changed.emit(current_hour)


## Gana la noche ya, como si hubieran dado las 6.
func debug_win_night() -> void:
	if is_night_active:
		_win_night()


## Hace llegar el siguiente ticket que falte, sin esperar su hora.
func debug_arrive_next_ticket() -> bool:
	for i: int in _tickets.size():
		if bool(_tickets[i]["arrived"]):
			continue
		_tickets[i]["arrived"] = true
		ticket_arrived.emit(i)
		return true
	return false





func _process(delta: float) -> void:
	if is_night_active:
		_process_ai_boosts(delta)
		_process_tickets()
	if not is_night_active:
		return
	# El tutorial de la noche 1 para el reloj sin pausar el juego.
	if is_clock_held:
		return
	_hour_elapsed += delta
	var hour_duration: float = NightConfig.hour_duration()
	while _hour_elapsed >= hour_duration:
		_hour_elapsed -= hour_duration
		current_hour += 1
		hour_changed.emit(current_hour)
		if current_hour >= NightConfig.END_HOUR:
			_win_night()
			return


func _win_night() -> void:
	is_night_active = false
	PowerManager.set_draining(false)
	night_won.emit(current_night)


## Quedarse sin energía ya no mata de inmediato: la noche sigue corriendo a
## oscuras y el Mago Eléctrico viene a cobrar. Si dan las 6 AM antes, el
## jugador se salva, así que aquí no se termina nada.
func _on_power_depleted() -> void:
	pass
