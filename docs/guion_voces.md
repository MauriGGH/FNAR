# Guion de voces — Five Nights at Rocha's

Todas las líneas habladas que el juego usa hoy o va a usar, para grabarlas.
Por personaje, con el texto exacto, el archivo que el juego espera y cuándo suena.

## Generar las que faltan con voz sintética

Mientras no estén grabadas de verdad, `tools/generar_voces.py` las saca con
edge-tts (y, en el caso de Rochis, pasándolas por el modelo de Applio). Lee las
líneas de este mismo documento y de `data/voice_lines.gd`, **salta las llamadas
de noche** y **nunca pisa un archivo que ya exista** salvo que se le pase
`--forzar`:

```
pip install edge-tts
python3 tools/generar_voces.py --listar     # qué haría, sin hacer nada
python3 tools/generar_voces.py              # genera lo que falte
```

La voz de cada personaje (velocidad y tono) está en el diccionario `VOCES` del
script, pensado para que se toque a mano.

## Cómo leer este documento

Cada línea lleva una marca de estado:

- **[EN EL JUEGO]** — el id ya existe en `data/sounds.gd`. Dejas el archivo con ese
  nombre exacto en `assets/audio/` y suena solo, sin tocar código.
- **[FALTA ENGANCHAR]** — la línea existe como texto en el juego, pero todavía no
  tiene id de sonido. Grabarla no basta: hay que añadir su entrada al catálogo.
- **[POR ESCRIBIR]** — el momento existe en el diseño pero nadie ha escrito el texto.

Formato: **.ogg**, mono, 44.1 kHz. Las rutas son relativas a `assets/audio/`.

Buses: las voces salen por **Voces**; los gritos y los sonidos de esfuerzo, por
**Efectos** (van mezclados con el golpe del jumpscare, no con el diálogo).

---

## 1. Llamadas de inicio de noche

La voz del guardia anterior, el que cubría el turno antes que tú y está acabando su
servicio social. Tono: amable, cansado, se va por las ramas y evita los temas feos.
La noche 6 no es él: es estática y una voz de robot al revés.

Suena a los 3 s de empezar la noche: el teléfono timbra 10 s y, si lo contestas, se
reproduce entera con subtítulos abajo. Se puede silenciar en cualquier momento y no
bloquea el juego. **Si el archivo de una noche no existe, esa noche no hay llamada.**

| Noche | Archivo | Subtítulos | Estado |
| --- | --- | --- | --- |
| 1 | `llamadas/llamada_noche1.ogg` | `data/llamadas/llamada_noche1.txt` | **[EN EL JUEGO]** grabada (ElevenLabs) |
| 2 | `llamadas/llamada_noche2.ogg` | `data/llamadas/llamada_noche2.txt` | **[EN EL JUEGO]** grabada (ElevenLabs) |
| 3 | `llamadas/llamada_noche3.ogg` | `data/llamadas/llamada_noche3.txt` | **[EN EL JUEGO]** grabada (ElevenLabs) |
| 4 | `llamadas/llamada_noche4.ogg` | `data/llamadas/llamada_noche4.txt` | **[EN EL JUEGO]** grabada (ElevenLabs) |
| 5 | `llamadas/llamada_noche5.ogg` | `data/llamadas/llamada_noche5.txt` | **[EN EL JUEGO]** grabada (ElevenLabs) |
| 6 | `llamadas/llamada_noche6.ogg` | `data/llamadas/llamada_noche6.txt` | **[EN EL JUEGO]** grabada: estática y una voz de robot al revés |

Los subtítulos van en un `.txt` aparte, una línea por frase con el formato
`m:ss|texto`. Las líneas que empiezan con `#` se ignoran. Cada frase se queda en
pantalla hasta que entra la siguiente, así que solo hay que apuntar en qué segundo
empieza cada una.

El tiempo admite **centésimas** (`1:09.45`) y también vale un número de segundos a
secas (`90|...`). Y si recortas o alargas el silencio del principio, **no hace falta
reescribir nada**: pon una línea `@offset=2.5` (segundos, con decimales y con signo)
en cualquier sitio del archivo y se suma a todos los tiempos de golpe.

