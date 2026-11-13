# Pendientes y provisionales

Inventario de lo que falta y lo que está puesto de mentiras, sacado **del propio código y del
disco** el 12 de noviembre de 2026 (cuarta pasada, con los lotes de audio 11 y 12 instalados), no
de la memoria de nadie. Si algo de aquí ya no cuadra, es que el juego cambió: vuelve a correr las
comprobaciones que están al final de cada tabla.

**Nada de esto cambia el juego.** Es solo la lista.

---

## 1. Audios

Los 123 ids de `data/sounds.gd`. Tres estados posibles:

- **archivo real** — el `.ogg` está en `assets/audio/` y suena ese.
- **provisional** — no hay archivo, suena lo que genera `scripts/audio/tone_builder.gd` por código
  (entre paréntesis, el nombre del generador). El juego avisa una vez en consola.
- **FALTA** — ni archivo ni provisional: **ese id no suena nada**. Las voces entran aquí a
  propósito: **ninguna lleva provisional**, porque un pitido en vez de una frase no dice nada.

La columna "dónde se usa" es el script que lo pide. Cuando el id no se pide por su constante sino
que lo resuelve una función (los gritos, los golpes, los tics), ahí va la función.

#### Durante la noche — 99 ids (94 reales, 5 provisionales, 0 faltan)

