# Audios que faltan

Los sonidos del catálogo (`data/sounds.gd`) que todavía no tienen archivo en
`assets/audio/`. Mientras falten, el juego usa el provisional que genera
`scripts/audio/tone_builder.gd`, y los que no tienen provisional sencillamente
no suenan.

**Para meter uno:** deja el archivo con ese nombre exacto en `assets/audio/` y
corre `godot --headless --import`. No hay que tocar código.

Esta lista la escribe el panel de pruebas (F1 → Audio → «Escribir la lista de
audios que faltan»); no se edita a mano.

Faltan **14 de 123**. Generado desde el catálogo.

## Sin archivo y sin provisional (no suena nada)

Ninguno.

## Sin archivo, pero con provisional por código

| id | archivo que se espera | bus | cómo debe sonar |
| --- | --- | --- | --- |
| `tono_ocupado` | `tono_ocupado.ogg` | Efectos | Tono de ocupado de teléfono fijo, dos o tres pitidos. |
| `arcade_nivel1` | `arcade_nivel1.ogg` | Música | Chiptune de 8 bits de la maquinita, nivel 1: alegre, de posada. |
| `arcade_nivel2` | `arcade_nivel2.ogg` | Música | La misma idea para el nivel 2, pero ya desafinada: algo va mal. |
| `arcade_nivel3` | `arcade_nivel3.ogg` | Música | Nivel 3: sin melodía, solo un zumbido grave que no para. |
| `arcade_golpe` | `arcade_golpe.ogg` | Efectos | Golpe de 8 bits al perder una vida: un zumbido que baja de tono. |
| `arcade_salto` | `arcade_salto.ogg` | Efectos | Pitido de 8 bits al saltar, de los que suben. |
| `arcade_recoge` | `arcade_recoge.ogg` | Efectos | Pitido corto de 8 bits al recoger algo. |
| `arcade_bip` | `arcade_bip.ogg` | Efectos | El bip de arranque de la maquinita, con su estática. |
| `arcade_cajita` | `arcade_cajita.ogg` | Música | La cajita musical distorsionada del final del nivel 3. |
| `menu_blip` | `menu_blip.ogg` | Efectos | Pitido corto y seco de moverse por un menú de consola vieja. |
| `carta_toma` | `carta_toma.ogg` | Efectos | Una carta que se despega del montón: roce corto de cartón. |
| `carta_pone` | `carta_pone.ogg` | Efectos | Una carta que cae sobre el montón: palmadita seca de cartón. |
| `urena_banos` | `lejos/urena_banos.ogg` | Lejos | Agua de lavabo corriendo, lejos, en bucle. |
| `armando_modem` | `lejos/armando_modem.ogg` | Lejos | Módem de 56k negociando, distorsionado y lejos. |
