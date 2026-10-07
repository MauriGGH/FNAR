#!/usr/bin/env python3
"""Copia las hojas de referencia a los expedientes de Extras, una sola vez.

En art_refs/ están las hojas de referencia con las que se dibujó a cada
personaje. El menú de Extras las muestra como "expediente" de cada profe, y
las busca por el id que ya usa el código (el mismo de image_slug(): barcosa,
mamador, urena, juan, armando, rochis, audel, come_trabas).

Este script solo copia y renombra; no toca art_refs/, que se queda como
carpeta de trabajo fuera del juego (tiene su .gdignore para que Godot no la
importe). Se respeta la extensión original, y el cargador del juego acepta
png, jpg y jpeg.

Uso:  python3 tools/copy_dossiers.py
"""

import pathlib
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
REFS_DIR = ROOT / "art_refs"
OUT_DIR = ROOT / "assets/art/extras"

EXTENSIONS = (".png", ".jpg", ".jpeg")

# Hoja de referencia -> id del personaje en el código. De Mamador hay dos
# hojas; el expediente usa la primera.
REFS = {
    "ref_barcosa": "barcosa",
    "ref_mamador_1": "mamador",
    "ref_urena": "urena",
    "ref_rochis": "rochis",
    "ref_audel": "audel",
    "ref_juan": "juan",
    "ref_armando": "armando",
    "ref_cometrabas": "come_trabas",
}


def find_ref(name):
    """La hoja con la extensión que tenga."""
    for extension in EXTENSIONS:
        candidate = REFS_DIR / (name + extension)
        if candidate.exists():
            return candidate
    return None


def main():
    if not REFS_DIR.is_dir():
        print("No está la carpeta %s" % REFS_DIR, file=sys.stderr)
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    copied = 0
    for ref_name, character_id in sorted(REFS.items()):
        source = find_ref(ref_name)
        if source is None:
            print("  falta %s%s" % (ref_name, "|".join(EXTENSIONS)))
            continue
        target = OUT_DIR / ("expediente_%s%s" % (character_id, source.suffix))
        # Si antes se copió con otra extensión, esa sobra.
        for extension in EXTENSIONS:
            other = OUT_DIR / ("expediente_%s%s" % (character_id, extension))
            if other != target and other.exists():
                other.unlink()
                print("  quitado el duplicado %s" % other.name)
        shutil.copyfile(source, target)
        print("  %-16s -> %s" % (source.name, target.name))
        copied += 1

    extra = sorted(p.name for p in REFS_DIR.iterdir()
                   if p.suffix in EXTENSIONS and p.stem not in REFS)
    if extra:
        print("sin usar en art_refs/: %s" % ", ".join(extra))
    print("%d expedientes en %s" % (copied, OUT_DIR.relative_to(ROOT)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
