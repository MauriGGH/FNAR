#!/usr/bin/env python3
"""Genera con voz sintética las líneas de voz que todavía no están grabadas.

Qué hace, en orden:

  1. Saca la lista de líneas pendientes de `docs/guion_voces.md` y de
     `data/voice_lines.gd`. Las llamadas de noche NO entran: esas se graban a
     mano.
  2. Cada línea se dice con edge-tts, con una voz de español de México y con
     la velocidad y el tono que le toque a ese personaje (ver VOCES).
  3. Si el personaje lo pide, la pasa por Applio con un modelo entrenado.
     Ahora mismo solo Rochis.
  4. La limpia con sox: normaliza a -3 dB y recorta los silencios de los
     extremos. A Rochis además le mete un eco ligero.
  5. La deja en assets/audio/<id>.ogg, mono y a 44.1 kHz.

**Nunca pisa un archivo que ya exista**, salvo que le pases --forzar. Así se
puede correr mil veces sin miedo a borrar una grabación de verdad.

Hace falta:
    pip install edge-tts
    sox   (en Debian/Ubuntu: sudo apt install sox libsox-fmt-all)

OJO: Godot no ve un audio nuevo hasta que lo importa. Si tienes el editor
abierto, lo hace solo al volver a la ventana. Si no, cuando termines:
    godot --headless --import

Uso:
    python3 tools/generar_voces.py --listar          # qué haría, sin hacerlo
    python3 tools/generar_voces.py                   # genera lo que falta
    python3 tools/generar_voces.py --personaje rochis
    python3 tools/generar_voces.py --id mamador_ok_1 --forzar
    python3 tools/generar_voces.py --sin-applio      # solo la voz sintética
"""

import argparse
import asyncio
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
GUION = RAIZ / "docs/guion_voces.md"
VOICE_LINES = RAIZ / "data/voice_lines.gd"
SALIDA = RAIZ / "assets/audio"

# --- Las voces, por personaje ------------------------------------------------
# Para cambiarle la voz a alguien, toca su línea de aquí y vuelve a correr el
# script con --forzar. Las voces de México que trae edge-tts son:
#   es-MX-JorgeNeural    (hombre)
#   es-MX-DaliaNeural    (mujer)
# Y si quieres probar otro acento, `edge-tts --list-voices | grep es-` las lista
# todas. `rate` y `pitch` van como los quiere edge-tts: un porcentaje y un
# desplazamiento en Hz, los dos con signo.
VOCES = {
    "barcosa": {
        "voz": "es-MX-JorgeNeural",
        "rate": "+18%",     # habla rápido: está molesto y con prisa
        "pitch": "+15Hz",
        "applio": False,
    },
    "mamador": {
        "voz": "es-MX-JorgeNeural",
        "rate": "-8%",      # seco y sin prisa, de autoridad
        "pitch": "-30Hz",
        "applio": False,
    },
    "urena": {
        "voz": "es-MX-JorgeNeural",
        "rate": "-14%",     # meloso: arrastra las palabras
        "pitch": "-8Hz",
        "applio": False,
    },
    "rochis": {
        "voz": "es-MX-JorgeNeural",
        "rate": "-12%",     # lento y tranquilo, de profesor mayor
        "pitch": "-18Hz",
        "applio": True,
        "eco": True,
    },
    "armando": {
        "voz": "es-MX-JorgeNeural",
        "rate": "+10%",     # locutor de curso de internet
        "pitch": "+8Hz",
        "applio": False,
    },
    "santi": {
        "voz": "es-MX-JorgeNeural",
        "rate": "-6%",      # chavo joven, ahogado dentro de la botarga
        "pitch": "+25Hz",
        "applio": False,
    },
    # El que no esté arriba usa esto.
    "_default": {
        "voz": "es-MX-JorgeNeural",
        "rate": "+0%",
        "pitch": "+0Hz",
        "applio": False,
    },
}

# --- Applio ------------------------------------------------------------------
# Un modelo por personaje. Los parámetros son los que pediste; para probar otro
# modelo basta con cambiar las rutas. Los nombres de las opciones salen de
# `python core.py infer --help`, no están inventados.
APPLIO_DIR = Path("/home/artemis/Applio")
APPLIO_PYTHON = APPLIO_DIR / ".venv/bin/python"
MODELOS = {
    "rochis": {
        "pth": APPLIO_DIR / "logs/rochis/rochis_150e_3300s.pth",
        "index": APPLIO_DIR / "logs/rochis/rochis.index",
        "pitch": -4,
        "index_rate": 0.6,
        "protect": 0.4,
        "f0_method": "rmvpe",
    },
}

# --- Posproceso con sox ------------------------------------------------------
NIVEL_DB = -3.0
## Lo que tiene que estar por debajo para contar como silencio, y cuánto aire
## se deja a los lados para que no suene cortado de golpe.
SILENCIO_UMBRAL = "1%"
SILENCIO_AIRE = "0.08"
## El eco de Rochis: un solo rebote a 120 ms, suficiente para que suene al
## fondo del cubículo sin volverse una cueva.
ECO = ["echo", "0.8", "0.7", "120", "0.35"]

