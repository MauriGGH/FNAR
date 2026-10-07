#!/usr/bin/env python3
"""Inventario de las imágenes de cámara: qué estados tienen imagen y qué
imágenes no usa nadie.

El estado de una cámara se arma en tiempo de juego juntando los "tokens" que
aporta cada profe presente, en el orden fijo barcosa, mamador, urena, juan,
armando (ver camera_system.gd). Este script reconstruye todas las
combinaciones posibles a partir de lo que dice el código y las compara con
los archivos de assets/art/cameras/.

No toca nada: solo informa. Si una imagen aparece como no usada, casi siempre
es que el código la pide con otro nombre; eso se arregla en el código.

Uso:  python3 tools/check_camera_images.py
"""

import itertools
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CAMERAS_DIR = ROOT / "assets/art/cameras"
EXTENSIONS = (".png", ".jpg", ".jpeg")

# El orden fijo con el que se nombran los profes juntos en una cámara.
NAME_ORDER = ["barcosa", "mamador", "urena", "juan", "armando"]

# Con tantos profes o más, se muestra "SEÑAL SATURADA" y no hace falta imagen.
SATURATED_COUNT = 3
SATURATED_EXCEPTION_CAMERA = 13

# Estados de respaldo que el sistema busca cuando falta el exacto.
BASE_STATES = ["etapa0", "vacia", "base"]

# Qué puede aportar cada profe en cada cámara, según su camera_token().
# camara -> lista de listas: cada lista son las opciones de un profe (el ""
# significa "ese profe no está"). La combinación se une con "_".
TOKENS = {
    1: [["", "barcosa"], ["", "mamador", "mamador-acecho"], ["", "juan", "juan-acecho"],
        ["", "armando", "armando-acecho"]],
    2: [["", "barcosa-corriendo", "barcosa-golpeando"], ["", "mamador"], ["", "urena"],
        ["", "juan"], ["", "armando"]],
    3: [["sentado", "medio", "de_pie", "vacia"]],
    4: [["desplomada", "despertando", "vacia"]],
    5: [["", "audel", "audel-acecho"]],
    6: [["", "audel", "audel-acecho"]],
    7: [["", "mamador-escalera", "armando-escalera"]],
    8: [["", "mamador"], ["", "armando"]],
    9: [["", "armando"]],
    10: [["etapa0", "etapa1", "etapa2", "salio"]],
    11: [["", "urena", "urena-acecho"]],
    12: [["", "urena", "urena-acecho"]],
    13: [["", "mamador", "mamador-acecho"], ["", "juan", "juan-acecho"],
         ["", "armando", "armando-acecho"]],
}

# Capas y recortes que el código encima aparte del estado (camera_overlays.gd)
# y que por lo tanto también son imágenes usadas.
OVERLAYS = {
    2: ["cam02_cortina"],
    3: ["cam03_foto"],
}

# Cámaras que solo pasan por un profe a la vez según su ruta: en la CAM 7 el
# código recorta a uno solo, así que las combinaciones no existen.
SINGLE_TOKEN_CAMERAS = [7]


def states_for(camera):
    """Todos los estados posibles de una cámara, ya unidos con guion bajo."""
    groups = TOKENS.get(camera, [])
    states = set()
    for combination in itertools.product(*groups):
        present = [token for token in combination if token]
        if not present:
            continue
        if camera in SINGLE_TOKEN_CAMERAS and len(present) > 1:
            continue
        # Solo acecha el que se queda solo entre los activos, así que un
        # token de acecho nunca aparece acompañado.
        if len(present) > 1 and any(token.endswith("-acecho") for token in present):
            continue
        # La señal saturada no lleva imagen, salvo la excepción de la CAM 13.
        if len(present) >= SATURATED_COUNT and camera != SATURATED_EXCEPTION_CAMERA:
            continue
        states.add("_".join(present))
    return sorted(states)


def found_path(base):
    for extension in EXTENSIONS:
        candidate = CAMERAS_DIR / (base + extension)
        if candidate.exists():
            return candidate
    return None


def main():
    if not CAMERAS_DIR.is_dir():
        print("No está %s" % CAMERAS_DIR, file=sys.stderr)
        return 1

    on_disk = {}
    for path in sorted(CAMERAS_DIR.iterdir()):
        if path.suffix in EXTENSIONS:
            on_disk.setdefault(path.stem, []).append(path.name)

    used = set()
    print("=== (a) Estados por cámara ===")
    for camera in sorted(TOKENS):
        states = states_for(camera)
        base = [name for name in BASE_STATES if found_path("cam%02d_%s" % (camera, name))]
        have, missing = [], []
        for state in states:
            name = "cam%02d_%s" % (camera, state)
            if found_path(name):
                used.add(name)
                have.append(state)
            else:
                missing.append(state)
        for name in OVERLAYS.get(camera, []):
            if found_path(name):
                used.add(name)
        for name in BASE_STATES:
            full = "cam%02d_%s" % (camera, name)
            if found_path(full):
                used.add(full)
        print("  CAM %02d  %d de %d estados con imagen   respaldo: %s" % (
            camera, len(have), len(states), ", ".join(base) if base else "NINGUNO"))
        if have:
            print("      tiene:  %s" % ", ".join(have))
        if missing:
            print("      falta:  %s" % ", ".join(missing))
        extra = OVERLAYS.get(camera, [])
        if extra:
            print("      encima: %s" % ", ".join(
                "%s%s" % (name, "" if found_path(name) else " (FALTA)") for name in extra))

    print("\n=== (b) Imágenes que ningún estado usa ===")
    unused = sorted(set(on_disk) - used)
    if not unused:
        print("  ninguna: todas las imágenes de la carpeta las pide el código")
    for stem in unused:
        print("  %s  (archivo: %s)" % (stem, ", ".join(on_disk[stem])))

    duplicated = sorted(stem for stem, names in on_disk.items() if len(names) > 1)
    if duplicated:
        print("\n=== Mismo nombre con dos extensiones (se usa la primera: %s) ===" % ", ".join(EXTENSIONS))
        for stem in duplicated:
            print("  %s -> %s" % (stem, ", ".join(on_disk[stem])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
