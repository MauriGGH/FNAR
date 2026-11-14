# El expediente: libro de lore

El libro de lore de *Five Nights at Rocha's*, actualizado a la **v0.9.2 beta**.

- **`Five_Nights_at_Rochas_Expediente.pdf`**: para imprimir. Media carta (5.5 x 8.5 in), 46 páginas,
  cada capítulo empieza en página impar. En la copiadora: media carta, doble cara, engrapado o engargolado.
- **`Five_Nights_at_Rochas_Expediente.epub`**: libro digital, para celular o lector
  (Google Play Libros, Libros de Apple, Send to Kindle). Validado con epubcheck.
- **Versión web**: el artifact de Claude, con el mismo texto.

El capítulo 9 trae los spoilers de la historia.

## Cómo regenerarlo

Todo el texto vive en `fuente/contenido.html`, y los tres formatos salen de ahí. Si cambia algo
del juego, se edita ese archivo y se corre, desde `fuente/`:

```
pip install weasyprint ebooklib pypdfium2
python3 build_print.py "$PWD"   # el PDF
python3 build_epub.py "$PWD"    # el EPUB (usa la portada del PDF, así que va después)
python3 build_web.py "$PWD"     # index.html de la versión web
```

Las imágenes están en `fuente/img/` y las fuentes (VT323, Special Elite y Spectral, todas OFL) en
`fuente/fonts/`. La carpeta lleva `.gdignore` para que Godot no importe nada de aquí.