| id | archivo esperado | dónde se usa | estado |
| --- | --- | --- | --- |
| `armando_modem` | `lejos/armando_modem.ogg` | scenes/night/distant_sounds.gd | provisional (`far_modem`) |
| `carta_pone` | `carta_pone.ogg` | scenes/office/uno_desk.gd | provisional (`typewriter_key`) |
| `carta_toma` | `carta_toma.ogg` | scenes/office/uno_desk.gd | provisional (`typewriter_key`) |
| `tono_ocupado` | `tono_ocupado.ogg` | scenes/phone/phone_call.gd | provisional (`busy_tone`) |
| `urena_banos` | `lejos/urena_banos.ogg` | scenes/night/distant_sounds.gd | provisional (`far_water`) |
| `ambiente_oficina` | `ambiente_oficina.ogg` | scenes/night/night.gd | **archivo real** |
| `ambiente_pasillo` | `ambiente_pasillo.ogg` | scenes/night/night.gd | **archivo real** |
| `apagon_frase` | `apagon_frase.ogg` | scenes/night/night.gd | **archivo real** |
| `armando_glitch_bucle` | `armando_glitch_bucle.ogg` | scenes/pc_screen/armando_takeover.gd | **archivo real** |
| `armando_windows_crash` | `armando_windows_crash.ogg` | scenes/pc_screen/armando_takeover.gd | **archivo real** |
| `audel_chispa` | `lejos/audel_chispa.ogg` | scenes/night/distant_sounds.gd | **archivo real** |
| `barcosa_corre` | `lejos/barcosa_corre.ogg` | scripts/characters/barcosa.gd | **archivo real** |
| `breaker_palanca` | `breaker_palanca.ogg` | scenes/night/night.gd | **archivo real** |
| `cajita_musical` | `cajita_musical.ogg` | data/music_box.gd · scenes/night/blackout_death.gd · scenes/night/night.gd | **archivo real** |
| `cajita_musical_apagon` | `cajita_musical.ogg` | data/music_box.gd · scenes/night/blackout_death.gd | **archivo real** |
| `cajita_musical_aviso` | `cajita_musical.ogg` | scenes/night/blackout_death.gd · scenes/night/night.gd | **archivo real** |
| `camara_cambio` | `camara_cambio.ogg` | scenes/night/night.gd | **archivo real** |
| `camara_sin_senal` | `camara_sin_senal.ogg` | scenes/camera_system/camera_system.gd | **archivo real** |
| `cortaso` | `cortaso.ogg` | scenes/night/mod_menu.gd · scripts/characters/audel.gd | **archivo real** |
| `descarga_pararrayos` | `descarga_pararrayos.ogg` | scenes/night/mod_menu.gd · scripts/characters/audel.gd | **archivo real** |
| `es_impresionante` | `es_impresionante.ogg` | scripts/characters/rochis.gd | **archivo real** |
| `golpe_grave` | `golpe_grave.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `golpe_grave_1` | `golpe_grave_1.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `golpe_grave_2` | `golpe_grave_2.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `golpe_grave_3` | `golpe_grave_3.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `golpe_metal_1` | `golpe_metal_1.ogg` | `Sounds.door_knock()` · scripts/characters/barcosa.gd | **archivo real** |
| `golpe_metal_2` | `golpe_metal_2.ogg` | `Sounds.door_knock()` · scripts/characters/barcosa.gd | **archivo real** |
| `golpe_metal_3` | `golpe_metal_3.ogg` | `Sounds.door_knock()` · scripts/characters/barcosa.gd | **archivo real** |
| `golpes_cortina` | `golpes_cortina.ogg` | — | **archivo real** |
| `grito` | `grito.ogg` | — | **archivo real** |
| `grito_armando` | `gritos/grito_armando.ogg` | `Sounds.scream_for()` · scenes/night/jumpscare_overlay.gd | **archivo real** |
| `grito_audel` | `gritos/grito_audel.ogg` | `Sounds.scream_for()` · scenes/night/jumpscare_overlay.gd | **archivo real** |
| `grito_barcosa` | `gritos/grito_barcosa.ogg` | `Sounds.scream_for()` · scenes/night/jumpscare_overlay.gd | **archivo real** |
| `grito_cometrabas` | `gritos/grito_cometrabas.ogg` | `Sounds.scream_for()` · scenes/night/jumpscare_overlay.gd | **archivo real** |
| `grito_juan` | `gritos/grito_juan.ogg` | `Sounds.scream_for()` · scenes/night/jumpscare_overlay.gd | **archivo real** |
| `grito_rochis` | `gritos/grito_rochis.ogg` | `Sounds.scream_for()` · scenes/night/jumpscare_overlay.gd | **archivo real** |
| `grito_urena` | `gritos/grito_urena.ogg` | `Sounds.scream_for()` · scenes/night/jumpscare_overlay.gd | **archivo real** |
| `juan_respiracion` | `voces/juan_respiracion.ogg` | scenes/night/distant_sounds.gd | **archivo real** |
| `juan_teclado` | `lejos/juan_teclado.ogg` | scenes/night/distant_sounds.gd | **archivo real** |
| `lejos_pasos_arriba` | `lejos/lejos_pasos_arriba.ogg` | scenes/night/distant_sounds.gd · scenes/night/mod_menu.gd | **archivo real** |
| `lejos_pasos_pasillo` | `lejos/lejos_pasos_pasillo.ogg` | scenes/night/distant_sounds.gd · scenes/night/mod_menu.gd | **archivo real** |
| `lejos_platos` | `lejos/lejos_platos.ogg` | scenes/night/distant_sounds.gd · scenes/night/mod_menu.gd | **archivo real** |
| `lejos_portazo` | `lejos/lejos_portazo.ogg` | scenes/night/distant_sounds.gd · scenes/night/mod_menu.gd | **archivo real** |
| `lejos_risa` | `lejos/lejos_risa.ogg` | scenes/night/distant_sounds.gd · scenes/night/mod_menu.gd | **archivo real** |
| `lejos_silla` | `lejos/lejos_silla.ogg` | scenes/night/distant_sounds.gd · scenes/night/mod_menu.gd | **archivo real** |
| `linterna_click` | `linterna_click.ogg` | scenes/night/night.gd | **archivo real** |
| `llamada_juguete` | `llamadas/llamada_juguete.ogg` | data/night_calls.gd · scenes/night/mod_menu.gd | **archivo real** |
| `llamada_mencho` | `llamadas/llamada_mencho.ogg` | data/night_calls.gd · scenes/night/mod_menu.gd · scenes/night/night.gd | **archivo real** |
| `llamada_noche1` | `llamadas/llamada_noche1.ogg` | `NightCalls` · scenes/phone/phone_call.gd | **archivo real** |
| `llamada_noche2` | `llamadas/llamada_noche2.ogg` | `NightCalls` · scenes/phone/phone_call.gd | **archivo real** |
| `llamada_noche3` | `llamadas/llamada_noche3.ogg` | `NightCalls` · scenes/phone/phone_call.gd | **archivo real** |
| `llamada_noche4` | `llamadas/llamada_noche4.ogg` | `NightCalls` · scenes/phone/phone_call.gd | **archivo real** |
| `llamada_noche5` | `llamadas/llamada_noche5.ogg` | `NightCalls` · scenes/phone/phone_call.gd | **archivo real** |
| `llamada_noche6` | `llamadas/llamada_noche6.ogg` | `NightCalls` · scenes/phone/phone_call.gd | **archivo real** |
| `llavero` | `llavero.ogg` | — | **archivo real** |
| `mamador_ok_1` | `voces/mamador_ok_1.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `mamador_ok_2` | `voces/mamador_ok_2.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `mamador_ok_3` | `voces/mamador_ok_3.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `mamador_pasos` | `lejos/mamador_pasos.ogg` | scenes/night/distant_sounds.gd | **archivo real** |
| `momo_cancion` | `extras/momo_cancion.ogg` | scenes/night/momo_event.gd · scenes/night/night.gd | **archivo real** |
| `pasos_acercandose` | `pasos_acercandose.ogg` | scenes/night/blackout_death.gd | **archivo real** |
| `puerta_cortina` | `puerta_cortina.ogg` | `Sounds.shutter_sound()` · scenes/office/door_shutter.gd | **archivo real** |
| `puerta_cortina_2` | `puerta_cortina_2.ogg` | `Sounds.shutter_sound()` · scenes/office/door_shutter.gd | **archivo real** |
| `rochis_extra_1` | `voces/rochis_extra_1.ogg` | `Sounds.rochis_line()` · scripts/characters/rochis.gd | **archivo real** |
| `rochis_extra_2` | `voces/rochis_extra_2.ogg` | `Sounds.rochis_line()` · scripts/characters/rochis.gd | **archivo real** |
| `rochis_extra_3` | `voces/rochis_extra_3.ogg` | `Sounds.rochis_line()` · scripts/characters/rochis.gd | **archivo real** |
| `rochis_silla` | `lejos/rochis_silla.ogg` | scenes/night/night.gd | **archivo real** |
| `se_aleja` | `se_aleja.ogg` | scripts/characters/glass_stalker.gd | **archivo real** |
| `sergio_rescate` | `extras/sergio_rescate.ogg` | scenes/night/sergio_rescue.gd | **archivo real** |
| `sonido_perturbador` | `extras/sonido_perturbador.ogg` | scenes/camera_system/camera_system.gd | **archivo real** |
| `telefono_colgar` | `telefono_colgar.ogg` | scenes/phone/call_subtitles.gd | **archivo real** |
| `telefono_timbre` | `telefono_timbre.ogg` | scenes/night/night.gd | **archivo real** |
| `tic_boom_1` | `menu/tic_boom_1.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `tic_boom_2` | `menu/tic_boom_2.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `tic_boom_3` | `menu/tic_boom_3.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `tic_estatica` | `menu/tic_estatica.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `tic_golpe_eco` | `menu/tic_golpe_eco.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `tic_golpe_metal` | `menu/tic_golpe_metal.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `tic_piano` | `menu/tic_piano.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `tic_raspon` | `menu/tic_raspon.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `tic_vidrio` | `menu/tic_vidrio.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `tic_whoosh_golpe` | `menu/tic_whoosh_golpe.ogg` | scenes/night/mod_menu.gd | **archivo real** |
| `ticket_nuevo` | `ticket_nuevo.ogg` | scenes/night/night.gd | **archivo real** |
| `totem_reventando` | `extras/totem_reventando.ogg` | scenes/night/sergio_rescue.gd | **archivo real** |
| `urena_adios_colgado` | `voces/urena_adios_colgado.ogg` | scenes/phone/phone_call.gd | **archivo real** |
| `urena_adios_esquivo` | `voces/urena_adios_esquivo.ogg` | data/urena_questions.gd | **archivo real** |
| `urena_adios_foto` | `voces/urena_adios_foto.ogg` | data/urena_questions.gd | **archivo real** |
| `urena_adios_grosero` | `voces/urena_adios_grosero.ogg` | data/urena_questions.gd | **archivo real** |
| `urena_linea1` | `voces/urena_linea1.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `urena_linea2` | `voces/urena_linea2.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `urena_linea3` | `voces/urena_linea3.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `urena_linea4` | `voces/urena_linea4.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `urena_linea5` | `voces/urena_linea5.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `urena_linea6` | `voces/urena_linea6.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `urena_linea7` | `voces/urena_linea7.ogg` | `VoiceLines` · scenes/night/voice_line.gd | **archivo real** |
| `urena_reaccion_esquiva` | `voces/urena_reaccion_esquiva.ogg` | data/urena_questions.gd | **archivo real** |
| `urena_reaccion_grosero` | `voces/urena_reaccion_grosero.ogg` | data/urena_questions.gd | **archivo real** |
| `urena_reaccion_sigue` | `voces/urena_reaccion_sigue.ogg` | data/urena_questions.gd | **archivo real** |
| `urena_saludo` | `voces/urena_saludo.ogg` | scenes/phone/phone_call.gd | **archivo real** |

