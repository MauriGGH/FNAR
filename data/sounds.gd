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
const SCREAM_SLUGS: Array[String] = [
	"barcosa", "urena", "rochis", "juan", "armando", "cometrabas", "audel",
]
const BUSY_TONE: String = "tono_ocupado"
const ALARM: String = "despertador"
## Los niños gritando "¡yeeey!" al acabarse las campanadas de las 6 AM.
## La música del menú principal: **una sola pista en bucle**, de 64 s. Ya trae
## mezclado el dron de voces, así que no lleva ninguna capa encima ni hay nada
## que elegir: antes eran tres pistas a la vez y dos opciones para comparar.
const MENU_MUSIC: String = "menu_musica_final"
## Lo que tarda en entrar al abrir el menú.
const MENU_MUSIC_FADE_IN: float = 0.5
## Y la de Extras y la Custom Night, también en bucle.
const EXTRAS_MUSIC: String = "extras_musica"
const FOOTSTEPS: String = "pasos_acercandose"
## El golpe de una alucinación. Hay tres tomas y se alternan sin repetir la
## última; LOW_HIT es la de respaldo, la única con provisional por código.
const LOW_HIT: String = "golpe_grave"
const LOW_HITS: Array[String] = ["golpe_grave_1", "golpe_grave_2", "golpe_grave_3"]
## Los golpes del tic del menú. En cada tic suena uno al azar, y no se repite
## ninguno de los dos últimos: así no se le agarra el ritmo.
##
## `tic_rechinido` **ya no entra en el sorteo**: sonaba a puerta abriéndose y en
## el menú no hay ninguna puerta. Su id se queda registrado, con su archivo, por
## si algún día le sirve a otra cosa.
const MENU_TICS: Array[String] = [
	"tic_boom_1", "tic_boom_2", "tic_boom_3", "tic_golpe_metal", "tic_vidrio",
	"tic_raspon", "tic_golpe_eco", "tic_whoosh_golpe",
	"tic_piano", "tic_estatica",
]
## Los tres booms, que son los gordos: uno de ellos acompaña al glitch largo
## en el tic "ultra", el de los tres profes.
const MENU_TIC_BOOMS: Array[String] = ["tic_boom_1", "tic_boom_2", "tic_boom_3"]
## Y la estática que va de fondo en ese tic.
const UNEASY_STATIC: String = "estatica_inquietante"
## La misma, más bajita, debajo de la estática de la pantalla de game over.
const UNEASY_STATIC_GAME_OVER: String = "estatica_inquietante_gameover"
# --- Secuencias de efectos ----------------------------------------------------
## Un susto, un rescate o una irrupción son **secuencias**: sus sonidos van uno
## detrás de otro y **nunca se enciman**. Quien las pide no apunta tiempos a
## mano: el AudioManager encola el siguiente y lo suelta cuando el anterior
## termina de verdad (su señal `finished`). Y al empezar una secuencia se calla
## lo que haya quedado sonando de ella, para que un susto nuevo no se mezcle
## con los restos del anterior.
const SEQ_SCARE: String = "susto"
const SEQ_RESCUE: String = "rescate"
const SEQ_MOMO: String = "momo"
const SEQ_BLACKOUT: String = "apagon"

## Qué sonidos forman cada una. Los gritos no se listan: son muchos (uno por
## profe y tres de reserva) y entran por su prefijo en `sequence_of()`.
const SEQUENCES: Dictionary = {
	SEQ_SCARE: [
		"wasted", "mamador_delito", "mamador_brecha",
		"estatica_inquietante_gameover", "cortaso",
	],
	SEQ_VOICE: [
		"urena_saludo", "urena_linea1", "urena_linea2", "urena_linea3",
		"urena_linea4", "urena_linea5", "urena_linea6", "urena_linea7",
		"urena_reaccion_esquiva", "urena_reaccion_sigue", "urena_reaccion_grosero",
		"urena_adios_esquivo", "urena_adios_foto", "urena_adios_grosero",
		"urena_adios_colgado",
	],
	SEQ_RESCUE: ["sergio_rescate"],
	SEQ_MOMO: ["momo_cancion"],
	SEQ_BLACKOUT: ["apagon_frase", "cajita_musical_apagon", "pasos_acercandose"],
}

## Los ids de cada secuencia, resueltos del catálogo una sola vez.
static var _sequence_ids: Dictionary = {}


## A qué secuencia pertenece un sonido, o "" si va por su cuenta.
static func sequence_of(id: String) -> String:
	for name: Variant in SEQUENCES:
		if id in (SEQUENCES[name] as Array):
			return str(name)
	return SEQ_SCARE if id.begins_with("grito") else ""


