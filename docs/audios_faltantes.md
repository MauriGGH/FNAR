# Audios que faltan

Los sonidos del catálogo (`data/sounds.gd`) que todavía no tienen archivo en
`assets/audio/`. Mientras falten, el juego usa el provisional que genera
`scripts/audio/tone_builder.gd`, y los que no tienen provisional sencillamente
no suenan.

**Para meter uno:** deja el archivo con ese nombre exacto en `assets/audio/` y
corre `godot --headless --import`. No hay que tocar código.

Esta lista la escribe el panel de pruebas (F1 → Audio → «Escribir la lista de
audios que faltan»); no se edita a mano.

Faltan **49 de 67**. Generado desde el catálogo.

## Sin archivo y sin provisional (no suena nada)

| id | archivo que se espera | bus | cómo debe sonar |
| --- | --- | --- | --- |
| `grito_barcosa` | `gritos/grito_barcosa.ogg` | Efectos | Grito de Barcosa al atraparte: hombre mayor, ronco y enojado. |
| `grito_urena` | `gritos/grito_urena.ogg` | Efectos | Grito de Ureña: agudo y baboso, casi una risa que se rompe. |
| `grito_rochis` | `gritos/grito_rochis.ogg` | Efectos | Grito de Rochis: seco y grave, de pocas palabras. |
| `grito_juan` | `gritos/grito_juan.ogg` | Efectos | Grito de Juan.exe: chillido corto con un pitido digital encima. |
| `grito_armando` | `gritos/grito_armando.ogg` | Efectos | Grito de Armando: con reverb de micrófono malo y saturado. |
| `grito_cometrabas` | `gritos/grito_cometrabas.ogg` | Efectos | Grito de la botarga: coro de voces apagadas dentro de la felpa. |
| `grito_audel` | `gritos/grito_audel.ogg` | Efectos | Grito del Mago Eléctrico: chispazo eléctrico y una carcajada. |
| `grito_base_1` | `gritos/grito_base_1.ogg` | Efectos | Grito de jumpscare de reserva (1 de 3), fuerte y saturado. |
| `grito_base_2` | `gritos/grito_base_2.ogg` | Efectos | Grito de jumpscare de reserva (2 de 3), distinto al 1. |
| `grito_base_3` | `gritos/grito_base_3.ogg` | Efectos | Grito de jumpscare de reserva (3 de 3), distinto a los otros dos. |
| `llamada_noche2` | `llamadas/llamada_noche2.ogg` | Voces | La llamada entera de la noche 2 (solo voz). Guion en docs/guion_voces.md. |
| `llamada_noche3` | `llamadas/llamada_noche3.ogg` | Voces | La llamada entera de la noche 3 (solo voz). Guion en docs/guion_voces.md. |
| `llamada_noche4` | `llamadas/llamada_noche4.ogg` | Voces | La llamada entera de la noche 4 (solo voz). Guion en docs/guion_voces.md. |
| `llamada_noche5` | `llamadas/llamada_noche5.ogg` | Voces | La llamada entera de la noche 5 (solo voz). Guion en docs/guion_voces.md. |
| `llamada_noche6` | `llamadas/llamada_noche6.ogg` | Voces | La llamada entera de la noche 6 (solo voz). Guion en docs/guion_voces.md. |

## Sin archivo, pero con provisional por código

