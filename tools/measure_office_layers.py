#!/usr/bin/env python3
"""Mide las capas de la vista central de la oficina, una sola vez.

Saca dos cosas, que luego se copian a mano a data/office_layers.gd:

1. El rectángulo que ocupa de verdad cada profe dentro de su capa, tanto en la
   vista central como en la derecha (el recuadro
   de los píxeles que no son transparentes), en coordenadas normalizadas. El
   juego lo usa para saber si el cono de la linterna le está dando a ese profe.

2. El conector RJ45 (`assets/art/office/rj45.png`): lo que de verdad se pinta
   dentro del PNG, para poder girarlo y escalarlo por su punta en el patch
   panel. Va a scenes/server_room/patch_panel_view.gd.

3. Dónde tiene el ojo Armando: el píxel naranja más brillante de centro_armando,
   que es donde el juego pinta el puntito que parpadea en la oscuridad.

Uso:  python3 tools/measure_office_layers.py
"""

import sys
from pathlib import Path

from PIL import Image

OFFICE_DIR = Path(__file__).resolve().parent.parent / "assets/art/office"
LAYERS_DIR = OFFICE_DIR / "layers"
# Las capas de la vista central, en el orden en que se enseñan.
LAYERS = [
    "centro_mamador", "centro_barcosa", "centro_audel",
    "centro_urena", "centro_juan", "centro_armando",
]
# Las capas de la vista derecha: el paso hacia los cubículos.
RIGHT_LAYERS = ["derecha_rochis", "derecha_come_trabas"]
# Las siluetas de los que se ven al otro lado del cristal.
SILHOUETTES = [
    "silueta_barcosa", "silueta_mamador", "silueta_urena",
    "silueta_juan", "silueta_armando",
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
    print("## Capas de la vista derecha (x, y, ancho, alto normalizados)")
    for name in RIGHT_LAYERS:
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
        # En el .gd van por el slug del profe, sin el nombre de la vista.
        print('  "%s": Rect2(%.4f, %.4f, %.4f, %.4f),   # %s, %dx%d'
              % (name.removeprefix("derecha_"), box[0], box[1], box[2], box[3],
                 name, size[0], size[1]))

    print()
    print("## Siluetas tras el cristal (x, y, ancho, alto normalizados)")
    boxes = {}
    for name in SILHOUETTES:
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
        boxes[name] = box
        print('  "%s": Rect2(%.4f, %.4f, %.4f, %.4f),   # %dx%d'
              % (name, box[0], box[1], box[2], box[3], size[0], size[1]))

    # Ninguna debería encimarse con otra: cada profe tiene su sitio.
    names = list(boxes)
    clashes = []
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            a, b = boxes[names[i]], boxes[names[j]]
            wide = min(a[0] + a[2], b[0] + b[2]) - max(a[0], b[0])
            tall = min(a[1] + a[3], b[1] + b[3]) - max(a[1], b[1])
            if wide > 0 and tall > 0:
                clashes.append(f"{names[i]} con {names[j]}")
    print("  # se enciman: " + (", ".join(clashes) if clashes else "ninguna"))

    print()
    print("## El conector RJ45 (en píxeles de la imagen)")
    plug = OFFICE_DIR / "rj45.png"
    if not plug.is_file():
        print("  # falta rj45.png")
    else:
        with Image.open(plug) as handle:
            image = handle.convert("RGBA")
            alpha = image.getchannel("A")
            box = alpha.point(lambda value: 255 if value >= ALPHA_FLOOR else 0).getbbox()
            size = image.size
        if box is None:
            print("  # rj45.png está vacío")
        else:
            left, top, right, bottom = box
            print("  PLUG_IMAGE_SIZE: Vector2(%.1f, %.1f)" % size)
            # El PNG trae conector y cable; el juego solo usa el conector, que
            # acaba donde empieza la funda azul.
            pixels = image.load()
            boot = bottom
            for y in range(top, bottom):
                row = [pixels[x, y] for x in range(size[0])
                       if pixels[x, y][3] >= ALPHA_FLOOR]
                if not row:
                    continue
                red = sum(p[0] for p in row) / len(row)
                blue = sum(p[2] for p in row) / len(row)
                if blue > red + 40:
                    boot = y
                    break
            print("  PLUG_BODY: Rect2(%.1f, %.1f, %.1f, %.1f)"
                  % (left, top, right - left, boot - top))

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
