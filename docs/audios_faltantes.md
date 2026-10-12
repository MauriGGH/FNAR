# Audios que faltan

Los sonidos del catálogo (`data/sounds.gd`) que todavía no tienen archivo en
`assets/audio/`. Mientras falten, el juego usa el provisional que genera
`scripts/audio/tone_builder.gd`, y los que no tienen provisional sencillamente
no suenan.

**Para meter uno:** deja el archivo con ese nombre exacto en `assets/audio/` y
corre `godot --headless --import`. No hay que tocar código.

Esta lista la escribe el panel de pruebas (F1 → Audio → «Escribir la lista de
audios que faltan»); no se edita a mano.

Faltan **24 de 99**. Generado desde el catálogo.

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
| `breaker_palanca` | `breaker_palanca.ogg` | Efectos | Palanca de tablero eléctrico bajando: dos clacs pesados. |
| `estatica_camara` | `estatica_camara.ogg` | Ambiente | Estática de televisión vieja, en bucle sin corte, suave. |
| `menu_blip` | `menu_blip.ogg` | Efectos | Pitido corto y seco de moverse por un menú de consola vieja. |
| `tecla_maquina` | `tecla_maquina.ogg` | Efectos | Golpe de una tecla de máquina de escribir. Respaldo de las tres de abajo. |
| `urena_banos` | `lejos/urena_banos.ogg` | Lejos | Agua de lavabo corriendo, lejos, en bucle. |
| `juan_teclado` | `lejos/juan_teclado.ogg` | Lejos | Tecleo de teclado mecánico, lejos, en bucle. |
| `armando_modem` | `lejos/armando_modem.ogg` | Lejos | Módem de 56k negociando, distorsionado y lejos. |
| `audel_chispa` | `lejos/audel_chispa.ogg` | Lejos | Zumbido eléctrico con algún trueno, lejos, en bucle. |
| `rochis_silla` | `lejos/rochis_silla.ogg` | Lejos | Rechinido de una silla de oficina al moverse. |
| `lejos_portazo` | `lejos/lejos_portazo.ogg` | Lejos | Un portazo en otra parte del edificio. |
| `lejos_silla` | `lejos/lejos_silla.ogg` | Lejos | Una silla arrastrada en otro cuarto. |
| `lejos_risa` | `lejos/lejos_risa.ogg` | Lejos | Una risa corta, muy lejos, imposible de ubicar. |
| `lejos_platos` | `lejos/lejos_platos.ogg` | Lejos | Platos y cubiertos en la cafetería vacía. |
