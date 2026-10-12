class_name Sounds
extends RefCounted

## El catálogo de sonidos: un id por sonido, el archivo que espera en
## assets/audio/, el bus por el que sale y su volumen. Todo el juego pide sus
## sonidos por id a través del AudioManager; nadie carga un archivo a mano.
##
## Mientras el archivo de verdad no exista, el AudioManager usa el provisional
## de ToneBuilder y lo avisa una sola vez en consola. Para meter un sonido real
## basta con dejar el archivo con ese nombre en assets/audio/: no hay que tocar
## código.

const PATH: String = "res://assets/audio/%s"

# Los buses. Tienen que llamarse igual que en assets/audio/buses.tres.
const BUS_MASTER: String = "Master"
const BUS_AMBIENCE: String = "Ambiente"
const BUS_EFFECTS: String = "Efectos"
const BUS_VOICES: String = "Voces"
const BUS_MUSIC: String = "Música"
## Lo que se oye desde lejos, a través de las paredes: lleva reverb grande,
## un paso bajo a 2500 Hz y un paneo que se mueve según de dónde venga.
const BUS_DISTANT: String = "Lejos"

## Los buses que el jugador puede subir y bajar, en el orden del menú.
const MIXER_BUSES: Array[String] = ["Master", "Música", "Efectos", "Ambiente", "Voces"]

# --- Ids ---------------------------------------------------------------------
const MUSIC_BOX: String = "cajita_musical"
## La misma melodía, pero para el apagón: suena una sola vez y más fuerte, porque
## en la oscuridad es lo único que hay. Usa el mismo archivo que la de la botarga.
const MUSIC_BOX_BLACKOUT: String = "cajita_musical_apagon"
## La misma melodía, pero como aviso desde la oficina: muy bajita y con eco,
## por el bus Lejos, cuando a la botarga le queda poca cuerda.
const MUSIC_BOX_WARNING: String = "cajita_musical_aviso"
const TICKET: String = "ticket_nuevo"
const SCREAM: String = "grito"
## Los gritos de los jumpscares. Cada profe puede tener el suyo (`grito_<id>`);
## si no está grabado, se echa mano de uno de los tres de base. Los ids salen
## de scream_for().
const SCREAM_BASE: Array[String] = ["grito_base_1", "grito_base_2", "grito_base_3"]
const SCREAM_SLUGS: Array[String] = [
	"barcosa", "urena", "rochis", "juan", "armando", "cometrabas", "audel",
]
const BUSY_TONE: String = "tono_ocupado"
const ALARM: String = "despertador"
const SCHOOL_BELL: String = "campana_escuela"
## Los niños gritando "¡yeeey!" al acabarse las campanadas de las 6 AM.
const CHILDREN_CHEER: String = "ninos_yay"
## La música del menú principal: una pista larga en bucle y, encima, dos capas
## de ambiente más bajas. Las tres suenan a la vez.
const MENU_MUSIC: String = "menu_musica"
const MENU_LAYERS: Array[String] = ["menu_capa", "menu_capa2"]
## Y la de Extras y la Custom Night, también en bucle.
const EXTRAS_MUSIC: String = "extras_musica"
const FOOTSTEPS: String = "pasos_acercandose"
## El golpe de una alucinación. Hay tres tomas y se alternan sin repetir la
## última; LOW_HIT es la de respaldo, la única con provisional por código.
const LOW_HIT: String = "golpe_grave"
const LOW_HITS: Array[String] = ["golpe_grave_1", "golpe_grave_2", "golpe_grave_3"]
## Los ocho golpes del tic del menú. En cada tic suena uno al azar, y no se
## repite ninguno de los dos últimos: así no se le agarra el ritmo.
const MENU_TICS: Array[String] = [
	"tic_boom_1", "tic_boom_2", "tic_boom_3", "tic_golpe_metal", "tic_vidrio",
	"tic_rechinido", "tic_raspon", "tic_golpe_eco", "tic_whoosh_golpe",
	"tic_piano", "tic_estatica",
]
## Los tres booms, que son los gordos: uno de ellos acompaña al glitch largo
## en el tic "ultra", el de los tres profes.
const MENU_TIC_BOOMS: Array[String] = ["tic_boom_1", "tic_boom_2", "tic_boom_3"]
## Y la estática que va de fondo en ese tic.
const UNEASY_STATIC: String = "estatica_inquietante"
## La misma, más bajita, debajo de la estática de la pantalla de game over.
const UNEASY_STATIC_GAME_OVER: String = "estatica_inquietante_gameover"
## Cuando uno de los del cristal se va con el cuarto destello.
const GLASS_REPEL: String = "se_aleja"
## Ambiente, en bucle toda la noche.
const OFFICE_AMBIENCE: String = "ambiente_oficina"
const HALLWAY_AMBIENCE: String = "ambiente_pasillo"
## El timbre del teléfono, en bucle mientras suena.
const PHONE_RING: String = "telefono_timbre"
const DOOR_SHUTTER: String = "puerta_cortina"
const DOOR_BANGS: String = "golpes_cortina"
## Los tres golpes de metal de Barcosa contra la cortina: se alterna entre
## ellos sin repetir el mismo dos veces seguidas.
const METAL_HITS: Array[String] = [
	"golpe_metal_1", "golpe_metal_2", "golpe_metal_3",
]
const CAMERA_BLIP: String = "camara_cambio"
const FLASHLIGHT_CLICK: String = "linterna_click"
const BREAKER_LEVER: String = "breaker_palanca"
## El siseo de fondo mientras el monitor está abierto.
const CAMERA_STATIC: String = "estatica_camara"
## El blip de moverse por un menú y el de aceptar (el mismo, más agudo).
const MENU_BLIP: String = "menu_blip"
## El golpe de una tecla de máquina de escribir, al escribir el nombre. Este es
## el de respaldo: siempre suena, aunque sea el provisional por código.
const TYPEWRITER_KEY: String = "tecla_maquina"
## Las tres grabaciones de la tecla. Si están en assets/audio/, se alterna entre
## ellas sin repetir la misma dos veces seguidas; si no, suena el de respaldo.
## Por eso no llevan provisional: quien las usa pregunta antes si están.
const TYPEWRITER_KEYS: Array[String] = [
	"tecla_maquina_1", "tecla_maquina_2", "tecla_maquina_3",
]
## El clac de colgar, al acabar o silenciar una llamada.
const PHONE_HANG_UP: String = "telefono_colgar"
## El golpe de la pantalla de WASTED.
const WASTED: String = "wasted"
## La puerta derribada y los gritos del operativo, antes del WASTED de Mamador.
const MAMADOR_BREACH: String = "mamador_brecha"
## Armando tomando la pantalla de la PC: el crash al aparecer y el zumbido
## que se queda en bucle mientras dura.
const ARMANDO_CRASH: String = "armando_windows_crash"
const ARMANDO_GLITCH: String = "armando_glitch_bucle"
## La frase que suelta el Mago justo al quedarse la oficina sin energía.
const BLACKOUT_LINE: String = "apagon_frase"
## El glitch largo del tic "ultra" del menú, el de los tres profes.
const MENU_GLITCH_LONG: String = "menu_glitch_largo"
## El vistazo "de reojo" de las cámaras.
const DISTURBING: String = "sonido_perturbador"
## La llamada del Mencho: número equivocado, una vez por noche.
const MENCHO_CALL: String = "llamada_mencho"

