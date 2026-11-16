# El Ajedrez humano — misión del alcalde y minijuego (palabras del usuario, 16 de noviembre de 2026)

> Solo se podrá hacer después de haber finalizado la misión de los recreativos. La dará el alcalde desde el
> ayuntamiento. Te dirá que desde que perdió en el torneo de Tokken 9 ha dejado un poco los videojuegos y ha vuelto a
> sus antiguos hobbies, como el ajedrez. La cámara hará un plano aéreo desde donde estáis vosotros al tablero de
> ajedrez que hay en el ayuntamiento. Te dirá que cuando mira por la ventana de su oficina puede ver el tablero y se
> imagina partidas y tácticas en cabeza para entrenar. Lo más gracioso es que como ve a gente del pueblo pasar, las
> figuras que se imagina han empezado a ser gente del pueblo: gente alta los alfiles, gente baja las torres, niños los
> peones, perros los caballos... E incluso a él y a su mujer de reina y rey. (Para el juego las fichas serán estos
> mismos personajes pero coloreados en blanco y en gris para poder jugar, parecido al fraile del convento, pero tendrán
> su animación de idle.) Te dirá que si piensas que está loco [opción a elegir entre "Noooo, que vaaa, muy normal
> todo" y "Como una puñetera regadera"]. A la primera responderá que no le gustan los sarcasmos, que bastante tiene
> que aguantar en el trabajo, y a la segunda se reirá y apreciará tu sinceridad. Pasará a despedirse porque tiene
> mucho trabajo (entre paréntesis pondrá, como si hablase entre dientes, "y una partida abierta en SuperChess 2.0").
> Te saldrá un cartel de "Has desbloqueado el Ajedrez humano como minijuego". Y siempre que pases por encima del
> tablero, el botón de acción será "Jugar", que empezará una partida de ajedrez. Hay que hacer un juego de ajedrez con
> los personajes del juego. No sé cómo podemos implementar bots de ajedrez contra los que jugar con distintas
> dificultades: dame opciones para esto. Ganar dará puntos cívicos en función de la dificultad.

## Lo que eligió el usuario (16/11)

- **Los bots:** un minimax propio en GDScript, con poda alfa-beta (descartados Stockfish, por GPL-3 y por llevar un
  programa por plataforma, Android incluido, y un motor en C++ como extensión de Godot).
- **El rival:** el alcalde en los cuatro niveles; cada nivel es lo en serio que se lo toma.
- **Niveles y Puntos Cívicos:** cuatro, y como son partidas largas, que merezca la pena: 4, 6, 8 y 12.

## Lo que hay

- **Archivos:** `godot/scripts/ajedrez.gd` (reglas e IA), `godot/scripts/ajedrez_humano.gd` (misión y minijuego),
  `godot/assets/ajedrez/perro.glb` (los caballos).
- **Misión «Partidas en la cabeza»:**
  - El alcalde lleva la flecha verde en la puerta del ayuntamiento en cuanto se acaba lo de los Recress.
  - Plano de los dos. La cámara sube y pasa por encima del tablero oeste de la plaza, mirando desde el lado del
    ayuntamiento, como desde su ventana.
  - Las piezas que se imagina van saliendo en el tablero según las nombra, con su ropa de siempre (es su imaginación).
  - La pregunta, con las dos respuestas.
  - El paréntesis va en gris y en cursiva: en los textos, `((…))` es «entre dientes».
  - El cartel con las palabras del usuario.
- **El minijuego:**
  - Encima de cualquiera de los dos tableros, el botón dice «Jugar». También se juega desde la Agenda, en Minijuegos:
    los cuatro niveles, que te llevan al tablero.
  - Eliges nivel y bando: blancas, grises o a suertes. El tablero se gira para que tu bando quede siempre cerca de la
    cámara.
  - Se juega con el ratón, el dedo o el cursor (teclas o mando). Hay vista desde tu lado o casi cenital, y un menú
    para seguir, dejarla para luego o rendirse.
  - Las piezas andan a su casilla. Los perros saltan. Las piezas comidas se caen, se levantan y se quedan de
    espectadoras a un lado del tablero.
  - Coronar pregunta en qué se convierte el crío.
  - El alcalde piensa en un hilo aparte, sin parar el juego, y comenta las jugadas en el panel.
  - Mientras dura la partida, el pueblo se queda quieto, pero la hora sigue corriendo: el día, el cielo y las farolas avanzan. Lo pidió el usuario a Sistemas, que lo hizo el 16/11: «que el tiempo siga pasando mientras juega, una partida de ajedrez es larga y puede gastar fácilmente más de un día».
  - Al ganar: sello «¡JAQUE MATE!» y los Puntos Cívicos del nivel en la pizarra.

## Retoques del usuario (16/11)

> Por las fotos los perros parece que están al revés de donde deberían mirar (hacia la dirección que se mueven). Y
> creo que las piezas se pueden confundir una vez empiezan a moverse. Qué tal si a cada pieza le ponemos un holograma
> encima de su cabeza que indiquen qué pieza son? Un simple .png que siempre mire a cámara, así la pieza siempre está
> clara.

- **Los perros:** el modelo mira hacia su −Z, y ahora va girado. Saltan mirando adonde van y, parados, miran a tu lado
  como las demás piezas.
- **El holograma:**
  - Encima de cada pieza va el símbolo de ajedrez de lo que es, siempre de cara a la cámara. Es blanco o gris como la
    pieza, con una línea oscura, el borde y el brillo cian, y líneas de barrido.
  - Flota y parpadea un poco. Se ve del mismo tamaño cerca o lejos.
  - El de la pieza que tienes cogida crece. Al comer una pieza, su holograma se apaga.
  - Lo dibuja `tools/make_ajedrez.py` con los símbolos de DejaVu Sans (se sube el dibujo, no la fuente):
    `godot/assets/ajedrez/holo_<pieza>_<blanca|gris>.png`.

## Veredicto

El usuario, el 16/11, tras ver los retoques: «Visto bueno». Lo de debajo no lo ha comentado.

## Elegido por mí, pendiente de confirmar

- **Reparto:**
  - Alfiles: Venancio (el de la chistera) y Katakumba69 (el más alto), algo más grandes.
  - Torres: Tía Paca y Josefa.
  - Peones: Kevin y siete críos del pueblo, sacados como los de la plaza.
  - Caballos: el «Shiba Inu» de Quaternius (CC0), con sus animaciones de reposo, galope, salto y caída.
  - Rey y reina: el alcalde y su mujer, con una coronita.
- **Cómo van pintadas:** blancas o grises, como el fraile. Los ojos, las cejas y las monturas van en un tono oscuro,
  para que se lean las caras.
- **Hacia dónde miran:** todas las piezas miran a tu lado del tablero (de espaldas no se reconoce a nadie), y giran
  la cabeza hacia la casilla del cursor.
- **Los niveles por dentro:**
  - «Con desgana»: piensa 1 jugada, con mucho ruido y despistes gordos.
  - «Entre dientes»: piensa 2.
  - «En serio»: piensa 3.
  - «Modo SuperChess 2.0»: piensa hasta 5 o 6 jugadas en unos 4 s en el PC, sin despistes.
  - En el móvil, el nivel alto pensará menos jugadas en el mismo tiempo. Sin probar en un móvil.
- **Puntos Cívicos:**
  - Por cada victoria, siempre, sin límite diario: decidido. Como la hora corre mientras juegas, cada partida cuesta su tiempo de juego. El boxeo solo da 1 PC la primera victoria del día.
  - Las tablas no dan nada.
  - La conversación con el alcalde no da Puntos Cívicos ni sello ¡APAÑAO!: solo el cartel que pidió el usuario.
- **Confianza:** la respuesta sincera suma 5 de confianza con el alcalde; el sarcasmo no resta.
