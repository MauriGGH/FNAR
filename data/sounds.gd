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
const BUSY_TONE: String = "tono_ocupado"
const ALARM: String = "despertador"
const SCHOOL_BELL: String = "campana_escuela"
const FOOTSTEPS: String = "pasos_acercandose"
const LOW_HIT: String = "golpe_grave"
## El mismo golpe grave, más bajito, para el tic del menú.
const MENU_TIC: String = "golpe_grave_menu"
## Cuando uno de los del cristal se va con el cuarto destello.
const GLASS_REPEL: String = "se_aleja"
## Ambiente, en bucle toda la noche.
const OFFICE_AMBIENCE: String = "ambiente_oficina"
const HALLWAY_AMBIENCE: String = "ambiente_pasillo"
## El timbre del teléfono, en bucle mientras suena.
const PHONE_RING: String = "telefono_timbre"
const DOOR_SHUTTER: String = "puerta_cortina"
const DOOR_BANGS: String = "golpes_cortina"
const CAMERA_BLIP: String = "camara_cambio"
const FLASHLIGHT_CLICK: String = "linterna_click"
const BREAKER_LEVER: String = "breaker_palanca"
## El siseo de fondo mientras el monitor está abierto.
const CAMERA_STATIC: String = "estatica_camara"
## El blip de moverse por un menú y el de aceptar (el mismo, más agudo).
const MENU_BLIP: String = "menu_blip"
## El golpe de una tecla de máquina de escribir, al escribir el nombre.
const TYPEWRITER_KEY: String = "tecla_maquina"
## El clac de colgar, al acabar o silenciar una llamada.
const PHONE_HANG_UP: String = "telefono_colgar"
## El golpe de la pantalla de WASTED.
const WASTED: String = "wasted"

