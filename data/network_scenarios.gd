class_name NetworkScenarios
extends RefCounted

## Escenarios del simulador de red. Cada uno dice qué equipos hay, cómo están
## (o no) cableados y qué configuración traen puesta. Las tareas solo nombran
## el escenario que necesitan.

const LAB_MASK: String = "255.255.255.0"
const LAB_GATEWAY: String = "192.168.30.1"
const LAB_SERVER_IP: String = "192.168.30.50"

## IPs que la tarea de configuración pide para cada PC.
const LAB_PC_IPS: Array[String] = [
	"192.168.30.11", "192.168.30.12", "192.168.30.13", "192.168.30.14",
]

const SCENARIO_UNCABLED: String = "lab_sin_cablear"
const SCENARIO_NO_IPS: String = "lab_sin_ips"
const SCENARIO_WITH_SERVER: String = "lab_con_servidor"
const SCENARIO_ROUTER_DOWN: String = "lab_router_apagado"
const SCENARIO_VLAN_MISMATCH: String = "salon_vlan_equivocada"
const SCENARIO_PRINTER_DHCP: String = "impresora_sin_reserva"

## La VLAN en la que tiene que quedar el salón, y la equivocada en la que
## arranca su puerto del switch.
const CLASSROOM_VLAN: int = 10
const WRONG_VLAN: int = 20
## El puerto del switch donde está enchufado el salón.
const CLASSROOM_PORT: int = 5
const CLASSROOM_LABEL: String = "SALON-E"

## La impresora y la IP que hay que reservarle en el router.
const PRINTER_LABEL: String = "IMPRESORA"
const PRINTER_IP: String = "192.168.30.60"
const PRINTER_POOL: String = "impresora"


## Arma el escenario dentro de un modelo ya vacío.
static func build(scenario: String, model: NetModel) -> void:
	match scenario:
		SCENARIO_UNCABLED:
			_build_lab(model, false, false, false, true)
		SCENARIO_NO_IPS:
			_build_lab(model, true, false, false, true)
		SCENARIO_WITH_SERVER:
			_build_lab(model, true, true, true, true)
		SCENARIO_ROUTER_DOWN:
			_build_lab(model, true, true, false, false)
		SCENARIO_VLAN_MISMATCH:
			_build_lab(model, true, true, true, true)
			_make_classroom(model)
		SCENARIO_PRINTER_DHCP:
			_build_lab(model, true, true, true, true)
			_make_printer(model)
		_:
			_build_lab(model, false, false, false, true)
	model.validate()


## El laboratorio: un router arriba, un switch al centro y cuatro PCs abajo.
## Las banderas dicen si ya viene cableado, con IPs, con servidor, y si la
## interfaz del router está levantada y con dirección.
static func _build_lab(model: NetModel, cabled: bool, configured: bool,
		with_server: bool, router_ready: bool) -> void:
	var router: NetDevice = NetDevice.new()
	router.id = "rt"
	router.kind = NetDevice.Kind.ROUTER
	router.label = "LAB-RT"
	router.position = Vector2(0.25, 0.17)
	router.port_count = 2
	router.top_ports = 0  # Sus puertos van abajo, hacia el switch.
	if router_ready:
		router.ip = LAB_GATEWAY
		router.mask = LAB_MASK
		router.interface_up = true
	else:
		router.interface_up = false
	model.add_device(router)

	var switch: NetDevice = NetDevice.new()
	switch.id = "sw"
	switch.kind = NetDevice.Kind.SWITCH
	switch.label = "LAB-SW"
	switch.position = Vector2(0.5, 0.5)
	switch.port_count = 6
	switch.top_ports = 2  # Arriba: router y servidor. Abajo: las PCs.
	model.add_device(switch)

	if with_server:
		var server: NetDevice = NetDevice.new()
		server.id = "srv"
		server.kind = NetDevice.Kind.SERVER
		server.label = "SRV-LAB"
		server.position = Vector2(0.76, 0.17)
		server.port_count = 1
		server.top_ports = 0
		server.ip = LAB_SERVER_IP
		server.mask = LAB_MASK
		server.gateway = LAB_GATEWAY
		model.add_device(server)

	for i: int in 4:
		var pc: NetDevice = NetDevice.new()
		pc.id = "pc%d" % (i + 1)
		pc.kind = NetDevice.Kind.PC
		pc.label = "LAB-0%d" % (i + 1)
		pc.position = Vector2(0.12 + i * 0.25, 0.8)
		pc.port_count = 1
		pc.top_ports = 1
		if configured:
			pc.ip = LAB_PC_IPS[i]
			pc.mask = LAB_MASK
			pc.gateway = LAB_GATEWAY
		model.add_device(pc)

	if not cabled:
		return
	model.connect_ports("rt", 0, "sw", 0, NetModel.CABLE_STRAIGHT)
	if with_server:
		model.connect_ports("srv", 0, "sw", 1, NetModel.CABLE_STRAIGHT)
	for i: int in 4:
		model.connect_ports("pc%d" % (i + 1), 0, "sw", i + 2, NetModel.CABLE_STRAIGHT)


## El salón E: la cuarta PC del laboratorio pasa a ser la del salón, y su
## puerto del switch arranca en la VLAN equivocada, así que queda aislada.
static func _make_classroom(model: NetModel) -> void:
	var classroom: NetDevice = model.device("pc4")
	if classroom == null:
		return
	classroom.label = CLASSROOM_LABEL
	classroom.vlan = CLASSROOM_VLAN
	var switch: NetDevice = model.device("sw")
	if switch != null:
		switch.port_vlans[CLASSROOM_PORT] = WRONG_VLAN
		# Los demás puertos quedan en la VLAN del salón, para que el problema
		# sea claramente ese puerto y no media red.
		for port: int in switch.port_count:
			if port != CLASSROOM_PORT:
				switch.port_vlans[port] = CLASSROOM_VLAN
	for device: NetDevice in model.device_list():
		if device.id != "pc4":
			device.vlan = CLASSROOM_VLAN


## La impresora: la cuarta PC pasa a ser la impresora, sin dirección, y el
## router arranca sin ninguna reserva de DHCP.
static func _make_printer(model: NetModel) -> void:
	var printer: NetDevice = model.device("pc4")
	if printer == null:
		return
	printer.label = PRINTER_LABEL
	printer.ip = ""
	printer.mask = ""
	printer.gateway = ""
	var router_device: NetDevice = model.router()
	if router_device != null:
		router_device.reservations.clear()


## Los enlaces que la tarea de cableado espera ver: equipo, puerto, equipo, puerto.
static func required_lab_links() -> Array[Dictionary]:
	var required: Array[Dictionary] = [{"a": "rt", "ap": 0, "b": "sw", "bp": 0}]
	for i: int in 4:
		required.append({"a": "pc%d" % (i + 1), "ap": 0, "b": "sw", "bp": i + 2})
	return required