## Todos los ids de una secuencia, gritos incluidos.
static func sequence_ids(sequence: String) -> Array[String]:
	if _sequence_ids.is_empty():
		for id: Variant in CATALOG:
			var name: String = sequence_of(str(id))
			if name.is_empty():
				continue
			if not _sequence_ids.has(name):
				_sequence_ids[name] = [] as Array[String]
			(_sequence_ids[name] as Array[String]).append(str(id))
	return _sequence_ids.get(sequence, [] as Array[String])


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
## La maquinita: su música por nivel (chiptune de 8 bits generado por código) y
## sus pitidos. El nivel 3 no lleva melodía, solo un zumbido grave.
const ARCADE_MUSIC: Array[String] = [
	"arcade_nivel1", "arcade_nivel2", "arcade_nivel3",
]
const ARCADE_JUMP: String = "arcade_salto"
const ARCADE_HURT: String = "arcade_golpe"
const ARCADE_PICK: String = "arcade_recoge"
const ARCADE_BOOT: String = "arcade_bip"
const ARCADE_MUSIC_BOX: String = "arcade_cajita"


## La música que le toca a un nivel.
static func arcade_music(level: int) -> String:
	return ARCADE_MUSIC[clampi(level, 1, ARCADE_MUSIC.size()) - 1]


## El blip de moverse por un menú y el de aceptar (el mismo, más agudo).
const MENU_BLIP: String = "menu_blip"
## El golpe de una tecla de máquina de escribir, al escribir el nombre. Este es
## el de respaldo: siempre suena, aunque sea el provisional por código.
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
## Las dos llamadas raras que pueden entrar a media noche, una por noche. La
## noche 1 es siempre la del Mencho; desde la 2 se sortea entre las dos.
const MENCHO_CALL: String = "llamada_mencho"
const TOY_CALL: String = "llamada_juguete"
const RANDOM_CALLS: Array[String] = ["llamada_mencho", "llamada_juguete"]
## La descarga del pararrayos que desconecta los patch cords.
const LIGHTNING: String = "descarga_pararrayos"
## El cortaso: el Mago entrando a la oficina a dejarla sin linterna.
const CORTASO: String = "cortaso"

## El rescate de Sergio es **una sola pista de 13.3 s** que lleva dentro todo:
## el suspenso del congelado, el aire del haz y el aura del tótem. La escena se
## cuelga de sus tiempos (ver `Sergio.RESCUE_*`), así que no hay nada que
## encimar. Antes eran tres sonidos sueltos y se pisaban.
const SERGIO_RESCUE: String = "sergio_rescate"
## El aura sigue en pie, pero solo para el final del minijuego de la maquinita.
const AURA: String = "aura"
## Y la canción de Momo, con su grito al final.
const MOMO_SONG: String = "momo_cancion"

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
## La voz de Rochis, ya grabada. **Ninguna voz lleva provisional por código**:
## un pitido en vez de una frase no dice nada, así que si falta el archivo lo
## único que sale es el subtítulo.
const IMPRESSIVE: String = "es_impresionante"
## Frases sueltas más de Rochis, todavía **sin grabar**. Las que existan entran
## al sorteo del botón de la CAM 4 junto con «es impresionante»; mientras no
## esté el archivo, es como si no estuvieran.
const ROCHIS_EXTRA: Array[String] = [
	"rochis_extra_1", "rochis_extra_2", "rochis_extra_3",
]

# --- Las voces de Ureña y de Mamador -----------------------------------------
## La llamada de media noche de Ureña, línea por línea. Todas van por el bus
## Voces y **sin provisional**: lo que falte se queda en subtítulo.
const URENA_GREETING: String = "urena_saludo"
const URENA_LINES: Array[String] = [
	"urena_linea1", "urena_linea2", "urena_linea3", "urena_linea4",
	"urena_linea5", "urena_linea6", "urena_linea7",
]
const URENA_REACTION_DODGE: String = "urena_reaccion_esquiva"
const URENA_REACTION_ALONG: String = "urena_reaccion_sigue"
const URENA_REACTION_RUDE: String = "urena_reaccion_grosero"
const URENA_FAREWELL_DODGED: String = "urena_adios_esquivo"
const URENA_FAREWELL_ALONG: String = "urena_adios_foto"
const URENA_FAREWELL_RUDE: String = "urena_adios_grosero"
const URENA_FAREWELL_SNUBBED: String = "urena_adios_colgado"
## Lo que grita Mamador al pillarte, justo antes de la irrupción.
const MAMADOR_CRIME: String = "mamador_delito"

