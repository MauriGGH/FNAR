#!/usr/bin/env python3
"""Genera assets/art/office/layers/oclusor_puerta.png una sola vez.

El problema: en la vista central, la lámina de la cortina se dibuja recortada
de la foto con la puerta cerrada y queda por encima de lo que en realidad está
más cerca de la cámara que la puerta (el mueble de la recepción, su base y los
perfiles verticales del cristal).

La solución: una máscara de oclusión. Dentro del rectángulo de la puerta se
buscan los píxeles donde la foto con la puerta abierta y la foto con la puerta
cerrada son casi iguales: si no cambian al bajar la cortina, es que hay algo
delante tapándola. Esos píxeles se guardan opacos con el color de la foto con
la puerta abierta, y todo lo demás queda transparente.

Un umbral por píxel a secas no sirve: las ranuras oscuras de la lámina se
parecen al vidrio oscuro de la puerta abierta y salen marcadas. Por eso, tras
el umbral va una apertura con un elemento VERTICAL, que borra las rayas
horizontales de las ranuras y deja en pie lo que es alto (el mueble y los
perfiles), y después se descartan las islas chicas.

Uso:  python3 tools/make_door_occluder.py
Deja la máscara en assets/art/office/layers/ y una vista previa con la máscara
en rojo en tools/preview/.
"""

import json
import pathlib
import sys

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter
from scipy import ndimage

ROOT = pathlib.Path(__file__).resolve().parent.parent

OPEN_IMAGE = ROOT / "assets/art/office/oficina_centro.jpeg"
CLOSED_IMAGE = ROOT / "assets/art/office/oficina_centro_cortina.png"
ZONES_FILE = ROOT / "data/oficina_zonas.json"
OUT_IMAGE = ROOT / "assets/art/office/layers/oclusor_puerta.png"
PREVIEW_DIR = ROOT / "tools/preview"

# Los mismos valores que door_shutter.gd: el área de la puerta en la foto y
# desde dónde empieza la lámina. Si allá cambian, aquí también.
IMAGE_AREA = (0.289, 0.293, 0.122, 0.391)
CURTAIN_TOP = 0.335

# Hasta cuánto pueden diferir dos píxeles para contarlos como "lo mismo".
DIFF_THRESHOLD = 11
# Alto del elemento vertical de la apertura, en píxeles.
OPENING_HEIGHT = 13
# Islas más chicas que esto se tiran.
MIN_AREA = 400
# Lo que se suaviza el borde de la máscara, en píxeles.
FEATHER = 1.4

# Zonas de data/oficina_zonas.json con las que se completa a mano lo que la
# comparación no alcance a ver. Se usan las que tengan este prefijo y un
# campo "polygon" con puntos normalizados.
MANUAL_PREFIX = "occluder_"


def load_pair():
    """Las dos fotos al tamaño de la de la puerta abierta."""
    open_image = Image.open(OPEN_IMAGE).convert("RGB")
    size = open_image.size
    closed_image = Image.open(CLOSED_IMAGE).convert("RGB").resize(size, Image.LANCZOS)
    return open_image, closed_image, size


def door_band(size):
    """El rectángulo de la lámina en píxeles: de CURTAIN_TOP hacia abajo."""
    width, height = size
    left = int(IMAGE_AREA[0] * width)
    right = int((IMAGE_AREA[0] + IMAGE_AREA[2]) * width)
    top = int(CURTAIN_TOP * height)
    bottom = int((IMAGE_AREA[1] + IMAGE_AREA[3]) * height)
    return left, top, right, bottom


def manual_polygons():
    """Los polígonos de relleno que haya en el JSON de zonas, normalizados."""
    if not ZONES_FILE.exists():
        return []
    zones = json.loads(ZONES_FILE.read_text()).get("zones", {})
    found = []
    for zone_id, zone in zones.items():
        if zone_id.startswith(MANUAL_PREFIX) and "polygon" in zone:
            found.append((zone_id, zone["polygon"]))
    return found


def build_mask(open_image, closed_image, size):
    """La máscara de oclusión, como arreglo de booleanos."""
    width, height = size
    left, top, right, bottom = door_band(size)
    difference = ImageChops.difference(open_image, closed_image).convert("L")
    difference = difference.filter(ImageFilter.MedianFilter(3))
    diff = np.asarray(difference, dtype=np.int16)

    mask = np.zeros((height, width), dtype=bool)
    mask[top:bottom, left:right] = diff[top:bottom, left:right] <= DIFF_THRESHOLD

    # Apertura vertical: se van las rayas de las ranuras, se quedan el mueble
    # y los perfiles, que son altos.
    mask = ndimage.binary_opening(mask, structure=np.ones((OPENING_HEIGHT, 1), dtype=bool))
    labels, count = ndimage.label(mask)
    if count:
        areas = ndimage.sum(mask, labels, range(1, count + 1))
        keep = [index + 1 for index, area in enumerate(areas) if area >= MIN_AREA]
        mask = np.isin(labels, keep)
    mask = ndimage.binary_closing(mask, structure=np.ones((5, 5), dtype=bool))

    # Lo que se haya completado a mano en el JSON de zonas.
    polygons = manual_polygons()
    if polygons:
        drawn = Image.new("L", size, 0)
        pen = ImageDraw.Draw(drawn)
        for zone_id, polygon in polygons:
            points = [(point[0] * width, point[1] * height) for point in polygon]
            pen.polygon(points, fill=255)
            print("  + polígono manual %s con %d puntos" % (zone_id, len(points)))
        mask |= np.asarray(drawn, dtype=bool)
        # El relleno manual tampoco sale del área de la lámina.
        band = np.zeros((height, width), dtype=bool)
        band[top:bottom, left:right] = True
        mask &= band
    return mask


