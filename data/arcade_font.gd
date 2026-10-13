class_name ArcadeFont
extends RefCounted

## La fuente de la maquinita: letras de 3x5 píxeles dibujadas a mano, una por
## una, con rectángulos de un píxel.
##
## ¿Por qué no VT323? Porque dentro del lienzo de 160x90 habría que pedirla a
## 10 px, y a ese tamaño el rasterizador la suaviza; al ampliar el lienzo siete
## veces con filtro nearest, ese suavizado se convierte en manchas grises y no
## se lee nada. Estas letras son píxeles enteros, así que al ampliarlas quedan
## como las de una consola de verdad. VT323 se sigue usando **fuera** del
## lienzo, donde se dibuja a su tamaño real.

## Lo alto que es todo y el hueco que queda entre dos letras. El ancho lo pone
## cada letra: casi todas son de tres píxeles, pero la M, la N y la W necesitan
## cuatro o no se distinguen entre ellas.
const GLYPH_HEIGHT: int = 5
const GAP: int = 1
const LINE_HEIGHT: int = 7

## Cada letra, en cinco renglones: `#` pinta, cualquier otra cosa no.
const GLYPHS: Dictionary = {
	"A": [".#.", "#.#", "###", "#.#", "#.#"],
	"B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"],
	"D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"],
	"F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"],
	"H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"],
	"J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"],
	# Estas tres van de cuatro píxeles: en tres, la N sale igual que la H.
	"M": ["#..#", "####", "####", "#..#", "#..#"],
	"N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
	"W": ["#..#", "#..#", "#..#", "####", ".##."],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."],
	"P": ["###", "#.#", "###", "#..", "#.."],
	"Q": [".#.", "#.#", "#.#", ".#.", "..#"],
	"R": ["###", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"],
	# La V se cierra dos renglones antes, para que no se confunda con la U.
	"V": ["#.#", "#.#", "#.#", ".#.", ".#."],
	"X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
	"Z": ["###", "..#", ".#.", "#..", "###"],
	# Las acentuadas llevan el acento en el primer renglón: no hay sitio arriba.
	"Á": ["..#", "###", "#.#", "###", "#.#"],
	"É": ["..#", "###", "##.", "#..", "###"],
	"Í": ["..#", "###", ".#.", ".#.", "###"],
	"Ó": ["..#", ".#.", "#.#", "#.#", ".#."],
	"Ú": ["..#", "#.#", "#.#", "#.#", "###"],
	"Ñ": ["####", "#..#", "####", "#..#", "#..#"],
	"0": ["###", "#.#", "#.#", "#.#", "###"],
	"1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"],
	"3": ["##.", "..#", ".#.", "..#", "##."],
	"4": ["#.#", "#.#", "###", "..#", "..#"],
	"5": ["###", "#..", "##.", "..#", "##."],
	"6": [".##", "#..", "###", "#.#", "###"],
	"7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"],
	"9": ["###", "#.#", "###", "..#", "##."],
	"/": ["..#", "..#", ".#.", "#..", "#.."],
	".": ["...", "...", "...", "...", ".#."],
	",": ["...", "...", "...", ".#.", "#.."],
	":": ["...", ".#.", "...", ".#.", "..."],
	"-": ["...", "...", "###", "...", "..."],
	"!": [".#.", ".#.", ".#.", "...", ".#."],
	"?": ["##.", "..#", ".#.", "...", ".#."],
	"'": [".#.", ".#.", "...", "...", "..."],
}


## Lo que ocupa un texto, para poder centrarlo.
static func width(text: String, scale: int = 1) -> float:
	var total: int = 0
	for i: int in text.length():
		total += _advance(text.substr(i, 1).to_upper())
	return float(maxi(total - GAP, 0) * scale)


## Lo que avanza el cursor después de una letra, con su hueco.
static func _advance(key: String) -> int:
	if not GLYPHS.has(key):
		return 3 + GAP  # El espacio y lo que no esté en la tabla.
	var rows: Array = GLYPHS[key]
	return String(rows[0]).length() + GAP


## Pinta el texto con su esquina superior izquierda en `at`.
static func draw_text(canvas: CanvasItem, at: Vector2, text: String, color: Color,
		scale: int = 1) -> void:
	var pixel: float = float(scale)
	var cursor: Vector2 = at.round()
	for i: int in text.length():
		var key: String = text.substr(i, 1).to_upper()
		if GLYPHS.has(key):
			var rows: Array = GLYPHS[key]
			for row: int in rows.size():
				var line: String = rows[row]
				for column: int in line.length():
					if line[column] != "#":
						continue
					canvas.draw_rect(Rect2(
						cursor + Vector2(float(column), float(row)) * pixel,
						Vector2(pixel, pixel)), color)
		cursor.x += float(_advance(key)) * pixel