**El archivo de la llamada es solo voz.** El timbre y el clac de colgar los pone el
juego: `telefono_timbre.ogg` en bucle hasta que contestan, y `telefono_colgar.ogg`
al acabar la llamada o al silenciarla.

### El texto final de cada noche

**Las seis están grabadas, con ElevenLabs.** Lo que va abajo es el texto final: el mismo de su
`data/llamadas/llamada_nocheN.txt`, sin los tiempos. Si una llamada cambia, se cambia en su `.txt`
(que es lo que sale en pantalla) y se copia aquí.

#### Noche 1 — 15 frases, 1:37

> ¿Bueno? ¿Bueno, bueno?
>
> Ah, qué bueno que contestas. Te dejo este mensaje para que sepas cómo instalarte la primera noche, ¿va?
>
> Yo cubría este turno antes que tú. De hecho, estoy terminando mi última semana de servicio social.
>
> A ver, primero hay un aviso que estoy obligado a leer. Es cosa legal, ¿sabes?
>
> "La Coordinación de Sistemas no se hace responsable de daños a la propiedad, a las personas ni a los expedientes académicos. En caso de desaparición, se levantará el reporte en un plazo de setenta y dos horas hábiles." Bla, bla, bla.
>
> No te espantes, eh. Es nada más que los profes de aquí se portan... raro, de noche.
>
> Desde aquella junta de academia no han vuelto a salir del edificio. Nomás... deambulan.
>
> Y si te ven fuera de horario, pues... no te van a reconocer como alumno.
>
> La última vez que alguien se quedó aquí de noche... bueno. Tú nada más cuídate, ¿sí?
>
> Bueno, lo importante. La cortina de la puerta gasta muchísima energía, entonces ciérrala solo cuando haga falta. Las cámaras también gastan, pero úsalas seguido, eh.
>
> Los tickets de la PC te los pagan. O sea... tú trabaja, pero no te pases de listo.
>
> Si ves al profe Mamador en la cámara, ten cuidado. Viene a revisar que todo esté en orden. Que no vea la asistente de la PC abierta, ni la puerta cerrada. Se lo toma muy en serio. Demasiado.
>
> Al profe Juan, alúmbralo con la linterna cuando esté en el cristal. Varias veces, eh. Y se va solito.
>
> Y la botarga del cubículo 3... dale cuerda en la cámara 4. Siempre. No preguntes por qué.
>
> Bueno, ya te dejo. Te hablo mañana. Buenas noches.

#### Noche 2 — 8 frases, 1:12

> ¿Bueno? ¿Bueno? Bueno, si estás oyendo esto y llegaste a la segunda noche... felicidades.
>
> No... no voy a hablar tanto esta vez. Los profes se ponen más activos conforme avanza la semana. Eh, sería buena idea que revises las cámaras mientras te hablo, nomás para ver que cada quien esté en su lugar, ¿sabes?
>
> Bueno. Hoy hay que estar pendientes del profe Barcosa. Está en la sala de servicio del salón B, cámara 10. Es... un caso especial. No le gusta que lo vigilen, pero si dejas de vigilarlo mucho tiempo, se... impacienta.
>
> Si oyes pasos corriendo en el pasillo, cierra la cortina. Rápido. Va a tocar, va a gritar, a lo mejor te pide unos minutos para pasar lista. No abras.
>
> El profe Armando también empieza a moverse hoy. Igual que con Juan: si lo ves en el cristal, linterna hasta que se vaya. Si te habla de inteligencia artificial, tú nomás... asiente.
>
> Ah, y si entran llamadas raras al conmutador, números equivocados y eso... tú cuelga. No es nada.
>
> Y sigue dándole cuerda a la botarga, ¿eh? Esa botarga la usaba un alumno, en los eventos. Bueno, eso no importa ahorita.
>
> Bueno, ya te dejo. Revisa la cámara 10 seguido. Buenas noches.

#### Noche 3 — 9 frases, 1:08

