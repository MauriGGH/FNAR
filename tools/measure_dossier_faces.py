#!/usr/bin/env python3
"""Mide dónde está la foto de cada profe dentro de su expediente.

Los expedientes de assets/art/extras/ son la escena completa (la carpeta, la
hoja y el plano) y traen pegada una foto tipo polaroid en blanco y negro. La
Custom Night enseña **solo esa cara**, así que hay que saber en qué parte de la
imagen cae: eso es lo que mide este programa.

Cómo la encuentra: la hoja es sepia y el plano azul, pero la foto es gris de
verdad (los tres canales casi iguales). Busca el bloque más grande de píxeles
grises que no sean casi blancos (el marco de la polaroid lo es) y devuelve su
recuadro, normalizado sobre el tamaño de la imagen.

Los valores se copian a mano a data/custom_night_faces.gd.

Uso:  python3 tools/measure_dossier_faces.py
"""

import sys
from pathlib import Path

from PIL import Image

EXTRAS_DIR = Path(__file__).resolve().parent.parent / "assets/art/extras"
# Los ocho profes, con el mismo id que usa el código.
CHARACTERS = [
    "barcosa", "mamador", "urena", "rochis",
    "audel", "juan", "armando", "come_trabas",
]

# Cuándo se considera gris un píxel y cuándo ya es el marco blanco.
MAX_CHANNEL_SPREAD = 14
MAX_BRIGHTNESS = 228
MIN_BRIGHTNESS = 8
# La foto está pegada en la hoja, que ocupa la mitad izquierda.
SEARCH_BOX = (0.25, 0.14, 0.55, 0.66)
# Una fila o columna cuenta como parte de la foto si tiene al menos esta parte
# de los píxeles grises que tiene la fila o la columna más gris de todas. Se
# mide contra el máximo y no contra el ancho de la búsqueda, porque la foto
# ocupa solo un cacho de ella.
MIN_RUN = 0.35


def photo_box(image):
    """El recuadro de la foto en blanco y negro, en píxeles."""
    width, height = image.size
    left = int(SEARCH_BOX[0] * width)
    top = int(SEARCH_BOX[1] * height)
    right = int(SEARCH_BOX[2] * width)
    bottom = int(SEARCH_BOX[3] * height)
    pixels = image.load()

    grey = []
    for y in range(top, bottom):
        row = []
        for x in range(left, right):
            r, g, b = pixels[x, y][:3]
            spread = max(r, g, b) - min(r, g, b)
            value = (r + g + b) // 3
            row.append(spread <= MAX_CHANNEL_SPREAD
                       and MIN_BRIGHTNESS <= value <= MAX_BRIGHTNESS)
        grey.append(row)

    row_counts = [sum(row) for row in grey]
    column_counts = [sum(row[x] for row in grey) for x in range(right - left)]
    if not any(row_counts) or not any(column_counts):
        return None
    row_floor = MIN_RUN * max(row_counts)
    column_floor = MIN_RUN * max(column_counts)
    rows = [y for y, count in enumerate(row_counts) if count >= row_floor]
    columns = [x for x, count in enumerate(column_counts) if count >= column_floor]
    if not rows or not columns:
        return None
    return (left + columns[0], top + rows[0],
            columns[-1] - columns[0] + 1, rows[-1] - rows[0] + 1)


def main():
    if not EXTRAS_DIR.is_dir():
        print("No está %s" % EXTRAS_DIR)
        return 1
    print("## La foto de cada expediente, medida sobre la imagen")
    print("## (x, y, ancho, alto, normalizados)")
    for character in CHARACTERS:
        path = EXTRAS_DIR / ("expediente_%s.png" % character)
        if not path.is_file():
            print('\t"%s": null,   # falta %s' % (character, path.name))
            continue
        with Image.open(path) as handle:
            image = handle.convert("RGB")
            box = photo_box(image)
            width, height = image.size
        if box is None:
            print('\t"%s": null,   # no se encontró la foto' % character)
            continue
        print('\t"%s": Rect2(%.4f, %.4f, %.4f, %.4f),   # %d x %d px'
              % (character, box[0] / width, box[1] / height,
                 box[2] / width, box[3] / height, box[2], box[3]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