# --- Lo que se oye de lejos --------------------------------------------------
const FAR_BARCOSA_RUN: String = "barcosa_corre"
const FAR_MAMADOR_STEPS: String = "mamador_pasos"
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
const FAR_AMBIENT: Array[String] = [
	"lejos_portazo", "lejos_silla", "lejos_pasos_arriba", "lejos_risa", "lejos_platos",
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
	},
	"cajita_musical_apagon": {
		"file": "cajita_musical.ogg", "bus": "Música",
		"volume_db": -4.0, "generator": "music_box",
	},
	"ticket_nuevo": {
		"file": "ticket_nuevo.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "ticket_chime",
	},
	"grito": {
		"file": "grito.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "scream",
	},
	"tono_ocupado": {
		"file": "tono_ocupado.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "busy_tone",
	},
	"despertador": {
		"file": "despertador.ogg", "bus": "Efectos",
		"volume_db": -8.0, "generator": "alarm",
	},
	"campana_escuela": {
		"file": "campana_escuela.ogg", "bus": "Efectos",
		"volume_db": -4.0, "generator": "school_bell",
	},
	"pasos_acercandose": {
		"file": "pasos_acercandose.ogg", "bus": "Efectos",
		"volume_db": -2.0, "generator": "footsteps",
	},
	"se_aleja": {
		"file": "se_aleja.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "glass_repel",
	},
	"golpe_grave": {
		"file": "golpe_grave.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "low_hit",
	},
	"golpe_grave_menu": {
		"file": "golpe_grave.ogg", "bus": "Efectos",
		"volume_db": -10.0, "generator": "low_hit",
	},
	"ambiente_oficina": {
		"file": "ambiente_oficina.ogg", "bus": "Ambiente",
		"volume_db": -14.0, "generator": "office_ambience",
	},
	"ambiente_pasillo": {
		"file": "ambiente_pasillo.ogg", "bus": "Ambiente",
		"volume_db": -20.0, "generator": "hallway_ambience",
	},
	"telefono_timbre": {
		"file": "telefono_timbre.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "phone_ring",
	},
	"puerta_cortina": {
		"file": "puerta_cortina.ogg", "bus": "Efectos",
		"volume_db": -5.0, "generator": "door_shutter",
	},
	"golpes_cortina": {
		"file": "golpes_cortina.ogg", "bus": "Efectos",
		"volume_db": -3.0, "generator": "door_bang",
	},
	"camara_cambio": {
		"file": "camara_cambio.ogg", "bus": "Efectos",
		"volume_db": -10.0, "generator": "camera_blip",
	},
	"linterna_click": {
		"file": "linterna_click.ogg", "bus": "Efectos",
		"volume_db": -14.0, "generator": "flashlight_click",
	},
	"breaker_palanca": {
		"file": "breaker_palanca.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "breaker_lever",
	},
	"telefono_colgar": {
		"file": "telefono_colgar.ogg", "bus": "Efectos",
		"volume_db": -6.0, "generator": "phone_hang_up",
	},
	"wasted": {
		"file": "wasted.ogg", "bus": "Efectos",
		"volume_db": 0.0, "generator": "wasted_sting",
	},
	"estatica_camara": {
		"file": "estatica_camara.ogg", "bus": "Ambiente",
		"volume_db": -30.0, "generator": "camera_static",
	},
	"menu_blip": {
		"file": "menu_blip.ogg", "bus": "Efectos",
		"volume_db": -16.0, "generator": "menu_blip",
	},
	"tecla_maquina": {
		"file": "tecla_maquina.ogg", "bus": "Efectos",
		"volume_db": -12.0, "generator": "typewriter_key",
	},
	"es_impresionante": {
		"file": "es_impresionante.ogg", "bus": "Voces",
		"volume_db": -2.0, "generator": "",
	},
	"cajita_musical_aviso": {
		"file": "cajita_musical.ogg", "bus": "Lejos",
		"volume_db": -22.0, "generator": "music_box", "pan": PAN_RIGHT,
	},
	"barcosa_corre": {
		"file": "lejos/barcosa_corre.ogg", "bus": "Lejos",
		"volume_db": -2.0, "generator": "far_running", "pan": PAN_CENTER,
	},
	"mamador_pasos": {
		"file": "lejos/mamador_pasos.ogg", "bus": "Lejos",
		"volume_db": -3.0, "generator": "far_boots", "pan": PAN_CENTER,
	},
	"urena_banos": {
		"file": "lejos/urena_banos.ogg", "bus": "Lejos",
		"volume_db": -5.0, "generator": "far_water", "pan": PAN_CENTER,
	},
	"juan_teclado": {
		"file": "lejos/juan_teclado.ogg", "bus": "Lejos",
		"volume_db": -6.0, "generator": "far_keyboard", "pan": PAN_CENTER,
	},
	"armando_modem": {
		"file": "lejos/armando_modem.ogg", "bus": "Lejos",
		"volume_db": -5.0, "generator": "far_modem", "pan": PAN_CENTER,
	},
	"audel_chispa": {
		"file": "lejos/audel_chispa.ogg", "bus": "Lejos",
		"volume_db": -3.0, "generator": "far_spark", "pan": PAN_LEFT,
	},
	"rochis_silla": {
		"file": "lejos/rochis_silla.ogg", "bus": "Lejos",
		"volume_db": -4.0, "generator": "far_chair", "pan": PAN_LEFT,
	},
	"lejos_portazo": {
		"file": "lejos/lejos_portazo.ogg", "bus": "Lejos",
		"volume_db": -3.0, "generator": "far_door_slam", "pan": PAN_CENTER,
	},
	"lejos_silla": {
		"file": "lejos/lejos_silla.ogg", "bus": "Lejos",
		"volume_db": -5.0, "generator": "far_chair", "pan": PAN_LEFT,
	},
	"lejos_pasos_arriba": {
		"file": "lejos/lejos_pasos_arriba.ogg", "bus": "Lejos",
		"volume_db": -5.0, "generator": "far_upstairs", "pan": PAN_CENTER,
	},
	"lejos_risa": {
		"file": "lejos/lejos_risa.ogg", "bus": "Lejos",
		"volume_db": -6.0, "generator": "far_laugh", "pan": PAN_RIGHT,
	},
	"lejos_platos": {
		"file": "lejos/lejos_platos.ogg", "bus": "Lejos",
		"volume_db": -6.0, "generator": "far_dishes", "pan": PAN_RIGHT,
	},
	"barcosa_puerta_1": {
		"file": "voces/barcosa_puerta_1.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"barcosa_puerta_2": {
		"file": "voces/barcosa_puerta_2.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"barcosa_puerta_3": {
		"file": "voces/barcosa_puerta_3.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"barcosa_se_va": {
		"file": "voces/barcosa_se_va.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"mamador_ok_1": {
		"file": "voces/mamador_ok_1.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"mamador_ok_2": {
		"file": "voces/mamador_ok_2.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"mamador_ok_3": {
		"file": "voces/mamador_ok_3.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"llamada_noche1": {
		"file": "llamadas/llamada_noche1.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"llamada_noche2": {
		"file": "llamadas/llamada_noche2.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"llamada_noche3": {
		"file": "llamadas/llamada_noche3.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"llamada_noche4": {
		"file": "llamadas/llamada_noche4.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"llamada_noche5": {
		"file": "llamadas/llamada_noche5.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
	"llamada_noche6": {
		"file": "llamadas/llamada_noche6.ogg", "bus": "Voces",
		"volume_db": 0.0, "generator": "",
	},
}

## Los que suenan en bucle: el AudioManager les marca el bucle al cargarlos.
const LOOPING: Array[String] = [
	"cajita_musical", "cajita_musical_aviso", "despertador", "ambiente_oficina",
	"ambiente_pasillo", "telefono_timbre", "estatica_camara",
	"urena_banos", "juan_teclado", "audel_chispa",
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