## El rescate de Sergio, que todavía no está hecho: los ids quedan registrados
## para que el día que se programe solo haya que pedirlos.
## - ROSE_SUSPENSE: al congelarse el susto.
## - ROSE_AIR: con el destello blanco y el tótem.
## - AURA: al terminar, y también al ganar el tótem en el minijuego.
const ROSE_SUSPENSE: String = "rosa_suspenso"
const ROSE_AIR: String = "rosa_aire"
const AURA: String = "aura"

# --- Lo que se oye de lejos --------------------------------------------------
const FAR_BARCOSA_RUN: String = "barcosa_corre"
const FAR_MAMADOR_STEPS: String = "mamador_pasos"
## El llavero de Mamador, que suena con sus pasos cada vez que se mueve.
const FAR_KEYS: String = "llavero"
const FAR_URENA_BATHROOM: String = "urena_banos"
const FAR_JUAN_KEYBOARD: String = "juan_teclado"
const FAR_ARMANDO_MODEM: String = "armando_modem"
const FAR_AUDEL_SPARK: String = "audel_chispa"
const FAR_ROCHIS_CHAIR: String = "rochis_silla"
## Los ambientales que salen solos cada tanto.
const FAR_DOOR_SLAM: String = "lejos_portazo"
const FAR_CHAIR_DRAG: String = "lejos_silla"
const FAR_UPSTAIRS: String = "lejos_pasos_arriba"
const FAR_LAUGH: String = "lejos_risa"
const FAR_DISHES: String = "lejos_platos"
const FAR_PASSAGE: String = "lejos_pasos_pasillo"
const FAR_AMBIENT: Array[String] = [
	"lejos_portazo", "lejos_silla", "lejos_pasos_arriba", "lejos_risa",
	"lejos_platos", "lejos_pasos_pasillo",
]