> ¿Bueno? ¿Bueno? Hola. Noche tres. Vas muy bien, de verdad. La mayoría no... bueno. Vas muy bien.
>
> Hoy se despiertan dos más, así que ponle atención a esto.
>
> El profe Ureña empieza en los baños, cámara 12. Es lento, pero llega. Si lo ves en el cristal, linterna, igual que a los otros.
>
> También te va a llamar. Por teléfono. Te va a ofrecer... trabajitos. Tú sé educado. No le sigas el juego, pero tampoco le cuelgues. Se ofende. Y cuando se ofende... viene.
>
> Luego está el profe Rochis, en el cubículo 2, cámara 3. Casi no se mueve. Se la pasa sentado viendo la foto de su esposa, Mónica. Que en paz descanse.
>
> Si ves que se empieza a levantar, ponle el audio desde la cámara. El de "es impresionante". Es su frase. Lo calma. Eso sí, no se lo pongas si está sentado. No le gusta que lo interrumpan.
>
> Es un buen profe. Mucha gente no lo entiende.
>
> Ah, y si oyes una cajita de música sonando sola, es la botarga. El mecanismo que trae adentro. No es nada. No le busques letra.
>
> Bueno, te dejo. Buenas noches.

#### Noche 4 — 10 frases, 1:18

> ¿Bueno? Hola. Eh, rápido, que hoy no tengo mucho tiempo.
>
> Pasó algo en la sala de juntas. Encontraron... cosas. Velas, sal, un dibujo en la mesa. La universidad dice que fue una broma de alumnos. Entonces fue una broma de alumnos, ¿de acuerdo? Si alguien te pregunta, tú no viste nada.
>
> Bueno. Hoy se despierta el Mago Eléctrico. Vive en el techo, cámara 6, y baja por la escalera, cámara 5. Si lo ves en la escalera, baja el breaker. Se asusta y se regresa.
>
> Si llega a entrar, te deja sin linterna. Y sin linterna... bueno. Ya sabes para qué sirve la linterna.
>
> También le da por jugar con el pararrayos. Si se te caen cámaras, ve a la sala de servidores y reconecta los cables como dice la hoja del rack.
>
> Ah, y el profe Armando ya encontró la asistente de la PC. Si te tapa la pantalla, escribe "APÁGATE". Rápido.
>
> Esa junta... nadie sabe quién la convocó. Ni quién apartó la sala. Bueno. Alguien sabe. Siempre alguien sabe.
>
> Y no fue la primera vez que se juntaron. Unas semanas antes vieron a varios profes en Los Rojos, ya muy noche. Nadie sabe qué hacían... pero todos se lo imaginan.
>
> Alguien escuchó que estaban con unas... "trabas". Bueno, eso ya es chisme.
>
> Cuídate. Te hablo mañana.

#### Noche 5 — 6 frases, 0:51

> ¿Bueno? ...Hola. Se filtró una lista. La de la junta extraordinaria. Ocho nombres. Todos tachados en rojo.
>
> Ya sé. Suena feo. Pero así se acostumbra en las juntas, ¿no? Se tacha al que ya... participó.
>
> Hoy van a estar todos despiertos. Todos. Hasta Juan, y Juan nunca está despierto en las juntas. No te quedes mucho en la PC.
>
> Otra cosa, y esto es importante. Si ves a alguien en la oficina que no es profe... alguien que no sale en ninguna cámara... no le hagas caso. No es de aquí. No sabe lo que dice. No confíes en él.
>
> Lo has hecho muy bien, ¿sabes? Mejor que el otro muchacho. Él no pasó de la bienvenida.
>
> Bueno. Una noche más y terminas. Buenas noches.

#### Noche 6 — 0:42, sin diálogo

No habla el guardia anterior: es **estática y una voz de robot al revés**. No hay frases que
subtitular, así que el `.txt` lleva una sola entrada que se queda en pantalla toda la llamada:

> (estática)

---

## 2. Ureña — la llamada de media noche

Tono: meloso, confianzudo, baja la voz al final de cada frase. Llama entre las 2 y
las 4 AM. Hoy lo dice todo la **síntesis de voz de Godot**; estas grabaciones la
sustituirían. El jugador no habla: sus respuestas son solo texto en pantalla.

### Saludo  **[FALTA ENGANCHAR]**