def save_occluder(open_image, mask, size):
    """Los píxeles tapados con su color de la foto, el resto transparente."""
    alpha = Image.fromarray((mask * 255).astype("uint8"), "L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(FEATHER))
    out = open_image.convert("RGBA")
    out.putalpha(alpha)
    OUT_IMAGE.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT_IMAGE)
    return alpha


def save_previews(open_image, closed_image, mask, size):
    """Vistas previas para revisar la máscara a ojo."""
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    left, top, right, bottom = door_band(size)
    pad = 24
    crop = (left - pad, top - pad, right + pad, bottom + pad)
    mask_image = Image.fromarray((mask * 255).astype("uint8"), "L").crop(crop)

    base = closed_image.crop(crop)
    red = Image.new("RGB", base.size, (255, 0, 0))
    over = Image.composite(Image.blend(base, red, 0.7), base, mask_image)
    tiles = [open_image.crop(crop), base, over]
    zoom = 4
    tiles = [tile.resize((tile.width * zoom, tile.height * zoom), Image.NEAREST) for tile in tiles]
    gap = 8
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + gap * 2, tiles[0].height), (255, 255, 0))
    offset = 0
    for tile in tiles:
        sheet.paste(tile, (offset, 0))
        offset += tile.width + gap
    ImageEnhance.Brightness(sheet).enhance(2.1).save(PREVIEW_DIR / "oclusor_mascara.png")

    # Y cómo queda la lámina a media bajada, con y sin el oclusor.
    half = _simulate(open_image, closed_image, mask, size, 0.5, use_occluder=False)
    good = _simulate(open_image, closed_image, mask, size, 0.5, use_occluder=True)
    closed_sim = _simulate(open_image, closed_image, mask, size, 1.0, use_occluder=True)
    tiles = [image.crop(crop) for image in (half, good, closed_sim)]
    tiles = [tile.resize((tile.width * zoom, tile.height * zoom), Image.NEAREST) for tile in tiles]
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + gap * 2, tiles[0].height), (255, 255, 0))
    offset = 0
    for tile in tiles:
        sheet.paste(tile, (offset, 0))
        offset += tile.width + gap
    ImageEnhance.Brightness(sheet).enhance(2.1).save(PREVIEW_DIR / "oclusor_resultado.png")


def _simulate(open_image, closed_image, mask, size, progress, use_occluder):
    """Lo mismo que hace door_shutter.gd, para poder revisarlo aquí."""
    width, height = size
    left, _, right, bottom = door_band(size)
    area_top = int(IMAGE_AREA[1] * height)
    curtain_top = int(CURTAIN_TOP * height)
    out = open_image.copy()
    # La caja del rodillo, siempre.
    box = (left, area_top, right, curtain_top)
    out.paste(closed_image.crop(box), (left, area_top))
    # La lámina, lo que haya bajado.
    slat_bottom = curtain_top + int((bottom - curtain_top) * progress)
    if slat_bottom > curtain_top:
        slat = (left, curtain_top, right, slat_bottom)
        out.paste(closed_image.crop(slat), (left, curtain_top))
    if use_occluder:
        alpha = Image.fromarray((mask * 255).astype("uint8"), "L")
        alpha = alpha.filter(ImageFilter.GaussianBlur(FEATHER))
        out = Image.composite(open_image, out, alpha)
    return out


def main():
    if not OPEN_IMAGE.exists() or not CLOSED_IMAGE.exists():
        print("Faltan las fotos de la oficina", file=sys.stderr)
        return 1
    open_image, closed_image, size = load_pair()
    print("fotos a %dx%d" % size)
    left, top, right, bottom = door_band(size)
    print("banda de la lámina: x %d..%d  y %d..%d" % (left, right, top, bottom))
    mask = build_mask(open_image, closed_image, size)
    covered = mask[top:bottom, left:right].mean() * 100.0
    print("la máscara tapa el %.1f %% de la banda" % covered)
    save_occluder(open_image, mask, size)
    save_previews(open_image, closed_image, mask, size)
    print("escrito %s" % OUT_IMAGE.relative_to(ROOT))
    print("vistas previas en %s" % PREVIEW_DIR.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