## De qué lado viene cada sonido, de -1 (izquierda) a 1 (derecha). Izquierda
## son los cubículos y la escalera; el centro, el pasillo; la derecha, la sala
## de servidores. Lo pone el AudioManager en el paneo del bus Lejos.
const PAN_LEFT: float = -0.7
const PAN_CENTER: float = 0.0
const PAN_RIGHT: float = 0.7
## La voz de Rochis. No tiene provisional por código: mientras no esté grabada,
## el botón de la CAM 3 la dice con la síntesis de voz.
const IMPRESSIVE: String = "es_impresionante"

## Las llamadas grabadas con las que empieza cada noche. Tampoco llevan
## provisional: si no está el archivo, esa noche no hay llamada y ya.
const NIGHT_CALL: String = "llamada_noche%d"


## Uno de los tres booms, para el tic "ultra".
static func menu_boom() -> String:
	var pool: Array[String] = []
	for id: String in MENU_TIC_BOOMS:
		if AudioManager.has_real_file(id):
			pool.append(id)
	return pool[randi() % pool.size()] if not pool.is_empty() else ""


## El golpe de una alucinación: una de las tres tomas, nunca la misma dos veces
## seguidas. Sin ninguna grabada, el de siempre, que lleva provisional.
static func low_hit(last: String = "") -> String:
	var pool: Array[String] = []
	for id: String in LOW_HITS:
		if id != last and AudioManager.has_real_file(id):
			pool.append(id)
	if pool.is_empty():
		for id: String in LOW_HITS:
			if AudioManager.has_real_file(id):
				pool.append(id)
	return pool[randi() % pool.size()] if not pool.is_empty() else LOW_HIT


## El golpe que le toca a este tic del menú: uno de los ocho al azar, saltándose
## los dos últimos que sonaron, para que no se le agarre el ritmo. Si no hay
## ninguno grabado devuelve vacío, y entonces el tic va mudo.
static func menu_tic(recent: Array[String]) -> String:
	var pool: Array[String] = []
	for id: String in MENU_TICS:
		if not id in recent and AudioManager.has_real_file(id):
			pool.append(id)
	if pool.is_empty():
		# Con dos o tres grabados hay que permitir repetir algo.
		for id: String in MENU_TICS:
			if AudioManager.has_real_file(id):
				pool.append(id)
	return pool[randi() % pool.size()] if not pool.is_empty() else ""


## El golpe de metal que le toca a este porrazo: uno de los tres al azar, pero
## nunca el mismo dos veces seguidas. `last` es el que acaba de sonar; si no
## hay ninguno grabado, devuelve el golpe de siempre, que sí tiene provisional.
static func metal_hit(last: String = "") -> String:
	var pool: Array[String] = []
	for id: String in METAL_HITS:
		if id != last and AudioManager.has_real_file(id):
			pool.append(id)
	if pool.is_empty():
		# Con una sola grabación se repite, y sin ninguna va el de siempre.
		for id: String in METAL_HITS:
			if AudioManager.has_real_file(id):
				pool.append(id)
	if pool.is_empty():
		return DOOR_BANGS
	return pool[randi() % pool.size()]


## El grito que le toca a un jumpscare: el suyo si está grabado, uno de los
## tres de base al azar si no, y el grito de siempre como último recurso.
## **Nunca devuelve vacío**: un salto sin grito no asusta, y con la estática
## sola no se entiende lo que pasó.
static func scream_for(slug: String) -> String:
	var own: String = "grito_%s" % slug
	if AudioManager.has_real_file(own):
		return own
	var pool: Array[String] = []
	for id: String in SCREAM_BASE:
		if AudioManager.has_real_file(id):
			pool.append(id)
	if not pool.is_empty():
		return pool[randi() % pool.size()]
	return SCREAM


## El id de una línea suelta de profe es el mismo que el de data/voice_lines.gd.
static func voice_line(line_id: String) -> String:
	return line_id


## El id de la llamada de una noche.
static func night_call(night: int) -> String:
	return NIGHT_CALL % night

