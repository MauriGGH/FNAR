class_name LabDiagnosticTask
extends Control

## Tarea "Diagnosticar el laboratorio". El panel lista los seis equipos y se va
## llenando conforme el jugador les hace ping desde la Terminal. Cuál no
## responde lo decide la consola al empezar la noche, así que cambia cada vez.
## Se termina reportando el equipo correcto con reportar <ip>.

signal completed()

const HINT: String = "Hazle ping a cada IP del laboratorio y reporta la que no responde con reportar <ip>."

const UNTESTED: String = "sin probar"
const RESPONDS: String = "responde"
const NO_ANSWER: String = "NO RESPONDE"

var task_id: String = ""
var is_completed: bool = false

var _hosts: PackedStringArray = PackedStringArray()
var _results: Dictionary = {}  # ip -> texto de estado
var _terminal: PcTerminal = null

@onready var host_list: VBoxContainer = $HostList
@onready var status_label: Label = $StatusLabel


func setup(data: Dictionary) -> void:
	task_id = str(data.get("id", ""))
	_hosts = PackedStringArray(data.get("hosts", CampusNetwork.LAB_HOSTS))
	_results.clear()
	for ip: String in _hosts:
		_results[ip] = UNTESTED
	_build_rows()


## La PC le pasa la consola para escuchar los pings y los reportes.
func bind_terminal(terminal: PcTerminal) -> void:
	_terminal = terminal
	_terminal.host_pinged.connect(_on_host_pinged)
	_terminal.host_reported.connect(_on_host_reported)


## Lo que el asistente teclea: prueba los seis y reporta el que falla.
func solve_commands() -> PackedStringArray:
	var commands: PackedStringArray = PackedStringArray()
	for ip: String in _hosts:
		commands.append("ping " + ip)
	if _terminal != null:
		commands.append("reportar " + _terminal.dead_lab_ip)
	return commands


func hint() -> String:
	return HINT


func _build_rows() -> void:
	for child: Node in host_list.get_children():
		host_list.remove_child(child)
		child.queue_free()
	for ip: String in _hosts:
		var label: Label = Label.new()
		label.name = ip
		label.add_theme_font_size_override("font_size", 19)
		host_list.add_child(label)
	_refresh_rows()


func _refresh_rows() -> void:
	var labels: Array[Node] = host_list.get_children()
	for i: int in mini(labels.size(), _hosts.size()):
		var ip: String = _hosts[i]
		var name: String = CampusNetwork.host_name(ip)
		(labels[i] as Label).text = "%-15s %-10s %s" % [ip, name, _results[ip]]


func _on_host_pinged(ip: String, responded: bool) -> void:
	if not _results.has(ip):
		return
	_results[ip] = RESPONDS if responded else NO_ANSWER
	_refresh_rows()


## Reportar el equipo equivocado no termina la tarea: solo avisa.
func _on_host_reported(ip: String) -> void:
	if is_completed or _terminal == null:
		return
	if not _results.has(ip):
		status_label.text = "%s no es del laboratorio." % ip
		_terminal.print_lines(PackedStringArray([
			"Mesa de ayuda: %s no pertenece al laboratorio." % ip, ""]))
		return
	if ip != _terminal.dead_lab_ip:
		status_label.text = "%s si responde, ese no es." % ip
		_terminal.print_lines(PackedStringArray([
			"Mesa de ayuda: %s responde bien, revisa de nuevo." % ip, ""]))
		return

	is_completed = true
	status_label.text = "LISTO: equipo reportado."
	_terminal.print_lines(PackedStringArray([
		"Mesa de ayuda: confirmado, %s esta caido. Gracias." % ip, ""]))
	completed.emit()