#### En los dos sitios — 5 ids (5 reales, 0 provisionales, 0 faltan)

| id | archivo esperado | dónde se usa | estado |
| --- | --- | --- | --- |
| `estatica_camara` | `estatica_camara.ogg` | scenes/main_menu/main_menu.gd · scenes/night/night.gd | **archivo real** |
| `estatica_inquietante` | `estatica_inquietante.ogg` | scenes/game_over/game_over.gd · scenes/night/mod_menu.gd · scripts/ui/menu_backdrop.gd | **archivo real** |
| `estatica_inquietante_gameover` | `estatica_inquietante.ogg` | scenes/game_over/game_over.gd · scenes/night/mod_menu.gd | **archivo real** |
| `menu_glitch_largo` | `menu_glitch_largo.ogg` | scenes/night/mod_menu.gd · scripts/ui/menu_backdrop.gd | **archivo real** |
| `menu_musica_final` | `menu/menu_musica_final.ogg` | scenes/main_menu/main_menu.gd · scenes/night/mod_menu.gd | **archivo real** |

#### Menús, pantallas y maquinita — 19 ids (10 reales, 9 provisionales, 0 faltan)

| id | archivo esperado | dónde se usa | estado |
| --- | --- | --- | --- |
| `arcade_bip` | `arcade_bip.ogg` | scenes/minigames/arcade_screen.gd | provisional (`arcade_boot`) |
| `arcade_cajita` | `arcade_cajita.ogg` | scenes/minigames/arcade_junta.gd | provisional (`arcade_music_box`) |
| `arcade_golpe` | `arcade_golpe.ogg` | scenes/minigames/arcade_bienvenida.gd · scenes/minigames/arcade_level.gd | provisional (`arcade_hurt`) |
| `arcade_nivel1` | `arcade_nivel1.ogg` | scenes/minigames/arcade_junta.gd | provisional (`arcade_level1`) |
| `arcade_nivel2` | `arcade_nivel2.ogg` | scenes/minigames/arcade_junta.gd | provisional (`arcade_level2`) |
| `arcade_nivel3` | `arcade_nivel3.ogg` | scenes/minigames/arcade_junta.gd | provisional (`arcade_level3`) |
| `arcade_recoge` | `arcade_recoge.ogg` | scenes/minigames/arcade_bienvenida.gd · scenes/minigames/arcade_posada.gd | provisional (`arcade_pick`) |
| `arcade_salto` | `arcade_salto.ogg` | scenes/minigames/arcade_bienvenida.gd · scenes/minigames/arcade_junta.gd · scenes/minigames/arcade_posada.gd | provisional (`arcade_jump`) |
| `menu_blip` | `menu_blip.ogg` | scripts/ui/menu_style.gd | provisional (`menu_blip`) |
| `aura` | `extras/aura.ogg` | scenes/minigames/arcade_ending.gd | **archivo real** |
| `despertador` | `despertador.ogg` | scenes/win_screen/six_am_roll.gd | **archivo real** |
| `extras_musica` | `extras_musica.ogg` | scenes/extras/custom_night.gd · scenes/extras/extras_menu.gd | **archivo real** |
| `mamador_brecha` | `mamador_brecha.ogg` | scenes/ui/wasted_screen.gd | **archivo real** |
| `mamador_delito` | `voces/mamador_delito.ogg` | scenes/ui/wasted_screen.gd | **archivo real** |
| `tecla_maquina_1` | `tecla_maquina_1.ogg` | scenes/main_menu/name_entry.gd | **archivo real** |
| `tecla_maquina_2` | `tecla_maquina_2.ogg` | scenes/main_menu/name_entry.gd | **archivo real** |
| `tecla_maquina_3` | `tecla_maquina_3.ogg` | scenes/main_menu/name_entry.gd | **archivo real** |
| `tic_rechinido` | `menu/tic_rechinido.ogg` | `Sounds.menu_tic()` · scripts/ui/menu_backdrop.gd | **archivo real** |
| `wasted` | `wasted.ogg` | scenes/ui/wasted_screen.gd | **archivo real** |