## El catálogo. Por sonido: "file" (nombre dentro de assets/audio/, sin ruta),
## "bus", "volume_db" y "generator" (el nombre de la función de ToneBuilder que
## lo arma si el archivo falta; vacío si no hay provisional).
const CATALOG: Dictionary = {
	"cajita_musical": {
		"file": "cajita_musical.ogg", "bus": "Música",
		"volume_db": -16.0, "generator": "music_box",
		"desc": "Melodía de cajita musical, lenta y metálica, en bucle sin corte. 28 s.",
	},
	"cajita_musical_apagon": {
		"file": "cajita_musical.ogg", "bus": "Música",
		"volume_db": -4.0, "generator": "music_box",
		"desc": "La misma cajita, más fuerte: es lo único que se oye a oscuras.",
	},
	"ticket_nuevo": {
		"file": "ticket_nuevo.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "ticket_chime",
		"desc": "Campanita corta de aviso de sistema, dos notas que suben.",
	},
	"grito": {
		"file": "grito.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "scream",
		"desc": "Grito genérico de jumpscare, agudo y saturado. Es el último recurso.",
	},
	# Los gritos de cada profe y los tres de base. Van sin provisional: si no
	# están grabados, scream_for() se cae al "grito" de arriba, que sí lo tiene.
	"grito_barcosa": {"file": "gritos/grito_barcosa.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito de Barcosa al atraparte: hombre mayor, ronco y enojado.",
	},
	"grito_urena": {"file": "gritos/grito_urena.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito de Ureña: agudo y baboso, casi una risa que se rompe.",
	},
	"grito_rochis": {"file": "gritos/grito_rochis.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito de Rochis: seco y grave, de pocas palabras.",
	},
	"grito_juan": {"file": "gritos/grito_juan.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito de Juan.exe: chillido corto con un pitido digital encima.",
	},
	"grito_armando": {"file": "gritos/grito_armando.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito de Armando: con reverb de micrófono malo y saturado.",
	},
	"grito_cometrabas": {"file": "gritos/grito_cometrabas.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito de la botarga: coro de voces apagadas dentro de la felpa.",
	},
	"grito_audel": {"file": "gritos/grito_audel.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito del Mago Eléctrico: chispazo eléctrico y una carcajada.",
	},
	"grito_base_1": {"file": "gritos/grito_base_1.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito de jumpscare de reserva (1 de 3), fuerte y saturado.",
	},
	"grito_base_2": {"file": "gritos/grito_base_2.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito de jumpscare de reserva (2 de 3), distinto al 1.",
	},
	"grito_base_3": {"file": "gritos/grito_base_3.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "",
		"desc": "Grito de jumpscare de reserva (3 de 3), distinto a los otros dos.",
	},
	"tono_ocupado": {
		"file": "tono_ocupado.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "busy_tone",
		"desc": "Tono de ocupado de teléfono fijo, dos o tres pitidos.",
	},
	"despertador": {
		"file": "despertador.ogg", "bus": "Efectos",
		"volume_db": -8.0, "generator": "alarm",
		"desc": "Campanadas de reloj despertador de los de cuerda, 2 o 3 s.",
	},
	"campana_escuela": {
		"file": "campana_escuela.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "school_bell",
		"desc": "Campana de escuela con aplausos de fondo.",
	},
	"ninos_yay": {
		"file": "ninos_yay.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "school_bell",
		"desc": "Niños gritando «yeeey», contentos, 1 o 2 s. Entra al acabarse el despertador.",
	},
	"extras_musica": {
		"file": "extras_musica.ogg", "bus": "Música",
		"volume_db": -14.0, "generator": "menu_music",
		"desc": "Música de Extras y la Custom Night: más tranquila que la del menú, en bucle sin corte.",
	},
	"golpe_metal_1": {
		"file": "golpe_metal_1.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "door_bang",
		"desc": "Golpe de metal contra la cortina, toma 1 de 3 (se alternan en cada golpe de Barcosa).",
	},
	"golpe_metal_2": {
		"file": "golpe_metal_2.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "door_bang",
		"desc": "Golpe de metal contra la cortina, toma 2 de 3.",
	},
	"golpe_metal_3": {
		"file": "golpe_metal_3.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "door_bang",
		"desc": "Golpe de metal contra la cortina, toma 3 de 3.",
	},
	"llavero": {
		"file": "llavero.ogg", "bus": "Lejos",
		"volume_db": -4.0, "generator": "", "pan": PAN_CENTER,
		"desc": "Un llavero colgando que tintinea al caminar. Suena con los pasos de Mamador.",
	},
	"tic_boom_1": {
		"file": "menu/tic_boom_1.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: boom grave y largo, toma 1 de 3. Los booms son los que acompañan al tic «ultra».",
	},
	"tic_boom_2": {
		"file": "menu/tic_boom_2.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: boom grave y largo, toma 2 de 3.",
	},
	"tic_boom_3": {
		"file": "menu/tic_boom_3.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: boom grave y largo, toma 3 de 3.",
	},
	"tic_piano": {
		"file": "menu/tic_piano.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: un acorde de piano golpeado, que se queda sonando.",
	},
	"tic_golpe_metal": {
		"file": "menu/tic_golpe_metal.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: Un golpe contra metal, con su resonancia.",
	},
	"tic_vidrio": {
		"file": "menu/tic_vidrio.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: Vidrio que se raja de golpe.",
	},
	"tic_rechinido": {
		"file": "menu/tic_rechinido.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: Un rechinido metálico, incómodo.",
	},
	"tic_raspon": {
		"file": "menu/tic_raspon.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: Algo que raspa, seco y corto.",
	},
	"tic_golpe_eco": {
		"file": "menu/tic_golpe_eco.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: Un golpe con mucho eco, como en un pasillo vacío.",
	},
	"tic_whoosh_golpe": {
		"file": "menu/tic_whoosh_golpe.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: Un barrido de aire que acaba en golpe.",
	},
	"tic_estatica": {
		"file": "menu/tic_estatica.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "Tic del menú: Un chasquido de estática, el más corto de todos.",
	},
	"estatica_inquietante": {
		"file": "estatica_inquietante.ogg", "bus": "Efectos",
		"volume_db": -14.0, "generator": "camera_static",
		"desc": "Estática con algo dentro, de las que ponen nervioso. Va de fondo en el tic «ultra» del menú.",
	},
	"estatica_inquietante_gameover": {
		"file": "estatica_inquietante.ogg", "bus": "Efectos",
		"volume_db": -16.0, "generator": "camera_static",
		"desc": "La misma estática, más bajita, debajo de la de la pantalla de game over (mismo archivo).",
	},
	"menu_musica": {
		"file": "menu_musica.ogg", "bus": "Música",
		"volume_db": -12.0, "generator": "menu_music",
		"desc": "La pista principal del menú, en bucle (5:46). Es «Halloween Atmosphere 2024» de Sascha Ende, CC BY 4.0.",
	},
	"menu_capa": {
		"file": "menu_capa.ogg", "bus": "Música",
		"volume_db": -22.0, "generator": "",
		"desc": "Primera capa de ambiente encima de la música del menú, en bucle sin corte.",
	},
	"menu_capa2": {
		"file": "menu_capa2.ogg", "bus": "Música",
		"volume_db": -24.0, "generator": "",
		"desc": "Segunda capa de ambiente del menú, más baja todavía, en bucle sin corte.",
	},
	"pasos_acercandose": {
		"file": "pasos_acercandose.ogg", "bus": "Efectos",
		"volume_db": -2.0, "generator": "footsteps",
		"desc": "Tres pasos pesados que se acercan en la oscuridad y paran.",
	},
	"se_aleja": {
		"file": "se_aleja.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "glass_repel",
		"desc": "Alguien que se despega del cristal y se va arrastrando los pies.",
	},
	"golpe_grave_1": {
		"file": "golpe_grave_1.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "low_hit",
		"desc": "El golpe de una alucinación, toma 1 de 3 (se alternan sin repetir).",
	},
	"golpe_grave_2": {
		"file": "golpe_grave_2.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "low_hit",
		"desc": "El golpe de una alucinación, toma 2 de 3.",
	},
	"golpe_grave_3": {
		"file": "golpe_grave_3.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "low_hit",
		"desc": "El golpe de una alucinación, toma 3 de 3.",
	},
	"golpe_grave": {
		"file": "golpe_grave.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "low_hit",
		"desc": "Golpe grave y seco, de los que pegan un susto. Medio segundo.",
	},
	"ambiente_oficina": {
		"file": "ambiente_oficina.ogg", "bus": "Ambiente",
		"volume_db": -14.0, "generator": "office_ambience",
		"desc": "Zumbido de lámparas y ventilador de oficina, en bucle sin corte.",
	},
	"ambiente_pasillo": {
		"file": "ambiente_pasillo.ogg", "bus": "Ambiente",
		"volume_db": -20.0, "generator": "hallway_ambience",
		"desc": "Aire de pasillo vacío de noche, en bucle sin corte, muy tenue.",
	},
	"telefono_timbre": {
		"file": "telefono_timbre.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "phone_ring",
		"desc": "Timbre de teléfono de escritorio, en bucle hasta que contesten.",
	},
	"puerta_cortina": {
		"file": "puerta_cortina.ogg", "bus": "Efectos",
		"volume_db": -5.0, "generator": "door_shutter",
		"desc": "Cortina metálica de local bajando o subiendo, con su traqueteo.",
	},
	"golpes_cortina": {
		"file": "golpes_cortina.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "door_bang",
		"desc": "Un puñetazo contra la cortina metálica, con resonancia.",
	},
	"camara_cambio": {
		"file": "camara_cambio.ogg", "bus": "Efectos",
		"volume_db": -10.0, "generator": "camera_blip",
		"desc": "Clac de relé y zumbido corto al cambiar de cámara.",
	},
	"linterna_click": {
		"file": "linterna_click.ogg", "bus": "Efectos",
		"volume_db": -14.0, "generator": "flashlight_click",
		"desc": "Clic seco de interruptor de linterna.",
	},
	"breaker_palanca": {
		"file": "breaker_palanca.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "breaker_lever",
		"desc": "Palanca de tablero eléctrico bajando: dos clacs pesados.",
	},
	"telefono_colgar": {
		"file": "telefono_colgar.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "phone_hang_up",
		"desc": "Auricular que se cuelga sobre la base.",
	},
	"wasted": {
		"file": "wasted.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "wasted_sting",
		"desc": "Golpe orquestal corto y feo, de muerte en un juego de coches.",
	},
	"armando_windows_crash": {
		"file": "armando_windows_crash.ogg", "bus": "Efectos",
		"volume_db": -2.0, "generator": "",
		"desc": "Pantallazo azul: el sonido de un sistema que se cae de golpe.",
	},
	"armando_glitch_bucle": {
		"file": "armando_glitch_bucle.ogg", "bus": "Efectos",
		"volume_db": -18.0, "generator": "",
		"desc": "Zumbido digital roto, en bucle sin corte, mientras Armando tiene la pantalla tomada.",
	},
	"apagon_frase": {
		"file": "apagon_frase.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Lo que se oye justo al irse la luz, antes de la oscuridad del apagón.",
	},
	"menu_glitch_largo": {
		"file": "menu_glitch_largo.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "low_hit",
		"desc": "Glitch largo y feo para el tic «ultra» del menú, el de los tres profes.",
	},
	"sonido_perturbador": {
		"file": "extras/sonido_perturbador.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "",
		"desc": "El golpe del vistazo «de reojo»: medio segundo de algo que no debería estar ahí.",
	},
	"llamada_mencho": {
		"file": "llamadas/llamada_mencho.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Número equivocado, ya con efecto de teléfono. Entra una vez por noche entre la 1 y las 5 AM.",
	},
	"rosa_suspenso": {
		"file": "extras/rosa_suspenso.ogg", "bus": "Música",
		"volume_db": -4.0, "generator": "",
		"desc": "Rescate de Sergio (sin programar): el suspenso de cuando el susto se congela.",
	},
	"rosa_aire": {
		"file": "extras/rosa_aire.ogg", "bus": "Música",
		"volume_db": -4.0, "generator": "",
		"desc": "Rescate de Sergio (sin programar): el golpe de aire del destello blanco y el tótem.",
	},
	"aura": {
		"file": "extras/aura.ogg", "bus": "Música",
		"volume_db": -6.0, "generator": "",
		"desc": "Rescate de Sergio (sin programar): el aura del final, y también al ganar el tótem en el minijuego.",
	},
	"mamador_brecha": {
		"file": "mamador_brecha.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "breach",
		"desc": "Puerta derribada de una patada y gritos de un operativo entrando. Un segundo.",
	},
	"estatica_camara": {
		"file": "estatica_camara.ogg", "bus": "Ambiente",
		"volume_db": -30.0, "generator": "camera_static",
		"desc": "Estática de televisión vieja, en bucle sin corte, suave.",
	},
	"menu_blip": {
		"file": "menu_blip.ogg", "bus": "Efectos",
		"volume_db": -16.0, "generator": "menu_blip",
		"desc": "Pitido corto y seco de moverse por un menú de consola vieja.",
	},
	"tecla_maquina": {
		"file": "tecla_maquina.ogg", "bus": "Efectos",
		"volume_db": -12.0, "generator": "typewriter_key",
		"desc": "Golpe de una tecla de máquina de escribir. Respaldo de las tres de abajo.",
	},
	"tecla_maquina_1": {
		"file": "tecla_maquina_1.ogg", "bus": "Efectos",
		"volume_db": -12.0, "generator": "",
		"desc": "Tecla de máquina de escribir, toma 1 de 3 (se alternan al escribir).",
	},
	"tecla_maquina_2": {
		"file": "tecla_maquina_2.ogg", "bus": "Efectos",
		"volume_db": -12.0, "generator": "",
		"desc": "Tecla de máquina de escribir, toma 2 de 3.",
	},
	"tecla_maquina_3": {
		"file": "tecla_maquina_3.ogg", "bus": "Efectos",
		"volume_db": -12.0, "generator": "",
		"desc": "Tecla de máquina de escribir, toma 3 de 3.",
	},
	"es_impresionante": {
		"file": "es_impresionante.ogg", "bus": "Voces",
		"volume_db": -2.0, "generator": "",
		"desc": "Voz de Rochis diciendo «es impresionante». Si falta, la dice la voz sintética.",
	},
	"cajita_musical_aviso": {
		"file": "cajita_musical.ogg", "bus": "Lejos",
		"volume_db": -22.0, "generator": "music_box", "pan": PAN_RIGHT,
		"desc": "La misma cajita, muy bajita y con eco, como desde el cubículo 3.",
	},
	"barcosa_corre": {
		"file": "lejos/barcosa_corre.ogg", "bus": "Lejos",
		"volume_db": -2.0, "generator": "far_running", "pan": PAN_CENTER,
		"desc": "Pasos corriendo por un pasillo, acercándose, en bucle: suenan toda su carrera.",
	},
	"mamador_pasos": {
		"file": "lejos/mamador_pasos.ogg", "bus": "Lejos",
		"volume_db": -3.0, "generator": "far_boots", "pan": PAN_CENTER,
		"desc": "Botas pesadas y un radio con estática, lejos.",
	},
	"urena_banos": {
		"file": "lejos/urena_banos.ogg", "bus": "Lejos",
		"volume_db": -5.0, "generator": "far_water", "pan": PAN_CENTER,
		"desc": "Agua de lavabo corriendo, lejos, en bucle.",
	},
	"juan_teclado": {
		"file": "lejos/juan_teclado.ogg", "bus": "Lejos",
		"volume_db": -6.0, "generator": "far_keyboard", "pan": PAN_CENTER,
		"desc": "Tecleo de teclado mecánico, lejos, en bucle.",
	},
	"armando_modem": {
		"file": "lejos/armando_modem.ogg", "bus": "Lejos",
		"volume_db": -5.0, "generator": "far_modem", "pan": PAN_CENTER,
		"desc": "Módem de 56k negociando, distorsionado y lejos.",
	},
	"audel_chispa": {
		"file": "lejos/audel_chispa.ogg", "bus": "Lejos",
		"volume_db": -3.0, "generator": "far_spark", "pan": PAN_LEFT,
		"desc": "Zumbido eléctrico con algún trueno, lejos, en bucle.",
	},
	"rochis_silla": {
		"file": "lejos/rochis_silla.ogg", "bus": "Lejos",
		"volume_db": -4.0, "generator": "far_chair", "pan": PAN_LEFT,
		"desc": "Rechinido de una silla de oficina al moverse.",
	},
	"lejos_portazo": {
		"file": "lejos/lejos_portazo.ogg", "bus": "Lejos",
		"volume_db": -3.0, "generator": "far_door_slam", "pan": PAN_CENTER,
		"desc": "Un portazo en otra parte del edificio.",
	},
	"lejos_silla": {
		"file": "lejos/lejos_silla.ogg", "bus": "Lejos",
		"volume_db": -5.0, "generator": "far_chair", "pan": PAN_LEFT,
		"desc": "Una silla arrastrada en otro cuarto.",
	},
	"lejos_pasos_pasillo": {
		"file": "lejos/lejos_pasos_pasillo.ogg", "bus": "Lejos",
		"volume_db": -6.0, "generator": "far_upstairs", "pan": PAN_CENTER,
		"desc": "Pasos recorriendo el pasillo, lejos, sin prisa. Se oyen y se van.",
	},
	"lejos_pasos_arriba": {
		"file": "lejos/lejos_pasos_arriba.ogg", "bus": "Lejos",
		"volume_db": -5.0, "generator": "far_upstairs", "pan": PAN_CENTER,
		"desc": "Pasos en el piso de arriba, apagados.",
	},
	"lejos_risa": {
		"file": "lejos/lejos_risa.ogg", "bus": "Lejos",
		"volume_db": -6.0, "generator": "far_laugh", "pan": PAN_RIGHT,
		"desc": "Una risa corta, muy lejos, imposible de ubicar.",
	},
	"lejos_platos": {
		"file": "lejos/lejos_platos.ogg", "bus": "Lejos",
		"volume_db": -6.0, "generator": "far_dishes", "pan": PAN_RIGHT,
		"desc": "Platos y cubiertos en la cafetería vacía.",
	},
	"barcosa_puerta_1": {
		"file": "voces/barcosa_puerta_1.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Barcosa aporreando: «¿Quién cerró? Tengo clase en este salón.»",
	},
	"barcosa_puerta_2": {
		"file": "voces/barcosa_puerta_2.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Barcosa aporreando: «Abra, joven. Nada más paso lista y me voy.»",
	},
	"barcosa_puerta_3": {
		"file": "voces/barcosa_puerta_3.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Barcosa aporreando: «Diez minutos. Le estoy pidiendo diez minutos.»",
	},
	"barcosa_se_va": {
		"file": "voces/barcosa_se_va.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Barcosa rindiéndose: «Bueno, ya. Quedan todos con falta.»",
	},
	"mamador_ok_1": {
		"file": "voces/mamador_ok_1.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Mamador conforme: «Sin novedad. Me retiro.»",
	},
	"mamador_ok_2": {
		"file": "voces/mamador_ok_2.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Mamador conforme: «Nada de inteligencia artificial. Así me gusta.»",
	},
	"mamador_ok_3": {
		"file": "voces/mamador_ok_3.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Mamador conforme: «Todo en orden. Sigan así.»",
	},
	"llamada_noche1": {
		"file": "llamadas/llamada_noche1.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "La llamada entera de la noche 1 (solo voz; el timbre lo pone el juego). Guion en docs/guion_voces.md.",
	},
	"llamada_noche2": {
		"file": "llamadas/llamada_noche2.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "La llamada entera de la noche 2 (solo voz). Guion en docs/guion_voces.md.",
	},
	"llamada_noche3": {
		"file": "llamadas/llamada_noche3.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "La llamada entera de la noche 3 (solo voz). Guion en docs/guion_voces.md.",
	},
	"llamada_noche4": {
		"file": "llamadas/llamada_noche4.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "La llamada entera de la noche 4 (solo voz). Guion en docs/guion_voces.md.",
	},
	"llamada_noche5": {
		"file": "llamadas/llamada_noche5.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "La llamada entera de la noche 5 (solo voz). Guion en docs/guion_voces.md.",
	},
	"llamada_noche6": {
		"file": "llamadas/llamada_noche6.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "La llamada entera de la noche 6 (solo voz). Guion en docs/guion_voces.md.",
	},
}