| id | archivo que se espera | bus | cómo debe sonar |
| --- | --- | --- | --- |
| `ticket_nuevo` | `ticket_nuevo.ogg` | Efectos | Campanita corta de aviso de sistema, dos notas que suben. |
| `grito` | `grito.ogg` | Efectos | Grito genérico de jumpscare, agudo y saturado. Es el último recurso. |
| `tono_ocupado` | `tono_ocupado.ogg` | Efectos | Tono de ocupado de teléfono fijo, dos o tres pitidos. |
| `despertador` | `despertador.ogg` | Efectos | Campanadas de reloj despertador de los de cuerda, 2 o 3 s. |
| `campana_escuela` | `campana_escuela.ogg` | Efectos | Campana de escuela con aplausos de fondo. |
| `ninos_yay` | `ninos_yay.ogg` | Efectos | Niños gritando «yeeey», contentos, 1 o 2 s. Entra al acabarse el despertador. |
| `menu_musica` | `menu_musica.ogg` | Música | Música del menú: zumbido grave y lento, inquietante, en bucle sin corte. |
| `pasos_acercandose` | `pasos_acercandose.ogg` | Efectos | Tres pasos pesados que se acercan en la oscuridad y paran. |
| `se_aleja` | `se_aleja.ogg` | Efectos | Alguien que se despega del cristal y se va arrastrando los pies. |
| `golpe_grave` | `golpe_grave.ogg` | Efectos | Golpe grave y seco, de los que pegan un susto. Medio segundo. |
| `golpe_grave_menu` | `golpe_grave.ogg` | Efectos | El mismo golpe, para el tic del menú (va aparte por su volumen). |
| `ambiente_oficina` | `ambiente_oficina.ogg` | Ambiente | Zumbido de lámparas y ventilador de oficina, en bucle sin corte. |
| `ambiente_pasillo` | `ambiente_pasillo.ogg` | Ambiente | Aire de pasillo vacío de noche, en bucle sin corte, muy tenue. |
| `puerta_cortina` | `puerta_cortina.ogg` | Efectos | Cortina metálica de local bajando o subiendo, con su traqueteo. |
| `golpes_cortina` | `golpes_cortina.ogg` | Efectos | Un puñetazo contra la cortina metálica, con resonancia. |
| `camara_cambio` | `camara_cambio.ogg` | Efectos | Clac de relé y zumbido corto al cambiar de cámara. |
| `linterna_click` | `linterna_click.ogg` | Efectos | Clic seco de interruptor de linterna. |
| `breaker_palanca` | `breaker_palanca.ogg` | Efectos | Palanca de tablero eléctrico bajando: dos clacs pesados. |
| `mamador_brecha` | `mamador_brecha.ogg` | Efectos | Puerta derribada de una patada y gritos de un operativo entrando. Un segundo. |
| `estatica_camara` | `estatica_camara.ogg` | Ambiente | Estática de televisión vieja, en bucle sin corte, suave. |
| `menu_blip` | `menu_blip.ogg` | Efectos | Pitido corto y seco de moverse por un menú de consola vieja. |
| `tecla_maquina` | `tecla_maquina.ogg` | Efectos | Golpe de una tecla de máquina de escribir. Respaldo de las tres de abajo. |
| `barcosa_corre` | `lejos/barcosa_corre.ogg` | Lejos | Pasos corriendo por un pasillo, acercándose, en bucle: suenan toda su carrera. |
| `mamador_pasos` | `lejos/mamador_pasos.ogg` | Lejos | Botas pesadas y un radio con estática, lejos. |
| `urena_banos` | `lejos/urena_banos.ogg` | Lejos | Agua de lavabo corriendo, lejos, en bucle. |
| `juan_teclado` | `lejos/juan_teclado.ogg` | Lejos | Tecleo de teclado mecánico, lejos, en bucle. |
| `armando_modem` | `lejos/armando_modem.ogg` | Lejos | Módem de 56k negociando, distorsionado y lejos. |
| `audel_chispa` | `lejos/audel_chispa.ogg` | Lejos | Zumbido eléctrico con algún trueno, lejos, en bucle. |
| `rochis_silla` | `lejos/rochis_silla.ogg` | Lejos | Rechinido de una silla de oficina al moverse. |
| `lejos_portazo` | `lejos/lejos_portazo.ogg` | Lejos | Un portazo en otra parte del edificio. |
| `lejos_silla` | `lejos/lejos_silla.ogg` | Lejos | Una silla arrastrada en otro cuarto. |
| `lejos_pasos_arriba` | `lejos/lejos_pasos_arriba.ogg` | Lejos | Pasos en el piso de arriba, apagados. |
| `lejos_risa` | `lejos/lejos_risa.ogg` | Lejos | Una risa corta, muy lejos, imposible de ubicar. |
| `lejos_platos` | `lejos/lejos_platos.ogg` | Lejos | Platos y cubiertos en la cafetería vacía. |