### Los que conviene mirar

| id | qué pasa |
| --- | --- |
| `grito` | solo sale como **último recurso** de `Sounds.scream_for()`. Con los siete gritos propios grabados, hoy no se oye nunca. |
| `golpes_cortina` | es el respaldo de `Sounds.metal_hit()`. Con los tres `golpe_metal_N` ya grabados, **hoy no se oye nunca**. |
| `llavero` | se pide con el id escrito a pelo en `night.gd` (`DISTANT_WITH_MOVE`), no por su constante. **Ya tiene archivo** (apareció el 26 de octubre), así que suena. |
| `estatica_camara` | el archivo nuevo dura 0.5 s y **trae un fundido en las dos puntas**: entra en unos 10 ms y se apaga en los últimos 20 a 25 ms. En bucle eso es un bajón de nivel **dos veces por segundo**. No hace clic, pero puede oírse como un aleteo; a −30 dB y debajo de todo lo demás apenas se nota. Si molesta, hay que exportarlo sin fundidos o más largo. |
| `totem_reventando` | dura **4.3 s** y entra a los 14 s de una pista de 17.5: su cola se pasa **0.8 s** del final del rescate y se oye ya con la noche andando. Va suelto (`play()` a secas) y nadie lo corta. |

---

## 2. Voces

Las 29 líneas habladas que quedan en el juego, con su texto completo para poder grabarlas.

**Barcosa y Armando ya no hablan.** Sus diez audios se borraron de `assets/audio/voces/` y sus ids
salieron del catálogo: Barcosa sigue gritando **por escrito** cuando aporrea la cortina, y la frase
de Armando sigue saliendo escrita en la pantalla de la PC. Por eso sus cuatro líneas siguen aquí
(el texto se usa) marcadas como *sin voz a propósito*, y las seis de Armando ya no aparecen.

Estados:

- **enganchada** — tiene id en `data/sounds.gd` y archivo: suena.
- **sin voz a propósito** — el texto se lee, pero no hay ni id ni audio y así se queda.
- **reservada** — el audio está, pero todavía no tiene id porque falta decidir dónde va.
- **FALTA el archivo** — tiene id, no tiene audio: hoy solo sale el subtítulo.

**De dónde salen:** las primeras tomas las generó `tools/generar_voces.py` (edge-tts, voz
`es-MX-JorgeNeural`, con la velocidad y el tono de cada personaje en su diccionario `VOCES`, y
Applio encima **solo para Rochis**). Desde entonces han ido llegando archivos nuevos: en el árbol de
trabajo están modificadas las de Mamador, las de Ureña y «es impresionante», y `urena_saludo`,
`rochis_extra_1..3` y `juan_respiracion` entraron sin pasar por el script (el script no conoce las
de Rochis, salta la respiración y con `urena_saludo` se topó con un 403). Este inventario mira el
disco, no escucha: no sabe con qué se hizo cada archivo.