## Las voces de la llamada son **una secuencia**: cada línea nueva calla la
## anterior en vez de encimarse. En una conversación, interrumpir es lo que se
## entiende; esperar turno dejaría la voz detrás del subtítulo.
const SEQ_VOICE: String = "voz"

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


## El grito que le toca a un jumpscare: el suyo si está grabado y, si no, el
## grito de siempre. **Nunca devuelve vacío**: un salto sin grito no asusta, y
## con la estática sola no se entiende lo que pasó.
static func scream_for(slug: String) -> String:
	var own: String = "grito_%s" % slug
	return own if AudioManager.has_real_file(own) else SCREAM


## La frase que suelta Rochis al darle al botón: «es impresionante» y, cuando
## estén grabadas, cualquiera de sus frases extra, una al azar. Las que no
## tengan archivo no entran al sorteo, así que hoy siempre sale la de siempre.
static func rochis_line() -> String:
	var pool: Array[String] = [IMPRESSIVE]
	for id: String in ROCHIS_EXTRA:
		if AudioManager.has_real_file(id):
			pool.append(id)
	return pool[randi() % pool.size()]


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
		"desc": "Un rechinido metálico, incómodo. Fuera del sorteo del tic: sonaba a puerta.",
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
	"momo_cancion": {
		"file": "extras/momo_cancion.ogg", "bus": "Música",
		"volume_db": 0.0, "generator": "momo_song",
		"desc": "La cancioncita de Momo, 15 s: dulce al principio y rota al final, con su grito.",
	},
	"menu_musica_final": {
		"file": "menu/menu_musica_final.ogg", "bus": "Música",
		# A la par de los tics del menú, que son los efectos que suenan con
		# ella: los dos a -4 dB.
		"volume_db": -4.0, "generator": "menu_music",
		"desc": "La música del menú principal: bucle de 64 s, con el dron de voces ya mezclado dentro.",
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
	"llamada_juguete": {
		"file": "llamadas/llamada_juguete.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "La otra llamada rara, ya con efecto de teléfono. Se sortea con la del Mencho desde la noche 2.",
	},
	"descarga_pararrayos": {
		"file": "descarga_pararrayos.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "far_spark",
		"desc": "La descarga del pararrayos que tumba los patch cords: un trueno seco con chispazo eléctrico.",
	},
	"cortaso": {
		"file": "cortaso.ogg", "bus": "Efectos",
		"volume_db": -2.0, "generator": "breaker_lever",
		"desc": "El cortaso del Mago Eléctrico al entrar a la oficina: cortocircuito y todo apagándose.",
	},
	"llamada_mencho": {
		"file": "llamadas/llamada_mencho.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Número equivocado, ya con efecto de teléfono. Entra una vez por noche entre la 1 y las 5 AM.",
	},
	"sergio_rescate": {
		"file": "extras/sergio_rescate.ogg", "bus": "Música",
		"volume_db": -2.0, "generator": "rescue",
		"desc": "El rescate de Sergio completo, 13.3 s: suspenso, el aire del haz a los 3.5 s y el aura del tótem a los 8.5 s.",
	},
	"aura": {
		"file": "extras/aura.ogg", "bus": "Música",
		"volume_db": -6.0, "generator": "",
		"desc": "El aura del tótem al ganar un nivel de la maquinita.",
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
	"arcade_nivel1": {
		"file": "arcade_nivel1.ogg", "bus": "Música",
		"volume_db": -12.0, "generator": "arcade_level1",
		"desc": "Chiptune de 8 bits de la maquinita, nivel 1: alegre, de posada.",
	},
	"arcade_nivel2": {
		"file": "arcade_nivel2.ogg", "bus": "Música",
		"volume_db": -12.0, "generator": "arcade_level2",
		"desc": "La misma idea para el nivel 2, pero ya desafinada: algo va mal.",
	},
	"arcade_nivel3": {
		"file": "arcade_nivel3.ogg", "bus": "Música",
		"volume_db": -14.0, "generator": "arcade_level3",
		"desc": "Nivel 3: sin melodía, solo un zumbido grave que no para.",
	},
	"arcade_golpe": {
		"file": "arcade_golpe.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "arcade_hurt",
		"desc": "Golpe de 8 bits al perder una vida: un zumbido que baja de tono.",
	},
	"arcade_salto": {
		"file": "arcade_salto.ogg", "bus": "Efectos",
		"volume_db": -10.0, "generator": "arcade_jump",
		"desc": "Pitido de 8 bits al saltar, de los que suben.",
	},
	"arcade_recoge": {
		"file": "arcade_recoge.ogg", "bus": "Efectos",
		"volume_db": -10.0, "generator": "arcade_pick",
		"desc": "Pitido corto de 8 bits al recoger algo.",
	},
	"arcade_bip": {
		"file": "arcade_bip.ogg", "bus": "Efectos",
		"volume_db": -8.0, "generator": "arcade_boot",
		"desc": "El bip de arranque de la maquinita, con su estática.",
	},
	"arcade_cajita": {
		"file": "arcade_cajita.ogg", "bus": "Música",
		"volume_db": -6.0, "generator": "arcade_music_box",
		"desc": "La cajita musical distorsionada del final del nivel 3.",
	},
	"menu_blip": {
		"file": "menu_blip.ogg", "bus": "Efectos",
		"volume_db": -16.0, "generator": "menu_blip",
		"desc": "Pitido corto y seco de moverse por un menú de consola vieja.",
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
		"desc": "Voz de Rochis diciendo «es impresionante».",
	},
	"rochis_extra_1": {
		"file": "voces/rochis_extra_1.ogg", "bus": "Voces",
		"volume_db": -2.0, "generator": "",
		"desc": "Otra frase de Rochis para el botón de la CAM 4, en su mismo tono de asombro (1 de 3).",
	},
	"rochis_extra_2": {
		"file": "voces/rochis_extra_2.ogg", "bus": "Voces",
		"volume_db": -2.0, "generator": "",
		"desc": "Otra frase de Rochis para el botón de la CAM 4 (2 de 3), distinta a la 1.",
	},
	"rochis_extra_3": {
		"file": "voces/rochis_extra_3.ogg", "bus": "Voces",
		"volume_db": -2.0, "generator": "",
		"desc": "Otra frase de Rochis para el botón de la CAM 4 (3 de 3), distinta a las otras dos.",
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
	"urena_saludo": {
		"file": "voces/urena_saludo.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Ureña saludando por teléfono, sin el nombre ni la cuenta de tareas.",
	},
	"urena_linea1": {
		"file": "voces/urena_linea1.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Insinuación 1 de Ureña: los trabajitos extra en su cubículo.",
	},
	"urena_linea2": {
		"file": "voces/urena_linea2.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Insinuación 2 de Ureña: convertirte en mujer por una noche.",
	},
	"urena_linea3": {
		"file": "voces/urena_linea3.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Insinuación 3 de Ureña: subirte la calificación en su oficina.",
	},
	"urena_linea4": {
		"file": "voces/urena_linea4.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Insinuación 4 de Ureña: la foto de cuerpo completo.",
	},
	"urena_linea5": {
		"file": "voces/urena_linea5.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Insinuación 5 de Ureña: el disco duro.",
	},
	"urena_linea6": {
		"file": "voces/urena_linea6.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Insinuación 6 de Ureña: la conexión punto a punto.",
	},
	"urena_linea7": {
		"file": "voces/urena_linea7.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Insinuación 7 de Ureña: el cable y el conector.",
	},
	"urena_reaccion_esquiva": {
		"file": "voces/urena_reaccion_esquiva.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Reacción de Ureña cuando lo esquivas con educación: «Ay, qué serio...»",
	},
	"urena_reaccion_sigue": {
		"file": "voces/urena_reaccion_sigue.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Reacción de Ureña cuando le sigues el juego: «¡Así me gusta!»",
	},
	"urena_reaccion_grosero": {
		"file": "voces/urena_reaccion_grosero.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Reacción de Ureña cuando le contestas mal: «Qué grosero eres...»",
	},
	"urena_adios_esquivo": {
		"file": "voces/urena_adios_esquivo.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Despedida de Ureña si lo esquivaste todo: la oferta sigue en pie.",
	},
	"urena_adios_foto": {
		"file": "voces/urena_adios_foto.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Despedida de Ureña si le seguiste el juego: te dejó un regalito.",
	},
	"urena_adios_grosero": {
		"file": "voces/urena_adios_grosero.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Despedida de Ureña si le contestaste mal: eso se paga.",
	},
	"urena_adios_colgado": {
		"file": "voces/urena_adios_colgado.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Lo que dice Ureña por el altavoz si le cuelgas: «Ahorita voy para allá.»",
	},
	"mamador_delito": {
		"file": "voces/mamador_delito.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
		"desc": "Mamador al pillarte: «¡Delito federal!». Va antes de la irrupción.",
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
	"cajita_musical", "cajita_musical_aviso", "ambiente_oficina", "menu_musica_final",
	"ambiente_pasillo", "telefono_timbre", "estatica_camara",
	"urena_banos", "juan_teclado", "audel_chispa", "extras_musica",
	"arcade_nivel1", "arcade_nivel2", "arcade_nivel3",
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