## Los que suenan en bucle: el AudioManager les marca el bucle al cargarlos.
const LOOPING: Array[String] = [
	"cajita_musical", "cajita_musical_aviso", "ambiente_oficina", "menu_musica",
	"ambiente_pasillo", "telefono_timbre", "estatica_camara",
	"urena_banos", "juan_teclado", "audel_chispa", "extras_musica",
	"menu_capa", "menu_capa2",
	# El zumbido de Armando dura lo que dure su toma de pantalla.
	"armando_glitch_bucle",
	# Los pasos de Barcosa suenan toda su carrera, así que van en bucle.
	"barcosa_corre",
]


static func ids() -> Array:
	return CATALOG.keys()


static func entry(id: String) -> Dictionary:
	return CATALOG.get(id, {}) as Dictionary


static func file_name(id: String) -> String:
	return str(entry(id).get("file", ""))


## La ruta donde se espera el archivo de verdad.
static func file_path(id: String) -> String:
	var name: String = file_name(id)
	return "" if name.is_empty() else PATH % name


static func bus_of(id: String) -> String:
	return str(entry(id).get("bus", BUS_EFFECTS))


static func volume_db(id: String) -> float:
	return float(entry(id).get("volume_db", 0.0))


static func generator_of(id: String) -> String:
	return str(entry(id).get("generator", ""))


static func is_looping(id: String) -> bool:
	return id in LOOPING


## De qué lado viene un sonido, de -1 a 1. 0 si no lo dice.
static func pan_of(id: String) -> float:
	return float(entry(id).get("pan", PAN_CENTER))


## true si ese sonido sale por el bus de los lejanos.
static func is_distant(id: String) -> bool:
	return bus_of(id) == BUS_DISTANT