| id | archivo esperado | dónde se usa | estado | texto |
| --- | --- | --- | --- | --- |
| `barcosa_puerta_1` | `voces/barcosa_puerta_1.ogg` | scripts/characters/barcosa.gd → `Hud/VoiceLine` (**solo subtítulo**) | **sin voz a propósito**: Barcosa no habla | «¿Quién cerró? Tengo clase en este salón.» |
| `barcosa_puerta_2` | `voces/barcosa_puerta_2.ogg` | scripts/characters/barcosa.gd → `Hud/VoiceLine` (**solo subtítulo**) | **sin voz a propósito**: Barcosa no habla | «Abra, joven. Nada más paso lista y me voy.» |
| `barcosa_puerta_3` | `voces/barcosa_puerta_3.ogg` | scripts/characters/barcosa.gd → `Hud/VoiceLine` (**solo subtítulo**) | **sin voz a propósito**: Barcosa no habla | «Diez minutos. Le estoy pidiendo diez minutos.» |
| `barcosa_se_va` | `voces/barcosa_se_va.ogg` | scripts/characters/barcosa.gd → `Hud/VoiceLine` (**solo subtítulo**) | **sin voz a propósito**: Barcosa no habla | «Bueno, ya. Quedan todos con falta.» |
| `es_impresionante` | `es_impresionante.ogg` | scripts/characters/rochis.gd (botón de la CAM 3) | **enganchada** | «Es impresionante» |
| `juan_respiracion` | `voces/juan_respiracion.ogg` | scenes/night/distant_sounds.gd, en bucle mientras Juan está en el cristal | **enganchada**: no es una línea sino su respiración, pero va por Voces | «[respiración en el cristal]» |
| `mamador_delito` | `voces/mamador_delito.ogg` | scenes/ui/wasted_screen.gd, antes de `mamador_brecha` | **enganchada** | «¡Delito federal!» |
| `mamador_ok_1` | `voces/mamador_ok_1.ogg` | scripts/characters/mamador.gd → `Hud/VoiceLine` | **enganchada** | «Sin novedad. Me retiro.» |
| `mamador_ok_2` | `voces/mamador_ok_2.ogg` | scripts/characters/mamador.gd → `Hud/VoiceLine` | **enganchada** | «Nada de inteligencia artificial. Así me gusta.» |
| `mamador_ok_3` | `voces/mamador_ok_3.ogg` | scripts/characters/mamador.gd → `Hud/VoiceLine` | **enganchada** | «Todo en orden. Sigan así.» |
| `rochis_extra_1` | `voces/rochis_extra_1.ogg` | `Sounds.rochis_line()` · scripts/characters/rochis.gd (botón de la CAM 3, al azar) | **enganchada** | *no está escrito en el repo* |
| `rochis_extra_2` | `voces/rochis_extra_2.ogg` | `Sounds.rochis_line()` · scripts/characters/rochis.gd (botón de la CAM 3, al azar) | **enganchada** | *no está escrito en el repo* |
| `rochis_extra_3` | `voces/rochis_extra_3.ogg` | `Sounds.rochis_line()` · scripts/characters/rochis.gd (botón de la CAM 3, al azar) | **enganchada** | *no está escrito en el repo* |
| `santi_voces` | `voces/santi_voces.ogg` | **sin enganchar a propósito**: falta decidir dónde va | grabada, **reservada**: sin id todavía | «Voces, muchas voces» |
| `urena_adios_colgado` | `voces/urena_adios_colgado.ogg` | scenes/phone/phone_call.gd (despedida) | **enganchada** | «¿Me colgaste? ...Ahorita voy para allá.» |
| `urena_adios_esquivo` | `voces/urena_adios_esquivo.ogg` | scenes/phone/phone_call.gd (despedida) | **enganchada** | «Ay, qué serio... la oferta sigue en pie.» |
| `urena_adios_foto` | `voces/urena_adios_foto.ogg` | scenes/phone/phone_call.gd (despedida) | **enganchada** | «Te dejé un regalito en tu escritorio.» |
| `urena_adios_grosero` | `voces/urena_adios_grosero.ogg` | scenes/phone/phone_call.gd (despedida) | **enganchada** | «Me rompiste el corazón... y eso se paga.» |
| `urena_linea1` | `voces/urena_linea1.ogg` | scenes/phone/phone_call.gd (insinuación, id en el banco) | **enganchada** | «Ando buscando a alguien para unos trabajitos extra... en mi cubículo.» |
| `urena_linea2` | `voces/urena_linea2.ogg` | scenes/phone/phone_call.gd (insinuación, id en el banco) | **enganchada** | «Te quiero convertir en mujer por una noche.» |
| `urena_linea3` | `voces/urena_linea3.ogg` | scenes/phone/phone_call.gd (insinuación, id en el banco) | **enganchada** | «Te subo la calificación... ven a mi oficina a las 3 AM.» |
| `urena_linea4` | `voces/urena_linea4.ogg` | scenes/phone/phone_call.gd (insinuación, id en el banco) | **enganchada** | «¿Me mandas una foto de cuerpo completo? Para el archivo.» |
| `urena_linea5` | `voces/urena_linea5.ogg` | scenes/phone/phone_call.gd (insinuación, id en el banco) | **enganchada** | «Se me puso bien duro... el disco. ¿Me lo formateas?» |
| `urena_linea6` | `voces/urena_linea6.ogg` | scenes/phone/phone_call.gd (insinuación, id en el banco) | **enganchada** | «¿Me haces una conexión punto a punto? Sin switch.» |
| `urena_linea7` | `voces/urena_linea7.ogg` | scenes/phone/phone_call.gd (insinuación, id en el banco) | **enganchada** | «Tengo el cable bien largo... ¿me ayudas a ponchar el conector?» |
| `urena_reaccion_esquiva` | `voces/urena_reaccion_esquiva.ogg` | scenes/phone/phone_call.gd (reacción) | **enganchada** | «Ay, qué serio...» |
| `urena_reaccion_grosero` | `voces/urena_reaccion_grosero.ogg` | scenes/phone/phone_call.gd (reacción) | **enganchada** | «Qué grosero eres...» |
| `urena_reaccion_sigue` | `voces/urena_reaccion_sigue.ogg` | scenes/phone/phone_call.gd (reacción) | **enganchada** | «¡Así me gusta!» |
| `urena_saludo` | `voces/urena_saludo.ogg` | scenes/phone/phone_call.gd (saludo) | **enganchada** | «¡Quihubo! Ya vi que andas muy trabajador... qué aplicadito.» |