FRECUENCIA = "44100"

## Las secciones del guion que NO se generan aquí.
SECCIONES_SALTADAS = ("llamadas",)
## Un texto con corchetes es una acotación o un hueco variable ([NOMBRE], [N],
## "[respiración en el cristal]"), no una línea que se pueda grabar.
CORCHETES = re.compile(r"\[.+?\]")


def dedo(mensaje: str) -> None:
    print("  -> " + mensaje)


# --- De dónde salen las líneas ----------------------------------------------

def lineas_del_guion() -> dict:
    """Las filas del guion que traen un texto «entre comillas» y un archivo."""
    if not GUION.is_file():
        print("No encuentro", GUION)
        return {}
    encontradas = {}
    texto = GUION.read_text(encoding="utf-8")
    for bloque in re.split(r"^## ", texto, flags=re.M)[1:]:
        titulo = bloque.split("\n", 1)[0].strip()
        plano = titulo.lower()
        if any(saltar in plano for saltar in SECCIONES_SALTADAS):
            continue
        personaje = _personaje_de(titulo)
        for linea in bloque.splitlines():
            if not linea.startswith("|"):
                continue
            dicho = re.search(r"«(.+?)»", linea)
            archivos = re.findall(r"`([a-z0-9_/]+\.ogg)`", linea)
            if not dicho or not archivos:
                continue
            identificador = Path(archivos[0]).stem
            encontradas[identificador] = {
                "texto": dicho.group(1).strip(),
                "archivo": archivos[0],
                "personaje": personaje,
            }
    return encontradas


def _personaje_de(titulo: str) -> str:
    """Saca el personaje del título de la sección: '4. Barcosa' -> barcosa."""
    limpio = re.sub(r"^\d+\.\s*", "", titulo).lower()
    for nombre in VOCES:
        if nombre.startswith("_"):
            continue
        if nombre in limpio.replace("ñ", "n").replace("ureña", "urena"):
            return nombre
    if "ureña" in limpio or "urena" in limpio:
        return "urena"
    if "juan" in limpio:
        return "juan"
    if "santi" in limpio or "botarga" in limpio:
        return "santi"
    if "mago" in limpio or "audel" in limpio:
        return "audel"
    return "_default"


def lineas_del_juego() -> dict:
    """Las de data/voice_lines.gd, que son las que manda el código."""
    if not VOICE_LINES.is_file():
        return {}
    texto = VOICE_LINES.read_text(encoding="utf-8")
    bloque = re.search(r"const LINES: Dictionary = \{\n(.*?)\n\}", texto, re.S)
    if not bloque:
        return {}
    encontradas = {}
    for identificador, dicho in re.findall(r'"([a-z0-9_]+)": "(.+?)",', bloque.group(1)):
        encontradas[identificador] = {
            "texto": dicho,
            "archivo": "voces/%s.ogg" % identificador,
            "personaje": identificador.split("_")[0],
        }
    return encontradas


def recoger() -> list:
    """Todas las líneas, sin repetir. El código manda sobre el guion."""
    todas = lineas_del_guion()
    todas.update(lineas_del_juego())
    salida = []
    for identificador in sorted(todas):
        entrada = dict(todas[identificador])
        entrada["id"] = identificador
        if entrada["personaje"] not in VOCES:
            entrada["personaje"] = "_default"
        salida.append(entrada)
    return salida


# --- Generación ---------------------------------------------------------------

def hablar(texto: str, ajuste: dict, destino: Path) -> bool:
    """edge-tts a un mp3 temporal."""
    try:
        import edge_tts
    except ImportError:
        print("Falta edge-tts. Instálalo con:  pip install edge-tts")
        sys.exit(1)

    async def correr() -> None:
        voz = edge_tts.Communicate(
            texto, ajuste["voz"], rate=ajuste["rate"], pitch=ajuste["pitch"])
        await voz.save(str(destino))

    try:
        asyncio.run(correr())
    except Exception as error:   # red caída, voz que no existe...
        dedo("edge-tts falló: %s" % error)
        return False
    return destino.is_file() and destino.stat().st_size > 0


def pasar_por_applio(personaje: str, entrada: Path, salida: Path) -> bool:
    """Convierte la voz con el modelo entrenado de ese personaje."""
    modelo = MODELOS.get(personaje)
    if modelo is None:
        dedo("no hay modelo de Applio para %s" % personaje)
        return False
    for ruta in (APPLIO_PYTHON, APPLIO_DIR / "core.py", modelo["pth"], modelo["index"]):
        if not Path(ruta).exists():
            dedo("falta %s" % ruta)
            return False
    orden = [
        str(APPLIO_PYTHON), "core.py", "infer",
        "--input-path", str(entrada),
        "--output-path", str(salida),
        "--pth-path", str(modelo["pth"]),
        "--index-path", str(modelo["index"]),
        "--pitch", str(modelo["pitch"]),
        "--index-rate", str(modelo["index_rate"]),
        "--protect", str(modelo["protect"]),
        "--f0-method", modelo["f0_method"],
        "--export-format", "WAV",
        # clean_audio va desactivado: es un flag, así que basta con no ponerlo.
    ]
    hecho = subprocess.run(orden, cwd=APPLIO_DIR, capture_output=True, text=True)
    if hecho.returncode != 0 or not salida.is_file():
        dedo("Applio falló: %s" % (hecho.stderr or hecho.stdout).strip().splitlines()[-1:])
        return False
    return True