**Ya está resuelto:** se graba la versión **sin nombre**. El nombre del jugador sale
solo en el subtítulo, que es lo que se lee.

| Qué | Texto | Archivo |
| --- | --- | --- |
| Lo que se **lee** | «¡Quihubo, [NOMBRE]! Ya llevas [N] tareas... qué aplicadito.» | — (lo escribe el juego) |
| Lo que se **graba** | «¡Quihubo! Ya vi que andas muy trabajador... qué aplicadito.» | `voces/urena_saludo.ogg` |

El `[N]` se resolvió igual que el nombre: **tampoco se graba**. La voz dice «ya vi
que andas muy trabajador» y la cifra se queda nada más en el subtítulo.

### Insinuaciones  **[FALTA ENGANCHAR]**

Salen 1 o 2 por llamada, sin repetir en la misma noche. 6 s para contestar.

| # | Texto | Archivo |
| --- | --- | --- |
| 1 | «Ando buscando a alguien para unos trabajitos extra... en mi cubículo.» | `voces/urena_linea1.ogg` |
| 2 | «Te quiero convertir en mujer por una noche.» | `voces/urena_linea2.ogg` |
| 3 | «Te subo la calificación... ven a mi oficina a las 3 AM.» | `voces/urena_linea3.ogg` |
| 4 | «¿Me mandas una foto de cuerpo completo? Para el archivo.» | `voces/urena_linea4.ogg` |
| 5 | «Se me puso bien duro... el disco. ¿Me lo formateas?» | `voces/urena_linea5.ogg` |
| 6 | «¿Me haces una conexión punto a punto? Sin switch.» | `voces/urena_linea6.ogg` |
| 7 | «Tengo el cable bien largo... ¿me ayudas a ponchar el conector?» | `voces/urena_linea7.ogg` |

### Reacciones  **[FALTA ENGANCHAR]**

| Texto | Archivo | Cuándo |
| --- | --- | --- |
| «Ay, qué serio...» | `voces/urena_reaccion_esquiva.ogg` | El jugador se zafa con educación |
| «¡Así me gusta!» | `voces/urena_reaccion_sigue.ogg` | El jugador le sigue el juego |
| «Qué grosero eres...» | `voces/urena_reaccion_grosero.ogg` | El jugador le contesta mal |

### Despedidas  **[FALTA ENGANCHAR]**

| Texto | Archivo | Cuándo |
| --- | --- | --- |
| «Ay, qué serio... la oferta sigue en pie.» | `voces/urena_adios_esquivo.ogg` | Esquivó todas |
| «Te dejé un regalito en tu escritorio.» | `voces/urena_adios_foto.ogg` | Le siguió el juego alguna vez |
| «Me rompiste el corazón... y eso se paga.» | `voces/urena_adios_grosero.ogg` | Le contestó mal |
| «¿Me colgaste? ...Ahorita voy para allá.» | `voces/urena_adios_colgado.ogg` | Le colgaron o no contestaron. **Sale por el altavoz de la oficina, después del tono de ocupado** |

---

## 3. Rochis

Tono: profesor mayor, pausado, satisfecho de sí mismo. Cuando se levanta, va en serio.

| Texto | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| «Es impresionante» | `es_impresionante.ogg` | Botón "REPRODUCIR AUDIO" de la CAM 3, para que se vuelva a sentar | **[EN EL JUEGO]** |

> **El nombre del jugador ya no se dice en voz.** No hay nada que grabar: al entrar,
> su nombre sale **escrito en rojo y grande encima del jumpscare**. Si en algún
> momento quieres un gruñido o un «...» antes del salto, ese sí se podría grabar.

| Grito | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Jumpscare de Rochis | `grito.ogg` (común) | Al saltar | **[EN EL JUEGO]**, compartido |
| Jumpscare propio de Rochis | `voces/grito_rochis.ogg` | Al saltar | **[FALTA ENGANCHAR]** |

---

## 4. Barcosa

Tono: enfadado, a gritos, golpeando. Lo que dice no se entiende del todo.