**Para grabarlas:** `.ogg` mono a 44.1 kHz en `assets/audio/voces/`, con el nombre exacto de la
columna. El bus es Voces. Para regenerarlas con voz sintética:
`python3 tools/generar_voces.py --listar` enseña qué haría sin tocar nada, y sin `--listar` genera
lo que falte (nunca pisa un archivo que ya exista salvo con `--forzar`).

### Lo que falta de voces

**Nada con id.** Todas las líneas que el juego pide ya tienen su archivo.

- **`santi_voces`** está grabada y reservada: no tiene id todavía porque falta decidir en qué
  momento suena.
- **`rochis_extra_1..3`** ya entran al sorteo del botón de Rochis junto con «es impresionante»:
  `Sounds.rochis_line()` mete las que tengan archivo, sin tocar código. Lo que dicen no está
  escrito en ningún sitio del repo; si se quiere en el guion, hay que transcribirlas.
- **`juan_respiracion`** suena en bucle a −12 dB por el bus Voces mientras Juan está en el cristal,
  y mientras suena se calla `juan_teclado` (`SILENCED_BY` en `distant_sounds.gd`).
- **Ya no se usa la síntesis de voz de Godot en ningún sitio** (`DisplayServer.tts_*` no aparece en
  todo el proyecto). Antes la usaban la llamada de Ureña, el botón de Rochis y las líneas sueltas.

---

## 3. Imágenes

### 3.1 Lo que el código pide y está

| bloque | ruta | cuántas | estado |
| --- | --- | --- | --- |
| Cámaras | `assets/art/cameras/camXX_<estado>` | **72** | todas las que el código nombra a pelo están. El resto de nombres los **compone el sistema** con los profes presentes; si falta una combinación, sale la etiqueta de texto. La CAM 10 no tiene `vacia` a propósito: usa `cam10_salio` |
| Oficina, vistas | `assets/art/office/oficina_*.{jpeg,png}` | 7 | izquierda, centro (clara, oscura, y las dos cerradas), derecha y derecha vacía |
| Oficina, cortina | `assets/art/office/cortina_capa[_oscura].png` | 2 | las dos, la clara y la oscura |
| Oficina, capas de profe | `assets/art/office/layers/centro_<slug>.png` | 6 | barcosa, mamador, urena, juan, armando, audel |
| Oficina, siluetas | `assets/art/office/layers/silueta_<slug>.png` | 5 | los cinco del cristal |
| Jumpscares | `assets/art/jumpscares/jumpscare_<id>[_a].png` | **18** | los nueve con su variante `_a`: barcosa, urena, rochis, juan, armando, cometrabas, audel, audel_susto y mamador_militares |
| Expedientes | `assets/art/extras/expediente_<id>.png` | 8 | los ocho profes |
| Periódicos | `assets/art/extras/periodico_0..6.png` | 7 | los siete recortes |
| Documentos | `assets/art/extras/documentos/*.png` | 3 | los dos recibos y la carta de despido |
| Sergio | `assets/art/extras/sergio/*.png` | 4 | la capa, la silueta, el tótem y su ícono |
| Momo | `assets/art/extras/momo/*.png` | 2 | la vista izquierda tomada y el screamer |
| Maquinita | `assets/art/minijuego/fondos` + `sprites` | 3 + 22 | los tres fondos y los sprites |
| Menú | `assets/art/menu/menu_fondo_0.png` + `menu_tic_*.png` | 5 | el fondo y los cuatro tics |
| Pantallas-foto | `assets/art/screens/{solicitud_empleo,pago_noche}.png` | 2 | las dos |
| Estática | `assets/art/screens/static/estatica_0..7.png` | 8 | los ocho cuadros |

### 3.2 Lo que el código pide y **no está**

**Nada.** Con las dos capas de la vista derecha y el conector del patch panel ya puestos, todas
las rutas que el código nombra existen en el disco. La única capa que no existe es
`layers/izquierda_*.png`, y es a propósito: a la vista izquierda no llega ningún profe (es por
donde entra Momo, que tiene su propia imagen).

### 3.3 Arte que existe y nadie pide