def rematar(entrada: Path, salida: Path, eco: bool) -> bool:
    """sox: mono, 44.1 kHz, normalizado, sin silencios y con eco si toca."""
    orden = ["sox", str(entrada), "-c", "1", "-r", FRECUENCIA, str(salida)]
    # El orden importa: primero se recortan los silencios del original, luego
    # se añade el eco (si no, el recorte de la cola se lo comería) y al final
    # se normaliza, para que el eco no se salga del margen.
    orden += [
        "silence", "1", "0.05", SILENCIO_UMBRAL,
        "reverse", "silence", "1", SILENCIO_AIRE, SILENCIO_UMBRAL, "reverse",
    ]
    if eco:
        orden += ECO
    orden += ["gain", "-n", str(NIVEL_DB)]
    hecho = subprocess.run(orden, capture_output=True, text=True)
    if hecho.returncode != 0:
        dedo("sox falló: %s" % hecho.stderr.strip())
        return False
    return salida.is_file()


def generar(entrada: dict, usar_applio: bool) -> bool:
    personaje = entrada["personaje"]
    ajuste = VOCES.get(personaje, VOCES["_default"])
    destino = SALIDA / entrada["archivo"]
    destino.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as carpeta:
        temporal = Path(carpeta)
        crudo = temporal / "crudo.mp3"
        if not hablar(entrada["texto"], ajuste, crudo):
            return False
        fuente = crudo
        if usar_applio and ajuste.get("applio"):
            convertido = temporal / "applio.wav"
            # edge-tts da mp3 y Applio quiere algo que pueda leer: wav.
            wav = temporal / "crudo.wav"
            subprocess.run(["sox", str(crudo), "-r", FRECUENCIA, "-c", "1", str(wav)],
                           capture_output=True)
            if pasar_por_applio(personaje, wav, convertido):
                fuente = convertido
            else:
                dedo("sigo con la voz sintética sin convertir")
        return rematar(fuente, destino, bool(ajuste.get("eco")))


# --- Programa -----------------------------------------------------------------

def main() -> int:
    opciones = argparse.ArgumentParser(
        description="Genera con voz sintética las líneas que faltan por grabar.")
    opciones.add_argument("--listar", action="store_true",
                          help="solo enseña qué haría, sin generar nada")
    opciones.add_argument("--forzar", action="store_true",
                          help="vuelve a generar aunque el archivo ya exista")
    opciones.add_argument("--personaje", default="",
                          help="solo las de ese personaje (barcosa, mamador, ...)")
    opciones.add_argument("--id", default="",
                          help="solo esa línea, por su id")
    opciones.add_argument("--sin-applio", action="store_true",
                          help="no pasar nada por Applio, solo la voz sintética")
    argumentos = opciones.parse_args()

    if shutil.which("sox") is None:
        print("Falta sox. En Debian/Ubuntu:  sudo apt install sox libsox-fmt-all")
        return 1

    lineas = recoger()
    if argumentos.personaje:
        lineas = [l for l in lineas if l["personaje"] == argumentos.personaje]
    if argumentos.id:
        lineas = [l for l in lineas if l["id"] == argumentos.id]
    if not lineas:
        print("No hay ninguna línea que cuadre con eso.")
        return 1

    hechas = saltadas = fallidas = 0
    for entrada in lineas:
        destino = SALIDA / entrada["archivo"]
        existe = destino.is_file()
        marca = "ya está" if existe and not argumentos.forzar else "pendiente"
        if CORCHETES.search(entrada["texto"]):
            marca = "saltada (lleva [corchetes]: es una acotación o un hueco)"
        print("%-24s %-9s %-11s %s" % (
            entrada["id"], entrada["personaje"], marca, entrada["texto"][:44]))

        if argumentos.listar:
            continue
        if marca.startswith("saltada") or (existe and not argumentos.forzar):
            saltadas += 1
            continue
        if generar(entrada, not argumentos.sin_applio):
            dedo("escrito %s" % destino.relative_to(RAIZ))
            hechas += 1
        else:
            fallidas += 1

    if not argumentos.listar:
        print("\nGeneradas %d, saltadas %d, con error %d." % (hechas, saltadas, fallidas))
        if hechas:
            print("Acuérdate de que Godot las importe: abre el editor, o corre")
            print("  godot --headless --import")
    return 0


if __name__ == "__main__":
    sys.exit(main())