| Qué | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Golpe en la cortina (sin voz) | `golpes_cortina.ogg` | Uno por segundo, los 5 s que aporrea la puerta | **[EN EL JUEGO]** |
| Grito del jumpscare | `voces/grito_barcosa.ogg` | Si te pilla con la puerta abierta | **[FALTA ENGANCHAR]** |

### Lo que dice en la puerta  **[EN EL JUEGO]**

Al empezar a aporrear suelta **una de las tres, al azar**. Al rendirse, siempre la
misma. Mientras no estén grabadas las dice la voz sintética y el texto sale igual
como subtítulo pequeño.

| Texto | Archivo | Cuándo |
| --- | --- | --- |
| «¿Quién cerró? Tengo clase en este salón.» | `voces/barcosa_puerta_1.ogg` | Empieza a golpear |
| «Abra, joven. Nada más paso lista y me voy.» | `voces/barcosa_puerta_2.ogg` | Empieza a golpear |
| «Diez minutos. Le estoy pidiendo diez minutos.» | `voces/barcosa_puerta_3.ogg` | Empieza a golpear |
| «Bueno, ya. Quedan todos con falta.» | `voces/barcosa_se_va.ogg` | Se rinde y vuelve al salón B |

---

## 5. Mamador

Tono: autoridad administrativa, seco, sin levantar la voz. Da más miedo por lo
tranquilo que está.

### Cuando no encuentra nada  **[EN EL JUEGO]**

Una de las tres, al azar, al terminar de inspeccionar desde el cristal.

| Texto | Archivo |
| --- | --- |
| «Sin novedad. Me retiro.» | `voces/mamador_ok_1.ogg` |
| «Nada de inteligencia artificial. Así me gusta.» | `voces/mamador_ok_2.ogg` |
| «Todo en orden. Sigan así.» | `voces/mamador_ok_3.ogg` |

### El resto

| Texto | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| «¡Delito federal!» | `voces/mamador_delito.ogg` | Llega al cristal y te ve la ventana de Claudio abierta o la puerta cerrada. Es el game over de los militares | **[FALTA ENGANCHAR]** |
| Pasos lentos y llavero | `voces/mamador_aviso.ogg` | Su sonido propio de aviso, mientras baja por el pasillo | **[FALTA ENGANCHAR]** |

> Mamador **no tiene jumpscare**: su game over es la pantalla de los militares. No
> hace falta grito, pero sí sirve ambiente de sirenas y radio de policía.

---

## 6. Mago Eléctrico

Tono: risa corta y burlona, nada de frases. Es el que te fastidia, no el que te mata.

| Qué | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Risa del cortaso | `voces/mago_risa.ogg` | Entra a la oficina, chispazo y pantalla en negro 0.5 s. Después la linterna queda muerta | **[FALTA ENGANCHAR]** |
| Grito del jumpscare del apagón | `voces/grito_mago.ogg` | Al final de la secuencia del apagón, tras los tres pasos | **[FALTA ENGANCHAR]** |

---

## 7. Juan.exe

Tono: plano, como si leyera. No tiene mecánica propia y hoy no dice nada.

| Qué | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Respiración en el cristal | `voces/juan_respiracion.ogg` | En bucle y bajita mientras está pegado al cristal; se corta cuando se va | **enganchada** |
| Grito del jumpscare | `voces/grito_juan.ogg` | Si no lo ahuyentas con la linterna a tiempo | **[FALTA ENGANCHAR]** |

---

## 8. Armando Prompts

Tono: locutor de curso de internet, seguridad absoluta, cero autocrítica.

Las seis frases ya salen escritas a pantalla completa en la PC desde la noche 4.
Grabadas darían mucho más. **[FALTA ENGANCHAR]**