| ruta | nota |
| --- | --- |
| `assets/art/minijuego/sprites/llave.png` | la llave de cuerda de la botarga; ningún nivel la dibuja |
| `assets/art/minijuego/sprites/traje_walk.png` | el de traje caminando; los niveles usan `traje_side` y `traje_back` |
| `assets/art/office/layers/centro_barcosa.png` | desactivada: ahora Barcosa aporrea detrás de la cortina y no se dibuja |
| `assets/art/office/rj45.png` | los conectores del patch panel se dibujan por código; ya no se pide en ningún sitio y se puede borrar |

### 3.4 Lo que dibuja el código (candidatos a hacerse a mano)

**41 archivos** tienen un `_draw()` propio. Esto no está "mal": en muchos casos dibujar por código
es lo correcto (barras, medidores, texto). La lista es para saber **qué podría sustituirse por arte**
si algún día quieres.

| dónde | qué dibuja | ¿valdría la pena arte? |
| --- | --- | --- |
| `scenes/minigames/arcade_level.gd` + los tres niveles | corazones de vida, tablas, escaleras, huecos, charcos, piñatas, ventiladores, macetas, sillas, el círculo de oscuridad | **sí**: es lo único del minijuego que no es pixel art tuyo |
| `scenes/server_room/patch_panel_view.gd` | el rack, los puertos, los cables, los conectores y la hoja de etiquetado | **sí**, el rack y la hoja; los conectores ya se dibujan por código a propósito |
| `scenes/tasks/network_sim/network_canvas.gd` y `plan_diagram.gd` | los equipos, los cables y el diagrama de topología | quizá: con íconos de equipo se vería mejor |
| `scenes/breaker/breaker_panel.gd` | la placa, las pastillas y la palanca | quizá |
| `scenes/pc_screen/desktop_icon.gd`, `pc_window.gd`, `monitor_bezel.gd` | los íconos del escritorio, las ventanas y el bisel | quizá los íconos; el bisel y las ventanas funcionan bien por código |
| `scenes/pc_screen/armando_takeover.gd` | la toma de pantalla de Armando (usa `pc/armando_standby.png` de fondo) | ya tiene su imagen |
| `scenes/office/ticket_envelope.gd` | el sobrecito del ticket nuevo | **sí**, es pequeño y se ve mucho |
| `scenes/night/warning_icon.gd`, `usage_bars.gd`, `camera_bar.gd` | el aviso de la cuerda, las barras de consumo y la pestaña de cámaras | no: son HUD |
| `scenes/camera_system/*` | esquinas del visor, minimapa, medidor de cuerda, capa de la cámara | no: son HUD |
| `scenes/office/sergio_arrival.gd` y `scenes/night/sergio_rescue.gd` | el haz de luz (44 tiras) y las 70 partículas del tótem | no: son efectos |
| `scenes/night/blackout_death.gd` | los dos ojos del pasillo a oscuras | no |
| `scenes/win_screen/confetti_fall.gd` | el confeti de las 6 AM | no |
| `scripts/ui/star_row.gd` | las tres estrellas del menú | quizá |
| `scenes/extras/newspaper_screen.gd`, `document_screen.gd` | la plantilla de respaldo por si falta una imagen, y el nombre encima de las hojas | no: la plantilla es el plan B |
| `scenes/night/hallucination_overlay.gd` | el parche y el nombre del expediente de la alucinación | no |
| `scenes/minigames/arcade_over.gd` | el "GAME OVER" en la fuente de 3x5 | no |

---

## 4. Llamadas y subtítulos

| noche | audio esperado | subtítulos esperados | estado |
| --- | --- | --- | --- |
| 1 | `llamadas/llamada_noche1.ogg` | `data/llamadas/llamada_noche1.txt` | **las dos cosas están** (15 líneas, 1:37) |
| 2 | `llamadas/llamada_noche2.ogg` | `data/llamadas/llamada_noche2.txt` | **las dos cosas están** (8 líneas, 1:12) |
| 3 | `llamadas/llamada_noche3.ogg` | `data/llamadas/llamada_noche3.txt` | **las dos cosas están** (9 líneas, 1:08) |
| 4 | `llamadas/llamada_noche4.ogg` | `data/llamadas/llamada_noche4.txt` | **las dos cosas están** (10 líneas, 1:18) |
| 5 | `llamadas/llamada_noche5.ogg` | `data/llamadas/llamada_noche5.txt` | **las dos cosas están** (6 líneas, 0:51) |
| 6 | `llamadas/llamada_noche6.ogg` | `data/llamadas/llamada_noche6.txt` | **las dos cosas están** (0:42; estática y una voz de robot al revés, con un solo subtítulo: «(estática)») |
| — | `llamadas/llamada_mencho.ogg` | no lleva (un solo subtítulo corto en código) | **está** |
| — | `llamadas/llamada_juguete.ogg` | no lleva (un solo subtítulo corto en código) | **está** |

Una noche **tiene llamada solo si existe su `.ogg`**: si falta, el teléfono no suena esa noche y no
pasa nada más. Las seis están grabadas con ElevenLabs. El texto de cada una vive en su `.txt`, y
[docs/guion_voces.md](guion_voces.md) lleva el texto final de las seis, sin los tiempos.

Recordatorios del formato, que son fáciles de olvidar:

- El archivo de la llamada es **solo voz**. El timbre (`telefono_timbre`) y el clac de colgar
  (`telefono_colgar`) los pone el juego.
- Los subtítulos van `m:ss|texto`, una línea por frase. Si al audio le recortas o le añades silencio
  al principio **no reescribas los tiempos**: mete una línea `@offset=-1.4` (con decimales y signo)
  en cualquier sitio del archivo y se corren todos.

---

## Resumen

| Bloque | Total | Listo | Provisional | Falta |
| --- | --- | --- | --- | --- |
| **Audios** (ids del catálogo) | 123 | 109 con archivo real | 14 con provisional por código | **0 sin nada** |
| **Voces** (líneas que quedan) | 29 | 24 enganchadas | 4 sin voz a propósito · 1 reservada | **0** |
| **Imágenes** (bloques que pide el código) | 15 bloques | **15 completos** | 4 cosas se dibujan por código pudiendo ser arte | — |
| **Llamadas** | 6 noches + 2 raras | **las 8** | — | **0** |

**Audios que no suenan nada: ninguno.** Los 14 que siguen con provisional son los ocho de la
maquinita (chiptune por código, que es como se diseñó), `carta_toma` y `carta_pone`,
`tono_ocupado`, y **tres que se quedan así a propósito**: `urena_banos`, `armando_modem` y
`menu_blip` (decidido el 12 de noviembre).

**Lo que cambió en esta pasada (12 de noviembre, lotes de audio 11 y 12):**

- Dejan atrás su provisional `ambiente_oficina` (60 s) y `ambiente_pasillo` (57 s), los dos en
  bucle sin salto: medida la unión, el paso de la última muestra a la primera cae dentro de lo
  normal entre dos muestras seguidas y el nivel no baja. También `estatica_camara`,
  `ticket_nuevo` y `totem_reventando`; de esos, dos traen un detalle (ver **Los que conviene mirar**).
- Ya están las llamadas de las noches 2 a 6 con sus subtítulos, `urena_saludo` y
  `rochis_extra_1..3`.
- Tres ids nuevos: `juan_respiracion` (Juan en el cristal), `camara_sin_senal` (el monitor pasa a
  SIN SEÑAL) y `puerta_cortina_2` (segunda toma al bajar la cortina, 3 de cada 10 veces).
- La cortina **sonaba dos veces en cada movimiento**: la pedían `door_shutter.gd` y `night.gd`.
  Al ser el mismo id no se notaba; con dos tomas se habrían encimado. Ahora solo la pide la lámina.
- Corregido un error de la pasada anterior: `derecha_rochis.png` **sí se usa** (es la capa de Rochis
  en la vista derecha). La que no se usa es `office/rj45.png`.

**En las pasadas anteriores:**

- Fuera las voces de **Barcosa** (4) y **Armando** (6): borradas del disco y del catálogo.
- Dentro las **15 de Ureña** y la de **Mamador**, ya enganchadas.
- **Ni una línea de síntesis de voz** en todo el proyecto.
- Aparecieron cinco audios tuyos: `llavero`, `golpe_metal_1..3` y `extras_musica`, **los cinco
  comprobados sonando de verdad**, no por provisional.
- Fuera del catálogo seis ids que sobraban: `campana_escuela` y `ninos_yay` (el despertador ya trae
  el grito de los niños), `tecla_maquina` (las tres tomas están grabadas) y `grito_base_1..3` (los
  siete gritos propios están grabados). Con ellos se fueron sus tres `.import` huérfanos.
- Apartados `rochis_extra_1..3`, sin grabar todavía.
- Entraron `carta_toma` y `carta_pone`, de la baraja de UNO. Los dos suenan con el provisional de
  la tecla de máquina, que es justo lo que hace una carta: un clac seco de cartón.
- Ya están las dos capas de la vista derecha (`derecha_rochis`, `derecha_come_trabas`), así que
  ninguna imagen queda pendiente. **`office/rj45.png` ya no se usa**: los conectores del patch
  panel, enchufados y sueltos, se dibujan por código, porque la imagen se veía como una
  calcomanía. El archivo se puede borrar.

**Lo más barato de arreglar, por orden:**

1. **Decidir dónde va `santi_voces`** — el audio ya está, solo falta el momento.
2. **Transcribir las frases extra de Rochis** en [docs/guion_voces.md](guion_voces.md): las
   llamadas ya están, pero lo que dicen `rochis_extra_1..3` no está escrito en ningún sitio.
3. **`estatica_camara` sin fundidos**, si el aleteo del bucle llega a notarse.
4. **`tono_ocupado` y las dos cartas** — los únicos provisionales que no se quedan a propósito,
   fuera de la maquinita.

### Cómo rehacer este inventario

- Audios: `data/sounds.gd` contra `assets/audio/`, y los generadores de
  `scripts/audio/tone_builder.gd`. El propio juego lo saca con F1 → Audio → "Escribir la lista de
  audios que faltan", que regenera [docs/audios_faltantes.md](audios_faltantes.md).
- Voces: `python3 tools/generar_voces.py --listar`.
- Imágenes: `grep -rn "res://assets/art" --include=*.gd .` y comparar con `assets/art/`.
- Llamadas: `ls assets/audio/llamadas/` y `ls data/llamadas/`.
