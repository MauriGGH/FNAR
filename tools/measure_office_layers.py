#!/usr/bin/env python3
"""Mide las capas de la vista central de la oficina, una sola vez.

Saca dos cosas, que luego se copian a mano a data/office_layers.gd:

1. El rectángulo que ocupa de verdad cada profe dentro de su capa (el recuadro
   de los píxeles que no son transparentes), en coordenadas normalizadas. El
   juego lo usa para saber si el cono de la linterna le está dando a ese profe.

2. Dónde tiene el ojo Armando: el píxel naranja más brillante de centro_armando,
   que es donde el juego pinta el puntito que parpadea en la oscuridad.

Uso:  python3 tools/measure_office_layers.py
"""

import sys
from pathlib import Path

from PIL import Image

LAYERS_DIR = Path(__file__).resolve().parent.parent / "assets/art/office/layers"
# Las capas de la vista central, en el orden en que se enseñan.
LAYERS = [
    "centro_mamador", "centro_barcosa", "centro_audel",
    "centro_urena", "centro_juan", "centro_armando",
]
# Un píxel cuenta como parte del profe a partir de esta opacidad.
ALPHA_FLOOR = 24
# Para el ojo: qué tan naranja tiene que ser (rojo por encima de verde y azul).
EYE_MIN_RED = 120
EYE_MIN_RATIO = 1.25


def opaque_box(image):
    """El recuadro de lo que no es transparente, normalizado."""
    alpha = image.getchannel("A")
    box = alpha.point(lambda value: 255 if value >= ALPHA_FLOOR else 0).getbbox()
    if box is None:
        return None
    left, top, right, bottom = box
    width, height = image.size
    return (left / width, top / height,
            (right - left) / width, (bottom - top) / height)


def brightest_orange(image):
    """El píxel más naranja y más brillante: el ojo de Armando."""
    width, height = image.size
    pixels = image.load()
    best = None
    best_score = -1.0
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha < ALPHA_FLOOR or red < EYE_MIN_RED:
                continue
            # Naranja: el rojo manda sobre el verde, y el verde sobre el azul.
            if green <= 0 or red < green * EYE_MIN_RATIO or green < blue:
                continue
            score = float(red) - float(blue)
            if score > best_score:
                best_score = score
                best = (x, y, red, green, blue)
    if best is None:
        return None
    x, y, red, green, blue = best
    return (x / width, y / height, red, green, blue)


def main():
    if not LAYERS_DIR.is_dir():
        print("no encuentro", LAYERS_DIR)
        return 1
    print("## Rectángulos de cada capa (x, y, ancho, alto normalizados)")
    for name in LAYERS:
        path = LAYERS_DIR / f"{name}.png"
        if not path.is_file():
            print(f'  # falta {name}.png')
            continue
        with Image.open(path) as handle:
            image = handle.convert("RGBA")
            box = opaque_box(image)
            size = image.size
        if box is None:
            print(f'  # {name}: la capa está vacía')
            continue
        print('  "%s": Rect2(%.4f, %.4f, %.4f, %.4f),   # %dx%d'
              % (name, box[0], box[1], box[2], box[3], size[0], size[1]))

    print()
    print("## El ojo de Armando")
    path = LAYERS_DIR / "centro_armando.png"
    if not path.is_file():
        print("  # falta centro_armando.png")
        return 0
    with Image.open(path) as handle:
        found = brightest_orange(handle.convert("RGBA"))
    if found is None:
        print("  # no hay ningún píxel naranja claro en la capa")
        return 0
    print("  Vector2(%.4f, %.4f)   # rgb(%d, %d, %d)"
          % (found[0], found[1], found[2], found[3], found[4]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