| # | Texto | Archivo |
| --- | --- | --- |
| 1 | «HOLA, SOY ARMANDO PROMPTS, INGENIERO EN PROMPTS CERTIFICADO POR MÍ MISMO.» | `voces/armando_frase1.ogg` |
| 2 | «LE PEDÍ A CLAUDIO QUE HICIERA TU TAREA. TAMBIÉN LE PEDÍ QUE TE CORRIERA.» | `voces/armando_frase2.ogg` |
| 3 | «ESTE MENSAJE FUE GENERADO CON IA. YO NI LO LEÍ.» | `voces/armando_frase3.ogg` |
| 4 | «MI TESIS LA HIZO CLAUDIO. MI BODA TAMBIÉN.» | `voces/armando_frase4.ogg` |
| 5 | «AUTOMATICÉ MIS SENTIMIENTOS. AHORA SUFRO 40% MÁS RÁPIDO.» | `voces/armando_frase5.ogg` |
| 6 | «¿PENSAR? NAH, ESO ES DE BOOMERS.» | `voces/armando_frase6.ogg` |

| Otros | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Grito del jumpscare | `voces/grito_armando.ogg` | Si no lo ahuyentas en el cristal | **[FALTA ENGANCHAR]** |

---

## 9. Santi / la botarga del Come Trabas

Santi era un alumno de Sistemas. Un ritual encerró su alma dentro de la botarga de
la mascota. Tono: voz de chavo joven, ahogada, como desde dentro de un disfraz.

| Qué | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Canción de cajita musical | `cajita_musical.ogg` | En bucle mientras la botarga tenga cuerda. **No es voz**, pero es su sonido | **[EN EL JUEGO]** |
| Respiración o quejido al levantar la cabeza | `voces/santi_despierta.ogg` | La cuerda llega a cero y la botarga levanta la cabeza en la CAM 4 | **[POR ESCRIBIR]** |
| Grito del jumpscare | `voces/grito_cometrabas.ogg` | Cuando la botarga llega a la oficina | **[FALTA ENGANCHAR]** |
| «Voces, muchas voces» dentro de la botarga | `voces/santi_voces.ogg` | Pista de las Trabas, del recorte de la noche 4. Sin momento asignado todavía | **[POR ESCRIBIR]** |

> De quién es la canción de la cajita musical se guarda para la segunda entrega. No
> se menciona en ningún texto del juego, solo se oye.

---

## 10. Gritos y sonidos vocales, juntos

Hoy **todos los jumpscares comparten un mismo grito provisional** generado por
código. Lo mínimo imprescindible es grabar uno bueno; lo ideal, uno por personaje.

| Personaje | Archivo | Estado |
| --- | --- | --- |
| Común a todos (lo que se usa hoy) | `grito.ogg` | **[EN EL JUEGO]** |
| Barcosa | `voces/grito_barcosa.ogg` | **[FALTA ENGANCHAR]** |
| Ureña | `voces/grito_urena.ogg` | **[FALTA ENGANCHAR]** |
| Rochis | `voces/grito_rochis.ogg` | **[FALTA ENGANCHAR]** |
| Juan.exe | `voces/grito_juan.ogg` | **[FALTA ENGANCHAR]** |
| Armando Prompts | `voces/grito_armando.ogg` | **[FALTA ENGANCHAR]** |
| Come Trabas (botarga) | `voces/grito_cometrabas.ogg` | **[FALTA ENGANCHAR]** |
| Mago Eléctrico | `voces/grito_mago.ogg` | **[FALTA ENGANCHAR]** |
| Mamador | — | No salta: su game over es la pantalla de los militares |

---

## 11. Lo que no es voz pero se graba igual

Para que la lista de encargo quede completa, los sonidos no vocales que el juego ya
espera están en `data/sounds.gd`. Los que más se notan:

| id | Archivo | Qué es |
| --- | --- | --- |
| `ambiente_oficina` | `ambiente_oficina.ogg` | Zumbido de lámparas y ventilador, en bucle |
| `ambiente_pasillo` | `ambiente_pasillo.ogg` | Viento lejano y crujidos, en bucle |
| `telefono_timbre` | `telefono_timbre.ogg` | Timbre de teléfono de oficina |
| `puerta_cortina` | `puerta_cortina.ogg` | Cortina metálica al bajar y subir |
| `golpes_cortina` | `golpes_cortina.ogg` | Barcosa aporreando |
| `pasos_acercandose` | `pasos_acercandose.ogg` | Los tres pasos del apagón |

La lista completa, con buses y volúmenes, está en `CLAUDE.md`, sección **Audio**.

