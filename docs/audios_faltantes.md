# Audios que faltan

Los sonidos del catálogo (`data/sounds.gd`) que todavía no tienen archivo en
`assets/audio/`. Mientras falten, el juego usa el provisional que genera
`scripts/audio/tone_builder.gd`, y los que no tienen provisional sencillamente
no suenan.

**Para meter uno:** deja el archivo con ese nombre exacto en `assets/audio/` y
corre `godot --headless --import`. No hay que tocar código.

Esta lista la escribe el panel de pruebas (F1 → Audio → «Escribir la lista de
audios que faltan»); no se edita a mano.

Faltan **23 de 111**. Generado desde el catálogo.

## Sin archivo y sin provisional (no suena nada)

| id | archivo que se espera | bus | cómo debe sonar |
| --- | --- | --- | --- |
| `llamada_noche2` | `llamadas/llamada_noche2.ogg` | Voces | La llamada entera de la noche 2 (solo voz). Guion en docs/guion_voces.md. |
| `llamada_noche3` | `llamadas/llamada_noche3.ogg` | Voces | La llamada entera de la noche 3 (solo voz). Guion en docs/guion_voces.md. |
| `llamada_noche4` | `llamadas/llamada_noche4.ogg` | Voces | La llamada entera de la noche 4 (solo voz). Guion en docs/guion_voces.md. |
| `llamada_noche5` | `llamadas/llamada_noche5.ogg` | Voces | La llamada entera de la noche 5 (solo voz). Guion en docs/guion_voces.md. |
| `llamada_noche6` | `llamadas/llamada_noche6.ogg` | Voces | La llamada entera de la noche 6 (solo voz). Guion en docs/guion_voces.md. |

## Sin archivo, pero con provisional por código

| id | archivo que se espera | bus | cómo debe sonar |
| --- | --- | --- | --- |
| `ticket_nuevo` | `ticket_nuevo.ogg` | Efectos | Campanita corta de aviso de sistema, dos notas que suben. |
| `tono_ocupado` | `tono_ocupado.ogg` | Efectos | Tono de ocupado de teléfono fijo, dos o tres pitidos. |
| `campana_escuela` | `campana_escuela.ogg` | Efectos | Campana de escuela con aplausos de fondo. |
| `ninos_yay` | `ninos_yay.ogg` | Efectos | Niños gritando «yeeey», contentos, 1 o 2 s. Entra al acabarse el despertador. |
| `ambiente_oficina` | `ambiente_oficina.ogg` | Ambiente | Zumbido de lámparas y ventilador de oficina, en bucle sin corte. |
| `ambiente_pasillo` | `ambiente_pasillo.ogg` | Ambiente | Aire de pasillo vacío de noche, en bucle sin corte, muy tenue. |
| `estatica_camara` | `estatica_camara.ogg` | Ambiente | Estática de televisión vieja, en bucle sin corte, suave. |
| `arcade_nivel1` | `arcade_nivel1.ogg` | Música | Chiptune de 8 bits de la maquinita, nivel 1: alegre, de posada. |
| `arcade_nivel2` | `arcade_nivel2.ogg` | Música | La misma idea para el nivel 2, pero ya desafinada: algo va mal. |
| `arcade_nivel3` | `arcade_nivel3.ogg` | Música | Nivel 3: sin melodía, solo un zumbido grave que no para. |
| `arcade_salto` | `arcade_salto.ogg` | Efectos | Pitido de 8 bits al saltar, de los que suben. |
| `arcade_recoge` | `arcade_recoge.ogg` | Efectos | Pitido corto de 8 bits al recoger algo. |
| `arcade_bip` | `arcade_bip.ogg` | Efectos | El bip de arranque de la maquinita, con su estática. |
| `arcade_cajita` | `arcade_cajita.ogg` | Música | La cajita musical distorsionada del final del nivel 3. |
| `menu_blip` | `menu_blip.ogg` | Efectos | Pitido corto y seco de moverse por un menú de consola vieja. |
| `tecla_maquina` | `tecla_maquina.ogg` | Efectos | Golpe de una tecla de máquina de escribir. Respaldo de las tres de abajo. |
| `urena_banos` | `lejos/urena_banos.ogg` | Lejos | Agua de lavabo corriendo, lejos, en bucle. |
| `armando_modem` | `lejos/armando_modem.ogg` | Lejos | Módem de 56k negociando, distorsionado y lejos. |
