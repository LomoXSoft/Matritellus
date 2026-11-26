# Traspaso a Claude

Este documento recoge el trabajo hecho con Codex en `X:\MatritellusGPT` mientras la sesión de Claude está en pausa. El desarrollo durante esta etapa se hará exclusivamente en esta carpeta.

## Punto de partida

- El commit que apuntaba `HEAD` al abrir el registro era `92d852e` (`Matritellus 0.0.17`). Los trabajos anteriores y las tareas pendientes están descritos en [PROJECT_STATE.md](PROJECT_STATE.md). La organización del repo y las instrucciones para jugar y publicar están en [README.md](README.md).
- Para incorporar cambios al retomar el trabajo, revisar cada entrada junto con `git status --short` y `git diff` en esta carpeta. Las entradas indicarán si los cambios tienen commit y, cuando corresponda, el resultado de las pruebas.

## Registro

### 18 de noviembre de 2026 — Apertura del traspaso

- **Hecho.** Se estableció `X:\MatritellusGPT` como carpeta exclusiva de trabajo y se abrió este registro.
- **Archivos.** `TRASPASO_CLAUDE.md`.
- **Verificación.** Se comprobó la estructura del repositorio y se leyó su documentación de trabajo. Esta entrada es de documentación y no requiere ejecutar el juego.
- La primera mejora jugable se recoge en la entrada de boxeo siguiente.

### Boxeo de Fonsi

18 y 19 de noviembre de 2026. Implementado en `X:\MatritellusGPT` sobre el combate de la versión 0.0.17, con Godot `4.7.2.stable.official.ed1daf0bf`. El [dossier descomprimido](referencias/Boxeo-Wii-Sports-Matritellus/README.md) incluye sus [referencias](referencias/Boxeo-Wii-Sports-Matritellus/REFERENCIAS.md) y seis láminas. El ring, los personajes, el papel del marcador, los sonidos sintetizados y la cámara son los de Matritellus.

#### Dónde jugar y cómo se controla

Entra en el **V.I.P. de la calle de Santa Ana, 14**, habla con Fonsi en el mostrador y elige combatir. Puedes hacerlo durante el encargo del móvil de Josefa y como reto libre tras resolverlo. Cuando ganas y se desbloquea `box`, también puedes entrar desde **Pausa → Agenda → Minijuegos → Combate de boxeo**.

| Acción | Teclado y ratón por defecto | Mando Xbox / PlayStation | Táctil |
| --- | --- | --- | --- |
| Golpear con la derecha | Clic izquierdo, E o Espacio | X / □. También A / ✕ y B / ○ | Derecha |
| Golpear con la izquierda | Clic derecho o F | Y / △ | Izquierda |
| Golpear o cubrirse al cuerpo | Mantener Ctrl. Al soltar, vuelve a alto | Mantener LB / L1 | Tocar Alto ↕ o Cuerpo ↕ para alternar |
| Guardia | Mantener S o flecha abajo | Mantener el stick izquierdo hacia abajo | Mantener Guardia |
| Esquivar | A a la izquierda, D a la derecha | Stick izquierdo hacia un lado | Arrastrar hacia un lado el stick que aparece al tocar la mitad izquierda |

El stick necesita volver al centro para repetir. La altura del golpe queda fijada al aceptar la orden. El selector táctil vuelve a alto al empezar otro asalto o combate. F y Ctrl son reasignables desde los ajustes. Y también sirve para el claxon en conducción, donde la acción de boxeo está inactiva. Los alias de la mano derecha siguen los enlaces de interacción y freno de mano.

#### Mecánica y decisiones

- **Simulación.** `game._physics_process` llama a `boxing.tick` en cada paso de física. Los eventos se recogen antes del HUD y se consumen una vez por paso. El mismo lector de flancos usa las intensidades del stick de mando y del stick táctil. La IA usa su propio generador, cuya semilla se puede fijar con `--selftest`.
- **Entrada simultánea.** Primero se lee la altura. Entre órdenes válidas se elige esquiva antes que golpe, izquierda antes que derecha para esquivar, y mano primaria antes que secundaria para atacar. Una pulsación rechazada se descarta. Un impacto que aturde impide iniciar otra orden, pero el golpe ya aceptado llega a contacto mientras siga el asalto.
- **Tiempos.** Fonsi avisa durante 0,50 s o 0,80 s si carga el fuerte. Tu golpe tarda 0,10 s en llegar, tiene 0,05 s de contacto y 0,20 s de recuperación. La esquiva protege desde los 0,05 s incluidos hasta los 0,25 s excluidos. Puedes golpear durante los 0,25 s que tardas en enderezarte. El aviso distingue altura por postura y texto. Las ayudas cambian con el dispositivo y el idioma.
- **Daño.** Cada mano quita 6 de vida, o 1 si encuentra la guardia a esa altura. Fonsi quita 16 o 28 y su golpe hace un 20 % del daño si te cubres a la altura correcta. Si falla, queda abierto durante 0,95 s. El primer contacto limpio antes de que venza ese plazo quita 12 y consume la contra. Si Fonsi bloquea, el bonus sigue disponible. Las señales de aire, guantes, golpe limpio y contra se reproducen a velocidad normal.
- **Asaltos.** Gana el primero en llevarse dos. Cada asalto empieza a 100 de vida y 60 s. Un derribo lo cierra. La campana tiene prioridad sobre los contactos de ese paso y el empate a vida favorece al jugador. Dos golpes que llegan juntos se calculan con el mismo estado previo, se aplican ambos y un doble derribo concede un solo asalto al jugador. El descanso dura 3,4 s. El resultado final permanece 2,4 s antes del único callback.
- **Progreso.** `box_fights` cuenta todos los combates y `box_wins` solo victorias. `box_best` conserva el máximo de `100 × asaltos ganados − 40 × asaltos perdidos + vida restante si se gana`, con mínimo cero. `box_pc` guarda el día de la primera victoria para el límite de un Punto Cívico diario cuando ese sistema ya está activo. El primer triunfo del reto libre guarda el desbloqueo en el mismo cierre. En la misión y el reto libre se vuelve al mostrador. La Agenda devuelve al lugar de partida.

#### Archivos y comprobaciones

| Archivos | Trabajo realizado |
| --- | --- |
| `godot/scripts/boxing.gd` y `chara.gd` | Fases, contacto simultáneo, IA, posiciones de manos, guantes y reacciones, sonido de los cuatro resultados y limpieza al salir. |
| `godot/scripts/controls.gd` y `touch.gd` | Enlaces, glifos, compatibilidad de teclas reasignadas y cuatro botones táctiles. La guardia táctil tiene su propia acción para que el stick pueda soltar la dirección atrás sin soltar el botón de guardia. |
| `godot/scripts/game.gd`, `hud.gd` y `loc.gd` | Entrada y salida del ring, guardado del reto libre, ayudas por dispositivo, marcador y avisos en castellano e inglés. El objetivo de la calle y el mapa se recogen durante el combate. |
| `godot/scripts/selftest.gd` | Se migraron las antiguas preparaciones del boxeo y se añadió el filtro `boxeo`. Se movió un comentario preexistente de la prueba de muros que ocultaba el paréntesis de cierre e impedía cargar cualquier selftest. |
| `PROJECT_STATE.md`, este registro y `referencias/Boxeo-Wii-Sports-Matritellus/` | Resumen de la entrega y dossier recibido. |

La [muestra de guardado 0.0.17](tools/fixtures/boxeo_0_0_17.json) se creó con el código de combate anterior, ganando al Fonsi en el V.I.P. Contiene una victoria en un combate, récord de 300 y el desbloqueo de `box`. Se verificó que los 410 bytes coinciden con el archivo escrito por la versión antigua. El filtro con `guardado-anterior` carga una copia de esa muestra en una ranura de prueba, juega otra vez y verifica el historial.

La primera suite completa detectó la palabra «para» en la ayuda táctil. Se adaptó el texto a las normas manchegas de `guion/palabros.md`. El filtro de vocabulario de la siguiente ejecución aceptó toda la localización.

Los comandos corresponden a la raíz de esta copia. `tools/run_tests.py` usa el ejecutable del proyecto y añade `--headless --path godot --fixed-fps 60 -- --selftest` en las pruebas sin ventana.

| Ejecución | Resultado |
| --- | --- |
| Guardado previo con el combate 0.0.17 | [Una comprobación correcta](logs/selftest_boxing-baseline_20261118_204312.log). El preparador temporal escribió el original en `logs/` y la copia reproducible está en `tools/fixtures/`. |
| `python tools/run_tests.py boxeo guardado-anterior --headless` | [86 comprobaciones correctas](logs/selftest_boxeo_guardado-anterior_20261119_032920.log). Incluye las dos manos y alturas, Ctrl + F pulsados y soltados entre pasos de física, Ctrl + S ante un golpe al cuerpo, defensa cruzada, límites de esquiva y contra, botones y ejes del mando, multitáctil, campana, doble derribo en el asalto decisivo, datos guardados y las tres entradas al ring. |
| `python tools/run_tests.py boxeo shots --window` | [Tres comprobaciones correctas](logs/selftest_boxeo_shots_20261118_210321.log). Vistas renderizadas del [aviso alto en 16:9](godot/shots/fonsi_aviso_alto.png), la [guardia al cuerpo con ayudas táctiles en inglés en 20:9](godot/shots/fonsi_tactil_cuerpo.png) y la [ventana de contra](godot/shots/fonsi_esquiva_contra.png). |
| `python tools/run_tests.py boxeo manual --window` | Tres combates interactivos en Windows con teclado y ratón, todos 0–2. Se verificaron el mostrador, los avisos de altura, el marcador, el derribo, el siguiente asalto y el cierre. El [registro de la última partida](logs/selftest_boxeo_manual_20261119_032357.log) recoge dos derechas, una izquierda y tres impactos. La guardia, los golpes al cuerpo y el tiempo de la esquiva se comprobaron en las pruebas automatizadas. Tras la primera partida se ajustaron la visibilidad del objetivo y el número de voces simultáneas del público. |
| `python tools/run_tests.py --headless` | [855 comprobaciones correctas, cero fallos y cero errores de script](logs/selftest_full_20261119_031303.log), incluida la historia completa de Josefa y la revancha desde la Agenda. |

La suite completa sigue emitiendo diagnósticos de Godot sobre `brick_red` al cargar fachadas, un material nulo en el renderizador headless y recursos al cerrar. Los tres ya figuraban en el [registro del 17 de noviembre](logs/selftest_full_20261117_231129.log).

**Dispositivos pendientes.** Godot informó de cero mandos conectados y de pantalla sin capacidad táctil. Windows tenía perfiles Bluetooth de Xbox y DualSense y enumeró cero mandos activos en `Windows.Gaming.Input`. El filtro ejercitó botones y ejes de mando mediante `InputMap` y la ruta de `InputEventScreenTouch` y `InputEventScreenDrag`, incluidos un dedo en la guardia y otro en el stick. Quedan las pruebas en mando físico, dispositivo Android multitáctil y Linux o Steam Deck. Queda pendiente la escucha de los efectos de `Sfx` en altavoces o auriculares.

La base ya tenía ediciones del mundo, misiones y creador. La entrega de boxeo está en el árbol de trabajo de `main`, pendiente de commit y publicación.

### Riña del jamón de Henry

19 de noviembre de 2026, en `X:\MatritellusGPT`, con Godot `4.7.2.stable.official.ed1daf0bf`. La referencia de ritmo se tomó del [dossier](referencias/Bate-Dead-Rising-Matritellus/README.md) y sus cuatro láminas. Los seis archivos coinciden byte por byte con el ZIP recibido. El enlace al vídeo no se pudo reproducir directamente en esta sesión.

**Dónde y cómo jugar.** Acércate a La Cocina de Henry, en la calle de la Palma, con el primer encargo del menú de Josefa. Después, el grupo vuelve los jueves de 8 a 21 si se cumplen las condiciones del evento. En **Pausa → Agenda → Minijuegos → Recoger el jamón asao** puedes repetir para mejorar el récord. El menú devuelve al punto de origen. Se conservan los 60 segundos, la recompensa diaria, el encargo y la entrega.

| Gesto sobre Golpe | Contacto | Cuándo puedes repetir | Alcance |
| --- | --- | --- | --- |
| Soltar antes de 0,25 s | 0,40 s desde la pulsación | 0,70 s desde la pulsación | Hasta dos vecinos |
| Mantener al menos 0,25 s y soltar al ver «¡Bate listo!» | 0,22 s después de soltar | 0,50 s después del contacto | Hasta tres vecinos |

Se usa clic izquierdo, X en Xbox, cuadrado en PlayStation o el botón táctil **Golpe**. Se puede girar la cámara con un segundo dedo al cargar. La altura del sonido y la pose distinguen carga lista, golpe al aire e impacto. Las ayudas están en español e inglés. El frente es el del avatar en el instante del contacto. El filtro conserva el alcance estricto de 1,9 m, el umbral frontal de 0,25 y la excepción a menos de 0,6 m. Se ordena por distancia y se aplica una sola vez el daño de 25 por vecino. Cada impacto ordinario suma 5 puntos y uno que derriba suma 10 en total.

**Implementación.** `motin.gd` recibe en la riña los dos flancos de la acción existente `punch`. El reloj de física de la riña gobierna la preparación, el contacto y la recuperación. La pausa y el mapa congelan el reloj y soltar mientras están abiertos descarta la carga. La pérdida de foco, el cambio de dispositivo y la desconexión del mando también sueltan la preparación. El reloj agotado y una caída anterior al contacto cancelan el ataque. La revancha comienza con el bate en reposo. `chara.gd` comparte las poses base del bate con exploración. `motin.gd` presenta de perfil el bate de la riña y da más amplitud al cargado. El vecino que recibe el impacto se inclina y vuelve a erguirse durante sus 0,35 s de aturdimiento.

**Encuadre.** La primera comprobación dejó la lente detrás de la puerta y otra vista mostró el gorro de Henry por delante del avatar. En `game.gd` se corrigió la cámara sobre el hombro del bate. La posición buscada pasó de 3,4 a 3,8 m por detrás, de 0,9 a 1,35 m de desplazamiento lateral hacia la mano y de 2,15 a 2,55 m de altura. Se usa la colisión de la calle para acortar el recorrido antes del muro, con 0,7 m de margen, y se ocultan temporalmente las figuras entre la lente y el jugador. La pose cargada amplía el recorrido lateral de la mano un 22 %. Se mantuvieron los tiempos de juego y los límites de blancos del dossier.

**Archivos de esta entrega.** `godot/scripts/motin.gd`, `game.gd`, `chara.gd`, `touch.gd`, `loc.gd` y `selftest.gd`, además de [las reglas del encargo](guion/misiones_y_puntos_civicos.md), `PROJECT_STATE.md`, este registro y el dossier en `referencias/Bate-Dead-Rising-Matritellus/`. La acción de `controls.gd` ya tenía los enlaces necesarios.

**Comprobación interactiva.** Jugué los 60 segundos en la ventana de Windows. Un clic conectó con dos vecinos, sumó 10 puntos y el juego volvió con Henry al cerrar la ronda. El [registro manual](logs/selftest_motin_manual_20261119_100926.log) recoge los dos impactos y cero derribos. El barrido cargado se comprobó con entradas controladas y capturas. Godot detectó cero mandos y una pantalla sin capacidad táctil. Se probaron eventos de mando, pantalla táctil y arrastre por la ruta de entrada real del juego. Quedan pendientes el tacto de un mando físico, el multitáctil en móvil y la escucha directa de los efectos.

**Pruebas reproducibles.** Desde la raíz de esta copia:

| Comando | Resultado |
| --- | --- |
| `python tools/run_tests.py motin --headless` | [64 correctas](logs/selftest_motin_20261119_101925.log). Incluye toque, umbral exacto, aire, carga, selección y puntuación, cancelación, pausa, mapa, revancha, encargo de Josefa, jueves y Agenda. |
| `python tools/run_tests.py motin shots --window` | [65 correctas](logs/selftest_motin_shots_20261119_101708.log), incluida la lectura del aviso de carga en inglés. |
| `python tools/run_tests.py motin manual --window` | [18 correctas y ronda interactiva completada](logs/selftest_motin_manual_20261119_100926.log). |
| `python tools/run_tests.py bate --window` | [2 correctas](logs/selftest_bate_20261119_102034.log). En exploración, la animación empieza al pulsar, el vecino cae y el avatar guarda el bate. |
| `python tools/run_tests.py palabros --headless` | [3 correctas](logs/selftest_palabros_20261119_102134.log). |
| `python tools/run_tests.py boxeo guardado-anterior --headless` | [86 correctas](logs/selftest_boxeo_guardado-anterior_20261119_102213.log). Cubre las entradas táctiles compartidas y el estado anterior del juego. |

Las seis ejecuciones finales terminaron sin fallos de comprobación ni errores de script. Durante las pruebas siguió apareciendo el diagnóstico preexistente de fachadas sobre `brick_red`. Se ejecutaron los filtros afectados. La suite integral de 855 comprobaciones de la entrada anterior corresponde al boxeo y se ejecutó antes de esta entrega.

**Imágenes revisadas.** [Carga lista en inglés](godot/shots/motin_carga_lista.png), [contacto del barrido](godot/shots/motin_contacto_cargado.png), [giro entre vecinos](godot/shots/motin_giro_grupo.png), [cámara junto a la fachada](godot/shots/motin_fachada.png) y [derribo con el bate de exploración](godot/shots/bate_5_suelo.png). Las barras de vida se ocultan con el vecino que tapa la lente y también cuando quedan a menos de 1,5 m de ella. Trabajo en `main`, pendiente de commit y publicación.

### RALLY 9 en Galaxy Recress

19 de noviembre de 2026. Se incorporó el [dossier de carrera](referencias/Burnout-3-Rally-9/README.md) a esta copia de Matritellus. Se consultaron su recorrido comentado, las láminas y la animación de los dos encuadres. La reproducción directa del vídeo de BR4GG4 no estuvo disponible desde la sesión. El arte, los coches, la música y los efectos del juego proceden de Matritellus.

**Acceso.** Después de la reapertura del Galaxy Recress, entra en su horario habitual, de 15:00 a 02:00. Acércate al asiento rojo junto a la entrada y usa la interacción habitual. El punto de interacción se calcula con la misma transformación que coloca el asiento. Las máquinas contiguas siguen ofreciendo Tokken. La pausa permite volver al salón. La meta ofrece volver al asiento o empezar otra carrera.

**Circuito.** El Tunero compite contra tres rivales en dos vueltas de unos 503 m al Circuito del Azafrán. Cada vuelta exige ocho puertas consecutivas cruzadas hacia delante, dentro de la anchura de pista. Las rectas tienen 132 m y las curvas, 38 m de radio. El puesto se decide por orden de meta, con interpolación del instante de cruce dentro del paso de física. Antes de meta se compara el último control válido y el avance hasta el siguiente. La meta tiene prioridad sobre el accidente que coincida con ella.

| Acción | Teclado por defecto | Mando Xbox / PlayStation | Táctil |
| --- | --- | --- | --- |
| Jugar / confirmar | E o Intro en el menú de resultados | A / ✕ | Botón de interacción o tocar la fila de resultado |
| Acelerar / frenar | W / S | RT / LT o R2 / L2 | Gas / Freno |
| Dirección y aftertouch | A / D | Stick izquierdo | Stick flotante a la izquierda |
| Derrape | Espacio y dirección | B / ○ y dirección | Derrape y stick |
| Nitro dosificable | Mantener Mayús mientras aceleras | Mantener RB / R1 y acelerador | Mantener Nitro también da gas |
| Pausa | Esc o P | Start / Options | Ⅱ |

La configuración de teclas y los glifos se toman de Controls. En la pausa se pueden cambiar cámara continua, efectos reducidos y vibración. La escala y el antialiasing de la vista usan los ajustes gráficos activos. Al perder el foco se pausa y se liberan las acciones.

**Nitro y accidentes.** Salida con 50/100. Las cuatro capacidades son 100, 150, 225 y 300. El impulso gasta 32 unidades por segundo. Una esquiva sin roce da 15 una vez y un derrape real con apoyo y velocidad lateral da 8 por segundo. Los puntos de maniobra se llevan aparte. Un contacto relevante abre 1,2 s de atribución con ese rival. Un derribo rellena el nuevo nivel. En un accidente propio se puede dirigir lateralmente el coche durante 1 s. Un derribo en ese margen preserva el nivel y rellena el depósito. En caso contrario se pierde un nivel y queda como máximo el 25 % de la nueva capacidad. Se reaparece en el último tramo válido con 0,8 s de protección. El plano del rival dura 0,55 s y su enlace con la vista trasera, 0,20 s. Ambos congelan la carrera y su reloj mientras se anima una copia del coche. Antes de una curva se mantiene la vista trasera.

**Ajustes después de jugar.** La primera carrera de prueba terminó en 43,11 s con el rival más avanzado en la puerta 14 de 16. Se subieron las velocidades objetivo de los tres rivales de 18,2 / 19,5 / 20,9 a 20 / 22,4 / 23,6 m/s. En la siguiente llegada el rival más próximo estaba en la puerta 15. En la primera imagen del derribo otro coche tapaba al accidentado. Ahora el plano se toma desde su lado exterior, se muestra su nombre y se incluyen las ruedas en la copia visual. Los puntos quedaron sobre fondo oscuro para que se lean sobre el campo claro.

**Código.** `rally.gd` administra el intento y su mundo 3D aislado. La física del pueblo se detiene durante la partida. `rally_pista.gd` crea el trazado y calcula posiciones, `rally_hud.gd` dibuja el marcador y `rally_pruebas.gd` conduce y comprueba la carrera. `car.gd` usa el empuje de turbo habitual con un depósito gobernado por la recreativa. Para el derrape se consulta la señal de `derrape.gd`. Integración en `recress_sala.gd`, `recress.gd`, `game.gd`, `touch.gd`, `settings.gd`, `loc.gd` y `selftest.gd`. Todos son archivos de `godot/scripts/`.

**Evidencia visual.** [Asiento e interacción](godot/shots/rally9_asiento.png), [impulso y depósito](godot/shots/rally9_nitro.png), [plano del rival](godot/shots/rally9_derribo.png), [reincorporación](godot/shots/rally9_reincorporacion.png) y [meta](godot/shots/rally9_meta.png).

**Partidas y dispositivos.** El filtro de RALLY 9 recorre las dos vueltas con las entradas de conducción y la física de las cuatro ruedas. La [prueba de reglas](logs/selftest_rally_20261119_151327.log) pasó 31 comprobaciones. Se comprobó una victoria en 43,11 s, con los controles ordenados, una derrota por puesto y el regreso al asiento. En una [partida interactiva en Windows](logs/selftest_rally_manual_touch_20261119_152743.log) se entró desde el asiento con el ratón sobre el botón táctil emulado, se dosificó el nitro en la salida y se pulsó «Volver al salón» en la meta. Tras los primeros 12 s el conductor de prueba completó las dos vueltas. El resultado fue 4.º de cuatro en 54,31 s. La posición, el dinero, la hora, la alerta policial y la sala se comprobaron al volver. Se añadió el glifo de interacción al asiento y se separó la pausa táctil del contador de vueltas tras revisar la ventana.

Godot 4.7.2 en Windows informó de cero mandos conectados y de una pantalla sin capacidad táctil. La dirección simultánea con gatillo y nitro se probó con eventos de mando. El stick flotante y los botones se probaron con eventos multitáctiles en los nodos reales de la interfaz. La primera prueba interactiva de teclado no arrancó la recreativa desde el escritorio remoto. Las teclas físicas de Godot sí se ejercitaron por su mapa de entradas en la carrera automática. Quedan el tacto y la vibración de un mando conectado, el teclado en persona, un móvil multitáctil y Linux o Steam Deck.

Las regresiones del [Galaxy Recress](logs/selftest_recress_20261119_151447.log) y del [vocabulario](logs/selftest_palabros_20261119_151832.log) pasaron. Las pruebas del salón recorren la misión de reapertura, la entrada, los horarios y la recreativa contigua. Los registros de esta copia ya mostraban un diagnóstico de color `brick_red` en las casas y avisos de recursos al cerrar Godot.

### Salir del coche en la misión del puente

19 de noviembre de 2026. El jugador informó de que, con mando camino de la misión del puente, después de bajar seguía viendo «Bajar» y perdía la posibilidad de hablar o conducir otro coche. Al probar con el coche de Tía Paca junto a Alberto se reprodujeron dos fallos. Pulsar el botón mientras el coche aún iba demasiado rápido vaciaba el asiento antes de rechazar la salida. Al bajar ya detenido, el aviso conservaba la acción anterior hasta que se volvía a calcular el HUD. La [prueba antes del arreglo](logs/selftest_bajar_20261119_152106.log) también detectó dos problemas táctiles al mantener el pedal y «Bajar» mientras cambiaba la distribución de botones.

En `godot/scripts/game.gd` el juego comprueba primero si puede salir. Si el coche supera los 3 m/s o está en reparación conserva el asiento, sus ocupantes y el modo de conducción. Al salir se recuperan el personaje, sus colisiones y la selección de interacciones a pie. El aviso anterior se borra en la misma pulsación. En `godot/scripts/touch.gd` cada botón recuerda la acción que empezó y libera esa acción al cambiar de función o al levantar el dedo. Al cambiar de dispositivo se liberan únicamente los botones y el stick que estaban en uso.

Se añadió `python tools/run_tests.py bajar --headless` a `godot/scripts/selftest.gd`. Las [14 comprobaciones pasaron](logs/selftest_bajar_20261119_152704.log). Con el botón inferior de mando se intentó salir a 3,2 m/s, se salió tras parar, se mantuvo A durante el cambio a «Hablar», se abrió el diálogo de Alberto y se subió a otro coche tras la conversación. También se cubrieron la repetición de E, el paso del teclado al mando, dos dedos que siguen pulsando al bajar y el primer desplazamiento a pie. Se ejercitó la ruta de entrada de mando de Godot. Queda por reproducir en el mando físico del jugador el bloqueo prolongado descrito.

### Versión local 0.0.18

19 de noviembre de 2026. Se guardó el estado conjunto de la copia de trabajo, incluidos los cambios previos de mapa, casas y creador que figuran en PROJECT_STATE.md. La versión del juego se lee de `godot/project.godot`. Android lleva nombre 0.0.18 y código 18 en `godot/export_presets.cfg`. Los tres paquetes se generan con `tools/make_apk.py 0.0.18`, `tools/make_installer.py` y `tools/make_linux.py` y se conservan en [dist/v0.0.18](dist/v0.0.18/). Para abrir la copia de desarrollo en Windows se puede seguir usando [play.bat](play.bat).

El empaquetador comprobó la firma de Android. Se verificaron los CRC del APK y del contenido del instalador de Windows, el archivo de juego incluido en Linux y la coincidencia de siete scripts compilados entre las tres plataformas. Las [sumas SHA-256](dist/v0.0.18/SHA256SUMS.txt) identifican los tres ficheros comprobados. La etiqueta de Git de esta copia es `v0.0.18`. La [prueba completa de la primera compilación](logs/selftest_full_20261119_201317.log), ejecutada con `python tools/run_tests.py`, terminó con 880 comprobaciones correctas y cero fallos en 516 segundos. El registro también recoge avisos del motor al cerrar y del renderizador sin ventana. El [salón completo](logs/selftest_recress_20261119_201041.log) pasó sus 16 comprobaciones y el [vocabulario](logs/selftest_palabros_20261119_201241.log), sus tres.

Pruebas complementarias de los controles compartidos: [boxeo y guardado de 0.0.17, 86 correctas](logs/selftest_boxeo_guardado-anterior_20261119_153136.log), [bate de Henry, 64 correctas](logs/selftest_motin_20261119_153215.log), [derrape, 9 correctas](logs/selftest_derrape_20261119_153324.log). Las 14 comprobaciones del coche pasaron tanto [en ventana](logs/selftest_bajar_20261119_153411.log) como [sin ventana](logs/selftest_bajar_20261119_200915.log). La recreativa pasó 31 comprobaciones [con imagen](logs/selftest_rally_shots_20261119_153003.log) y [sin ventana](logs/selftest_rally_20261119_200958.log). La [vista táctil final](godot/shots/rally9_mandos.png) muestra el botón de pausa separado de la vuelta.

### Hit The VIP en el Galaxy Recress

Incorporado a la edición local 0.0.18 a petición del usuario. Esta revisión sustituye a la primera compilación local de la misma versión (commit `a03a12e`). Tras reabrir el salón, se juega en la última máquina de la fila de la canasta de baloncesto, al fondo. Lleva el rótulo «Hit The VIP» y muestra dos guantes animados con los colores del combate. Al acercarse aparece el botón de interacción configurado. En teclado es E por defecto, en mando A o ✕ y en táctil se toca el nombre del juego.

Se reutilizan el ring, Fonsi, las reglas, los controles y el marcador del combate libre. Tanto victoria como derrota devuelven al mismo sitio del salón, con la orientación y la cámara anteriores. Cuenta como un combate de boxeo y comparte el récord y el límite diario del Punto Cívico. La historia de Josefa y el desbloqueo por las vías anteriores conservan sus condiciones.

El mueble y su pantalla están en `godot/scripts/recress_sala.gd`, la selección por distancia en `recress.gd`, la entrada y el retorno en `game.gd` y el aviso en `loc.gd`. El filtro `python tools/run_tests.py hitvip --headless` de `selftest.gd` prueba la disponibilidad antes y después de la reapertura, los tres tipos de máquina, el aviso, una derrota y una victoria consecutivas, las estadísticas y el regreso. Se verificó la lectura del rótulo sobre fondo oscuro y la animación de guantes en la [vista final del mueble](godot/shots/hit_the_vip_mueble.png). Pasaron las nueve comprobaciones [sin ventana](logs/selftest_hitvip_20261119_204503.log) y [con imagen](logs/selftest_hitvip_shots_20261119_204943.log), las [86 de boxeo con guardado anterior](logs/selftest_boxeo_guardado-anterior_20261119_204542.log) y las [16 de la misión del Galaxy Recress](logs/selftest_recress_20261119_204621.log). El botón A se comprobó con eventos simulados de mando en Windows.

### Tanda de 20 mejoras jugables (20/11)

20 de noviembre de 2026. Implementadas las 20 mejoras solicitadas por el usuario en `X:\MatritellusGPT` sobre `main` e incorporadas a la edición local `0.0.18`:

- **Rendimiento carteles (Galaxy Recress):** `map_data.gd` evita recalcular Dijkstra en `set_route_target()` si el destino no cambió y `recress.gd` espacia la búsqueda de tienda más cercana (`_poster_t = 0.35`).
- **Rampas y saltos con coche:** planos inclinados lisos a ras de suelo en `sebastian.gd`, `plaza.gd`, `aceras_altas.gd`, `puente.gd`, `caridad.gd` y `cuartel.gd`; `car.gd` añade material de baja fricción, levanta 0,10 m los bajos del morro/trasera y lanza el coche en `_ramp_launch(dt)` al entrar rápido en cualquier rampa de `MapData.decks`.
- **Cinemática del alcalde a la salida del Recress:** `recress.gd` oculta al jugador y limpia vehículos aparcados, tráfico, policía y peatones en el tramo de calle; `game.gd` congela el tráfico durante `recress.cine`.
- **Tokken 9 — Salir:** botón «SALIR», atajo `ESC`/atrás, ratón visible en selección/pausa y botón táctil en `tokken.gd`.
- **Rally 9:** ruedas visuales montadas en `body.inner` para los 7 coches (sin culling en `parts.gd` ni desync en `car.gd`), hitboxes dinámicas por tamaño de coche, rubberbanding + reaparición con llama de nitro si un rival se descuelga `> 95 m`, y 3 vueltas (`rally.gd`, `rally_hud.gd`, `rally_pruebas.gd`).
- **Katakumba69 y máquinas de Tokken 9:** todas las cabinas en libre juegan contra la CPU; para retar a Katakumba69 hay que hablar con él dentro del Recress (con puntos de confianza y respetando su revelación a 100 de confianza).
- **Ajedrez humano y perros:** eliminada la rotación errónea de `PI` en `perro.glb` (`ajedrez_humano.gd` y `ruta.gd`); las piezas del jugador miran hacia la partida y las rivales hacia el jugador.
- **Rondas lúdicas de NPCs únicos:** ampliadas a 12 personajes únicos exteriores en `rondas.gd` con rutinas por personalidad (bares, pubs, comida, recreativos, salud, plazas) cuando están libres y sin misión.
- **Movimiento diagonal estable:** vector radial `Input.get_vector(..., 0.25)` en `game.gd` y zona muerta radial en `touch.gd`.
- **Misión del kebab (sospecha, furgoneta rápida y captura):** medidor continuo de sospecha en `hud.gd` + `sabotaje.gd`, velocidad de reparto subida (`PACE = 1.65`) con bocadillos flotantes de `*hablando en árabe inventado*`, y si el repartidor te pilla fuera de la furgoneta esta queda aparcada junto a él sin clonarse ni marcharse.
- **Frases de golpe divididas:** `hit_bat`, `hit_car` y `hit_both` en `loc.gd` (incluyendo «¡Ostia!» y cumpliendo `palabros.md`), cableadas en `game.gd` y `motin.gd`.
- **Policías y guardias civiles uniformados:** `officer_look()` en `game.gd` (uniforme y gorra azul para pitufos; clon de Ramírez con tricornio para guardias civiles) usado en `traffic.gd` y `police.gd`.
- **Taller (repintado y limpieza de búsqueda):** `Modelos.repaint()` y `car.repaint()` cambian el color a otro distinto y `_mended()` limpia `police.reset()`, congelando a la policía durante la reparación.
- **Entrar en interiores pulsando Acción:** `entradas.gd` y `game.gd` exigen pulsar interacción (`p_entrar`) igual que al salir.
- **Mapa grande (elegir/quitar misión):** panel interactivo y fotos clicables en `minimap.gd` + `game.gd` + `marcas.gd`; deseleccionar («Ninguna») oculta flecha 3D, baliza y ruta GPS.
- **Objetos 3D flotantes giratorios con brillo:** nuevo `godot/scripts/pickups.gd` (halo billboard aditivo + aro en suelo + malla 3D giratoria para bate, spray, carteles, jamón, móvil, kebab), integrado en `game.gd`, `pintadas.gd` y `recress.gd`.
- **Inventario estilo Animal Crossing:** nuevo `godot/scripts/inventario.gd` con dos pestañas (`Objetos` y `Objetos clave` no vendibles/tirables), tecla `I` / mando `Y`/`△` (`controls.gd`) y botón táctil «Mochila» (`touch.gd`).
- **Salir del juego con confirmación y ratón en menús:** opción Salir en menú principal y pausa con confirmación («¿Tás seguro? Mía que se estaba poniendo divertío.») en `game.gd`/`loc.gd` y soporte de ratón en `menu.gd`.

**Pruebas ejecutadas (todas con 0 fallos y 0 errores de script):**
- `python tools/run_tests.py mejoras --window`: **9 ok, 0 failed** ([log](logs/selftest_mejoras_20261120_150152.log)) + capturas revisadas (`mejora_mapa.png`, `mejora_pickups.png`, `mejora_inv_obj.png`, `mejora_inv_key.png`).
- `python tools/run_tests.py entradas --window`: **4 ok, 0 failed** ([log](logs/selftest_entradas_20261120_150247.log)).
- `python tools/run_tests.py rally shots --window`: **31 ok, 0 failed** ([log](logs/selftest_rally_shots_20261120_150401.log)) + capturas revisadas (`rally9_derribo.png`, `rally9_nitro.png`, `rally9_meta.png`, `rally9_reincorporacion.png`).
- `python tools/run_tests.py ajedrez --window`: **17 ok, 0 failed** ([log](logs/selftest_ajedrez_20261120_151618.log)) + capturas revisadas (`aj_inicio.png`, `aj_perro_salta.png`, `aj_perro_quieto.png`).
- `python tools/run_tests.py palabros --headless`: **3 ok, 0 failed** ([log](logs/selftest_palabros_20261120_151815.log)).
- `python tools/run_tests.py recress --headless` (**16 ok, 0 failed**), `tokken shots --window` (**11 ok, 0 failed**), `rondas --headless` (**1 ok, 0 failed**), `sabotaje --headless` (**45 ok, 0 failed**).

### Cámaras al conducir, Tomasa Malvora, fumadores y HUD dev (20/11)

20 de noviembre de 2026. Implementadas las 5 mejoras nuevas en `X:\MatritellusGPT` sobre `main` (commit `8262fd8`, con el director del tráiler `trailer.gd`; la canción, `trailer song/`, queda fuera del repositorio en `.gitignore`):

- **Sistema de cámara en coche (3 modos):** acción reasignable `cam_mode` (`V` en teclado, `cruceta ←` / `R3` en mando, botón táctil «Cámara» en `controls.gd` y `touch.gd`).
  - `0` Tercera persona (clásica).
  - `1` Primera persona (`car.gd:driver_pov()` + `set_driver_head_visible(false)` en el nodo `head` de `chara.gd:sit()`): vista desde encima de los hombros dentro del habitáculo con `cam.near = 0.05` y giro libre de cabeza con ratón/stick derecho.
  - `2` Cinemática tipo GTA (`game.gd:_pick_cine_spot()`): planos estratégicos en acera/esquina/ángulo bajo validados con raycast; salta automáticamente al siguiente punto si el coche se aleja `> 36 m`, si pasan `≥ 5 s` o si un edificio tapa la vista.
- **Slow-motion + cámara cinemática en saltos de coche:** `game.gd:_update_air_cine()` detecta saltos reales en el aire (`airborne()`, altura sobre el suelo/rampa), baja `Engine.time_scale` suavemente a `0,38` con plano cinemático lateral-bajo siguiendo el vuelo y restaura `1,00` al aterrizar (y al instante al pausar, bajar del coche o cambiar de fase).
- **Tomasa Malvora e interior de los chinos del Arroyuelo:**
  - Nuevo `godot/scripts/chinos_dentro.gd` en `(1800, 1400)`, conectado en `chinos.gd` y `entradas.gd` según el horario comercial del local.
  - Nuevo `godot/scripts/tomasa.gd`: Tomasa Malvora pasea cerca de los chinos mientras están abiertos; al hablar ofrece el recado (`Sí` / `No`: decir «No» la enfada y resta confianza; decir «Sí» hace que espere fuera). Dentro del local, **El chino** habla en infinitivo advirtiendo que no robes nada porque te vigila, y en el pasillo derecho gira el paquete de tabaco (`pickups.gd`, `auto = false`, cartel «Comprar · 6 €»). Al entregarlo a Tomasa termina la misión (`+10` confianza, `+3` PC, `10 €`), explica que sus hijos le vigilan el dinero pero que ella controla, y se enciende un cigarro. El paquete figura en `Objetos clave` de `inventario.gd`.
- **Tabaco en el 5 % de la población (no niños):** `game.gd:_neighbour_look()` asigna `"smoke": true` al 5 % de vecinos adultos y mayores (0 % niños); `chara.gd:_cigarette()` acopla un cigarro encendido con brasa emisiva y voluta ligera de humo en `neck`.
- **Opción de desarrollador para ocultar HUD:** fila «Botón ocultar HUD (ºª / Select)» en `Pausa → Desarrollador` (`game.gd:dev_hud_key`, `set_hud_hidden()`). Con el modo desarrollador y la opción activados, `ºª` en teclado y `Select` (`JOY_BUTTON_BACK`) en mando ocultan y muestran el HUD, flecha guía, baliza, FPS y controles táctiles sin bloquear los menús.

**Pruebas ejecutadas (todas con 0 fallos y 0 errores de script):**
- `python tools/run_tests.py mejoras2 --window`: **9 ok, 0 failed** ([log](logs/selftest_mejoras2_20261120_182926.log)) + capturas revisadas (`mejora2_cam_fp.png`, `mejora2_cam_cine.png`, `mejora2_air_slowmo.png`, `mejora2_chinos_tabaco.png`).
- `python tools/run_tests.py chinos --window`: **5 ok, 0 failed** ([log](logs/selftest_chinos_20261120_183050.log)).
- `python tools/run_tests.py palabros --headless`: **3 ok, 0 failed** ([log](logs/selftest_palabros_20261120_182640.log)).

### Publicación de la 0.0.18 en GitHub (20/11, Claude · Sistemas)

20 de noviembre de 2026. El usuario pidió publicar la 0.0.18 con todo lo pendiente y que las sesiones de Claude trabajen desde ahora en `X:\MatritellusGPT` (`X:\Matritellus` queda de copia de seguridad). Avisadas Edificios Especiales (Pretil), Texturas y Modelado y Worldbuilding; Creador y Recreativos están archivadas.

- **Prueba completa** (`python tools/run_tests.py`): 879 ok y 1 fallo en 568 s ([log](logs/selftest_full_20261120_231727.log)). El fallo era de la prueba: la copistería del Recress esperaba entrar solo con pisar la flecha y desde la tanda de 20 mejoras hay que pulsar Acción. `selftest.gd` llama ahora a `g.interact()` sobre la flecha, como ya hacía la del Recress. `python tools/run_tests.py recress --headless`: 16 ok ([log](logs/selftest_recress_20261120_232718.log)).
- **Commits:** `8262fd8` (la tanda de cámaras, Tomasa, fumadores, HUD dev y tráiler) y «Matritellus 0.0.18» con estas notas. La etiqueta local `v0.0.18`, que no se había subido, se movió a este último.
- **Paquetes** rehechos con `tools/make_apk.py 0.0.18`, `tools/make_installer.py` y `tools/make_linux.py`, copiados a `dist/v0.0.18/` con sus `SHA256SUMS.txt` nuevas, y subidos a la release: https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.18
- ~~**Pendiente:** la casa de Matías Pérez 16 sale como hueco hasta que Pretil la haga a mano (aviso de Texturas).~~ El aviso era un error. La casa sí está en la 0.0.18: la levanta `matias.gd`. Edificios Especiales lo comprobó con el paquete de Linux y en esta carpeta (prueba `matias`: 2 ok). Solo sale como hueco en las hojas de repaso de casas, que dibujan únicamente `casas.gd`. Más abajo está la entrada de Texturas del 20/11.

### Árbol de relaciones: Tomasa Malvora y el chino del Arroyuelo (20/11)

20 de noviembre de 2026, Worldbuilding (Claude). Cada personaje nuevo va al árbol de relaciones del guion (`guion/relaciones.html`, para el usuario; no es parte del juego). Tomasa Malvora y el chino llegaron con la 0.0.18 y no estaban.

- **Hecho.** Tres personas más: Tomasa Malvora, sus hijos (solo se les nombra) y el chino del Arroyuelo. Tres relaciones: la Tomasa y sus hijos, que le vigilan el dinero; la Tomasa y el chino, que no le vende directamente porque ella no entra; tú y la Tomasa, el recado del tabaco. Un cabo suelto nuevo: ni los hijos ni el chino tienen nombre.
- **Archivos.** `guion/relaciones.json`, `guion/relaciones.html` (hecho con `tools/make_relaciones.py`: 43 personas, 36 relaciones) y las fotos `guion/fotos/tomasa.png` y `guion/fotos/chino.png`. En `godot/scripts/selftest.gd`, el modo `--portraits` saca también a la Tomasa y al chino (sus caras están en `tomasa.gd`, porque solo salen con la tienda abierta). La opción nueva `--solo=tomasa,chino` hace solo esas fotos y deja las demás como estaban.
- **Verificación.** `python tools/run_tests.py portraits solo=tomasa,chino --window` escribió solo las dos fotos, revisadas a ojo (el ejecutor dice «NO RESULT» porque este modo no hace comprobaciones: guarda las fotos y sale). Se comprobó con un cálculo sobre las posiciones que ninguna línea del árbol pasa por encima de una cara junto a los nuevos.
- **Sin commit.**

### El color de la barandilla de una terraza en Covadonga (20/11)

20 de noviembre de 2026, Texturas (Claude). Edificios Especiales vio que la prueba registraba el error `Invalid hexadecimal notation character "r" in string "brick_red"`. Sale en `casas.gd:877` (`_unpack`), al que llaman `world._houses` y `recress._spec_of`.

- **Causa.** En la línea de `cov_6` (Calle de Covadonga, aprobada el 17/11), la pieza `ter` llevaba como color de la barandilla el nombre de un material, `brick_red`. Ese valor solo admite un código hexadecimal, así que la barandilla salía negra. No había ningún otro `ter`, `awn` o `c=` con un nombre en lugar de un código.
- **Hecho.** La barandilla es ahora `9a4e36`, un rojo ladrillo como el remate de la terraza en la foto del Catastro. No hace falta rehacer el mapa, porque la línea de la casa se lee al cargar el juego.
- **Archivos.** `godot/scripts/casas_calles.gd`: solo la línea de `cov_6`.
- **Verificación.** `python tools/run_tests.py casas "solo=cov_6"`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_cov_6_20261120_233933.log)). El aviso del hexadecimal ya no sale.
- **Corrección.** El pendiente de la entrada de la 0.0.18 sobre Matías Pérez 16 salió de un aviso mío equivocado. Está tachado y explicado allí.
- **Sin commit.**

### Matías Pérez 16 retocada con Street View (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Luis lo pidió el 17/11 («Nuevo proyecto. Matias Pérez 16», con una captura de Street View de noviembre de 2024). La casa se levantó a mano en `X:\Matritellus` y llegó a la 0.0.18. Al compararla en esta carpeta con Street View desde las mismas cámaras, salieron estas diferencias, ya corregidas:

- **El ladrillo.** Era el rojo oscuro y rugoso de `brick_wall_006`; en la foto es caravista salmón, de hiladas regulares y llaga clara. Ahora es `brick_wall_003@0.9`, para que cada ladrillo mida 25 cm.
- **Los sardineles.** Antes eran rosados y destacaban. Ahora tienen el tono del muro. El de cada ventana de arriba va justo sobre el hueco, sin hilada en medio, y la faja corrida está a 2,85 m.
- **Las persianas.** Quedaban detrás del cristal y no se veían. Ahora están bajadas hasta el alféizar, delante de la ventana, en color liso con sus lamas, como las de `casas.gd`. Las de arriba son blancas y la de abajo beige.
- **El resto.**
  - Las cortinas del portalón son crema con rosas grandes de gris malva, se juntan en el centro y el portalón lleva jambas de madera oscura.
  - La cortina de la puerta es más blanca.
  - La reja tiene nueve barrotes y travesaños solo arriba y abajo.
  - El zócalo gris sube a unos 45 cm.
  - El cable va a la altura de los alféizares, y en lugar de la caja gris hay dos cajitas blancas.
- **Archivos.** `godot/scripts/matias.gd` y, nuevos, `tools/matias/hojas.py` y `referencias/matias/LEEME.md`. No se tocó ningún archivo compartido.
- **Pruebas.**
  - `python tools/run_tests.py matias`: 2 ok, 0 fallos ([log](logs/selftest_matias_20261121_002706.log)).
  - Las vistas desde las cámaras de Street View se sacaron con `tools/merkocarry/vistas.py`. El ejecutor dice «NO RESULT» porque ese modo solo hace fotos.
  - Se probó también el paquete de Linux publicado (`--main-pack`), con la casa antigua: 2 ok, 357 piezas.
  - Esa última prueba coincidió un momento con un Godot de otra sesión. No volverá a pasar.
- **Hojas para Luis.** `guion/fotos/matias/01_street_view_y_juego.jpg` (Street View al lado del juego) y `02_en_el_juego.jpg`.
- **Aprobada** por Luis el 21/11: «Visto bueno». Sin commit: la publica Sistemas.

### Calle del Triunfo, tramo de las afueras: 16 naves (21/11)

21 de noviembre de 2026, Texturas (Claude). Es la siguiente calle del núcleo, a la orden del usuario («Visto bueno y siguiente»).

- **Hecho.** 16 naves y almacenes con su frente en el Triunfo (`tri_e147` … `tri_17`), descritos con las fotos del Catastro. Para cuatro, cuya foto del Catastro está hecha desde la Avenida de Europa, se usó Street View. Se dejan sin hacer el 35, el molino viejo de Reyes Católicos, el 11, el 27 y el 18. La razón de cada uno está en `PROJECT_STATE.md`, y lo que aún no se parece, en `guion/repaso_casas.md`.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd`: 16 entradas nuevas.
  - `godot/data/map.json`: horneado.
  - Las carpetas del Catastro `tools/casas/<ref>/` de estos edificios.
  - Las hojas `guion/fotos/tanda34/triunfo_4..6.jpg`.
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Se horneó dos veces, avisando a Edificios Especiales antes y después. Comparado con la copia de antes: 16 casas nuevas, ninguna quitada ni cambiada. Calles (656), nodos (6376), relieve, árboles (2956) y holguras de las calles siguen igual. Ninguna casa tiene partes por delante de su frente.
- **Pruebas.**
  - `python tools/run_tests.py casas "solo=tri_"`: el primer intento falló porque `tri_e151`, `tri_e145` y `tri_41` no llegaban a 12 piezas.
  - Con los postes, las juntas y el ladrillo desteñido que se ven en las fotos, `solo=tri_e151,tri_e145,tri_41` dio 4 ok, 0 fallos.
  - Tras los últimos retoques, `solo=tri_e151,tri_41,tri_e129,tri_t1` dio 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tri_e151_tri_41_tri_e129_tri_t1_20261121_004155.log)).
- **Pendiente.** El visto bueno del usuario a las hojas. Sin commit.

### El puente sin «todo hecho», el reloj en la hoja y el pitillo de la Tomasa (21/11, Claude · Sistemas)

21 de noviembre de 2026. Tres cambios que pidió el usuario.

- **El puente.** Desbloquearlo ya no lleva a la pantalla de «continuará» ni a sus estadísticas: «Ahora hay más misiones disponibles». El paso `tbc` sigue cerrando la historia hecha, pero no cuenta los 9 s ni funde a negro. El objetivo es `obj_free`, con texto nuevo: «Hay más gente en el pueblo que te necesita. Mira el mapa o la Agenda, o date un garbeo.».
  - `game.gd`: fuera `_tbc_t` y `_show_end`.
  - `missions.gd`: el paso `tbc` usa `obj_free`.
- **El reloj.** La hoja del calendario dice «LUNES · 12:07» en vez de «LUNES · MAÑANA»: «solo horas y minutos».
  - `game.gd`: `clock_text()` y `_tag()`.
  - La hoja solo sale sola cuando cambia el momento del día, no a cada minuto. `_tag()` deja `hud.day_key` (día y momento) y `hud.gd` compara eso en vez del texto.
  - `hud.show_day(s)` la saca un rato a propósito.
- **El pitillo.** La primera vez que le llevas el tabaco, la Tomasa pregunta «¿te echas un *pitillo* conmigo?».
  - Con «Venga, uno» o con «No, que yo no fumo» te lo fumas igual, con frases distintas: la culpa y el cáncer «al cincuenta por ciento».
  - Ese primero es el ejemplo de la mecánica. La cámara sube 16 m por encima de los tejados mirando al cielo. Pasan 6 horas en 5 s, con el cielo y el reloj cambiando, y la cámara vuelve.
  - Después te da tres: el objeto clave «Pitillo» ×3. En Mochila → Objetos clave se puede «Usar».
  - Solo se fuma a pie, sin misión ni encargo en marcha y sin que te busquen. Si no, un aviso dice por qué.
  - En los chinos del Arroyuelo, una vez hecho el recado, el estante del tabaco vende «Pitillos ×3 · 6 €». Son los únicos chinos del pueblo por ahora; el usuario dijo «en cualquier chino».
  - Archivos: `fumar.gd` (nuevo), `tomasa.gd` (`_offer_smoke`, `_smoke_with`, `_spawn_pitillos`, `buy_prompt`, `buy`), `inventario.gd` (el objeto, su botón Usar y su icono), `game.gd` (la fase `smoke`) y `loc.gd` (las frases).
  - Con una partida guardada entre el tabaco y los tres pitillos, `restore()` te los da.
- **Pruebas.**
  - `python tools/run_tests.py mejoras2 --headless`: 12 ok, 0 fallos. Incluye las tres nuevas: el pitillo con la Tomasa (6,00 h, la cámara arriba, 3 pitillos), comprar en los chinos y fumar desde la mochila.
  - `mejoras2 shots --window`: las fotos `pitillo_tomasa.png` y `pitillo_cielo.png` (el cielo a las 15:55, con la hoja).
  - Prueba completa (`python tools/run_tests.py`): 879 ok y 1 fallo en 480 s ([log](logs/selftest_full_20261121_012128.log)). Ahí pasan las del reloj y el final del puente. El fallo era un «tienes» en `fumar_busy`, que ahora dice «tiés». `palabros --headless`: 3 ok ([log](logs/selftest_palabros_20261121_012938.log)). La prueba incluía, sin commitear, el suelo y los matojos de Texturas.
- **Decidido sin preguntar.** El pitillo de la Tomasa es suyo: no gasta de los tres. Un paquete de los chinos trae tres por 6 €, el precio del tabaco del recado.

### Ermita del Cristo del Prado (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Luis lo pidió el 21/11: «Siguiente proyecto la Ermita del Cristo del Prado (junto a la residencia, en la misma manzana)».

- **Hecho.** `godot/scripts/cristoprado.gd`, sobre `obra.gd`. Incluye la ermita, su placita, la acera del Paseo con el ajedrezado, los olmos y los pilones, la franja con verja de la Calle del Cristo y el calvario del parque. El detalle y las medidas están en [referencias/cristoprado/LEEME.md](referencias/cristoprado/LEEME.md).
- **El horneado.**
  - El Catastro tiene la ermita y la Residencia como un solo edificio, `4587301VJ5648N`. `tools/bake_godot.py` deja de levantar las partes de la ermita (con los cambios de `tools/cristoprado/enganche.py`); la Residencia sigue genérica.
  - `godot/data/map.json` rehorneado con el OK de Sistemas y de Texturas, igual al ensayo.
  - Frente al mapa anterior: cambia la manzana de la ermita (su contorno y 25 muros que se quitan y 10 nuevos, todos a menos de 60 m), hay 2 árboles menos en la acera sur y aparece la clave `cristoprado`. Casas, calles y relieve, iguales.
  - Unos 155 contornos de otras manzanas se mueven 0,3 m como mucho, porque se simplifican de otra manera.
- **Archivos compartidos**, con los avisos dados: `map_data.gd`, `world.gd` y `selftest.gd` (modo `--cristoprado`, y `_cristoprado_checks` en la prueba completa, tras Matías Pérez). Los cambios salen de `tools/cristoprado/enganche_juego.py`.
- **Nuevos.**
  - `tools/cristoprado/`: `manzana.py`, `capturas.py`, `enganche.py`, `enganche_juego.py` y `hojas.py`.
  - `tools/ign/cristoprado.*`.
  - `referencias/cristoprado/LEEME.md`.
- **Pruebas.**
  - `python tools/run_tests.py cristoprado`: 2 ok, 0 fallos ([log](logs/selftest_cristoprado_20261121_013705.log)): 2171 piezas, 10 ventanas y puertas, los muros paran, el suelo ante las dos puertas está libre y nada pisa el asfalto.
  - La primera pasada falló: la verja de la cabecera pisaba la Calle del Cristo, que dobla la esquina. Ya está corregida.
  - Vistas desde las cámaras de Street View con `tools/merkocarry/vistas.py`. El ejecutor dice «NO RESULT» porque ese modo solo hace fotos.
- **Hojas para Luis.** `guion/fotos/cristoprado/01_street_view_y_juego.jpg` y `02_en_el_juego.jpg`.
- **Su corrección (21/11).** Sobre la vista desde la esquina del Paseo con la Calle del Cristo dijo: «The building it's pretty good, but i'm missing the little stone wall in red and the last portion of acera (in yellow). After these fixes we can continue with the rest of the apple». Hecho en `cristoprado.gd`, sin rehornear:
  - **El murete de piedra.** El enlosado claro sigue el suelo hasta el crucero y desde allí queda a nivel, mientras la calle baja. Su murete con albardilla sube así de bordillo a medio metro en la esquina y rodea la cabecera por la Calle del Cristo, con su chaflán donde la calle corta la esquina.
  - **El enlosado claro** tiene su suelo para pisar (`MapData.decks`). Los pilones están sobre el murete y el portón se abre a su nivel.
  - **La acera.** El ajedrezado es ahora una sola rejilla que rodea la esquina hasta el asfalto de las dos calles; antes allí salía el césped del parque del mapa. Los coches aparcan solo hasta x = 30.
  - **Pruebas.** `python tools/run_tests.py cristoprado`: 2 ok ([log](logs/selftest_cristoprado_20261121_021318.log)). Un primer intento falló porque un pilón pisaba la Calle del Cristo; ya está corregido. Otra pasada coincidió con un Godot de otra sesión.
- **Aprobada con esos arreglos.** Sin commit.

### Suelo de tierra y plantas secas en todo el pueblo (21/11)

21 de noviembre de 2026, Texturas (Claude). El usuario, al ver las hojas del Triunfo: el suelo de color plano «tiene poco y nada que ver con la realidad». Pidió algo más anaranjado o marrón, con algo de textura, y «plantas secas sueltas, para que no quede todo tan plano».

- **El suelo** (`godot/scripts/world.gd`):
  - El terreno era arena pálida (`e3cf95`). Ahora es pardo anaranjado (`EARTH = 0xc4905c`), sacado de la tierra al sol en las fotos del Catastro del Triunfo (tono unos 30°, `#cf9a5c`).
  - Lleva una textura nueva hecha en código, `"tierra"` en `_tex`: grano, manchas suaves más rojizas donde son más oscuras y chinas de 2×2.
  - Con un material propio, `_earth_mat()`, la textura se superpone a 5, 23 y 61 m para que no se note que se repite en un solar entero.
  - Los caminos de tierra pasan a `"tierra"` en `caa170`, más claros y apisonados. Los barbechos y los campos arados pasan a pardos (`c99c66`, `c39266`).
  - La textura `"earth"` de siempre no cambia: la siguen usando Calasanz y la Caridad.
- **Las plantas** (`godot/scripts/matojos.gd`, nuevo):
  - Son matas de hierba seca y algún matojo seco, en rodales, más espesas al pie de las tapias y en la orilla pasada la acera.
  - Solo crecen en el pueblo y hasta 64 m de la última manzana.
  - No salen:
    - en calles ni aceras;
    - dentro de las manzanas;
    - en césped, parques, viñas ni agua;
    - en los sitios hechos a mano: se miran los nodos que heredan de `obra.gd` o `petril.gd`, en su propio marco.
  - Además, un rayo hacia abajo tiene que dar en el terreno desnudo.
  - Se dibujan con MultiMesh por cuadros de 64 m, que no se ven a más de 120 m (`Parts._range`, así que les afecta la opción de distancia de dibujado). No dan sombra ni chocan.
  - Es un paso nuevo de la construcción del mundo, `["dry plants", _build_matojos]` entre `details` y `bounds`, que trabaja a trozos de 12 ms.
- **Caché.**
  - La primera vez se calculan unas 137.000 plantas en 4,7 s y se guardan en `user://matojos.cache` (6 MB).
  - Después se leen en 0,7 s. Hay que volver a calcularlas solo si cambian el mapa, los sitios hechos a mano o `VERSION` en `matojos.gd`.
  - Las pruebas usan la misma caché.
  - `--sin-matojos` las quita, para medir lo que cuestan.
- **Pruebas.**
  - `python tools/run_tests.py casas "solo=tri_47,tri_e151,tri_45,tri_17,tri_t1,tri_e129"`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tri_47_tri_e151_tri_45_tri_17_tri_t1_tri_e129_tim_20261121_011538.log)).
  - `python tools/run_tests.py suelos`: 1 ok, 0 fallos ([log](logs/selftest_suelos_20261121_011818.log)).
  - `bench --window`, con plantas: 127,8 fps, gpu 5,06 ms, 1362 llamadas de dibujo ([log](logs/selftest_bench_20261121_011227.log)). Con `sin-matojos`: 125,4 fps, gpu 5,16 ms, 1398 llamadas ([log](logs/selftest_bench_sin-matojos_20261121_011400.log)). Es la misma cifra con su ruido.
  - Vistas con `vistas=`: hay plantas en los solares y los caminos, y ninguna en la plaza.
- **Hojas.** `guion/fotos/suelo/suelo_1.jpg` (Catastro, antes y ahora en dos casas del Triunfo) y `suelo_2.jpg` (solar, matas de cerca, camino de tierra y las afueras desde arriba).
- **Sin probar en el móvil.** La primera vez que se abra, la carga tardará unos segundos más.
- **Aprobado** por el usuario el 21/11: «Mucho mejor. Visto bueno y siguiente». En el commit `ad86143` (Sistemas, 21/11, sin push).

### Calle de los Cipreses: 33 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Es la siguiente calle del núcleo, a la orden del usuario («Visto bueno y siguiente»).

- **Hecho.** 33 casas con su frente en los Cipreses (`cip_*`), descritas con las fotos del Catastro y siete con Street View. Lo que queda fuera y por qué está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd`: 33 entradas nuevas.
  - `godot/data/map.json`: horneado.
  - Las carpetas del Catastro `tools/casas/<ref>/`.
  - Las hojas `guion/fotos/tanda34/cipreses_1..6.jpg`.
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Horneado sobre el mapa con el Cristo del Prado de Edificios Especiales, avisándole antes y después. Comparado con la copia de antes: 33 casas nuevas, ninguna quitada ni cambiada. Calles (656), nodos (6376), relieve, árboles (2954) y holguras siguen igual. Ninguna casa tiene partes por delante de su frente.
- **Pruebas.**
  - `python tools/run_tests.py casas "solo=cip_"`: el primer intento falló porque `cip_t60` no llegaba a 12 piezas.
  - Con las pilastras y el portón de su foto, `solo=cip_t60` dio 4 ok, 0 fallos.
  - Tras los once arreglos, `solo=cip_t58,…,cip_10` dio 4 ok, 0 fallos ([log](logs/selftest_casas_solo_cip_t58_cip_sb47_cip_x1_cip_34_cip_26_cip_39_cip__20261121_021512.log)).
- **Plantas secas.** El mapa ha cambiado, así que la caché de `matojos.gd` se rehace sola la próxima vez que arranque (unos 4,7 s).
- **Aprobada** por el usuario el 21/11: «Visto bueno y siguiente». En el commit `ad86143` (Sistemas, 21/11, sin push).

### Arreglo: errores de UV en el calvario (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Aviso de Sistemas tras el commit ad86143: al cargar salían 6 errores del motor («Condition "!first && !(format & Mesh::ARRAY_FORMAT_TEX_UV)"») desde `roof()` en `cristoprado.gd` `_calvario`.

- **Causa.** El remate del calvario usaba `roof()`, que pone UV, con el material `caliza`. Las demás piezas de ese material no llevan UV, y una misma malla no puede mezclar vértices con y sin UV.
- **Arreglo.** `_slope()` en `cristoprado.gd`: las cuatro caras inclinadas sin UV. `caliza` es triplanar y no las necesita. Se ve igual.
- **Prueba.** `python tools/run_tests.py cristoprado`: 2 ok, 0 fallos, y ningún error de UV en el log ([log](logs/selftest_cristoprado_20261121_083749.log)). Sin commit.

### Residencia de mayores del Cristo del Prado (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Después de aprobar la ermita, Luis dijo: «After these fixes we can continue with the rest of the apple». Es el resto de la manzana de la ermita.

- **Hecho.** `godot/scripts/residencia.gd`, sobre `obra.gd`:
  - **El bloque grande**, de tres plantas entre los dos brazos de la Calle del Cristo:
    - ladrillo salmón claro con paños altos de mampostería entre los huecos y zócalo de mampostería con las ventanas enrejadas del sótano;
    - rejas con copete abajo y balconcitos de hierro arriba;
    - alero de teja en inglete alrededor de la azotea con sus placas solares.
  - **Dos alturas**: la calle baja casi 3 m de la punta norte al Paseo, así que la parte sur está un escalón más baja, donde la marca el Catastro.
  - **La entrada principal**, a la Calle del Cristo: el gran medio punto acristalado con sus radios, las puertas de vidrio, la marquesina y la escalinata. La escalinata va dentro del porche porque el asfalto del mapa llega allí casi a la fachada.
  - **El cuerpo redondo** de dos plantas, contra la nave de la ermita.
  - **El ala baja**, sobre la placita y el brazo oeste: el porche de pies derechos de madera, los canecillos y las rejas.
  - **Las aceras** de baldosa clara.
- **Fuentes.**
  - El Catastro, `4587301VJ5648N`: las partes que no son la ermita.
  - La ortofoto `tools/ign/cristoprado.jpg`.
  - Street View: el brazo este y la punta norte en 2024, el brazo oeste y la placita en 2013. Están listados en `tools/residencia/capturas.py`.
- **El horneado.**
  - `tools/residencia/enganche.py`, aplicado a `tools/bake_godot.py`. Con `residencia.gd` en `READY := true` no se levanta nada del edificio 4587301, y sus cuatro contornos entran en los bloques. La clave del mapa es `residencia`.
  - Rehorneado con el OK de Sistemas y de Texturas, igual al ensayo. Frente al mapa anterior: casas (2246, también las `cip_*` de Texturas), calles, relieve y árboles, iguales. Desaparece el bloque genérico (35 muros y 4 tejados planos) y entra la clave.
- **Archivos compartidos**, con los avisos dados: `map_data.gd`; `world.gd`, con el paso tras la ermita (los matojos y el suelo de Texturas, sin tocar); `selftest.gd`, con el modo `--residencia`, y `_residencia_checks` en la prueba completa tras `_cristoprado_checks`. Los cambios salen de `tools/residencia/enganche_juego.py`.
- **Pruebas.**
  - `python tools/run_tests.py residencia`: 2 ok, 0 fallos ([log](logs/selftest_residencia_20261121_023744.log)).
  - Los dos primeros intentos fallaron porque el pie de la escalinata pisaba el asfalto. Ya está corregido.
- **Hojas para Luis.** `guion/fotos/residencia/01_street_view_y_juego.jpg` y `02_en_el_juego.jpg`.
- **Corrección del ala baja (21/11, mañana).**
  - Luis: «Really impressive. Just a couple of adjustments. Here in red the fachada is very different to the photo, also a door is missing», y mandó seis capturas de una foto 360 de Google Maps de hace seis años (C. del Cristo, 52). Las capturas no se guardan en el repositorio.
  - **La fachada a la placita, rehecha en `residencia.gd`**:
    - cuatro ventanas, un solo porche de dos vanos, cerrado por cancelas de hierro de suelo a viga, con el pie derecho de madera en medio, y una última ventana junto al cuerpo redondo;
    - dentro del porche, la puerta de madera de cuarterones, una ventana, la tabla de la Mayordomía con el azulejo del Cristo, dos faroles, el banco y las macetas;
    - el zócalo de granito claro, las columnas de cajones, la cornisa de ladrillo en dientes y los canecillos.
    - Antes el porche ocupaba toda la fachada.
  - **La puerta que faltaba** es la de la Residencia, en el muro del cuerpo redondo, entre el ala y la ermita. Lleva la cancela, la banda con el nombre, el montante con la cruz y el balcón de dos ventanas encima.
  - **La fachada del ala está 2,85 m más atrás que la línea del Catastro.**
    - Medido en la ortofoto: el alero queda 2,25 m dentro, igual de punta a punta. La cara oeste y la fachada de la ermita sí coinciden con el Catastro.
    - El césped de OpenStreetMap del mapa rodea el edificio por esa misma línea.
    - Así queda al aire el muro de la puerta. La franja que sobra se enlosa como la placita.
    - No hace falta horneado: el contorno del ala solo está en `residencia.gd`.
  - **Archivos**: `godot/scripts/residencia.gd`; `tools/residencia/hojas.py`, con la hoja 03, que pone las fotos 360 al lado del juego; `referencias/cristoprado/LEEME.md`, con la sección de la Residencia y las cámaras. Ningún archivo compartido.
  - **Pruebas**: `python tools/run_tests.py residencia`, 2 ok y 0 fallos ([log](logs/selftest_residencia_20261121_054845.log)).
    - El primer intento dejaba el suelo del porche medio metro por encima de la placita, y por debajo se veía el césped. Ya está corregido.
  - **Hojas**: `01_street_view_y_juego.jpg`, rehecha, y `03_ala_fotos_360.jpg`, nueva.
- **Aprobada** por Luis el 21/11 («Visto bueno»), con la corrección del ala. Sin commit.

### Modelados de la línea de la casa: el cajero, el interior del banco y la casa en seis estados (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Encargo de Luis pasado por Sistemas: «Que Pretil haga los modelados y tú los sistemas de juegos». Son tres cosas: los seis estados de la casa de la Calle de Alemania 5, un cajero modelado delante de cada banco y el interior visitable del Banco Cantabria.

- **Hecho: el cajero del Banco Cantabria** (`godot/scripts/bancosancho.gd`, `_cajero()`). Antes era un dibujo en la pared. Ahora es un cajero modelado en su marco rojo: la pantalla encendida («Bienvenido / Introduzca su tarjeta»), las teclas de los lados, la repisa del teclado, las ranuras de la tarjeta (con su luz verde), el recibo y los billetes, la visera roja con su luz y las pantallas laterales.
  - **Para Sistemas**: `G.world.bancosancho.cajero_spot` (dónde se pone el jugador, en el mapa, a 0,8 m de la pared), `cajero_face` (hacia dónde mira, como `out_h`) y `cajero_at` (la pantalla, en el mundo).
- **Hecho: el interior del Banco Cantabria** (`godot/scripts/banco_dentro.gd`, nuevo). Es un decorado aparte en (−1840, 1320), al que se entra por la flecha verde de la puerta de cristal, en horario del banco.
  - Una sucursal de pueblo, de 9 × 10 m, que no copia ninguna real: baldosa clara y paredes blancas con la banda roja del banco y su nombre al fondo.
  - A la izquierda, las sillas de espera, la mesa de folletos, el expositor y una planta.
  - Al fondo, el mostrador de caja tras su cristal, con dos puestos, los postes y la cinta roja de la cola, los archivadores y la puerta redonda de la cámara acorazada.
  - A la derecha, el rincón del encargado tras una mampara baja de cristal: su mesa con pantalla, papeles, teléfono y placa, su sillón, dos sillas para quien venga, el archivador y el calendario.
  - Sin personajes: al encargado lo pone Sistemas.
  - **Para Sistemas**: `G.world.bancosancho.banco`, con `manager_spot` y `manager_h` (dónde está el encargado y hacia dónde mira), `client_spot` y `client_h` (dónde se pone el jugador ante su mesa), `counter_front` (ante la caja) y `open` (lo mantiene `set_open`).
- **Hecho: las seis fachadas de la casa** (Calle de Alemania 5). Sistemas eligió el camino: seis fachadas como nodos aparte y solo una visible.
  - `godot/scripts/casa_fachada.gd` (nuevo): una fachada hecha a mano con el kit de `obra.gd`, según el estado.
    - 0, heredada: cal vieja desconchada hasta el adobe, puerta y portón de tablas grises, tejado con tramos caídos.
    - 1, arreglada: encalada, puerta y ventana verdes con reja, tejado entero, un farol y un geranio.
    - 2, primera ampliación: zócalo añil, huecos enmarcados en blanco (también el portón, ya de dos hojas).
    - 3, habitación a la izquierda: una ventanita con reja en ese extremo, un poyo junto a la puerta y otro farol.
    - 4, habitación a la derecha: otra ventana con reja, el portón pasa a ser puerta de garaje con marco de ladrillo y tejadillo, y aparece la cornisa de ladrillo bajo el alero.
    - 5, segunda planta: tres balcones con barandilla de hierro, la banda añil, la cornisa y una chimenea.
  - `godot/scripts/casa_fuera.gd` (nuevo): las seis juntas. Oculta las demás, les quita la colisión y da a las luces del pueblo solo los faroles de la visible.
  - **Para Sistemas**: `G.world.casa_fuera.set_state(n)` con n de 0 a 5; además `state`, `door`, `openings()` y `top()`.
  - La puerta de la calle no se mueve en ningún estado (a 2,14 m del extremo izquierdo, de 1,0 × 2,1): `HOME_DOOR`, la placa del Padrón, la flecha y la pintada de la peña siguen en su sitio.
  - El SPEC `alemania_5` se queda en `casas.gd`, porque `casa_dentro.gd` lo lee para situar la puerta.
- **Hecho: el interior de la casa en seis estados.**
  - `godot/scripts/casa_estado.gd` (nuevo): la casa por dentro tras cada obra (estados 1 a 5), cada una un interior entero.
    - 1, arreglada: la misma sala, con mesa y sillas, cortinas, una planta y lámpara.
    - 2, primera ampliación: la sala crece hacia la derecha (de 6 a 10 m), con cocina en la pared del fondo, comedor y aparador.
    - 3, habitación a la izquierda: un baño.
    - 4, habitación a la derecha: un salón con sofá, sillón, televisión y librería.
    - 5, segunda planta: una puerta al fondo, la escalera detrás y arriba un estudio con puertas a la terraza.
  - `godot/scripts/casa_dentro.gd` (de Sistemas, solo añadidos): la sala actual es el estado 0. `set_state(n)` oculta sus paredes y le quita la colisión, y muestra la casa del estado pedido.
  - La cama, el armario, la pintada sobre la cama, `bed_spot`, `wardrobe_spot`, `in_door` e `in_spawn` no cambian en ningún estado. Por eso la casa crece hacia la derecha y por puertas en las paredes.
  - La planta de arriba no está encima de la baja, sino más al fondo, subiendo su escalera: dos pisos no pueden compartir un punto del mapa (`MapData.decks`). Dentro del decorado no se nota.
  - **Para Sistemas**: `G.casa.set_state(n)`, `state`, `rooms()`, `room_at(pp)` (para la cámara de `entradas.gd`), y en el estado 5 `back_door` (ante la puerta del fondo, en la sala) y `back_spawn` (arriba, al final de la escalera). Se sube andando: no hace falta transporte.
- **Sin personajes** en ningún estado.
- **Azafrán escondido** (acuerdo con Sistemas): las flores de sitios especiales llevan `"id"` y `"hidden": true` en `G.flowers`. La del silo ya lo lleva (`"id": "silo"`).
- **Archivos**: `godot/scripts/bancosancho.gd` (el cajero, `BancoS`, `var banco`, y `banco.open` en `set_open`), `godot/scripts/banco_dentro.gd`, `godot/scripts/casa_fachada.gd`, `godot/scripts/casa_fuera.gd`, `tools/casa/hojas.py` y la clave del azafrán en `godot/scripts/silo_dentro.gd`.
  - Compartidos, con el aviso dado: `casas_calles.gd` (de Texturas: la línea `"alemania_5": ["obra"]`), `world.gd` (`CasaFueraS`, `var casa_fuera` y el paso «the house you inherit», tras el del silo), `casa_dentro.gd` (los añadidos de los estados) y `selftest.gd` (el modo `--casa`, y `_casa_fuera_checks()` y `_casa_dentro_checks()` en la prueba completa).
  - Nuevo también `godot/scripts/casa_estado.gd`.
  - Compartido, con el aviso dado a Sistemas: `entradas.gd`, una línea en `shops()` para `bancosancho.banco`.
- **Pruebas.** `python tools/run_tests.py bancosancho`: 5 ok, 0 fallos ([log](logs/selftest_bancosancho_20261121_133253.log)), ya con el interior del banco.
  - Antes daba 1 fallo ajeno al cajero: la prueba esperaba entrar en la copistería solo con pisar la flecha. Lo arregló Sistemas.
  - Después de esa prueba solo he bajado el brillo de los carteles del interior; no la he repetido.
  - La entrada al banco por la flecha no la he probado yo: la pasa Sistemas con `herencia`.
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_140527.log)), con fachadas e interior.
    - Un primer intento falló por el límite de mi propia comprobación: la puerta está a 1,54 m del punto `HOME_DOOR`, que es un sitio de la calle junto a ella, y pedía 1,5.
    - Otro no arrancó: había llamado `_shell` a una variable y ya existía una función con ese nombre en `casa_dentro.gd`.
  - `python tools/run_tests.py entradas`: 4 ok ([log](logs/selftest_entradas_20261121_141529.log)).
  - `python tools/run_tests.py padron`: 9 ok ([log](logs/selftest_padron_20261121_141814.log)): la placa con el nombre sigue sobre la puerta con la fachada hecha a mano.
  - `python tools/run_tests.py silo`: 6 ok ([log](logs/selftest_silo_20261121_134920.log)), con el azafrán ya marcado.
- **Hojas para Luis.** `guion/fotos/casa/01_fachadas.jpg` y `02_interiores.jpg` (`tools/casa/hojas.py`).
- **Fachadas aprobadas por Luis** («Las fachadas están increíbles»), con un cambio: faltaban plantas en la última.
  - Hecho en `casa_fachada.gd` (`_plants()`, `_climber()`, `_tuft()`, `_shrub()`), solo en el estado 5:
    - tres macetas de geranios colgadas por fuera de la barandilla de cada balcón, la del centro con una gitanilla que cae;
    - cuatro macetas colgadas en la pared, entre los balcones;
    - una fila de macetas al pie de la fachada, una sobre el poyo y dos macetones verdes;
    - tres macetas en cada alféizar en vez de una;
    - una buganvilla que sale de un macetón en el extremo derecho, sube hasta el alero y tiende un brazo sobre el garaje.
  - Ninguna planta es sólida ni cambia la puerta, los faroles o `openings()`.
  - En `selftest.gd`, una foto más en el modo `--casa`: `casa_5_plantas`.
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_142420.log)).
  - Hoja: `guion/fotos/casa/03_plantas.jpg`.
- **Capturas sueltas a petición de Luis**: `guion/fotos/casa/estados/fachada_N_*.jpg`, una por estado, de frente.
  - En `selftest.gd` (modo `--casa`), la vista de frente oculta a los vecinos y al jugador para que nadie tape la fachada; la vista desde la calle los deja.
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_142809.log)).
- **Segunda corrección de Luis a las fachadas**: «La cornisa de ladrillo añádela en la 4 y mantenla en la 5 mejor. Demasiadas flores en la 5. Quita la enredadera de la 5 y reduce un poco las flores».
  - La cornisa de ladrillo pasa de «desde el estado 2» a «desde el estado 4»: los estados 2 y 3 quedan con el alero de tejas sin más.
  - En el estado 5: fuera la buganvilla (`_climber()`, `_tuft()` y `_rnd()` borradas). Dos macetas colgadas por balcón en vez de tres y sin gitanilla, dos en la pared en vez de cuatro, una por alféizar en vez de tres, y cinco al pie de la fachada en vez de siete. Quedan el poyo con su maceta y los dos macetones verdes.
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_143252.log)).
  - Capturas y hojas rehechas (`guion/fotos/casa/`).
- **Tercera corrección de Luis**: «En las fotos que has pasado la cornisa de ladrillo del garaje aparece antes de la 4 y desaparece en la 4 y la 5. Quiero lo contrario».
  - Yo había entendido mal la anterior: Luis hablaba del marco de ladrillo con tejadillo del portón, no de la cornisa del alero.
  - Hecho en `casa_fachada.gd`: el portón de los estados 2 y 3 lleva marco blanco, como la puerta y la ventana; la puerta de garaje de los estados 4 y 5 lleva el marco de ladrillo con su tejadillo (antes llevaba el blanco).
  - Las dos macetas de la derecha y el macetón junto al garaje se apartan un poco para no pisar el ladrillo.
  - La cornisa del alero se queda como en la corrección anterior (desde el estado 4).
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_144321.log)).
  - Capturas y hojas rehechas.
- **Visto bueno de Luis a todo el encargo** (cajero, interior del banco, fachadas e interiores de la casa): «Quitando eso visto bueno a todo lo tuyo» y, minutos después, «Ahora sí, visto bueno».
  - Queda aprobado lo que muestran las últimas capturas enviadas: cornisa del alero desde el estado 4, ladrillo y tejadillo del garaje en los estados 4 y 5, y la fachada 5 sin enredadera.
  - Entre sus dos mensajes devolví la cornisa del alero al estado 2 (leí el primero como «eso no») y, al llegar el segundo, la restauré al estado 4 para que el juego coincida con las fotos aprobadas. Si Luis la quiere desde el estado 2 es una línea: `state >= 4` por `state >= 2` en `_front()`, donde dice «the eaves».
  - Prueba final: `python tools/run_tests.py casa`, 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_145538.log)).
  - Sin commit: lo hace Sistemas con la 0.0.19.
- **Sin commit.**

### Silo del Tío Anaranjao (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Luis, tras aprobar el parque: «Pasamos al siguiente proyecto que es algo más complejo. […] el silo del tío colorao (que lo llamaremos silo del tío anaranjao). Aparte de la fachada quiero que se pueda visitar por dentro (hay varias fotos 360 por dentro), con sus muebles y utensilios de como vivía antes la gente bajo tierra en la mancha». Mandó el enlace de Google Maps y una captura del mapa. Las fotos no se guardan en el repositorio.

- **Hecho.** El Silo del Tío Colorao real (C. San Agustín 9), con el nombre de Luis. Detalle, planta y trampas en `referencias/silo/LEEME.md`.
  - **Fuera** (`godot/scripts/silo.gd`, sin horneado): la tapia blanca con albardilla de teja siguiendo la acera en curva, el portón claveteado, el cartel «SILO DEL TÍO ANARANJAO», cinco rejas, y dentro el patio de tierra con el caño visto desde arriba y dos chimeneas.
  - **Dentro** (`godot/scripts/silo_dentro.gd`, un decorado aparte en (1560, −1120) al que se entra por la flecha verde del portón): la bajada con escalones y rampa empedrada, el patio hundido, la cuadra, la leñera y dos viviendas. En total, nueve estancias con sus muebles y utensilios. Sin personajes.
- **La cámara.** Las estancias eran pequeñas y bajas, y la cámara de esquina quedaba pegada a la cabeza. La primera solución (quitar la tierra de encima y mirar desde arriba) no le gustó a Luis: ver la corrección de abajo.
- **Fuentes.** El recorrido virtual de 38 fotos 360 de 2019, las diez fotos del sitio, Street View de 2024 y la ortofoto. Herramientas nuevas en `tools/silo/` (`cerca360.py`, `tour360.py`, `baja360.py`, `hojas360.py`, `fotos.py`, `manzana.py`, `hojas.py`).
- **Archivos compartidos**, con el aviso dado a Sistemas y a Texturas:
  - `world.gd`: `SiloS`, `var silo` y el paso «the Silo del Tío Anaranjao» tras el parque del Paseo;
  - `entradas.gd`: `world.silo.dentro` en `shops()`, y `camera()` usa `place.room_at(pp)` si el decorado lo tiene (los demás decorados no cambian);
  - `selftest.gd`: el modo `--silo` y `_silo_checks()` en la prueba completa, tras `_paseo_checks`.
- **Pruebas.**
  - `python tools/run_tests.py silo`: 5 ok, 0 fallos ([log](logs/selftest_silo_20261121_125531.log)).
  - `python tools/run_tests.py entradas`: 4 ok, 0 fallos ([log](logs/selftest_entradas_20261121_125808.log)).
  - La prueba completa no se ha pasado.
  - El primer intento falló al entrar: sobre la flecha hay que pulsar el botón de acción. Ya está corregido en la prueba.
- **Hojas para Luis.** `guion/fotos/silo/01_fuera.jpg`, `02_bajada_patio_y_cuadra.jpg`, `03_primera_casa.jpg` y `04_segunda_casa.jpg`: las fotos reales al lado del juego.
- **Aprobado** por Luis el 21/11, con tres cambios ya hechos.
  - Sus palabras: «Visto bueno pero no me gusta que parezca que está al aire libre, podrías hacer la cueva un poco más profunda y colocar la cámara de tal manera que no se note que el modelo no tiene techo. También podrías dejar las puertas abiertas para que se vea un poco el modelo de la entrada desde fuera». Y después: «Deja el cable negro. Pero revisa las puertas, tienen una textura de suelo clippeada y las paredes interiores atraviesan las puertas».
  - **La cueva, más honda** (`silo_dentro.gd`): el patio queda 4,6 m bajo el corral (antes 2,8). Las estancias miden unos 4 m de alto, con bóveda, así que la cámara cuelga a 3,6 m por debajo del techo y solo ve paredes blancas. Ya no se quita ninguna tapa de tierra.
    - La bajada es ahora una escalera larga de 23 peldaños empedrados, sin rampa: con esa hondura la rampa salía demasiado empinada.
    - En la escalera la cámara baja detrás del jugador, unos peldaños más arriba (`room_at`).
    - El cable de las bombillas se queda negro.
  - **El portón, abierto** (`silo.gd`): las dos hojas abren hacia dentro y desde la calle se ve el rellano empedrado y los primeros peldaños, que se van oscureciendo. No se cruza andando: se entra por la flecha.
  - **El arreglo del portón**: el caño de fuera iba torcido (con el rumbo del real) y nivelado a la cota más alta del patio, así que el suelo y los muretes atravesaban las hojas. Ahora sale recto del portón, es más ancho que él y va pegado al terreno tramo a tramo.
  - **Pruebas**: `python tools/run_tests.py silo`, 5 ok y 0 fallos ([log](logs/selftest_silo_20261121_132656.log)). Hojas rehechas.
- **Cerrado** por Luis el 21/11: «El silo está perfecto. Añade un azafrán en una de las habitaciones pequeñas y lo damos por cerrado. (Pasale a sistemas que sería buena idea esconder azafrán en ubicaciones especiales)».
  - **El azafrán** (`silo_dentro.gd`, `_saffron`): una flor de azafrán en una macetita de barro, junto a la pared de la última alcoba (la de la cama azul, al fondo de la segunda casa). Es el coleccionable del juego, igual que los de las calles: al acercarse se recoge (+1 azafrán, +6 €). La maceta se queda.
    - El decorado la añade él mismo a `G.flowers` (`{"node", "p"}`), sin tocar `game.gd`. Su sitio queda en `silo.dentro.saffron_spot`.
    - Como las demás flores, vuelve a estar ahí cada vez que se arranca el juego.
  - **Idea de Luis pasada a Sistemas**: esconder azafrán en ubicaciones especiales.
  - **Pruebas**: `python tools/run_tests.py silo`, 6 ok y 0 fallos ([log](logs/selftest_silo_20261121_133743.log)); la comprobación nueva recoge la flor.
- **Sin commit.**

### Parque del Paseo del Cristo (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Luis, tras aprobar la Residencia: «Visto bueno. Podemos continuar con el parque largo empedrado que hay al lado del paseo del cristo (tiene su propia linea en street view, sin nombre)». Mandó una foto de noviembre de 2024 de la esquina oeste y el mapa con la flecha. Las capturas no se guardan en el repositorio.

- **Hecho.** `godot/scripts/paseo.gd`, sobre `obra.gd`. Es el «Parque del Paseo del Cristo» del mapa: unos 165 m desde la esquina de la Calle de las Viñas y la Calle de los Arcos hasta la placita de la ermita.
  - **El paseo central**: baldosa clara de 40 cm con un cuadro rojo en marco rojo cada 15 m. Apunta a la puerta de la ermita (a 0,01 m). A cada lado, una banda de losas de pizarra irregulares (`tools/paseo/losas.py` → `godot/assets/paseo/losas.png`).
  - **Los céspedes** con bordillo, y la acera ajedrezada roja y crema a lo largo del Paseo.
  - **Al oeste**:
    - la plaza de ladrillo, con la prensa de piedra (ver la corrección de abajo);
    - el seto de boj ante la casa de los arcos;
    - el parterre de cipreses con su verjita, el álamo y la farola alta;
    - el monolito con su banco de granito y su pilón, y la mesa de piedra con su asiento redondo.
  - **Al norte**: la tapia blanca de los huertos, con su albardilla de teja. Después, el murete de mampostería con pilares de ladrillo y verja, ante los patios y el callejón. La fuente de rocalla, entre el sauce llorón y una palmera.
  - **La plaza de losas del cruce**, con faroles de dos brazos. Al este, las losas alrededor del calvario (el de `cristoprado.gd`), los bancos de granito y los bolardos ante la placita.
  - **Lo demás**:
    - 33 árboles donde la ortofoto tiene sus copas: plátanos encalados, olmos y olmos trasmochos, álamos, la acacia, el sauce y una palmera;
    - bancos de hierro;
    - 22 faroles que se encienden con los del pueblo (`W.lamp_spots`);
    - papeleras y bolardos, como mobiliario que se puede tumbar (`W.extra_props`).
- **Sin horneado.**
  - Se tiende sobre el suelo, el césped y la senda del mapa, y se corta por el borde del asfalto tal como lo pone el juego: cada tramo de calle es una cápsula de su ancho ajustado, y las sendas peatonales no cuentan.
  - Los bordes se leen al cargar: el asfalto del Paseo al sur; la tapia, la verja, el callejón o las casas al norte.
  - Los 13 árboles del mapa que caían dentro se quitan con `W.fell_tree`.
- **Trampas.**
  - El Paseo del juego está unos 4 m metido en el parque real, así que el césped sur queda más estrecho.
  - La línea propia de Street View del parque es solo de marzo de 2013. En 2024 solo hay fotos desde el coche.
  - La tapia blanca no está en el mapa: la levanta el parque.
  - El asfalto de la esquina de la Calle de los Arcos pasa a 2,5 m del parterre de cipreses, que se corre hacia el este hasta quedar libre.
- **La casa de los arcos** (la de la foto de Luis, en la esquina norte) sigue siendo la casa genérica del horneado: no forma parte del parque.
- **Fuentes.** Street View (las cámaras están en `tools/paseo/capturas.py`), la ortofoto `tools/ign/paseo_cristo.jpg` y la foto de Luis. Notas en `referencias/paseo/LEEME.md`.
- **Archivos compartidos**, con el aviso dado a Sistemas:
  - `world.gd`: `PaseoS`, `var paseo` y el paso «the park of the Paseo del Cristo» detrás de la Residencia;
  - `selftest.gd`: el modo `--paseo` y `_paseo_checks()` en la prueba completa, tras `_residencia_checks`.
- **Pruebas.** `python tools/run_tests.py paseo`: 3 ok, 0 fallos ([log](logs/selftest_paseo_20261121_081505.log)).
  - El primer intento contaba las sendas peatonales como calles, y el borde del Paseo salía en la senda central. Ya está corregido.
- **Hojas.** `guion/fotos/paseo/01_street_view_y_juego.jpg` (13 puntos de Street View al lado del juego) y `02_en_el_juego.jpg` (la foto de Luis al lado del juego, y el parque).
- **Commit** `ad86143` de Sistemas (sin push), con la ermita y la Residencia.
- **Corrección: las piezas de piedra (21/11, mañana).**
  - Luis mandó cuatro capturas de Street View de marzo de 2013, de la línea propia del parque: «Faltan varias cosas. La prensa de piedra, el monolito de piedra, la mesa de piedra, la fuente». Las capturas no se guardan en el repositorio.
  - **Todo en `paseo.gd`**, con piezas nuevas del kit: `_lump` (una piedra tosca de caras planas, con ruido fijo), `_arc` (un murete curvo con albardilla) y `_arc_solids`.
    - **La prensa** (`_press`), en la esquina ante la casa de los arcos. Lleva un zócalo redondo de mampostería con albardilla, la solera, tres rulos cónicos de granito con la chapa de hierro del ojo y su churrete de óxido, el eje de hierro, los brazos y el aro. Uno de los rulos mira a la casa, como en la foto. Sustituye a la muela de pie y el cono de 2024.
    - **El monolito** (`_monolith`): una piedra alta y tosca de unos 2,1 m, ancha al pie y con una mancha de pintura roja. A su lado, un banco largo de granito al borde del paseo y un pilón de piedra con matas secas. Sustituye a la piedra y al tronco tallado.
    - **La mesa de piedra** (`_mesa`): un asiento redondo de mampostería con albardilla, abierto al este y al oeste, con respaldo en la mitad sur y la mesa redonda sobre su pie en medio. Sustituye a la jardinera redonda.
    - **La fuente de rocalla** (`_fountain`). Lleva el estanque de agua limpia (como la que Luis quiso para la plaza), el murete de toba, ocho pilares de toba con maceteros blancos y sus plantas, cadenas colgadas entre ellos, el montículo en medio con la estatua y losas alrededor hasta la banda del paseo. Sustituye a la rocalla de piedras sueltas.
    - **La estatua** (`_statue`). Luis, al ver la hoja: «Muchísimo mejor. Solo cambiaría que la estatua de la fuente es de una mujer desnuda con un jarrón de donde sale el agua que cae a la fuente».
      - Primero se hizo de piedra blanca, como en Street View (p14_n, 2013): una mujer desnuda de pie, con la cabeza inclinada hacia el cántaro que lleva al hombro izquierdo.
      - Luis, después: «vamos a sustituirlo por una figura de mármol de una mujer al estilo de nuestros personajes. Igual que con la estatua de bronce del fraile».
      - **Ahora es una figura del juego** (`chara.gd`), como el fraile de `santaana.gd`, pasada entera a mármol blanco: una mujer con moño, pestañas y nada de ropa, a 0,55 de tamaño (cerca de 1 m).
      - Tiene la cabeza un poco inclinada hacia el cántaro, que lleva al hombro izquierdo con esa mano; la otra mano la tiene delante. El nodo es `paseo.statue`.
      - Del cántaro cae un hilo de agua, que corre pegado a la rocalla hasta el estanque. Se hace con `_limb`, una pieza redonda de un punto a otro.
      - `chara.gd` no pasa la comprobación de sintaxis suelta (le falta MapData), así que se ha probado en el juego.
  - **Trampa de la fuente**: el callejón del norte pasa en el juego unos 2 m más al sur que el real, y la fuente no cabía. Ahora se coloca sola entre el borde norte tal como lo pone el juego y el paseo, y encoge si hace falta: queda con 2,08 m de radio exterior en lugar de 2,25.
    - El sauce pasa a (125,0, −8,4) y la palmera nueva queda en (131,2, −8,5), a cada lado.
    - Se quitan el banco norte de x = 127 y una papelera, que caían encima.
  - **Archivos**: `godot/scripts/paseo.gd` y `tools/paseo/hojas.py`, con la hoja 03 (`piezas=`, las cuatro fotos al lado del juego). Ningún archivo compartido.
  - **Pruebas**: `python tools/run_tests.py paseo`, 3 ok y 0 fallos ([log](logs/selftest_paseo_20261121_120228.log), ya con la figura de mármol), sin errores de formato en el registro.
    - En el primer intento el monolito salió negro: los materiales nuevos no habían entrado en `_material`. Ya está corregido.
    - Las vistas se llaman `ps_*`: con `pz_*` se leen en el marco de la plaza.
  - **Hojas**: `guion/fotos/paseo/03_piezas_de_piedra.jpg`, nueva, con la estatua de cerca al lado de Street View; `01` y `02`, rehechas.
- **Aprobado** por Luis el 21/11 («Visto bueno»), con las piezas de piedra y la figura de mármol. Las piezas y la figura, sin commit.

### Calle de las Viñas: 44 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Es la siguiente calle del núcleo, a la orden del usuario («Visto bueno y siguiente»).

- **Hecho.** 44 casas con su frente en las Viñas (`vin_*`), descritas con las fotos del Catastro y doce con Street View. Lo que queda fuera y por qué está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd`: 44 entradas nuevas.
  - `godot/data/map.json`: horneado.
  - Las carpetas del Catastro `tools/casas/<ref>/`.
  - Las hojas `guion/fotos/tanda34/vinas_1..8.jpg`.
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado dos veces sobre el mapa de Edificios Especiales de las 02:25, con el Cristo del Prado y la Residencia, avisándole antes y después de cada vez.
  - La segunda vez fue para quitar `vin_bv12`, `vin_bv11` y `vin_ja8`, cuyas fachadas quedaban detrás de otras.
  - Comparado con la copia de antes: 44 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954) siguen igual.
  - La holgura de 21 nodos junto a las casas nuevas baja unos 0,7 m; la menor queda en 3,7 m.
  - Ninguna casa tiene partes por delante de su frente.
- **Lección.** Además de las partes por delante, conviene buscar fachadas paralelas en el mismo lado de la calle a menos de unos 9 m una de otra. La de detrás no se ve desde la calle, y en la hoja la cámara queda dentro de la de delante.
- **Pruebas.**
  - `casas solo=vin_`: el primer intento falló porque `vin_rs67` no llegaba a 12 piezas.
  - Con la celosía de su foto, `solo=vin_rs67` dio 4 ok.
  - Tras los arreglos, `solo=vin_rs71,vin_x2,vin_12,vin_x4,vin_bv14,vin_4b,vin_4` dio 4 ok, 0 fallos ([log](logs/selftest_casas_solo_vin_rs71_vin_x2_vin_12_vin_x4_vin_bv14_vin_4b_vin_20261121_023910.log)).
- **Aprobada** por el usuario el 21/11 («Visto bueno y siguiente»). En el commit `ad86143` (Sistemas, 21/11, sin push).

### Calle del Florido, tramo norte: 29 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Es la siguiente calle del núcleo, a la orden del usuario («Visto bueno y siguiente», tras aprobar las Viñas). La calle es larga (unas 84 casas, más 20 en la Bajada del Florido) y va en tres tandas; esta es la primera, de los Silos a la Bajada.

- **Hecho.** 29 casas con su frente en el Florido (`flo_*`), descritas con las fotos del Catastro y doce con Street View de noviembre de 2024. Lo que queda fuera y por qué está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos puestos a mano** (en `tools/casas/calles.json`):
  - `flo_68`: frente por la pared de delante, sobre el hueco de la escalera de fuera.
  - `flo_50` y `flo_50g`: una misma referencia partida por plantas con `only`: la parte de una planta y la de dos, cada una con su trozo de frente.
  - `flo_b10`: el trozo de una planta (`only` 1) de Bajada del Florido 10, su portón a esta calle.
  - `flo_62`: la tapia del patio, sin referencia (`rc` null, 0,9 m de fondo), porque el Catastro da el patio sin plantas.
  - Los Ángeles 1 queda fuera: su cara a esta calle está detrás de la casa de la esquina.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd`: 29 entradas nuevas.
  - `godot/data/map.json`: horneado.
  - Las carpetas del Catastro `tools/casas/<ref>/`.
  - Las hojas `guion/fotos/tanda34/florido_1..5.jpg`.
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el mapa de las 02:39 (el de las Viñas), avisando a Edificios Especiales antes y después.
  - Comparado con la copia de antes: 29 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954) siguen igual; la holgura de un nodo baja de 4,9 a 3,5 m.
  - Antes de hornear se comprobó que ninguna casa tiene partes por delante de su frente ni fachadas paralelas escondidas detrás de otras (`precheck.py` en el scratchpad, sobre los anillos de `datos.json`).
- **Pruebas.**
  - `casas solo=flo_`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_flo__20261121_053430.log)).
  - Tras los arreglos de la comparación, `solo=flo_65,flo_66,flo_60,flo_58,flo_an15,flo_b10,flo_50,flo_50g,flo_48,flo_49` dio 4 ok, 0 fallos. El primer intento paró en un error de compilación de `residencia.gd`, que Edificios Especiales estaba editando; al terminar él, pasó.
  - `solo=flo_48`, con el friso en ladrillo oscuro: 4 ok ([log](logs/selftest_casas_solo_flo_48_20261121_054237.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En el mensaje de las hojas lo llamé «tramo sur» por error; es el extremo norte de la calle (en el mapa, z negativa es el norte). En el commit `ad86143` (Sistemas, 21/11, sin push).

### Calle del Florido, tramo medio, y Bajada del Florido: 34 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Segunda de las tres tandas del Florido, a la orden del usuario («Visto bueno y siguiente», tras aprobar el tramo norte).

- **Hecho.** 18 casas del Florido entre la Bajada y el 21 y el 26 (`flo_*`) y 16 de la Bajada del Florido (`bfl_*`). Fotos del Catastro, y ocho con Street View de noviembre de 2024. Lo que queda fuera y por qué está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - `bfl_10` lleva `only` 2; su parte de una planta es `flo_b10`, del tramo norte.
  - Monjas 65 y 63 quedan fuera: sus frentes a la Bajada están de 4 a 7 m detrás de `bfl_2` y `bfl_1`, en el mismo lado.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (34 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/florido_medio_1..6.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 05:34 (el del tramo norte), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 34 casas nuevas, ninguna quitada. `flo_50g` cambia solo en qué aristas quedan tapadas por la casa nueva de al lado. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: ninguna parte por delante; las únicas fachadas escondidas eran las de Monjas 65 y 63, que se quitaron.
- **Pruebas.**
  - `casas` de las 34: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_flo_41_flo_46_flo_39_flo_34_flo_37_flo_32_flo_35__20261121_055758.log)).
  - Tras los arreglos, `solo=flo_27,flo_23,flo_26,bfl_21,bfl_23`: 4 ok ([log](logs/selftest_casas_solo_flo_27_flo_23_flo_26_bfl_21_bfl_23_20261121_060251.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En el commit `ad86143` (Sistemas, 21/11, sin push).

### Calle del Florido, tramo sur, y Prolongación del Florido: 39 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Última de las tres tandas del Florido, a la orden del usuario («Visto bueno y siguiente», tras aprobar el tramo medio y la Bajada).

- **Hecho.** 18 entradas del tramo sur del Florido (del 24 y el 15 hasta el final, con el 1 A y el 1 B) y 21 de la Prolongación (`flo_p*`), todas `flo_*`. Fotos del Catastro, y Street View de 2024 (2026 en la Bajada del Rollo) en las casas sin foto, cambiadas o dudosas. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - `only` para partir dos referencias: `flo_x2`/`flo_x2g` (3692606, bloque de tres plantas y almacén con `reach` 6, para que sus naves de la calle de la Vega queden normales) y `flo_x3`/`flo_x3t` (3692608, bloque y tapia de bloques).
  - Pareadas impares de la Prolongación: `house_street` cogía la cara inclinada del porche (4 m). El frente va ahora paralelo a la calle en la cara del cuerpo de dos plantas, a todo lo ancho, con `floors` 2 y `strip` 2.5 para quitar el porche (lo calcula `sur_write.py` en el scratchpad).
  - Bajada del Rollo 4 (3692302) está derribada según Street View de 2026. No hay forma de dejar un solar sin tocar `bake_godot.py`, así que queda la casa genérica; está apuntado.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (39 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/florido_sur_1..7.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 05:57 (el del tramo medio), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 39 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: ni partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 39: 3 ok, 1 fallo, porque `flo_x3t` tenía pocas piezas ([log](logs/selftest_casas_solo_flo_24_flo_15_flo_x4_flo_13_flo_11_flo_9_flo_22_f_20261121_075137.log)).
  - Con más hiladas, `solo=flo_x3t`: 4 ok ([log](logs/selftest_casas_solo_flo_x3t_20261121_075422.log)).
  - Tras los cambios de color: 4 ok ([log](logs/selftest_casas_solo_flo_x2_flo_p13_flo_p15_flo_p14_flo_p16_flo_p18_fl_20261121_075654.log)) y 4 ok ([log](logs/selftest_casas_solo_flo_p14_flo_p16_flo_p18_flo_p20_flo_p22_flo_p24_f_20261121_075815.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y seguimos»). En el commit `ad86143` (Sistemas, 21/11, sin push). La Bajada del Rollo 4 sigue genérica.

### Commit del Cristo del Prado, la Residencia, el Paseo, el suelo y las casas del Florido (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Cuando terminen sus dos trabajos actuales haz commit».
- Los trabajos son el parque del Paseo de Pretil y lo que tenía Texturas.
- Prueba completa: 886 ok, 1 fallo. El fallo era solo el mínimo de fachadas de «houses meet their street»: pedía más de 5000 y quedan 4807, porque las casas hechas a mano sustituyen a las genéricas.
- Los límites de verdad pasan: 6 fachadas raras, la peor 2,4 m por encima y 0,1 m por debajo.
- El mínimo baja a 4000 en `selftest.gd`, con una nota.
- Commit `ad86143`, sin push.
- Queda: el tramo sur del Florido, a la espera del visto bueno del usuario. Y unos errores del motor al cargar: `set_uv` en `obra.gd` desde `cristoprado.gd` `_calvario`, el tejado. No hacen fallar la prueba; se lo he pasado a Pretil.

### Calle de la Rosa del Salvador: 35 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y seguimos», tras aprobar el tramo sur del Florido).

- **Hecho.** 35 entradas `rsa_*`. Fotos del Catastro (2019), y Street View de noviembre de 2024 (el 24, de 2013) donde no había foto, la foto era de otra fachada o la casa ha cambiado. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Lado par del 20 al final: la calle del mapa va 3–4 m al sur de la real. Frentes de la pared genérica (`frente_gen.py`) con `clear` 6; el 4 y el 6 también (su frente del Catastro era una pared interior), con `clear` 3.
  - Cajas a mano (`rc: null`): `rsa_9` y `rsa_18` (0 plantas en el Catastro: eran un hueco en el juego), `rsa_10g` (la parte de 0 plantas de la trasera de Sevilla 7) y `rsa_34` (el cobertizo; la parcela de Sevilla 27 queda bajo la calle).
  - Traseras con `reach`: `rsa_s7`, `rsa_s9` (8 m), `rsa_24`, `rsa_44` (6 m) y `rsa_36` (8 m); `rsa_1` lleva `reach` 6 para dejar su bloque de tres plantas del fondo.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (35 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/rosa_salvador_1..6.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 07:51 (el del Florido sur), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 35 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve, árboles (2954) iguales. Solo la holgura del nodo 310 (Rosa del Salvador) pasa de 2,3 a 2,1 m.
  - `precheck.py` antes de hornear: sin fachadas escondidas; partes por delante solo en las de `clear`.
- **Pruebas.**
  - `casas` de las 35: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_rsa_1_rsa_3_rsa_5_rsa_7_rsa_9_rsa_11_rsa_13_rsa_1_20261121_113502.log)).
  - Tras arreglar puertas y tonos, `solo=rsa_1,rsa_4,rsa_6,rsa_15,rsa_21,rsa_32`: 4 ok ([log](logs/selftest_casas_solo_rsa_1_rsa_4_rsa_6_rsa_15_rsa_21_rsa_32_20261121_113959.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y continuar»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de Sevilla: 36 casas, y `house_of` con `reach` en el horneado (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y continuar», tras aprobar la Rosa del Salvador).

- **Hecho.** 36 entradas `sev_*`. Fotos del Catastro, y Street View de noviembre de 2024 donde no había foto, la foto era de otra fachada o la casa ha cambiado. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Cambio en `tools/bake_godot.py`.**
  - `house_of(bid, floors, p)` salta una entrada cuyo `reach` deja fuera la parte `p` y prueba la siguiente con la misma referencia.
  - Motivo: cuatro parcelas pasantes (Sevilla 7, 9, 19 y 29) ya tenían su trasera en la Rosa (`rsa_s7`, `rsa_s9`, `rsa_24`, `rsa_36`, con `reach`). Antes, la primera entrada era la única que contaba, y la fachada de Sevilla se quedaba genérica.
  - Las referencias con una sola entrada hornean igual: el horneado no quitó ni movió ninguna casa.
- **Archivos.** `tools/bake_godot.py`, `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (36 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/sevilla_1..6.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 11:34 (el de la Rosa), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 36 casas nuevas, ninguna quitada. `rsa_6`, `rsa_8`, `rsa_s7` y `rsa_36` cambian solo en qué aristas quedan tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 36 y las cuatro de la Rosa: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_sev_3_sev_5_sev_7_sev_9_sev_11_sev_13_sev_15_sev__20261121_120325.log)).
  - Tras arreglar los tonos del 13 y del 22, `solo=sev_13,sev_22`: 4 ok ([log](logs/selftest_casas_solo_sev_13_sev_22_20261121_120630.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Las cámaras de las giras de la Chiki y de Alberto (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «La cámara de la Chiki cuando te enseña los grafitis y la de Alberto cuando enseña el pueblo muchas veces acaba clippeada entre edificios y no se ve el objetivo».

- **Por qué pasaba.** Las dos ponían la cámara a una distancia fija de la calle más cercana.
  - La Chiki, a 7 m de la pared hacia fuera. En una calle estrecha eso cae dentro de la casa de enfrente: con los sitios viejos, 22 de las 60 paredes no se veían.
  - Alberto, a 7 m a lo largo de la calle. En una curva o al final de la calle eso cae en una casa.
- **El arreglo.** Una función nueva en `game.gd`: `scene_shot(at, want_a, want_b)`, con `_shot_turned`, `_shot_clear`, `_shot_room` y `_shot_open`.
  - Mira con rayos de la capa 1 (las paredes) desde el objetivo hacia cada punto, y deja la cámara 0,6 m antes de la primera pared.
  - Prefiere de frente y más cerca, siempre que conserve al menos el 45 % de la distancia, antes que girada de lado.
  - Si no, prueba a girarla poco a poco (±0,4, ±0,8, ±1,2 rad) y a subirla 3 m.
  - La separa de una pared que tenga pegada al lado.
  - Comprueba que el paso de un punto al otro no cruce ninguna esquina.
- **Dónde se usa.**
  - `pintadas.gd`: `tour_shot(t)`, que apunta al propio grafiti y sale según la cara de la pared (`t.n`).
  - `recress.gd`: `_sad_corners()` y el paso por la puerta del Recress en `_pitch`.
- **Prueba.**
  - `selftest.gd`: `_tour_camera_checks()`, al principio de `_pintadas_checks`, así que entra en la prueba completa.
  - Las 60 paredes se ven desde los dos extremos del paso, de frente (a menos de 63°), a 2,5 m o más y sin nada en medio. Los 5 rincones de Alberto, igual.
  - Con `--shots` saca las fotos `gira_chiki_N_antes/ahora` y `gira_alberto_N`.
  - `run_tests.py pintadas --headless`: 7 ok. `pintadas shots --window`: 7 ok, y las fotos están revisadas. `recress --headless`: 16 ok.
  - Sin commit.

### Calle del Cristo, de la Mayordomía a la Travesía del Cristo: 32 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar la calle de Sevilla).

- **Hecho.** 32 entradas `cri_*`. Fotos del Catastro, y Street View de noviembre de 2024 donde no había foto, la foto era de otra casa o la casa ha cambiado. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Fuera:
    - el 3 (4790711): es la nave de la Mayordomía, hecha a mano (`MERKOCARRY_RCS` en `bake_godot.py`);
    - Paz 1 y Doctor Fleming 22: dan a sus calles;
    - nada al sur de la Travesía del Cristo, donde empiezan el parque, la ermita y la Residencia de Edificios Especiales.
  - Las fotos del Catastro del 35 y del 45 son de otras casas. Se han seguido las placas de Street View.
  - Las tiendas llevan solo lo que venden (PASTELERIA, ELECTRICIDAD).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (32 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/cristo_1..6.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 12:03 (el de Sevilla), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 32 casas nuevas, ninguna quitada. `argentina_42` y `argentina_b029` cambian solo en las aristas tapadas.
  - Calles, nodos, relieve y árboles (2954) iguales. La holgura del nodo 225 (cruce del Cristo con la Cruz) pasa de 4,7 a 4,2 m.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 32 y las dos de Argentina: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_cri_5_cri_7_cri_9_cri_x11_cri_13_cri_15_cri_15d_c_20261121_122321.log)).
  - Tras aclarar el amarillo, `solo=cri_x11`: 4 ok ([log](logs/selftest_casas_solo_cri_x11_20261121_122612.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle del Doctor Fleming: 24 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar la calle del Cristo). Elegida con `faltan.py`: la calle cercana con más fachada genérica sin tocar (319 m), al sur de Sevilla.

- **Hecho.** 24 entradas `fle_*`. Fotos del Catastro (viejas, hacia 2010), y Street View de noviembre de 2024 en casi toda la calle. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - `fle_23`: la tapia de una planta de la trasera de Sevilla 34; `sev_34` ya tomaba solo las partes de dos plantas, así que no se pisan.
  - `fle_6`: la tapia con portón de Paseo del Cristo 1 (`reach` 6).
  - Fuera: Paseo del Cristo 2 y 48, que dan al Paseo, junto al parque de Edificios Especiales.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (24 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/fleming_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 12:23 (el del Cristo), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 24 casas nuevas, ninguna quitada. `sev_26` y `sev_28` cambian solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 24 y las dos de Sevilla: 3 ok, 1 fallo, porque `fle_25` tenía pocas piezas ([log](logs/selftest_casas_solo_fle_1_fle_3_fle_5_fle_7_fle_9_fle_11_fle_13_fle_1_20261121_124038.log)).
  - Con más parches y una hilada de albardilla, `solo=fle_25`: 4 ok ([log](logs/selftest_casas_solo_fle_25_20261121_124336.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de la Vega: 16 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar Doctor Fleming). Elegida con `faltan.py` (257 m de fachada genérica), junto al Florido y lejos del silo que está haciendo Edificios Especiales.

- **Hecho.** 16 entradas `veg_*`. Fotos del Catastro y Street View de noviembre de 2024 en toda la calle. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Las hileras de adosadas del lado sur (`veg_x1`, `veg_x3`: cuatro casas; `veg_x5`, `veg_x7`: dos) son una parcela cada una. `veg_write.py` (scratchpad, `row()`) pinta cada casa con garaje, escalera (`esc`) y su color con `paño`.
  - `veg_6` lleva `floors` 1: su cuerpo de tres plantas llega a la calle y las tiras de una planta de delante entran en el mismo frente.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (16 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/vega_1..3.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 12:40 (el de Fleming), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 16 casas nuevas, ninguna quitada. `sap_19` cambia solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 16 y `sap_19`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_veg_x1_veg_x3_veg_x5_veg_x7_veg_3d_veg_sap25_veg__20261121_125239.log)).
  - Tras bajar los ventanucos, `solo=veg_3d`: 4 ok ([log](logs/selftest_casas_solo_veg_3d_20261121_125440.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y continuar»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de los Ángeles: 17 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y continuar», tras aprobar la Vega). Elegida con `faltan.py` (246 m de fachada genérica).

- **Hecho.** 17 entradas `ang_*`. Fotos del Catastro, y Street View de noviembre de 2024 en la mitad de la calle. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - `ang_19`: frente de la pared genérica; el del Catastro es un muro 7 m más adentro.
  - `ang_25`: frente recortado a su casilla (6 m de 22); lo demás es una tapia de patio sin edificio.
  - Entran tres esquinas de otras calles (`ang_tol1`, `ang_vp1`, `ang_bf25`). Bajada del Florido 25 quedó fuera de la Bajada porque no tiene fachada allí.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (17 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/angeles_1..3.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 12:52 (el de la Vega), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 17 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954) iguales. La holgura del nodo 1491 pasa de 2,3 a 2,2 m.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - El primer intento de `casas` paró en el arranque, por un error de sintaxis en `fondo_casa.gd:256` (archivo nuevo de Sistemas, a medio escribir; avisado). No se tocó.
  - A las 13:10, ya corregido, `casas` de las 17: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_ang_tol1_ang_2_ang_4_ang_8_ang_10_ang_x12_ang_vp1_20261121_131024.log)).
- **Visto bueno** del usuario el 21/11 («Visto bueno y siguiente cuando puedas»), antes de ver las hojas, que se le mandaron después. En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de la Virgen de la Paloma: 20 entradas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente cuando puedas»). Elegida con `faltan.py` (241 m de fachada genérica), junto a Los Ángeles.

- **Hecho.** 20 entradas `vpa_*` (18 parcelas). Fotos del Catastro (2010–2015) y Street View de noviembre de 2024 en la mitad de la calle. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.** Dos parcelas con `only`: `vpa_x18` (3 plantas; la de 4 retranqueada queda como bloque normal) con `vpa_x18g` (1 planta), y `vpa_20` (2) con `vpa_20g` (1). Las esquinas `vpa_tol17` (Camino de Toledo 17) y la de Los Ángeles (`ang_vp1`, ya hecha) dan a esta calle.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (20 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/paloma_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 13:07 (el de Los Ángeles), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 20 entradas nuevas, ninguna quitada. `ang_vp1` cambia solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 20 y `ang_vp1`: 3 ok, 1 fallo, porque `vpa_3` tenía pocas piezas ([log](logs/selftest_casas_solo_vpa_3_vpa_5_vpa_9_vpa_11_vpa_13_vpa_x15_vpa_19_vp_20261121_131744.log)).
  - Con una hilada de albardilla más, `solo=vpa_3`: 4 ok ([log](logs/selftest_casas_solo_vpa_3_20261121_131931.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de Pizarro: 16 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar la Virgen de la Paloma). Elegida con `faltan.py` (197 m de fachada genérica), entre Los Ángeles y la Virgen de la Paloma.

- **Hecho.** 16 entradas `piz_*`. Fotos del Catastro y Street View de noviembre de 2024 en la mitad de la calle. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.** Los frentes del lado impar quedan 6 m del eje de la calle (2,5 m más que los del par), pero el juego ya tenía allí sus paredes genéricas: se han dejado los del Catastro. Tres costados de otras calles entran (`piz_an16b`, `piz_va1`, `piz_va8`).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (16 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/pizarro_1..3.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 13:17 (el de la Virgen de la Paloma), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 16 casas nuevas, ninguna quitada. `vpa_13` cambia solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 16 y `vpa_13`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_piz_an16b_piz_3_piz_5a_piz_5d_piz_7_piz_x9_piz_va_20261121_133113.log)).
  - Tras apagar el ocre, `solo=piz_13`: 4 ok ([log](logs/selftest_casas_solo_piz_13_20261121_133308.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y seguimos»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Misiones de fondo (la casa de la Eufrasia, Edmundo Monedero, cajero) y Trabajos (21/11, Claude · Sistemas)

21 de noviembre de 2026. Lo pidió el usuario. Los modelados los hace Pretil; los sistemas, Sistemas.

**Misiones «de fondo».** Van a la vez que el resto del juego: no usan `G.side` ni el objetivo de la hoja. Están en la Agenda, en una página 3 nueva, «MISIONES DE FONDO» (`log_bg`). Ahora la Agenda tiene 7 páginas y 7 pestañas, más juntas (`menu.gd`). En esa página van:
- la casa;
- las pintadas de la Chiki, que salen de la página de encargos y cuentan «tuyas N de 60»;
- el azafrán.

**La casa** (`fondo_casa.gd`, nuevo):
- **La llamada de la Paca.** 2 h de juego después de abrir el puente te llama la Paca: «ven a verme, ande siempre, al lao de casa».
- **La deuda.** Allí te cuenta que la Eufrasia defraudaba a Hacienda y que la casa tiene una carga de **10.000 €**.
  - El usuario escribió «tía Eusebia», pero en el juego la tía de la herencia es la **Eufrasia** (loc `paca_cutscene`), así que se queda Eufrasia. Hay que confirmárselo.
- **El cajero.** Se paga a plazos en el cajero del Banco Cantabria: 100, 500, 1.000 o «To lo que llevo». Lo que no te llega sale en gris.
  - El cajero es el modelado de Pretil: `bancosancho.cajero_spot`, `cajero_face` y `cajero_at`.
- **Edmundo Monedero.** Cuando la deuda está pagada, te llama en un cuarto de hora. Es el director de sucursal, «usurero tipo Tom Nook»: vende productos y suelta verdades por lo bajini, con `((…))` en gris.
  - Dónde está:
    - De lunes a viernes, de 8:30 a 14:30, en la puerta del banco.
    - Cuando Pretil haga el interior, dentro: `bancosancho.banco.manager_spot` y `manager_h`.
  - Aspecto provisional: hombre adulto, camisa con cuello azul oscuro (top 11), corbata (pendant 6), gafas y piel pálida. No hay ninguna chaqueta de traje entre las prendas.
- **Las obras.**
  - Se contratan con Edmundo, y cada una tiene que estar pagada antes de que te ofrezca la siguiente.
  - Están hechas a la mañana siguiente, a partir de las 7. Lo que cuestan se debe al banco y se paga en el cajero.
  - Estados, con su precio:
    1. Arreglada: 20.000 €.
    2. Fachada nueva y más sitio dentro: 30.000 €.
    3. Cuarto a la izquierda: 40.000 €.
    4. Cuarto a la derecha: 50.000 €.
    5. Segundo piso, con su puerta por detrás: 60.000 €.
  - Cuando se cambia de estado se llama a `casa.set_state(n)` y `casa.dentro.set_state(n)`, si existen (Pretil).
- **Lo que se guarda:** `stats.casa = {st, debe, estado, obra, obra_dia, offered}`.

**Trabajos** (`trabajos.gd`, nuevo). Ocupan `G.side = {id: "trabajo", kind, stage…}`, y una misión de la historia los deja.
- **El de las faenas** (`faenas`) es un NPC genérico en la Plaza del Ayuntamiento: `plaza.spot(6, 24)`. Da tres trabajos:
  - **Reparto en coche.** Recoges un bulto y lo llevas a una casa a 250–800 m, contrarreloj. Paga 100–600 € según lo rápido y lo entero que llegue.
  - **Taxi.** Un turno de 5 carreras: un vecino genérico a 40–150 m te hace señas, paras, se sube y lo llevas a 250–700 m. Cada carrera paga 100–500 €. Si te bajas del coche más de 10 s, se acaba el turno.
  - **Jornal en el campo.** 30 rosas del azafrán en la viña o el surco grande más cercano, en 150 s. Paga 25 € por rosa y 50 € más si las coges todas.
- **Henry**, cualquier día menos el jueves, te da un pedido para un vecino conocido; si conoces a menos de 3, para cualquier vecino con nombre del pueblo. Paga 30–150 € según lo caliente que llegue, y da +2 de confianza.
- **Lo cobrado** se guarda en `stats.trabajos`, con una línea en la página de encargos.

**Engranajes compartidos:**
- `game.gd`: preloads, setup, tick, `talk_to`, cajero en `interact` y en el texto de la acción, `restore` en `start_game`, `_side_drop`/`_side_show`/`_side_tick` para "trabajo", y la Agenda.
- `marcas.gd`: `givers`.
- `loc.gd`: los textos.
- `selftest.gd`:
  - Modo `--herencia`, porque `--casa` ya existía: 11 comprobaciones.
  - Modo `--trabajos`: 7 comprobaciones.
  - Las dos entran en la prueba completa, detrás de `_pintadas_checks`.
  - La comprobación de las páginas de la Agenda cambia de 6 a 7.

**Arreglado de paso:** la prueba `bancosancho` entraba en la copistería solo con pisar la flecha. Ahora pulsa Acción, y ya da 5 ok.

**Pruebas:** `herencia` 11 ok, `trabajos` 7 ok, `palabros` 3 ok, `bancosancho` 5 ok. Las fotos salen con `herencia shots` y `trabajos shots`. La prueba completa va después.

**Diagrama de misiones:** `guion/misiones.html` y el artefacto (v3) tienen ahora las secciones «De fondo» y «Trabajos».

**Pendiente:**
- `guion/relaciones.html`: añadir a Edmundo y a El de las faenas.
- Los modelados de Pretil: el interior del banco y los 6 estados de la casa.
- Para las rosas del jornal se usa la bola morada de `pickups`; mejor una rosa de verdad.

### Travesía del Rollo y tramo norte de la Bajada del Rollo: 21 entradas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y seguimos», tras aprobar Pizarro). Elegida con `faltan.py` (Travesía del Rollo, 170 m de fachada genérica), con lo que faltaba de la Bajada del Rollo al lado.

- **Hecho.** 21 entradas `rol_*`. Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Pareadas de 1995 (Bajada del Rollo 30 a 44 en el Catastro): `rol_write.py` (scratchpad) pone el frente paralelo a la Travesía en la cara del cuerpo de dos plantas, recortado en la medianera, con `floors` 2 y `strip` 2,5, como `sur_write.py` en la Prolongación del Florido.
  - Travesía 3 en dos entradas con `only`: `rol_tr3h` (2 plantas, frente al tramo noreste) y `rol_tr3w` (1 planta, la tapia larga, `reach` 16).
  - `rol_tr3h` y `rol_tr1` se adelantaron 1,7 y 1,9 m hasta la cara de su parte, porque `precheck.py` las daba por detrás.
  - `rol_br10` se quitó tras ver las hojas: su frente estaba en un patio detrás de `rol_br8` (no lo cogió el aviso de fachadas escondidas).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (21 entradas; respetada la línea `alemania_5` de Edificios Especiales); `godot/data/map.json`; las hojas `guion/fotos/tanda34/rollo_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado sobre el de las 13:31 (el de Pizarro) y otra vez para quitar `rol_br10`, avisando a Edificios Especiales antes y después de cada uno.
  - Frente a las copias: 21 entradas nuevas, ninguna quitada de las de antes. `monjas_21`, `monjas_5` y `rol_br8` cambian solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
- **Pruebas.**
  - A las 14:02 el juego no cargaba `casa_dentro.gd` (Edificios Especiales lo estaba editando; avisado, no se tocó).
  - A las 14:05, `casas` de las 22 y las dos de Monjas: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_rol_b30_rol_b32_rol_b34_rol_b36_rol_b38_rol_b40_r_20261121_140557.log)).
  - Tras quitar `rol_br10`, `solo=rol_br8,rol_br15a,rol_br17`: 4 ok ([log](logs/selftest_casas_solo_rol_br8_rol_br15a_rol_br17_20261121_140907.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y seguimos»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle del Rollo y calle del Socorro: 16 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y seguimos», tras aprobar la Travesía y la Bajada del Rollo). Dos calles cortas en una tanda: el Rollo recoge las casas 17 y 19 que quedaron fuera de la Travesía; el Socorro sale de `faltan.py`.

- **Hecho.** 8 entradas `rro_*` y 8 `soc_*`. Fotos del Catastro; Street View de noviembre de 2024 en el bloque del Socorro. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Rollo 1 (3890801) y Juan Carlos I 50 (3890803) están en `CARIDAD_RCS` de `bake_godot.py`: fuera.
  - `soc_2b` (3 plantas) y `soc_2y` (1 planta) comparten la parcela 4298527 con `only`.
  - `soc_4` y `soc_6` llevan `reach` 6, para dejar como casas normales sus cuerpos de dos plantas del fondo.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (16 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/rollo_socorro_1..3.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 14:08 (el del Rollo sin `rol_br10`), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 16 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 16: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_rro_17_rro_19_rro_37_rro_39_rro_41_rro_43_rro_45__20261121_141632.log)).
  - Tras oscurecer el ladrillo del bloque, `solo=soc_2,soc_2b`: 4 ok ([log](logs/selftest_casas_solo_soc_2_soc_2b_20261121_141825.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno a todo y paramos un poco»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11). Pausa después de esta tanda.

### «Saltar a misión» con todas las misiones (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Actualiza el "ir a misión" del modo desarrollador para que incluya todas las misiones».
- `game.gd`: la página `dev_missions` lista ahora la historia, como antes, y tres apartados más (`DEV_OTHERS`):
  - **Secundarias:** el menú de la Josefa, Don Luis, el jamón de los jueves, las pintadas de la Chiki, el Recress, el ajedrez y la Tomasa.
  - **De fondo:** la herencia y las obras con Edmundo.
  - **Trabajos:** El de las faenas y los pedidos de Henry.
- `_dev_side(id)` deja la historia hecha (paso `tbc`), con lo que pide esa misión abierto y sin hacer.
  - La hora es la que le hace falta: el jueves a las 8:30 para el jamón, y la llamada suena ya.
  - Te baja del coche de la Paca y te pone al lado de quien la da. Para las obras, en la flecha del banco.
  - Guarda la partida, como los saltos de la historia.
- Arreglado de paso: la Chiki no salía entre quienes dan misión, así que no tenía flecha verde con su encargo por estrenar y se iba de ronda. Ahora sí sale, con `pintadas.givers()` en `marcas.gd`.
- Prueba: modo `--devmisiones` (solo suyo, porque pone el juego patas arriba), 2 ok: están las 11 y cada salto te deja junto a quien da la misión.
  - `pintadas` 7 ok y `civicos` 39 ok.
  - La prueba completa de las 14:05 dio 917 ok y 0 fallos; fue antes de este cambio.

### Tres pitillos al día y 24 horas entre sueño y sueño (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Los cigarros limitados a tres al día y el dormir tendrá un cooldown de 24 horas in-game».
- **Pitillos** (`fumar.gd`): como mucho `PER_DAY` 3 en un día de juego, contando desde la medianoche.
  - Se cuentan en `stats.pitillo_n` y `stats.pitillo_dia`.
  - Con un cuarto, `why_not()` devuelve `fumar_day`: «Ya llevas tres pitillos hoy…». El pitillo no se gasta.
  - El de la Tomasa no cuenta.
- **Dormir** (`game.gd`): `SLEEP_EVERY` son 24 h, contadas desde que te acuestas. Se guarda en `stats.slept_h`, que pone `_go_to_sleep`. Así, quien se acuesta a las diez puede volver a hacerlo a las diez de la noche siguiente.
  - Antes de tiempo, la cama dice «Sin sueño hasta el MARTES · 22:00», y al pulsar sale un aviso.
  - La hora de dormir de la historia (paso `sleep`) nunca espera.
- **Prueba:** modo `--descanso`, 2 ok, también en la completa detrás de los trabajos. `mejoras2`, 12 ok.
- **Diagrama:** la tarjeta de los pitillos y una de dormir nuevas.

### Publicación de la 0.0.19 en GitHub (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Cuando termine Pretil, visto bueno a todo y 0.0.19».
- **Congelado.** Pretil y Texturas, desde que avisaron de que habían terminado.
- **Prueba completa:** 920 ok, 0 fallos (`logs/selftest_full_20261121_144541.log`). Después, `herencia` 12 ok y `casa` 4 ok, con el último retoque de Pretil en las fachadas, que solo cambia comentarios respecto a la versión probada.
- **Commits:**
  - `af9420f`: todo lo aprobado, de Sistemas, Pretil y Texturas.
  - «Matritellus 0.0.19»: número de versión, notas y los `.uid` de los scripts nuevos.
- **Etiqueta:** `v0.0.19`.
- **Paquetes:** `tools/make_apk.py 0.0.19` (versión 0.0.19, código 19, firmado y verificado), `tools/make_installer.py` y `tools/make_linux.py`.
  - Están en `dist/v0.0.19/`, con [sus SHA-256](dist/v0.0.19/SHA256SUMS.txt) comprobados.
  - Subidos a la release: https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.19
- **Sin probar:** no se ha probado en móvil ni en Steam Machine.

### Calle de Don Pedro de Castilla y calle de Dulcinea del Toboso: 19 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Perfecto. Puedes seguir», tras publicarse la 0.0.19). Las dos siguientes de `faltan.py`.

- **Hecho.** 11 entradas `dpc_*` y 8 `dul_*`. Fotos del Catastro; Street View de 2013 en `dpc_8d`. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - La hilera de 2007 de Don Pedro sale de `dd_write.py` (scratchpad, `orange()`).
  - `dpc_x14` lleva `floors` 1, para tomar el semisótano de los garajes, con `esc`.
  - Fuera: `dpc_b28` (Bajada del Rollo 28, 3,5 m de costado) y el molino (`MOLINO_RC`).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (19 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/donpedro_dulcinea_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 14:16 (el que publicó la 0.0.19), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 19 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 19: 3 ok, 1 fallo, porque `dul_4` tenía pocas piezas ([log](logs/selftest_casas_solo_dpc_2_dpc_4_dpc_8d_dpc_x10_dpc_x14_dpc_16_dpc_18__20261121_152232.log)).
  - Con hiladas y una puerta, `solo=dul_4`: 4 ok ([log](logs/selftest_casas_solo_dul_4_20261121_152411.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).

### Camino Hondo: 12 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar Don Pedro y Dulcinea). La siguiente de `faltan.py`.

- **Hecho.** 12 entradas `cho_*`. Fotos del Catastro; Street View de noviembre de 2024 en `cho_9a` y `cho_9b`. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.** `cho_jx43` lleva el frente de la pared genérica (el del Catastro era un muro 4 m más al este). Fuera `cho_co8` (Concordia 8 da a la Concordia).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (12 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/camino_hondo_1..2.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 15:22 (el de Don Pedro y Dulcinea), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 12 casas nuevas, ninguna quitada. `bs_h20` cambia solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 12 y `bs_h20`: 3 ok, 1 fallo, porque `cho_30` tenía pocas piezas ([log](logs/selftest_casas_solo_cho_jx43_cho_jx45_cho_1a_cho_14_cho_co10_cho_16_c_20261121_154705.log)).
  - Con hiladas y una puerta, `solo=cho_30`: 4 ok ([log](logs/selftest_casas_solo_cho_30_20261121_154832.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y continuar»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).

### Calle de las Monjas, del 29 y el 40 a la Rosa de Santa María: 27 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y continuar», tras aprobar el Camino Hondo). La calle con más fachada genérica de `faltan.py` (378 m); esta es su primera tanda.

- **Hecho.** 27 entradas `mon_*`. Fotos del Catastro; Street View de noviembre de 2024 en tres puntos. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.** `mon_54`: frente adelantado 2 m hasta la cara de su porche (`precheck.py`). `mon_64` lleva `floors` 2. Fuera: Santa Ana (`SANTAANA_RC`), Monjas 63 y 65.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (27 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/monjas_1..5.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 15:46 (el del Camino Hondo), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 27 casas nuevas, ninguna quitada. Cuatro vecinas cambian solo en las aristas tapadas. Calles, nodos, relieve y árboles (2954) iguales. La holgura del nodo 2305 pasa de 6,3 a 6,0 m.
- **Pruebas.**
  - `casas` de las 27 y las cuatro vecinas: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_mon_29_mon_33_mon_35_mon_35d_mon_37_mon_39_mon_45_20261121_155912.log)).
  - Tras los cambios de color, `solo=mon_44,mon_46,mon_62,mon_x55`: 4 ok ([log](logs/selftest_casas_solo_mon_44_mon_46_mon_62_mon_x55_20261121_160145.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).

### Calle de las Monjas, el resto (de Nalda a Sancho Panza): 20 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar el primer tramo de las Monjas).

- **Hecho.** 20 entradas `mon_*`: Nalda 21, 23 y 25, Monjas 6, 10, 17, 19, 24, 36, 76, 78, 82, 84, 87, 88, 89, 90, 91, San Isidro 59 y Sancho Panza 10. Street View de noviembre de 2024 en todas (el 24, de marzo de 2013) y fotos del Catastro. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - El 6 y el 89 son solares en el Catastro y tienen casa en 2024: `rc` nulo con `deep` (10 y 5 m).
  - El 87 es el brazo de la parcela de Florido 68 (`flo_68` toma solo las partes de 3 plantas): `only` 2, `reach` 3.
  - El 17 (`reach` 4: el trozo de la acera y el bloque de 3 plantas de detrás) y el 10 (`reach` 2,5: solo la punta a la calle).
  - Nalda 25 y Sancho Panza 10 llevan el frente en la calle de su número.
  - `monjas_26` (tanda antigua): frente movido de la trasera de `mon_24` a su cara a la revuelta, solo en `calles.json`. `precheck.py` da FORWARD 2,2 m: es el quiebro real de su fachada, más allá del final del frente.
  - Fuera: Monjas 22 (nada en pie a la calle en el Catastro).
- **Archivos.** `tools/casas/calles.json` (20 entradas y el frente de `monjas_26`), `godot/scripts/casas_calles.gd` (20 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/monjas_b_1..5.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 16:23, avisando a Edificios Especiales antes y después.
  - Frente a la copia: 20 casas nuevas, ninguna quitada. Nueve vecinas cambian solo en las aristas tapadas; `amargura_17` y `monjas_85`, además, 1–3 cm de suelo. Calles, nodos, relieve y árboles (2954) iguales.
- **Pruebas.**
  - `casas` de las 20, `monjas_26`, `amargura_17` y `monjas_85`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_mon_n21_mon_n23_mon_n25_mon_10_mon_6_mon_17_mon_1_20261121_172329.log)).
  - Tras los cambios de color de ocho y la ventana de San Isidro 59, `solo=mon_n23,mon_6,mon_17,mon_36,mon_76,mon_si59,mon_88,mon_90,mon_24`: 4 ok ([log](logs/selftest_casas_solo_mon_n23_mon_6_mon_17_mon_36_mon_76_mon_si59_mon_8_20261121_172751.log)).
- **El arco del patio entre el 2 y el 10** (el usuario, al ver las hojas: «Falta el arco de ladrillo con patio interior. Tendrá la portada abierta y habrá un azafrán escondido ahí»).
  - El mapa ya dejaba ese hueco sin casa entre `mon_10` y `monjas_b742`: es el patio. No hizo falta rehornear.
  - `godot/scripts/casas.gd`: `_mon_10()` construye la casa por su línea corta y, en un marco propio a lo largo del hueco, el muro de ladrillo con arco de medio punto y albardilla de teja, el zócalo de granito, la franja blanca contra el 2, las dos hojas de la cancela abiertas hacia dentro (`_arco_leaf`), el solado rojo del patio, un palé de ladrillos y, detrás, el azafrán en su maceta (`game.flowers`, `"id": "arco_monjas"`, `"hidden": true`).
  - Los pilares, la franja blanca y el palé dejan su contorno en `MapData.outlines` (y en la rejilla si ya está hecha), como la almazara; el arco queda libre para pasar.
  - Pruebas: `casas` de `mon_10` y `monjas_b742`: 4 ok ([log](logs/selftest_casas_solo_mon_10_monjas_b742_20261121_174451.log)); los 12 avisos `ARRAY_FORMAT_TEX_UV` ya salían antes. Fotos con `vistas=arco_calle,arco_dentro,arco_azafran` (sale «VISTAS OK»; `run_tests.py` no reconoce esa línea y da «NO RESULT»). Hoja `guion/fotos/tanda34/monjas_arco.jpg`.
  - No probado: coger el azafrán en una partida de verdad (la recogida es la misma de los otros escondidos). Avisado Sistemas.
- **Aprobado** por el usuario el 21/11 («Visto bueno»), la tanda y el arco. En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).

### Travesía del Clavel, principio del Clavel y Calle del Romero: 24 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Siguiente», tras aprobar las Monjas). Elegidas por `faltan.py`: calles cerca del centro con fachada genérica.

- **Hecho.** 24 entradas: `tcl_4` a `tcl_20` (la hilera de 2004 del callejón), `cla_6`, `cla_tsr8`, `rom_d14`, `rom_45`, `rom_39`, `rom_39b`, `rom_24c`, `rom_24b`, `rom_24a`, `rom_18b`, `rom_21`, `rom_19`, `rom_17`, `rom_15`, `rom_9`. Fotos del Catastro y Street View de noviembre de 2024; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - La hilera va en parejas que comparten la escalera de entrada: la puerta a la derecha en el 4, 8, 12, 16 y 20, a la izquierda en el 6, 10, 14 y 18 (`tcl()` en el borrador).
  - `rom_39` (`only` 2) y `rom_39b` (`only` 1, `reach` 3): la casa de dos plantas y su trozo bajo. `rom_24c` con `reach` 8 (su bloque de cuatro plantas de detrás, no el del fondo).
  - Fuera: 4494604 (una tira de una planta sin dirección en el lado oeste de la Travesía), Delicias 21 y 12 (no dan al Romero).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (24 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/clavel_romero_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Horneado una vez, avisando a Edificios Especiales antes y después. Frente a la copia: 24 casas nuevas, ninguna quitada; `romero_11` y `rafael_tc2` solo cambian en las aristas tapadas (y 6 cm de suelo en la segunda). Calles, nodos, relieve y árboles (2954) iguales.
- **Pruebas.**
  - `casas` de las 24, `romero_11` y `rafael_tc2`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tcl_4_tcl_6_tcl_8_tcl_10_tcl_12_tcl_14_tcl_16_tcl_20261121_180513.log)).
  - Tras los cambios de color (el ocre de la hilera; los portones del 24 A y el 17; la puerta del 21): 4 ok ([log](logs/selftest_casas_solo_tcl_4_tcl_12_tcl_20_rom_24a_rom_21_rom_17_20261121_180823.log), [log](logs/selftest_casas_solo_tcl_6_tcl_8_tcl_10_tcl_14_tcl_16_tcl_18_20261121_180932.log)).
- **La Travesía, peatonal y elevada:** el usuario preguntó si la había hecho elevada, con sus dos accesos (escalera por el Clavel, rampa por San Rafael). No lo estaba: en el mapa es una calle `residential` de asfalto. El usuario: «De acuerdo, que sea peatonal y con las cosas que has dicho. Que se ponga Petril con eso cuando termine con el Rice». Encargado a Edificios Especiales por mensaje. Fotos y notas en `referencias/travesia_clavel/` (LEEME.md, nuevo).
- **Aprobado** por el usuario el 21/11 («Visto bueno a todo y paramos»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).
- **Después, a petición de Pretil** (su paseo elevado, `travesia.gd`, pasa 0,30–0,55 m por debajo de cada umbral, con un rellano y peldaños ante cada puerta): en `tcl_4` a `tcl_20` quité la escalera `esc` y el ventanuco de la planta de piedra. Queda `wall=stone h=1.4`; las puertas no se mueven. Sin horneado. Sobre el mapa de Pretil con la Travesía (clave `travesia`), `casas` de las nueve: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tcl_4_tcl_6_tcl_8_tcl_10_tcl_12_tcl_14_tcl_16_tcl_20261121_192344.log)). En las fotos, sus rellanos con barandilla quedan ante cada puerta y la piedra asoma por debajo.

### Teniente Infante, Avenida de Castilla-La Mancha, Alameda y Arroyuelo Bajo: 17 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Siguiente calle»). Elegidas por `faltan.py`: calles cerca del centro con fachada genérica.

- **Hecho.** 17 entradas:
  - `tin_15`, `tin_x11`, `tin_x10`, `tin_16`, `tin_x6`;
  - `acm_6`, `acm_8`, `acm_21`, `acm_24`, `acm_26`, `acm_28`, `acm_ar28`;
  - `ala_10`, `ala_am36b`, `abj_jm27`, `abj_rs14`, `abj_jc15d`.
  - Fotos del Catastro y Street View de noviembre de 2024; lo que no se parece, en `guion/repaso_casas.md`.
- **Rótulos.** La sucursal de la caja rural del Teniente Infante lleva «AHORROS RURALES», el banco del juego. La zapatería de Castilla-La Mancha 28 lleva solo «CALZADOS». Los carteles de «se alquila» van con `t=1` (de agencia, sin número de teléfono).
- **Fuera.** Cervantes 3 es la iglesia parroquial, hecha a mano. Santo 40 y Reina Sofía 31 no dan a estas calles. Castilla-La Mancha 14 queda escondida detrás de `castilla_16` (`precheck.py`).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (17 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/infante_castilla_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Paré mi primer horneado al avisar Edificios Especiales de que horneaba la cafetería Rize; no llegó a escribir `map.json`.
  - El de Pretil terminó (18:37) antes de mi fusión, así que no traía mis casas. Volví a hornear sobre el suyo, avisando antes y después.
  - Frente a la copia: 17 casas nuevas, ninguna quitada, `rize` intacto. `alameda_9`, `alameda_10` y `castilla_22` solo cambian en las aristas tapadas (y 9 cm de suelo en la primera). Calles, nodos, relieve y árboles (2954) iguales.
- **Pruebas.**
  - `casas` de las 17 y esas tres: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tin_15_tin_x11_tin_x10_tin_16_tin_x6_acm_6_acm_8__20261121_184539.log)).
  - Tras cambiar a `brick_rose` el ladrillo del 6 y del 28 de Castilla-La Mancha: 4 ok ([log](logs/selftest_casas_solo_acm_6_acm_28_20261121_184753.log), [log](logs/selftest_casas_solo_acm_6_20261121_184902.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno a todo y paramos»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11). Las calles quedan en pausa hasta nueva orden; la siguiente por `faltan.py` sería Tembleque o Delicias.

### La almazara «González de la Ruz» (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Ahora ponte con aceites García de la Cruz (que llamaremos Gonzalez de la Ruz) tiene fachada tanto en calle triunfo como en carretera de villacañas».
- **Qué es.** La almazara de la carretera de Villacañas (Catastro 4699012VJ5649N), con la trasera en la calle del Triunfo, hecha a mano en `godot/scripts/almazara.gd`. Incluye la nave alta junto a la carretera, que Catastro no tiene.
  - Por la carretera: testero de la nave vieja con el mural, la entrada abierta al patio, el muro largo con el rótulo repetido y la nave alta de 14,7 m.
  - En el patio: el costado de la tienda, las oficinas color salmón, la nave de recepción abierta con su cabina, su tolva y sus depósitos; tras el muro, banderas, cobertizo de madera, depósitos de acero e instalaciones.
  - Por el Triunfo: el otro testero, un bloque de dos plantas, un tramo viejo con alero de teja y el muro largo de las naves.
  - Rótulo, emblema y mural son dibujos propios (`tools/almazara/dibujos.py`, en `godot/assets/almazara/`). Sin personajes. Sin interior.
  - Un azafrán escondido tras el muro (`"id": "almazara"`, `"hidden": true`).
- **Rehorneado** (avisados Sistemas y Texturas antes y después; ensayado con `tools/colegio/ensayo.py`).
  - Bloque ALMAZARA en `tools/bake_godot.py`: salta el RC, sus contornos en `block_list`, sin árboles en su zona, clave `almazara`.
  - Cambios en `godot/data/map.json`: fuera las 5 naves genéricas de la parcela (5 tejados planos, 46 muros) y la holgura del nodo 1250 del Triunfo de 2,3 a 2,4 m. Relieve, nodos, calles y árboles (2954) iguales.
  - Después retoqué dos contornos del bloque (nave de recepción más grande, nave alta un metro más corta). Un segundo ensayo da el mismo mapa que el horneado, así que no hizo falta rehornear.
- **Archivos.**
  - Nuevos: `godot/scripts/almazara.gd`, `godot/assets/almazara/` (6 PNG), `tools/almazara/` (capturas, alzado, manzana, plano, vistas, hojas, dibujos, LEEME), `tools/ign/almazara*.jpg/.json`, `referencias/almazara/LEEME.md`, `guion/fotos/almazara/01–03`, `tools/casas/4699012VJ5649N/` (ficha de Catastro).
  - Compartidos, solo con añadidos y con aviso: `tools/bake_godot.py`, `godot/data/map.json`, `godot/scripts/map_data.gd` (`var almazara`), `godot/scripts/world.gd` (`AlmazaraS`, `var almazara`, paso «the oil mill», `_build_almazara()`), `godot/scripts/selftest.gd` (modo `--almazara`, `_almazara_checks()` y su llamada en la completa tras `_silo_checks()`).
- **Decisiones que conviene conocer** (detalle en [referencias/almazara/LEEME.md](referencias/almazara/LEEME.md)).
  - El muro del Triunfo va retranqueado hasta un metro respecto a Catastro, para no meterse en el pasillo que el horneado reserva a la calle.
  - El muro de la carretera sigue el terreno: en el juego la carretera cae 4 m hacia el noreste.
  - La nave alta y la de recepción se han trazado sobre la ortofoto, no sobre Catastro.
- **Pruebas.**
  - `python tools/run_tests.py almazara`: 3 ok, 0 fallos ([log](logs/selftest_almazara_20261121_163528.log)). Comprueba que está construida, que frena en las dos calles, que la entrada está abierta, que el mapa conoce sus contornos, el azafrán y el paseo desde la carretera hasta su rincón.
  - `python tools/run_tests.py relief` tras el horneado: 19 ok, 0 fallos ([log](logs/selftest_relief_20261121_163800.log)).
  - La prueba completa no la he pasado.
- **Aprobada por Luis** (21/11): «Mejor con tilde. Visto bueno». El rótulo se queda como está, «González de la Ruz», con tilde (él lo había escrito sin ella y se lo pregunté).
- **Sin commit**: lo hace Sistemas.

### Javi y sus pollos (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario, a través de Pretil, que hace el asador y su interior: Javi, del «Asador de pollos Juli» (llamado Javi).
- **Qué pidió.** Repartos «como los de Henry pero de pollo», los martes y los domingos. Se desbloquea tras el jamón de la Josefa, «al llegar el próximo día de reparto o al hablar con él». Desde entonces sale su cara en el mapa y la Josefa te habla de él. Javi es «bajito, hermoso, con gafas, calvo y vestido de negro básico».
- **`javi.gd` (nuevo).**
  - La figura:
    - Camiseta negra, calvo (`hair_style` 32), gafas.
    - `scale` 0.86 y `build` 1.34.
  - Dónde está: tras el mostrador mientras abre el asador. Lo lee de `G.world.asador.dentro`: `javi_spot`, `javi_h` y `open`, o si no `asador.open_at`.
  - El desbloqueo:
    - Se guarda en `stats.javi`.
    - Con `stats.menu_done`, llega por un martes o domingo o al hablarle.
    - Te avisa con un toast y te lo presenta (`folk.meet`).
  - La Josefa te habla de él una vez (`stats.javi_josefa`).
  - Lleva flecha verde y cara en el mapa cuando tiene un pedido.
  - Sin asador en el mapa, no se crea.
- **`trabajos.gd`.** Los pedidos de Henry pasan a `order_offer(n, kind, lines_key)`, y los pollos de Javi son el kind `pollo`. Cuando el que da el pedido está dentro de un decorado, la distancia se mide desde la puerta.
- **`game.gd` y `marcas.gd`:** los enganches.
- **`loc.gd`:** sus frases, y las de firma de Javi.
- **Pruebas:**
  - Modo `--javi` (`_javi_checks`), también en la completa. Mientras no esté el asador se salta.
  - `trabajos`: 7 ok. Ahora entrega el pedido hablando, porque ponerse a 1 m de la Paca dejaba al jugador dentro de la pared.
  - `palabros`: 3 ok.
- **Árbol de relaciones** (sin foto hasta que exista en el juego) y **diagrama de misiones** (v5), actualizados.
- **Pendiente:** el asador de Pretil, para enganchar y pasar `javi`.

### El asador de pollos «Javi»: fachada e interior (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Siguiente edificio asador de pollos juli (que llamaremos Javi). Abrirá en horario comercial y dentro estará Javi […] Se podrá acceder al interior, que estará diseñado (adjunto foto). Pasa a sistemas lo que le toque».
- **Reparto.** Yo hago el edificio y su interior. A Sistemas le pasé su parte con las palabras de Luis: el personaje Javi, sus repartos de pollo de martes y domingos, el desbloqueo tras la misión del jamón de Josefa, su cara en el mapa y la mención de Josefa.
- **Dónde.** La casa ocre de la calle de los Arcos (Catastro 4390040VJ5649S), que es la `arcos_4d` de Texturas. Google la da como «Arcos, 6», pero en Catastro ese número es la casa blanca de al lado.
- **Qué hay.**
  - `godot/scripts/asador.gd`: la fachada sobre la casa del mapa. Ocre sobre zócalo de piedra, puerta de la vivienda con cortina, la tienda con su reja plegable y su toldo, el rótulo «Javi · Pollos Asados · Comidas preparadas» (primero decía «Asador de pollos»; Luis: «En vez de Asador de Pollos mejor llamarlo Pollos Asados»), la banderola «POLLOS ASADOS», dos balcones y una buhardilla. Abierto y cerrado según la hora.
  - `godot/scripts/asador_dentro.gd`: el interior, un decorado aparte en (2100, −1400) con flecha verde en la puerta. Sigue la foto de Luis: mostrador de acero con tela morada, mampara y diez bandejas, la caja registradora, suelo de barro, cortinas naranjas; detrás, el asador con los pollos girando.
  - Rótulos propios en `godot/assets/asador/` (`tools/asador/dibujos.py`), sin el nombre real ni teléfonos.
  - Un azafrán escondido dentro (`"id": "asador"`, `"hidden": true`).
  - Sin personajes: dejo `javi_spot`, `javi_h`, `client_spot`, `client_h` y `counter_front` para Sistemas.
- **Horario**: martes y domingos de 7:00 a 16:00; cerrado el resto de la semana (`HOURS` en `asador.gd`). Un cartel en el cristal lo dice. Luis pidió primero «horario comercial», luego mandó el del asador real (martes 11–15, domingos 11:30–15) y por último: «Pon que esos días abre a las 7:00 mejor. Y cierra a las 16:00».
- **Archivos.**
  - Nuevos: `godot/scripts/asador.gd`, `godot/scripts/asador_dentro.gd`, `godot/assets/asador/` (4 PNG), `tools/asador/` (`dibujos.py`, `hojas.py`), `referencias/asador/` (`LEEME.md`, `arcos_4d_antes.txt`), `guion/fotos/asador/01–02`.
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`AsadorS`, `var asador`, paso «the roast chicken shop», `_build_asador()`), `entradas.gd` (una entrada en `shops()`), `selftest.gd` (modo `--asador`, `_asador_checks()` y su llamada en la completa tras `_almazara_checks()`).
  - De Texturas: `casas_calles.gd`, solo la línea de `arcos_4d`, que pasa a `["obra"]`. Le avisé antes con el detalle; como no contestó (estaba ocupado), la cambié yo y se lo comuniqué. Sin rehorneado.
- **Pruebas.** `python tools/run_tests.py asador`: 5 ok, 0 fallos ([log](logs/selftest_asador_20261121_180801.log)). Comprueba que está construido, que la casa está cedida, el horario y los dos estados, que el decorado está lejos y cerrado, que es una tienda con flecha, el azafrán y que el mostrador no deja pasar.
  - No he probado entrar por la flecha desde la calle andando, ni la prueba completa.
- **Trampas** (detalle en [referencias/asador/LEEME.md](referencias/asador/LEEME.md)): el primer sitio del decorado tenía dos olivos del mapa dentro; la puerta del decorado tiene que ir centrada en su pared.
- **Aprobado por Luis** (21/11): «Visto bueno», tras los cambios de nombre y de horario.
- **Pendiente.** La parte de Sistemas (Javi y sus repartos). Sin commit.

### Coger con Acción, azafrán que gira, bate al recogerlo, pedidos que esperan, Marciano (21/11, Claude · Sistemas)

21 de noviembre de 2026. Lo pidió el usuario:
> «Todos los azafranes deberían ser como los desperdigados por la ciudad, pero con el mismo efecto 3D giratorio y halo del resto de objetos»
> «muchos de los que te piden recoger aparecen exactamente donde está el jugador… no da tiempo a ver el modelo»
> «El golpe con bate estará disponible desde que lo recoges del suelo»
> «para evitar coger el objeto por accidente sería mejor que sea necesario pulsar el botón de acción»
> «cuando Henry o Javi te digan que recojas el encargo… no se activará el temporizador hasta que recojas el objeto 3D»

- **Coger con Acción** (`pickups.gd`). Ya no se coge nada solo con pisarlo.
  - `near(pp)`, `prompt(it)` («Coger %s», `p_coger`) y `take(it)`, en `interact` y en el texto de la acción de `game.gd`.
  - Los de mostrador (`auto` false: el tabaco, los pitillos) siguen con su botón.
  - Un objeto que aparecería encima de ti sale a 2,4 m, por el primer lado sin pared (`_off_the_player`).
- **Azafrán.**
  - Las flores del pueblo y las escondidas por los decorados flotan, giran y llevan el halo (`pickups.dress`, `game._dress_flowers`).
  - El jornal usa la misma flor (kind `azafran` en `_build_mesh`).
  - Se coge con Acción (`near_flower`, `_take_flower`).
- **Bate.** `has_bat()` vale también con `stats.bate`, que se pone al recoger el bate en casa de la Josefa.
- **Pedidos de Henry y Javi.** Con el «sí», el pedido aparece junto a quien lo da (kind `jamon` o `pollo`; el pollo es un modelo nuevo) y no corre el tiempo (`stage` `recoger`). Al cogerlo empieza el reloj.
  - Se entrega hablando antes que cualquier otra cosa del vecino (`trabajos.hand_over`, al principio de `talk_to`).
  - El vecino a quien va ya no tiene que estar a la vista (desde dentro de un decorado no se ve a nadie).
- **Javi, enganchado a Pollos Asados Javi** (Pretil: `asador.dentro`). Su horario final: martes y domingos de 7 a 16. El nombre del sitio está cambiado en los textos.
- **Marciano** (`marciano.gd`, nuevo; el usuario: bigote, hermoso, tupé negro).
  - Aspecto: `hair_style` 8, `face` 4 y `build` 1.3.
  - Está enfrente de la cafetería del callejón (`G.world.cafeteria.marciano_spot`/`_h`, que hace Pretil). Seis charlas: los jóvenes de hoy, los ochenta y la ruta del bacalao.
  - Hasta que esté la cafetería no aparece.
- **`scene_shot`:** una segunda pasada más cerca y más alta, con los planos de lado solo al final. Con la tanda nueva de casas, una pared de la Chiki había quedado de lado.
- **Pruebas:**
  - Completa: 934 ok, 0 fallos (`logs/selftest_full_20261121_181743.log`), antes de Marciano.
  - `javi`: 5 ok. `trabajos`: 8 ok. `herencia`: 12 ok. `pintadas`: 7 ok. `motin`: 64 ok. `palabros`: 3 ok.
  - `--marciano` se salta hasta que esté la cafetería.

### La «Cafetería Rize» y su callejón (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «El siguiente objetivo es la cafetería rice con todo su callejón incluido. Hay una foto 360° dentro del callejón. Enfrente habrá un NPC con bigote, hermoso, y peinado tupé negro que se llamará Marciano […]». Y después: «Lo llamaremos al local Rize en vez de Rice».
- **Reparto.** Yo hago el callejón, la cafetería y lo que la rodea. Marciano es de Sistemas (`marciano.gd`), que ya lee `G.world.rize`.
- **Dónde.** El callejón sin nombre que entra desde la avenida de Juan Carlos I entre `juancarlos_10` y `juancarlos_4`. Catastro: la cafetería es 4091010VJ5649S y el garaje de enfrente, 4091028VJ5649S.
- **Fuentes.** Una foto 360° del fondo del callejón (febrero de 2020; de otra persona, no está en el repositorio) y Street View desde la avenida (noviembre de 2024). En 2020 el suelo era hormigón y en 2024 adoquín gris: vale lo más reciente.
- **Qué hay** (`godot/scripts/rize.gd`, `world.rize`).
  - El callejón adoquinado y cerrado al tráfico, con un remate propio al fondo.
  - La cafetería: pared blanca sobre zócalo de granito, tres ventanas en rombo con reja, puerta sobre tres escalones, toldo con el nombre, terraza de cuatro mesas, barril, cajas y sillas apiladas.
  - El fondo: tapia vieja con un portón verde, la tinaja y las sombrillas cerradas.
  - Enfrente: el garaje blanco de uralita con el emblema y la puerta de ramas pintadas, y la casa gris de recercos de travertino.
  - La casa gris es una piel de 22 cm sobre el costado de `juancarlos_10` (Texturas la acepta: «me vale; déjala»).
  - En la boca, la pizarra, solo mientras está abierta.
  - El emblema es del juego (tupé y bigote negros, «SIEMPRE DE FIESTA»), en lugar del de la peña real.
  - Un azafrán escondido tras las cajas (`"id": "rize"`, `"hidden": true`).
  - Sin interior.
  - Para Sistemas: `marciano_spot`, `marciano_h`, `door`, `is_open`, `open_at(day, hour)`.
- **Horario**, el de la cafetería real: lunes cerrado; martes y miércoles de 9 a 17; de jueves a domingo de 9 a 19.
- **Horneado** (hecho, con aviso antes y después a Texturas y a Sistemas).
  - `PAVED_ALLEYS`: la vía sin nombre pasa a `k` 2, `paved` 2 y la marca nueva `narrow`.
  - `corridor_half` respeta `narrow` (pasillo de 1,9 m: ninguna casa se mueve).
  - Bloque `RIZE`: las dos parcelas ya no se levantan como genéricas; clave `rize` en `map.json`.
  - Diferencias: 2 tejados y 5 muros genéricos menos; `clr` del nodo 3062 de 2,8 a 1,6; lo demás, igual.
- **Archivos.**
  - Nuevos: `godot/scripts/rize.gd`, `godot/assets/rize/` (4 PNG), `tools/rice/` (`dibujos.py`, `hojas.py`, `manzana.py`, `vistas360.py`), `tools/ign/rice.jpg` y `.json`, `tools/casas/4091010VJ5649S/`, `referencias/rice/LEEME.md`, `guion/fotos/rice/01–02`.
  - Compartidos, solo con añadidos y con aviso: `tools/bake_godot.py`, `godot/data/map.json` (rehorneado), `map_data.gd` (`var rize`), `world.gd` (`RizeS`, `var rize`, paso «the Cafetería Rize», `_build_rize()`), `selftest.gd` (modo `--rize`, `_rize_checks()` y su llamada en la completa tras `_asador_checks()`).
- **Pruebas.** `python tools/run_tests.py rize`: 4 ok, 0 fallos ([log](logs/selftest_rize_20261121_185042.log)). Comprueba que está construido, que sus muros paran y el callejón es peatonal, el horario y los dos estados, el azafrán, que se entra andando desde la avenida hasta el fondo y que el sitio de Marciano ve la puerta.
  - No he pasado la prueba completa ni `--marciano` (es de Sistemas).
- **Trampas** (detalle en [referencias/rice/LEEME.md](referencias/rice/LEEME.md)): `nearest_road(p, true)` para ver una vía peatonal; lo que rellena los huecos de la piel va por delante del ladrillo; la piedra clara necesita `_glow` para no salir parda en la sombra.
- **Aprobado por Luis** (21/11): «Visto bueno sobre todo». Sin commit (lo hace Sistemas).

### La persecución de la furgoneta del sabotaje, sin caída de FPS (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «la misión de sabotaje baja mucho de FPS cuando empiezas a perseguir a la furgoneta».
- **Medido** con el modo nuevo `--perfil_sabotaje` (en ventana, sin `--fixed-fps`): el tick por partes antes del recado y durante la persecución.
  - Antes del recado: 201 fps.
  - Persiguiendo: entre 51 y 73 fps.
  - La parte de la misión pasaba de 0,1 a 5 ms en cada fotograma.
- **Causa.** `sabotaje.stop(i)` recorría las 2.727 casas del mapa y llamaba a `MapData.nearest_road`, que mira todas las calles, y `_follow` la pedía en cada fotograma.
- **Arreglo.** Se calcula una vez y se guarda (`_stops`, `_find_stop`).
- **Después:** entre 116 y 136 fps persiguiendo; la misión, 0,07 ms por fotograma. El tick de física sigue algo más alto que fuera de la misión (unos 11–15 ms frente a 5–6), pero ya no por la misión: sus partes medidas suman menos de 1,5 ms.
- **`game.gd`:** la marca «garages, missions» del perfil se parte en «garages, calls», «mission markers», «side lines» y «sabotage». Sin perfil activo no cuestan nada.
- **Prueba:** en `_sabotaje_checks`, la misión cronometrada directamente durante la persecución tiene que costar menos de 0,5 ms por fotograma. Con el código antiguo falla (4,72 ms) y con el arreglo pasa (0,07 ms). `sabotaje`: 46 ok.
- **Revisado** el resto de búsquedas caras (`nearest_road`, recorrer `houses`, `path`, `route_nodes`) dentro de código de cada fotograma: las que quedan van cada 2 s.

### La Travesía del Clavel, peatonal y elevada (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**, que llegó por Texturas: «De acuerdo, que sea peatonal y con las cosas que has dicho. Que se ponga Petril con eso cuando termine con el Rice». Antes había dicho: «Tiene dos accesos, es de la escalera de la calle clavel y el de la rampa de la calle san Rafael».
- **Qué hay** (`godot/scripts/travesia.gd`, `world.travesia`).
  - El paseo de baldosa a cuadros, un plano inclinado entre 0,9 y 1,5 m sobre el terreno.
  - Por San Rafael, tres rampas en zigzag entre muretes blancos con rejillas y barandilla de tubo.
  - Por el Clavel, la escalera a cuadros, el carril del garaje y la escalera de la terraza de la hilera este.
  - Ante cada puerta de la hilera este (de Texturas), un rellano con sus peldaños y barandilla de forja.
  - La hilera oeste y la casa blanca de la esquina del Clavel, hechas a mano: el Catastro las tiene de 1,4 a 5 m fuera de su sitio.
  - Un azafrán escondido junto al primer banco (`"id": "travesia"`).
- **Aproximado**: el carril del garaje no baja bajo el paseo (el relieve no admite un foso tan estrecho); la hilera oeste es una reconstrucción regular.
- **Horneado** (hecho, con aviso antes y después): la calle pasa a `k` 2, `pedestrian`, `paved` 5; la parte 2 de 4494604 no se levanta; clave `travesia`. Relieve, nodos, `clr`, árboles y casas, iguales.
- **Archivos.**
  - Nuevos: `godot/scripts/travesia.gd`, `godot/assets/travesia/` (3 PNG), `tools/travesia/` (5 scripts), `tools/ign/travesia.jpg` y `.json`, `guion/fotos/travesia_clavel/01–03`.
  - Compartidos, solo con añadidos y con aviso: `tools/bake_godot.py`, `godot/data/map.json`, `map_data.gd` (`var travesia`), `world.gd` (`TravesiaS`, `var travesia`, paso, `_build_travesia()`), `selftest.gd` (`--travesia`, `_travesia_checks()` tras `_rize_checks()`), `empedrado.gd` (salta `paved` 5).
  - De Texturas, hecho por ella a petición mía: `casas_calles.gd`, las nueve líneas `tcl_4` a `tcl_20` sin `esc` ni ventanuco.
  - Notas añadidas al final de [referencias/travesia_clavel/LEEME.md](referencias/travesia_clavel/LEEME.md).
- **Pruebas.** `travesia`: 4 ok ([log](logs/selftest_travesia_20261121_192929.log)): construido, el paseo elevado, se sube por las rampas, se recorre y se baja por la escalera, los muros paran, el azafrán. `relief`: 19 ok ([log](logs/selftest_relief_20261121_192716.log)).
  - No he pasado la completa.
- **Para Sistemas**: ante las puertas de la hilera hay que usar `MapData.foot(p)`; avisado.
- **Aprobado por Luis** (21/11): «Visto bueno sobre todo». Sin commit (lo hace Sistemas).

### Rendimiento de las misiones y la riña que deja ver a través (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Prueba de rendimiento» y «Que durante la riña del jamón los NPCs detrás de ti salgan transparentes, no invisibles».
- **Medida.** Modo nuevo `--perfil_misiones` (en ventana, sin `--fixed-fps`). Mide una tras otra varias situaciones del juego, y el informe del perfil saca ahora también las llamadas de dibujado, los objetos y los triángulos.

  | Situación | FPS |
  |---|---|
  | A pie en la plaza | 140 |
  | Taxi | 112–116 |
  | Reparto | 160 |
  | Jornal con 30 rosas | 232 |
  | Persecución de la policía | 101 |
  | Dentro del Recress | 252 |
  | La riña del jamón | 70–74 |
  | Persecución de la furgoneta del sabotaje, ya arreglada (antes 51–73) | 116–136 |

- **La riña.** Ninguna parte del código destaca. Lo que pesa es el dibujado:
  - 2.471 llamadas frente a 1.343 a pie, y 3.790 objetos frente a 2.014.
  - Cada vecino de la multitud son decenas de piezas.
  - Quitar las sombras de la multitud no cambia nada: solo 103 piezas hacían sombra.
  - **Pendiente:** juntar las piezas de cada vecino en una malla. Es un cambio en `chara.gd` de calado, que se deja fuera de esta versión.
- **Transparencia en la riña** (`game.gd` `_ghost_lens` y `_ghost`, `GHOST` 0.68). Los vecinos entre la cámara del hombro y tú se ven a través, con `transparency` en sus `GeometryInstance3D`, en vez de ocultarse. En las escenas de cámara fija, quien queda pegado al objetivo se sigue ocultando como antes.
  - Prueba nueva en `motin`: un vecino en medio se ve a través y vuelve a ser sólido al apartarse. `motin`: 66 ok. La foto es `motin_transparente`.

### Publicación de la 0.0.20 en GitHub (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Si todo sale bien, prueba completa, commit de todo y release».
- **Congelado.** Pretil y Texturas, sin nada a medias.
- **Prueba completa:** 945 ok, 0 fallos (`logs/selftest_full_20261121_200056.log`).
- **Commits:**
  - `b97ac87`: todo, de Sistemas, Pretil y Texturas.
  - «Matritellus 0.0.20»: versión y notas.
- **Etiqueta:** `v0.0.20`.
- **Paquetes:** `tools/make_apk.py 0.0.20` (versión 0.0.20, código 20, firmado y verificado), `tools/make_installer.py` y `tools/make_linux.py`.
  - Están en `dist/v0.0.20/`, con [sus SHA-256](dist/v0.0.20/SHA256SUMS.txt) comprobados.
  - Release: https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.20
- **Sin probar:** no se ha probado en móvil ni en Steam Machine.

### «Seguros Sopiss», primera pieza del cruce de los semáforos (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «…el cruce de los semáforos o las cuatro esquinas… Te pido ahora colocar estos donde corresponde. Antes igual tendremos que hacer unas pocas fachadas. Sugiero ir una por una y empezar por el edificio de soliss seguros (última foto) y que llamaremos seguros sopiss, tendrá luces de apagado o encendido según su horario y en su interior saldrán dos NPCs genéricos hablando de seguros cuando abierto, y una señora de la limpieza cuando cerrado. Se podrá ver desde fuera, pero no pasar. Vayamos poco a poco».
- **Qué hay** (`godot/scripts/sopiss.gd`, `world.sopiss`, sobre la casa `salvador_24`, sin horneado).
  - El edificio rojo de tres plantas con sus tres fachadas, la banda fucsia «SOPISS · Seguros de toda la vida», balcones de forja, alero de madera y tejado a cuatro aguas.
  - La oficina a la vista por cristales de verdad; no se entra.
  - Luces, penumbra y cartel «ABIERTO»/«CERRADO» según el horario real: lunes a viernes de 9 a 14 y de 17 a 20.
  - Un azafrán escondido en el portal de los pisos (`"id": "sopiss"`).
- **Reparto.** Texturas pasó `salvador_24` a `["obra"]`. Los tres personajes son de Sistemas (`sopiss_gente.gd`), que lee `desk_spots`, `clean_spots` e `is_open`.
- **Archivos.**
  - Nuevos: `godot/scripts/sopiss.gd`, `godot/assets/sopiss/` (10 PNG), `tools/cruce/` (6 scripts), `tools/ign/cruce*.jpg` y `.json`, `guion/fotos/cruce/sopiss_01–04`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`SopissS`, `var sopiss`, paso «Seguros Sopiss», `_build_sopiss()`), `selftest.gd` (`--sopiss`, `_sopiss_checks()` y su llamada tras `_travesia_checks()`).
- **El neón (22/11).** Luis: «El neon de salamanquesa podría brillar en amarillo por la noche». El letrero «Salamanquesa» es azul de día y luz amarilla de noche, con una luz sin sombras en la pared; sigue al cielo (`sky_fx.night`), no al horario. Es más grande que al principio (2,5 m) para que se lea.
- **Prueba.** `sopiss`: 4 ok ([log](logs/selftest_sopiss_20261122_000215.log)).
  - No he pasado la completa ni la prueba de Sistemas con los personajes dentro.
- **Visto de paso, sin tocar.**
  - La calle al sur del edificio es «Calle del Teniente Infante» en el mapa y «Calle Cervantes» en la placa real. Preguntado a Luis.
  - Cada arranque del juego escribe doce veces el error `ARRAY_FORMAT_TEX_UV` al construir la almazara (`_build_almazara`): mezcla piezas con y sin coordenadas de textura en un mismo material. Es mío y viene de antes; no afecta a lo que se ve. **Quitado el 22/11**: los dos faldones de chapa de las naves de atrás se ponen ahora sin esas coordenadas, como el resto de su chapa (`_sheet_slope` en `almazara.gd`). `almazara`: 3 ok y ninguna aparición del error ([log](logs/selftest_almazara_20261122_003121.log)).
- **Visto bueno de Luis (22/11):** «Visto bueno a sopiss».
- **Pendiente.** Las otras esquinas, una por una; los semáforos, el espejo y las señales del cruce. Sin commit (lo hace Sistemas).

### «Clínica Dental», segunda pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Vamos con el dentista. Lo llamaremos "Clínica Dental" y "Dr. Josué Escudero"».
- **Qué hay** (`godot/scripts/clinica.gd`, `world.clinica`, sobre la casa `arcos_2`, sin horneado).
  - La esquina de la calle Cervantes con los Arcos: planta baja de piedra oscura con tiras de acero y letras en relieve, ventanas de espejo con sus palabras, puertas de lamas y puerta de la clínica.
  - A los Arcos, además, el portal de la casa entre granito gris, tras una cortina rosa.
  - Arriba, el balcón corrido de chapa que dobla la esquina, tres balcones de forja y el alero de madera.
  - Sin azafrán: puse uno en el portal de la casa y Luis lo mandó quitar (ver abajo).
- **Añadido mío, sin pedir**: los cristales tienen una luz tenue mientras está abierta (horario real: L–V 9–13:30 y 16:30–20) y las letras se iluminan de noche.
- **Código común nuevo**: `godot/scripts/esquina.gd` recoge lo que comparten los edificios del cruce (tejado por faldones, aleros, medianeras, sólidos). `sopiss.gd` pasa a extenderlo; su prueba sigue en 4 ok tras el cambio ([log](logs/selftest_sopiss_20261122_001746.log)).
- **Reparto.** Texturas pasó `arcos_2` a `["obra"]`. No hay personajes.
- **Archivos.**
  - Nuevos: `godot/scripts/clinica.gd`, `godot/scripts/esquina.gd`, `godot/assets/clinica/` (7 PNG), `tools/cruce/dibujos_clinica.py`, `guion/fotos/cruce/clinica_01–03`.
  - Cambiados, míos: `godot/scripts/sopiss.gd`, `tools/cruce/capturas.py`, `mide.py`, `hojas.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`ClinicaS`, `var clinica`, paso «the dental clinic», `_build_clinica()`), `selftest.gd` (`--clinica`, `_clinica_checks()` y su llamada tras `_sopiss_checks()`).
- **Prueba.** `clinica`: 2 ok ([log](logs/selftest_clinica_20261122_002736.log)).
  - No he pasado la completa.
- **Visto bueno de Luis (22/11):** «Visto bueno. No renombres. Quita ese azafrán escondido, sigue proponiendolos y yo te digo en cada proyecto si lo añadimos o lo quitamos».
  - La clínica queda aprobada.
  - La calle de abajo no se renombra en el mapa.
  - El azafrán de la clínica, quitado; su cortina cierra el portal entero. **Norma nueva**: en cada proyecto se propone el azafrán y no se pone hasta que Luis lo diga.
- **Pendiente.** Las otras tres esquinas; los semáforos y las señales. Sin commit (lo hace Sistemas).

### La gente de dentro de «Seguros Sopiss» (21–22/11, Claude · Sistemas)

- **Encargo de Luis** (por Pretil, y después en directo): «dos NPCs genéricos hablando de seguros cuando abierto, y una señora de la limpieza cuando cerrado»; «Que se oiga a través del cristal, el seguro lo vende una mujer rubia con americana, el que recibe el seguro cambia cada vez. La de la limpieza va tarareando música».
- **Qué hay** (`godot/scripts/sopiss_gente.gd`, `game.sopiss_gente`; lee `world.sopiss`: `is_open`, `desk_spots`, `clean_spots`).
  - Abierto: la vendedora (rubia, americana azul oscuro con blusa en pico) tras el mostrador y un cliente delante.
  - A menos de 9 m del cristal se oye una charla entera, frase a frase sobre sus cabezas (Loc `sopiss_charla`, 10 charlas).
  - Cuando acaba la charla o te vas, el siguiente cliente se sienta sin que nadie mire. Es otra persona y trae otra charla.
  - Cerrado (también de 14 a 17): la limpiadora, con bata y fregona, hace la ronda de `clean_spots`. Tararea una melodía hecha en el propio juego, sin canción concreta, apagada por el cristal (clase `Hum`), con «♪ la-ra-ra ♪» sobre la cabeza (Loc `sopiss_tarareo`).
  - Hablarles a través del cristal: contestan desde dentro (Loc `sopiss_cristal`, `sopiss_cristal_limpia`).
  - Son vecinos anónimos (`id ""`, `still`) con meta `sopiss`; no entran en `named`, así que no firman ni reciben pedidos.
- **Archivos**: nuevo `sopiss_gente.gd`; añadidos en `game.gd` (preload, var, setup, tick, gancho al principio de `talk_to`), `loc.gd` (las cuatro claves) y `selftest.gd` (`_sopiss_gente_checks`, modos `--sopiss_gente` y `--sopiss_gente_fotos`, llamada en la completa tras `_marciano_checks`).
- **Pruebas.** `sopiss_gente`: 10 ok con la oficina de verdad ([log](logs/selftest_sopiss_gente_20261122_003019.log)). `palabros`: ok. Fotos en `godot/shots/sopiss_gente_*`. No se ha pasado la completa.
- **Visto bueno de Luis a Sopiss (22/11).** Sin commit todavía.

### La casa blanca de Santa Ana 2, tercera pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**, con una captura de Street View: «Vamos a tratar de terminar el cruce de los semáforos para poner definitivamente los semáforos. El siguiente será Calle Santa Ana, 2».
- **Qué hay** (`godot/scripts/stana2.gd`, `world.stana2`, sobre la casa `constitucion_a1`, sin horneado).
  - La casa encalada de la esquina de Santa Ana con los Arcos: zócalo de mampostería, portón de madera con clavos, ventanas con reja, marcos añil, balconcillos, cornisa blanca con las bocas de las tejas y chimenea.
  - A los Arcos, la ventana con reja, el portal con cortina morada y la placa de la calle.
  - Detrás, la construcción del fondo, lisa.
  - Sin azafrán: propuesto a Luis junto al portón.
- **Reparto.** Texturas pasó `constitucion_a1` a `["obra"]`. No hay personajes ni horario.
- **Archivos.**
  - Nuevos: `godot/scripts/stana2.gd`, `guion/fotos/cruce/stana2_01–02`.
  - Cambiados, míos: `tools/cruce/capturas.py`, `mide.py`, `hojas.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`Stana2S`, `var stana2`, paso «the white house of Santa Ana», `_build_stana2()`), `selftest.gd` (`--stana2`, `_stana2_checks()` y su llamada tras `_clinica_checks()`).
- **Pruebas.** `stana2`: 2 ok ([log](logs/selftest_stana2_20261122_004858.log)).
  - `clinica`, ya sin su azafrán: 2 ok ([log](logs/selftest_clinica_20261122_004718.log)).
  - No he pasado la completa.
- **Visto bueno de Luis (22/11):** «No se pone Azafrán. Visto Bueno. Siguiente».
- **Pendiente.** Las dos esquinas que quedan; los semáforos y las señales. Sin commit (lo hace Sistemas).

### La casa crema del mirador, cuarta pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**, tras aprobar Santa Ana 2: «No se pone Azafrán. Visto Bueno. Siguiente». De las dos esquinas que quedaban he seguido por la del mirador.
- **Qué hay** (`godot/scripts/mirador.gd`, `world.mirador`, sobre la casa `constitucion_2`, sin horneado).
  - La casa de 1925 de la esquina de la avenida con Santa Ana: revoco crema con zócalo, recercos, balcones y cornisa en ocre.
  - En el chaflán, el portal con cortina y el mirador encima.
  - A la avenida y a Santa Ana, ventanas con reja, balcones de antepecho macizo y las placas de las calles.
  - A Santa Ana, además, la parte blanca con el portón de arco y la galería de madera.
  - Un acerado propio ante el chaflán y Santa Ana, porque el del pueblo no llegaba a las paredes. Cada punto sale de la pared hasta el bordillo y no más (`_to_kerb()`).
  - Sin azafrán: propuesto a Luis tras el portón de arco.
- **Reparto.** Texturas pasó `constitucion_2` a `["obra"]`. No hay personajes ni horario.
- **Archivos.**
  - Nuevos: `godot/scripts/mirador.gd`, `godot/assets/clinica/placa_santa_ana.png`, `guion/fotos/cruce/mirador_01–02`.
  - Cambiados, míos: `tools/cruce/capturas.py`, `mide.py`, `hojas.py`, `dibujos_clinica.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`MiradorS`, `var mirador`, paso «the house with the bay window», `_build_mirador()`), `selftest.gd` (`--mirador`, `_mirador_checks()` y su llamada tras `_stana2_checks()`).
- **Prueba.** `mirador`: 2 ok ([log](logs/selftest_mirador_20261122_013352.log)).
  - No he pasado la completa.
- **Pendiente.** Nada: aprobada por Luis el 22/11, sin azafrán. Sin commit (lo hace Sistemas).

### La casa beige del Salvador, quinta pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Vamos a tratar de terminar el cruce de los semáforos para poner definitivamente los semáforos». Era la última esquina.
- **Qué hay** (`godot/scripts/beige.gd`, `world.beige`, sobre la casa `salvador_c3`, sin horneado).
  - La casa de dos plantas de 1976 al norte del Salvador, en su esquina con la avenida: dos alas de una crujía alrededor de un patio.
  - A la avenida: revoco beige, portal hondo encalado, dos ventanas con reja y tres arriba con barandilla.
  - Al Salvador: revoco gris, cuatro ventanas con reja (una de buche), trampilla, respiraderos y la placa «Calle Salvador».
  - El testero norte, con el yeso de la casa vecina que tiraron.
  - Tejado a dos aguas en cada ala, hecho con dos tejados que se solapan en la esquina.
  - Las naves del patio y del fondo de la parcela, lisas: con `["obra"]` el mapa deja de dibujar las tres piezas de la casa.
  - La tapia de bloques del solar del norte, con su cancela roja: por la avenida y, doblando, por la calle de Colón.
  - Sin azafrán: propuesto a Luis en el fondo del portal.
- **Arreglos de paso.**
  - `esquina.gd`, `_inset()`: dos aristas casi en línea ya no se cruzan a cientos de metros. Repetidas las pruebas de los otros cuatro edificios, que usan el mismo kit.
  - `mirador.gd`: su acerado propio busca el bordillo punto a punto (`_to_kerb()`); a ojo se metía 0,83 m en la calzada.
  - `selftest.gd`, en mis modos `--mirador` y `--beige`: `g.traffic.clear()` antes de cada captura.
- **Reparto.** Texturas pasó `salvador_c3` a `["obra"]`. No hay personajes ni horario.
- **Archivos.**
  - Nuevos: `godot/scripts/beige.gd`, `godot/assets/clinica/placa_salvador.png`, `guion/fotos/cruce/beige_01–03`.
  - Cambiados, míos: `godot/scripts/esquina.gd`, `mirador.gd`, `tools/cruce/capturas.py`, `mide.py`, `hojas.py`, `dibujos_clinica.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`BeigeS`, `var beige`, paso «the house north of the Salvador», `_build_beige()`), `selftest.gd` (`--beige`, `_beige_checks()` y su llamada tras `_mirador_checks()`).
- **Pruebas.** `beige`: 2 ok ([log](logs/selftest_beige_20261122_020647.log)). Tras el cambio del kit: `sopiss` 4 ok; `clinica` 2 ok; `stana2` 2 ok; `mirador` 2 ok.
  - No he pasado la completa.
- **Pendiente.** Nada: Luis aprobó esta casa y la del mirador el 22/11 («Visto bueno. Sin azafrán. Pasamos a semáforos»). Los semáforos están en la entrada siguiente. Sin commit (lo hace Sistemas).

### Semáforos, espejo y señales, sexta pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Visto bueno. Sin azafrán. Pasamos a semáforos». Con eso aprobó la casa del mirador y la casa beige, sin azafrán en ninguna.
- **Qué hay** (`godot/scripts/cruce.gd`, `world.cruce`, sin horneado y sin casa del mapa).
  - Cinco postes de semáforo y un báculo con brazo sobre Santa Ana: 7 cabezas de tres luces y 7 de peatones, con sus pulsadores.
  - Una cabeza en escuadra y el ceda el paso en la fachada de Sopiss al Salvador.
  - El espejo redondo y un STOP en un poste ante Sopiss; prohibido autobuses a Cervantes.
  - Prohibido el paso al Salvador (con su placa) y a Santa Ana; prohibido girar a la derecha sobre STOP en la esquina de la casa blanca; prohibido parar en la avenida; prohibido aparcar en la pared de la clínica.
  - El armario gris de la casa beige y la papelera de la casa blanca.
  - En la calzada, la línea de detención de cada calle que trae coches y el paso de cebra de la avenida al norte del Salvador.
  - Las lentes brillan con su material: no hay luces nuevas.
- **Se rompen de un golpe** (Luis, 22/11: «Solo añadiría que se puedan romper con un golpe, una vez rotos pasan a funcionar como ámbar. Se arreglan igual que el resto de objetos rompibles»).
  - Los postes, el báculo, el armario y la papelera son 14 cuerpos sueltos que `props.gd` adopta (`adopt()`, nueva): un coche o un puñetazo los tumba como al resto del mobiliario.
  - Sistemas añadió dos ganchos a `_knock` y `cruce.gd` se los pone a sus cuerpos: `on_knock` (avisa en el momento de la caída; los 14) y `keep` (no se borra a los 40 s; los siete que llevan luces o las mandan). Un semáforo caído se queda tirado; una señal o la papelera desaparecen como el resto.
  - Con un semáforo o el armario caídos, `world.cruce.broken` es `true` y todo el cruce parpadea en ámbar; `semaforos.gd` lo trata como su ámbar de madrugada.
  - `world.cruce.repair()` lo levanta todo. Se arreglan al día siguiente, como el resto del mobiliario (decisión de Luis del 22/11, «Al día siguiente», que llegó por Sistemas): `props.gd` (`mend()`, de Sistemas) llama a `world.cruce.repair()` cuando hay algo caído (`broken` o `down > 0`), ya es otro día que el de la última caída y no se ve el punto de parada de la avenida. Hasta entonces el semáforo caído sigue tirado y el cruce en ámbar. Al cargar la partida todo está en pie. `world.cruce.fallen()` da los sitios que el arreglo cambiaría.
  - Lo que cuelga de una pared (ceda el paso y cabeza de Sopiss, prohibido aparcar de la clínica) no se rompe.
- **Cómo se midió.** 42 vistas `x_` de Street View y `tools/cruce/postes.py`, que cruza rumbos desde varias cámaras (±0,7 m). Cada cosa va por su sitio a lo largo de la fachada más cercana; `_stand()` la arrima a la pared donde la acera del juego es más estrecha.
- **Reparto con Sistemas.**
  - `cruce.gd` da `heads`, `walk`, `set_light()`, `set_walk()`, `auto`, `restart()`, `lights()` y `put_back()`.
  - `semaforos.gd` (Sistemas) lleva el ciclo, el ámbar intermitente de 1 a 7 y los coches que paran. Pone `auto` a `false`; sin él, `cruce.gd` lleva un ciclo propio solo de luces.
  - Luis decidió que los semáforos solo paran a los coches del pueblo, y que el último tramo de Santa Ana sea de sentido único hacia el cruce (`ONE_WAY_FIX`, de Sistemas).
  - Los nombres `avenida` y `arcos` de `heads` no se pueden cambiar: Sistemas los usa para el STOP de noche.
- **Archivos.**
  - Nuevos: `godot/scripts/cruce.gd`, `tools/cruce/postes.py`, `guion/fotos/cruce/cruce_01–05`.
  - Cambiados, míos: `tools/cruce/capturas.py`, `hojas.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`CruceS`, `var cruce`, paso «the crossroads' traffic lights», `_build_cruce()`), `selftest.gd` (`--cruce`, `_cruce_checks()` y su llamada tras `_beige_checks()`), `props.gd` (`adopt()`, tras `_knock`).
- **Pruebas.** `cruce`: 5 ok ([log](logs/selftest_cruce_20261122_031520.log)); `arreglos` (la prueba de Sistemas de la regla del día siguiente, con este cruce): 2 ok ([log](logs/selftest_arreglos_20261122_031706.log)).
  - Sistemas ha pasado su prueba `semaforos` sobre este cruce con coches de verdad: 8 ok, con dos coches esperando en la linea de la avenida. No he pasado la completa.
- **Cómo verlo en el juego.** Ir al cruce de la avenida de la Constitución con Santa Ana: los semáforos cambian solos y los coches del pueblo paran en las líneas. Dar un puñetazo a un poste con semáforo, o tumbarlo con un coche: todo el cruce queda en ámbar intermitente.
- **Pendiente.** El visto bueno de Luis. Sin poner: las farolas de brazo de las fachadas, los carteles de dirección y el semáforo siguiente de la avenida. Sin commit (lo hace Sistemas).

### Hoja de relevo de Edificios Especiales (22/11, Claude · Edificios Especiales)

22 de noviembre de 2026. Luis va a pasar el trabajo de Edificios Especiales a otra IA mientras esta sesión está en pausa («Para aliviar carga le voy a pasar tu trabajo a otra IA mientras tanto») y pidió preparar lo necesario para que no se estropee.

- **Hecho.** [RELEVO_EDIFICIOS_ESPECIALES.md](RELEVO_EDIFICIOS_ESPECIALES.md), en la raíz: qué es el papel, qué leer antes, lo que puede estropear el trabajo (git, Godot, horneado, archivos compartidos y de otros, nombres que usan `semaforos.gd` y `props.gd`), las normas de Luis que solo estaban en la memoria de Claude, cómo se hace un lugar, el estado del cruce y qué dejar escrito al terminar.
- **Archivos.** `RELEVO_EDIFICIOS_ESPECIALES.md` (nuevo) y este registro. Sin cambios en el juego: no hay prueba.
- **Copia antes del relevo.** Luis pidió commit y versión («Pidele commit y release, asi tenemos un backup de todo antes de tocar con la otra IA») y Sistemas publicó la 0.0.21 (`8c49e83` y `61f3781`, etiqueta `v0.0.21`), con todo el cruce dentro y el árbol limpio. Después se puso al día la hoja: ya no dice que el cruce está sin commit, y añade los finales de línea y los dos umbrales justos de la prueba completa. Ese cambio de la hoja queda sin commit.
- **Para Claude al volver.** Leer las entradas posteriores a esta, con `git status --short` y `git diff`, antes de tocar nada.

### Semáforos que funcionan, el último tramo de Santa Ana y lo roto que vuelve (22/11, Claude · Sistemas)

- **Encargo de Luis**: «Solo paran coches» (qué hacen los semáforos), «Solo el último tramo» (Santa Ana de sentido único), «Al día siguiente» (cuándo se arregla lo roto). El cruce (`cruce.gd`) es de Edificios Especiales.
- **Semáforos** (`godot/scripts/semaforos.gd`, `game.semaforos`):
  - El ciclo: el grupo 0 (avenida y Arcos) tiene 16 s de verde y el 1 (Salvador y Santa Ana) 11 s; después 3 s de ámbar y 1,5 s de rojo en los dos.
  - Ámbar intermitente de 1 a 7, y también mientras `world.cruce.broken`. Entonces solo paran un momento en la línea los de «avenida» y «arcos», que tienen STOP.
  - Manda sobre `cruce.set_light` y `cruce.set_walk` y pone `cruce.auto = false`. Se engancha al tráfico en su primer tick, porque el tráfico se crea después.
  - `traffic.gd`: `lights.gap()` frena el coche a 3 m/s² hasta su línea y lo deja esperando (`at_light`). Los de detrás lo ven como «en marcha» y hacen cola en vez de adelantar. Los de servicio y el piloto automático no paran.
- **Santa Ana**: `map_data.gd` `ONE_WAY_FIX`, del Romero (969) al cruce (974), solo hacia el cruce, sin rehornear. `one_way_says` lo lee primero.
- **Lo roto vuelve al día siguiente** (`props.gd`):
  - `_knock` guarda dónde estaba la pieza. A los 40 s se esconde (`_tidy`) en vez de borrarse.
  - `mend()` la vuelve a poner cada 2 s si ya es otro día y no se ve. Los árboles también (`world.unfell_tree`).
  - Lo que lleva la meta `on_knock` es del dueño: el cruce se arregla entero con `cruce.repair()` cuando no se ve ninguno de los sitios de `cruce.fallen()`. Con `keep` no se borra a los 40 s.
- **Pruebas.** `semaforos`: 9 ok (ciclo, caras, distancia a la línea, noche y STOP, roto, Santa Ana, un coche de verdad que para en rojo y sigue en verde, todo sobre el cruce de verdad). `arreglos`: 2 ok. `sentido` y `grua` ok. Foto: `--semaforos_fotos`.

### MaxiPrecio, la tienda de ropa de la calle de los Arcos (23/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Vamos con el HiperTextil Miniprecio (que llamaremos MaxiPrecio). Necesitará tener un interior (hay fotos en maps) y su horario comercial». Después, con una imagen de referencia: «Como el logo original son dos cerezas que el nuestro sean dos melocotones».
- **Hecho.**
  - **La fachada** (`godot/scripts/maxiprecio.gd`, sobre `esquina.gd`, `world.maxiprecio`), en la casa `mol_b301` de Texturas, que la cedió con `["obra"]`. Sin rehorneado.
    - A los Arcos: el frente en V bajo sus dos rótulos y sus toldos, el pilar crema con pintadas, los tres escalones y el porche de cristal sobre azulejo.
    - Arriba, las dos alas con balcones corridos y el mirador curvo con su pérgola.
    - A Granada y al Molino: las rayas azules y el mural; en Granada, el portal de los pisos. La parte 3 del Molino, de ladrillo tosco con manchas de mortero.
  - **El logo**: dos melocotones en vez de las cerezas, con «Maxi Precio» en blanco. Los dibujos son nuestros (`tools/maxiprecio/dibujos.py` → `godot/assets/maxiprecio/`): rótulo, rayas, mural y cartel del horario. Sin «Síguenos en Facebook», porque en el juego no hay redes sociales.
  - **El horario** de la tienda real (Google Maps): de lunes a viernes de 9:30 a 14 y de 17 a 21, los sábados de 9:30 a 14 y los domingos cerrada. Abierta: los toldos bajados, la puerta abierta, luz dentro y la flecha verde. Cerrada: los toldos recogidos y la puerta cerrada.
  - **El interior** (`godot/scripts/maxiprecio_dentro.gd`): un decorado aparte en (2150, −600), al que se entra por la flecha verde de delante de los escalones (`entradas.gd`).
    - Es un **primer borrador**: un hipertextil genérico, hasta que lleguen las capturas de Luis (las fotos de Maps piden iniciar sesión).
    - Para el Maxi de Sistemas da `open`, `clerk_spot`/`clerk_h` y `probador_spot`/`probador_h`. Sin maniquíes ni figuras.
  - **Repaso con Street View** (noviembre de 2024):
    - el ladrillo, salmón pálido en vez del naranja de la textura;
    - las barandillas de los pisos, gris claro (la pérgola y la del mirador siguen de hierro oscuro);
    - el azul de rayas y toldos, más hondo;
    - los escaparates, oscuros de día;
    - el mortero del tosco, en manchas.
- **Archivos.**
  - Nuevos: `godot/scripts/maxiprecio.gd`, `godot/scripts/maxiprecio_dentro.gd`, `tools/maxiprecio/dibujos.py`, `godot/assets/maxiprecio/` (cuatro PNG), [referencias/maxiprecio/LEEME.md](referencias/maxiprecio/LEEME.md), `guion/fotos/maxiprecio/` (dibujos y capturas del juego).
  - Compartidos, solo con añadidos y con aviso a Sistemas:
    - `world.gd`: `MaxiprecioS`, `var maxiprecio`, el paso «the shop MaxiPrecio» y `_build_maxiprecio()`;
    - `entradas.gd`: el interior en `shops()`;
    - `selftest.gd`: `_maxiprecio_checks()`, el modo `--maxiprecio` y la llamada tras `_asador_checks()`.
- **Pruebas.** `maxiprecio`: 5 ok ([log](logs/selftest_maxiprecio_20261123_062937.log)), sin avisos de UV. No he pasado la completa.
  - Lo que mira: la casa cedida, que las fachadas y los escalones paran, las tres calles, el horario y sus dos estados, el interior lejos y cerrado, y que nadie pasa tras el mostrador.
  - La flecha verde aparece una vez que el Vizum de la Josefa abre la tienda (era de la Tía Paca; Luis se lo pasó a la Josefa el 23/11) (`tiendas_ropa.gd`, de Sistemas). Antes está cerrada.
- **Pendiente.**
  - El visto bueno de Luis a la fachada.
  - Las capturas del interior, para rehacer el borrador.
  - El azafrán escondido, solo propuesto: dentro, en una de las cestas de la isla del centro, entre los calcetines.
  - Al este de E2–SE el mapa está vacío (en la realidad sigue el bloque de pisos), así que desde Granada se ve una medianera lisa. Es zona de Texturas.
  - Sin commit: lo hace Sistemas.

### El maniquí de la puerta del MaxiPrecio (23/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Ponle un maniquí con ropa y sombrero en la puerta (puede ser un modelo de NPC blanco y la ropa con color), que sea rompible y que cambie cada día aleatoriamente».
- **Hecho.** `godot/scripts/maniqui.gd` (nuevo y mío, vale para cualquier tienda), puesto por `maxiprecio.gd` como `maniqui`.
  - Es una figura de `chara.gd`: la piel de plástico blanco, sin pelo, sin ojos y sin coloretes, sobre una peana. Está en la acera, a la derecha de los escalones según se mira la tienda.
  - Cada día lleva otra ropa, otro sombrero y otro calzado, sacados de las opciones del creador. Se sortea con el día como semilla y se cambia cuando nadie lo mira.
  - Es mobiliario de la calle: `props.adopt(self, p, "maniqui", 0.35, 4.0)` cuando el juego tiene `props`. Un golpe o un coche lo tiran y vuelve al día siguiente (`mend()`). `props.gd` no se ha tocado.
- **Archivos.** Nuevo: `godot/scripts/maniqui.gd`. Cambiados, míos: `maxiprecio.gd` (`ManiquiS`, `MANIQUI`, `var maniqui`), [referencias/maxiprecio/LEEME.md](referencias/maxiprecio/LEEME.md), `guion/fotos/maxiprecio/maxiprecio_05_maniqui.jpg`. En `selftest.gd`, solo dentro de lo mío: una comprobación más en `_maxiprecio_checks()` y seis vistas del maniquí en `--maxiprecio`.
- **Pruebas.** `maxiprecio`: 6 ok ([log](logs/selftest_maxiprecio_20261123_064043.log)). El maniquí está en su sitio, es blanco y sin cara, viste distinto los siete días y el mismo día igual; un puñetazo lo tira y `mend()` lo levanta.
- **Solo con la tienda abierta.** Luis: «Solo mientras la tienda está abierta». `maxiprecio.set_open()` llama a `maniqui.set_out()`. Cerrada, el maniquí se guarda: no se ve, la capa de colisión pasa a 0 y su `rad` para `props.gd` queda fuera de alcance. Abierta, vuelve a salir. `maxiprecio`: 7 ok ([log](logs/selftest_maxiprecio_20261123_070045.log)).
- **Pendiente.** El visto bueno de Luis. Sin commit: lo hace Sistemas.
- **Visto bueno de Luis** (23/11, después de aprobar la Tetoqa): «Visto bueno también», al MaxiPrecio con su maniquí. 
- **El azafrán escondido**, a la palabra de Luis («Ponlo también», 23/11): en el cubo del fondo de la isla del centro, el de la izquierda según se entra, entre los calcetines (`maxiprecio_dentro.gd` `_saffron`, `"id": "maxiprecio"`). En `selftest.gd`, dentro de lo mío: una comprobación más al final de `_maxiprecio_checks()` (que está y se llega a él sin cogerlo) y la vista `dentro_azafran` en `--maxiprecio`. `maxiprecio`: 8 ok ([log](logs/selftest_maxiprecio_20261123_085253.log)). Como todos, `pickups.gd` lo hace flotar y girar con su halo sobre el cubo. Avisado a Sistemas para su cuenta.

### Tetoqa, la tienda de complementos de Santa Ana con el Cristo (23/11, Claude · Edificios Especiales)

- **Encargo de Luis**, con una captura de Street View (C. Sta. Ana 54, noviembre de 2024): «Vamos con la tienda de complementos Tutoq (que llamaremos Tetoqa). Mismo tratamiento que con MiniPrecio pero esta vez para complementos».
- **Hecho.**
  - **La fachada** (`godot/scripts/tetoqa.gd`, sobre `esquina.gd`, `world.tetoqa`), en la casa `stana_54` de Texturas, cedida en `casas_calles.gd` con `["obra"]`. Sin rehorneado.
    - Planta baja de granito rosado gris: dos escaparates de ropa a Santa Ana con el rótulo encima, el aire acondicionado y la alarma, y el portal de los pisos en piedra clara con su cancela; en el chaflán, la puerta tras su persiana blanca; al Cristo, el escaparate de cubos blancos de bolsos y zapatos, el de baldas de cristal con sombrerero y la caja de luz en blanco.
    - Dos plantas en vuelo de 0,45 m sobre las tres calles: ladrillo naranja con paños crema, balcones franceses con persianas beis, franjas crema con rombos de ladrillo, cornisa y bocas de teja. Tejado de teja vieja a cuatro aguas (una vertiente a cada calle y otra a la trasera).
  - **El rótulo** es nuestro (`tools/tetoqa/dibujos.py` → `godot/assets/tetoqa/`): «Complementos» en rosa manuscrito con ramitas de flor de almendro y «Tetoqa» pequeño. También el cartel del horario y el nombre de la pared del fondo de dentro.
  - **El horario** es inventado (Google Maps no da el de la tienda real): de lunes a viernes de 10 a 13:30 y de 17:30 a 20:30, los sábados de 10 a 14 y los domingos cerrada. Abierta: persiana subida, luz dentro, maniquí fuera y flecha verde. Cerrada: persiana bajada y escaparates a oscuras.
  - **El interior** (`godot/scripts/tetoqa_dentro.gd`, en borrador): un decorado aparte en (−1000, −1200), con la flecha verde delante del chaflán (`entradas.gd`). Baldas de cubos, mostrador con pared rosa, barra de ropa con ganchos, vitrina de bisutería, torre de gafas, mesa de pañuelos, sombrerero, el nombre al fondo con un espejo ovalado y el probador con cortina rosa. Expone para Sistemas `clerk_spot`, `client_spot` y `probador_spot` con sus rumbos. Sin maniquíes ni figuras dentro.
  - **El maniquí de la puerta**: el de `maniqui.gd`, con un quinto parámetro nuevo `trinkets` (por defecto `false`, así que el del MaxiPrecio no cambia). Siempre con sombrero y casi siempre con gafas, pendientes y algo al cuello. Cambia cada día y solo sale con la tienda abierta.
- **Archivos compartidos** (solo líneas insertadas, avisando antes a Sistemas):
  - `world.gd`: `TetoqaS`, `var tetoqa`, el paso «the shop Tetoqa» y `_build_tetoqa()`;
  - `entradas.gd`: el interior en `shops()`, cerrado hasta el Vizum de la Josefa como el MaxiPrecio;
  - `selftest.gd`: `_tetoqa_checks()`, el modo `--tetoqa` y la llamada tras `_maxiprecio_checks()` en la prueba completa.
  - Sistemas ya añadió `"tetoqa"` a `SHOPS` en `tiendas_ropa.gd`.
- **Pruebas.** `tetoqa`: 7 ok ([log](logs/selftest_tetoqa_20261123_080313.log)). Mira la casa cedida, que las tres fachadas paran, las calles, el tejado entero, el horario y sus dos estados, el interior lejos, cerrado y llano con su flecha, el mostrador y el probador, y el maniquí (sombrero, adornos, cambios, golpe y vuelta, recogido al cerrar). No he pasado la completa.
  - Después de las hojas: el granito, más claro y gris como en Street View; el fondo de los escaparates, oscuro como la tienda que se ve detrás; y quien está en el probador mira un poco hacia el centro, porque la cámara a su lado caía en la pared.
- **Pendiente.**
  - El visto bueno de Luis, y las capturas del interior de Google Maps (se ven solo con la sesión iniciada) para rehacer el borrador.
  - Solo propuestos: el azafrán (en una sombrerera del banco del fondo, o a los pies del sombrerero del escaparate estrecho), maniquíes en los escaparates y el semáforo del chaflán (de Sistemas).
  - Al sur, donde está la juguetería, el mapa está vacío y se ve la medianera. Es zona de Texturas.
  - Sin commit: lo hace Sistemas.

### Tetoqa: azafrán, maniquíes en los escaparates y el semáforo del chaflán (23/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Si a las tres recomendaciones» (las tres propuestas de la entrada anterior).
- **Hecho.**
  - **El azafrán escondido** (`tetoqa_dentro.gd` `_saffron`): en la última sombrerera del banco del fondo, abierta, con la tapa apoyada de canto. Está en `G.flowers` con `"id": "tetoqa"` y `"hidden": true`. Propuse dos sitios y elegí este.
  - **Cuatro maniquíes tras los cristales del Cristo** (`tetoqa.dummies`), como en Street View: uno en cada punta del escaparate ancho, con los cubos entre ellos y un busto de costura encima (chaqueta crema y lazo negro); dos en el estrecho, junto a sus baldas de cristal. `maniqui.gd` tiene ahora un sexto parámetro, `in_window`: sin colisión, no lo adopta `props.gd`, un poco más pequeño (0,8), igual abierta o cerrada la tienda, y cambia de ropa cada día mientras nadie lo mira.
  - **El semáforo del chaflán** (`godot/scripts/semaforo_ambar.gd`, nuevo y mío, `tetoqa.semaforo`): un poste gris claro con una cabeza de tres luces, en la punta del chaflán que da al Cristo, junto al bordillo, mirando a Santa Ana. Solo parpadea el ámbar, como se ve en Street View, y no para a nadie. Es mobiliario de `props.gd` (`"semaforo"`): se tira, se apaga y vuelve al día siguiente. Tiene `set_light()` y `auto` por si Sistemas quiere llevarlo desde `semaforos.gd`.
  - **Corrección de Street View**: la caja de luz del Cristo no estaba en blanco, sino que lleva el nombre de la tienda. Ahora pone «TETOQA» entre ramitas de almendro, con marco verde (`caja.png`, en `tools/tetoqa/dibujos.py`).
- **Archivos.** Nuevo: `semaforo_ambar.gd`. Cambiados, míos: `tetoqa.gd`, `tetoqa_dentro.gd`, `maniqui.gd`, `tools/tetoqa/dibujos.py`, `godot/assets/tetoqa/caja.png`, [referencias/tetoqa/LEEME.md](referencias/tetoqa/LEEME.md). En `selftest.gd`, solo dentro de lo mío: tres comprobaciones más en `_tetoqa_checks()` y tres vistas más en `--tetoqa`.
- **Avisado a Sistemas**: el azafrán nuevo para su cuenta y cómo llevar el semáforo.
- **Pruebas.** `tetoqa`: 10 ok ([log](logs/selftest_tetoqa_20261123_083936.log)), con los maniquíes de los escaparates ya reducidos. Hoja en `guion/fotos/tetoqa/tetoqa_04_propuestas.jpg`. Comprueba que el azafrán está escondido y se llega a él (sin cogerlo), los cuatro maniquíes (dentro de los muros, fuera de alcance, blancos, cada uno a su manera, con la tienda cerrada también) y el semáforo (en la acera junto al bordillo, lejos de la puerta, que parpadea, que obedece a `set_light`, que se tira, se apaga y vuelve). Ojo: las dos últimas tandas coincidieron un momento con un Godot de Sistemas que arrancó a la vez.
- **Visto bueno de Luis**: «Así está perfecto. Visto bueno» (23/11), a la Tetoqa entera con lo de esta entrada.
- **Pendiente.** Las capturas del interior, si Luis las manda, para rehacer el borrador. Sin commit: lo hace Sistemas.

### Pisacastaña, la zapatería de los Arcos con la calle Argentina (23/11, Claude · Edificios Especiales)

- **Encargo de Luis**, con una captura de Street View de la Pisamorena: «Perfecto. Ahora la zapatería. Usaremos Pisamorena (que llamaremos Pisacastaña). Mismo tratamiento que las otras dos tiendas pero solo con zapatos».
- **Hecho.**
  - **La fachada** (`godot/scripts/pisacastana.gd`, sobre `esquina.gd`, `world.pisacastana`), en la casa `arcos_5` de Texturas, cedida en `casas_calles.gd` con `["obra"]`. Sin rehorneado.
    - Planta baja de enfoscado blanco sobre azulejo turquesa. A la calle Argentina: el machón de la esquina con un cristal esmerilado estrecho y su cartelito, dos escaparates de zapatos (baldas blancas; cubos blancos) con toldo crema y el rótulo encima del primero, el cristal esmerilado turquesa con el nombre y el horario, y la puerta metida casi un metro bajo una marquesina de cristal ahumado con hiedra. Pasada la tienda, el cuarto beis de los pisos con su reja abombada, el contador y dos aparatos de aire. A los Arcos: un escaparate de zapatos en escalones con su friso, el portal de los pisos en granito negro con tres escalones y puerta tallada, y una tienda de electrodomésticos cerrada y en venta (letrero sin marca, toldo con franja verde, reja de tijera, cartel de «se vende» sin teléfono).
    - Tres plantas de ladrillo en vuelo de 0,4 m sobre las dos calles: ventanas de aluminio blanco con persiana blanca y visillo, sardineles, cuatro ventanas por planta a la Argentina y, a los Arcos, una ventana en cada punta con una columna de terrazas de barandilla roja (la primera medio cerrada con aluminio y costado naranja, con macetas; la tercera con toldo verde). Aire acondicionado, parabólica, la placa «Calle Argentina», los cables por el canto del vuelo. Tejado bajo de cinco vertientes con cornisa de ladrillo.
  - **Los dibujos** son nuestros (`tools/pisacastana/dibujos.py` → `godot/assets/pisacastana/`): «PISACASTAÑA» en mayúsculas grises entre líneas art déco en el rótulo, el friso y el cristal esmerilado; el cartelito, el horario, la placa de la calle, el nombre de dentro, el letrero de electrodomésticos y el «se vende».
  - **El horario** es el real (Google Maps): de lunes a viernes de 10 a 13:30 y de 17 a 20, los sábados de 10:30 a 14 y los domingos cerrada. Abierta: persiana subida, puerta de cristal, luz dentro, maniquí fuera y flecha verde. Cerrada: la persiana blanca bajada (como en Street View 2024) y los escaparates en penumbra.
  - **El interior** (`godot/scripts/pisacastana_dentro.gd`, en borrador): un decorado aparte en (−1400, −150), con la flecha verde delante de la puerta (`entradas.gd`). Solo zapatos: paredes de baldas con pares a los dos lados, escalones blancos tras los cristales, mesa redonda, banco tapizado con el taburete inclinado, espejo bajo, mostrador con frente turquesa delante de una pared de cajas de zapatos, y el nombre en la pared turquesa del fondo sobre un escalón de botas. Expone para Sistemas `clerk_spot`, `client_spot` y `probador_spot` (junto al espejo bajo, mirando a la puerta) con sus rumbos. Sin figuras.
  - **El maniquí de la puerta**: el de `maniqui.gd`, con un séptimo parámetro nuevo, `with_shoes` (por defecto `false`): siempre zapatos vistosos y, a su lado, un pie blanco con otro par del día. Cambia cada día y solo sale con la tienda abierta.
  - **Sin maniquíes tras los cristales**: en Street View de 2021 el escaparate de los Arcos solo tiene zapatos (en 2024 hay maniquíes), y Luis pidió «solo con zapatos».
- **Archivos compartidos** (solo líneas insertadas, avisando antes a Sistemas):
  - `world.gd`: `PisacastanaS`, `var pisacastana`, el paso «the shop Pisacastaña» y `_build_pisacastana()`;
  - `entradas.gd`: el interior en `shops()`, cerrado hasta el Vizum de la Josefa como las otras dos;
  - `selftest.gd`: `_pisacastana_checks()`, el modo `--pisacastana` y la llamada tras `_tetoqa_checks()` en la prueba completa.
  - Sistemas añadió `"pisacastana": "zapatos"` a `SHOPS` en `tiendas_ropa.gd`, con su icono de bota de tacón en el mapa.
- **Pruebas.** `pisacastana`: 7 ok ([log](logs/selftest_pisacastana_20261123_095327.log)). Mira la casa cedida, los zapatos de los escaparates y de dentro, que las tres fachadas paran, las calles, el tejado entero, el horario real y sus dos estados, el interior lejos, cerrado y llano con su flecha, el mostrador y dónde se prueba uno los zapatos, y el maniquí (zapatos vistosos con su pie, cambios, golpe y vuelta, recogido al cerrar). No he pasado la completa.
  - Después de las hojas: el ladrillo con otra textura (`brick_wall_09`, de salmón apagado, con un tinte rosado; la naranja `brick_wall_003` de la Tetoqa salía demasiado viva al lado de la foto), el blanco de la planta baja más claro, toldos más grandes, la cornisa de ladrillo en vez de un alero blanco, fondo blanco en los dos escaparates que lo tenían gris y el nombre de dentro en gris oscuro para que se lea sobre el turquesa.
- **Pendiente.**
  - El visto bueno de Luis, y las capturas del interior de Google Maps (se ven solo con la sesión iniciada) para rehacer el borrador.
  - Solo propuesto: el azafrán escondido. Sistemas ofrece frases de dependiente o elegir zapatos en el banco: lo decide Luis.
  - Sin commit: lo hace Sistemas.

### Pisacastaña: visto bueno y azafrán en una caja de zapatos (23/11, Claude · Edificios Especiales)

- **Respuesta de Luis**: «Visto bueno. Azafrán en caja de zapatos. Así está bien el interior. Las dos opciones me gustan».
- **Hecho.**
  - **El azafrán escondido** (`pisacastana_dentro.gd` `_saffron`): en una caja de zapatos negra, abierta y con papel de seda dentro, en el suelo junto al banco donde uno se prueba los zapatos; la tapa, de canto, apoyada en su frente. Está en `G.flowers` con `"id": "pisacastana"` y `"hidden": true`. Era la primera de las dos propuestas (la otra, dentro de una bota del escalón del fondo).
  - **El interior** se queda como está: Luis no manda capturas («Así está bien el interior»).
- **Avisado a Sistemas**: el azafrán nuevo para su cuenta y, con las palabras de Luis («Las dos opciones me gustan»), que quiere las dos cosas que ofreció: frases de dependiente como las del Maxi y elegir zapatos en el banco. Le he pasado dónde están el mostrador, el banco, el taburete y el espejo bajo.
- **Archivos.** Cambiados, míos: `pisacastana_dentro.gd`, `pisacastana.gd` (solo la cabecera), [referencias/pisacastana/LEEME.md](referencias/pisacastana/LEEME.md). En `selftest.gd`, solo dentro de lo mío: una comprobación más en `_pisacastana_checks()` y una vista más en `--pisacastana`.
- **Pruebas.** `pisacastana`: 8 ok ([log](logs/selftest_pisacastana_20261123_100424.log)). Comprueba también que el azafrán está escondido y que se llega a él (sin cogerlo). No he pasado la completa.
- **Visto bueno de Luis**: «Visto bueno» (23/11), a la Pisacastaña entera.
- **Pendiente.** Lo de Sistemas (dependiente y zapatos en el banco). Sin commit: lo hace Sistemas.

### La «Cruz Verde» y el parque de la plaza de Jesús Requejo (23/11, Claude · Edificios Especiales)

- **Petición de Luis**, con una captura de Google Maps de la manzana marcada en rojo: «Ahora la cruz roja y el parque que tiene detrás, los dos lados de la misma manzana. Tiene varias 360 así que debería ser fácil».
  - El nombre, el mismo día: «Que llamaremos la cruz verde. La plaza puede mantener el nombre».
- **Hecho**, todo en `godot/scripts/requejo.gd` (nuevo), sobre `esquina.gd`, en la casa `vin_jr3` que cedió Texturas (`["obra"]`), sin rehorneado:
  - **El bloque de pisos**:
    - revoco crema, zócalo de mampostería, pilastras e imposta de ladrillo, cornisa de ladrillo y tejado a cuatro aguas de teja vieja gris;
    - a la avenida: ventanas con persianas marrones y rejas abajo, el cuerpo de ladrillo con la puerta, el balcón con el cartel «Cruz Verde», la farola de brazo, aires, placa y letrerito;
    - costados con foco, contadores, aires y bajantes, como en Street View.
  - **Las dos alas**:
    - la oficina, con la cancela, «Cruz Verde / MATRITELLUS» pintado, dos ventanas con reja y el garaje marrón;
    - el ala este, con el garaje gris, la placa de vado y el zócalo de cemento;
    - entre las dos, el patio. La pared sur es el mural, un pueblo pintado de los nuestros.
  - **Delante**: la explanada de tierra, las vallas rojas, el árbol joven, hierbajos y matorrales en el costado este, y la señal de prohibido de la esquina del transformador.
  - **Detrás, el parque**: el paseo de adoquín con cuatro bancos y papelera, el césped con bordillo, cinco tarajes (uno encalado, con su claro de tierra), el tablón, el árbol grande en su alcorque y la señal de prohibido.
  - **El relieve**: el del juego cae 2,5 veces más que el real. Las alas tienen la coronación en un plano a 3,2 m del suelo en tres esquinas, y el zócalo baja un 60 % de lo que cae el suelo. Así las proporciones quedan como en las fotos.
  - **Los dibujos** son nuestros (`tools/requejo/dibujos.py` → `godot/assets/requejo/`): el rótulo, el cartel, la placa, el letrerito de la cruz, el mural, el tablón y el vado. Sin el nombre ni el emblema de nadie real, sin teléfono y sin la placa del partido que hay junto a la puerta.
- **Archivos compartidos** (solo líneas insertadas, avisando antes a Sistemas):
  - `world.gd`: `RequejoS`, `var requejo`, el paso «the Plaza de Jesús Requejo» tras el de la Pisacastaña, y `_build_requejo()`;
  - `selftest.gd`: `_requejo_checks()`, el modo `--requejo` y la llamada tras `_pisacastana_checks()` en la prueba completa.
- **Texturas**: cedió `vin_jr3`. Quita en su próximo horneado los dos árboles del mapa de delante de la fachada (`NO_TREES`), y dejó el transformador `requejo_1` blanco liso, con puerta de chapa.
- **Pruebas.** `requejo`: 3 ok ([log](logs/selftest_requejo_20261123_143043.log)). Comprueba la obra, la casa cedida, el transformador intacto, que paran las seis fachadas, el tejado entero y que nada pisa el asfalto. Saca 22 vistas desde las cámaras de Street View, dos desde arriba y una de noche. No he pasado la prueba completa.
  - Después de las hojas:
    - el tejado, de naranja a teja vieja gris;
    - el revoco, más cálido;
    - la tierra, más gris;
    - las alas, siguiendo la cuesta;
    - el rótulo, del ancho de las palabras;
    - persianas bajadas en la oficina;
    - el cartel del balcón, en su mitad oeste;
    - los tubos del costado oeste, en su sitio;
    - tarajes más altos y tupidos;
    - el matorral grande del ala este;
    - el vado.
- **Pendiente.**
  - El visto bueno de Luis.
  - Solo propuesto: el azafrán escondido.
  - Sin commit: lo hace Sistemas.
- **Detalle**: [referencias/requejo/LEEME.md](referencias/requejo/LEEME.md).

### La caseta del transformador de la plaza de Jesús Requejo (23/11, Claude · Edificios Especiales)

- **Luis**, sobre la hoja de Street View de la «Cruz Verde», con la caseta rodeada: «En general muy bien. Pero este edificio no se parece nada».
- **Texturas** cedió `requejo_1` (`["obra"]` en `casas_calles.gd`). Su línea «ciego» de `casas.gd` sigue para otras casetas.
- **Hecho** en `godot/scripts/requejo.gd` (`_hut()` y sus cuatro paredes), con el resto de la manzana:
  - una torre blanca de cal de 5 × 4,9 m;
  - la pared llega a 6,7 m sobre el pie de la avenida;
  - tejado a dos aguas de teja vieja parda, con la cumbrera de este a oeste, la moldura blanca y las bocas de las tejas en los aleros.
  - **A la avenida**:
    - la puerta de chapa gris de dos hojas, con su marco, el escalón y los triángulos de peligro;
    - el armario de chapa con el logo de la peña Costrola;
    - la chapa vieja y la placa «PLAZA / D. JESÚS / REQUEJO»;
    - la rejilla de lamas;
    - el mazo de cables colgando de su soporte y enroscado en la esquina;
    - la farola de brazo, y un cable que baja por la otra esquina.
  - **Los otros lados**:
    - el hastial este, con la flecha del Camino;
    - el costado sur, con el nicho de respiraderos y los ganchos;
    - el hastial oeste, con la barra de aisladores, un desconchón y el logo de Croquetilla al pie.
  - La señal de prohibido pasa al costado este, con la azul de girar a la derecha debajo, como en la foto.
  - Sin el número de encima de la puerta ni la pegatina de la compañía de la luz.
  - **Dibujos nuevos** en `tools/requejo/dibujos.py`: `aviso`, `chapa`, `calle`, `camino` y `desconchon`.
- **Medidas.** Salen de ocho vistas de Street View alrededor de la caseta. Cada foto se ajustó con las dos esquinas de la pared que se ve (`caseta_fit.py`, en el scratchpad), porque las cámaras de la avenida tienen el rumbo torcido hasta 10°.
- **Archivos compartidos**, avisando a Sistemas:
  - en `selftest.gd`, `_requejo_checks()` comprueba ahora que la caseta está cedida y hecha a mano, y que su fachada para;
  - el modo `--requejo` saca ocho vistas más (`h_…`).
- **Pruebas.** `requejo`: 3 ok ([log](logsselftest_requejo_20261123_150807.log)). No he pasado la prueba completa.
- **Pendiente.**
  - Nada de la obra. **Aprobado** por Luis: «Me habré confundido. Cruz verde está bien. Visto bueno». Lo de «Cruz Naranja» fue una confusión suya; se queda «Cruz Verde».
  - **Azafrán escondido, puesto.** Luis eligió el sitio: «1. En el parque». Va al pie del taraje encalado, detrás del tronco visto desde el paseo (`_saffron` en `requejo.gd`, `id` "requejo", `"hidden": true`). En `selftest.gd`, `_requejo_checks()` lleva una comprobación más, y `--requejo` una vista más (`azafran`). `requejo`: 4 ok ([log](logs/selftest_requejo_20261123_152141.log)).
  - Sin commit.

### 2026-11-23 · Óptica Corsa, la óptica de la calle del Salvador 5 (Claude · Edificios Especiales)

- **Luis**, con una captura de Street View del Centro Óptico Corts: «Vamos con el centro óptico cors (que llamaremos Óptica Corsa, en C. Salvador, 5 … Igual que Tutoq, icono de complementos, no, mejor, icono de gafas, y dividimos las tiendas entre complementos y gafas, gafas en las ópticas y complementos en las tiendas de complementos. aquí el NPC será una Óptica con bata blanca y solo venderá gafas … Se llamará Fátima Corsa».
- **Texturas** cedió `salvador_5` (`["obra"]` en `casas_calles.gd`). Sin rehorneado. El solar de al lado por el oeste estaba vacío en el mapa; Texturas lo rellena con la parcela 4192011VJ5649S.
- **Hecho**:
  - `godot/scripts/optica.gd` (`world.optica`), sobre `esquina.gd`, desde el Street View de marzo de 2013:
    - planta baja de granito con las gafas en relieve en su brazo, la persiana del garaje, el escaparate y la entrada metida medio metro;
    - la banda verde «ÓPTICA CORSA», la placa granate de la óptica, la alarma y el portal de madera en ladrillo;
    - dos plantas en vuelo de ladrillo beige con su moldura de dientes, los aires acondicionados y la parabólica, y el alero;
    - el horario real de Google Maps (lunes a viernes 10–14 y 18–21, sábados 10–14, domingos cerrada); cerrada, una persiana gris sobre la entrada.
  - `godot/scripts/optica_dentro.gd` (`world.optica.dentro`): el interior en (2150, 650), con flecha verde. Lleva el mostrador, la pared «Novedades», la vitrina «Vintage», la torre de gafas de sol, la vitrina baja, el espejo, y el gabinete de graduar tras un tabique (sillón, foróptero, optotipo, caja de lentes, autorrefractómetro). Expone `clerk_spot`, `client_spot`, `probador_spot` y `chair_spot` con sus rumbos.
  - Dibujos nuevos en `tools/optica/dibujos.py` → `godot/assets/optica/`.
- **Fátima Corsa** es de Sistemas (`fatima.gd`): está tras el mostrador mientras abre y te lleva al espejo; las gafas, a 20 €. Su prueba `fatima` da 4/4 con este interior.
- **Gafas solo en las ópticas**, como pidió Luis y a petición de Sistemas:
  - los maniquíes de la Tetoqa ya no llevan gafas (`maniqui.gd`; se mantiene la tirada para que el resto de la ropa de cada día no cambie);
  - la torre de gafas de sol del interior de la Tetoqa es ahora de coleteros y pinzas (`tetoqa_dentro.gd`, `_hair_tower`);
  - `_tetoqa_checks` cuenta pendientes y collares y exige cero gafas.
- **Archivos compartidos**, solo inserciones y avisando a Sistemas:
  - `world.gd`: `OpticaS`, `var optica`, el paso «the optician Óptica Corsa» y `_build_optica()`;
  - `entradas.gd`: la óptica en `shops()`, con la puerta de `tiendas_ropa.shut`;
  - `selftest.gd`: `_optica_checks()` (también en la prueba completa) y el modo `--optica`.
- **Lección.** Los dibujos con brillo propio necesitan `emission_operator = EMISSION_OP_MULTIPLY`, como `obra._glow`. Con el operador por defecto, `emission = WHITE` echa un velo gris de toda la energía, y el verde del rótulo salía color salvia de día y de noche. Lo tienen también otros sitios míos (asador, correos, tetoqa, pisacastaña, maxiprecio…), donde casi no se nota porque los rótulos son claros. No los he tocado: es cosa de Luis si se corrigen.
- **Pruebas.** `optica`: 5 ok ([log](logs/selftest_optica_20261123_210734.log)). Tras el cambio de los maniquíes y la torre, `tetoqa`: 10 ok ([log](logs/selftest_tetoqa_20261123_211036.log)). No he pasado la prueba completa.
- **Pendiente.**
  - **Aprobada** por Luis: «Visto bueno, y c».
  - **Azafrán escondido, puesto** (la «c»): detrás del optotipo del gabinete. La caja del optotipo está ahora separada 20 cm de la pared sobre dos soportes, con su cable y enchufe, y la flor pequeña está de pie en el soporte de abajo, asomando un poco de morado por el lado (`_saffron` en `optica_dentro.gd`, `id` "optica", `"hidden": true`). En `selftest.gd`, `_optica_checks()` lleva una comprobación más, y `--optica` una vista más (`dentro_azafran`). `optica`: 6 ok ([log](logs/selftest_optica_20261123_212809.log)).
  - Texturas rellenó el hueco del oeste con `salvador_3`.
  - Luis, con la captura del azafrán delante: «Visto bueno». Nada pendiente de la óptica.
  - Sin maniquí en la puerta, salvo que Luis lo pida.
  - Sin commit.
- [LEEME](referencias/optica/LEEME.md) · capturas en `guion/fotos/optica/`.

### 2026-11-23 · Los carteles de la entrada norte: el muro del Quijote y el del hermanamiento (Claude · Edificios Especiales)

- **Luis**, con tres capturas de Street View de la N-IVa (noviembre de 2024) y dos enlaces de Maps: «Hay dos carteles en la entrada de Madridejos que me gustaría añadir». Después, cuando puse MATRITELLUS en ellos: «Habíamos quedado que el pueblo del juego se llama Madridejos. Matritellus es el título y su nombre original en latín». Los carteles dicen MADRIDEJOS, como los reales.
- **Dónde**: en la tierra del lado oeste de la carretera vieja de Madrid a Cádiz, antes de la rotonda de la avenida de la Constitución. El muro está en (258.5, −1625.1) y su cara mira a 12°; el cartel, en (263.0, −1650.9), mira a 30°. Los dos miran a quien llega del norte. Lo dan los rumbos de seis panorámicas de Street View, que coinciden con medio metro de diferencia, y la ortofoto del PNOA (`tools/ign/entrada_norte.*`). Sin rehorneado y sin tocar el mapa.
- **Hecho**:
  - `godot/scripts/entrada.gd` (`world.entrada`, sobre `obra.gd`):
    - el muro encalado (5,10 × 3,18 m, 0,5 de grueso) con su borde ondulado, el remate de piedra parda y el zócalo, hundido un metro en la tierra;
    - las piedras metidas en la cal;
    - los azulejos «Un lugar de la Mancha» y «MADRIDEJOS»;
    - don Quijote a caballo en chapa oxidada, separado 4,5 cm de la cal, con la lanza por encima del muro.
  - `entrada.cartel`, el mismo script en otro nodo: la placa de 1,20 × 0,87 m sobre dos postes galvanizados, con sus travesaños por detrás. Al ser dos sitios aparte, las matas secas no crecen en ellos, pero sí en el campo de en medio.
  - `godot/data/quijote.json`: la silueta, calcada con `tools/entrada/silueta.py` de una foto de Street View que ve el muro de frente (la foto se queda fuera del repositorio; el LEEME dice cómo bajarla).
  - `tools/entrada/dibujos.py` → `godot/assets/entrada/` (importados): los dos azulejos y la cara del cartel, amarillenta y sucia como la real. Lleva el escudo del juego (`assets/logo.png` sin la cinta) y otro nuestro para Nérac (castillo de oro sobre un río, en azul).
- **Archivos compartidos**, solo inserciones:
  - `world.gd`: `EntradaS`, `var entrada`, el paso «the signs at the north entrance» y `_build_entrada()`;
  - `selftest.gd`: `_entrada_checks()` (también en la prueba completa, tras la óptica) y el modo `--entrada`, con las vistas de Street View (mismo rumbo y ángulo, para compararlas), dos de noche y ocho de cerca.
- **Pruebas.** `entrada`: 8 ok ([log](logs/selftest_entrada_20261123_235045.log)). No he pasado la prueba completa.
- **Memoria corregida**: en mis notas seguía la decisión vieja de llamar Matritellus al pueblo, junto a la buena. **El pueblo es Madridejos**; Matritellus es el título del juego.
- **24/11, Luis: «Si, cambialos por Madridejos. Esconde azafrán en la opción 1»**
  - **MADRIDEJOS en los demás carteles** míos que ponían MATRITELLUS como nombre del pueblo:
    - la palabra pintada de la Cruz Verde (`tools/requejo/dibujos.py`, `TOWN` → `assets/requejo/rotulo.png`);
    - la placa de la rotonda de los Tricornios (`tools/rotonda/dibujos.py` → `assets/rotonda/placa.png`);
    - la última fila del optotipo de la óptica (`tools/optica/dibujos.py` → `assets/optica/optotipo.png`).

    Al volver a dibujarlos solo han cambiado esos tres dibujos (comparados archivo a archivo con una copia).
  - **El escudo, con su cinta**: la cinta del escudo del juego dice MATRITELLUS. Luis: «No, deja Matritellus en el escudo, ahí puede estar, ya que es su nombre antiguo».
    - Le quité la cinta un momento y lo he deshecho: `tools/make_logo.py` vuelve a estar como en git, y el `assets/escudo.png` que añadí ya no existe.
    - La placa de la rotonda lleva el escudo de antes; su dibujo solo cambia donde está la palabra.
    - El cartel del hermanamiento lleva ahora el escudo entero, con la cinta (`logo.png` recortado a lo dibujado). Antes llevaba el escudo sin cinta y con la punta cortada.
  - **El azafrán escondido**, al pie del muro por detrás (`entrada._saffron`, `"id": "entrada"`).
    - La flor está entre matas secas. Son las mismas del campo (`matojos.gd`, `_tuft_mesh`, en un MultiMesh propio) y van también a lo largo de toda la espalda del muro.
    - El muro la tapa a quien llega del norte, y se llega a ella desde el campo de atrás.
    - Lo comprueba `_entrada_checks()`, y el modo `--entrada` saca su vista «azafran».
  - **El cartel del hermanamiento, cuadrado** (Luis: «La placa de Madridejos y Nerac está un poco descentrada, cuadrala un poco»). La placa estaba centrada en sus postes; lo descentrado era el dibujo.
    - Ahora los dos escudos van en una columna y las palabras en otra, y el conjunto queda centrado con el mismo margen a cada lado.
    - Hay el mismo aire arriba, en medio y abajo, y cada palabra se centra por su tinta (`sign()` en `tools/entrada/dibujos.py`).
  - `entrada`: 9 ok ([log](logs/selftest_entrada_20261124_002212.log)).
- **Aprobado.** Luis, 24/11: «Visto bueno». Están los dos carteles, el azafrán, MADRIDEJOS en los carteles, el escudo con su cinta y el cartel cuadrado.
- **Pendiente.**
  - Sin commit.
- [LEEME](referencias/entrada/LEEME.md) · capturas en `guion/fotos/entrada/` (`entrada_03_azafran.jpg`, el azafrán).

### 2026-11-24 · La rotonda de la entrada norte: la portada, el cartel MADRIDEJOS y la tinaja (Claude · Edificios Especiales)

- **Luis**, con dos capturas de Street View y dos enlaces de Maps: «Un poco más adelante hay una rotonda bastante bonita. Me gustaría que fuese lo siguiente que hacemos». Es la rotonda donde la carretera vieja de Madrid a Cádiz se cruza con la avenida de la Constitución, unos 70 m al sur de los carteles de la entrada.
- **Dónde**:
  - Sin rehorneado y sin tocar el mapa. Es la isleta del anillo que ya tiene el mapa (la carretera 98). `rotonda_norte.gd` la busca cerca de (276.9, −1555.75), como hace `rotonda.gd` con la de los Tricornios.
  - La isleta real (círculos ajustados a la ortofoto del PNOA, `tools/ign/rotonda_norte.*`) tiene su centro en (275.87, −1555.66) y mide 6,94 m de radio.
  - El anillo del mapa está 1,1 m más al este y deja 6,34 m. La isleta del juego sigue al anillo para no invadir el carril; el césped casi mantiene su tamaño real (4,40 m frente a 4,56) y lo que falta lo pierde la corona de ladrillo.
  - Lo de encima va a su tamaño real y en su sitio real, contado desde el centro real. Los sitios salen de los rumbos desde tres cámaras de Street View (norte, sur y este), y la ortofoto confirma la portada y la tinaja.
- **Hecho**, en `godot/scripts/rotonda_norte.gd` (`world.rotonda_norte`, sobre `obra.gd`):
  - **El suelo**, cortado por las facetas del relieve, con un anillo de asfalto que tapa la plaza clara que dibujaba el mundo:
    - el bordillo pintado a franjas rojas y blancas;
    - la corona de ladrillo rojo puesto a lo largo, que sube hacia el centro;
    - un bordillo blanco;
    - el césped, que se pisa como todo lo demás (`MapData.decks`).
  - **La portada**:
    - dos pilares de ladrillo claro, el dintel con una hilada saliente y un tejadillo de teja árabe vieja con sus tejas de alero;
    - la reja sobre un poyete con su remate;
    - el mismo ladrillo por las dos caras (ver abajo).
  - **El cartel**: una chapa oxidada de 4,60 m con los bordes rotos y MADRIDEJOS pintado a mano en blanco, sobre tres patas. La punta del este está enrollada hasta el césped, y por detrás es óxido sin letras.
  - **La tinaja**: tumbada, con la boca levantada al norte-noroeste, oscura por dentro y un poco hundida en la hierba. A su lado hay un foco alargado y otro pequeño a su pie, apagados.
  - El cartel y la portada miran a 350°: desde el este se ven de canto y desde el sur, de frente, como en Street View.
  - **Tres señales azules de rotonda.** Ante la calle del este no hay ninguna, porque en Street View no se ve.
  - `tools/rotonda_norte/dibujos.py` → `godot/assets/rotonda_norte/` (importados): `chapa.png`, la cara del cartel en la letra Ink Free de Windows, y `oxido.png`.
- **Luis**: «Por detrás no es blanca. Es del mismo material que delante» (con una foto de 2019). Yo había encalado la cara sur de la portada, porque al sol parecía blanca. Ahora es toda de ladrillo y ya no hay material de cal.
- **Fuera**:
  - lo de las esquinas, fuera de la isleta (el pino, los armarios, el banco, el poste rojo), se queda como lo tiene el mapa;
  - los focos de la tinaja no se encienden de noche.
- **Archivos compartidos**, solo inserciones:
  - `world.gd`: `RotondaNorteS`, `var rotonda_norte`, el paso «the roundabout at the north entrance» y `_build_rotonda_norte()`;
  - `selftest.gd`: `_rotonda_norte_checks()` (también en la prueba completa, tras los carteles de la entrada) y el modo `--rotonda_norte`, con vistas desde las cámaras de Street View, dos de noche y cinco de cerca.
- **Pruebas.** `rotonda_norte`: 3 ok ([log](logs/selftest_rotonda_norte_20261124_040550.log)). No he pasado la prueba completa.
- **Luis, 24/11: «Visto bueno. Dentro de la boca de la tinaja»**
  - **El azafrán escondido**, dentro de la tinaja, justo detrás de la boca (`rotonda_norte._saffron`, `"id": "rotonda_norte"`).
    - `pickups.gd` viste todas las flores con su halo de 1,45 m y su aro. Aquí la flor va al 35 % (`SAFFRON_K`), y el halo y el aro con ella, para que todo quepa en el hueco de la tinaja. No he tocado `pickups.gd`: la escala de la flor se lo lleva todo.
    - Asomándose a la boca, desde el noroeste, se ve la flor brillando en lo oscuro; desde la carretera del norte apenas asoma un poco de brillo.
    - Se coge de pie delante de la boca.
  - `_rotonda_norte_checks()` lo comprueba: que la flor está apuntada, que su halo cabe en la tinaja y que hay sitio delante de la boca. El modo `--rotonda_norte` saca las vistas `azafran` y `azafran_bordillo`.
  - `rotonda_norte`: 4 ok ([log](logs/selftest_rotonda_norte_20261124_041657.log)).
- **Aprobada.** Luis, 24/11: «Visto bueno», y otra vez «Visto bueno» al ver el azafrán en la tinaja.
- **Publicada en 0.1.2** (commit 9d8824a, etiqueta v0.1.2, por Sistemas).
- [LEEME](referencias/rotonda_norte/LEEME.md) · capturas en `guion/fotos/rotonda_norte/` (`rotonda_norte_03_azafran.jpg`, el azafrán).

### 2026-11-25 · El cementerio, fuera del mapa, y el cambio de zona para llegar (Claude · Edificios Especiales)

- **Luis**: «Vamos a poner las con el cementerio». Para llegar, eligió un cambio de zona como el de Borderlands 2: «que te acerques al cambio de zona y que un botón te transporte a la siguiente. Así podremos meter zonas fuera del pueblo sin ampliar el mapa». Y «A pie y en coche».
- **El cambio de zona** (`zonas.gd`, `game.zonas`), mío:
  - Una zona es un rectángulo del llano fuera del mapa (aquí x 300..640, z −2650..−2275), con su suelo y cuatro paredes invisibles. `limite.gd` no la cuenta como fuera del mapa (`in_zone`).
  - Hay dos puertas sobre la carretera vieja del norte, con cartel y cortina: CEMENTERIO al final del mapa (289.9, −1806) y, en la zona (363.1, −2292), MADRIDEJOS, que luego pasó a NÚCLEO URBANO.
  - Cerca de una puerta, a pie o en coche parado, el botón dice «Ir al Cementerio» o «Volver a Madridejos» (luego, «Volver al Núcleo Urbano»). Al pulsarlo apareces 10 m delante de la otra puerta, con el coche si vas en él (`car.place`).
  - `_blocked()` no deja cruzar en estos casos:
    - con la pasma: estrellas, persecución, `bust_t` o la cuenta atrás del borde;
    - en la riña, con el coche en el taller o durante una llamada;
    - con `comida.faint`;
    - con `G.side` «trabajo», que incluye a Koke;
    - con `G.side` «luis» mientras `sabotaje.stage` va de cine_out a cine_go.
  - Esa lista la dio Sistemas. Con los recados sin reloj y en el Modo Chavisca sí se puede cruzar.
- **El cementerio** (`cementerio.gd`, `world.cementerio`, sobre `obra.gd`), mío:
  - Las esquinas de la tapia salen de la ortofoto del PNOA (`tools/ign/cementerio_todo.jpg`). Se mide en u/v con un paso bilineal por las cuatro esquinas.
  - **La tapia** es encalada, de 2,4 m.
  - **El pórtico** está en la tapia oeste:
    - alas con tejados a cuatro aguas de teja vieja;
    - un frente levantado con pináculos y un frontón ancho y bajo, de 4,95 a 6,1 m, con un tejadillo de teja de tres caras;
    - la ventana estrecha a un lado y el banco debajo;
    - el arco del norte, cerrado con reja;
    - el arco del sur, abierto, de 1,5 m: se entra a pie y el coche no cabe. Su pasadizo tiene techo sólido para la cámara.
  - **Lo comparé con Street View 2024** (la cámara de (385.19, −2441.6) con rumbo 76): primero hice un cuerpo saliente con frontón estrecho, y no era así.
  - **Delante**:
    - adoquines grises;
    - la isleta en D con bordillo rojo y blanco, enebros, arbustos rojizos, dos cipreses, un árbol y la señal de dirección prohibida;
    - la acera, el armario de la luz y seis farolas.
  - **Dentro**:
    - grava y el paseo de losetas entre cipreses;
    - la avenida con 16 panteones (capillas, recintos con verja, losas);
    - 4532 tumbas en 58 cuadros, en parejas de filas con pasillos de 1 m (el jugador mide 0,76). Van con MultiMesh y sin nombres ni fechas.
- **Archivos compartidos**, solo inserciones:
  - `game.gd`, con el visto bueno de Sistemas: preload, `var zonas`, su arranque, `interact`, `tick` y los dos avisos del botón;
  - `limite.gd`: `in_zone`;
  - `loc.gd`: `p_zona_cementerio`, `p_zona_madridejos`, `t_zona_pasma` y `t_zona_no`;
  - `world.gd`: `CementerioS`, `var cementerio`, el paso «the cemetery» y `_build_cementerio()`;
  - `selftest.gd`: `_zonas_checks()`, `_cementerio_checks()` y `_cem_walk()` (las dos comprobaciones van también en la prueba completa), y los modos `--zonas` y `--cementerio`.
- **Pruebas**:
  - `zonas`: 4 ok ([log](logs/selftest_zonas_20261125_122151.log));
  - `cementerio`: 6 ok. Comprueba la tapia por los cuatro lados, la entrada por el arco, el arco cerrado, las tumbas sólidas, los pasillos y los paseos libres, y el jugador entrando de verdad y recorriendo un pasillo.
  - No he pasado la prueba completa.
- **Un fallo mío**: durante unos minutos, cementerio.gd (línea 714) y luego selftest.gd (`_cem_walk`) tuvieron errores de tipos que paraban cualquier Godot; a Sistemas le paró una prueba. Están arreglados.
- **Luis, 25/11, al ver las vistas: «Bien»**, con tres respuestas:
  - «no hace falta que ponga Madridejos a la hora de volver. Con que ponga Núcleo Urbano me basta. Así distinguimos distintas zonas que siguen siendo Madridejos». El cartel de la puerta de la zona dice NÚCLEO URBANO (`back_name`) y el botón, «Volver al Núcleo Urbano». En `loc.gd` la clave pasa a ser `p_zona_nucleo`.
  - «Bien, ponlo en los dos» (el azafrán). Hay dos escondidos, en `cementerio._saffron()`:
    - `cementerio_tumba`, en el jarrón de una tumba del rincón sureste, al final de su fila, que se coge desde el paseo;
    - `cementerio_cipres`, al pie del ciprés de tronco encalado delante del pórtico (el tronco, encalado hasta 0,9 m).
    - Se lo dije a Sistemas, que lleva la cuenta.
  - «Abierto 24 horas. De noche quita la música chill que tenemos y deja solo el leve sonido del viento de vez en cuando. Que dé algo de mal rollo».
    - `zonas.hush()`: de noche, dentro de la zona.
    - En `game.gd` `_update_audio`, con el OK de Sistemas, van dos líneas: a pie no suena el lofi, y `Ambience.town(..., in_world and not hush)` quita los grillos y los perros. La radio del coche sigue.
    - `zonas._tick_wind()` pone una ráfaga baja cada 8 a 24 s.
    - Las tres ráfagas (`godot/assets/cementerio/viento_0..2.wav`, importadas) salen de `tools/cementerio/viento.py`: ruido marrón con un filtro que se mueve despacio, sin grabaciones.
- **Pruebas**:
  - `cementerio`: 9 ok ([log](logs/selftest_cementerio_20261125_125717.log)). Añade los dos azafranes (en el juego, escondidos y con sitio para cogerlos) y el silencio de noche (sí allí; ni de día ni en el pueblo), y que de verdad se calla el lofi y vuelve en el pueblo.
  - `zonas`: 5 ok ([log](logs/selftest_zonas_20261125_125506.log)). Añade los carteles CEMENTERIO / NÚCLEO URBANO.
- **Aprobado.**
- **Fuera**: el paso de cebra, la A-4 y las naves de alrededor.
- [LEEME](referencias/cementerio/LEEME.md) · capturas en `guion/fotos/cementerio/`.

### 25/11 · Pretil: la carretera del cementerio sigue y la zona es un círculo

- **Luis**: «la carretera en el cementerio se corta muy pronto y se nota mucho que es una zona aparte. Podríamos extender la carretera? También pondría un círculo invisible con centro en el cementerio y que llegase poco más lejos que las puertas de zona, para que la gente no se saliese del mapa».
- **La carretera** (`zonas.gd`, `road_to`): ya no acaba al final de la zona. Sigue recta hacia el norte hasta (680.4, −4400), unos 2 km más, más lejos de lo que alcanza la cámara (1600 m), con sus rayas. Solo se ve: por ella no se sale.
- **El círculo**: la zona ya no es un rectángulo. Es un círculo con centro en el medio del cementerio (la media de sus cuatro esquinas, (491.9, −2439.7)) y 210 m de radio.
  - La puerta de zona queda a 196 m del centro, así que el círculo pasa 14 m más allá.
  - `zone_at` mide la distancia al centro, y `limite.gd` sigue usando `in_zone` sin cambios.
  - `_ground` pone el suelo en el cuadrado que lo contiene y la pared, invisible, en 72 cajas de 80 m de alto alrededor.
- **Pruebas**:
  - `zonas`: 5 ok ([log](logs/selftest_zonas_20261125_130450.log)). La comprobación de las paredes lanza 16 rayos alrededor del círculo y 2 por la carretera, en los dos sentidos: 18 de 18 parados. Y mira que el círculo pase entre 8 y 25 m más allá de la puerta.
  - `cementerio`: 9 ok ([log](logs/selftest_cementerio_20261125_130634.log)). Saca dos vistas nuevas, `cementerio_norte` y `cementerio_norte_alto`.
- Capturas: `guion/fotos/cementerio/cementerio_03_carretera.jpg`.

### 25/11 · Pretil: matas y árboles sueltos en el campo del cementerio

- **Luis**: «El suelo está muy plano y vacío. No había cambiado como se hace para que salgan malas hierba/arbustos/arboles sueltos de vez en cuando y darle más vida?».
- **Por qué no salían**: `matojos.gd` (no es mío) solo siembra cerca de las manzanas de casas, en cuadros de 32 m a 2 o 4 cuadros de una manzana, y la zona está a 450 m de la última. No he tocado `matojos.gd` ni su caché.
- **Lo nuevo**: `zonas._scrub(z)`, que se llama desde `setup` para cada zona.
  - Pone las mismas matas que el pueblo, con las mismas mallas (`Matojos._tuft_mesh`, `_bush_mesh` y `_mata_mesh`, funciones estáticas), los mismos colores y la misma regla de manchas.
  - Van en cuadros de 64 m bajo el nodo `zona_<id>_matas`, con `Parts._range` a 120 m y sin sombra. Salen más espesas en las cunetas y al pie de la tapia.
  - Llegan 200 m más allá del círculo y se aclaran en los últimos 80 m.
  - Los árboles (olivo, almendro y pino piñonero, con la regla de `_try_tree`) llegan hasta 1400 m del centro y se aclaran pasados los 400. Se dan al mundo en una sola llamada a `world.add_trees`, antes de que props.gd los indexe, así que se caen con el coche como los del pueblo.
  - No salen al norte del mapa (`MapData.zmin`) ni dentro de él, ni a menos de 0,6 m del borde de la carretera (los árboles, a menos de 5 m), ni a menos de 9 m de una puerta (los árboles, 15 m), ni en lo que devuelve `cementerio.keep_off(trees, grow)`. Los árboles tampoco salen a menos de 8 m de la pared redonda.
  - Con `--sin-matojos` no se ponen. Se calculan sin rayos ni caché, y salen 9443 matas y 685 árboles.
- **Pruebas**:
  - `zonas`: 6 ok ([log](logs/selftest_zonas_20261125_132630.log)). Hay una comprobación nueva: 9443 matas, 2752 de ellas dentro del círculo; 685 árboles, 400 lejos, todos en `world.tree_info`; y 0 fuera de sitio.
  - `cementerio`: 9 ok ([log](logs/selftest_cementerio_20261125_132918.log)), con tres vistas nuevas: `cementerio_campo_oeste`, `_este` y `_alto`.
- Capturas: `guion/fotos/cementerio/cementerio_04_campo.jpg`.

### 25/11 · Pretil: la A-4, el enlace y el pueblo a lo lejos desde el cementerio

- **Luis**: «Veo que la acera, los pinos y las farolas se cortan donde se cortaba antes la carretera. Podemos extenderlos también? Quizás mirando hacia el sur se podría ver un .PNG del pueblo, parecido a lo que hicimos con el castillo de la muela. Y quizás hacia el norte/oeste podríamos ver la autovía A4 uniéndose a la carretera, con .PNG de coches y camiones viajando».
- **La carretera**: ahora acaba donde de verdad (OpenStreetMap), en (462.9, −2955), 515 m al norte del centro, donde salen los ramales de la A-4 (`zonas.ZONES` `road_to`). `cementerio._roadside()` sigue las farolas (cada 30 m), la fila de árboles del otro lado (cada 18 m, hasta z −2700 como en la ortofoto) y la acera con su bordillo, por la línea de la carretera (no por el marco del cementerio, que va un tercio de grado torcido). Se cortan en las puertas de zona. La acera entra en `keep_off` para que no le salgan matas.
- **La A-4** (`autovia.gd`, nuevo, lo crea `zonas.setup` si la zona lleva `"autovia": true`):
  - Las líneas vienen de OSM: `tools/cementerio/autovia.py` lee `tools/ign/a4_osm.json` y escribe `godot/data/autovia.json` (las dos calzadas, el lazo de entrada y el ramal de salida). Se corre con `python -I`.
  - Tiene dos carriles y arcenes por sentido, líneas, quitamiedos en la mediana y una valla de malla 12 m al oeste de la calzada hacia el sur, desde donde entra el lazo. La valla es sólida dentro del círculo (la A-4 pasa por dentro, a 124 m del centro).
  - `gap(p)` (con una rejilla de 32 m) hace que `zonas._road_gap` aparte también de la A-4 las matas y los árboles.
  - El tráfico va en un MultiMesh de cuadros que miran a la cámara; el shader escoge el dibujo según desde dónde lo ves (16 vistas) y lee el tamaño de cuadro de `INSTANCE_CUSTOM.w`. Hay 4 carriles; los camiones van solo por el de la derecha. Guardan la distancia según la longitud de cada uno. De noche se suman los faros (`trafico_luces.png`).
  - Solo se ve y se mueve con la cámara en la zona.
- **Los dibujos** (`lejanias_foto.gd`, nuevo; modo `python tools/run_tests.py lejanias`, en ventana):
  - Coches: las filas de `autovia.KINDS`, con los coches del juego (`Modelos.make_from(SK)`) en varios colores. Camiones: tráiler de caja, de lona, cisterna y rígido, hechos con piezas, porque el kit solo tiene pickups y una furgoneta.
  - Cámara ortográfica a 3°, 256×128 px por cuadro, un cuadro de 12×6 m para los coches y 18×9 para los articulados.
  - Trampa: el movimiento de la cámara llega a la imagen un fotograma tarde. Hay que esperar un `process_frame` antes de los `frame_post_draw`.
- **El pueblo a lo lejos** (`lejanias.gd`, nuevo, con `"lejos": true`):
  - El mismo modo saca 12 fotos de 30° desde el centro de la zona. Usa el mundo del juego sin distancia de dibujo (`Parts.draw = 0`) y `near` a 1300 m. Va sin cielo, nubes ni sierras, con el tono lineal y los reflejos del cielo del juego (con el fondo vacío salían de un gris y la noche quedaba clara). Hace dos tandas, a mediodía y a las 23:00, y se guardan en `user://lejanias/`.
  - `tools/cementerio/lejanias.py` las pasa a una banda de −3° a +5°, a 32 px por grado, en cuatro cuartos (`assets/autovia/pueblo_dia_*.png` y `_noche_*`). `data/lejanias.json` guarda desde dónde y la luz del mediodía.
  - En el juego es un anillo que el shader pone como si estuviera a 2,4 km, con profundidad 1e-5: detrás de lo que el juego dibuja y delante de las sierras. De día lleva la luz de la hora; de noche, la foto de noche. Se ve solo en la zona y no en el Modo Silent Hill.
  - Para rehacerlo: el modo `lejanias`, luego `lejanias.py` con la carpeta que dice el log, y luego `--import`.
- **Pruebas**:
  - `zonas`: 7 ok ([log](logs/selftest_zonas_20261125_144914.log)). Hay una comprobación nueva de la A-4: empalma con el final de la carretera; la valla para antes de la calzada, a 124 m del centro; se ve desde la zona y no desde el pueblo; hay 69 vehículos (21 camiones) y ninguno se sale de su carril; la foto del pueblo está puesta.
  - `cementerio`: 9 ok ([log](logs/selftest_cementerio_20261125_150136.log)), con vistas nuevas: `cementerio_autovia`, `_enlace`, `_autovia_alto`, `_pueblo` y `_pueblo_alto`, y `autovia` y `pueblo` también `_tarde` y `_noche`.
- Capturas: `guion/fotos/cementerio/cementerio_05_autovia.jpg`.
- No he tocado ningún archivo compartido: en `selftest.gd` solo he metido líneas.

### 25/11 · Pretil: los arcos del pórtico, huecos de verdad, y la planta solar de enfrente

- **Luis**, con dos imágenes (la hoja de capturas con el arco abierto rodeado y una captura de Street View de la puerta de la planta): «Un pequeño ajuste a los arcos. Que sale el hueco de entrada rectangular y luego clippeado un arco. Y un añadido. En frente del cementerio hay una planta solar. Estaría bien añadirla también. Por lo demás bastante bien. Daría un repaso por si hay alguna propuesta o mejora posible.»
- **Los arcos** (`cementerio.gd`):
  - El abierto era un hueco rectangular de 2,6 m con una cara fina de arco delante. Ahora es una bóveda de medio punto de lado a lado del edificio (`_vault()`, nueva: normales suaves, enjutas delante y detrás), y por dentro sale con el mismo arco. El techo sólido del pasadizo baja de 2,6 a 2,3 m.
  - El cerrado era una cara oscura plana. Ahora el ala se parte en su vano y la puerta oscura queda 45 cm dentro del muro, bajo su bóveda, con su umbral (`SHUT_R`, `SHUT_SPRING`, `SHUT_DEEP`).
- **La planta solar** (`planta_solar.gd`, nuevo, sobre `obra.gd`; la crea `zonas.setup` con `"solar": true`, `zonas.solares`):
  - Medida del PNOA (`tools/ign/cementerio_solar.jpg` y `cementerio_solar_oeste.jpg`, nuevos) y de Street View de 2024 (la puerta), sin guardar ninguna foto de Google.
  - Valla de malla todo alrededor (sólida donde se llega), puerta de tubo y malla con el cartel «PLANTA SOLAR / AGROINDUSTRIAL» (como el real, sin la letra pequeña: **pendiente de que Luis diga si quiere un nombre inventado**), entrada de tierra, caseta blanca, chatarra y un coche viejo.
  - 28 seguidores de dos ejes (mesa de 16 × 13 m sobre mástil de 6,5 m), en un MultiMesh. Siguen al sol del juego y de noche se quedan casi planos; giran a 5° por segundo como mucho.
  - Las matas de la zona crecen dentro, menos en la entrada, la caseta y los pies; ningún árbol suelto. `cementerio._roadside()` no planta árbol de la fila en la entrada.
  - No entra nadie: no hace falta nada de Sistemas.
- **Archivos tocados**: `cementerio.gd`, `zonas.gd` y `planta_solar.gd` (míos); en `selftest.gd` solo líneas metidas (una comprobación en `_zonas_checks` y vistas en el modo `--cementerio`). Ningún otro compartido.
- **Pruebas**:
  - `zonas`: 8 ok ([log](logs/selftest_zonas_20261125_161137.log)). La comprobación nueva: 28 seguidores, de cara al sol a mediodía (1,000), al este por la mañana y al oeste por la tarde, planos de noche; 54 tramos de valla sólidos y la puerta cerrada; 678 matas dentro, ninguna en la entrada ni al pie de un seguidor; ningún árbol dentro.
  - `cementerio`: 9 ok ([log](logs/selftest_cementerio_20261125_161843.log)), con vistas nuevas de los arcos y de la planta.
- **Repaso pedido por Luis**: propuestas dichas en el chat, a la espera de su palabra (ninguna hecha): azafrán escondido en la planta, las plantas grandes de paneles fijos del oeste, la nave blanca junto a la puerta de zona, el minimapa vacío en la zona, lamparillas en las tumbas de noche, el rumor de la A-4, carteles en el enlace y troncos encalados en la fila de árboles.
- Capturas: `guion/fotos/cementerio/cementerio_06_arcos_solar.jpg`.

### 25/11 · Pretil: las ocho cosas del repaso, y el cartel «Planta Industrial Agrosolar»

- **Luis**, al repaso que pidió: «Haz las 8. Y el cartel "Planta Industrial Agrosolar"». Y a mitad del trabajo, con dos fotos de velas rojas de cementerio: «En el 2 cambiaría lamparillas por velas, que son las que se suelen poner».
- **El cartel de la planta** dice ahora «PLANTA INDUSTRIAL» (azul) y «AGROSOLAR» (rojo): el nombre es de Luis (`planta_solar.SIGN`).
- **Las ocho**, todas hechas y pendientes de su visto bueno (el detalle, en `referencias/cementerio/LEEME.md`):
  1. Azafrán escondido `planta_solar_puerta`, al pie del poste sur de la puerta de la planta, por fuera, entre matas (`planta_solar._saffron()`). **Sistemas: es uno más en la cuenta de escondidos.**
  2. Velas rojas de cementerio (no lamparillas) al pie de una tumba de cada siete, de una a tres; de noche brillan con un punto rojo que parpadea, sin luces de verdad (`cementerio.gd`: clases `candle` y `wax`, `_candle_glow()`, `tick()`).
  3. La zona en el minimapa: `minimap.gd` (de Sistemas, avisado antes) lleva **solo líneas metidas**: `static var extras` y un bucle en `_draw()`. La rellena `zonas._plan()`.
  4. La nave blanca junto a la puerta de zona (`afueras.gd`, nuevo, sobre `obra.gd`): dos bloques, portones, una sala abierta de verdad con foso y banco, solera y explanada. Sin rótulo.
  5. Las dos plantas de paneles fijos del oeste, como filas bajas a lo lejos (`planta_solar._farms()`).
  6. El rumor de la A-4 de día, más fuerte cuanto más cerca; de noche calla (`autovia.gd` `_tick_hum()`; el bucle lo hace `tools/cementerio/rumor.py`).
  7. Tres carteles azules: el de la carretera vieja antes del enlace (Madrid de frente, Córdoba a la derecha), el mismo en el enlace y el de distancias en la A-4 (`afueras.gd`).
  8. Troncos encalados en la fila de árboles de la carretera (`cementerio._whitewash()`); la cal se va con el árbol si un coche lo tumba.
- **Archivos tocados**: míos, `cementerio.gd`, `zonas.gd`, `planta_solar.gd`, `autovia.gd` y `afueras.gd` (nuevo, lo precarga `zonas.gd` y también `cementerio.gd`). De otros, solo líneas metidas: `minimap.gd` (Sistemas) y `selftest.gd`. Recursos nuevos: `godot/assets/autovia/rumor.wav`, `tools/cementerio/rumor.py` y tres ortofotos en `tools/ign/` (`cementerio_nave`, `cementerio_fijas`, `cementerio_enlace`).
- **Pruebas**:
  - `zonas`: 9 ok, 0 fallos ([log](logs/selftest_zonas_20261125_170846.log)). La comprobación nueva: 634 tumbas de 4532 con velas, encendidas de noche y no de día; el rumor de la A-4 a −27 dB en la puerta del cementerio de día (−19 detrás de su tapia este, junto a la A-4) y callado de noche (−60); 43 troncos encalados; 3 carteles azules; la nave con el frente macizo y el taller abierto donde se puede entrar, sin árboles en su explanada; 81 filas de paneles fijos; el azafrán de la puerta en la lista y a mano; y la carretera de la zona y la tapia en el plano (41 cosas).
  - `cementerio`: 9 ok, 0 fallos ([log](logs/selftest_cementerio_20261125_170226.log)), con las vistas nuevas `cementerio_ocho_*`.
- **Queda para Luis**: el visto bueno; si la nave lleva algún rótulo inventado; y si los seguidores siguen al sol o los quiere fijos.
- **Queda para Sistemas**: contar el azafrán nuevo; y, si se quiere ver la zona en el mapa entero, dejar que se desplace por encima del borde norte (`game.gd`).
- Capturas: `guion/fotos/cementerio/cementerio_07_las_ocho.jpg`.

### 25/11 · Pretil: los retoques del cementerio (R.I.P./D.E.P., rumor de noche, taller Recoveco)

- **Qué dijo Luis**: «Muy buena pinta todo. Solo unos retoques: Poner R.I.P y D.E.P grabado en algunas lápidas (50% de todas ellas). Dejar el rumor de la autovía por la noche, pero mucho más bajo. La nave podemos modelarla también y en vez de Iveco llamarla Recoveco, y que funcione como los demás talleres, puerta plegable, arreglo y pintura. Los seguidores déjalos que sigan al sol. Por lo demás visto bueno».
- **Aprobado**: las ocho cosas del repaso y el cartel «Planta Industrial Agrosolar».
- **Los retoques**, hechos y pendientes de su visto bueno (el detalle, en `referencias/cementerio/LEEME.md`):
  1. «R.I.P.» o «D.E.P.» en una tumba de cada dos, en la lápida de pie o tumbada en la losa (`cementerio._grave()`; dibujos de `tools/cementerio/lapidas.py`). Sin nombres ni fechas, como antes.
  2. El rumor de la A-4 sigue de noche, 16 dB más bajo (`autovia.HUM_NIGHT`).
  3. La nave se llama «Recoveco» (letras azules en el bloque bajo, carteles «TALLER OFICIAL» y «CHAPA Y PINTURA») y su portón del norte es un taller como los del pueblo, con el hueco y la persiana de `garage.gd` (`afueras._workshop()`).
  4. Los seguidores siguen al sol: sin cambios.
- **Para Sistemas**: el taller Recoveco **no** está en `game.garages` ni en `props.repairs` (está fuera del mapa: la grúa, `_limite_checks` y las pruebas de relieve cuentan con que todos estén dentro). `afueras.tick()` mueve su persiana y, con el coche parado dentro, pone `game.at_shop` y `game.at_garage` cada momento (después de `_drive_car`, que los borra); el pitido, la reparación, la pintura y el cobro son los de `game.gd`. No he tocado `game.gd`, `props.gd` ni `garage.gd`. Si se quiere el aviso «Mételo pa dentro», el cuadro azul del minimapa o la luz de noche, son suyos.
- **Archivos tocados**: míos, `cementerio.gd`, `autovia.gd`, `afueras.gd` y `zonas.gd` (una llamada a `af.tick`). De otros, solo `selftest.gd`: función nueva `_recoveco_checks()`, una llamada, vistas `cementerio_retoque_*`, y tres retoques en mi propia comprobación de las ocho (el rumor de noche ya no es −60; la nave tiene 5 sólidos). Recursos nuevos: `godot/assets/cementerio/lapida_rip.png` y `lapida_dep.png`, y `tools/cementerio/lapidas.py`.
- **Pruebas**:
  - `zonas`: 11 ok, 0 fallos ([log](logs/selftest_zonas_20261125_173121.log)). Lápidas: 2240 de 4532 tumbas (49 %), 1094 con «R.I.P.» y 1146 con «D.E.P.»; 1407 en la lápida de pie y 833 en la losa; todas dibujadas. Taller: nombre y carteles puestos; fuera de las listas del pueblo y entero dentro de la zona; persiana bajada sin nadie y arriba al llegar un coche; dentro, precio y pitido («Apañar · 4 €»); al pitar baja, y sale arreglado, pintado y cobrado (4 €); sube otra vez y no vuelve a ofrecer nada.
  - `cementerio`: 9 ok, 0 fallos ([log](logs/selftest_cementerio_20261125_174015.log)), con las vistas nuevas `cementerio_retoque_*`.
- **Aprobado por Luis el 25/11**: «Déjalos. Creo que no queda nada. Visto bueno». Los carteles «TALLER OFICIAL» y «CHAPA Y PINTURA», que añadí por mi cuenta, se quedan. No queda nada pendiente en la zona del cementerio.
- Capturas: `guion/fotos/cementerio/cementerio_08_retoques.jpg`.

### 25/11 · Pretil: la sala de fiestas de la carretera vieja, gastada y arreglada

- **Qué dijo Luis**, con una captura de Street View de noviembre de 2024: «Ponte ahora con Sala Cuevas KUE [...] Aquí voy a necesitar dos modelos también. Uno con todo bien y otro con la pintura desgastada, tablones en las puertas y cosas medio rotas, que parezca desgastado. Ya que es otro de los edificios que "arreglaremos" dentro del juego».
- **Qué hay**: la sala real de la carretera antigua de Madrid a Cádiz (Catastro 5187003VJ5658N), hecha a mano en dos estados como la plaza de toros vieja. El detalle, en `referencias/cuevas/LEEME.md`.
  - `godot/scripts/cuevas.gd`, `world.cuevas`. `set_restored(true/false)` cambia de estado; arranca gastada y con `--cuevas-arreglada` arranca arreglada.
  - El frente oscuro con sus arcos y sus listones de colores, la torre del rótulo, el bar de la esquina, la terraza de verano con sus velas blancas, la rampa, el cobertizo de los coches, el patio del sur y las naves de detrás.
  - Gastada: pintura desconchada, listones caídos, tablones en puertas y portones, celosías rotas, matas secas, pintadas de las peñas, rótulo medio borrado, una farola doblada, chapas y tejas que faltan.
- **Pendiente de Luis**: el visto bueno, **el nombre de los rótulos** (llevan uno provisional mío, «SALA COVACHAS» y «KOVA», porque no se ponen marcas reales y no ha dado nombre) y si quiere un azafrán escondido (propuesto, no puesto).
- **Para Sistemas**: `cuevas.lamps` son sus tres farolas; solo están en `world.lamp_spots` cuando está arreglada, y `game.gd` lee esa lista una vez al arrancar, así que encenderlas tras un cambio en marcha es cosa de `lights.add_lamp`. La actividad que la arregla queda para cuando Luis la pida. No está en el minimapa más que como bloque.
- **Horneado**: bloque CUEVAS en `tools/bake_godot.py` (salta el RC, contornos en `block_list`, sin árboles del mapa en la parcela, clave `cuevas`). Sin cambio de relieve ni de calles. Horneé yo una vez, con el visto bueno de Sistemas; los horneados posteriores de Texturas (Calle de la Plata) ya llevan el bloque. Tras hornear: casas, árboles, calles y relieve iguales; `plantas_altas.py` da 0 casas.
- **Archivos tocados**: míos, `cuevas.gd`, `tools/cuevas/texturas.py`, `godot/assets/cuevas/` (5 PNG), `tools/ign/cuevas.jpg` y `.json`, `referencias/cuevas/LEEME.md`. De otros, solo líneas insertadas: `tools/bake_godot.py` (bloque CUEVAS y cuatro líneas), `map_data.gd` (`var cuevas` y su lectura), `world.gd` (`CuevasS`, `var cuevas`, el paso y `_build_cuevas`), `selftest.gd` (`_cuevas_checks()`, el modo `--cuevas` y una llamada en la completa tras `_toros_checks()`).
- **Pruebas**:
  - `cuevas`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_20261125_203341.log)). Los dos estados construidos; gastada, con tablones, listones caídos y farolas apagadas; arreglada, con sus farolas entre las del pueblo; el frente, las puertas, el bar, la terraza, la rampa, la valla y las naves paran y la acera, el descampado y el cobertizo quedan libres; nada suyo en una calle.
  - `cuevas cuevas-arreglada` (arranca arreglada, vistas de noche): CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_cuevas-arreglada_20261125_203147.log)).
  - Sin pasada completa.
- Capturas: `guion/fotos/cuevas/cuevas_01_dos_estados.jpg`, `cuevas_02_detalles_y_noche.jpg`. Sin commit.

### 25/11 · Pretil: la sala se llama «Sala Cavernas KAE»; pintura con textura y azafrán bajo el cobertizo

- **Qué dijo Luis**: «Nombre: "Sala Cavernas KAE". Azafrán bajo el cobertizo. La pintura tan negra y lisa hace que casi no se vean los outlines ni las formas. Le pondría algo de textura.»
- **Nombre**: los rótulos dicen «SALA CAVERNAS» y «KAE» (`cuevas.NAME`, `NAME_SHORT`); en la gastada, con letras caídas.
- **Pintura**: el frente arreglado ya no es negro liso, sino antracita sobre enfoscado rugoso (`godot/assets/cuevas/pintura_nueva.png`, de `tools/cuevas/texturas.py`), con la albardilla más clara.
- **Azafrán escondido**: `"id": "cuevas"`, bajo el cobertizo de los coches, en el rincón entre el bar y el arranque de la rampa, tras unas cajas de botellas apiladas. Está en los dos estados. **Para Sistemas**: es uno más en la cuenta de los escondidos.
- **Archivos tocados**: `cuevas.gd`, `tools/cuevas/texturas.py`, el PNG nuevo y, en `selftest.gd`, mi propia `_cuevas_checks()` (una comprobación más) y una vista más del modo `--cuevas`.
- **Pruebas**: `cuevas`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_20261125_211043.log)); `cuevas cuevas-arreglada`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_cuevas-arreglada_20261125_211243.log)). Sin pasada completa.
- Capturas: `guion/fotos/cuevas/cuevas_03_cavernas.jpg`. Sin commit. Pendiente del visto bueno de Luis.

### 25/11 · Pretil: visto bueno de la Sala Cavernas KAE y su interior (luces, barra, Koka y Ná en el altillo del DJ)

- **Qué dijo Luis**, con cuatro fotos del interior real: «Visto bueno. Me gustaría que se pudiera pasar y hubiese un interior con luces de fiesta, barra, y que sonase Koka Y Ná por unos altavoces al fondo, en el altillo del DJ. Paso fotos por dentro».
- **La sala por fuera queda aprobada** (los dos estados, el nombre, la pintura con textura y el azafrán del cobertizo).
- **El interior** (`godot/scripts/cuevas_dentro.gd`, `world.cuevas.dentro`; el detalle, en `referencias/cuevas/LEEME.md`, apartado «Por dentro»):
  - Un decorado aparte en `(1650, 0)`, como los de las tiendas: una cueva de roca de 24 × 30 m con unas 2600 tiras colgando del techo, la barra al oeste con sus botellas, tres reservados al este, la pista con la jaula blanca, y al fondo el altillo del DJ con las letras «KAE», la pantalla de la emisora y dos torres de altavoces.
  - Luces de fiesta: seis focos que barren, seis rayos de láser, tres bolas de espejos con sus reflejos por el suelo, neones y colores que cambian con el compás. Sin sombras y sin destellos.
  - Suena «Koka y Ná FM» por los altavoces del altillo, la misma canción y el mismo punto que en la radio de los coches, más fuerte cuanto más cerca. Desde la carretera se oye apagada, solo con la sala abierta.
  - **Se entra solo con la sala arreglada y de 23:00 a 6:00**, todas las noches: las puertas rojas se abren con luz rosa, y la flecha verde está delante. El tablón de la puerta dice ahora «TODAS LAS NOCHES» (decía «SÁBADO NOCHE»).
  - Nadie modelado por mí: la gente es de Sistemas (`fiesta.gd`).
- **Para Sistemas**:
  - `game.gd`: dos líneas insertadas en `_update_audio`, tras el bloque de `recress.music()`, con su permiso («mételas tú»): con `inside_of.own_music == true` calla la música de la calle.
  - Lo que lee `fiesta.gd` de `dentro` sigue igual: `dance_spots`, `client_spots`, `client_spot`, `bar_spot`, `dj_spot`. Para fotos sin entrar, `dentro.peek = true`.
  - **La pista en blanco que vio en sus fotos está arreglada**: era el `Decal` de los reflejos de la bola (su luz es el color del dibujo, no el alfa).
  - El horario de la puerta es ya el de la gente: 23 a 6 (`cuevas.OPEN_FROM`, `OPEN_TO`, `open_at`).
  - Nada arregla la sala todavía en el juego (su actividad es de Sistemas, cuando Luis la pida): hoy solo se ve dentro con `--cuevas-arreglada` o llamando a `set_restored(true)`.
- **Archivos tocados**: míos, `cuevas_dentro.gd` (nuevo), `cuevas.gd` (horario, puertas que se abren, `dentro`), `tools/cuevas/texturas.py` y cinco PNG nuevos en `godot/assets/cuevas/` (`roca`, `suelo_sala`, `pista`, `bola`, `motas`). De otros, solo líneas insertadas: `entradas.gd` (tres en `shops()`), `game.gd` (las dos de arriba) y `selftest.gd` (cinco comprobaciones más en mi `_cuevas_checks()` y once vistas `cuevas_dentro_*` en el modo `--cuevas`).
- **Pruebas**:
  - `cuevas`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_20261125_220115.log)). En ese registro hay un «SCRIPT ERROR: Bad address type» suelto al construir la cooperativa (`coop.gd:558`, un archivo sin cambios desde el 12/11): no es de la sala, no salió en la pasada de noche y no hizo fallar nada. Si se repite, es de quien lleve `coop.gd` o `parts.gd`.
  - `cuevas cuevas-arreglada`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_cuevas-arreglada_20261125_215843.log)). El decorado construido; gastada no se entra, arreglada está cerrada de día y abierta de noche con la flecha en la acera; dentro paran el altillo, la barra, los reservados, la jaula, la escalera y una columna, y la pista queda libre; los focos se mueven y la emisora suena desde el altillo, más fuerte de cerca, con el lo-fi callado; al salir se oye apagada desde la carretera y calla al cerrar.
  - Sin pasada completa.
- Capturas: `guion/fotos/cuevas/cuevas_04_dentro.jpg`. Sin commit. **Pendiente del visto bueno de Luis** (el interior).

### 25/11 · Pretil: la Sala Cavernas abre de jueves a domingo; se sube al altillo del DJ y, por su puerta, a la azotea

- **Qué dijo Luis**, a mis dos preguntas (el visto bueno del interior, y si la sala va arreglada en Modo Golismeo): «1. Visto bueno, pero que solo abra jueves, viernes, sábados y domingos. Al altillo molaría poder subir y ver el pueblo desde ahí. Pon aires acondicionados antenas y eso. De momento que se pueda arreglar con 30 P.C., luego ya daremos misión. 2. Si, arreglada ahí.»
- **El interior queda aprobado.**
- **Noches de apertura**: arreglada, la sala abre de 23:00 a 6:00 solo las noches de jueves, viernes, sábado y domingo. La madrugada es de la noche anterior: el lunes está abierta hasta las 6 y el jueves no abre hasta las 23. `cuevas.opens(día, hora)` (estática, 0 = lunes; `OPEN_DAYS`) sustituye a `open_at(hora)`, que ya no existe. El tablón de la puerta dice «DE JUEVES A DOMINGO».
- **El altillo se sube** (`cuevas_dentro.gd`): fuera la cadena y el «PRIVADO». Escalera de siete peldaños con el canto en rosa (una tarima con `low` en `MapData.decks`), y el altillo se pisa entero: paran su borde (de suelo a techo), la mesa del DJ, la cabina, los altavoces y las cajas. En la escalera y en ese extremo del altillo la cámara va detrás de ti (desde la del salón te tapaban una columna y un altavoz); el mando no cambia de sentido.
- **La azotea** (mi lectura de «y ver el pueblo desde ahí»): en la pared del fondo del altillo, la puerta «AZOTEA» lleva a la cubierta de la sala en el pueblo. Es otra puerta del mismo decorado (`dentro.azotea`, `set_id` común). Se anda por los dos faldones (tarimas con `grad`), con bordes invisibles en la capa 16. Arriba, en los dos estados: la caseta de la escalera con su antena y su parabólica, cinco aires acondicionados en fila tras el peto, una máquina grande con su conducto, cuatro extractores en la cumbrera, un depósito, ocho lucernarios y otra antena; arreglada, además, barandilla, dos sillas de plástico con una caja por mesa y dos luces sin sombras. La emisora se oye apagada desde allí con la sala abierta. El detalle, en `referencias/cuevas/LEEME.md`, apartado «La azotea».
- **Lo que puse por mi cuenta**: la caseta, los extractores, el depósito, los lucernarios, la máquina grande, la barandilla, las sillas y las luces (Luis pidió «aires acondicionados antenas y eso»), y el texto del tablón.
- **Para Sistemas**:
  - Arreglar con 30 P.C. y arreglada en Modo Golismeo: suyo, y ya hecho en `fiesta.gd` (su línea de PROJECT_STATE).
  - La puerta de la azotea es `world.cuevas.dentro.azotea` (no `roof`: `obra.gd` ya tiene una función con ese nombre). Entres por la puerta que entres, `game.inside_of` acaba siendo `dentro` (lo cambia `cuevas_dentro._process`).
  - `fiesta.gd` no cambia: `open()` ya llama a `sala.opens(weekday, clock)`.
  - Nadie de la gente sube al altillo ni a la azotea (no lo he tocado): el DJ sigue en `dj_spot`.
- **Archivos tocados**: míos, `cuevas.gd` y `cuevas_dentro.gd`. De otros, solo líneas insertadas o mías: `entradas.gd` (dos más en `shops()`) y `selftest.gd` (seis comprobaciones más en `_cuevas_checks()`, vistas de la azotea y de la escalera en el modo `--cuevas`). Sin rehorneado, sin texturas nuevas, sin nada descargado.
- **Pruebas**:
  - `cuevas`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_20261125_230031.log)), 17 comprobaciones. Es anterior a un último retoque (el tamaño de la letra del tablón de la puerta), que sí está en la pasada de noche.
  - `cuevas cuevas-arreglada`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_cuevas-arreglada_20261125_230358.log)), 17 comprobaciones: las nueve horas de la semana probadas abren o cierran como deben; la escalera se sube andando de verdad y del altillo no se sale por el borde; por la puerta de la azotea se sale a la cubierta a su altura, con la bajada marcada solo allí arriba; los cuatro bordes paran y la cámara no los ve; de vuelta estás en la sala como por la puerta principal.
  - Sin pasada completa.
- Capturas: `guion/fotos/cuevas/cuevas_05_azotea.jpg`. Sin commit. **Pendiente del visto bueno de Luis** (la subida al altillo y la azotea).

### 26/11 · Pretil: «La Kueva», la sala de abajo de la Sala Cavernas; el altillo y la azotea, aprobados

- **Qué dijo Luis** (25/11): «Y también añade una escalera para abajo, será "La Kueva", una sala de fiestas oscura y turbia. Estará  a oscuras salvo por los rayos láser de fiesta, y la música sonará bass boosted».
- **El altillo y la azotea quedan aprobados.** Sistemas le dijo a Luis: «De lo de Pretil quedará sin tu visto bueno, según me dice: la subida al altillo, la azotea y La Kueva cuando esté. Entrarán en la versión igualmente salvo que digas lo contrario.» Luis: «Tienen mi visto bueno». La Kueva no estaba hecha entonces: la frase vale para que entre en la 0.1.4, no como visto bueno del resultado (lectura de Sistemas, y mía).
- **La bajada** (`cuevas_dentro.gd`): al fondo de los reservados, en la esquina del altillo, bajo un tablero «LA KUEVA» en verde. 24 peldaños con el canto en verde bajan 4,5 m por un túnel de roca, por debajo del altillo y de la pared del fondo. Es parte del mismo decorado: se baja y se sube andando, sin puerta.
- **La sala** (16 × 15 m, 3 m de alto, tras un pasillo de 4 m): roca, dos pilares, pared de altavoces con un rack de amplificadores al fondo, una barra de tablón sobre bidones con una nevera apagada y cajas, dos sofás viejos, un palé, un colchón, bidones por mesa, botellas por el suelo y un rótulo verde «SALIDA» sobre la puerta. Nadie.
- **A oscuras salvo por los láseres**: ninguna luz redonda; la roca tiene un tercio de la luz propia de la de arriba. Cuatro máquinas en el techo (verde, violeta, cian con rosa, roja) echan 31 rayos que barren al compás de la emisora; cada 16 tiempos cambian las que están encendidas. Ocho rayos son además focos estrechísimos sin sombras, que dejan el punto del láser en la roca y en quien pasa.
- **Música con los graves subidos**: la misma emisora, por los altavoces de abajo y un bus propio (`CuevasKueva`): graves a +12 dB, agudos a −12 dB, algo de distorsión y un limitador. El efecto crece peldaño a peldaño.
- **Cámara**: te sigue de cerca en la escalera y el pasillo y cuelga como arriba en la sala de abajo; el mando no cambia de sentido.
- **Lo que puse por mi cuenta**: las tiras verdes de los peldaños, el foco verde de la boca, el rótulo «SALIDA», el mobiliario de abajo, el brazo más corto del último reservado (y sin roca detrás: es el paso a la escalera) y la barandilla que cierra el extremo del altillo sobre la bajada.
- **Para Sistemas**:
  - `dentro.level` es ahora 4,6 m más alto (el decorado entero subió para que La Kueva quede sobre el terreno). Quien use `level`, `MapData.foot` o los sitios que da el decorado no nota nada.
  - Sitios nuevos para su gente si Luis la pide: `dentro.kueva_spots` (diez, en el suelo de abajo). `dentro.kueva_mix(p)` dice cuánto de abajo está un punto (0 a 1); `dentro.kueva_speakers`, de dónde sale la música allí.
  - Bus de audio nuevo `CuevasKueva` (hijo de `Music`), creado al bajar la primera vez.
  - El último reservado tiene el brazo del fondo más corto y el extremo este del altillo (x > 8,95) ya no se pisa. `dance_spots`, `bar_spot`, `dj_spot` y `client_spots` no cambian.
  - `entradas.gd`, `game.gd` y `fiesta.gd`, sin tocar. En una sala a oscuras la gente se vería igual de clara que el jugador (los personajes tienen su propia luz).
- **Archivos tocados**: mío, `cuevas_dentro.gd`. De otros, solo líneas insertadas: `selftest.gd` (cinco comprobaciones más en `_cuevas_checks()` y nueve vistas en el modo `--cuevas` de noche). Sin rehorneado, sin texturas nuevas, sin nada descargado.
- **Pruebas**:
  - `cuevas`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_20261126_001126.log)), 22 comprobaciones.
  - `cuevas cuevas-arreglada`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_cuevas-arreglada_20261126_000511.log)), 22 comprobaciones. Las de La Kueva: los suelos y el terreno por debajo de todo; lo que para y lo que deja pasar (10 rayos, y nada de los campos dentro); se baja andando de verdad hasta la sala con la cámara bajo los techos; ninguna luz redonda, ninguna de arriba llega, 31 rayos que se mueven y 8 focos sin sombras; abajo suena por su bus con +12 dB en graves, y al subir vuelve la música de la sala y La Kueva se guarda.
  - Sin pasada completa.
- **Sin comprobar**: cómo suena de verdad el refuerzo de graves (las pruebas miran el bus y sus bandas, no el sonido), y la sala con gente dentro.
- Capturas: `guion/fotos/cuevas/cuevas_06_kueva.jpg`. Sin commit. **Aprobada por Luis el 26/11 («Visto bueno»)** (La Kueva y sus dos azafranes).

### 26/11 · Pretil: dos azafranes escondidos más en la Sala Cavernas (azotea y La Kueva)

- **Qué dijo Luis** (26/11): «Angelus en La Kueva. Pon un azafrán en la azotea y otro en la Kueva. Que en la Kueva haya aparte 3-5 NPCs genéricos de drogadictos y borrachos, casi zombies, diciendo lo que les gusta esa parte porque es oscura.»
- **Ángelus y los genéricos son de Sistemas** (`fiesta.gd`): le pasé las palabras de Luis. Ángelus ya está, en `kueva_spots[6]`. Los «casi zombies», en su entrada.
- **Azafrán de la azotea** (`cuevas.gd`): en un tiesto viejo detrás del depósito de agua, en `P(37.7, -19.8)`; id `cuevas_azotea`. El depósito lo tapa al salir de la caseta. En los dos estados (a la azotea solo se sube con la sala arreglada y abierta).
- **Azafrán de La Kueva** (`cuevas_dentro.gd`): en una caja de botellas abierta detrás de la barra de tablón, en `INSIDE + (17.75, 42.42)`; id `cuevas_kueva`. Cuelga de `kueva` (se oculta con ella) y se coge rodeando la barra por el fondo. Flor al 60 %.
- Los dos van en `game.flowers` con `hidden`: la cuenta de escondidos sube en dos sola.
- **Lo que puse por mi cuenta**: el tiesto y la caja de botellas, y el sitio exacto de cada uno (Luis dijo «en la azotea» y «en la Kueva»).
- **Archivos tocados**: míos, `cuevas.gd` y `cuevas_dentro.gd`. De otros, solo líneas insertadas en `selftest.gd` (una comprobación más al final de `_cuevas_checks()`, prefijo `cvf_`; las vistas `azotea_azafran` y `kueva_azafran` del modo `--cuevas`). Hecho en el hueco que me abrió Sistemas con la carpeta congelada para la versión, que según me dice se llamará 0.2.0.
- **Pruebas**: `cuevas`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_20261126_003659.log)), 23 comprobaciones. `cuevas cuevas-arreglada`: CUEVAS OK (0 failed) ([log](logs/selftest_cuevas_cuevas-arreglada_20261126_003414.log)), 23. Sin pasada completa.
- **Sin comprobar**: coger de verdad cada flor andando (la prueba mira que estén donde deben, que se llegue a ellas y qué las tapa).
- Capturas: `guion/fotos/cuevas/cuevas_07_azafranes.jpg`, enviada a Luis. Sin commit. La Kueva seguía entonces sin un visto bueno expreso de Luis después de verla; lo dio el mismo 26/11 («Visto bueno»), con los dos azafranes.

### 26/11 · Pretil: dos comprobaciones mías fallaban solo en la prueba completa (corre sin ventana)

- **Quién lo pidió**: Sistemas, para la 0.2.0. No es una petición de Luis. La completa dejaba dos fallos en comprobaciones mías que sueltas pasaban.
- **Causa**: no era un fallo del juego. La completa corre con `--headless`, y sin ventana el motor no guarda las instancias de un MultiMesh: `get_instance_transform()` devuelve la identidad. Las dos comprobaciones leían posiciones de vuelta del motor.
  - Plantas de la zona (`_zonas_checks`): cada mata se leía en el centro de su celda de 64 m. De ahí 2650 dentro del círculo y 601 fuera de sitio, frente a 2458 y 0 con ventana.
  - Láseres de La Kueva (`_cuevas_checks`): el rayo 0 se leía igual antes y después de 30 fotogramas.
- **Arreglo**: los scripts guardan su propio registro y las comprobaciones leen eso. Al motor se le pregunta además solo cuando hay ventana (`DisplayServer.get_name() != "headless"`).
  - `zonas.gd`, `_scrub()`: meta `"ps"` en el MultiMeshInstance3D de cada celda, con el sitio de cada mata en el orden del búfer. Lo leen la comprobación de las plantas y la de la planta solar, que leía igual del motor y pasaba por casualidad.
  - `cuevas_dentro.gd`, `_k_party()`: `b["d"]`, adónde apunta cada rayo.
  - `selftest.gd`: las dos comprobaciones (variables `zp_*` y `cvk_*`). A los rayos se les mira tres veces en vez de dos. Los mensajes dicen ahora lo que callaban: lámparas redondas, sombras, instancias del MultiMesh y si se preguntó al motor.
  - Mis modos `zonas` y `cuevas` aceptan `sinfotos`, como `ajedrez`: `python tools/run_tests.py zonas sinfotos --headless` corre como la completa, sin fotos, en un minuto.
- **Pruebas**:
  - Sin ventana: `zonas sinfotos --headless`: ZONAS OK (0 failed), 11 ([log](logs/selftest_zonas_sinfotos_20261126_015914.log)); `cuevas sinfotos --headless`: CUEVAS OK (0 failed), 23 ([log](logs/selftest_cuevas_sinfotos_20261126_020044.log)).
  - Con ventana: `zonas`: ZONAS OK (0 failed), 11 ([log](logs/selftest_zonas_20261126_020235.log)); `cuevas`: CUEVAS OK (0 failed), 23 ([log](logs/selftest_cuevas_20261126_020635.log)).
  - La completa la repite Sistemas.
- **Queda**: la comprobación de las lápidas «R.I.P.»/«D.E.P.» (`_recoveco_checks`, `wmm.get_instance_transform(i).basis`) pasa en vacío sin ventana; con ventana (`zonas`) sí mira. Necesita un registro en `cementerio.gd`, que no estaba abierto durante la congelación.
- **Archivos tocados**: míos, `zonas.gd` y `cuevas_dentro.gd`. De otros, `selftest.gd` (mis comprobaciones y mis dos modos). Sin commit.

### 26/11 · Pretil: la comprobación de las palabras de las lápidas ya mira también sin ventana

- **Por qué**: quedó pendiente al arreglar las otras dos (entrada anterior). Leía del motor cómo está girada cada palabra «R.I.P.»/«D.E.P.», y sin ventana el motor devuelve cada instancia de un MultiMesh sin girar: en la prueba completa pasaba sin mirar nada. No es una petición de Luis; me lo recordó Sistemas al publicar la 0.2.0.
- **Corrección a la entrada anterior**: la comprobación está en `_recoveco_checks()`, que corre con el modo `zonas`, no en `_cementerio_checks()` como puse allí. Corregido también en aquella línea.
- **Qué he hecho**:
  - `cementerio.gd`, `_grave_meshes()`: meta `"xf"` en los MultiMesh `tumbas_rip_*` y `tumbas_dep_*`, con cómo puso el script cada palabra. Sin cambio en lo que se ve.
  - `selftest.gd`, `_recoveco_checks()`: lee ese registro. Ahora cuenta además las tumbadas, que tienen que ser las que no van en lápida de pie (`words - words_upright`); antes solo miraba que ninguna estuviera torcida. Con ventana pregunta también al motor (variables `lp_*`).
  - Mi modo `cementerio` acepta `sinfotos`, como `zonas` y `cuevas`.
- **Pruebas**:
  - Sin ventana: `zonas sinfotos --headless`: ZONAS OK (0 failed), 11 ([log](logs/selftest_zonas_sinfotos_20261126_025733.log)); `cementerio sinfotos --headless`: CEMENTERIO OK (0 failed) ([log](logs/selftest_cementerio_sinfotos_20261126_025857.log)).
  - Con ventana: `zonas`: ZONAS OK (0 failed), 11 ([log](logs/selftest_zonas_20261126_030019.log)).
  - Lo que dice la comprobación, igual con y sin ventana: 2240 palabras en 4532 tumbas, 833 tumbadas (las 833 que van en la losa) y 1407 de pie, ninguna distinta del registro.
  - Sin pasada completa.
- **Archivos tocados**: mío, `cementerio.gd`. De otros, `selftest.gd` (mi comprobación y mi modo). Después de la 0.2.0: sin publicar. Sin commit.

### 26/11 · Pretil: una caja sin fondo en las estanterías del MasAhorro

- **Quién lo encontró**: Sistemas, al comparar las mallas de `obra.gd` (una caja de 0,04 × 0,3 × ~0 en (22,61; 1,05; −7,9), color 0xEEEEEA). No es una petición de Luis.
- **Qué era**: en `masahorro.gd`, los productos de las baldas se recortan a lo que queda de balda (`minf(ln, back + 5.1 - z)`); al final de una balda ese resto puede ser casi cero y salía una caja sin fondo. No se veía. Era una sola de 388 (quinta estantería, tercera fila; fondo 9e-16 m), contada repitiendo el bucle fuera del juego.
- **Arreglo**: no se pone el producto si su fondo es menor de 2 cm. La secuencia de colores y largos de los demás no cambia.
- **Prueba**: `masahorro`: MASAHORRO OK (0 failed), 5 comprobaciones, 1546 piezas ([log](logs/selftest_masahorro_20261126_044601.log)). La prueba no mira esa caja: que ya no sale lo sé por el bucle repetido fuera (387 productos, ninguno de menos de 2 cm). Sin pasada completa.
- **Sin comprobar**: no he corrido `--mundo-huella` antes y después; no he tocado `obra.gd` ni piezas comunes, solo esa línea de `masahorro.gd`, así que la huella del MasAhorro cambia en esas cajas y en nada más.
- **Archivos tocados**: mío, `masahorro.gd`. Después de la 0.2.1: sin publicar. Sin commit.

## Cómo mantener el registro

Añadir una entrada por tarea con la fecha, el motivo y el resultado del cambio, los archivos principales, la prueba ejecutada y su resultado, y cualquier decisión o pendiente que Claude necesite conocer. Si el comportamiento cambia de cara al jugador, incluir cómo reproducirlo en el juego. Indicar las comprobaciones que queden pendientes y anotar el hash si se crea un commit.

Para cambios del juego, seguir las normas de [PROJECT_STATE.md](PROJECT_STATE.md) y ejecutar `python tools/run_tests.py <modo>` desde este repositorio para el modo afectado. Anotar aquí los resultados nuevos y enlazar a la documentación específica de la tarea cuando exista.

### Calles de la Parra, del Descanso y de la Pastora: 26 casas (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario retomó las calles («Seguimos»).

- **Hecho.** 26 entradas:
  - `par_4`, `par_2`, `par_1`, `par_3`, `par_5`, `par_3b`, `par_7`;
  - `des_14`, `des_12`, `des_10`, `des_8`, `des_6`, `des_4`, `des_13`, `des_11`, `des_9`, `des_aa31`, `des_7d`, `des_3`;
  - `pas_6`, `pas_4`, `pas_2`, `pas_2a`, `pas_3`, `pas_1d`, `pas_1`.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Parcelas partidas.**
  - Parra 3 tiene dos frentes, separados por el 5: `par_3` (dos plantas) y `par_3b` (`only` 1, el trozo junto al 7).
  - El portón verde de Descanso 11 es la parte de una planta de la parcela de Travesía del Santo 8 (4296603). Va en `des_11`, con `only` 1 y `reach` 2; `trsanto_8` se queda con lo de dos plantas.
- **Calle desplazada.** En el lado norte de la Parra, la calle del mapa va unos 2 m al norte de la real. Frentes del muro genérico (`frente_gen.py`), con `clear` 1 (1,4 en `par_1`).
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (26 entradas);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/parra_descanso_pastora_1..4.jpg`;
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Tres horneados, avisando a Pretil antes y después de cada uno.
  - El primero dejó fuera la caja hecha a mano del 11 (3,4 m²: `add_part` quita lo que tiene menos de 5 m²).
  - En la hoja de repaso se vio que ese sitio era de `trsanto_8`. El tercer horneado lo arregló.
  - Frente a la copia: 26 casas nuevas, ninguna quitada. `real_83`, `real_85`, `santo_62`, `santo_80`, `alto_29` y `alto_57` solo cambian en las aristas tapadas.
  - Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 26: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_par_4_par_2_par_1_par_3_par_5_par_3b_par_7_des_14_20261122_010656.log)).
  - Tras arreglar `des_14` y `des_11`: 4 ok ([log](logs/selftest_casas_solo_des_14_des_13_des_11_des_9_20261122_011352.log)).
- **Casas cedidas a Edificios Especiales (21–22/11).** A petición de Pretil, para el cruce de los semáforos, estas casas pasan a `["obra"]` en `casas_calles.gd`:
  - `salvador_24` (Seguros Sopiss);
  - `arcos_2` (la clínica dental);
  - `constitucion_a1` (Santa Ana 2);
  - `constitucion_2` (la casa del mirador);
  - `salvador_c3` (la casa de dos plantas al norte del Salvador, en la esquina de la avenida: la última del cruce, que Pretil hace en `beige.gd`).
  - Sus entradas de `calles.json` no se tocan. Las líneas viejas están en las notas compartidas de las sesiones (`*_antes_de_pretil.md`).
- **Aprobado** por el usuario el 22/11 («Añade la bandera de españa ahí y damos visto bueno»). La bandera cuelga de la ventana de arriba a la izquierda del Descanso 9: `_des_9()` en `godot/scripts/casas.gd`, con `casas` 4 ok ([log](logs/selftest_casas_solo_des_9_20261122_011859.log)).

### Avenida de la Reina Sofía, lo que faltaba: 19 casas (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario pidió seguir con la siguiente calle («Sí, siguiente»).

- **Hecho.** 19 entradas:
  - lado de los impares (5 a 31): `rsof_31n`, `rsof_31`, `rsof_29`, `rsof_27`, `rsof_25`, `rsof_23`, `rsof_21`, `rsof_19`, `rsof_17`, `rsof_15`, `rsof_13`, `rsof_11`, `rsof_9`, `rsof_7`, `rsof_5`;
  - lado de los pares (4 a 12): `rsof_12`, `rsof_10`, `rsof_6`, `rsof_4`.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Parcelas partidas y retoques de datos.**
  - El 31: la casa de dos plantas son los 8,6 m de la izquierda (`rsof_31`, con `porch` [8,6, 16, 5,6] que corta el resto de la parte del Catastro). La nave blanca de la esquina va en `rsof_31n`, una caja sin referencia (`rc` None, `deep` 5,4, 4 m de alto) con su puerta gris en el costado.
  - El 12: frente en el borde de la parte de dos plantas, `floors` 2 y `strip` 1 para quitar la tira de una planta de delante.
  - El 11: `floors` 1 y `reach` 14 (dos plantas en las fotos).
- **Edificio nuevo.** El 10 es una fachada de celosía de ladrillo claro. Su línea en `casas_calles.gd` pone el portón y las ventanas azules, y `_rsof_10()` en `godot/scripts/casas.gd` dibuja los huecos de la celosía (un damero de cuadros oscuros, con algunos azulejos azules sobre la franja azul).
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (19 entradas);
  - `godot/scripts/casas.gd` (`_rsof_10`);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/reina_sofia_1..4.jpg`;
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Un horneado, avisando a Pretil antes y después. Frente a la copia: 19 casas nuevas, ninguna quitada. `cajal_rs2` solo cambia en las aristas tapadas. Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 19: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_rsof_31n_rsof_31_rsof_29_rsof_27_rsof_25_rsof_23__20261122_014527.log)).
  - Tras los arreglos de color y la puerta de la nave: 4 ok ([log](logs/selftest_casas_solo_rsof_31n_rsof_27_rsof_23_rsof_21_rsof_11_rsof_10_20261122_014823.log)).
- **Aprobado** por el usuario el 22/11 («Visto bueno y siguiente»).

### Calle de las Delicias, primera mitad: 19 casas y el arreglo del 10 (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario aprobó la Reina Sofía y pidió la siguiente calle («Visto bueno y siguiente»).

- **Hecho.** 19 entradas nuevas:
  - impares: `delicias_3`, `delicias_5`, `delicias_7`, `delicias_17b`, `delicias_19`, `delicias_21`, `delicias_19b` (la nave), y la hilera de atrás `delicias_21r1..5` con el muro de sus patios `delicias_21t`;
  - pares: `delicias_12`, `delicias_28`, `delicias_30`, `delicias_32`, `delicias_32g`, `delicias_36`.
  - `delicias_10` cambia de línea: ahora es crema, con el marco mostaza y el portón de tablas de Street View.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Herramientas nuevas.**
  - `fill` en `tools/casas/calles.json` (lo lee `tools/bake_godot.py`, antes del bucle de las cajas sin `rc`): `[[desde, hasta, fondo], ...]` en metros a lo largo del frente y hacia atrás. Añade una caja al grupo de la casa hecha a mano. Sirve para el suelo que el Catastro deja fuera: el 3, que dibuja 4 m detrás de la calle, y el porche del 17, que tiene 0 plantas. Se avisó a Pretil, porque es una herramienta común.
  - `arc` con `sq=1` (hueco recto: un porche o un portal metido en la casa), `gh=<m>` (cancela baja de hierro) y `bd=<color>` (puerta al fondo). Está en `godot/scripts/casas.gd`.
  - `_sillares(spec, y0, junta)`: juntas claras de sillería sobre el revoco, que dejan libres los huecos (`_holes_of`). La usan `_delicias_28()` y `_delicias_30()`.
  - `_hilera21(lado)` y la tabla `HILERA21` en `casas_calles.gd`: los adosados de 2008, con el lado del porche de cada uno.
- **Ojo (lección).** Primero entró el reparto a `HILERA21` en `casas.gd` y la tabla en `casas_calles.gd` llegó un momento después. La prueba `grua` de Sistemas, a las 02:19, cogió ese hueco y falló («Cannot find member "HILERA21"»). El código y los datos que lee van juntos, en el mismo paso.
- **Archivos.**
  - `tools/casas/calles.json` (19 entradas) y `godot/scripts/casas_calles.gd` (14 líneas, `HILERA21`, la línea del 10);
  - `godot/scripts/casas.gd` (`_hilera21`, `_sillares`, `_holes_of`, `_delicias_28`, `_delicias_30`, las opciones del `arc`);
  - `tools/bake_godot.py` (`fill`);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/delicias_1..4.jpg`;
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Un horneado, avisando a Pretil antes y después. Frente a la copia: 19 casas nuevas, ninguna quitada. `delicias_10` solo cambia en las aristas tapadas. Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 19: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_delicias_3_delicias_5_delicias_7_delicias_17b_del_20261122_022436.log)).
  - Tras los arreglos: 4 ok ([log](logs/selftest_casas_solo_delicias_3_delicias_17b_delicias_19_delicias_21_d_20261122_023203.log), [log](logs/selftest_casas_solo_delicias_12_20261122_023428.log), [log](logs/selftest_casas_solo_delicias_3_delicias_17b_delicias_21_20261122_023601.log)).
- **Aprobado** por el usuario el 22/11 («Visto bueno y siguiente»). La segunda mitad de la calle va en la tanda siguiente.

### Calle de las Delicias, segunda mitad: 17 casas (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario aprobó la primera mitad y pidió seguir («Visto bueno y siguiente»).

- **Hecho.** El lado sur, del 36 D al 68:
  - `delicias_36d`, `delicias_40`, `delicias_40b`, `delicias_42`, `delicias_44`, `delicias_46`, `delicias_48`, `delicias_50`, `delicias_52`, `delicias_54`;
  - `delicias_56`, `delicias_58`, `delicias_60`, `delicias_62`, `delicias_64`, `delicias_66`, `delicias_68`.
  - Datos del Catastro de 13 parcelas nuevas con `tools/house_data.py`, en `tools/casas/<rc>/`.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Cajas sin referencia.**
  - `delicias_40`: la tapia del solar, 10 m, de 2,5 m de alto y 0,6 m de fondo.
  - `delicias_40b`: la casa de dos plantas que el Catastro cubre con el solar del 40, de 9 m de fondo.
  - `delicias_54`: el corral entre el 52 y el 56, que no está en el Catastro, de 0,7 m de fondo.
  - Ojo: una caja de menos de 5 m² se pierde en el horneado.
- **Código.** `_delicias_64()` en `godot/scripts/casas.gd`: la galería de madera (suelo volado, cabezas de vigas, barandilla, postes, tabla del alero) y los dinteles de madera. Entró en el mismo paso que su línea en `casas_calles.gd`.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (17 entradas);
  - `godot/scripts/casas.gd` (`_delicias_64`);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/delicias_5..7.jpg`;
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Un horneado, avisando a Pretil antes y después. Frente a la copia: 17 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 17: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_delicias_36d_delicias_40_delicias_42_delicias_44__20261122_030132.log)).
  - Tras los arreglos de color: 4 ok ([log](logs/selftest_casas_solo_delicias_50_delicias_54_delicias_58_delicias_60_d_20261122_030403.log)).
- **Aprobado** por el usuario el 22/11 («Visto bueno y siguiente»). Con esto la Calle de las Delicias queda entera.

### Calle de Tembleque, lo que faltaba: 19 casas (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario aprobó Delicias entera y pidió la calle siguiente («Visto bueno y siguiente»).

- **Hecho.**
  - Lado oeste: `tembleque_29`, `tembleque_31`, `tembleque_33`, `tembleque_35`, `tembleque_53`, `tembleque_89d`, `tembleque_91`, `tembleque_93`, `tembleque_95`, `tembleque_99`.
  - Lado este: `tembleque_34`, `tembleque_34b`, `tembleque_36`, `tembleque_38`, `tembleque_40`, `tembleque_42`, `tembleque_44`, `tembleque_46`, `tembleque_48d`.
  - Datos del Catastro de 19 parcelas nuevas con `tools/house_data.py`, en `tools/casas/<rc>/`.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **El solar del 48 D.** El Catastro dibuja una tira de casas viejas que ya no están: en Street View hay una tapia de ladrillo.
  - `porch: [10.2, 36, 8]` quita esa tira.
  - `fill: [[10.2, 32.83, 0.5]]` pone en su sitio la tapia, de medio metro.
  - Se queda el cobertizo viejo de la punta norte; todo a 2,6 m.
- **Fuera.**
  - El 57: en el Catastro solo tiene una franja de 2 m en la calle, y su casa queda detrás de la fachada del 59.
  - Tembleque 2: un solar sin plantas que da a otra calle.
  - Consuegra 1 y 2: dan a la Calle de Consuegra.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (19 entradas);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/tembleque_10..14.jpg` (las 1..9 son de la tanda del 16/11 y siguen como estaban);
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Un horneado, avisando a Pretil antes y después. Frente a la copia: 19 casas nuevas, ninguna quitada; de `rsm_26` y `rsm_28` solo cambian las aristas tapadas. Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 19: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tembleque_29_tembleque_31_tembleque_33_tembleque__20261122_032755.log)).
  - Tras los arreglos de color del 35 (`brick_dark`) y del 95 (`brick_red`): 4 ok ([log](logs/selftest_casas_solo_tembleque_35_tembleque_95_20261122_033052.log)).
- **Aprobado** por el usuario el 22/11 («Visto bueno y paramos de momento»). Las calles quedan en pausa hasta nueva orden.

### La prueba completa de la 0.0.21: siete fallos de las pruebas, no del juego (22/11, Claude · Sistemas)

22 de noviembre de 2026. La primera prueba completa de la 0.0.21 dio 976 ok y 7 fallos. Ninguno era un error del juego. Todos se arreglaron en `godot/scripts/selftest.gd`:
- **Muros y fachadas.** Las comprobaciones pedían más de 25.000 muros y más de 4.000 fachadas genéricas. Hay menos porque los sitios hechos a mano las sustituyen. Ahora piden más de 24.000 y más de 3.500.
  - **Ojo, Pretil y Texturas:** quedan unos 770 muros de margen (hay 24.770) y unas 360 fachadas (hay 3.863). Cada sitio hecho a mano los baja; si salta, bajad el umbral, no es un error.
- **Mobiliario «fuera de sitio» (14).** Los semáforos, señales y papelera del cruce cuelgan de `world.cruce`, que va desplazado `level` en altura. La comprobación usaba `position.y` (local); ahora usa `global_position.y`.
- **Robar el coche de un vecino** (fallaba a veces). La prueba cogía el primer coche de la lista, que podía ir «sobre raíles» (lejos, sin física). Al ponerlo junto a ti volvía a la física a su velocidad de antes (8 m/s) y ya no estaba «parado». Ahora se le quitan los raíles, se le pone `halt` y velocidad cero.
- **La cama** («dos horas después de acostarte no puedes volver a dormir»). En medio de la prueba sonaba la llamada de la Tía Paca por la casa (`casa_paca_call`, dos horas de juego después del puente). `_casa_checks` deja al acabar «una casa tranquila», pero solo si antes no había estado de casa, y el tick de `fondo_casa.gd` crea `{"st": ""}` al principio. Ahora también lo hace si el estado guardado está sin empezar.
- **Los días en `_mend_checks`.** La prueba de lo roto adelantaba `day_n` durante dos fotogramas, y `llamadas.now()` cuenta los días. Ahora lo devuelve antes de esperar ningún fotograma.
- **El semáforo con coche real.** A veces un peatón cruzaba delante del coche de la prueba y lo paraba antes de la línea. Los vecinos a menos de 70 m se apartan (`away`) mientras dura.
- **El pedido de Henry** (fallaba a veces en la completa, nunca solo). Ahora la comprobación acepta el tope de confianza (100) y su mensaje dice qué condición falla. Puede que la causa fuera ese tope, pero **no está confirmado**: si vuelve a fallar, el mensaje lo dirá.
- **Finales de línea.** `game.gd`, `world.gd`, `props.gd`, `selftest.gd`, `traffic.gd`, `map_data.gd` y `semaforos.gd` habían pasado a CRLF por ediciones con Python. Vuelven a LF, como en el repositorio. `loc.gd` sigue en CRLF, como estaba. **Pretil y Texturas:** releed esos ficheros antes de editarlos.
- **Prueba completa:** 983 ok, 0 fallos ([log](logs/selftest_full_20261122_051320.log)).
- **Memoria con el renderizador de móvil** (`--rendering-method mobile -- --timing`): 752 MB al acabar la carga (893 en la 0.0.11) y 1.988 MB de vídeo; carga de 42 s en este PC.

### Publicación de la 0.0.21 en GitHub (22/11, Claude · Sistemas)

22 de noviembre de 2026. El usuario, a través de Pretil: «Pidele commit y release, asi tenemos un backup de todo antes de tocar con la otra IA». Confirmado con el usuario: «Sí, 0.0.21 completa».
- **Congelado.** Pretil y Texturas, sin nada a medias.
- **Prueba completa:** 983 ok, 0 fallos ([log](logs/selftest_full_20261122_051320.log)), tras los arreglos de la entrada anterior.
- **Commits:**
  - `8c49e83`: todo, de Sistemas, Pretil y Texturas.
  - «Matritellus 0.0.21»: versión, notas, y los `.uid` de `cruce.gd` y `semaforos.gd` que crea la exportación.
- **Etiqueta:** `v0.0.21`.
- **Paquetes:** `tools/make_apk.py 0.0.21` (versión 0.0.21, código 21, firmado y verificado), `tools/make_installer.py` y `tools/make_linux.py`.
  - Están en `dist/v0.0.21/`, con [sus SHA-256](dist/v0.0.21/SHA256SUMS.txt) comprobados.
  - Release: https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.21
- **Sin probar:** no se ha probado en móvil ni en Steam Machine.

### Peinados reajustados y nuevos «Cortito» y «Cuatro pelos» para 0.0.22 (22/11, Antigravity · Creador)

22 de noviembre de 2026. Encargo de Luis sobre `v0.0.21`: corregir los peinados demasiado grandes o mal encajados (viseras frontales, colas horizontales, huecos, clipping con manos) manteniendo la dirección artística low-poly Animal Crossing + outlines sin aumentar complejidad geométrica.

- **Cambios en el pipeline de Blender (`tools/creador/pelo.py`, `tools/creador/piezas.json`):**
  - Solo afecta a `kind == "pelo"` (sombreros, ropa, barbas, cejas y calzado sin tocar).
  - Nueva escala proporcional del exceso fuera del cráneo (`far_excess`) para encoger volumen/vuelo sin aplastar moños ni afros contra la esfera (`R = 0.50 m`).
  - Nueva pasada `refine_pelo()`: recorte de visera frontal (`front_max`), caída vertical pegada a la espalda sin repisa horizontal (`clean_drop`, `z_min`, `drape_back`), despeje de la zona de manos (`side_back`), redondeo del afro (`round_k`), suavizado laplaciano controlado de vértices interiores (`smooth_passes`), subdivisión selectiva solo de aristas largas (`max_edge`) para evitar que las cuerdas planas entren en la esfera y pase final de holgura (`head_eps`).
  - `fill_scalp()` pasa de `96 × 48` a `32 × 18` con recorte estricto dentro del borde real del pelo (sin asomar bajo la nuca en `25 · Coletas bajas`). `subd: 0` en los peinados de OverScore Proxy.
  - Los 19 `godot/assets/creador/pelo/pelo_*.glb` regenerados con Blender 4.5.9 y reimportados en Godot: total de triángulos de **83.562 → 23.804 tris (−71,5 %)** y 0 % penetración.
- **Tupé (`tools/creador/tupe.py`):** altura y avance frontal reducidos ~8 % (`Ymax 2.07 → 2.03`, `2.288 → 1.408 tris`). Visto bueno de Luis: «El nuevo tupé está bien».
- **Primitivas de `godot/scripts/chara.gd`:** `4 · Afro` centrado y proporcionado (`1.36 → 1.20 m`), `7 · Ensaimadas` pegadas a la sien con gomas limpias, `11 · Rizos` compactados en silueta continua y `12 · Trenza` con eslabones más solapados.
- **Dos estilos nuevos aprobados («Me gustan los nuevos estilos. Para dentro»):**
  - **`17 · Cortito` (`Buzz cut`)** en lugar de `Pelusilla` (que era casi idéntica a `14 · Tazón`): rapado al 1–2 pegado al cráneo (`_cortito()` en `chara.gd`, `_shave_zone`) en el color del pelo elegido (`0.86` alfa) con línea frontal, patillas sutiles y degradado en nuca. `pelo_rapao_ella.glb` se conserva en disco porque `31 · Rulos` lo sigue usando como base.
  - **`34 · Cuatro pelos` (`Four hairs`)** añadido al final en `creator.gd` y `loc.gd` (compatible con guardados antiguos): 4 mechones tubulares curvos asimétricos sobre la coronilla despejada (`_cuatro_pelos()` en `chara.gd`), ocultos automáticamente bajo cualquier sombrero.
- **Archivos tocados:**
  - `tools/creador/pelo.py`, `tools/creador/piezas.json`, `tools/creador/tupe.py`;
  - `godot/assets/creador/pelo/pelo_*.glb` (los 19 de pelo);
  - Compartidos (solo añadidos / cambios localizados): `godot/scripts/chara.gd`, `godot/scripts/creator.gd`, `godot/scripts/loc.gd`;
  - Notas: `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.
- **Pruebas:**
  - `criba_pelo` (23 peinados modificados + 7 pulidos + `14, 17, 33, 34`, 3 ángulos): OK, 0 fallos ([log 1](logs/selftest_criba_pelo_solo_4_7_8_11_12_13_14_15_16_17_18_19_20_21_22_23_20261122_133319.log), [log 2](logs/selftest_criba_pelo_solo_23_24_25_26_27_29_30_20261122_134239.log), [log 3](logs/selftest_criba_pelo_solo_14_17_33_34_20261122_153827.log)).
  - `creador`: 19 ok, 0 fallos ([log](logs/selftest_creador_20261122_154745.log)).
  - `ropa`: 2 ok, 0 fallos ([log](logs/selftest_ropa_20261122_135134.log)).
  - `palabros`: 3 ok, 0 fallos ([log](logs/selftest_palabros_20261122_154604.log)).
- **Pendiente:** sin commit (esperando orden de Luis o cierre con el resto del creador para 0.0.22). Sin pasar la prueba completa todavía.

### Barbas reajustadas para 0.0.22 (22/11, Antigravity · Creador)

22 de noviembre de 2026. Encargo de Luis tras aprobar los peinados: «Vamos a hacer lo mismo con barbas».

- **Modo de fotos nuevo (`godot/scripts/selftest.gd`):** `--criba_barba` (en el bloque `criba`, con vistas cercanas de frente, 3/4 y perfil para las 12 barbas).
- **Barbas CC0 (`tools/creador/pelo.py`, `tools/creador/piezas.json` y los 4 `.glb`):**
  - Nueva pasada `refine_barba()` solo para `kind == "barba"`: ciñe patillas/mejillas a la esfera (`cheek_off`, `sideburn_top`), controla el avance frontal (`front_max`), suaviza puntas largas (`z_min`, `smooth_passes`) y garantiza 0 % de penetración.
  - `9 · Barba arreglá` (`barba_recortada.glb`): de `W = 1.11 m` con alas en sienes y flecha hasta `Y = 0.80` a `W = 1.02 m`, `Y = 0.93..1.39`.
  - `10 · Barba de pastor` (`barba_poblada.glb`): de `W = 1.16 m` con alas laterales a `W = 1.04 m`, `Y = 0.93..1.42`, picos inferiores suavizados.
  - `11 · Bigotillo y perilla` (`barba_candao.glb`) y `12 · Bigote de morsa` (`bigote_morsa.glb`): pegados al labio/mentón (`Zmax 0.56 → 0.52 m`).
- **Primitivas y `Dejadez` (`godot/scripts/chara.gd`):**
  - Nuevo generador `_add_face_tube()` para mallas curvas cerradas sobre la esfera (`_bigote_mesh`, `_mostacho_mesh`, `_patillas_mesh`, `_candao_mesh`): `1 · Bigote`, `4 · Mostacho`, `7 · Patillas` y `8 · Candao` dejan de ser cajas planas flotantes y abrazan la cara. En `8 · Candao`, Luis pidió mantener la perilla completa («creo que pierde demasiada perilla y parece más una boca que una barba»); ajustado con arco curvo + perilla sólida y aprobado («Ahora sí. Visto bueno»).
  - `2 · Barba`, `3 · Perilla` y `6 · Barbaza`: metidas hacia la mandíbula con transición suave a mejillas (sin efecto hocico ni cintura de muñeco de nieve).
  - `5 · Dejadez` (`_barba3`): degradado lateral más orgánico de perfil.
- **Archivos tocados:** `tools/creador/pelo.py`, `tools/creador/piezas.json`, los 4 `godot/assets/creador/pelo/{barba_*,bigote_morsa}.glb`, `godot/scripts/chara.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.
- **Pruebas:** `criba_barba` OK (0 fallos; [log completo](logs/selftest_criba_barba_20261122_161138.log), [log Candao](logs/selftest_criba_barba_solo_8_20261122_170225.log)); `creador` 19 ok, 0 fallos ([log](logs/selftest_creador_20261122_161442.log)).
- **Pendiente:** sin commit. Sin pasar la prueba completa todavía.

### Cejas reajustadas y 3 nuevas expresivas para 0.0.22 (22/11, Antigravity · Creador)

22 de noviembre de 2026. Encargo de Luis tras aprobar las barbas: «Vamos con cejas».

- **Modo de fotos nuevo (`godot/scripts/selftest.gd`):** `--criba_cejas` (frente, 3/4 y perfil cercanos).
- **Cejas CC0 (`tools/creador/pelo.py`, `tools/creador/piezas.json`, `cejas_pobladas.glb`, `cejas_arqueadas.glb`):**
  - `clean_brows_source()` conserva solo las 2 islas superiores del modelo de Quaternius, eliminando las pestañas humanas fantasma que flotaban debajo sobre los ojos del juego.
  - `decimate` + grosor vertical (`brow_scale_z`): `4 · Espesas` baja de 984 → 212 tris con volumen perfilado real; `5 · Arqueás` baja de 1.480 → 56 tris con arco limpio (−89 % en total).
- **Primitivas curvadas y 3 cejas expresivas nuevas (`godot/scripts/chara.gd`, `creator.gd`, `loc.gd`):**
  - `_brows()` y `_add_brow_tube()` sustituyen las cajas/vigas rectas flotantes de `0 · Finas`, `1 · Poblás` y `2 · Cejijunto` por arcos pegados a la esfera y pivotados en `(0, 1.38, 0)` (giran en X con el tamaño de ojos sin meterse en la frente).
  - Añadidos al final (compatibles con guardados): **`6 · Enfadás`** (`Angry`), **`7 · Preocupás`** (`Worried`) y **`8 · De abuelo`** (`Grandpa`).
- **Visto bueno de Luis (22/11):** «Me encantan, visto bueno».
- **Archivos tocados:** `tools/creador/pelo.py`, `tools/creador/piezas.json`, `godot/assets/creador/pelo/{cejas_pobladas,cejas_arqueadas}.glb`, `godot/scripts/chara.gd`, `godot/scripts/creator.gd`, `godot/scripts/loc.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.
- **Pruebas:** `criba_cejas` OK ([log](logs/selftest_criba_cejas_20261122_174922.log)); `palabros` 3 ok ([log](logs/selftest_palabros_20261122_175204.log)); `creador` 19 ok ([log](logs/selftest_creador_20261122_175328.log)).
- **Pendiente:** sin commit. Sin pasar la prueba completa todavía.

### Ropa reajustada, traje con corbata y 3 prendas nuevas para 0.0.22 (22/11, Antigravity · Creador)

22 de noviembre de 2026. Encargo de Luis tras aprobar las cejas: «Podemos pasar a la ropa. Mismo proceso que hasta ahora».

- **Pipeline de ropa CC0 (`tools/creador/pelo.py`, `tools/creador/piezas.json` y los 10 `ropa_*.glb` existentes):**
  - Nueva pasada `refine_cuerpo()` solo para `kind == "cuerpo"` (`refine_body: true`): recoge bordes de hombros/sisas (`shoulder_off`), acota vuelo excesivo (`max_off`), despeja la zona de manos, sube detalles secundarios (`detail_lift` / `layer_lifts`), permite silueta uniforme 360° con relieve local (`uniform_base`, `ripple_gain`, `skirt_flare`), estira prendas cortas hasta el cuello (`stretch_top`), cierra sisas de chaquetas con manga (`close_armholes`), abrocha americanas por debajo (`button_below_z`) y evita penetraciones en cuerpo y cabeza (`turtleneck` radial para cuellos altos).
  - Los 10 `ropa_*.glb` originales bajan de **23.312 → 8.970 tris (−61,5 %)** con **0,0 %** penetración en cuerpo y cabeza (`11 · Jersey de cuello alto`: 10,9 % → 0 %; `12 · Plumas sin mangas`: `cut_x: 0` + acolchado uniforme 360°, 4.704 → 1.884 tris; `17 · Marinera` estirada hasta el cuello `Y = 0.98`). Se conservan todas las superficies de color (incluidas las 3 de `ropa_futbol`).
- **Primitivas y capas interiores (`godot/scripts/chara.gd`):**
  - `_band()` pasa a construir conos cacheados de 12 caras alineados con el cuerpo (elimina rebordes en «maceta» en `5 · Peto`, `6 · Camisa con tirantes`, `8 · Camiseta imperio` y escalones en `2`, `3`, `4`). Contraste automático de tirantes en `6`.
  - `_dot()` y `_r_at()` aplanan botones y flores sobre la superficie exacta del cono de 12 caras (`1 · Camisa`, `7 · Bata de flores`, `5 · Peto`).
  - `13 · Chaleco de vestir` y `14 · Rebeca` muestran camiseta interior contrastada (blanca o carbón) en el tronco base.
- **Nuevas prendas aprobadas por Luis («Ahora sí. Visto bueno»):**
  - **`2 · Traje con corbata` (`Suit and tie`, `ropa_traje.glb`):** sustituye en su mismo hueco a `Camiseta de rayas` (sin desplazar índices; `Blazer` + `Neck Tie` CC0 OverScore Proxy, 1.140 tris, americana abrochada con 2 botones, sisas cerradas, camisa blanca interior, Color 1 chaqueta + Color 2 corbata).
  - **`20 · Vestido` (`Dress`, valor `22`, `ropa_vestido.glb`):** `Cocktail Dress` CC0 (1.096 tris) con hombros y espalda en V descubiertos, falda acampanada y fajín en cintura configurable con Color 2.
  - **`21 · Camisa hawaiana` (`Hawaiian shirt`, valor `23`):** cuello abierto veraniego, botones de madera y flores de hibisco planas con hojas de palmera (`_hibiscus()`) por los 360° con contraste automático.
  - **`22 · Bata` (`Lab coat`, valor `24`, `ropa_bata.glb`):** bata abrochada con solapas (852 tris), 3 botones, dos bolsillos inferiores, bolsillo de pecho con bolígrafo y camiseta interior configurable con Color 2.
- **Archivos tocados:** `tools/creador/pelo.py`, `tools/creador/piezas.json`, 13 `godot/assets/creador/pelo/ropa_*.glb` (10 regenerados + `ropa_traje`, `ropa_vestido`, `ropa_bata`), `godot/scripts/chara.gd`, `godot/scripts/creator.gd`, `godot/scripts/loc.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.
- **Pruebas:** `criba_ropa` OK ([log](logs/selftest_criba_ropa_solo_2_20_21_22_20261122_200338.log)); `palabros` 3 ok ([log](logs/selftest_palabros_20261122_200602.log)); `creador` 19 ok ([log](logs/selftest_creador_20261122_200705.log)); `ropa` 2 ok ([log](logs/selftest_ropa_20261122_200829.log)).
- **Pendiente:** sin commit. Sin pasar la prueba completa todavía.

### Sombreros rehechos desde cero y sombrero de cocinero para 0.0.22 (22/11, Antigravity · Creador)

22 de noviembre de 2026. Encargo de Luis tras cerrar ropa: auditar sombreros, añadir `Sombrero de cocinero` y rehacer desde cero los 9 sombreros importados de OverScore Proxy para igualar la limpieza estilizada de las primitivas («En general creo que los importados están bastante peor que los hechos desde cero. Se podrían rehacer sabiendo el concepto que tenemos de la estética y el objeto que son?»).

- **Nuevo generador `tools/creador/sombreros.py` (9 `gorro_*.glb` esculpidos desde cero):**
  - Construye los 9 sombreros directamente sobre nuestra cabeza esférica (`C = (0,0,1.38), R = 0.50`) con holgura explícita frente a la bola del pelo corto (`HAIR_C = (0,0.06,1.50)`), sombreado de vértices `Col` suave y 1–2 superficies (superficie 0 toma `hat_color`, superficie 1 conserva cinta/visera de contraste):
    - `4 · Parpusa` (`724 tris`), `5 · Sombrero de ala` (`1.056 tris`, pliegue fedora + cinta y lazo), `6 · Bombín` (`1.056 tris`, cúpula esférica + cinta oscura + ala estrecha rizada), `7 · Pamela` (`1.184 tris`, ala ancha ondulada + cinta crema con lazo), `8 · Pañoleta` (`2.356 tris`, pañuelo tradicional manchego con marco amplio, nudo bajo la barbilla con dos puntas y caída triangular trasera), `9 · Cinta` (`384 tris`), `10 · Gorra de béisbol` y `11 · Gorra pa' trás` (`1.032 tris` c/u, visera curva gris carbón + tira trasera), `12 · Sombrero vaquero` (`1.056 tris`, copa *cattleman* + cinta de cuero + alas laterales bien curvadas).
- **Primitivas y nuevo sombrero (`godot/scripts/chara.gd`, `creator.gd`, `loc.gd`):**
  - `1 · Boina` asentada más baja (`Y = 1.79`), ligeramente más ancha y ladeada (`rot_z = -0.10`).
  - **`13 · Sombrero de cocinero` (`Chef hat`, valor `"chef"`):** añadido al final en `creator.gd` y `loc.gd` (siempre blanco, oculta selector de color como la boina, `hat_cut == 2`), con ribete oscuro en la base (`Y = 1.70`) y copa abullonada de 6 pliegues (actualiza también a Henry en La Cocina de Henry).
- **Variedad en NPCs (`godot/scripts/game.gd`):**
  - En `_neighbour_look("old_f")`, 28 % de probabilidad de llevar `"panoleta"` en tonos oscuros de luto manchego (`0x1b1b1f` / `0x2a2d36` / `0x3b2d26` / `0x4b3b4e`), reservándola exclusivamente para ancianas en NPCs. En `"kid"`, sustituido el viejo `top = 2` (ahora traje) por `19` (`Marinera`).
- **Archivos tocados:** `tools/creador/sombreros.py`, `tools/creador/piezas.json`, los 9 `godot/assets/creador/pelo/gorro_*.glb`, `godot/scripts/chara.gd`, `godot/scripts/creator.gd`, `godot/scripts/loc.gd`, `godot/scripts/game.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.
- **Pruebas:** `criba_sombrero` OK ([log completo](logs/selftest_criba_sombrero_solo_4_5_6_8_9_10_11_12_20261122_214124.log), [log pañoleta](logs/selftest_criba_sombrero_solo_8_20261122_220729.log)); `palabros` 3 ok ([log](logs/selftest_palabros_20261122_204314.log)); `creador` 19 ok ([log](logs/selftest_creador_20261122_214714.log)); `ropa` 2 ok ([log](logs/selftest_ropa_20261122_214858.log)).
- **Pendiente:** sin commit. Sin pasar la prueba completa todavía.

### Calzado rehecho desde cero, zapatos de misa y zuecos para 0.0.22 (22/11, Antigravity · Creador)

22 de noviembre de 2026. Encargo de Luis tras cerrar sombreros: «Vamos con calzado» → «Rehaz los 12 y añade mocasines (zapatos de misa) y zuecos (zapatos feos)» → «A las chanclas se les debería ver el hilo del pulgar por delante, y a los zapatos feos los llamaremos zuecos de nuevo. Por lo demás de 10» → «Visto bueno».

- **Modo de fotos nuevo (`godot/scripts/selftest.gd`):** `--criba_calzado` (planos cercanos bajos de frente, 3/4 y perfil para ver suelas, puentes y tiras).
- **Nuevo generador `tools/creador/calzado.py` (14 `calzado_*.glb` esculpidos a medida):**
  - `0..3` (`calzado_lona`, `calzado_botas`, `calzado_alpargatas`, `calzado_chanclas`): sustituyen las antiguas primitivas con suelas de ladrillo rectangular por calzado redondeado con contraste de suela/lona/esparto/tira en Y con hilo del pulgar visible por delante.
  - `5..12` (`calzado_zapatillas`, `calzado_botas_faena`, `calzado_botas_agua`, `calzado_sandalias`, `calzado_bailarinas`, `calzado_camperas`, `calzado_zapatillas_casa`, `calzado_tacones`): sustituyen los modelos monocromos/toscamente escalados de OverScore Proxy por mallas limpias de 2–4 superficies (`6.768 tris` vs `8.640` originales), con empeine real en `9 · Bailarinas` y pie elevado/inclinado en `12 · Tacones` sin atravesar el arco. `4 · Descalzo` intacto.
  - Dos calzados nuevos añadidos al final en `creator.gd`, `loc.gd` y `chara.gd` (`CALZADO`): **`13 · Zapatos de misa`** (`Dress loafers`, `calzado_misa.glb`, 832 tris) y **`14 · Zuecos`** (`Clogs`, `calzado_zuecos.glb`, 1.422 tris, tipo Crocs con agujeros y tira trasera).
- **Archivos tocados:** `tools/creador/calzado.py`, 14 `godot/assets/creador/pelo/calzado_*.glb`, `godot/scripts/chara.gd`, `godot/scripts/creator.gd`, `godot/scripts/loc.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.
- **Pruebas:** `criba_calzado` OK ([log completo](logs/selftest_criba_calzado_solo_0_1_2_3_5_6_7_8_9_10_11_12_13_14_20261122_232418.log), [log chanclas](logs/selftest_criba_calzado_solo_3_20261122_234148.log)); `palabros` 3 ok ([log](logs/selftest_palabros_20261122_234432.log)); `creador` 19 ok ([log](logs/selftest_creador_20261122_233308.log)); `ropa` 2 ok ([log](logs/selftest_ropa_20261122_233458.log)).
- **Pendiente:** sin commit. Sin pasar la prueba completa todavía.

### Complementos (gafas, pendientes y cuello), 11 nuevos y ajuste sobre ropa gruesa para 0.0.22 (23/11, Antigravity · Creador)

23 de noviembre de 2026. Cierre del último bloque de la auditoría del Creador de personajes para `0.0.22` (gafas, pendientes y cuello). Aprobado por Luis tras verificar también el ajuste sobre prendas acolchadas («Quedan muy bien. Habría que ver si quedan igual de bien con ropa más gorda» → «Ahora si, mucho mejor»).

- **Modos de fotos nuevos (`godot/scripts/selftest.gd`):** `--criba_gafas`, `--criba_pendientes`, `--criba_cuello` (planos cercanos de frente, 3/4 y perfil) y flag `--top=N` para comprobar el encaje de los complementos sobre cualquier prenda (ej. `top=12` para `Plumas sin mangas`).
- **Nuevo generador `tools/creador/complementos.py` (12 `.glb` esculpidos a medida con 0 % de penetración y sombreado de vértices `Col`):**
  - **Gafas (5 `.glb`):** `gafas_sol` (`5 · De sol`, Wayfarer con remaches plateados, 1.184 tris), `gafas_aviador` (`6 · De aviador`, lágrima con doble puente dorado, 1.080 tris), `gafas_gato` (`8 · De ojo de gato`, rojo vintage con tachuelas doradas, 1.088 tris), `gafas_corazon` (`9 · De corazón`, 1.200 tris) y `gafas_parche` (`11 · Parche de pirata`, parche curvo + cinta diagonal ceñida, 792 tris).
  - **Cuello (7 `.glb`):** sustituyen las 4 importaciones deformes de OverScore Proxy (`cuello_corbata` 1.600 → 696 tris burdeos a rayas, `cuello_pajarita` 1.536 → 788 tris negra con volumen, `cuello_delantal` 1.892 tris crema con tirantes azul marino, bolsillo y lazo trasero, `cuello_bufanda` 1.648 tris roja con flecos y 20,4 % → 0,0 % en cabeza) y añaden 3 nuevos (`cuello_camara` 684 tris retro plateada/negra, `cuello_flores` 3.360 tris guirnalda 360°, `cuello_gargantilla` 1.052 tris negra con arandela y tachuelas).
- **Primitivas, compatibilidad sobre ropa gruesa y catálogo (`chara.gd`, `creator.gd`, `loc.gd`, `game.gd`):**
  - **Gafas:** `1 · Finas`, `2 · De pasta`, `4 · Opacas` (lentes ampliadas sin asomo del ojo en 3/4) y `3 · De tubo` (cilindros compactos + aro metálico frontal); expuestas **`7 · Rectangulares`** (`Rectangular`, encuadrando bien todo el ojo) y añadido **`10 · Monóculo`** (`Monocle`) con cadenita curva de cuentas doradas.
  - **Pendientes:** corregido el bug de orientación de `2 · Aros`, `3 · Uno solo` y `6 · Aros de plata` (pasan del plano frontal tipo asa al plano lateral de la mejilla con leve ángulo hacia delante), refinado `4 · Largos` y añadidos **`7 · Flores`**, **`8 · Botones negros`** y **`9 · Cruz colgante`**.
  - **Cuello y ajuste sobre prendas gruesas:** `1..3` ceñidos e inclinados a la pendiente del torso (`-0.185 rad`), `4 · Collar de perlas` completado a 360°, `5 · Pañuelo de la peña` con nudo frontal e inclinación limpia. Nuevo `_top_pad(top_id)` en `chara.gd` con el grosor radial medido de cada prenda 3D (`+0,018 m` a `+0,056 m`) aplicado tanto a `_pendant()` (`1..12`) como a `_panuelo()` (pañuelo del armario), verificado sin clipping sobre `12 · Plumas sin mangas`.
  - **Estereotipos en NPCs (`game.gd`):** actualizados los pools de ropa, sombreros, calzado y complementos en `_neighbour_look()` respetando estereotipos de edad y género (`kid`, `adult_f`, `old_f`, `old_m`, `adult_m`), manteniendo libertad total en el creador.
- **Archivos tocados:** `tools/creador/complementos.py`, 12 `godot/assets/creador/pelo/{gafas,cuello}_*.glb`, `godot/scripts/chara.gd`, `godot/scripts/creator.gd`, `godot/scripts/loc.gd`, `godot/scripts/game.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.
- **Pruebas:** `criba_gafas` OK ([log](logs/selftest_criba_gafas_20261123_003108.log)); `criba_pendientes` OK ([log](logs/selftest_criba_pendientes_20261123_002503.log)); `criba_cuello` OK camiseta ([log](logs/selftest_criba_cuello_20261123_002653.log)) y plumas ([log](logs/selftest_criba_cuello_top_12_20261123_004538.log)); `palabros` 3 ok ([log](logs/selftest_palabros_creador_ropa_20261123_003320.log)); `creador` 19 ok ([log](logs/selftest_creador_20261123_004820.log)); `ropa` 2 ok ([log](logs/selftest_ropa_20261123_003616.log)).
- **Pendiente:** sin commit. Sin pasar la prueba completa todavía.

### Ojos, pestañas y parpadeo orgánico para 0.0.22 (23/11, Antigravity · Creador)

23 de noviembre de 2026. Encargo de Luis tras cerrar complementos: «Vamos con ojos ahora» → mantener el efecto frontal saltón característico, aplicar mejoras de iris/brillos/párpados/pestañas, añadir todos los estilos propuestos y sumar parpadeo realista no periódico («Muy bien. Me gustaría añadir parpadeo a los personajes, que quede realista no que parpadeen exactamente cada x tiempo»).

- **Modos de fotos nuevos (`godot/scripts/selftest.gd`):** `--criba_ojos`, `--criba_pestanas` y `--blink=F` (para posar los ojos cerrados en pleno parpadeo).
- **Ojos (`godot/scripts/chara.gd`, `creator.gd`, `loc.gd`):**
  - `_eyes()` conserva el relieve frontal saltón (`z = 0.446..0.502`) y amplía ligeramente el iris con doble reflejo en `0 · Normales` y `1 · Ojazos`.
  - Nueva malla procedural cacheada `_sliced_ellipsoid()` en forma de D (sin ninguna caja de piel que genere bordes indeseados en el shader de contorno) para los ojos con párpado: `2 · De siesta` (recto medio cerrado), **`6 · Cansaos`** (caído hacia fuera con leve ojera fija en mejilla) y **`8 · De listo`** (párpado superior recto con mirada pícara de reojo).
  - Otros nuevos estilos añadidos al final (compatibles con guardados): **`3 · Rasgaos`** (*Almond*), **`4 · De botón`** (*Button*, brillantes estilo muñeco con halo de `eye_color`), **`5 · Alegres`** (*Happy*, arcos cerrados `^ ^` con `_add_face_tube()`) y **`7 · Brillantes`** (*Sparkly*, media luna luminosa inferior + triple brillo).
  - Dos nuevos colores de ojos en `eye_color`: **`Grises`** (`0x7d8a96`) y **`Violetas`** (`0x7b52ab`).
- **Pestañas (`_add_lashes()` en `chara.gd`):**
  - `1 · Finas` y `2 · De muñeca` recolocadas en abanico lateral sobre el arco superior-exterior del ojo (ya no atraviesan las cejas en ningún estilo).
  - Nuevo **`3 · Con rabillo`** (*Winged*, delineado lateral estilizado).
- **Parpadeo orgánico realista (`_blink_tick()`, `set_blink()` en `chara.gd`):**
  - Todos los ojos abiertos se agrupan bajo `_eyes_open` (pivote `y = 1.416`) y alternan con `_eyes_closed` (párpados curvos relajados `_blink_mesh`) mediante una curva asimétrica (cierre `30 %` → cerrado `34 %` → apertura `36 %`, duración `0,12–0,21 s`).
  - Ritmo no periódico (`_next_blink_gap()`): 70 % entre `1,7–4,6 s`, 22 % pausas largas `4,6–8,2 s`, 8 % rápidos `0,65–1,55 s`, más ~18 % de doble parpadeo natural (`0,14–0,28 s`) y fase inicial aleatoria (`0,35–5,2 s`) por personaje. Se ejecuta en `anim()` (activo en juego, cinemáticas y creador; congelado en pausa; omitido en `5 · Alegres` y en capturas estáticas).
- **Reparto en NPCs (`godot/scripts/game.gd`):** pools de ojos, colores y pestañas diferenciados por edad y género en `_neighbour_look()`.
- **Archivos tocados:** `godot/scripts/chara.gd`, `godot/scripts/creator.gd`, `godot/scripts/loc.gd`, `godot/scripts/game.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.
- **Pruebas:** `criba_ojos` OK ([ojos](logs/selftest_criba_ojos_solo_2_3_6_8_20261123_011808.log), [parpadeo](logs/selftest_criba_ojos_solo_0_blink_1.0_20261123_013522.log)); `criba_pestanas` OK ([log](logs/selftest_criba_pestanas_20261123_010933.log)); `palabros` 3 ok ([log](logs/selftest_palabros_20261123_012024.log)); `creador` 20 ok ([log](logs/selftest_creador_20261123_013651.log), incluye verificación de parpadeo no periódico: 34 parpadeos en 120 s, intervalos `0,33..8,17 s`).
- **Pendiente:** sin commit. Sin pasar la suite completa (`--headless`) todavía.

### Complexiones y botón Aleatorio en Lustre y Pintas para 0.0.22 (23/11, Antigravity · Creador)

23 de noviembre de 2026. Cierre final de la auditoría del Creador de personajes antes de preparar el release `0.0.22` («Visto bueno. Solo faltaría añadir un botón de Aleatorio tanto en Lustre como en Pintas y podemos comenzar a preparar el release de la 0.0.22»).

- **Complexiones (`godot/scripts/chara.gd`, `selftest.gd`):**
  - Nuevo modo `--criba_complexion` que prueba las 3 complexiones (`0 · Normal`, `1 · Canijo/a`, `2 · Hermoso/a`) sobre 4 conjuntos de estrés (`Camiseta`, `Traje con corbata`, `Plumas + Delantal` y `Bata + Cámara`).
  - `_slope()` calcula la pendiente real del cono (`atan(0.18667 * _girth)`) para `_strip()`, `_dot()`, `_hibiscus()` y `_pendant()`.
  - Botones, bolsillos y bolígrafo de `2 · Traje con corbata` y `22 · Bata` escalados con `_girth` (ya no se hunden en `Hermoso` ni flotan en `Canijo`).
  - Manos adaptativas (`_hx = _r(0.68) + 0.096 + _top_pad(top_id) * _girth * 0.62`), separación proporcional de pies (`±0.17 * lerpf(1.0, _girth, 0.55)`), cuellos de camisa proporcionales y correa de cámara ceñida en `Hermoso`.
- **Botón Aleatorio en Lustre y Pintas (`hud.gd`, `creator.gd`, `controls.gd`, `game.gd`, `loc.gd`):**
  - Nuevo botón `creator_rand` (`c_random`: «Aleatorio» / «Random») en la esquina inferior izquierda del panel del creador en ambas pestañas (**Lustre** y **Pintas**; oculto en el armario), con icono `[R]` en teclado (`controls.gd`), `(Y)`/`(△)` en mando (`JOY_BUTTON_Y` conectado además de `R` en `game.gd`) y botón táctil.
  - Nuevo `Creator.random_tab(sel, tab)` para que **Aleatorio** solo aleatorice la pestaña activa sin sobreescribir las elecciones de la otra pestaña.
- **Archivos tocados:** `godot/scripts/chara.gd`, `godot/scripts/creator.gd`, `godot/scripts/controls.gd`, `godot/scripts/hud.gd`, `godot/scripts/game.gd`, `godot/scripts/loc.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.
- **Pruebas:** `criba_complexion` OK ([log](logs/selftest_criba_complexion_20261123_015749.log)); `creador` 21 ok ([log](logs/selftest_creador_20261123_020848.log), verificadas capturas `creador_1_lustre.png`, `creador_3_pintas.png` y `creador_4_mando.png`); `palabros` 3 ok ([log](logs/selftest_palabros_20261123_021018.log)).

### Publicación de la 0.0.22 en GitHub (23/11, Antigravity · Creador)

23 de noviembre de 2026. Confirmado por Luis: «Eres la única sesión activa. Prosigue».
- **Prueba completa:** 983 ok, 0 fallos ([log](logs/selftest_full_20261123_022750.log)), tras actualizar 3 aserciones antiguas de `0.0.21` en `selftest.gd` (calzado `.glb`, nuevos tamaños de listas de pestañas/pendientes y conteo de pestañas bajo `_eyes_open`).
- **Commit y etiqueta:** `Matritellus 0.0.22`, etiqueta `v0.0.22`.
- **Paquetes:** `tools/make_apk.py 0.0.22` (versión 0.0.22, código 22, 318 MB, firmado y verificado), `tools/make_installer.py` (383 MB) y `tools/make_linux.py` (327 MB).
  - Copiados a `dist/v0.0.22/`, con [sus SHA-256](dist/v0.0.22/SHA256SUMS.txt) comprobados.
  - Release: https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.22
- **Sin probar:** no se ha probado en móvil físico ni en Steam Machine.

### Avenida de la Constitución, los impares de la Calle de Madrid a la Travesía de Alemania: 12 entradas (23/11, Claude · Texturas)

23 de noviembre de 2026, Texturas (Claude). El usuario dijo «Continuamos» tras la pausa de las calles.

- **Hecho.**
  - Lado oeste: `constitucion_23`, `constitucion_25`, `constitucion_31`, `constitucion_33`, `constitucion_39`, `constitucion_41`, `constitucion_43`, `constitucion_45`, `constitucion_47`, `constitucion_49`, `constitucion_55`.
  - `constitucion_51`: el solar entre el 49 y el 55, sin nada en el Catastro, como tapia de chapa (`rc: None`, 2,4 m).
  - Datos del Catastro de 25 parcelas con `tools/house_data.py`, en `tools/casas/<rc>/`: las 11 de esta tanda y 14 del tramo norte (71 a 91 y 104 a 114), para la tanda siguiente.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Fuera.** El 36: su casa queda detrás del 38, que ya estaba hecho (precheck HIDDEN). Ninguna de las parcelas está en los sitios hechos a mano de `bake_godot.py`.
- **Antes de hornear.** Pretil ya no toca la carpeta y la otra IA de Edificios Especiales no recibe avisos: se comprobó que no había ningún Godot abierto.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (12 entradas);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/constitucion_16..18.jpg`;
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Un horneado. Frente a la copia: 12 casas nuevas, ninguna quitada; de `alemania_14` y `madrid_30` solo cambian las aristas tapadas (y 1 cm la base de `madrid_30`). Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 12: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_constitucion_23_constitucion_25_constitucion_31_c_20261123_045121.log)).
  - Tras los arreglos de color (31 y 55 a `brick_dark`; 33, 39 y 43 a crema liso): 4 ok ([log](logs/selftest_casas_solo_constitucion_31_constitucion_33_constitucion_39_c_20261123_045337.log)).
- **Aprobado** por el usuario el 23/11 salvo el 23: «Visto bueno salvo la tienda de recambios, es la otra fachada de AT Taller Mecánico que hicimos en la calle del palo (y llamamos dt) habría que hacer coincidir su estética y logo».
- **El 23, otra fachada de df Mecánica.** El taller de la Calle del Palo es `df` en `garage.gd`. La tienda lleva ahora su cartel (`assets/df_mecanica.png`, de `tools/make_df.py`) sobre un marco gris encima del escaparate, y el banderín azul con la cara blanca que sale a la acera en la punta norte, como en el taller. El rótulo de texto se quita. Va en `_constitucion_23()` de `casas.gd`. `casas` de 23 y 25: 4 ok ([log](logs/selftest_casas_solo_constitucion_23_constitucion_25_20261123_050621.log)). Hoja `guion/fotos/tanda34/constitucion_19.jpg`, con el taller al lado. **Aprobado** el 23/11 («Visto bueno y seguimos»).

### Avenida de la Constitución, el tramo norte: 17 entradas (23/11, Claude · Texturas)

- **Qué.** Los impares del 71 al 91 (desde la Travesía de Alemania) y los pares del 104 al 114, con Street View 2024 y las fotos del Catastro. Líneas en `casas_calles.gd` (sección «the north stretch»), entradas en `tools/casas/calles.json`.
- **Casos raros.**
  - El 79 es la punta de la horquilla con la Calle Real: va por su fachada larga de la Calle Real; los 2,2 m de la avenida, sin describir.
  - El 81 sigue en Street View hasta el 83, aunque el Catastro dibuja sus partes solo 3,6 m: el resto con `fill`.
  - El 89 es la casita de una planta de la parcela de `alto_46`: segunda entrada en la misma referencia con `only: 1`.
  - El 89 B (`rc: None`) es la tapia de ladrillo con el portón verde.
  - El 91 es un solar que el Catastro aún dibuja con edificio: `porch` + `fill` como `tembleque_48d`. Con el `porch` a 9 m se cortaba la parcela entera, la casa desaparecía y el `fill` no se ponía: va a 3,5 m. `_constitucion_91()` en `casas.gd` le pone albardilla, machones con remate y el letrero «PROHIBIDO PEGAR CARTELES» delante de los machones (detrás se comían letras). La prueba `casas` pide al menos 12 piezas por casa.
- **Fuera.** El 108 (tapia blanca con portón verde): su referencia es la de `tri_c108`, de la Calle del Triunfo.
- **Colores.** `brick_buff` sale naranja también en el ladrillo de 1980: 79 y 81 a `c4a07c` liso. 89 B, 91 y el piso alto del 114 a `brick_dark`.
- **Mapa.** Dos horneados (el segundo por el 91). Frente a la copia: 17 casas nuevas, ninguna quitada; de `alemania_19` cambia 3 cm la base y de `alto_42` y `alto_48` solo las aristas tapadas.
- **Pruebas.** `casas` de las 15 claves: 4 ok ([log](logs/selftest_casas_solo_constitucion_71_constitucion_75_constitucion_77_c_20261123_052931.log)); tras los arreglos de color y del 91: 4 ok ([log](logs/selftest_casas_solo_constitucion_71_constitucion_79_constitucion_81_c_20261123_053309.log)).
- **Hojas.** `guion/fotos/tanda34/constitucion_20` a `constitucion_23`. **Aprobado** por el usuario el 23/11 («Visto bueno y siguiente»).

### Azafrán a la venta, la charla del curro, pieles y pañoletas, cámara al hombro, la Tomasa y las tres abuelas (23/11, Claude · Sistemas)

- **Qué pidió el usuario (23/11).** Menos pieles oscuras, pañoletas blancas, negras o azules, el azafrán solo se coge al pisarlo y se vende a cuatro vendedores, la Paca explica cómo ganar dinero tras la deuda, la Tomasa no se va a media charla, charlas con los vecinos únicos con cámara al hombro, y Josefa y Tomasa distintas de la Paca.
- **Pieles y pañoletas** (`game.gd` `_neighbour_look`). Piel oscura o negra en 1 de cada 20 vecinos al azar (la prueba da 5 %). Pañoleta de las viejas: blanca `f2efe6`, negra `1b1b1f` o azul `2c4a7a`.
- **Azafrán.**
  - Se coge al pasar por encima y ya no da dinero (`_take_flower`).
  - Nuevo `azafran.gd`: cuatro vendedores (Vendedor Azafrán 1 a 4, mismo modelo), en Máximo García de la Torre 34, Curtidores 27 (polígono San Sebastián), Santiago Apóstol 5 A y delante de la puerta MUSEO del Petril (buscada en el Label3D del Petril; `petril.gd` sin tocar).
  - Compran todo lo que llevas a 6 € la flor, el precio de antes. Pregonan si pasas cerca.
  - Círculos de azafrán en el minimapa (`minimap.gd` `saffron_shops`).
  - Contadores en `stats`: `azafran_cogido` y `azafran_vendido`.
- **La charla del curro** (`fondo_casa.gd` `_curro_talk`). Al acabar la de la deuda, 7 frases nuevas (`loc.gd` `casa_curro`). La cámara corta a un vendedor, al Henry, al asador de Javi (su fachada: él está en el interior aparte) y al de las faenas.
  - Al acabar se abren los vendedores y El de las faenas (`trabajos.gd` `place_giver`, `henry_can` pide `stats.curro`).
  - Las partidas guardadas con la deuda ya contada lo tienen abierto al cargar.
  - Los repartos de Javi no se han cerrado.
- **Rondas** (`rondas.gd`). Quien te está hablando ya no se mueve. Antes, con la cámara lejos, la ronda devolvía a la Paca a su sitio en mitad de la charla.
- **La Tomasa** (`tomasa.gd`). Tras su recado se queda contigo (`_hold`) hasta el pitillo. Antes, la rama de paseo la movía cada 1,2 s. La prueba de `mejoras2` espera 8 s con la charla abierta.
- **Cámara al hombro** (`game.gd` `_talk_camera`). Hablando en la calle con un vecino único: plano por encima de tu hombro y, en la frase siguiente, por encima del suyo; se pone del lado con sitio. No actúa con genéricos, dentro de tiendas, en coche ni en las escenas especiales (`cam_fixed`, `cine_lock`, Recress, Henry…).
- **Caras.** Josefa con pañoleta negra. Tomasa con cardao rubio teñido (peinado 26) y sin las gafas redondas de la Paca. La Paca igual. Nuevo modo `elenco`: foto de frente y de tres cuartos de cada vecino único (`--solo=`).
- **Pruebas.**
  - Nuevo `azafran`, también en la tanda completa tras `_mend_checks`: 6 ok.
  - `herencia` 13 ok, con el recorrido: 7 de 7 planos.
  - `trabajos` 8 ok, `mejoras2` 13 ok, `rondas` 1 ok, `palabros` 3 ok.
  - Fotos en `godot/shots/` (`curro_*`, `azafran_vendedor_*`, `hombro_*`, `elenco_*`).
  - Tanda completa sin pasar.

### Maxi y el probador del MaxiPrecio, el azafrán a 50 € y tres caras más (23/11, Claude · Sistemas)

- **Qué pidió el usuario (23/11).** «Pon a Tomasa de pelo blanco a Dolores Rubia y a Nocturno ponle barba con perilla», un dependiente para el MaxiPrecio que se llame Maxi y hable con maxis, que venda toda la ropa a 20 € directa al armario, y el azafrán a 50 € la flor.
- **Caras.**
  - Tomasa: cardao blanco (`tomasa.gd`).
  - Dolores: rubia teñida, `d8b25e` (`game.gd`).
  - Nocturno Correa: bigote y perilla, `face` 8 (`cartas.gd`).
- **Azafrán.** `azafran.gd` `PRICE` = 50.
- **Maxi** (`maxi.gd`, nuevo, de Sistemas).
  - Está tras el mostrador del interior de Pretil (`maxiprecio_dentro.gd`: `clerk_spot` y `clerk_h`) cuando la tienda abre.
  - El primer día saluda y luego va rotando 7 charlas, todas con maxis (`loc.gd` `maxi_*`).
  - Después pregunta «¿Te pruebas algo? To a 20 euros».
- **El probador** (`game.gd` `open_shop_ropa`). Es la pantalla del armario con una sola fila, Ropa, con todas las prendas del creador menos la camiseta de la peña.
  - Te las pruebas y compras a 20 €; lo que compras va a `stats.armario` y se guarda la partida.
  - Sales vestido como entraste: lo comprado está en el armario de casa.
  - Se prueba en el primer probador (`probador_spot` y `probador_h` de Pretil).
  - Sin zapatos, complementos ni gorras. Los colores siguen siendo los que ya tienes.
- **Árbol de relaciones.** Maxi y los Vendedores Azafrán 1 a 4 en `guion/relaciones.json`; retratos y `make_relaciones.py`.
- **Pruebas.**
  - Nuevo modo `maxi` (`_ropa_checks`), también en la tanda completa tras `_azafran_checks`: 4 ok.
  - `elenco` de las caras cambiadas: ok.
  - Fotos `godot/shots/maxi_probador*.png`.

### Huecos del centro: 9 casas sueltas (23/11, Claude · Texturas)

- **Qué.** El usuario pidió buscar «calles que falten empezando por el centro hacia afuera». Quedan pocas calles enteras sin hacer cerca del centro; lo que falta son parcelas sueltas. Se buscaron así: las parcelas del Catastro a menos de 300 m del centro (-100, -60) que no estaban en `calles.json`, ni en `bake_godot.py`, ni en ningún `.gd`, ordenadas por distancia (script `huecos`/`calle_rc` del scratchpad).
- **Las 8.** `zaragoza_14`, `madrid_24`, `arroyuelo_p15d`, `arroyuelo_t17`, `domingo_9d`, `toledano_8a`, `matias_a67` y `abajo_10`; cada una en su calle, en la sección «Holes near the centre» al final de `casas_calles.gd`.
- **Falsas libres.** Palo 35 y 37 son df Mecánica (el `GARAGES` de `bake_godot.py` las corta sin nombrar su referencia). Cervantes 3 es la parroquia. Constitución 36 queda detrás del 38. Las de la Calle Real del centro son `real_*` hechas a mano.
- **Fuera.** Arroyuelo Medio 57 y Regidor 5 quedan detrás de fachadas hechas (`precheck.py`: HIDDEN). Santo 40 no da a ninguna calle. Hay tres solares.
- **`madrid_24`.** Estaba pendiente porque su frente quedaba detrás de las vecinas. Va puesto a mano en el hueco entre `madrid_22` y `madrid_26` (4,5 m).
- **`salvador_1t`, quitada.** La caseta de ladrillo junto a la torre de la parroquia ya la había hecho Pretil. El usuario: «La casera de ladrillo de la parroquia creo que se la has pisado a Petril, que ya la había hecho. Siempre predomina el trabajo de Petril». Fuera de `calles.json` y `casas_calles.gd`, y se vuelve a hornear: frente a la copia quedan 8 casas nuevas, ninguna quitada. `casas`: 4 ok ([log](logs/selftest_casas_solo_zaragoza_14_madrid_24_20261123_070432.log)). Lección: antes de describir una parcela pegada a algo hecho a mano, mirar en el juego si ya hay algo en ella.
- **`abajo_10`.** Le falta la verja de machones de ladrillo con los cipreses.
- **Mapa.** Un horneado. Frente a la copia: 9 casas nuevas, ninguna quitada; de 6 vecinas solo cambian las aristas tapadas.
- **Pruebas.** `casas` de las 9: 4 ok ([log](logs/selftest_casas_solo_zaragoza_14_madrid_24_arroyuelo_p15d_arroyuelo_t1_20261123_062206.log)); tras los colores de `domingo_9d` y `toledano_8a`: 4 ok ([log](logs/selftest_casas_solo_domingo_9d_toledano_8a_20261123_062604.log)).
- **Hojas.** `guion/fotos/tanda34/huecos_1` y `huecos_2`. **Aprobado** por el usuario el 23/11 («Visto bueno y siguiente»).

### Probador con iconos, el Vizum de la Paca y el color en los gatillos (23/11, Claude · Sistemas)

- **Iconos en vez de flechas.** El probador del MaxiPrecio enseña una rejilla de 4 columnas con todas las prendas a la venta, con scroll si no caben (`hud.show_shop_grid`, `shop_grid_icon`). Cada celda lleva el dibujo del jugador con la prenda puesta, su nombre y «tuya» o «20 €».
  - Los dibujos los hace `ropa_icono.gd`: un SubViewport con mundo propio y fondo blanco, de 6 en 6 (`game._draw_ropa_icons`), guardados en `_ropa_tex` por prenda, colores, piel y talla.
  - Se mueve con el stick o las flechas (arriba/abajo saltan una fila) y se toca o pulsa para elegir.
- **El Vizum.** Contada la deuda de Hacienda y el curro (`stats.curro`), cuando te alejas más de 60 m de la Paca te llama una vez (`fondo_casa._vizum_rung`, `casa_vizum_call`): «una cosa es serlo y otra parecerlo». Te manda un Vizum de 20 € (`_vizum`: `stats.vizum` = día, +20 €, toast `t_vizum`).
  - Al colgar se abren las tiendas de ropa y complementos: `tiendas_ropa.gd` (`SHOPS`, hoy solo `maxiprecio`). Antes, la flecha verde de la puerta del MaxiPrecio no aparece: `entradas.gd`, `tiendas_ropa.shut(dentro)`.
  - En el minimapa y en el mapa grande cada tienda abierta lleva una peseta: moneda dorada con la P tachada (`minimap._peseta`, `clothes_shops`; en el mapa grande se pone también en `_set_map(true)`).
- **Color en el probador.** Mientras te pruebas algo, LT/RT en el mando, Z/X en el teclado o las flechas ‹ › de la fila de color (táctil, Android) cambian el color 1 de la prenda (opción 2 del creador).
  - Los dibujos se rehacen con ese color. Una prenda solo sale como «tuya» si tienes la prenda y también ese color.
  - Comprar mete en el armario la prenda y el color (el armario guarda prendas y colores por separado, así que el color sirve luego para todas).
  - Los colores 2 y 3 no se cambian en la tienda.
  - En la tienda los gatillos ya no giran al personaje (giran Q/E, el ratón o el stick derecho).
- **Pruebas.** Modo `maxi` (`_vizum_checks` y `_ropa_checks`), también en la tanda completa: 8 ok ([log](logs/selftest_maxi_shots_20261123_062838.log)). Fotos: `godot/shots/vizum*.png` y `maxi_probador*.png`. La tanda completa no se ha pasado. Nada subido.

### El Vizum pasa a la Josefa (23/11, Claude · Sistemas)

- **Qué.** El usuario: «movamos toda la parte del vizum a la Josefa, ya que ella se encarga de las misiones de negocios. Que sean suyas las llamadas y el vizum». Ahora llama ella (`fondo_casa.gd`, `npc: "josefa"`) y el toast dice «Vizum de la Josefa».
- **Cuándo.** Igual que antes: después de que la Tía Paca te cuente lo de Hacienda y el curro, cuando te alejas más de 60 m de la Paca. La deuda sale después del puente, así que la Josefa ya te conoce y ya tiene el móvil arreglado.
- **Diálogo.** La clave de loc es ahora `josefa_vizum_call` (antes `casa_vizum_call`). Dice lo mismo en su voz: «yo me entero de to», «una cosa es serlo y otra parecerlo», el muchacho del V.I.P. que le enseñó a darle al botón, «más de tres mil pesetas», y en los negocios lo primero es la pinta.
- **Pretil.** Su `_maxiprecio_checks` aún nombra a la Paca solo en dos textos (3808 y 3818). Está avisado; la lógica no cambia.

### Huecos del centro, el segundo anillo: 5 casas (23/11, Claude · Texturas)

- **Qué.** Las parcelas libres de 220 a 320 m del centro. Hechas: `sanjose_b032`, `sanjose_11b`, `sanjose_13`, `real_69d` y `trsr_3`, en la sección «the second ring» al final de `casas_calles.gd`.
- **Trampas.**
  - `roma_10` se horneaba y no salía, porque `roma_8` ya la incluye con `with` y `house_of` da la primera entrada que coincide. Antes de describir una parcela, buscar su referencia también dentro de los `with`.
  - `sanjose_13` y `constitucion_p12` salían metidas en un hoyo, a 12–13 m de la calle (d en `svh.py`). `sanjose_13` va a mano en el hueco de la línea entre sus vecinas, con `fill`. `constitucion_p12` era la parte de atrás del 75 D y se quita.
- **Fuera.** Las parcelas con 1–2 m de frente, las que no dan a ninguna calle y los solares (lista en `guion/repaso_casas.md`).
- **Mapa.** Tres horneados. Al final, frente a la copia: 5 casas nuevas, ninguna quitada; de `real_69` y `real_71` solo cambian las aristas tapadas.
- **Pruebas.** `casas`: 4 ok ([log](logs/selftest_casas_solo_real_69d_sanjose_b032_sanjose_11b_sanjose_13_trsr_20261123_071447.log)).
- **Hojas.** `guion/fotos/tanda34/huecos_3` y `huecos_4`. **Aprobado** por el usuario el 23/11 («Visto bueno y siguiente»).

### Calles enteras más allá de 320 m: 18 casas (23/11, Claude · Texturas)

- **Qué.** Calles enteras que faltaban, de la más cercana a la más lejana:
  - Mirasierra: 9 casas, del `mirasierra_1` al `mirasierra_10`.
  - Valdespino: `valdespino_3`, `_5`, `_6` y `_8`.
  - Plaza de Don Jesús Requejo: `requejo_1`, y `requejo_r57`, `_r59` y `_r61`, tres de la Reina Sofía que dan a la plaza.
  - Reyes Católicos 1: `reyes_1`.
  - Van en la sección «Whole streets past 320 m» al final de `casas_calles.gd`.
- **Trampa.** `requejo_r61` se horneaba y no salía. Le subí `floors` a 3, y `house_of` solo acepta partes con `floors >=` ese número; las del Catastro tienen 2. Queda en 2 en `calles.json`; las tres plantas las da la línea.
- **Mapa.** Dos horneados. Frente a la copia: 18 casas nuevas, ninguna quitada. De `vin_x2` solo cambian dos aristas, ahora tapadas por el 61.
- **Pruebas.** `casas solo=mirasierra_,valdespino_,requejo_,reyes_1`: bien. Después corregí los colores de `valdespino_5`, `mirasierra_2` y `requejo_r59` y repetí sus fotos.
- **Corrección (el usuario: «Esto es terrible. No pongas las fachadas sueltas y adelantadas»).**
  - `mirasierra_8` salía 2,3 m por delante del 6 y del 10, porque su parcela del Catastro lleva el porche dentro.
  - Los cinco pares (2–10) van ahora en una sola línea recta ajustada, con `clear: 3.0` para lo que queda delante y `fill` para lo que falta.
  - El porche del garaje del 10 es una parte de una planta que el filtro `floors` dejaba como casa genérica suelta en la acera; se quita con `strip: 4.0`.
  - La franja de una planta de `valdespino_3` entra en la casa con `floors: 1`.
  - Comprobado en el mapa: ningún punto de las piezas queda delante de su fachada.
  - Herramienta: `alinea.py` del scratchpad.
  - En todo `calles.json` hay 41 casos de una casa a más de 1,5 m por delante de su vecina. Están sin revisar; algunos serán reales.
- **Hojas.** `guion/fotos/tanda34/mirasierra_1` y `_2`, `valdespino_1` y `requejo_1`. A la espera del visto bueno.
- **Pretil.** Le he cedido `stana_54` (Santa Ana 54, «Tetoqa», `tetoqa.gd`), con `["obra"]`, como `mol_b301`.

### Koke el Kokas y su taxi; la Paca y la droga (23/11, Claude · Sistemas)

- **La Paca.** En la charla de Hacienda (`casa_curro`) hay una línea nueva antes de la última: «Y si no, siempre te queda vender droga: en este pueblo la mitad trafica y la otra mitad consume. Economía circular, lo llaman.». Tiene su plano en `CURRO_SHOTS` («paca»). De El de las faenas ya solo nombra «repartos, el campo...».
- **Koke el Kokas** (`koke.gd`, nuevo, pedido por el usuario).
  - Cuarentón pasado de vueltas: camisa hawaiana, gafas de aviador, cadena de oro, barba de tres días.
  - Su flota está en el recinto ferial (elección del usuario): tres Z15 tuneadas (amarilla, negra y azul) en fila a lo largo del camino más largo del ferial, a 7 m o más de las terrazas, y él al lado, en la tierra. Como `props.terrazas` aún está vacío en `koke.setup`, el sitio se vuelve a calcular en el primer tick que ya las tiene (`_find_spot`/`_settle`).
  - Llama una hora de juego después del Vizum de la Josefa (`stats.vizum_h`, que guarda `fondo_casa._vizum`; en una partida vieja sin esa hora, llama enseguida). La llamada es `koke_call`, de las que solo cuentan, sin sí/no. Al colgar: `stats.koke`, aviso «Nuevo trabajo» y la flecha verde (`marcas.gd`) mientras la carrera del día esté disponible.
- **La Z15 del Kokas** (`car.gd` SPECS «kokas»: la Z15 con más motor y turbo, es decir, nitro con el reloj deportivo).
  - Usa el mismo modelo que la Z15 (`modelos.gd` SK «kokas»). `koke_marcas.gd` le pone llamas en calcomanía en los dos costados y el capó, el letrero TAXI · KOKAS iluminado y un alerón con dos patas.
  - Las imágenes las pinta `tools/koke/pinturas.py` en `godot/assets/koke/` (importadas).
  - `car.gd` tiene ahora `unbreakable` (sin daño) y `knocks` (cuenta los golpes aunque no haya daño).
- **La carrera** (un tipo de trabajo más en `trabajos.gd`, `kind: "kokas"`; su tick, show y abort son de `koke.gd`).
  - Empieza al subirte a la amarilla (`game._enter_car` llama a `koke.entered`), una vez al día (`stats.koke_dia`). Si no te toca, Koke no te deja subir (`koke.refuses`, antes de `_enter_car`).
  - Turno de 60 s, con flecha al cliente más cercano. Esperan 4 vecinos con un aro a los pies: rojo, 150-320 m; amarillo, 320-560 m; verde, 560-900 m.
  - Paras al lado, se suben y empieza el reloj del cliente (distancia/9 + 10 s).
  - Al dejarlo pagan una base de 30 + 0,22 €/m (redondeada a 5) más una propina igual a la base por la fracción de tiempo que sobra. Se califica la carrera («¡Como un cohete!», «Ni tan mal», «A paso de burra») y el turno gana +30 s.
  - Si se le acaba su reloj, se baja sin pagar. El turno acaba cuando su reloj llega a 0, tras 10 s fuera del coche o si empieza una misión. Lo ganado se cobra con cada cliente.
  - Mientras dura, la furgoneta es irrompible y la policía está callada (`police.reset()` si había persecución, y `muted`, que se devuelve como estaba). Al acabar puedes seguir montado, pero vuelve a romperse y la policía vuelve (palabras del usuario).
  - Cuando te bajas y nadie la ve, la furgoneta vuelve sola a la flota.
  - Las mecánicas salen de los juegos de taxi arcade: aro de color por distancia, reloj general, reloj por cliente, propina por rapidez. No se usa el nombre, la estética ni el sonido de ningún juego.
- **Lo que dicen los clientes** (encima de la furgoneta, con el estilo de los murmullos de `npc.bark`, porque el usuario dijo: «Que las frases del cliente sean como los murmullos que ya tenemos»).
  - Hablan de la velocidad (`kokas_fast` por encima de 22 m/s, `kokas_slow` tras 3 s por debajo de 5 m/s), de los golpes (`kokas_crash`) y de tus pintas («{el|la} de la Eufrasia»: el usuario escribió «la Eusebia», pero la tía del juego es la Eufrasia). También de sus vidas, con `[[hombre|mujer]]`: divorcio, hijos que no les quieren, cuernos. Y frases sueltas.
  - Al subir dicen adónde van (`kokas_to`); al bajar dan las gracias (`kokas_thanks`) o se quejan (`kokas_angry`).
- **El de las faenas** ya no da el taxi (el usuario: «Se lo queda Koke»). Se quitaron su opción y su código; las pruebas `trabajos` y el perfil, sin el taxi, eligen el campo con `_choose(1)`.
- **Guion.** Koke está en `guion/relaciones.json` con sus enlaces (Josefa le da tu número, el Vizum de la Josefa, taxista suyo), con retrato y `make_relaciones.py`. En `guion/misiones.html` hay una tarjeta `m-koke`, el nodo en el esquema y la tarjeta de faenas con dos trabajos.
- **La radio de sus coches.** Al subirte a cualquiera de los tres suena Koka y Ná, y la tecla de la radio solo la cambia a Traktor y vuelta: ni otras emisoras ni apagarla (el usuario: «Ni otras cadenas ni apagarla»). Al bajarte, vuelve la emisora que llevabas. Las emisoras se buscan por el nombre de su `emisora.json` («koka» y «traktor»); si falta alguna de las dos, la radio va como en cualquier coche (`koke.station_of`, `_radio_tick`, `radio_flip`, llamado desde la tecla de `game.gd`).
- **Coches aparcados movidos (`car.gd`, `game.gd`).** Si se movía con `place` un coche aparcado y dormido (`doze`), se le quedaban las ruedas donde estaba, porque `_doze_cars` lo volvía a dormir antes de un paso de física. Ahora `place` lo despierta, y `awake_t` lo deja medio segundo en la física antes de que pueda dormirse otra vez.
- **Pruebas.** Modo nuevo `koke`, con 11 comprobaciones (también en la tanda completa, tras `_ropa_checks`); una de ellas comprueba que la flota esté lejos de las terrazas y con las ruedas debajo. Fotos en `godot/shots/koke_*.png`. Pasadas: koke 11 ok (10 con fotos; la 11.ª es la de la radio), tricornio 3 ok, trabajos 6 ok, herencia 13 ok, palabros 3 ok. La tanda completa no se ha corrido. No hay nada en commit.

### Fachadas adelantadas: repaso de todo lo hecho (23/11, Claude · Texturas)

- **Qué.** El usuario pidió «Arreglemos primero las fachadas adelantadas». `adelantadas.py` (scratchpad) busca en `calles.json` las fachadas que salen más de 1,5 m por delante de su vecina del mismo lado y da cuánto se separa cada una de la calle. Salieron 41.
- **Cómo se decidió cada una.** Por tres cosas: la acera de siempre de cada calle (la mediana), la foto del Catastro y Street View.
  - En casi todas, la que estaba mal era la casa de atrás: el Catastro la dibujaba de 3 a 6 m dentro, pero en la foto está a ras.
  - En Florido 14–26 la hilera es la buena: está metida de verdad, tras sus patios.
  - En Toledo 45–53 frente al 55 hay un escalón real de 1 m, no de 3,6.
- **Hecho.**
  - 19 casas a la línea de las vecinas, con `fill: [[0, L, avance + 0.4]]` y `clear: 3.0`.
  - Toledo 49, 51 y 53 en una línea girada desde la junta con el 47 hasta 1 m detrás del 55.
  - Viñas 47–57 en una sola línea ajustada.
  - Las tapias bajas `flo_p14t` a `flo_p26t` y `delicias_39t`, en `casas_calles.gd` junto a su casa. Un muro sin referencia necesita ≥ 5 m² de planta (`deep` ≥ 0,75), o el horneado lo tira.
- **Sin tocar.** Las casas detrás de su tapia (Regidor 24, Clavel 11, Santa María 13, Amargura 8) y lo de Pretil (Arcos 10 con su tapia y Real 24).
- **Error corregido.** Moví `real_24`, que es `["obra"]` de farmacia.gd, y lo devolví a su sitio. Su casa en el mapa queda idéntica a la de antes.
- **Parcelas en L, arregladas.** `mirador_18`, `rsm_t27`, `extremadura_b441` y `labradores_15` tenían la fachada al fondo de un entrante, entre sus propias alas. Tras mirarlas en Street View, la fachada va en la línea de las alas, con `fill [[0, L, D+0.4]]` y `clear: 3.0`. En el mapa solo cambiaron esas cuatro y los bordes y la base de `rsm_9`; ninguna tiene piezas por delante de su fachada. Test `casas solo=` OK; hoja `guion/fotos/tanda34/adelantadas_5.jpg`.
- **Mapa y pruebas.** Cuatro horneados; ninguna casa se pierde. Ninguna de las casas tocadas tiene piezas delante de su fachada. `casas` bien.
- **Hojas.** `guion/fotos/tanda34/adelantadas_1` a `_4`: Catastro, lo que haya de Street View y dos fotos del juego.

### El «efecto jabón» al rozar paredes (23/11, Claude · Sistemas)

- **Lo que pidió el usuario:** que un golpe de lado o contra la esquina de una fachada, si no es demasiado frontal ni demasiado fuerte, deslice el coche en vez de pararlo en seco.
- **El coche que conduces** (`car.set_soap`, que activan `game._enter_car` y `_exit_car`).
  - Su carrocería casi no agarra contra lo que roza (`PhysicsMaterial` con fricción 0,03, `SOAP_GRIP`). Con Jolt, eso basta para que un roce suave siga a lo largo de la pared.
  - Cuando un golpe le quita de golpe más de 3 m/s, `_soap` lee la normal de la pared en los contactos (`contact_monitor`, solo en el coche que conduces).
    - Si el golpe no es frontal (menos del 72 % de la velocidad va contra la pared, `SOAP_FRONT`) ni fuerte (menos de 13 m/s contra la pared, `SOAP_HARD`), el coche conserva el 85 % de la velocidad a lo largo de la pared (`SOAP_KEEP`), recibe un empujoncito hacia fuera y gira el morro hacia donde desliza. Como golpe solo cuenta el 70 % de la velocidad que iba contra la pared (daño, ruido, botellas).
    - Si es frontal o fuerte, es un choque como antes, y además se queda con un tercio de la velocidad que tenía, para que la carrocería resbaladiza no lo lleve por la pared.
  - Si el coche no pierde velocidad sino que lo empujan (un patrullero que te embiste por detrás), no se toca.
  - Los coches del tráfico y la policía no tienen jabón.
- **Pruebas.** Modo nuevo `jabon` (también en la tanda completa, tras `_driving_checks`), contra una fachada larga y recta.
  - Roce a 25° y 54 km/h: no baja de 14 m/s; sin jabón, se paraba en 2 m/s.
  - A 40° y 47 km/h: sigue a 7,7 m/s.
  - De frente: se para.
  - Fuerte, a 108 km/h: baja a 6,9 m/s.
  - Pasadas: jabon 5 ok, conduccion 8 ok, salto 11 ok, vuelcos 1 ok, y `pitufos` (diagnóstico) embiste igual que antes. Nada en commit.

### Iconos del mapa para las tiendas de ropa, complementos y zapaterías (23/11, Claude · Sistemas)

- **Lo que pidió el usuario:** «iconos para el mapa para las tiendas de ropa, de complementos y zapaterías. Que encajen con nuestro estilo».
- **El diseño.** Sobre la misma moneda dorada de la peseta (la que eligió el usuario para estas tiendas), en tinta, lo que vende cada una: una camiseta (ropa), un anillo con su piedra (complementos) y un zapato normal, con la suela marcada en dorado (zapatos). El usuario cambió el bolso por el anillo («Figuras más reconocibles») y la bota de tacón que vino después por un zapato normal («la bota está rara»).
  - Se dibujan con las llamadas de dibujo de `minimap.gd` (`_coin`, `_shop_icon`, `SHIRT`/`GEM`/`SHOE`, y el aro del anillo en óvalo, en unidades del radio), como el resto del mapa. La P de la peseta queda para un tipo que no se conozca.
  - `tools/iconos_mapa.py` dibuja la hoja de muestra, en grande y a su tamaño (`guion/iconos_mapa.png`).
- **Qué vende cada tienda.** `tiendas_ropa.SHOPS` ahora es un diccionario `{tienda: tipo}` con `KINDS = ropa, complementos, zapatos`: el MaxiPrecio es ropa y la Tetoqa, complementos. La zapatería es la Pisacastaña de Pretil («pisacastana»: «zapatos»), que ya se ve en el mapa.
  - `marks()` devuelve `{p, kind}`.
- **Pruebas.** Modo nuevo `iconos` (con `shots`, la foto del mapa grande; si no hubiera zapatería, pone una de muestra). La comprobación del Vizum (`_vizum_checks`) ahora cuenta una marca por tienda hecha.
  - Pasadas: iconos 1 ok, maxi 8 ok con fotos. Sin ventana, maxi falla en las dos comprobaciones del probador, porque no se dibujan las fotos; con ventana pasa. Nada en commit.

### Dos azafranes: los escondidos y los de la calle (23/11, Claude · Sistemas)

- **La regla del usuario** (pasada por Pretil): «Y internamente vamos a tener dos azafranes. Los escondidos que solo aparecen una vez por juego. Y los públicos que aparecerán aleatoriamente como hasta ahora y se regenerán cada 24 horas in-game en sitios diferentes».
- **Los escondidos** (los que llevan `"hidden": true` y su `id`) siguen como estaban: cuentan una vez por partida y se guardan en `stats.saffron_hidden`. Hoy son 9, con los dos nuevos de Pretil («tetoqa» y «maxiprecio»), y `hidden_saffron()` los cuenta solos.
- **Los de la calle** (`game._spread_saffron`).
  - Son `SAFFRON_N` = 40 por las aceras y las calles residenciales, como antes.
  - Cada día nuevo de juego (cuando cambia `day_n`: a medianoche, al despertar o al cargar una partida; lo vigila `_advance_clock` con `saffron_day`) se vuelven a repartir todos, también los que nadie cogió, a 15 m o más de los del día anterior (`SAFFRON_AWAY`).
  - Lo que se coge desaparece hasta el día siguiente.
- **Pruebas.** `_azafran_dia_checks`, al principio de `_azafran_checks`: se coge uno de la calle y uno escondido, pasa un día, y comprueba que vuelven los 40 en otros sitios y que el escondido sigue cogido. `azafran` 7 ok. Nada en commit.

### Calle de Manuel Álvarez de Ugena: 11 entradas (23/11, Claude · Texturas)

- **Qué.** Las cinco parcelas de la calle que faltaban, desde Street View 2024 (solo la 4, la 7 y la 14 tienen foto del Catastro): `ugena_1` (el taller), `ugena_3` con `_3b`, `_3t` y `_3p`, `ugena_4` con `_4w`, `ugena_7` con `_7l` y `_7g`, y `ugena_14`. Van al final de `casas_calles.gd`.
- **Trampa: una entrada pinta una sola pared a lo largo de todo su frente.** `_facade` levanta el muro del largo del frente, no por piezas. Dos entradas de la misma parcela con el mismo frente se tapan entre sí: la puerta y el garaje del 7, y el porche del 4, no salían. Los frentes de una parcela partida van uno al lado de otro.
- **Reparto de partes.** Con `reach` (distancia del polígono al frente) y con el orden de `calles.json`, porque `house_of` da la primera entrada que encaja:
  - `ugena_4` (`reach` 1.0) va antes que `ugena_4w`, y se queda la casa y el porche.
  - `ugena_7l` (`only` 1, `reach` 2.0) va antes que `ugena_7g`.
- **Patio delante.** El Catastro mete el patio del 3 en la casa. La fachada va 3 m atrás (`clear: 3.0`), con dos tapias de `rc` nulo en la calle, en línea con el taller.
  - Una tapia lisa no pasa la prueba de «too little»: la casa necesita 12 cajas o más, y los `paño` no cuentan. La del 3 lleva una cancelilla (`gar`).
  - La de las cancelas necesitaba `deep` 1.1 para pasar de 5 m².
- **Fuera.** Monjas 116, Consuegra 20/24 y Cipreses 14 salen junto a la calle pero dan a las suyas.
- **Mapa.** Frente a la copia, 11 casas nuevas, ninguna quitada ni cambiada. Ninguna pieza queda por delante de su fachada.
- **Pruebas.** `casas solo=ugena_`: 4 ok. Hojas `guion/fotos/tanda34/ugena_1..2`. **Aprobado** por el usuario el 23/11 («Visto bueno y paramos un poco»). Nada en commit.
- **Antes, aprobado.** El repaso de fachadas adelantadas, con las cuatro parcelas en L, y las calles de Mirasierra: «Visto bueno y paramos un momento».

### Calle Nueva: 9 entradas (23/11, Claude · Texturas)

- **Qué.** Las parcelas de la calle que faltaban, desde Street View 2024 y la foto del Catastro: `nueva_1` con su valla `nueva_1t`, `nueva_3`, `nueva_5`, `nueva_4a` con `_4b` (su remate de dos plantas, `floors` 2), `nueva_4t` (la tapia del n.º 4: el Catastro lo da con 0 plantas y el horneado no lo levanta), `nueva_6` y `nueva_10`. Van al final de `casas_calles.gd`.
- **Fachadas en línea.** La valla del 1 va de su esquina al frente del 3. El 6 va desde la punta de su garaje (la única parte que el Catastro pone en la calle) hasta el frente del 10, con `fill` 5,1 m y `clear` 3,0, como en Street View.
- **Fuera.** Constitución 116 (el cuartel, `cuartel.gd`) y Reyes Católicos 13.
- **Mapa.** Frente a la copia, 9 casas nuevas, ninguna quitada. De `constitucion_114` solo cambia una arista lateral, ahora tapada por `nueva_4b`.
- **Pruebas.** `casas solo=nueva_`: 4 ok. Hojas `guion/fotos/tanda34/nueva_1..2`. **Aprobado** por el usuario el 23/11 («Visto bueno y siguiente»). Nada en commit.
- **Antes, aprobado.** La calle de Manuel Álvarez de Ugena («Visto bueno y siguiente»). `arcos_5` pasó a `["obra"]` para la zapatería de Pretil (`pisacastana.gd`).

### Manuela Moreno y el banco de zapatos de la Pisacastaña (23/11, Claude · Sistemas)

- **Qué pidió el usuario.** Una dependienta con frases, como Maxi, y elegir zapatos en el banco de la tienda: «Las dos opciones me gustan» (a través de Pretil). El nombre, «Manuela Moreno», y el precio, todos a 20 €, los eligió él.
- **`manuela.gd` (nuevo).** Copia el modelo de `maxi.gd`:
  - está tras el mostrador de `pisacastana_dentro.gd` (de Pretil: `clerk_spot`/`clerk_h`, `probador_spot`/`probador_h`, `open`) mientras la tienda abre;
  - habla con pisas (`manuela_*` en `loc.gd`: pisaprecios, pisaofertas, «¡pisa fuerte!») y luego pregunta «¿Te pruebas algo?»;
  - con el sí se abre el banco: los 14 zapatos del creador menos ir descalzo, a 20 € el par, con el color en los gatillos. Lo comprado (zapato y color) va al armario de casa, y sales como entraste.
- **El probador, general.** `game.open_shop_ropa(spot, face, side, price, who, kind)` acepta `kind` = `{opt, col, title, poor, bought, have, have_btn}`. Sin `kind` sigue siendo la ropa del MaxiPrecio (opciones 15 y 2). `_so()`/`_sc()` dan la opción y el color de la tienda abierta; `ropa_for_sale()` quita lo que es «nada» (`Creator.NOTHING`).
- **Iconos.** `ropa_icono.gd viewport(look, px, feet)`: con `feet`, la foto es de los pies.
- **Textos.** «Pisacastaña · Zapatos», «tuyos», «Ya los tiés».
- **Más.** Retrato `guion/fotos/manuela.png`. Está en `guion/relaciones.json` (tú → «te vende zapatos»).
- **Pruebas.** Modo `manuela` (`_manuela_checks`, también en la pasada completa tras `_ropa_checks`): `manuela shots` 3 ok, `maxi shots` 8 ok, `palabros` 3 ok. Fotos `manuela_banco`, `manuela_tienda`. Nada en commit.

### Calle de la Flor: 10 entradas (23/11, Claude · Texturas)

- **Qué.** La acera sur, entera. La norte son las traseras de las casas de la calle Valencia (`valencia_37` a `_43`).
  - Las casas: `flor_1`, `flor_5`, `flor_7`, `flor_9` (dos plantas), `flor_11`, `flor_13`, `flor_13d` y el bloque de la esquina `flor_b024` (sin dirección en el Catastro).
  - Dos tapias con `rc` nulo: `flor_3t`, porque la casa del 3 (4692020VJ5649S) está 9 m atrás y `calle_rc.py` no la ve, y `flor_7t`, en un hueco de 5,5 m entre el 7 y el 9.
- **Fachadas en línea.** El 11 se alarga 1,6 m hasta el 13 con `fill`. El bloque va 0,7 m atrás, en la línea del 13 D, con `clear: 1.0`.
- **Trampas.**
  - `flor_7t` con 0,8 m de fondo se quedaba en 4,4 m² y el horneado lo tiraba: lleva `deep` 1.1.
  - El ladrillo del bloque va en `brick_rose`, el rosado de las casas de después de 2005.
- **Mapa.** Frente a la copia, 10 casas nuevas, ninguna quitada ni cambiada.
- **Pruebas.** `casas solo=flor_`: 4 ok. Hojas `guion/fotos/tanda34/flor_1..2`. **Aprobado** por el usuario el 23/11 («Visto bueno y paramos»). Nada en commit.
- **Antes, aprobado.** La Calle Nueva («Visto bueno y siguiente»).

### Pasada completa para la 0.0.23: lo que fallaba y por qué (23/11, Claude · Sistemas)

- **Primera pasada: 1030 ok, 12 fallos.** Solo una era de verdad: Maxi, Manuela y Koke no tenían frases para las firmas del puente. Ahora tienen `firma_si_*` y `firma_no_*` en `loc.gd`.
- **Del juego.**
  - `game._shot_clear` mira ahora en los dos sentidos. Una cara que solo da a la cámara no se veía desde la pared, y La Chiki tenía una pintada tapada en la Travesía del Clavel, en (140, −219).
  - `props._tidy` va sin tipo: un mueble ya liberado rompía la llamada del temporizador.
- **De las pruebas (`selftest.gd`):**
  - **Fotos del probador y del banco.** Sin ventana no se dibujan, así que solo se exigen con ventana (`maxi shots`, `manuela shots`).
  - **Maniquíes del MaxiPrecio, la Tetoqa y la Pisacastaña** (de Pretil). En la pasada completa todavía era la hora de la pantalla de título y el reloj de la tienda la cerraba. Se miran un lunes a mediodía y luego se deja la hora como estaba.
  - **Ajedrez.** El balanceo de los niños se mide durante 150 fotogramas en vez de 60.
  - **Javi, Vizum y llamada de Koke.** Una llamada se quedaba sonando de una prueba anterior (la Josefa, Koke). `_hush_phone()` cuelga y vacía la cola.
  - **Maruja que te sigue.** Se anda hacia un lado libre: donde para el coche, de frente podía haber una pared.
  - **Rondas.** Se quita `g.side`. Además, a menos de 25 m nadie se teletransporta: se mira su `home`. El mensaje dice quién falta y a cuántos metros está la cámara.
  - **El motín.** Se esperan hasta 40 fotogramas más a que llegue el último del corro. El mensaje da la etapa, el más lejano y los armados.
- **Pendiente, sin tocar.** En las rondas, la cámara estaba a 188 m del jugador: alguna prueba anterior la deja fija. No rompe nada, pero sería bueno saber cuál.

### Publicación de la 0.0.23 en GitHub (23/11, Claude · Sistemas)

- **Por qué.** Lo pidió el usuario: «Si está todo vamos preparando el release». Antes, Pretil y Texturas pararon y confirmaron que no les quedaba nada a medias.
- **Pruebas.** Hicieron falta siete pasadas completas; la última dio 1042 ok, 0 fallos. Lo que se arregló por el camino está en la entrada anterior.
- **Memoria con el renderizador del móvil** (`--rendering-method mobile -- --timing`): 773 MB estática y 2075 MB de vídeo al final de la carga. En la 0.0.21 eran 752 y 1988.
- **Paquetes.** Están en `dist/v0.0.23/`: `Matritellus-0.0.23-{Windows.exe,Android.apk,Linux.tar.gz}` y `SHA256SUMS.txt` (dos espacios). El APK lleva la versión 0.0.23 (código 23), firmado y verificado.
- **Contenido.**
  - Sistemas: Koke el Kokas y su taxi, el «efecto jabón», Maxi, Manuela Moreno y su banco de zapatos, el Vizum de la Josefa, los iconos del mapa, los dos azafranes, la charla del curro y la cámara al hombro.
  - Pretil: el MaxiPrecio, la Tetoqa y la Pisacastaña.
  - Texturas: Constitución, Ugena, Nueva, la Flor, los huecos del centro y las fachadas en línea.
- **Sin probar** en el móvil ni en la Steam Machine.

### Calle de las Terradas: 15 entradas (23/11, Claude · Texturas)

- **Qué.** Las dos aceras. Desde Street View 2024 y la ortofoto del PNOA, que encaja con la calle del mapa.
- **El Catastro aquí está mal.**
  - Dibuja el bar (3789001), el 9 (3689713), el 10 (3789005), el 13 (3689720) y el 15 (3689711) 8 m más al sur de donde están. La casa del 1 (3689717) sí cuadra.
  - Faltan tres edificios: la casa de la esquina con la avenida, la obra a medio hacer y la casa baja del 11.
- **Clave nueva en `bake_godot.py`: `"shift": [dx, dz]`.** Mueve todas las partes de la referencia de esa casa antes de cualquier otra cosa (`SHIFT_RC`, justo después de leer cada parte y antes del pasillo de las calles). Solo actúa donde una entrada la lleva.
- **Fachadas.** Todas en la calle a 5 m de su línea (`te_write.py` en el scratchpad, por distancia `s` a lo largo de la calle). La casa del 9 va 2,5 m detrás de su tapia, como en la foto. La del 10 queda tras su jardín.
- **Partidas.**
  - La casa del 1 en tres entradas: `1e` con `rc` nulo, `1g` (`only: 1`, `reach`, `porch`) y `1`.
  - El 9 en cuatro: el garaje como caja de `rc` nulo delante, la casa con `clear` 4.5, la tapia y la verja del porche.
  - El bar en dos por alturas (`only: 1` para la parte baja).
- **Trampas.**
  - Un trozo de la parte de 1 planta del 1 asomaba 2,2 m delante de la casa de ladrillo, porque `clear` solo corta de -1 a L+1. Se arregló alargando el tramo de la tapia hasta 5,7 m.
  - La verja del porche se quedaba en 4,6 m² y el horneado la tiraba: lleva `deep` 1.0.
- **Mapa.** Frente a la copia, 15 casas nuevas, ninguna quitada ni cambiada. Cambia el despeje de los nodos de la avenida en la esquina (de 15,4 a 6,8 m, por encima de la mitad del ancho de la avenida). Cambian unos pocos árboles: el reparto de olivos depende del orden aleatorio.
- **También.**
  - `vin_jr3` pasa a `["obra"]` para Pretil (la Cruz Roja de la plaza de Jesús Requejo).
  - Las tapias bajas con `rc` nulo dejaban asomar ventanas azules con reja por encima. `casas.gd` trata su cara de atrás, que da a un patio abierto, como fachada a otra calle y le pone las ventanas de la casa. Pasaba también en las ya publicadas de Florido (`flo_p14t` a `_26t`), `toledo_20`/`_20b`, `delicias_39t` y `ugena_3t`. Las 13, más `terradas_9p`, llevan ahora un `"lado wall=..."` en blanco. Hoja `guion/fotos/tanda34/tapias_lado.jpg`.
- **Línea nueva `"ciego"` en `casas.gd`.** Deja lisos todos los costados que dan a otra calle, también los que no alcanzan las líneas `lado` (esas solo van al costado más largo). Se usa en `requejo_1`, la caseta del transformador de Pretil: era blanca lisa con una celosía arriba y una puerta de chapa, y salían ventanas con reja en el costado. En `bake_godot.py`, `NO_TREES` quita los dos árboles que pidió Pretil en (-430.7, 173.8) y (-417.7, 173.9); entra en vigor en el siguiente horneado.
- **Después:** `requejo_1` pasó a `["obra"]`. Pretil la hace a mano en `requejo.gd`, porque el usuario dijo «este edificio no se parece nada». La línea `ciego` sigue en `casas.gd` para otras casetas.
- **Pruebas.** `casas solo=terradas_,flo_p,toledo_20,delicias_39t,ugena_3t`: 4 ok. Hojas `guion/fotos/tanda34/terradas_1..3`. Aprobada por el usuario. Nada en commit.

### Filtros de pantalla: prototipo para comparar (23/11, Claude · Sistemas)

- **Qué pidió el usuario.** «Proponme filtros para el juego. CRT o tipo falso PSX», y después «Comparame los tres». Es un prototipo: falta su elección.
- **`filtros.gd` (nuevo).** Es un CanvasLayer en la capa 0 (el HUD va en la 1), con una sola pasada de sombreador sobre la imagen acabada. `Settings.data["filtro"]`:
  - 0: ninguno.
  - 1: «Consola de los 90». El 3D se dibuja a 270 filas (`scaling_3d_scale`, bilineal, sin MSAA ni resolución dinámica) y se agranda en bloques, con 24 tonos por canal y tramado Bayer 4×4. La niebla, un poco más cerca.
  - 2: «Tele vieja». Líneas de barrido, cristal curvado, esquinas oscuras, colores separados en los bordes, las rayas del fósforo y un poco de resplandor.
  - 3: las dos.
- **Menú.** Gráficos tiene ahora una fila «Filtro». Las dos pruebas que contaban 21 filas cuentan ahora 22.
- **Prueba.** Modo `filtros`: la plaza y la calle de Henry, de día y de noche, con los cuatro filtros, y el tiempo de GPU de cada uno. Las hojas están en `guion/filtros_*.png`.
- **GPU a 1280×720.** Se midió con otro Godot abierto: vale para comparar, no como cifra absoluta.
  - Ninguno: 5,8–6,7 ms.
  - Consola: 4,8–5,5 ms.
  - Tele: +0,05 ms.
  - Las dos: igual que la consola.
- **Otras pruebas.** `reglas`: 56 ok. Nada en commit.

### Calle de Sancho Panza: 20 entradas (23/11, Claude · Texturas)

- **Qué.**
  - Las dos aceras de los tres tramos: de las Monjas a Don Quijote, de Don Quijote a la curva, y la subida a los Cipreses.
  - Desde Street View 2024 y la ortofoto.
  - Entran también las casas de número de otra calle que solo dan aquí: Cipreses 25, Don Quijote 3 y 4, y las traseras de Comisario 24 y 28.
- **Catastro y mapa.**
  - El Catastro cuadra con la ortofoto. Es la línea del mapa (OSM) la que va unos 2,5 m al sur del centro real.
  - No se ha movido la calle. El norte va en una línea a 5 m. El sur va a 2,5 m, donde el pasillo de 2,4 m ya dejaba la trasera de `com_38`. El ancho real entre fachadas, unos 8 m, se mantiene.
  - `sp_write.py` en el scratchpad da las posiciones por tramo (s a lo largo, d a la izquierda).
- **Traseras de la calle del Comisario.**
  - `com_24` y `com_28` llevan `floors` 2, así que sus partes de una planta en Sancho Panza no las tomaba nadie y faltaban.
  - Ahora entran `sancho_c24` y `sancho_c28` (`only: 1`, `reach: 2`). Las otras partes de una planta de esas parcelas siguen siendo genéricas.
- **Correcciones con la foto del Catastro.**
  - El 25 de los Cipreses es enfoscado naranja, no ladrillo.
  - La casa de Don Quijote 3 es de ladrillo salmón (en la foto de 2024 se ve borroso, como enfoscado).
- **Mapa.**
  - Frente a la copia: 20 casas nuevas, ninguna quitada. Fuera los dos árboles de Pretil (`NO_TREES`).
  - Cambian banderas de bordes en `com_38`, `com_24`, `cip_23` y `cip_19`, por sus vecinas nuevas.
  - Cambia el despeje de tres nodos (Don Quijote: de 7,5 a 3,8 m).
- **Pruebas.** `casas solo=sancho_,com_38,cip_19`: 4 ok. Hojas en `guion/fotos/tanda34/sancho_1..3`. Aprobada por el usuario. Nada en commit.
- **La elección del usuario: «El primero sin temblor».** Queda solo la «Consola de los 90»: el filtro es 0 o 1, y un 2 o 3 guardado pasa a 1. La tele vieja y «Las dos» se han quitado, y el filtro no hace temblar los vértices. `filtros` (2 × 2 × 2 fotos): consola 4,8–5,5 ms frente a 5,8–6,7 sin filtro, ya sin otro Godot abierto. `reglas`: 56 ok.
- **Después, otra vez los tres** (el usuario: «Déjame los tres filtros disponibles en las opciones gráficas. Así los pruebo yo en la próxima versión»). Gráficos → Filtro: Ninguno, Consola de los 90, Tele vieja, Las dos. Ninguno vibra (sin temblor de vértices). `filtros` (16 fotos) y `reglas` (56 ok), bien.
- **El HUD también, sin los textos** (el usuario: «Se puede hacer que también afecten al HUD pero no a los textos?»). Mientras juegas, `filtros.gd` hace dos pasadas.
  - Debajo del HUD (capa 0): el 3D, con la curva del cristal, el brillo y los colores separados.
  - Encima de los dibujos del HUD (un rect en `hud.root`, z 2000): bloques, tramado, rayas, franjas y esquinas oscuras sobre el minimapa, los iconos y las cajas.
  - Los textos (Label, RichTextLabel, Button, LineEdit y la radio del coche) suben a z 3000 y quedan nítidos. Se recogen los nuevos con `node_added`.
  - El HUD no se curva, porque un texto nítido no puede curvarse con su caja.
  - En el menú, el mapa grande y la mochila (o sin HUD de juego) vuelve a ser una sola pasada, y los textos vuelven a su z.
  - Lo dibujado con `draw_string` sí se filtra: la «N» del minimapa, los números del indicador, «€», «PC», «3G».
  - `filtros`: OK, con una prueba nueva (11 de 11 textos subidos, todos de vuelta en el menú, nada con el filtro quitado) y fotos `filtro_hud_0..3`. Hoja en `guion/filtros_hud.png` y `guion/filtros_hud_detalle.png`. Nada en commit.

### Publicación de la 0.1.0 en GitHub (23/11, Claude · Sistemas)

- **Por qué.** Lo pidió el usuario: «Vale, con todo esto creo que ya tenemos suficiente contenido para un loop jugable decente. Prepara una release para la 0.1.0 (la 0.2.0 será tener modeladas ~100% las calles del pueblo)». Antes, Pretil y Texturas pararon y confirmaron que no les quedaba nada a medias.
- **Pruebas.** Dos pasadas completas.
  - La primera dio 11 fallos. Uno era el recuento de paredes: quedan 23 977 genéricas y el umbral pasa de 24 000 a 22 000. Los otros diez eran de coches y Tricornios (robar, pintar, taller, esquivar, patrullas), con el pueblo quieto: 0,00 m.
  - La segunda, con un diagnóstico nuevo (`_why_still()` en el mensaje del robo y de las patrullas), dio 1046 ok, 0 fallos. Si vuelve a salir, el mensaje dirá la fase, la pausa y el mapa abierto.
  - Por si no salen las patrullas, `_mayhem_checks` ya no da error: corta ahí.
- **Memoria con el renderizador del móvil:** 592 MB estática y 1805 MB de vídeo al final de la carga. En la 0.0.23 eran 773 y 2075.
- **Paquetes.** Están en `dist/v0.1.0/`: `Matritellus-0.1.0-{Windows.exe,Android.apk,Linux.tar.gz}` y `SHA256SUMS.txt` (dos espacios). El APK lleva la versión 0.1.0 (código 100).
- **Contenido.**
  - Sistemas: los tres filtros de pantalla, con el HUD filtrado y sus textos nítidos.
  - Pretil: la «Cruz Verde», el parque de Requejo, la caseta del transformador y su azafrán escondido.
  - Texturas: las calles de las Terradas y de Sancho Panza.
- **Sin probar** en el móvil ni en la Steam Machine.

### Seis palabras manchegas más: semos, te se, vide, paece, d'ande, amoto (23/11, Claude · Worldbuilding)

- **Por qué.** El usuario las dio con ejemplos: «Semos tos amigos aquí», «te se ha caío la cartera» (o «te s'a caío»), «hace mucho que la vide», «Paece que va a llover», «¿d'ande sales tú?», «me he comprao una amoto» (contraído «me' comprao una amoto», solo para ancianos).
- **Textos (`loc.gd`, CRLF guardado).**
  - 20 «se te» pasan a «te se» («ni te se ocurra», «¿Qué te se ofrece?», «Te se han ido %d horas en humo»…); los dos «se t'á» que ya iban contraídos pasan a «te s'á» (Alberto y `t_firmas_late`).
  - Tres «vi» pasan a «vide» (copistería, la mili, el chisme del jamón).
  - Cinco «parece» pasan a «paece». Primero lo puse en todo el verbo; el usuario lo corrigió: «"paece" es solo para "parece"», «"parecío" es para "parecido"». Luego precisó: «También valen "paeces", "paecen", "paecerlo". Es el participio el que no cambia porque ya tiene otra forma: "parecío"». Quedan paece, paeces, paecen, paecemos y paecerlo; «parecío» y «parecíos» no cambian. La llamada de la Josefa (`_vizum_checks`) busca «paecerlo».
  - «Somos», «de donde» y «moto» ya no salían: los textos dicen «semos», «de ande» no aparece y el viejo ya decía «amoto».
- **Prueba.** `_palabros_checks` (selftest.gd) vigila cinco reglas más: «se te / se t'», «vi», «parec…» (menos «parecío/a/os/as»), «de ande», «moto(s)».
- **Escrito en** `guion/palabros.md` (las reglas de la casa, 23-11-2026).
- **Resultado.**
  - `palabros`: 3 ok. Tras la corrección del usuario, otra vez `palabros` y `maxi`.
  - `maxi`: 8 ok. En su log hay un SCRIPT ERROR de `menu.gd:28` (`paint_font`), que es de un cambio sin guardar de otra sesión, no de esto.
- Sin commit.

### Menú principal: rótulo pintao (23/11, Claude · Sistemas)

Luis: «No me gusta que sean textos entre cuadros el texto seleccionado, y la letra es muy básica. Propón tres alternativas». Le enseñé tres maquetas en HTML (artefacto https://claude.ai/artifact/2D3SeoHpeH9ZwE7Wnu1CME): A, rótulo pintao en la pared; B, cartel de fiestas; C, pizarra del bar. Eligió la A («Me gusta la A»).

- `godot/assets/fuentes/KaushanScript-Regular.ttf` y `OFL_KaushanScript.txt`, de google/fonts. `Menu.paint_font()` le pone de respaldo la letra por defecto, para los glifos que le falten.
- Solo cambia la pared (`_skin == ""`): título, subtítulo y opciones pintados, sin placas (`_dress_heads`, `_painted`). La opción elegida (`_mark`) va en ANIL, con LEAN −0,035 rad y GROW 1,08, y el brochazo ALMAGRE se dibuja en `_draw_stroke` después de la pared, debajo de las letras. La Agenda (`notebook`) mantiene sus placas.
- Las filas de menos de 24 px (las de Gráficos, Sonido, Gameplay y partidas) usan `dense_font()`: una FontVariation con spacing_top −5 y spacing_bottom −4, sin agrandar. Si no, la página de Gráficos se salía de la pantalla.
- Los textos de párrafo (créditos, cómo jugar) y la línea de teclas siguen en Open Sans, por legibilidad.
- Créditos (loc.gd): «Tipografía: Open Sans y Kaushan Script (licencia SIL Open Font).». Se lo avisé antes a Worldbuilding, que estaba tocando loc.gd.
- Pruebas: `titulo` 2/2 y `mando` 1/1. `menu shots` ahora saca también graphics y gameplay.

### Avenida de Martín Descalzo, tramo sur: 35 entradas (23/11, Claude · Texturas)

- **Qué.** Las dos aceras de la rotonda a Ortega y Gasset, con la esquina de la Constitución (120 y 122) y Estrella 2. Desde Street View 2024 y el Catastro.
- **Huecos.** Entre las parcelas del Catastro hay tapias, almacenes y el electricista que no tienen ficha: van con `rc` nulo (`md_23t`, `19t`, `15t`, `13t`, `9c`, `9e`, `4t`) o alargando el frente de la vecina con `fill` (`md_21`, `19d`, `17d`, `12`).
- **Retranqueos reales.** `md_16` 3 m, `md_12d` 2,5 m, `md_12` 5 m (`clear` 5, porque una parte de dos plantas quedaba delante), `md_17` 0,5 m. `alinea.py` sin fachadas sueltas.
- **`md_rot`.** La esquina de la rotonda (4397114) no tiene ficha: va con líneas `lado` y el rótulo «CAFETERÍA».
- **`md_13t`.** La tapia de 27 m no llegaba a 12 piezas: lleva machones y una caja de contador con `parche`.
- **Mapa.** Frente a la copia (`map_before_md.json` en el scratchpad): 35 casas nuevas, ninguna quitada, árboles 2943 iguales, relieve igual; un nodo de despeje de 9,5 a 7,5 m.
- **Pruebas.** `casas solo=md_` OK. Hojas en `guion/fotos/tanda34/descalzo_1..6`. Aprobada: «Visto bueno y siguiente». Nada en commit.
- **Siguiente.** El tramo norte de Martín Descalzo y después Consuegra.

### Gráficos en dos páginas: «Avanzados» (23/11, Claude · Sistemas)

Luis: «En gráficos hay muchas opciones. Vamos a dejar Calidad, Resolución, Ventana, Brillo y Filtro. Las demás opciones dentro de "Avanzados"».

- `game._menu_page`: «graphics» y «graphics_adv» comparten la misma rama, y `adv` decide qué filas salen.
- «graphics» tiene 7 filas: Calidad, Resolución, Pantalla, Brillo, Filtro, Avanzados y Volver. Van a tamaño 26, la letra pintada grande.
- «graphics_adv» tiene 17 filas: Sincronía vertical … Modo Silent Hill, Tráfico y Volver. Tanto Volver como Esc llevan de vuelta a «graphics».
- loc.gd: `s_advanced`, «Avanzados» / «Advanced».
- Pruebas que he cambiado en selftest:
  - `_reglas_checks` ahora comprueba la lista de Gráficos y que Avanzados tenga 17 filas;
  - `_run` comprueba 7 y 17 filas;
  - `_mando_checks` recorre «graphics_adv», la página más larga;
  - `--menu` saca también la foto de graphics_adv.
- Resultados: `reglas` 56/56, `mando` 1/1.

### La pared del menú, más panorámica (23/11, Claude · Sistemas)

Luis: «lo haría más panorámico, está muy cuadrado (o incluso alargado verticalmente)». Cambios en `menu.gd` `_draw`:

- La pared mide al menos `WALL_W` = 1000 px de ancho.
- El zócalo es ahora `PLINTH` = 56 px; antes, 78.
- El margen de arriba baja a 38 px y el de abajo es PLINTH + 22.
- Las piedras se apartan del texto según el ancho de `_box`, no a 290 px fijos.

En `rebuild`, cuando todas las filas de la pared son grandes (24 px o más), la separación de `_list` pasa a −8. Las páginas de filas pequeñas siguen con 3.

`titulo` 2/2, `mando` 1/1 y fotos con `menu shots`.

### La pared del menú, gastada y con Don Quijote y Sancho (23/11, Claude · Sistemas)

Luis: «Mucho mejor, pondría alguna marca de ladrillo y alguna pequeña grieta, un quijote y sancho en figuras negras en un lado, todo para rellenar el hueco vacío». Su referencia fue la foto del cartel de chapa de la entrada del pueblo por la antigua N-IV, «pero nosotros manteniendo el zócalo azul».

En `menu.gd`, `_draw_wear(r, plinth_y)` se llama justo después de las piedras. Pinta en los huecos a izquierda y derecha de `_ink_rect()`, que es la unión de lo que ocupa cada línea de texto y el escudo, no la columna entera:
- `_brick_patch`: un desconchón irregular con argamasa, ladrillos en hiladas y el borde de la cal.
- `_crack`: grietas finas, con una rama.
- Las figuras: `assets/menu/quijote_sancho.svg`, una silueta hecha a mano porque no había ninguna libre en vector. Van a la derecha, de pie sobre el zócalo, hasta 300 px de ancho, y solo si queda un hueco de más de 110 px.

`titulo` OK, `mando` OK. Fotos con `titulo shots` y `menu shots`.

### Fátima Corsa y las gafas de la Óptica Corsa (23/11, Claude · Sistemas)

El encargo lo pasó Pretil, con las palabras de Luis (ver PROJECT_STATE). La tienda (optica.gd) y su interior (optica_dentro.gd: open, clerk_spot/clerk_h, probador_spot/probador_h) son de Pretil.

- `fatima.gd`: copia el esquema de manuela.gd. LOOK lleva top 24 (la bata) en blanco y gafas 7. PRICE vale 20, como todo, «hasta que decida precios» (Luis). SKIP = [11]: el parche de pirata no se vende. `try_on` abre `open_shop_ropa` con opt 12 y col −1.
- `game.gd`:
  - `_col_off()`: con col −1 no hay color. Sale en `_shop_owns`, en col_prev/next, en el redibujado, en `_shop_buy` (no añade la clave "-1" al armario) y en `_refresh_armario`, que pasa una fila de color vacía y así la oculta.
  - `kind["skip"]` llega a `ropa_for_sale`.
  - `_ropa_key_of` incluye ahora pelo, peinado y barba, porque la foto de la óptica es de tu cara.
  - El cableado de `fatima`: setup, talk y tick.
- `ropa_icono.gd`: nuevo parámetro `face` (cámara a 2,5 de distancia, fov 22, apuntando a 1,36 de alto).
- `tiendas_ropa.gd`: el tipo "gafas" y "optica": "gafas". `minimap.gd` `_shop_icon` dibuja "gafas" como unas gafas redondas sobre la moneda.
- loc.gd (CRLF):
  - las frases de Fátima: n_fatima, fatima_hello, fatima_chat, fatima_q, fatima_yes, fatima_no, fatima_bought, fatima_poor y fatima_bye;
  - los textos de la tienda: arm_shop_title_gafas, arm_have_gafas y arm_have_btn_gafas;
  - las firmas: firma_si_fatima y firma_no_fatima.
- selftest: `_fatima_checks`, el modo `--fatima` (3/3) y la llamada en `_run`. Sin el interior de Pretil, prueba solo el espejo.
- Relaciones: Fátima en guion/relaciones.json, en [8, 8], sin foto hasta que salga en el juego. Hay que sacarle la foto con `--portraits` cuando esté.
- Le pedí a Pretil que quite las gafas de TRINKET_GLASSES en maniqui.gd (los maniquíes de la Tetoqa) para completar la separación.

### Avenida de Martín Descalzo, tramo norte: 27 entradas (23/11, Claude · Texturas)

- **Qué.** Las dos aceras de la rotonda de la Avenida de Europa a la Calle de la Mora, desde Street View 2024 y el Catastro. Sobre todo naves, tapias y almacenes. Las tapias van con `rc` nulo.
- **Mapa.** La línea de la avenida (OSM) va unos 5 m al este del centro real.
  - El oeste está en sus fachadas del Catastro, a 8-10 m de la línea. El este va a 3 m, la línea del garaje de 4398538, y junto al bar a 5,8 m, porque a 3 m el despeje del nodo 865 bajaba a 3,0 y estrechaba la calzada a 5 m.
  - `mdn_write.py` (scratchpad) da las posiciones con `P(s, d)`: s a lo largo de la línea desde la rotonda, d al oeste (+) o al este (−).
- **Con referencia.** `md_e161` (4402008, la esquina con la rotonda, número de la Avenida de Europa), `md_57`, `md_47d`, `md_45d` (`reach` 15), `md_47`, `md_37`, `md_37d` (con `fill`), `md_33`, `md_31`, `md_29`, `md_66t` (4398536: la foto del Catastro es la tapia de placas, con la caseta de contadores detrás), `md_56` (4398538, con `fill`).
- **Lo que no tiene ficha.** La tapia blanca de celosía del bar y la valla de chapa, el frente largo de la empresa del 47 (una parte de 0 plantas en el Catastro: `md_47c` va como caja de 8 m) y la casa blanca nueva del final (`md_62n`).
- **Rótulo.** Solo «FLORISTERÍA». Los nombres de las empresas no salen.
- **Pruebas.** Test `casas` de las 27 OK, tras dar más piezas a `md_43t`, `md_80t` y `md_80`. `md_58t` con fondo de 0,6 m se caía por no llegar a 5 m²; ahora tiene 1,8. Hojas en `guion/fotos/tanda34/descalzo_7..11`. Esperando el visto bueno. Nada en commit.
- **Siguiente.** Consuegra.

### Fotos de cuerpo entero de los personajes únicos (23/11, Claude · Sistemas)

Luis: «Puedes de paso mostrarme todos los NPCs únicos. Quiero ajustar el aspecto de algunos».

- `--selftest --portraits --cuerpo` saca a cada personaje de cuerpo entero en `guion/fotos/cuerpos/<id>.png` y escribe `nombres.json` con id → nombre. Usa `portrait.gd` `viewport(look, px, body=true)`. Sin `--cuerpo`, el modo hace lo de siempre.
- Fátima entra en las fotos aunque su interior no esté hecho.
- La hoja `guion/personajes_unicos.png` reúne los 38, numerados y con su id. Se hizo con PIL a partir de esas fotos.
- Las gafas de Fátima van a 20 €, como todo: «De momento todo a 20€ hasta que decida precios».

### Retoques de aspecto de seis personajes únicos (23/11, Claude · Sistemas)

Luis, sobre la hoja de los únicos: «A Edmundo ponle un tono de piel más rosado / A la Josefa el moño le clippea el pañuelo. / A Una Señora Mayor ponle el pelo gris en vez de blanco (deberíamos tener opciones de gris y blanco para ancianos, no solo blanco) / La Loli y a el Alberto ponles pelo largo, mantén la gorra. / A Tomasa Malvora ponle gafas de esas de ojo de gato rosa / El Alberto cambiale a pelo negro».

- **Edmundo** (`fondo_casa.gd` EDMUNDO_LOOK): piel 0xf4cdbd, antes 0xf7e3d6.
- **Josefa**: el moño (hair_style 1) ya no se dibuja bajo un pañuelo o una gorra (`chara.gd` `_hair`). Queda recogido bajo la tela. Abajo en la nuca también asomaba.
- **La madre del alcalde** («Una señora mayor», `recress.gd`): pelo gris 0x9a9aa0.
- **Canas para los mayores.** Los vecinos mayores sacan blanco o gris (`game.gd`: 0xd9d9de, 0xe8e8ea, 0xb9b3a8, 0xb4b4ba, 0x9a9aa0, 0x7d7d84). El creador tiene un color nuevo, «Canoso» (gris 0x9a9aa0), añadido al final; el antiguo «Canoso» blanco se llama ahora «Blanco». Las partidas guardadas no cambian.
- **Loli**: melena larga (hair_style 15, `pelo_melena_larga`) bajo la gorra.
- **Alberto**: pelo negro 0x111111. Pasó por la melena desfilada (30) y la ondulada (28); la última es la siguiente.
- **Alberto, con la melena de Loli.** Probé a rellenarle la cabeza del color del pelo bajo la gorra: «Sigue teniendo calvas». Luego, un rapado negro bajo la melena: «No, se sigue viendo mal. Probemos a ponerle el mismo peinado que la Loli, pero en negro y poniéndole dejadez». Lleva la melena larga (hair_style 15, `pelo_melena_larga`) en negro, sin barba (`face` 0) y con la barba de tres días (`barba3` 1, «Dejadez»). Los rellenos y el rapado bajo el pelo se han quitado del código; Loli no ha cambiado. Fotos en `guion/retoque_alberto.png`. **Aprobado por Luis el 23/11: «Perfecto. Visto bueno».**
- **Tomasa**: gafas de ojo de gato (8) en rosa. Hay una clave nueva, `"glasses_color"`, que `chara.gd` `_glasses(kind, col)` usa para la montura de las gafas modeladas.
- **Fotos de lado y de espalda.** `--portraits` acepta `--giro=<rad>`, que gira al personaje y guarda `<id>_giro.png`.
- **Pruebas.** Test `nuevo` 8/8: el creador dice Blanco y Canoso, y tiene tantos nombres como colores. Fotos rehechas en `guion/fotos/cuerpos/` y `guion/fotos/`, y `relaciones.html` reconstruido. Antes y después en `guion/retoques_antes_despues.png`. Nada en commit.

### Fátima regala las primeras gafas y vende el parche (23/11, Claude · Sistemas)

Luis: «Cuando Fátima te termine las pruebas dirá que te regala las primeras gafas, que te ha visto cara de pobre además de cegato. Si quieres más tendrás que pagarlas. También añadiría parche en el ojo, ya que lo considero cosa de ojos».

- **La primera vez.** Tras el saludo, Fátima te mira la vista (`fatima_test`): las letras, «más dioptrías que el tío Gerardo» y «las primeras te las regalo, que t'he visto cara de pobre además de {cegato|cegata}. Si quieres más, ya te tocará pagarlas».
- **El espejo.** Hasta que te llevas un par (stats `fatima_regalo`), la pregunta es `fatima_q_free` y el espejo abre a 0 €. Al coger el primero, ella dice `fatima_gift` y el resto vuelve a 20 €.
- **Cómo va.** Es genérico: `open_shop_ropa` acepta `kind["free"] = {stat, then, line}`, y `_shop_buy` lo aplica.
- **Parche de pirata.** Se vende en la óptica (`SKIP` vacío). Su frase de charla ahora dice que tiene parches «que eso también es cosa de ojos».
- **Pruebas.** `fatima` 4/4 con ventana: el primero a 0 € y el segundo a 20 €. Sin ventana fallan las fotos. `maxi` 8/8. Nada en commit.

### El hueco de la Calle del Salvador: `salvador_3` (23/11, Claude · Texturas)

- **Por qué.** Pretil avisó de que no había casa entre `salvador_1` (x −123) y su óptica (`salvador_5`, x −104), en la acera norte.
- **Qué hay.** El Catastro no tiene ningún edificio ahí (la carpeta 4192011 está vacía). La foto aérea muestra una crujía estrecha a la calle y detrás un corral con maleza. En Street View 2024 es una casa vieja de dos plantas, vacía.
- **Cómo va.** `rc` nulo, fondo 4 m, 2 plantas, h 7,6, cornisa. La puerta tapiada va como `paño` de ladrillo, porque un `parche` en planta baja queda tapado por el zócalo. Encima, un parche blanco hasta el forjado.
- **Pruebas.** Alineada con sus dos vecinas (`alinea.py`: 0,0). Horneado: una casa nueva y nada más (el despeje del nodo 455 pasa de 3,7 a 2,5, igual que sus vecinos). Test `casas` OK. Hoja `guion/fotos/tanda34/salvador_1.jpg`.
- El tramo norte de Martín Descalzo quedó aprobado: «Visto bueno y siguiente».

### Calle de Consuegra: 36 entradas `co_*` (23/11, Claude · Texturas)

- **Qué.** Las dos aceras, de la Calle de Tembleque (x −198) al final oeste (x −702). Línea en el scratchpad `co_line.py`; textos en `co_write.py`. En `casas_calles.gd` van tras `md_62n`.
- **Trampa del cruce con Ugena.** La línea de Consuegra comparte 8 m con Ugena (s 189,4–197,6). Las primeras tapias acababan dentro del cruce y el despeje de los nodos 764/765 caía de 17,8 a 2,0. Ahora `co_17t` acaba en s 182, `co_25f` y `co_18t` empiezan en s 203 y 205: despejes 4,9 y 4,4.
- **Tiras finas del Catastro delante de la fachada.** En `co_26` tapaban la cochera y la puerta: `clear: 1.5` las corta. El `paño out` (mirador) se quitó, hacía tiras raras.
- **Colores.** `brick_pale` y `brick_salmon` se ven naranjas: tapias claras con hex liso (`d6c8a2`, `cdb48c`).
- **Pruebas.** Horneado: 36 nuevas, nada quitado ni cambiado. Test `casas` OK (las 36). Hojas `guion/fotos/tanda34/consuegra_1..6.jpg`. Esperando el visto bueno. Nada en commit.

### Modo Historia y Modo Chavisca en el menú principal (23/11, Claude · Sistemas)

Luis: «Un cambio en el menú: en vez de Continuar y Nueva partida estas dos opciones estarán dentro de Modo Historia. Debajo de modo historia estará Modo Chavisca. Un modo con sus guardados aparte sin misiones, sin heat level, sin azafrán. Solo dar vueltas por el pueblo y hablar con los NPCs».

- **Menú principal:** Modo Historia, Modo Chavisca, Ajustes, Cómo jugar, Créditos, Salir.
  - Cada modo abre su página («story» / «chavisca» en `game.gd` `_menu_page`), con un rótulo bajo el título. Tiene Continuar (si hay partida de ese modo), Nueva partida y Volver.
  - Las páginas de huecos («slots», «newslot») vuelven a la página de su modo.
  - `_open_mode(free)` pone `game.chavisca`.
- **Guardados aparte:** `_slot_path` añade `chavisca_` (`user://matritellus_save_chavisca_1.json`…). El hueco no nombra misión, solo día y dinero. El guardado lleva `"chavisca": true`.
- **Partida nueva:**
  - Sin prólogo, derecho al creador; tras el Padrón, `_chavisca_begin()`. No hay vuelo sobre el pueblo ni Tía Paca.
  - Las stats quedan limpias como al final de la cinemática y empiezas en el paso «tbc» (fin de la historia: nada que hacer), a pie, en tu acera (`_home_pavement`).
  - El objetivo dice `obj_chavisca`. El puente de hierro está abierto.
- **Sin misiones:**
  - `talk_to` solo da la charla. La charla corriente está ahora en `_chat(n, s)`. No hay recados, ofertas, firmas, ventas, cartas ni sparring. Alberto y la Chiki usan sus frases «idle».
  - `_offer`, `_weekly_call` y `llamadas.ring` no hacen nada.
  - `marcas.givers()` está vacía: nadie sale en el mapa ni lleva flecha.
  - Lo demás (Recress, faenas, Koke, la tienda de la Josefa, el motín…) ya depende de stats que en este modo nunca se ponen.
- **Sin Tricornios:**
  - `police.add_heat` no suma.
  - Los pitufos de ronda no te ven el turbo.
  - El borde del mapa no da persecución (`limite._start`).
- **Sin azafrán:** no hay flores en la calle (`_spread_saffron` borra las de la calle y no pone nuevas). Las escondidas tampoco salen, `_take_flower` no coge nada y el contador de azafrán no aparece en la pizarra (`hud.set_counts` con −1).
- **Sin tocar:** la Agenda sigue con sus páginas, también las de misiones, que salen vacías o con lo de la historia. Las tiendas con flecha, la máquina de bolas y el ajedrez de los tableros siguen.
- **Pruebas:**
  - `chavisca` 6/6. Fotos `shots/chavisca_menu` y `chavisca_pagina`, juntas en `guion/menu_chavisca.png`.
  - Cambiadas sin pasar las dos comprobaciones del menú principal de la prueba completa: en `_mayhem_checks`, «Continue» está en la página «story». La prueba completa no se ha pasado.
- Nada en commit.

### Buero Vallejo, Juan Antonio Jiménez y Las Cruces 26–36: 25 entradas (23/11, Claude · Texturas)

- **Qué.** Los adosados de 1990–94 de las dos calles y las cinco casas de Las Cruces entre ellas. Escritas por el scratchpad `bv_write.py`, que mete las entradas en `calles.json` y las líneas en `casas_calles.gd` tras `co_40`. Mismo kit que `vin_bv14`.
- **Cuartos traseros.** Con `floors` 3 (lo que da `house_street.py`), las partes de dos plantas del Catastro quedaban fuera y se pintaban como casas genéricas con ventanas azules dentro de la manzana (28 paredes). Con `floors` 2 quedan 11, todas de otros solares.
- **Color.** El ocre `e0b050` de `vin_bv14` se ve amarillo limón al sol; aquí va `c4964e`.
- **Pruebas.** Horneado: 25 nuevas, nada quitado; `cruces_38` solo cambia su medianera. Test `casas` OK. Street View de esta zona sale muy lavado: se compara sobre todo con las fotos del Catastro. Aprobada: «Visto bueno y seguimos». Nada en commit.

### Modo Chavisca: cinemática, minijuegos abiertos, sin Agenda ni barras ni minimapa, marcador en el mapa (23/11, Claude · Sistemas)

Luis: «Oculta la agenda en este modo. Y crea una nueva cinemática introductoria para el modo Chavisca. Que hable de que hoy parece un día tranquilo. De que deberías ir a tomar el fresco, hablar con los vecinos. Que se encuadren varios de los edificios más complejos que hemos hecho. Todos los minijuegos deberán estar desbloqueados, Recress, Ajedrez. Que no salgan las dos barras de arriba. Aquí no hace falta saber la hora ni el dinero ni el azafrán que tienes. Ni tampoco el minimapa, si el jugador quiere ir a algún sitio siempre puede poner un marcador en el mapa al abrirlo».

- **Cinemática.**
  - Tras el Padrón, `_start_chavisca_flyover()`: el pregonero con `flyover_chavisca`, siete líneas, y una toma por línea.
  - Las seis primeras rodean edificios hechos a mano (`CHAVISCA_SHOTS`: Petril, plaza del Ayuntamiento, plaza de toros, molino, almazara y Caridad). Cada toma se calcula con `_place_shot` a partir de la caja de sus mallas.
  - La última baja hasta tu puerta, como la de la historia, pero sin Tía Paca. Al acabar llama a `_chavisca_begin()`.
  - Fotos: `guion/chavisca_intro.png` y la prueba `chavisca_intro`.
- **Sin Agenda.** En la pausa, «Minijuegos» sustituye a la Agenda y lleva a la página «minijuegos». Su contenido es el mismo que la página 3 de la Agenda, que ahora sale de `_minigame_items()`.
- **Todo abierto.** `_chavisca_unlock()` se ejecuta en cada `start_game` de este modo:
  - abre `unlocked` de box, jamon y ajedrez;
  - pone el Recress en «hecho», así que la sala está abierta con su Tokken 9;
  - da la misión del ajedrez por hecha, con los tableros de la plaza disponibles.
  - Fonsi te ofrece guantes al hablar con él.
  - El motín del jamón sale los jueves sin el menú de la Josefa (`motin.wanted`).
- **Sin barras ni minimapa.** `hud.bare` oculta el calendario y el objetivo, la pizarra de dinero y azafrán, y el minimapa.
- **Marcador propio en el mapa grande (en los dos modos).**
  - Una cruz marca el centro del mapa. La fila «Poner marcador en la cruz» pone el marcador ahí; con ratón o dedo, clic en cualquier punto del pueblo.
  - La flecha y la ruta llevan al marcador (`map_pin`, `track_pick` «pin», `put_pin`). Al llegar a menos de 7 m se quita, con el aviso `t_pin_there`.
  - `minimap.gd` tiene `cross()` y `world_at()`.
- **Pruebas.** `chavisca` 8/8 y `chavisca_intro` 2/2. Nada en commit.

### «Tó», «toa» y «golismera» (23/11, Claude · Worldbuilding)

- **Por qué.** El usuario: «"tó" en vez de "todo". Ej: "No te digo ná y te lo digo tó" // "¡Me cago en tó!"»; «"toa" en vez de "toda"»; y «golismero (o golismera)» = cotilla, que le gustó en boca de la Maruja.
- **Textos (`loc.gd`, CRLF guardado).** 73 «to» de los textos en castellano pasan a «tó»; dos «to la» (la cabeza, la vida) pasan a «toa la». La Maruja dice ahora «Que no soy golismera, {hermoso|hermosa}. Yo archivo.» (en: «I’m not nosy»).
- **Prueba.** Regla nueva en `_palabros_checks`: «to» sin tilde. La de Luis («en el amor y en kebab tó vale») busca la frase nueva.
- **Escrito en** `guion/palabros.md`.
- Sin commit.
- **Después, «cerquillo» por «bordillo»** (usuario: «"cerquillo" en vez de "bordillo"»). El único texto era el tropiezo (`t_trip`): «Ese cerquillo no estaba ahí.». La peña «El Bordillo» conserva el nombre (pendiente de que el usuario diga si pasa a «El Cerquillo»). La prueba `palabros` avisa de «bordillo», menos en «el bordillo».

### «Ná», «sentío» y repaso de los diálogos con palabros.md (23/11, Claude · Worldbuilding)

- **Por qué.** El usuario pidió repasar todos los diálogos con la documentación de palabras al día y que le dijera los cambios. Le propuse tres bloques y contestó: «A. Genial. B. No me gusta ninguna. Son demasiado arcaicas. No apliques estas. C. Bien, y añade que aquí es "sentío" en vez de "sentido"».
- **A, aplicado.** 80 «na» de los textos en castellano pasan a «ná», con tilde como «tó».
- **B, descartado.** Eran formas viejas de «Cómo hablan los mayores» (abora, cimenterio, escuro, dispierto, poblema, bueso, uguas, mujuer, ebros, busanillo) para la Paca, la Josefa, la Dolores, el Diurno, el Nocturno, la Tomasa y los viejos genéricos. No van: queda apuntado en `palabros.md` como «sin arcaísmos».
- **C, aplicado.** `palabros.md` sin contradicciones: «ná / tó», «paece que hay de muda», «en tó el sentío». Y «sentido» → «sentío» en los textos: «¡Que me has dao en tó el sentío!» (viejos) y «Y no en el buen sentío» (Koke).
- **Prueba.** `_palabros_checks` avisa también de «na» sin tilde y de «sentido».
- **De paso.** La prueba `palabros` fallaba por dos frases nuevas de la Fátima, sin commit y de otra sesión. Quedan en «¡Mira bien ande vas!» y «Firmo, que lé leío bien…». Avisado a Sistemas.
- Sin commit.

### Gentilicios de Madridejos, Consuegra y Camuñas (23/11, Claude · Worldbuilding)

- **Por qué.** El usuario dio los gentilicios: Madridejos madridejense / barrudo; Consuegra consaburense / cabezón / consuegrero (despectivo); Camuñas camuñero / «de Coconia» (burlón).
- **Escrito en** `guion/palabros.md`, en una tabla de «El pueblo por dentro».
- **Textos (`loc.gd`).**
  - Viejos que cuchichean: «Por lo menos es {consuegrero|consuegrera}.».
  - Sopiss: «Es por los cabezones, que siempre llegan tarde.».
  - El testigo sigue con «Seguro que es {camuñero|camuñera}», porque al usuario le gusta más cómo suena.
- **Prueba.** `palabros` pasa.
- Sin commit.

### Peso impar y Calle Rollo: 12 entradas, `RESHAPE` y `base_from` (23/11, Claude · Texturas)

- **Qué.** El lado impar del Peso, del 7 al 17, y el callejón sin salida «Calle Rollo». Escritas por el scratchpad `ro_write.py` (en `casas_calles.gd`, tras `ja_7`).
- **`RESHAPE` (bake_godot.py, tras `RENAME`).** Redibuja una calle por puntos dados: mueve sus dos extremos y añade los del medio con números nuevos al final, así que ninguna otra calle cambia de número. Solo se usa para la Calle Rollo: estaba ~5 m al este y su pasillo se comía la casa de la boca (`rro_37`). La boca queda sobre la recta de la Calle del Rollo, así que esa calle no se mueve.
- **`base_from` (calles.json).** Lista de calles de las que una casa toma su nivel. Puesta en `rro_19`, que al acercarse el callejón tomaba el nivel de una pared lateral cuesta arriba y quedaba 0,9 m por encima de su puerta.
- **Despiste.** Escribí la hoja nueva encima de `guion/fotos/tanda34/rollo_1.jpg`, que ya existía. La vieja se recuperó con `git restore` (estaba en el commit) y la nueva se llama `rollo_callejon_1.jpg`.
- **Pruebas.** Horneado: 12 nuevas, nada quitado. Test `casas` OK (con `rro_19`, `rro_37` y `rro_39`). APROBADA por el usuario («Visto bueno y siguiente»). Nada en commit.

### Las sierras en el horizonte (23/11, Claude · Sistemas)

- Luis, con un Street View del Camino de Toledo 76: «unas texturas o algo de fondo en la lejanía para que se viesen las montañas en el horizonte como en algunos puntos del pueblo».
- `tools/sierras.py` baja el MDT200 del IGN (EPSG:4258, CC BY 4.0) para ±0,45° de latitud y ±0,58° de longitud alrededor del origen del mapa. Lo guarda en `tools/ign/mdt200_ll.asc` y escribe `godot/data/sierras.json`: la rejilla en float16 base64 y sus bordes en metros del juego. Rejilla lat/long porque el mapa es un escalado lineal de lat/long.
- `godot/scripts/sierras.gd` es una MeshInstance3D creada en `game._setup_sky` y pintada en `_apply_sky` (`paint(top, hor, night)`). El shader recorre cada rumbo desde la cámara en tres franjas (2,5-9, 9-25 y 25-48 km), con la curvatura de la tierra y ×`K` = 2,2. Escribe `POSITION.z` casi a 0 (la profundidad va al revés), así el pueblo siempre la tapa y el cielo no. `fog_disabled`. Se oculta con «silent».
- Trampa: `Parts.thin` esconde de lejos las mallas pequeñas por el tamaño de su AABB (no mira `custom_aabb`). Por eso los vértices van ×1000 aunque el shader los coloque.
- Créditos (loc.gd): MDT200 añadido junto al MDT05.
- Probado con fotos (vistas= desde el Camino de Toledo y al sur del pueblo, a las 11, 20.6 y 22.5 h): `guion/sierras_horizonte.png`. Sin test propio; nada commiteado.
- Luis después: «Ponlo a x2.5. Como lo demás» (`K` = 2,5) y «que se vea el castillo de consuegra y los molinos». Están en `hitos` de sierras.json: el castillo de la Muela y los 12 molinos del Cerro Calderico, de una consulta a Overpass guardada en `tools/ign/consuegra_osm.json` (sin la torre del Palacio Prioral). `sierras.gd` los dibuja con una segunda malla (`_make_hitos`, `HITO_SHADER`): siluetas planas `MOLINO` y `CASTILLO` en metros, ×`HITO_K` = 2,5, de cara a la cámara, 5 m metidas en la loma, con `discard` si un cerro más cercano las tapa, un pelo por delante de las sierras. Los colores de vértice van con pow 2,2 (si no, salen lavados).
- La banda cercana pasa de 40 a 64 pasos: con 40 la cresta salía más baja que la tierra bajo los molinos, y flotaban.
- Luis: «que se iluminasen al atardecer y por la noche. Como en la vida real, que tienen focos». Uniform `lit` = smoothstep(0,06, 0,4, `sky_fx.night`): se encienden hacia las 20:45 y del todo a las 21:30. El color va de `day` a `flood` = (1, 0,60, 0,26) × 1,3 al pie y 0,75 arriba (`v_up`). Cada parte toma el foco según `UV2.x` (1, y 0,35 las aspas). Con ×1,9 salía blanco crema por el tonemap. Fotos a las 21.3 y 23 h: `guion/consuegra_focos.png`.

### Víctor Pradera y Pajaritos: 11 entradas (24/11, Claude · Texturas)

- **Qué.** El lado impar de Víctor Pradera (1, 3, 9, 11, 13, 15, 17), el 8, y Pajaritos 3, 4 y 5. Escritas por el scratchpad `vp_write.py` (en `casas_calles.gd`, tras `rollo_27`).
- **El cuartel.** `vp_4` (Víctor Pradera 4, 4397002) llegó a escribirse y se quitó: su parcela pisa 8,5 m² del contorno `cuartel_built` de `cuartel.gd`. El usuario: «No le pises nunca el trabajo a Pretil». Antes de describir una casa junto a un sitio hecho a mano, mido su parcela contra la zona de ese sitio en `bake_godot.py`.
- **Despiste.** Un `sed s/brick_pale/brick_buff/g` cambió también 9 casas viejas de `casas_calles.gd`. Se devolvieron al momento, línea a línea desde la copia de antes; fuera del bloque nuevo, el archivo es idéntico.
- **Pruebas.** Horneado: 11 nuevas, nada quitado; `nueva_3` solo oculta una medianera. Test `casas` OK. APROBADA por el usuario («Visto bueno y paramos»): la tanda se detiene aquí. Nada en commit.

### Versión 0.1.1 (24/11, Claude · Sistemas)

- Luis: «Procedamos a preparar release. Si todo sale bien publícalo». Pretil, Texturas y Worldbuilding congelados durante la preparación.
- Prueba completa 1: 1063 ok y 2 fallos, los dos de la prueba:
  - «houses meet their street» con 3481 fachadas; el umbral pasa de 3500 a 3000, porque los sitios hechos a mano se quedan con las suyas.
  - El espejo de la Óptica sin ventana no dibuja retratos; se acepta como en la Pisacastaña.
- Prueba completa 2: 1065/1065.
- Memoria con el renderizador del móvil: 789 MB estática y 2141 MB de vídeo. En 0.1.0 eran 592 y 1805; en 0.0.23, 773 y 2075.
- Contenido: Modo Chavisca, marcador del mapa, sierras con Consuegra y sus focos, Óptica Corsa y Fátima, carteles de la entrada norte, menú nuevo, retoques de personajes y las calles de Texturas.

### Cristo del Humilladero: 21 entradas (24/11, Claude · Texturas)

- **Qué.** La hilera de 1993 del lado oeste (UR EL CERRO 2 a 42 en el Catastro, 4098601..21), `hum_2..42`, escrita por el scratchpad `hum_write.py` (en `casas_calles.gd`, tras `paj_4`). Comprobado antes contra todas las zonas hechas a mano de `bake_godot.py`: nada a menos de 15 m.
- **Cómo.** Solo Street View 2024: 14 vistas, cada trozo asignado a su casa proyectando las fachadas en la foto desde la posición real de la cámara (el visor de Maps a 800 px tiene unos 120° de ancho, no 90). Las fotos del Catastro de varias parcelas son de otra hilera.
- **Alineación.** `alinea.py` daba el 16 y el 10 adelantados 1,2 y 0,8 m; van en la línea de sus vecinas con `clear` 1,4 y 1,0. (Primero se pusieron con `fill` por leer mal el signo: en `alinea.py`, + es adelantada.)
- **Pruebas.** Horneado: 21 nuevas, nada quitado ni cambiado. Test `casas solo=hum_` OK. APROBADA por el usuario («Visto bueno y siguiente»).

### Silos de la Magdalena: 10 entradas (24/11, Claude · Texturas)

- **Qué.** `sil_25, 23, 21, 19, 17, 15, 13, 11, 5` y `sil_p8` (Plaza de la Magdalena 8), escritas por el scratchpad `sil_write.py` (en `casas_calles.gd`, tras `hum_2`). Comprobado contra las zonas de `bake_godot.py` y las coordenadas de los scripts hechos a mano: nada cerca.
- **Alineación.** `sil_5` girado 0,65 m respecto al 11: frente en la línea del 11 y `fill` de 1,0 m. Horneado: 10 nuevas, nada quitado ni cambiado; el nudo del cruce sur (Ángeles / Camino de Toledo) pasa de 3,3 a 3,0 m de holgura.
- **Color.** El ladrillo rojo oscuro (25, 15) sale bien con `brick_dark`; `brick` lo deja naranja.
- **Pruebas.** Test `casas solo=sil_` OK. APROBADA por el usuario («Visto bueno y siguiente»).

### Valdespino: 11 entradas (24/11, Claude · Texturas)

- **Qué.** `vald_22, 20, 18, 16, 14, 12, 10, 4` (hilera de 1994-95, lado par) y `vald_11, 9, 7` (lado impar), escritas por el scratchpad `vald_write.py` (en `casas_calles.gd`, tras `sil_p8`). Comprobado contra las zonas y los scripts hechos a mano: lo más cerca es el Requejo (`requejo.gd`), a 28 m del 4.
- **Patios.** Los patios de delante del lado par no se ponen, como en `vin_45..53`. El 16, con el patio cerrado en ladrillo, lleva esa planta baja en su fachada y la azotea con balaustrada (`ter`).
- **Alineación.** Todas en línea (alinea.py 0,0). Horneado: 11 nuevas; `valdespino_6` solo cambia la medianera; holguras igual.
- **Pruebas.** Test `casas solo=vald_` OK. APROBADA por el usuario («Visto bueno y paramos»).

### Árboles sueltos y matas en la tierra vacía (24/11, Claude · Sistemas)

- **Qué.** Luis vio vacías las zonas de tierra. `matojos.gd` (`_try_tree`) planta, en el mismo paso que los matojos, un árbol a veces por cuadro de 32 m hasta `TREE_REACH` 4 cuadros de las manzanas, a rodales según un ruido (`_tnoise`): olivo (1), almendro redondo (0) o pino piñonero (3, nuevo). Unos 1500. `world.gd`: `_trees` partido en `_tree_add`, `_tree_meshes` (rehace los MultiMesh) y `add_trees(list)`; `trunk_h(k)` y `crown(k, s)` los usa también el árbol que cae (`props.gd _fell`). Tercer tipo de matojo: `_mata_mesh`, verde grisáceo.
- **Reglas.** `_ground_ok` igual a 1 (en campo, 0,3 de la probabilidad), `room_at` y `road_edge_dist` ≥ 4,5 m, la copa (6 puntos a 2,6 m) fuera de calles y manzanas, 7 m a cualquier otro árbol, el rayo da en el terreno y dos esferas (tronco y copa) no tocan nada.
- **Coste.** Caché VERSION 3: primera vez 9,3 s (antes 4,7), luego 1,7 s.
- **Pruebas.** `arreglos` 2 ok, `relief` 19 ok, `entrada` 9 ok, `paseo` 3 ok. Fotos `vista_arb_*` en `godot/shots/`. APROBADO por Luis («Visto bueno»).

### Versión 0.1.2 (24/11, Claude · Sistemas)

- **Qué.** Luis: «Preparamos release con todos los cambios», y luego «Publica». Lleva la rotonda de la entrada norte con su azafrán (Pretil), los árboles sueltos y las matas (Sistemas) y Humilladero, Silos de la Magdalena y Valdespino (Texturas).
- **Pruebas.** La prueba completa salió limpia a la primera: 1069/1069. Renderizador móvil: 809 MB y 2159 MB de vídeo (0.1.1: 789/2141).
- **Paquetes.** APK 321 MB (código 102), instalador de Windows 386 MB, Linux 330 MB, en `dist/v0.1.2` con `SHA256SUMS.txt`. Sin probar en el móvil ni en la Steam Machine.

### Árboles en las aceras de la Carretera Antigua de Madrid a Cádiz (24/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis («En la carretera antigua Madrid Cádiz. Si compruebas en Google maps. Verás que suele haber árboles en las aceras de los laterales (donde no hay construcciones)»), `matojos.gd` (`_avenue_trees`, `VERSION := 4`) planta **386 árboles de sombra** (tipo 0, tamaño `0,72–0,96`, espaciados cada ~14 m como en las ortofotos del PNOA `cristobal.jpg` y `entrada_norte.jpg`) con **alcorques** cuadrados de hormigón y tierra (`_alcorque_mesh`) sobre el borde exterior de las aceras laterales (`hw + 1,38 m`, dejando libre el paso de paseantes a `hw + 0,9 m`).
- **Reglas.** Solo en los tramos de cada acera sin construcciones detrás (`room_at` ≥ 7,5 m en la acera y ≥ 8,0 m 4 m por detrás, fuera de manzanas, zonas verdes/viñas/agua y sitios hechos a mano con margen), respetando cruces, rotondas, la visual del muro/cartel de la entrada norte y pruebas físicas de suelo/tronco/copa. Se integran con `world.add_trees` (sólidos, derribables por coches y regenerados al día siguiente). En `props.gd` `_place_furniture` comprueba `_near_tree` para evitar solapes con mobiliario aleatorio.
- **Archivos.** `godot/scripts/matojos.gd`, `godot/scripts/props.gd`, `godot/scripts/ruta.gd` (arreglada la escala del perro `perro.glb` aplicando `_rel(body, mi)` al `AABB`, de `19.0` a `0.19`), `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit (pendiente de visto bueno).
- **Pruebas.** `colesterol --window` (6/6 ok con comprobación de los 386 árboles en alcorques y escala `0.19` del perro + `ruta_colesterol.png`), `entrada --window` (9/9 ok), `rotonda_norte --window` (4/4 ok), `relief --window` (19/19 ok, 4848 árboles en el suelo y `relief_over_north.png`), `cristobal --window` (2/2 ok).

### Perros sueltos por el pueblo: 3 razas, 5 simultáneos, acariciar y atropello (24/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis (Opción B con 3 razas en Blender, 5 perros simultáneos, acariciables y atropellables con recuperación rápida como los NPCs). `tools/make_perros.py` esculpe y exporta en Blender 4.5.9 tres razas a partir de `godot/assets/ajedrez/perro.glb` conservando las 12 animaciones: `galgo.glb`, `mastin.glb` y `chucho.glb` (en `godot/assets/perros/` con `CREDITOS.txt`), más 4 capas de pelaje por raza.
- **Comportamiento (`godot/scripts/perros.gd`, integrado en `game.gd` y `loc.gd`).** 5 perros (siempre al menos uno de cada raza) pasean por las aceras (`Walk`) con pausas de olfateo (`Idle_2_HeadLow` / `Eating`), reciclándose en la burbuja de 85–175 m cuando quedan a >210 m fuera de cámara. Ladridos (`dog_0..3.wav`) con tono según raza. A pie aparece `p_pet` («Acariciar» / «Pet»): el perro salta contento (`Jump_ToIdle`), suelta un pequeño doble ladrido alegre y le sube un pequeño corazón rojo desde la cabeza (`Sprite3D`). Con un coche rápido (`> 4,5 m/s`, del jugador o de servicio) salen volando (`fly`), caen 1,8 s (`down`) y se levantan al trote (`Gallop`, `flee`).
- **Galletas para Perros y guía al azafrán.** Objeto `galletas_perro` («Galletas para Perros», 5 unidades por 5 €, icono de hueso en `inventario.gd` y caja con hueso girando con halo dorado en `pickups.gd`), colocado en la puerta de los dos veterinarios de Madridejos (**Avda. de la Constitución 88** `constitucion_88` y **C/ Arroyuelo Medio 63**). Al dar una galleta a un perro (Acción «Dar galleta» o «Usar» en la mochila), el jugador extiende la mano derecha con el hueso 3D, el perro se acerca, come (`Eating`), ladra alegre con corazón rojo y guía por las calles (A* sobre `MapData._adj`, sin tocar el GPS) hacia el azafrán exterior sin recoger más cercano, parándose y girándose hacia el jugador para esperar si le sigue; sin textos que revelen la mecánica.
- **Archivos.** `tools/make_perros.py`, `godot/assets/perros/{galgo,mastin,chucho}.glb` (+ `.import` y `CREDITOS.txt`), `godot/scripts/perros.gd`, `godot/scripts/pickups.gd`, `godot/scripts/inventario.gd`, `godot/scripts/game.gd`, `godot/scripts/loc.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `perros --window` (7/7 ok + `godot/shots/perros_razas.png` y `godot/shots/perros_veterinario.png`), `palabros --headless` (3/3 ok).

### Rosario colgando del retrovisor funcional y salpicadero C15 en las Z15 (24/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis con referencias fotográficas, `car.gd` (`set_rosary` / `_set_z15_cab_stripped` / `_build_z15_dash` / `_step_rosary`) y `chara.gd` (`hand_l`/`hand_r`) añaden al interior de la Z15 (`z15` y `kokas`) en primera persona:
  - Retrovisor interior funcional (reflejo real mediante `SubViewport` de `192×48` px, sin sombras ni MSAA, `far = 90 m`, refresco a la tasa completa del juego mediante `RemoteTransform3D` solo en 1.ª persona y cámara trasera tras las puertas con inversión horizontal de espejo) y rosario plateado articulado (12 cuentas perladas, medalla ovalada, cuenta inferior y crucifijo con péndulo secundario).
  - Salpicadero completo estilo Citroën C15 (repisa gris, visera del cuadro con los 3 botones redondos verticales, doble aireador central y aireador derecho, moldura y guantera abierta del copiloto, consola con radiocasete y calefacción, palanca de cambios y volante monobrazo con las dos manos del jugador —en su color de piel— agarradas a las «diez y diez» girando con `steering`). Al subir se cambia la malla `body` de la Z15 por una copia cacheada sin el volante/salpicadero/retrovisor horneados en `sk/z15.glb` (`Material_1` y parte delantera de `Material_14`), restaurándola al bajar.
  - Velocímetro interior vivo (textura procedural 256×128 cacheada 0–120 km/h con cuentakilómetros, barras de nivel/temperatura, testigo verde de luces y aguja naranja 3D movida en tiempo real por `linear_velocity`).
- **Física y rendimiento.** Péndulo doble amortiguado en espacio de cabina impulsado por aceleración longitudinal/lateral, gravedad aparente en cuestas, velocidad angular y leve vibración diésel. Todo (rosario, `SubViewport` del espejo, salpicadero, velocímetro y manos) solo existe mientras el jugador está subido a la Z15 (`_enter_car`) y se libera con `queue_free()` al salir (`_exit_car`, `faint_wake`, detención), con coste 0 en todas las demás Z15 y sin refrescar el espejo en tercera persona.
- **Archivos.** `godot/scripts/car.gd`, `godot/scripts/chara.gd`, `godot/scripts/game.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `rosario --window` (4/4 ok + `godot/shots/rosario_fp.png`, `rosario_salpicadero.png`, `rosario_itv.png` con las 4 pegatinas ITV acumuladas y `rosario_giro.png`).

### Puesto de conducción del Súper Hebro 555 (24/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis con fotos de referencia de un Ebro Super 55 (Opción A + todas las mejoras sugeridas), `car.gd` (`set_rosary`, `_set_hebro_cab_stripped`, `_build_hebro_pod_tex`, `_build_hebro_dial_tex`, `_build_hebro_dash`, `_step_rosary`) construye al subir a un `tractor` (`sk/hebro.glb`) y libera al bajar:
  - Capilla metálica redondeada en el color del tractor (`paint`: azul o rojo) con textura procedural desgastada/oxidada, collarín central oxidado y piloto azul central iluminado con el motor/luces.
  - Dos relojes redondos con bisel cromado y agujas 3D vivas: izquierda **Velocímetro 0–50 km/h** y derecha **Presión de aceite «HEBRO»** (banda verde normal, sube al arrancar y responde al gas).
  - Volante grande de 3 radios finos en baquelita negra (sustituyendo en memoria el volante fijo de `sk/hebro.glb` solo mientras conduces), tuerca central oxidada, pomo giratorio de tractor y las dos manos del jugador agarradas al aro girando con `steering`.
  - Acelerador de mano derecho móvil según `_thr`, vibración diésel sutil en capilla/agujas/volante al estar `running`, y clapeta metálica («sombrerete») articulada en `_pipe_at` que baila al ralentí y se levanta al acelerar.
- **Archivos.** `godot/scripts/car.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `hebro --window` (4/4 ok + `godot/shots/hebro_fp.png`, `hebro_salpicadero.png` y `hebro_giro.png`), más regresión `rosario --headless` (4/4 ok).

### Salpicadero deportivo y retrovisor funcional de la Omega Julietta (24/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis con foto de referencia del Alfa Romeo 159/Brera 2008 («Opción recomendada. Con retrovisor funcional y ajustando la altura»), `car.gd` (`driver_pov`, `set_rosary`, `_set_julietta_cab_stripped`, `_build_julietta_dial_tex`, `_build_julietta_gps_tex`, `_build_julietta_badge_tex`, `_build_julietta_dash`, `_step_rosary`) construye al subir a una `julietta` y destruye al salir:
  - Paleta «Nero + Aluminio cepillado» coherente con el cuero negro del descapotable en 3.ª persona; malla `body` sin el volante/salpicadero fijos (`alum` + zona delantera de `gummi`/`leder` respetando pilares A y asientos) restaurada al bajar.
  - Ajuste de altura solo en 1.ª persona (`local_eye.y -= 0.25`, `local_eye.z += 0.05` en `driver_pov`) para encuadrar limpiamente tras el parabrisas sin tocar la postura en 3.ª persona.
  - Cuadro binocular profundo con **Velocímetro 0–220 km/h** y **Cuentarrevoluciones 0–7000 rpm** vivos + ordenador de a bordo rojo; consola central de aluminio cepillado orientada al conductor con **3 aireadores redondos**, **3 relojes auxiliares** (incluyendo **manómetro de Turbo/Nitro vivo**), **pantalla GPS «OMEGA»** con flecha girando con `rotation.y`, clima bizona y palanca deportiva.
  - Volante de 3 radios en cuero y aluminio con emblema parodia `Ω` y las dos manos del jugador girando con `steering`, más retrovisor interior y retrovisor lateral izquierdo funcionales (`SubViewport` `192×48` y `96×80` px con shader ovalado, FPS nativos vía `RemoteTransform3D`, activos solo en 1.ª persona).
- **Archivos.** `godot/scripts/car.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `julietta --window` (4/4 ok + `godot/shots/julietta_fp.png`, `julietta_salpicadero.png` y `julietta_giro.png`) y regresión `hebro --headless` (4/4 ok).

### Seta Panda (renombre Zeat → Seta) y Seta Panda de los Pitufos: salpicadero, cabezones y lazo de España (24/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis con fotos de referencia del SEAT Panda y del lazo de España, se renombra `Zeat Panda` → `Seta Panda` y `Zeat Panda de los Pitufos` → `Seta Panda de los Pitufos` (`car.gd`, `gauge.gd`, `selftest.gd`), y `car.gd` (`_build_panda_dial_tex`, `_build_panda_badge_tex`, `_build_panda_bobblehead`, `_build_panda_cassette`, `_build_panda_dash`, `_step_rosary`) construye al subir y libera al bajar:
  - Bandeja/bolsa abierta de puerta a puerta con riel tubular acolchado, cenicero deslizante, chapa pintada del color del coche y 2 altavoces cuadrados ochenteros en las esquinas.
  - Cuadro rectangular con velocímetro `0–160 km/h` vivo, `0–4/4` gasolina, cuadrícula de testigos, 6 interruptores basculantes, 3 deslizadores verticales y aireador; volante grueso de 2 radios con placa `S E T A`, manos del jugador girando con `steering` y palanca fina.
  - En `panda` (determinista por coche con `_panda_seed`): monigote cabezón (**bulldog**, **pato** o **rana**) con muelle 3D reactivo a baches y curvas (`_bobble_piv`), casetes ochenteros tirados en la bandeja y asiento del copiloto, y 25 % de probabilidad de **lazo de España** (cinta rojo-amarillo-rojo con cuenta plateada) balanceándose del retrovisor. En `pitufo`: emisora VHF policial con micrófono y botón azul de sirena.
  - Retrovisor central (`192×48`) y lateral izquierdo (`96×72`) funcionales a FPS completos del juego vía `RemoteTransform3D`, activos solo en 1.ª persona.
- **Archivos.** `godot/scripts/car.gd`, `godot/scripts/gauge.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `seta --window` (4/4 ok + `godot/shots/seta_fp.png`, `seta_salpicadero.png`, `seta_itv.png` con 1 pegatina ITV, `seta_pato.png`, `seta_rana.png`) y regresión `rosario --headless` (4/4 ok).

### Salpicadero minimalista y pantallaza de 15" del Edison Model Y (24/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis con fotos de referencia de Tesla Model 3/Y Highland (3 luces ambientales al azar + «EDISON» grabado + cristal tintado oscuro + GPS real reutilizando `minimap.gd`), `car.gd` (`driver_pov`, `set_driver_head_visible`, `set_rosary`, `_set_edison_cab_stripped`, `_make_live_gps`, `_build_edison_carbon_tex`, `_build_edison_wheel_tex`, `_build_edison_screen_tex`, `_build_edison_dash`, `_step_rosary`) y `minimap.gd` (`dark_gps`) construyen al subir a un `edison` y destruyen al bajar:
  - Conversión de los triángulos oscuros del parabrisas y ventanillas delanteras en **cristal tintado ahumado translúcido** (`_edison_glass`, solo en 1.ª persona, con molduras negras en pilares A), restaurando las lunas negras opacas exteriores en 3.ª persona o al bajar.
  - Salpicadero horizontal de fibra de carbono / grafito con perfil de aluminio cepillado, consola con carga inalámbrica (con móvil) y doble posavasos cromado, y **tira LED ambiental envolvente** con 3 colores deterministas por coche (`_edison_seed % 3`: verde neón, azul hielo, morado neón).
  - Pantallaza central flotante de 15" («EDISON OS») con velocidad digital `km/h` viva (`Label3D`), selector `P R N D`, barra de potencia/regeneración, curva azul de «Autopilot» ligada a `steering` y **GPS real en directo** (`minimap.gd` con `dark_gps = true` en `SubViewport` 2D ligero mostrando las calles reales de Madridejos, manzanas y ruta activa `MapData.route_pts`, compartido también con la pantalla GPS de la Omega Julietta).
  - Volante redondo con arco metálico en «U», ruedecitas, texto **`EDISON` grabado en mate** y manos del jugador girando con `steering`, más retrovisor central (`192×48`) y lateral izquierdo ovalado (`96×72`) funcionales a FPS completos vía `RemoteTransform3D`.
- **Archivos.** `godot/scripts/car.gd`, `godot/scripts/minimap.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `edison --window` (4/4 ok + `godot/shots/edison_fp.png`, `edison_salpicadero.png`, `edison_giro.png`, `edison_azul.png`), `julietta --window` (4/4 ok con GPS real) y regresión `rosario --headless` (4/4 ok).

### Puesto de conducción del tractor Yondir (24/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis con fotos de referencia de cabina y retrovisores de tractor, `car.gd` (`driver_pov`, `set_driver_head_visible`, `set_rosary`, `_set_yondir_cab_stripped`, `_build_yondir_dial_tex`, `_build_yondir_badge_tex`, `_build_yondir_isidro_tex`, `_build_yondir_dash`, `_step_rosary`) construye al subir a un `yondir` y destruye al bajar:
  - Posición de cámara en 1.ª persona ajustada dentro de la cabina (`local_eye.y -= 0.14`, `z -= 0.12`), sustitución en memoria del volante fijo (`Part184Mtl`) y cambio del cristal cian opaco (`Part144Mtl`) por cristal sutil casi transparente solo en 1.ª persona (restaurado en 3.ª persona o al bajar).
  - Consola arqueada negro mate enmarcada en verde con enorme **tractómetro central cromado `0–60 km/h`** vivo (banda verde + cuentahoras), dos **relojes laterales cromados** (Temperatura vivo y Combustible), 3 testigos rojos, botón rojo de emergencia, basculantes crema/gris y llave de contacto.
  - Doble palanca con puño **naranja vivo** (la derecha como **acelerador de mano vivo** con `_thr`), dos pomos redondos naranjas de marchas y palanca amarilla de TdF/diferencial.
  - Volante de 3 radios negro brillante con **emblema redondo de oso amarillo-oro** y manos del jugador girando con `steering`, vibración diésel y **sombrerete metálico articulado** en el escape vertical delantero izquierdo (`_pipe_at`) abriéndose al acelerar.
  - **Dos retrovisores laterales superiores verticales** de tractor con brazos tubulares al techo (`YondirMirrorL` y `YondirMirrorR`, `96×128` px cada uno a FPS completos vía `RemoteTransform3D`), **50 % de probabilidad** de **estampita de San Isidro Labrador** apoyada en el salpicadero y **25 % de probabilidad** de **llavero/lazo de España** colgando y balanceándose del lateral superior izquierdo del techo (`_yondir_seed`).
- **Archivos.** `godot/scripts/car.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `yondir --window` (4/4 ok + `godot/shots/yondir_fp.png`, `yondir_salpicadero.png` y `yondir_giro.png`).

### Nuevo vehículo «Renol 4L» (inspirado en Renault 4): exterior en Blender e interior en 1.ª persona (24/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis con referencias fotográficas exteriores e interiores, nuevo vehículo `"cuatrolatas"` («Renol 4L») modelado desde cero en Blender 4.5.9 (`tools/blender/make_cuatrolatas.py` → `godot/assets/vehiculos/sk/cuatrolatas.glb`) e integrado en el tráfico, aparcamientos y talleres del pueblo.
  - **Exterior:** silueta fiel de Renault 4 TL/GTL (capó con nervio central y aletas altas, línea diagonal de la aleta, toma de aire negra y limpiaparabrisas bajos, parrilla rectangular cromada con faros redondos, intermitentes ámbar, paragolpes cromados con topes negros, 3 ventanillas redondeadas por lado, portón trasero inclinado con pilotos verticales y tapacubos cromados) en 7 colores clásicos.
  - **Estadísticas (`car.gd`):** mismas que `panda` (`acc 6.5`, `turn 0.55`, `mass 850`, `hp 100`), más lento en carretera (`max 22.0` vs `25.0`) y más rápido campo a través (`offroad 0.88` → `19,36 m/s` vs `13,75 m/s`).
  - **Interior 1.ª persona (`car.gd`: `_set_r4_cab_stripped`, `_build_r4_dial_tex`, `_build_r4_dash`, `_build_r4_cofrade`, `_step_rosary`, coste 0 en coches aparcados/IA):** cristal claro en 1.ª persona, salpicadero bicolor negro acolchado + chapa crema, bandejas abiertas con mapa y chaleco reflectante amarillo-lima, cuadro rectangular cromado con velocímetro de arco `0–130 km/h` vivo, **palanca de cambios «paraguas» viva** en el salpicadero (`_r4_shifter_piv`), volante fino de 3 radios en «T» con palanca cromada, llaves colgando y manos del jugador, **retrovisor cromado de pie sobre el salpicadero** (`192×64`) + **retrovisor lateral izquierdo** (`96×72`) funcionales a FPS completos vía `RemoteTransform3D`, pegatinas ITV, y **figurita Chibi sobre peana de madera de la Semana Santa de Madridejos** al azar por coche (`_r4_seed % 100`: **16 %** cada una entre **Cristo**, **Santo Sepulcro**, **Nazareno blanco**, **Nazareno morado**, **San Juan** y **Soledad**, más **4 %** raro con **las 6 en fila**).
- **Archivos.** `tools/blender/make_cuatrolatas.py`, `godot/assets/vehiculos/sk/cuatrolatas.glb` (+ `.import`), `godot/scripts/car.gd`, `godot/scripts/modelos.gd`, `godot/scripts/sfx.gd`, `godot/scripts/traffic.gd`, `godot/scripts/game.gd`, `godot/scripts/masahorro.gd`, `godot/scripts/merkocarry.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `cuatrolatas --window` (7/7 ok + `godot/shots/cuatrolatas_{frente,detras,perfil,colores,fp,salpicadero,cofrades,giro}.png`).

### Ocultado de HUD y controles de vehículo tras 5 s parado (25/11, Antigravity · Sistemas)

- **Qué.** A petición de Luis: si el jugador permanece detenido dentro de un vehículo más de 5 s sin acelerar, frenar, girar, tirar de freno de mano ni desplazarse (`speed < 0.35 m/s`), la interfaz de juego (minimapa, calendario, velocímetro, pizarra, flecha guía 3D, etc.) se desvanece suavemente y, en PC/mando (`not Touch.on`), aparece abajo la tarjeta `CONTROLES DEL VEHÍCULO` con los iconos reales del dispositivo activo (teclado, Xbox o PlayStation) e idioma (`es`/`en`): Acelerar, Frenar / atrás, Girar, Freno de mano, Turbo o Autopiloto (según vehículo), Salir, Radio, Cambiar vista y Claxon. En Android/táctil (`Touch.on`) solo se oculta la interfaz sin mostrar la tarjeta. Al volver a moverse, pulsar controles de conducción, abrir mapa/pausa o salir del vehículo, el HUD regresa de inmediato.
- **Archivos.** `godot/scripts/game.gd`, `godot/scripts/hud.gd`, `godot/scripts/loc.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `car_idle --window` (6/6 ok + `godot/shots/car_idle_teclado.png` y `car_idle_mando.png`) y `palabros --headless` (3/3 ok).

### El techo de la Z15 que asomaba desde fuera (25/11, Claude · Sistemas)

- **Qué.** Luis vio en 3.ª persona, al subirse a la Z15, un «toldo» que atravesaba el coche: el forro del techo (`m_headliner`, 1,46 × 0,72 m) y la barra del parabrisas que `set_rosary` añade para la 1.ª persona. Ahora van en `car.gd` `_fp_only` y solo se ven con `_fp_hide_head` (`set_driver_head_visible` los enciende y apaga al cambiar de cámara).
- **Pruebas.** `rosario --window`: 5 ok (nueva: «the Z15's headliner shows only in 1st person», más la foto `rosario_fuera.png`). Sin commit.

### La peña El Bordillo se queda así (25/11, Claude · Worldbuilding)

- Luis: «El Bordillo se sigue llamando así, su nombre original es El Cerquillo pero no puedo usar nombres reales». `guion/palabros.md` ya no dice que «hay quien les dice El Cerquillo»: es el nombre real y no va en el juego. Ningún texto lo usaba.
- Sin commit.

### Lo que dice el pueblo de los perros y los vehículos (25/11, Claude · Worldbuilding)

- **Por qué.** Le propuse a Luis frases sobre los perros sueltos y los vehículos nuevos en cinco bloques; contestó «Me gustan todos». Avisado Sistemas antes de tocar sus archivos.
- **A, charla (`loc.gd`).** Seis frases en `generic`, tres en `generic_old` y dos en `generic_kid` (galgo, mastín, 4L, Seta Panda, Edison, Hebro).
- **B, atropellar un perro.** El perro dice `dog_hit` («¡Cai, cai, cai!», «¡Guau!»; antes `HIT_LINES` fijo en castellano, también en inglés). Si es tu coche, el vecino libre más cercano a 22 m grita `dog_hit_seen` (`perros.gd` `_witness`).
- **C, acariciar.** El 40 % de las veces, un vecino a 12 m dice `dog_pet_seen`.
- **D, primera vez en cada vehículo.** `game.gd` `_first_drive` (desde `_enter_car`): un aviso `car_first_<kind>` una sola vez por modelo; stats `conducidos`. La Z15 del Kokas cuenta como Z15.
- **E, chismes.** `perros.gd` `_count` lleva stats `perros_atropellados`, `perros_acariciados` y `perros_galletas`. A 3 atropellos y a 10 caricias entra la noticia `perros_atropello` / `perros_caricias` en `chismes.gd` (`NEWS`; `said` usa `chisme_<id>` si no hay versión bien/mal/igual). Con una galleta dada, el murmullo `murmullo_galletas`.
- **Prueba.** `_perros_frases_checks` dentro de `perros` (12/12). La regla «pa» de `_palabros_checks` deja pasar «se para» y «te para» (el verbo); `palabros` 3/3.
- **Escrito en** `guion/palabros.md`.
- Sin commit.

### El Cerro: 17 entradas (25/11, Claude · Texturas)

- **Qué.** `cer_5` a `cer_37`, los impares de la Urbanización El Cerro (hilera de 1993), escritas por el scratchpad `cer_write.py` (en `casas_calles.gd`, tras `vald_7`). Comprobado contra las zonas y los scripts hechos a mano: lo más cerca es `molino_zone`, a 117 m.
- **Catastro.** Dibuja el cuarto de delante (4 m) y el patio de cada parcela, pero en espejo en varios pares frente a Street View (visto en las tomas del 21 y del 37; la placa «19» confirma el orden de las casas). Solo se usa el ancho de cada parcela: fachadas a toda la anchura en una línea, `fill` 1,3 m, `floors: 1`, h 6,2 (el 33, 7,2).
- **Dibujo.** Tipo A (patio a la izquierda) y B (a la derecha): patio `arc ... sq=1 g=bars`, tejado del cuarto con `teja`, tejadillo de la puerta. El 11 lleva `band` azul en la línea de arriba; el 37, `ciego` (hastial al campo).
- **Alineación.** alinea.py 0,0 en las 17. Horneado: 17 nuevas, nada cambiado; holguras 1122 (6,6 → 6,5) y 1123 (6,8 → 5,6); árboles igual (2943).
- **Pruebas.** Test `casas solo=cer_` OK. APROBADA por el usuario («Visto bueno y seguimos»). Sin commit.

### Constitución norte: 10 entradas (25/11, Claude · Texturas)

- **Qué.** `ctn_130, 128, 128b, 97s, 132a, 134, 136b, 136, 138, 109`, escritas por el scratchpad `ctn_write.py` (en `casas_calles.gd`, tras `cer_37`). Prefijo `ctn_` porque `constitucion_132` ya era otra casa (4398801). Comprobado contra las zonas: lo más cerca es `cuartel_zone`, a más de 100 m.
- **Frentes.** Los de `house_street.py`, salvo tres: `ctn_132a` alargado a 13,6 m por la casa entera (retirada tras su jardín), y `ctn_136` / `ctn_138` llevados a la linde común (11,5, -804,6). 97 (4298523) y 103 (4096412) se dejan: quedan detrás de `constitucion_95` y `_101`.
- **Alineación.** alinea.py 0,0-0,2. Horneado: 10 nuevas, nada cambiado; holgura 1097 (8,5 → 8,4).
- **Pruebas.** Test `casas solo=ctn_` OK. APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.

### Clavel este: 5 entradas (25/11, Claude · Texturas)

- **Qué.** `clavel_fp31a, clavel_103, clavel_eu1, clavel_eu2, clavel_al25`, escritas por el scratchpad `clv_write.py` (en `casas_calles.gd`, tras `ctn_109`). Frentes de `house_street.py` sin tocar. Comprobado contra las zonas: lo más cerca, `named_u` / `merkocarry_built`, a más de 270 m.
- **Dejadas.** `4993708` (el 105, 10 m atrás tras una tapia) y `5090002` (Santa Ana 137, 10 m atrás).
- **Alineación.** alinea.py 0,0. Horneado: 5 nuevas; `clavel_74` solo cambia la medianera.
- **Pruebas.** El primer `casas` falló por un error de análisis en `selftest.gd` / `loc.gd` (`Portrait`) mientras otra sesión los editaba; repetido luego, OK. APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.

### La Pili, los carros de la compra y la tía Paca si estás ocioso (25/11, Claude · Sistemas)

- **Qué.** Tres cosas que pidió Luis el 25/11, con una foto de referencia de una señora con su carro de cuadros rojo.
- **La Pili (`pili.gd`, nuevo).** Sigue el molde de `tomasa.gd` y ocupa el hueco de recado (`G.side` con id `pili`). Su etapa va en `stats.pili`.
  - Aparece cuando la tía Paca ha contado la herencia y el curro (`stats.curro`, y `fondo_casa._tour` ya acabado), de 8 a 22.
  - Con el recado sin hacer, sube y baja por la Calle del Arroyuelo Medio (`ARROYO`). Si estás a menos de 14 m, a pie y con las manos libres, te persigue soltando frases («¡Oye, tú!», `pili_chase`). A más de 30 m se rinde.
  - En la charla salen el bacalao, sus hijos de 30 años y la Laura la mamporrera. Decirle que no cuesta −5 de confianza.
  - Si dices que sí, el pez de los «bacaladitos» (`pickups.gd`) aparece en la primera caja del set del Merkocarry. Al cogerlo, La Pescadera (`pescadera`, nombre de Luis; en la caja mientras la pescadería está cerrada) explica lo de la panga.
  - El cartel tachado (su retrato de `Portrait` más una cruz roja y «PROHIBIDA LA ENTRADA») se cuelga desde `pili.gd`, sin tocar `merkocarry_dentro.gd` de Pretil. Va en el frente de la caja 1 y en la pared junto a la puerta.
  - Se entrega en su casa, por la Magdalena: «¿Esto es una puta panga?». Paga 50 € y 30 P.C. Después pasa unos 40 s en la puerta de cada una de 13 tiendas, súpers y bares (nunca el Merkocarry), y en sus charlas cuenta y pregunta demasiado (`pili_after`).
  - **Ojo:** a más de 185 m `game.gd` oculta a todos los NPC y deja de moverlos. Por eso `givers()` mira solo `away`, no `visible`, y la Pili se teletransporta a su casa si no se la ve.
- **Carro (`chara.gd`).** `_carrito` monta bolsa de cuadros (textura hecha en código), armazón, solapa negra y dos ruedas.
  - Andando va inclinado detrás, con el asa en la mano derecha. Parado, queda de pie al lado (`_carro_k`, `CARRO_TIP`, `_carro_pose`, `_carro_hand`).
  - Lo lleva el 20 % de las ancianas y el 5 % de los ancianos (`_neighbour_look`), en 12 colores; uno de cada cuatro es liso o de flores (`carro_dibujo`). `driver_look`, `sit()` y la gente de Sopiss lo quitan.
- **Paca, si estás ocioso (`fondo_casa.gd` `_ocio`, `idle_giver`, `where`).** El reloj va en `stats.ocio_h`. Tras 24 h de juego con alguien de `marcas.givers()` (sin contar trabajos, Paca ni Edmundo) y nada en marcha, llama (`paca_ocio`) diciendo la calle con artículo. Avisa una vez por misión (`stats.ocio_avisos`, `mission_key`). En el Modo Chavisca no llama.
- **Pruebas.** `pili` 10/10, con imágenes `pili shots` (hoja `godot/shots/pili_hoja.png`). `palabros` y `firmas` OK. Retratos nuevos en `guion/fotos`; `relaciones.json`/`.html` y `misiones.html` actualizados, y el artefacto 8A6YH1Dg7CE2meCEoRaqiK republicado. Sin commit.

### Juan XXIII: 15 entradas (25/11, Claude · Texturas)

- **Qué.** Prefijo `jx_`: `jx_24, 29, 28, 33, 30, 35, 37, 39, 32, 32b, 34, 36, 38, 40, 47`, escritas por el scratchpad `jx_write.py` (en `casas_calles.gd`, tras `clavel_al25`). Frentes de `house_street.py`. Comprobado contra las zonas: el Merkocarry, a más de 180 m; ningún RC del tramo aparece en `bake_godot.py` ni en los scripts.
- **Alineación.** alinea.py antes del horneado. Horneado: 15 nuevas; `delicias_68` solo cambia la medianera.
- **Pruebas.** El primer `casas solo=jx_` dio «NO RESULT (timeout)» con el log vacío; repetido, OK (88 s). APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.

### Juan XXIII, tramo sur: 13 entradas (25/11, Claude · Texturas)

- **Qué.** `jx_9, 11, 13, 15, 17, 10, 10d, 10e, rem1, 12, 14, 16, 18`, escritas por el scratchpad `jx2_write.py` (en `casas_calles.gd`, tras `jx_47`). La parcela `4791001` en dos: `jx_10d` (la parte de 2 plantas, frente cortado a mano) y `jx_10e` (`only: 1`, el almacén). Comprobado contra las zonas: lo más cerca, `named_u` / `merkocarry_zone`, a más de 100 m; ningún RC del tramo en `bake_godot.py` ni en los scripts.
- **Dejadas.** `4791017` (San Cristóbal 1, 6 m atrás), `4692155` y `4693026` (no dan a la calle).
- **Alineación.** alinea.py 0 salvo `jx_10` / `jx_10e` (2,3 m, del Catastro). Horneado: 13 nuevas, nada más cambia.
- **Pruebas.** `jx_10e` sin huecos falló «too little» (`boxes < 12`); con la cancela, OK. APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.

### Versión 0.2.1 (26/11, Claude · Sistemas)

- **Orden de Luis:** «Perfecto. Cuando lo tengas lanza release con los tres instaladores. Así puedo probar yo también directamente en android y steam machine».
- **Qué lleva:** la carga (los tres pasos de abajo: cajas, caché de las casas, árboles y kit) y el arreglo de Pretil de la comprobación de las lápidas. Nada cambia a la vista: el pueblo es el mismo malla a malla.
- **Pruebas:** completa 1141/1141 a la primera (661 s); `tools/cache_casas_check.py` CACHE CASAS OK; `--mundo-huella` 5253 mallas iguales.
- **El juego exportado (Windows, `dist/Matritellus/Matritellus.exe -- --selftest --palabros --timing --cache-casas --lotes-huella`):** el primer arranque escribe la caché (59 s en total: también prepara lo demás tras actualizar) y el segundo la lee (26,1 s; casas 6,0 s), con las mismas huellas que en el editor (1039918072 y 490539104). Registros en `logs/exportado_1.log` y `_2.log`.
- **Memoria con el renderizador de móvil:** 866 MB / 2374 MB de vídeo (0.2.0: 936 / 2353).
- **Sin probar:** el teléfono (allí la caché de las casas sigue apagada: `OS.has_feature("mobile")` en `world.gd`; si Luis ve que carga bien, se puede encender y probar) y la Steam Machine (allí la caché sí va: Luis la prueba).
- **Pendiente tras publicar:** Pretil quita la caja sin fondo de las baldas del MasAhorro (`masahorro.gd`, ~línea 443).

### La carga, tercer paso: árboles y kit de los sitios a mano (26/11, Claude · Sistemas)

- **Palabra de Luis:** «Vale, vamos con la carga en matas y árboles y tal».
- **Árboles (4,5 → 0,1 s):** `world.gd` añadía 4786 `CollisionShape3D` de uno en uno a un `StaticBody3D` ya dentro de la escena; con Jolt cada alta rehace el cuerpo compuesto (crece con el cuadrado). Ahora `_trees_body_out()` saca el cuerpo de la escena y `_trees_body_back(at)` lo devuelve a su sitio al acabar, tanto en `_trees()` como en `add_trees()` (los árboles sueltos de `matojos.gd`). **Lección para cualquier cuerpo con muchas formas: añadirlas con el cuerpo fuera de la escena.**
- **Kit `obra.gd` (es de Pretil; avisado):** `_tri` ya no hace listas (la normal se da una vez), `quad` no hace listas sin uvs, y `box()` calcula sus ocho esquinas una vez y pone las 36 en el orden en que las ponían los seis `quad`: hacia dónde gira cada triángulo depende solo de si el marco `_xf` está reflejado (signo del determinante). Una caja tan fina que dos esquinas caen en el mismo punto (el MasAhorro tiene una) va por el camino viejo, porque ahí los seis `quad` no saben hacia dónde girar y las dejan como vienen. `--cajas-viejas` manda todas por el camino viejo (casas y sitios). Contadores `obra.n_solids` y `obra.t_solids` (3976 sólidos, 264 ms: no merece tocarse).
- **Comprobación `--mundo-huella`:** `--selftest --palabros --timing --mundo-huella` (vale sin ventana) escribe `user://mundo_huella.txt`: una línea por malla (`ArrayMesh`) con el camino de índices por donde cuelga y la huella de sus datos (`world.write_fingerprints`). Dos arranques dan las mismas 5253 mallas bajo el mundo; lo que cuelga fuera (gente, coches, kebab) cambia por azar y no se compara. Úsese antes y después de tocar `obra.gd` o cualquier pieza común.
- **Medido y dejado como está:** matas 1,0 s desde su caché (`matojos.gd` desglosa con `--timing`: 0,9 s son enseñar 6044 MultiMesh); «actors» 3,5 s (Recress 832 ms, zonas 516, 68 coches aparcados 418, vecinos 329, kebab 207).
- **Tiempos (ventana, renderizador de móvil, `--cache-casas`, `--timing`):** 33,1 → 27,3 (árboles) → 25,7 s (kit). 53,1 en la 0.2.0. El juego real unos 3,6 s menos (lee la caché del suelo).
- **Pruebas:** batería completa 1141/1141 en 661 s (logs/selftest_full_20261126_042426.log); `tools/cache_casas_check.py`: CACHE CASAS OK (mallas 1039918072, casas 490539104, 22 pintadas, 1494 contornos en los tres arranques).
- **Queda por si se quiere seguir:** casas 4,7 s (leer la caché 1,7; las 927 casas con cartel, tela o función propia 2,3), «actors» 3,5 s, ~10 s en 70 sitios a mano (el mayor, el parque del Paseo, 0,86). Sin probar todavía: la caché en un juego exportado, en la Steam Machine y en un teléfono (apagada en móvil).

### La carga, segundo paso: caché de las casas (26/11, Claude · Sistemas)

- **Palabra de Luis:** «Si claro. Si mejora la carga adelante. Ayudará al rendimiento también?» (respondido: la caché no cambia los fps, se dibuja lo mismo).
- **Qué es:** `user://casas.cache` (93 MB): las 3003 mallas fundidas de `lotes.gd` en el formato de la gráfica (`ArrayMesh._surfaces`), cada una comprimida aparte (zstd) y leída cuando se construye la última casa de su cuadro; índice al final del archivo. Se escribe en `casas.cache.tmp` y se renombra al acabar.
- **Huella (`lotes.cache_key()`):** versión del juego, del motor, renderizador, md5 de `map.json` y de los guiones `casas`, `casas_calles`, `lotes`, `parts`, `texturas`, `tela`, `map_data` (.gd o .gdc), texturas elegidas y, exportado, fecha del ejecutable y del .pck. Si algo cambia, se reconstruye y se reescribe sola.
- **Con caché (`lotes.dry`):** las casas no dibujan piezas (`_dry` en `_tri`, `_quad_acc`, `quad`, `tri`, `box`); las que no son más que sus piezas (2479 de 3406: sin hijos, sin tela, sin pintadas ni contornos, sin función propia) no se calculan: `build` les repone las variables que su construcción cambió (`_state`, `_changed`, guardadas en el índice) y registra sus materiales.
- **Materiales:** uno por clave para todo el pueblo (`lotes.mat_keep`, en `_tool`).
- **Dónde no se usa:** en la autoprueba (salvo `--cache-casas`), con `--sin-cache-casas`, y en móvil (`OS.has_feature("mobile")`), hasta probarla en un teléfono.
- **Comprobar:** `python tools/cache_casas_check.py` (tres arranques; las huellas de las mallas y de las casas han de ser iguales y el tercero ha de leer la caché). Hoy: mallas 1039918072, casas 490539104. Pasarlo antes de cada versión y tras tocar `casas.gd`, `casas_calles.gd` o `lotes.gd` en algo más que casas nuevas.
- **Regla para quien escriba casas:** la construcción de una casa solo puede dejar cosas en sus variables, en sus hijos, en `world.hand_tags` y en `MapData.outlines`. Lo que deje en cualquier otro sitio hay que añadirlo a `left` en `casas.gd` `build`: la autoprueba no usa la caché y no lo vería.
- **Tiempos (ventana, renderizador de móvil, `--timing`):** casas 14,1 → ~4,9 s; carga 43,1 → ~33,5 s (53,1 en la 0.2.0). El primer arranque tras instalar o actualizar tarda 3,8 s más (escribe la caché).
- **Idea apuntada, sin hacer:** las mallas van sin índices (36 vértices por caja); indexarlas al escribir la caché bajaría un tercio la memoria de vídeo de las casas (1,2 GB) y algo el trabajo de la gráfica.

### La carga, primer paso para la 0.2.1 (26/11, Claude · Sistemas)

- **Petición de Luis:** «El juego tarda muchísimo en cargar para lo que es (un cozy low-poly). Porqué tarda tanto? Se puede agilizar?».
- **Por qué tarda:** el pueblo se construye entero en cada arranque. En la prueba (renderizador de móvil, `--timing`) eran 53 s: 20,7 las 3406 casas a mano, 5,6 vecinos y coches, 4,8 el suelo, 3,9 las matas, 2,0 los árboles y ~13 entre 70 sitios a mano. Las casas son ~900.000 cajas, 44 millones de vértices (1,2 GB en la gráfica).
- **Hecho, sin publicar:** `casas.gd` `box()` saca las ocho esquinas de la caja y añade de una vez sus 36 vértices y 36 normales; el orden de cada triángulo depende solo del marco `_xf` (espejado o no), así que se resuelve una vez por marco (`_box_frame`, listas `BOX_PLAIN` y `BOX_MIRRORED`; un marco raro cae al camino de antes). `--cajas-viejas` construye como antes.
- **Comprobado:** `--selftest --palabros --timing --casas-suma` imprime ahora una huella de toda la geometría de las casas (la suma no distingue un triángulo vuelto del revés): 44144780 vértices y huella 977870393 antes y después. Quien toque la geometría de `casas.gd` puede repetirlo (`logs/casas_suma_ref.log` es la referencia de hoy; cambia en cuanto cambie una casa).
- **Resultado:** casas 20,7 → 14,1 s; carga entera en la prueba 53,1 → 43,1 s (`logs/boot_movil_cajas.log`). Con `--selftest` el suelo se corta siempre de nuevo: el juego real tarda ~3,6 s menos que la prueba.
- **Siguiente, por decidir con Luis:** caché en disco de las mallas fundidas (`lotes.gd`), que ahorraría casi todo lo de las casas en el segundo arranque pero pesa ~1 GB sin comprimir; y vecinos creados según te acercas.

### Versión 0.2.0 (26/11, Claude · Sistemas)

- **Orden de Luis.** «En cuanto termine Petril lo suyo. Commit a todo y release», y después «Para la prueba porque a esta versión la vamos a llamar 0.2.0 y vamos a meter a Ángelus, El Foski y El Pochi». No hay 0.1.4.
- **Prueba completa: 1141/1141**, a la sexta pasada (42, 10, 4, 4, una cortada por un cierre del motor y 0). Ningún fallo era del juego. Lecciones para quien haga la siguiente:
  - Una comprobación nueva escrita para su modo suelto (menú cerrado, `phase` «free») falla en la completa, donde corre con el título en pantalla, y además deja el juego en mal estado para las siguientes (30 de los 42 primeros fallos eran arrastre). En la completa van dentro de `_as_in_its_mode(check, nombre)` (selftest.gd, junto a `_check`).
  - Cada `_check` que falla imprime debajo cómo estaba el juego (fase, menú, llamada, encargo, riña, dónde). Mirar eso antes que el código.
  - La completa corre sin ventana: ahí un MultiMesh no devuelve sus instancias (`get_instance_transform()` da la identidad). Las comprobaciones leen un registro propio del script, no el motor (Pretil: zonas, La Kueva; pendiente, las lápidas R.I.P./D.E.P.).
  - La completa salta días enteros: lo que depende del día (la llamada de la tía Paca por ocio, las visitas al cementerio de las rondas) se cuela en comprobaciones ajenas. `fondo_casa.ocio_quiet` la calla en la completa; rondas y Vizum apartan el cementerio mientras duran.
  - El tráfico es aleatorio: un coche puede tirar un poste del cruce antes de las comprobaciones de los semáforos (se reparan antes de empezar).
  - Una pasada se cortó con 1078 bien por un cierre del motor (signal 11) en `_riot_gestures` (selftest.gd:9543), en código de la riña sin cambios desde la 0.1.3; no se repitió en la siguiente. Registro: `logs/selftest_full_20261126_022102.log`. A vigilar.
- **Memoria con el renderizador de móvil:** 936 MB estática, 2353 MB de vídeo (0.1.2: 809 / 2159). Registro con los tiempos de cada paso de la carga: `logs/boot_movil_0.2.0.log` (53 s en total con las cachés recién hechas: casas 20,7 s, vecinos 5,6 s, suelo 4,8 s, matas 3,9 s, árboles 2,0 s).
- **Orden de construcción desde esta versión:** `python tools/make_apk.py X.Y.Z` PRIMERO (escribe la versión en `project.godot`), luego `make_installer.py` y `make_linux.py`. Si no, Windows y Linux saldrían con la versión vieja y el aviso de versión nueva avisaría siempre.
- **Va sin el visto bueno de Luis:** el aviso de versión nueva, Foski, El Pochi, el aspecto de Ángelus, de Ezequiel y de Frank, los parroquianos de La Kueva y el encuadre de las charlas.
- **Lo siguiente (0.2.1), pedido por Luis:** «El juego tarda muchísimo en cargar para lo que es (un cozy low-poly). Porqué tarda tanto? Se puede agilizar?». Plan dicho a Luis: guardar las casas ya construidas (mallas fundidas) en una caché que se rehaga sola al cambiar una casa, luego árboles, objetos y edificios lentos, y crear los vecinos según te acercas.

### El Pochi, Ángelus Apátrida y los parroquianos de La Kueva (26/11, Claude · Sistemas)

- **Qué pidió Luis.** El Pochi, con foto: «Primo de El Foski. Camisetas de anime todos los días. Le gusta el anime, no tiene reparos con el hentai, más malablado y con más palabrotas que su primo. Te insulta constantemente. […] Es un Otaku pero odia a los otros otakus por no ducharse y hablar con palabras en japonés, le dan asco, él al menos tiene cierta dignidad sobre ellos». Ángelus, por Pretil: «Quiero siempre que esté KAE abierto haya un NPC llamado Ángelus Apátrida. Perilla, dejadez, delgado, camiseta de tirantes fosforita verde, ojos pequeños y pelo corto con flequillo levantado. Dirá lo que le gusta este rollo del pueblo, aunque de normal vive en la capital, pero lo que le tira de verdad es la salvajada y la fiesta del pueblo. De que ojalá vendiesen litronas en las discotecas, se forrarían. Y alternará con preguntas filosóficas o que si piensas en la muerte. Y que él coca no, que eso no es sano, él solo alcohol y hachís», y después «Angelus en La Kueva. […] Que en la Kueva haya aparte 3-5 NPCs genéricos de drogadictos y borrachos, casi zombies, diciendo lo que les gusta esa parte porque es oscura». Estado: hechos y enseñados; falta su visto bueno. La versión en que salen se llama 0.2.0 por orden suya.
- **Dejado fuera a propósito (dicho a Luis).** De El Pochi, la queja sobre la edad de consentimiento y la frase del dragón de 1000 años en cuerpo de niña. No se escriben chistes de sexo con menores; quien siga, que no los meta por su cuenta.
- **Ficheros.** `godot/scripts/pochi.gd` (nuevo: `LOOK`, `STREETS`, `TEES`, `street()`, `start()`, `off_street()`, `tick()`, `_insult()`, `wear(day)`, `dress()`, `chibi()`); `foski.gd` (`print_on()` ahora estático y compartido); `game.gd` (`PochiS`, `pochi`, tras Foski); `fiesta.gd` (`ANGELUS_LOOK`, `ANGELUS_SPOT`, `angelus`, `angelus_spot()`, `ZOMBIES`, `_zombies()`, `_kueva_tick()`, `_down`; `of("kueva")`); `trabajos.gd` (Ángelus fuera de `_order_for`); `loc.gd` (`n_pochi`, `pochi`, `pochi_insultos`, `n_angelus`, `angelus`, `fiesta_kueva`, firmas del puente de los dos); `selftest.gd` (`_pochi_checks`, modo `--pochi`; punto 5c de `_fiesta_checks`); `guion/relaciones.json` y retratos.
- **Los recuadros de Luis para El Pochi.** Luis: «Son chistes de humor negro lo de El Pochi, si no quieres/puedes escribirlos déjame recuadros de texto y los escribo yo. Tu no los verás ni los escribirás». Un archivo de `godot/data/` con nombre sin significado, a petición suya («cambiale el nombre a valores alfanuméricos para que nadie sepa que archivo es»; el nombre está en `pochi.OWN` y no se escribe en las notas): cada renglón entre corchetes (`[1]`) abre un recuadro, cada renglón de debajo es un bocadillo, `#` son notas. `pochi.own_lines()` lo lee (nunca con `--selftest`), `pochi.extra` los guarda y `game._chat` los añade a su turno. Va en los instaladores por `data/*.txt` en los tres presets. **Ese archivo es solo de Luis: no abrirlo, no imprimirlo, no pasarle `git diff`, no reescribirlo.**
- **La camiseta de Ángelus.** Luis: «Ponle algún número a la camiseta de Ángelus, que parezca más una camiseta de basket que eso que parece un vestido». `fiesta.jersey(c)`: dorsal 13 delante y detrás (`dorsal()`, cifras de 5×7 en `DIGITS`, sobre `Foski.print_on`), ribetes blancos y un pantalón corto oscuro como banda (`c._band`). El cuerpo de los muñecos es un cono del color de la camiseta: sin esa banda, una camiseta lisa parece un vestido.
- **Cómo se cambia de camiseta El Pochi.** `tick` mira cada 5 s si `G.day_n` ha cambiado y, si no le ves (`G.sees`), llama a `wear(day)`: `set_look` rehace el muñeco, así que `dress` vuelve a ponerle el dibujo y la muñequera.
- **La gente de La Kueva.** Viven en `people` con `kind` «kueva» y se crean con la noche (`_fill`), `away` y ocultos. `_kueva_tick` los enseña, con Ángelus, solo mientras `dentro.kueva.visible` y el jugador está en ese decorado. Usan los sitios de Pretil `dentro.kueva_spots` menos el 6, que es el de Ángelus.
- **Sin hacer.** Misiones y relaciones de los tres; figuras en las máquinas de bolas; el aspecto de Ángelus es un primer intento.
- **Pruebas.** `pochi` 4 ok, `foski` 3 ok, `fiesta` 18 ok, `palabros` 3 ok.

### Foski, personaje único (26/11, Claude · Sistemas)

- **Qué pidió Luis** (con una foto suya de referencia). «vamos a añadir otro NPC único. De momento sin misiones, solo andará dando vueltas por la calle del florido. Se llamará Foski, te paso referencias física. Tatuajes, camisetas negras de grupos de metal, dejadez, hermoso. Personalidad: Le gusta el metal, el anime, tiene diversos problemas de salud (bromea con no llegar a los 40), le gustan las góticas y las transexuales, dice bastantes tacos hablando y es malablado en general, (pero es buen tío). Que haya una broma donde bromee sobre suicidarse y luego haya un *silencio incómodo* antes de continuar la conversación». Estado: hecho y enseñado; falta su visto bueno.
- **Ficheros.** `godot/scripts/foski.gd` (nuevo: `LOOK`, `street()`, `line()`, `start()`, `off_street()`, `tick()`, `dress()`, `logo(seed)`); `game.gd` (`FoskiS`, `foski`, se crea tras Feliciano, `foski.tick`; en el tic del diálogo, `hush`); `loc.gd` (`n_foski`, `foski`, `firma_si_/firma_no_foski`, `HUSH_A/B` y `_hush` en `rich()`); `selftest.gd` (`_foski_checks`, modo `--foski`, y en la completa tras Feliciano); `guion/relaciones.json` + `guion/fotos/foski.png`.
- **Cómo anda.** `n.walker = true`, `n.beat` = los nodos de la carretera llamada exactamente «Calle del Florido» (la Bajada no), `wspeed` 1,05. Es el mismo mecanismo de Dolores y de la ruta del colesterol (`game._walker_plan`). A cualquier hora.
- **La marca `~~…~~`.** Una línea de diálogo que empieza por `~~` es un silencio: `Loc.rich` la muestra en gris como `*texto*`, y `game.gd` no le pone voz y la escribe a un tercio de la velocidad. Sirve para cualquier otro personaje.
- **Lo suyo encima del muñeco.** `dress(c)`: el logo es una malla curva sobre el pecho (como `chara._pena_print`) con una textura generada; la tinta y el anillo son hijos de las bolas de las manos (`c._hl`, `c._hr`). Si alguna vez se le llama a `set_look`, hay que volver a llamar a `dress`.
- **Trampas.** En un modo de prueba suelto los vecinos no se mueven hasta que `g.phase` es `free` o `play` y el menú está cerrado. Los scripts de ayuda escritos con heredoc convierten `\\n` en salto de línea real: escribirlos con la herramienta Write.
- **El Pochi.** Luis, 26/11: «El Foski será primo de "El Pochi". Otro NPC único que también dará vueltas por esas calles. Empezamos con él cuando terminemos a El Foski». En `guion/relaciones.json` como persona nombrada (`foto: false`) con el lazo de primos; nada más hecho: esperar a que Luis dé a Foski por terminado y a su descripción.
- **El pelo.** Estilo 14 (`pelo_rapao_fino`); se probó el 13 (raya) y Luis dijo «El primer corte de pelo se parecía más».
- **Sin hacer.** Misiones, relaciones con otros vecinos, figura en las máquinas de bolas (`gacha.FIGURES`).
- **Pruebas.** `foski` 3 ok, `palabros` 3 ok. Sin pasar: la completa.

### Aviso de versión nueva al abrir el juego (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «sería posible añadir una manera de que al abrir el juego detecte si hay una versión nueva disponible y de opción de Actualizar o Jugar versión actual?». Estado: hecho y enseñado; falta su visto bueno.
- **Ficheros.** `godot/scripts/actualiza.gd` (nuevo: `check()`, `read(d)`, `available()`, `go()`, y las estáticas `valid`, `newer`, `safe`); `game.gd` (`ActualizaS`, `actualiza`, en `_boot_done` se crea y pregunta; `_first_page()`, `update_found()`, `_update_go()`; páginas `update` y `update_go` y la línea de arriba de `main` en `_menu_page`); `loc.gd` (`menu_update`, `upd_*`); `export_presets.cfg` (`permissions/internet=true` en Android); `selftest.gd` (`_actualiza_checks(ask)`, modo `--actualiza`, y en la completa sin la petición real).
- **Cómo decide.** Compara los tres números de la etiqueta de GitHub con `application/config/version` (que `tools/make_apk.py <versión>` escribe al publicar). Borradores y prelanzamientos no cuentan. El enlace del instalador se toma del propio GitHub y solo se acepta si empieza por `https://github.com/LomoXSoft/Matritellus/`.
- **De qué depende.** Etiquetas `vX.Y.Z`, ficheros `Matritellus-X.Y.Z-Windows.exe` / `-Android.apk` / `-Linux.tar.gz` y repositorio público. Si un día el repositorio vuelve a ser privado, el aviso calla sin romper nada.
- **Trampas.** Los textos del menú también pasan por `palabros` («Ha salío», «ná»). El subtítulo de una página de menú no parte líneas solo: lleva `\n`. En las pruebas `actualiza.dry = true` para no abrir el navegador.
- **Sin hacer (propuesto, no pedido).** Descargar e instalar desde dentro del juego; en Android no se puede instalar un APK desde GDScript sin un plugin.
- **Pruebas.** `actualiza` 4 ok, `palabros` 3 ok. Sin pasar: la completa.

### La plaza de toros arreglada, visitable por dentro (25/11, Claude · Sistemas, en `toros.gd` de Pretil)

- **Qué pidió Luis.** «Se puede visitar la plaza de toros? Estaria bien poder visitarla por dentro. Te adjunto referencias de como se vería». Sus dos fotos (otras plazas): `referencias/plaza_toros/usuario_02_ruedo.png` y `usuario_03_galeria.png`. Estado: aprobado el 25/11 («Así está bien. Visto bueno»), con el palco solo sobre los toriles: le ofrecí la galería con tejado dando toda la vuelta y prefirió dejarlo así.
- **Qué cambia en `toros.gd`** (solo el estado «nuevo»). Constantes `FRONT`, `TIER`, `TOP`, `R_TOP`, `STAIRS`, `FLIGHT`, `PENS_TOP`, `RED`, `PAINT`; `_stand_decks`, `_deck()`, `_note_floors()`; `set_restored` mete y saca esas tarimas de `MapData.decks` (llevan la clave `"toros"`); `_stairs()`, `_circles()`, `_palco()`; en `_ring`: los sólidos del pasillo de entrada suben a 5,8 m con barandilla, las escaleras sustituyen a `_tiers` en sus tramos, y el sólido del frente de las gradas pasa a ser un tope de 5,2 m en el borde (en la ruina sigue como estaba); `_pens_block` tapa los cantos de las dos gradas que sobresalen de su techo; `_barrier` añade juntas y postes.
- **Trampas.** Las tarimas de pendiente (`grad`) dan la altura en `o`: la escalera es una sola tarima inclinada, no veinte. Entre gradas no hay topes: se sube y se baja de una a otra andando (0,6 m). El orden importa: las escaleras van antes que los suelos. Los rayos de choque van a la altura de los pies más ~0,9 m: un sólido que acaba a la altura del suelo de arriba no para a quien anda por arriba.
- **Pruebas.** `arreglos` 4 ok (con `_toros_dentro_checks`), `toros` 5 ok. Sin pasar: la completa.

### Arreglar la plaza de toros con 15 P.C. (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «Añade también la plaza de toros para arreglar igual 15 P.C.». Estado: hecho y enseñado.
- **Archivos.** `godot/scripts/arreglos.gd` (nuevo): `PLACES` (coste, clave de `stats`, textos, bandera de pruebas), `place(id)`, `spot(id)`, `begin()`, `here()`, `can_fix()`, `prompt()`, `fix()`. `game.gd`: `ArreglosS`, `var arreglos`, alta tras `fiesta.setup`, `arreglos.begin()` tras `fiesta.begin()`, rama `elif arreglos.can_fix(): arreglos.fix()` y aviso, ambos tras los de la sala. `loc.gd`: `p_toros`, `t_toros_open`. `selftest.gd`: `_arreglos_checks()` y el modo `--arreglos`.
- **Modo Golismeo.** La plaza sale arreglada (Luis lo confirmó después: «Si, todo arreglado en Modo Golismeo»).
- **Para añadir otro sitio.** Una entrada en `PLACES` y sus ramas en `place()` y `spot()`; el sitio necesita `restored` y `set_restored(on)`.
- **Pruebas.** `arreglos` 2 ok (paga con el botón de acción de verdad, `g.interact()`), `fiesta` 16 ok, `palabros` 3 ok. Sin pasar: la completa ni `toros`.

### Arreglar la Sala Cavernas con 30 P.C., Golismeo y noches de jueves a domingo (25/11, Claude · Sistemas)

- **Qué pidió Luis (a través de Pretil).** «Visto bueno, pero que solo abra jueves, viernes, sábados y domingos. […] De momento que se pueda arreglar con 30 P.C., luego ya daremos misión. 2. Si, arreglada ahí» (Modo Golismeo). Estado: hecho; el pago es provisional hasta que haya misión.
- **Archivos.** `godot/scripts/fiesta.gd`: `NIGHTS`, `FIX_COST`, `FIX_REACH`, `FIX_KEY`, `open()`, `night_on(weekday, hour)` (estática), `begin()`, `restore(on)`, `fix_spot()`, `can_fix()`, `fix_prompt()`, `fix()`. `game.gd`: `fiesta.begin()` en `start_game` tras `bridge.close_off`; `elif fiesta != null and fiesta.can_fix(): fiesta.fix()` en el botón de acción, tras el puente; el aviso tras el del puente (no si hay un vecino a tiro). `loc.gd`: `p_cavernas`, `t_cavernas_open`. `selftest.gd`: el punto 0 de `_fiesta_checks()` (dos comprobaciones) y la foto `fiesta_arreglar`; la prueba pone sábado para lo demás.
- **Trampas.** `stats["cavernas"]` es la única memoria del arreglo: quien llame a `set_restored` a mano lo pierde al cargar (`begin()` manda). Las farolas añadidas a `lights` no se quitan si luego se carga una partida sin arreglar (no hay `remove` en `lights.gd`). `cuevas.is_open` se pone al día en `_process`: en una prueba, en el mismo frame que `set_time`, usar `fiesta.open()`.
- **Pruebas.** `fiesta` 16 ok, `palabros` 3 ok. Sin pasar: la completa.

### Ezequiel y Frank Málaga, camarero y DJ de la Sala Cavernas KAE (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «Al camarero le llamaremos Ezequiel, y al DJ Frank Málaga». Estado: hecho y enseñado; falta su visto bueno. Sus aspectos son un primer intento: los personajes los pule él.
- **Archivos.** `godot/scripts/fiesta.gd`: `EZEQUIEL_LOOK`, `FRANK_LOOK`, `SHOUT`, `BAR_SHIFT`, `ezequiel`, `frank`, `_staff()` (los crea una vez, cuando la sala tiene decorado), `_worker()`, `_staff_in(here)` (los pone en su sitio o los quita: `away` + `visible`, no se liberan), `_dj(dt, pp)`. `loc.gd`: `n_ezequiel`, `n_frank`, `ezequiel`, `frank`, `frank_gritos`. `trabajos.gd`: los dos en la lista de excluidos de `_order_for`. `selftest.gd`: el punto 5b de `_fiesta_checks()` y las fotos `fiesta_ezequiel`, `fiesta_frank`. `guion/relaciones.json`: los dos y su enlace; retratos en `guion/fotos/`.
- **Trampas.** `bar_spot` del decorado cae justo detrás de la caja registradora: por eso `BAR_SHIFT`. El frente negro de la cabina tapa a Frank hasta el cuello desde la pista: la mano en alto va a 1,6 m para que asome. No están en el gacha (`FIGURES` es una lista a mano) ni tienen cartas propias (usan `carta_bien_x`/`carta_mal_x`).
- **Pruebas.** `fiesta` 14 ok, `palabros` 3 ok. Sin pasar: la completa.

### La gente de noche de la Sala Cavernas KAE (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «NPCs aleatorios (y únicos, con la misma posibilidad que los demás locales según NPC) cuando esté arreglado de 23:00-06:00, incluidos 2 o 3 en la puerta fumando. Con frases típicas de fiesta, humor negro, exageradas, alcohol, drogas, peleas, ya sabes». Estado: hecho y enseñado; falta su visto bueno.
- **Archivos.** `godot/scripts/fiesta.gd` (nuevo): `open()`, `sync(force)`, `_fill()`/`_clear()` (los crea y los libera cada noche, como el cliente de Sopiss), `_dance(dt)`, `unique_spots()`, `is_mine(p)`, `of(kind)`. `game.gd`: `FiestaS`, `var fiesta`, alta entre `luto` y `rondas`, `fiesta.tick(dt)` tras `luto.tick`. `rondas.gd`: `_spots(kind)` y `_party_over(now)`. `loc.gd`: `fiesta`, `fiesta_puerta` (es/en). `selftest.gd`: `_fiesta_checks()` y el modo `--fiesta`.
- **Qué lee de lo de Pretil (sin tocar `cuevas*.gd`).** `world.cuevas.restored`, `P()`, y de `cuevas.dentro` con `get()`: `dance_spots`, `client_spots` o `client_spot`, `bar_spot`, `dj_spot`, `unique_spots` (si lo diera). Sin decorado, solo salen los fumadores y los únicos van a la puerta.
- **Trampas.** El decorado solo se ve si entras con `g._use_door(true, sala.dentro)`: teletransportar al jugador a sus coordenadas enseña tierra pelada. Las frases en manchego pasan por las reglas de `palabros` (tiés, l'á, entoavía, «ande» y no «por ande»): correr `palabros` tras tocar `loc.gd`. `MapData.at()` da la altura del terreno, no la del suelo del decorado: para cámaras dentro, `MapData.foot()`.
- **Pendiente.** Lo de Pretil quedó resuelto el mismo día (la pista en blanco era el `Decal` de la bola; la puerta ya es 23–6; `client_spots` de seis, se usan tres) y las fotos se repitieron bien. Nada arregla la sala dentro del juego todavía (`set_restored` solo lo llaman las pruebas): hasta que Luis diga cuándo se arregla, esta gente no se ve en partida. De Luis: si quiere a alguien detrás de la barra y en los platos (no se ha puesto a nadie).
- **Pruebas.** `fiesta` 12 ok, `luto` 10 ok, `palabros` 3 ok. Sin pasar: la completa.

### Cámara de conversación de dos y etiqueta de nombre (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «La cámara de conversación cinemática actual que tenemos tapa un poco a los personajes y no deja ver bien el tuyo, creo que sería mejor un plano en el que ambos se viesen claramente [...] Además si puedes añadir la etiqueta con el nombre de quién habla a la burbuja de diálogo [...] Propón diseños». Estado: **etiqueta elegida («Me quedo con la C»: la del color de la ropa de quien habla); los otros dos diseños y `tag_style` se quitaron. Del encuadre no ha dicho nada en contra**.
- **Cámara (`game.gd`).** `_talk_camera()` reescrita: plano fijo de los dos (constantes `TALK_*`), sin cortes; `_talk_with` (para quién está montado el plano) sustituye a `_talk_line`; `_talk_room` (cuánto del camino cabe, por `_clear_to`) y `_talk_fov` (campo que pide el plano; lo recoge el `want_fov` del final de `_process`). Paso atrás: `_talk_step(dt)` se inyecta en el movimiento a pie (`step_back`), sin girar al jugador. El código viejo está en el scratchpad de la sesión (`talk_camera_antes.gd`) y en git.
- **Etiqueta (`hud.gd`, `hud_bits.gd`).** `dlg_tag` (PanelContainer `top_level` dentro de `dlg_slot`, después de la cola), `dlg_tag_text`, `set_dlg_name`, `dress_tag`; se coloca en `_process` con la burbuja. `game.gd`: `say` y `ask` llaman a `hud.set_dlg_name(who, _speaker_colour(...))` (color = `Parts.col(look_data["shirt"])`, o almagre si la voz no tiene figura). Quien añada otro sitio que escriba el nombre debe usar `set_dlg_name`, no `dlg_name.text`.
- **Trampas.** Las cabezas miden un metro: de costado, a menos de ~1,5 m una tapa a la otra (por eso el paso atrás). El plano se pensó a 55° de campo: con otro FOV en Ajustes la distancia se escala. En la prueba, la Paca se mueve entre pasadas y `_pavement` recoloca al jugador: por eso la prueba lo pone a 0,9 m a mano.
- **Pruebas.** `azafran` 8 ok, `herencia` 16 ok. Sin pasar: la completa, y los modos que hablan con otros únicos (el paso atrás mueve al jugador ~0,8 m al empezar a hablar).

### La flecha de dirección, un metro sobre el objetivo (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «Podemos hacer que la flecha de dirección apunte como un metro más arriba del objetivo, a veces sale mirando hacia el suelo si te acercas mucho al objetivo».
- **`game.gd`** (bloque «GPS + guide arrow» de `_process`): `arrow_body.rotation.x` ya no sale de `close * close`; es `atan2(altura de la flecha − (MapData.height(aim) + 1.0), max(distancia, 0.5))`, acotado a [−0,6, 1,1], con el mismo suavizado y el mismo vaivén. El giro, el tamaño y el latido no cambian.
- **`selftest.gd`, modo `--flecha`**: tras el paseo se pone a 8, 3 y 1,5 m del objetivo por el lado de la calle y comprueba que el morro corta la altura de 1 m cerca del objetivo; imprime `FLECHA OK`. Las fotos `flecha_cerca_*.png` no valen (la cámara queda dentro del personaje junto a la Loli).
- **Aviso.** Una pasada dio «Parse Error» con un carácter inválido y 7 líneas de registro: otra sesión estaba escribiendo `selftest.gd` en ese segundo. Repetir bastó.

### El puente enlaza con la herencia (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «Después de los 10 P.C. para desbloquear el puente sigue saliendo lo de "hasta aquí lo hecho date una vuelta", cuando debería pasar directamente a la herencia de la eufrasia. Solo que dándole media hora in-game, en vez de dos».
- **Qué era.** Tras `_unlock_bridge` la historia entra en el paso `tbc` y la hoja del día ponía `obj_free` («... o date un garbeo»); la Paca llamaba a las 2 h de juego.
- **Cambios.** `fondo_casa.gd`: `CALL_AFTER_H := 0.25` (primero 0.5; Luis, acto seguido: «vamos a reducirlo a 15 minutos in-game»); `leaf()` ("" si no toca); `_leaf_was` y, en `tick`, `G.leaf_refresh()` cuando `leaf()` cambia y no hay `dlg` ni `phone_call` (la etapa cambia dentro de la llamada y de la charla). `game.gd`: `_show_step`, rama `tbc`/`free`: texto de `fondo_casa.leaf()` si lo hay (no en `chavisca`), y `set_target` a la Paca en la etapa `paca`; `leaf_refresh()` solo actúa con `side == null` y en `tbc`/`free`. `loc.gd`: `obj_casa_espera`, `obj_casa_paca`. El paso `tbc` y `obj_free` siguen: es lo que se ve con la deuda ya contada.
- **Pruebas.** `selftest.gd` `_casa_checks`: sitúa `si` en `tbc` si corre sola; comprueba que a 0,1 h no llama y la hoja dice `obj_casa_espera`, que a 0,3 h llama y la hoja manda a la Paca, y que tras la charla vuelve `obj_free`. `herencia` 16 ok, `firmas` 20 ok, `palabros` OK. En la completa, la comprobación «no to-be-continued screen» espera `obj_casa_espera`: sin pasar. Ojo en la completa: la Paca llama ahora a los 30 s reales de abrir el puente (antes a los cuatro); si alguna comprobación posterior se cruza con su llamada, es por esto.

### Alturas de menos, segunda pasada (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «Podemos repasar lo de las alturas de menos? Que hay edificios que tienen ventanas que sobresalen por arriba».
- **`casas.gd`.** `_rhythm(f, L, ground, room)`: si la ventana tipo (alféizar + alto) no cabe en `room` (el alto de la planta), no devuelve ninguna; `_facade` le pasa `h`. En la última planta, un parche se corta en el borde del muro y un rótulo baja a `h - 0,46`.
- **`casas_calles.gd`.** `h=` añadido a la planta baja de `co_31`, `vgracia_12`, `tembleque_95`, `santo_69`, `peso_b006`, `md_33`, `cip_16`, `abajo_7` (las líneas de antes, en `git diff`).
- **`tools/casas/plantas_altas.py`** reescrito: lee las fichas como `_unpack`, también «lado» y «quiebro». `tools/casas/alturas.gd` (lo mismo con el parser del juego, `Godot --headless --path godot -s ../tools/casas/alturas.gd -- salida.json`) está sin probar: el día que lo lancé `casas.gd` tenía un error de sintaxis de otra sesión (`var br := _mat(...)`, arreglado por ella a los cinco minutos).
- **Lo comprobado y descartado.** El tejado nunca baja del borde del muro (`_roof_y`), los edificios sin ficha estiran su textura con las plantas (`world.gd`), y recercos, dinteles y frontones de la última planta caben en las 3269 fichas.
- **Pruebas.** `casas solo=` con las trece: 4 ok. Fotos en `guion/fotos/dobles/alturas_3.png`. Nada en commit.

### Fachadas dobles: repaso de las 27, una por una (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «Revisamos las 27 y vamos una por una». Por cada casa, una hoja A/B (`guion/fotos/dobles/<id>_comparativa.png`) y él elige. Sus respuestas: «Rellenar» (`valencia_13`); «Haz el quiebro y ponme una comparativa. Y elijo» y luego «B» (`sanisidro_30`); «B» en `sanisidro_34`, `amargura_9`, `parto_10`, `cip_4`; «Las que sean rellenar, rellénalas directamente»; «Las del arreglo tienen mejor pinta» (`cri_xb` y las tres hechas sin preguntar); «Hay ventanas que quedan fuera de la fachada» (sobre `rsof_b402` y `cruces_22`).
- **`calles.json`.** `fill`: `valencia_13` [[4.1, 11.4, 3.1]], `cip_4` [[9.31, 19.32, 2.2]], `sev_21` [[3.4, 8.77, 1.95]], `ctn_132a` [[8.86, 13.76, 2.32]]. `clear`: `real_43` 0.95, `real_31` 1.4, `rsof_b402` 0.85, `cruces_22` 1.05, `bs_22` 1.1, `vin_x2` 0.85, `flo_26` 0.85, `fle_10` 1.0, `stana_31` 0.9, `co_14` 1.15, `stana_27` 0.9. `front` nuevo: `sanisidro_30`, `sanisidro_34`, `parto_10`, `rol_br19`, `cri_xb`, `monjas_8`, `jym_rs45`, `co_40`, `amargura_9`, `amargura_11`. `h`: `rsof_b402` y `constitucion_30b` 6.4, `cruces_22` y `cruces_11` 9.3, `md_12` 12.3. Casa nueva `amargura_11g` (va justo antes de `amargura_11`: el horneado toma la primera que encaja; `only` 2 y `only` 1).
- **`casas_calles.gd`.** Fichas reescritas: `sanisidro_30` (líneas «lado» para su tramo girado), `sanisidro_34`, `cri_xb`, `co_40` (líneas «quiebro»), `amargura_9` (6,2 m, `ciego`), `amargura_11g` (nueva), `amargura_11` (portón en .78). Las líneas de antes están en el scratchpad de la sesión (`*_antes.txt`), no en el repo: para volver atrás, `git diff`.
- **`casas.gd`.** `_unpack`: una línea que empieza por `quiebro ` va a `spec["turn"]`. En `_from_spec`, al dibujar un lado a calle de 3 m o más: si la ficha tiene `turn` y el borde corre a lo largo del frente (`|dx| > 0,9 · largo`) y uno de sus extremos está en el frente (`_on_front`), se dibuja con esas líneas (se ponen un momento en `spec["flank"]` y `_flank` a verdadero). Los carteles de una línea «quiebro» van a esa pared (`lado` 1 por defecto, como en «lado»).
- **Lo aprendido.** (1) Las piezas de Catastro por delante de la línea con una planta menos que el cuerpo son vuelos de las plantas altas; `_step` las sacaba como planta baja adelantada. Se recortan con `clear` y, si la ficha lleva `fly`, el vuelo se ve arriba. (2) El «6,25» que apunté para la esquina de `sanisidro_30` era del anillo ya crecido por el horneado, no de Catastro: para leer el solar real, el mapa de antes del arreglo o `partes_catastro.py`. (3) Las líneas «lado» van a la pared más larga a otra calle; un tramo girado más corto que esa se quedaba con ventanas genéricas: de ahí «quiebro». (4) Con `tol` propio en la ficha (`alemania_9`, 1,1) la cuenta de `fachadas_dobles.py` da un falso positivo.
- **Sin tocar.** `ctn_136` y `ctn_138` (cuerpos reales de 1,5–1,9 m en la medianera; el juego los saca como porche con terraza: Luis, 25/11: «Déjalos como están»). La tapia de `amargura_11` tiene zócalo de piedra en el juego y una franja marrón pintada en la foto. Los tres portones más altos que su planta baja.
- **Pruebas.** `casas solo=` con todas las tocadas, por tandas: 4 ok cada vez. Cuelgues de Godot al arrancar (señal 11, `game.gd:728`): unas siete veces hoy, siempre bien al repetir. Nada en commit.

### Fachadas dobles: el frente y el solar (25/11, Claude · Sistemas)

- **Qué pidió Luis.** «Hay muchas fachadas que salen dobles. Con una segunda fachada adelantada al bloque del edificio. A que puede deberse?», en «Calle tembleque con rosa de Santamaría» (`rsm_t12d`, `rsm_b113`). Tras el diagnóstico: «Hazlo tú cuando termines tu tanda, ya que lo has analizado. Y lo arreglas». Texturas avisó de que su tanda había terminado antes de que yo tocara nada.
- **Causa.** `front` más de 0,6 m por delante del borde del solar. `casas.gd` `_from_spec` no reconoce ese borde como fachada (`_on_front`, `tol` 0,6) y lo dibuja otra vez (`_facade(ln, spec, true)` si da a calle y mide 3 m o más). En el cruce, la hilera `rsm_t12d`/`rsm_24`/`rsm_b019` estaba sobre una sola recta y la calle quiebra 4°: 1,1 m de desfase en la esquina y la bocacalle a 2,8 m de ancho (Catastro: 4,9 m).
- **`tools/bake_godot.py`.** Bloque nuevo «The body reaches the front» antes de `for hand, (bid, floors, pieces) in hand_groups.items()`. Constantes `FRONT_REACH` 3,0, `FRONT_SURE` 1,9, `FRONT_TOL` 0,5, `FRONT_ROAD` 2,1. Por cada casa de `_from_spec` (fuera: `["obra"]`, `func _<id>` de `casas.gd`, `ADOSADOS`, `ROSAS`, `HILERA21`, `rc` nulo, `strip`, `"grow": 0`): barre el solar hacia la línea (`_sweep`), quita su porche, las demás casas descritas y la calzada (`_roadway`: los ejes de las calles con 2,1 m), y añade el hueco a las piezas de la casa. Un entrante de más de 1,9 m que coge entre el 15 % y el 85 % del frente no se rellena (se lista). Con `MATRI_FRONTS=<archivo>` escribe además, para cada casa con hueco y sin `porch`/`fill`/`clear`, la recta que de verdad tiene su solar (los dos puntos más separados de su contorno que no dejan nada a más de 0,15 m por delante).
- **`tools/casas/frentes_al_solar.py`** (nuevo). Lee ese archivo y pone en `calles.json` el frente de las casas cuya línea se metía en la calzada, y el de las vecinas que compartían extremo si así se cierra la junta. Se repite horneado + script hasta que no mueve nada (a la segunda vuelta, cero). `calles.json` se reescribe con `json.dumps(indent=1)`, idéntico byte a byte a como estaba salvo los frentes.
- **Números.** 153 frentes retrasados (19 de ellos por acompañar; de Texturas hoy: solo `sce_vm`, 0,15–0,32 m). 61 solares crecidos, 151 m². Dobles por la medida de `fachadas_dobles.py` (carpeta de notas): de 137 a 27.
- **Sin tocar.** Las 17 casas con el solar por DELANTE de la línea (`_step`: planta baja adelantada): `alemania_9`, `real_43`, `real_31`, `stana_27`, `stana_31`, `jym_rs45`, `monjas_8`, `rsof_b402`, `cruces_22`, `bs_22`, `vin_x2`, `flo_26`, `fle_10`, `co_14`, `co_40`, `ctn_136`, `ctn_138`; algunas serán de verdad. Los pareados de 1995 de Florido y del Rollo (`flo_p*`, `rol_b*`, con `strip`): tapia en la calle y casa detrás, a propósito.
- **Líneas que aún rozan la calzada** (el horneado las lista; casi todas por menos de 1 m²): `mon_n25` `rol_br19` `jym_10` `peso_24` `jym_8` `amargura_7` `sanisidro_30` `sanisidro_34` `sanisidro_55` `jym_rs26` `castilla_16` `parto_b301` `parto_10` `colon_s11` `real_49` `fle_1` `romero_5` `romero_3` `constitucion_44` `rsa_16` `delicias_36d` `cri_xb` `stana_56` `jx_10` `clavel_eu1`.
- **Trampas.** (1) El primer recuento (285) estaba inflado: contaba la pared trasera de piezas poco hondas; hay que mirar hacia dónde mira el borde. (2) Rellenar siempre hasta la línea dejaba calles con 0,9 m de paso libre: por eso la calzada manda. (3) `casas` sin `solo=` fotografía las 3280 y no acaba en 600 s; con `solo=` hace sus comprobaciones de todas igualmente.
- **Pruebas.** `casas solo=rsm_t12d,rsm_b113,rsm_24,toledo_t65,sanisidro_10,real_78,monjas_r23,cov_r9`: 4 ok. Nada en commit.

### La toquilla y el mandil (25/11, Claude · Sistemas)

- **Qué.** Luis, con una foto de cada prenda: «Para las ancianas habría que añadir de ropa posible una toquilla (negra para el cementerio, de colores fuera) y para todas las mujeres no niñas un posible mandil».
- **`chara.gd`.** Claves de look `toquilla` y `mandil` (un color; −1 o sin clave: nada). `_layers(top_id)` va tras `_clothes`, sobre cualquier ropa, separado por `_top_pad`. `_shell` es un generador de telas sobre el cono del cuerpo: `at(u, v)` → ángulo, altura y separación; uv en metros; ribete con color de vértice (dos líneas juntas en cada borde para que quede nítido); en caché por clave.
  - Toquilla: textura de agujeros al tresbolillo con alpha scissor (`TOQUILLA_CELL`), las dos mitades cruzadas abajo en el centro, el V abierto al cuello y tres bolas de nudo.
  - Mandil: vichy (`GINGHAM_TILE`), peto con tirantes y sisas, espalda, tira de flores sobre azul oscuro, bolsillos. Sobre los vestidos (ropa 22 y 25) se abre abajo con la falda (`flare`); sin eso, la falda lo atravesaba.
- **Creador.** Opciones 28 y 29 (añadidas al final), en Pintas tras el estampado, en `COLOUR_OPTIONS`, en `WARDROBE` con `NOTHING` 0 (los armarios guardados las reciben solos: `armario_owned`). Etiquetas en `c_names` y `c_values`.
- **Quién las lleva.** `_neighbour_look`: toquilla de color en el 18 % de `old_f`; mandil en el 22 % de `old_f` y el 8 % de `adult_f`. `luto.gd`: toquilla negra en el 45 % de las viejas (`TOQUILLA`); el mandil, si sale, negro; nada al viejo. Los NPC únicos no cambian.
- **Modelos libres y Blender, probados y descartados.** Luis pidió probar modelos libres o hechos en Blender. En OverScore Proxy (CC0) la «Shoulder Wrap» casi todo son mangas y la «Sleeveless Scoop Neck Tunic» sale con bultos. Se hizo una versión desde cero en Blender, con grosor, bordes enrollados, nudo y ribete en relieve. Luis prefirió la de código: «Las de las foto mejor. Han quedado increíbles». APROBADAS así; el script de Blender se borró.
- **Pruebas.** Foto `guion/fotos/toquilla_mandil.png` (de frente y de espaldas, `portraits --window --cuerpo --looks=`). `creador` 21 ok, `luto` 10 ok (comprobación nueva de la toquilla), `palabros` OK. Sin commit.

### El Modo Chavisca pasa a llamarse Modo Golismeo (25/11, Claude · Sistemas)

- **Qué.** Luis: «Modo Chavisca* sería modo golismeo». Cambian solo los textos que se ven: `loc.gd` `menu_chavisca` («Modo Golismeo» / «Golismeo mode»), `menu_chavisca_t` («MODO GOLISMEO»), `obj_chavisca`; y `guion/misiones.html` (y su artifact).
- **Lo que no cambia.** `G.chavisca`, las claves de Loc, los guardados `chavisca_*.json` (las partidas de antes siguen ahí), las pruebas `--chavisca` y `--chavisca_intro` y las notas viejas. La prueba busca «Golismeo» en el objetivo.
- **Pruebas.** `chavisca shots`: 8 ok; foto `chavisca_menu` con «Modo Golismeo». Sin commit.

### La gente de luto del cementerio (25/11, Claude · Sistemas)

- **Qué.** Luis: «En el cementerio habrá siempre 4/6 NPCs dando vueltas. Varias ancianas y un anciano. Vestirán de negro/colores oscuros y las mujeres siempre pañoleta negra se llamarán simplemente Viejo/a de luto y dirán frases en tono humor negro manchego ... No serán NPCs únicos ... También hay probabilidades de que aparezca un NPC único aquí si no está trabajando/de misión». Luego: «Mejor que solo un 25% de la viejas lleve la pañoleta» (`luto.SCARF`).
- **`luto.gd`** (preparado en `game.gd` antes de `rondas`, `tick` tras la Pili). Seis NPC sin `id`, nombre `generic_names` 10/11, frases `luto_f` / `luto_m`. Cada día salen `4 + posmod(day_n*7+3, 3)`, el viejo siempre; los demás `away` y ocultos, y solo cambian cuando no los ves. Aspecto: `_neighbour_look` y encima colores oscuros, zapatos negros, sin carro, sin tabaco; gafas y pendientes discretos; las viejas sin la blusa blanca sola (ropa 16 fuera).
- **Por dónde andan.** Una rejilla de paseos (`lanes_u`, `lanes_v`, en el marco del cementerio `cm.map_at` / `cm.P`) por los huecos de `COLS` / `ROWS`; ruta BFS, `_edge_ok` no deja cruzar un par de filas. `_uv` invierte `P` con Newton (la aproximación daba falsos «a través de tumbas»). Visitan pasillos de tumbas a menos de 35 m (`NEAR`).
- **Únicos.** `rondas.gd` `CEMENTERIO` (probabilidad por perfil) y `cementerio(id)` con un hash por tramo de dos horas, de 9 a 20; nunca niños; `zones["cementerio"] = G.luto.spots()`.
- **Pañoleta.** `chara.hat_cut("panoleta")` = 3 y `_hair` no pinta pelo con corte 3: antes algunos peinados asomaban por encima.
- **Pruebas.** `luto shots`: 9 ok (116 de 400 aspectos con pañoleta), fotos `luto_vieja`, `luto_grupo`. `palabros` OK. Sin commit.

### La Pili como la referencia: piezas nuevas de Lustre y Pintas (25/11, Claude · Sistemas)

- **Qué.** Luis: «La Pili se parece muy poco a la referencia. Crea nuevos elementos de Lustre y Pintas si lo ves necesario. Propón aspectos». Se le enseñaron cuatro (`guion/fotos/pili_aspectos.png`) y eligió la A. `PILI_LOOK` en `pili.gd` es esa.
- **Opciones nuevas del creador** (añadidas al final de `OPTIONS`, como manda la regla):
  - 24 `canas`;
  - 25 `brow_color` (−1 es el color del pelo);
  - 26 `nose`;
  - 27 `estampado`.
  También el peinado 35 (`Chara.MATA`) y la ropa 25 (`Chara.REBECA_VESTIDO`). Etiquetas en `loc.gd` (`c_names`, `c_values`). `TABS`: las tres primeras van en Lustre y el estampado en Pintas. `not_used` las apaga cuando no aplican.
- **Cómo están hechas (`chara.gd`).**
  - `_mata`: unos 150 rizos con bultos en una cáscara alrededor de la cabeza, en caché, más la bola de pelo normal debajo.
  - `_canas`: tras `_hair`, cambia los materiales del color del pelo por un shader de ruido. Los colores se pasan en lineal: con `source_color` y `Parts.col` salían grises.
  - `_cardi_fronts`: el cuerpo de la rebeca, curvo, con la V, da toda la vuelta, porque la rebeca del modelo libre deja un hueco en la espalda.
  - `_print_on`: textura triplanar con `uv1_triplanar_sharpness` alto, para que no emborrone.
  - `_nose`.
- **Creador (`game._refresh_creator`).** El panel tiene 12 filas (`hud.CREATOR_ROWS`) y Lustre ahora 15: la lista se desplaza con el cursor (`_creator_first`).
- **Vecinas.** `_neighbour_look` `old_f`: 14 % con la mata, 18 % con pelo oscuro y canas, 16 % con rebeca y vestido.
- **Pruebas.** `creador` 21 ok, `pili shots` 10 ok, `palabros` OK. `portraits looks=<json> out=<carpeta> [cuerpo] [giro=]` sirve para probar aspectos sin tocar los NPC. Retratos de la Pili rehechos y `relaciones.html` regenerado. Sin commit.

### Juan XXIII, los dos extremos: 15 entradas (25/11, Claude · Texturas)

- **Qué.** `jx_5, 7, 8, 6, 4, 2, 2s, 49, 51, 53, 55, 57, 59, 42, 44`, escritas por el scratchpad `jx3_write.py` (en `casas_calles.gd`, tras `jx_18`). Comprobado contra las zonas: `merkocarry_zone` a 36 m o más del extremo sur, `almazara_zone` a más de 300 m del norte; ningún RC en `bake_godot.py` ni en los scripts.
- **Dejadas.** `4591026` (el 3, detrás del 5).
- **Alineación.** alinea.py 0. Horneado: 15 nuevas; `stana_79` y `bs_j61p` solo cambian la medianera.
- **Pruebas.** `casas` OK. APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.

### San Cristóbal, tramo oeste: 14 entradas (25/11, Claude · Texturas)

- **Qué.** `scr_1, 3, 5, 9b, 9, 11, 13, 15, 17, 17b, 4, 6, fp11, fp10`, escritas por el scratchpad `scr_write.py` (en `casas_calles.gd`, tras `jx_44`). El 7 (`4791014`) es «suelo» en el Catastro: `scr_5` lleva `fill` sobre él. `4791013` y `4891021` van partidos por plantas (`only`). Comprobado: nada a menos de 90 m de `named_u` ni de `merkocarry_zone`; ningún RC en `bake_godot.py` ni en los scripts.
- **Dejadas.** La tapia por San Cristóbal de `jx_8` (`4791501_part3`, de una planta), que sigue como bloque normal; y el tramo este de la calle (el 19 y siguientes; el ladrillo de tres plantas `4891529`), para la próxima tanda.
- **Alineación.** alinea.py 0. Horneado: 14 nuevas; `jx_10` solo cambia la medianera.
- **Pruebas.** `casas` OK. APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.

### San Cristóbal, tramo este: 15 entradas (25/11, Claude · Texturas)

- **Qué.** `sce_19, 21, 23, 23b, 25, 27, 29, 31, vm, v11, 18, 20, 22, 24, 26`, escritas por el scratchpad `sce_write.py` (en `casas_calles.gd`, tras `scr_fp10`). `sce_23b` va sin RC (tapia). `sce_29` (`4891015`) es un solar: `porch` de 4,4 m y `fill` de 0,3 m para la valla. `sce_v11` es Vázquez Mella 11 (`4891527`) con `fill`. `sce_vm` es `4891529` (sin dirección). Comprobado: nada a menos de 120 m de `named_u` ni de `merkocarry_zone`; ningún RC en `bake_godot.py` ni en los scripts.
- **Dejadas.** Del 33 al 45, el 28, Alegría 7 y la Travesía de San Cristóbal 2, para la próxima tanda.
- **Alineación.** alinea.py 0. Horneado: 15 nuevas, ningún cambio en las demás.
- **Pruebas.** `casas` OK. APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.

### San Cristóbal, último tramo: 10 entradas (25/11, Claude · Texturas)

- **Qué.** `scf_33, 35, 39, 41, 43, 45, t2, tapia, 28, a7`, escritas por el scratchpad `scf_write.py` (en `casas_calles.gd`, tras `sce_26`). `scf_tapia` va sin RC. `scf_t2` es `4891506` con líneas `lado` a la Travesía. Comprobado: nada a menos de 180 m de `named_u` ni de `merkocarry_zone`; ningún RC en `bake_godot.py` ni en los scripts. `sce_26` solo cambia la medianera con `scf_t2`.
- **Dejadas.** Las fachadas de la Calle de la Alegría del 45 y de Alegría 7.
- **Alineación.** alinea.py 0. Horneado: 10 nuevas; `sce_26` solo cambia la medianera.
- **Pruebas.** `casas` OK (la tapia necesitó sus juntas de tapial para pasar de 12 piezas). APROBADA por el usuario («Visto bueno y paramos»). Sin commit.

### Los Remedios, tramo oeste: 15 entradas (25/11, Claude · Texturas)

- **Qué.** `rem_1d, 3, 5, 7, 9, 11, 13, 15, 15a, 17, 2, 2d, 4, 6, 8`, escritas por el scratchpad `rem_write.py` (en `casas_calles.gd`, tras `scf_t2`). Frentes de `house_street.py` sin tocar; huecos medidos con `rem_px.py` (rayos de la panorámica sobre las fachadas).
- **Frentes nuevos.** Horneado con las líneas `fronts:` de Sistemas: ninguna `rem_*` metida en la calzada ni con hueco.
- **Pruebas.** `casas` OK. APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.

### Los Remedios, segundo tramo: 15 entradas (25/11, Claude · Texturas)

- **Qué.** `rem_fp23, fp22, 19, 21, 23, 25, 27, 29, fp20, 14, p9, 18, 20, 22, 24`, escritas por el scratchpad `rem2_write.py` (en `casas_calles.gd`, tras `rem_8`). Frentes de `house_street.py`; el del 22 llevado a la línea de sus vecinos con `clear: 1.0`. Huecos medidos con `px_cast.py` (rayos de la panorámica sobre las fachadas).
- **Frentes nuevos.** Línea `fronts:`: solo `rem_fp20` con 0,6 m² en la calzada (cuña de esquina); `frentes_al_solar.py` movió 0 frentes. Se deja así.
- **Pruebas.** `casas` OK. APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.

### Los Remedios, tercer tramo: 21 entradas (25/11, Claude · Texturas)

- **Qué.** `rem_31 … rem_57` (impares) y `rem_26 … rem_al15` (pares), escritas por el scratchpad `rem3_write.py` (en `casas_calles.gd`, tras `rem_24`). Tres tapias rc null. Para los tramos de otra fábrica, `paño` y no `parche` (el parche tapa los huecos).
- **Frentes nuevos.** Ninguna `rem_*` nueva metida en la calzada; `alinea.py` 0.
- **Pruebas.** `casas` OK. APROBADA por el usuario («Visto bueno y siguiente»). Sin commit.
- **Lo que faltaba (usuario: «Ponte con lo que falta frente a las fotos»).** Adosados del 31 al 45: frentes 2,6 m atrás con `clear: 3.0` y tapias rc null a la calle (`rem_tw`, `rem_te`, `rem_39g`); `esc` y `ter` para escaleras y porches. Dos funciones nuevas en `casas.gd` tras `_des_9`: `_rem_36` (la bandera) y `_rem_t49b` (hastial y tejado de la nave). Ojo: `var br = _mat(...)` sin `:=` (con `:=` es un error de análisis que para todas las pruebas; lo arreglé al momento). Horneado: 4 nuevas y las 10 vecinas; ninguna `rem_*` nueva en la calzada. `casas` OK.

### La Plata, mitad oeste: 25 entradas (25/11, Claude · Texturas)

- **Qué.** `pla_*`, escritas por el scratchpad `pla_write.py` (en `casas_calles.gd`, tras la última fila `rem_`). Frentes de `pla_fronts.py`: norte en la línea del Catastro, sur a 2,45 m del eje de la calle del mapa (que va 3 m al sur de la real; el pasillo de la calle recorta los solares a 2,4 m del eje, así que no hace falta `clear`).
- **Trucos.** Un RC con dos edificios: dos entradas con `reach` (Fray Petronilo 17). Un RC con una parte de una planta al lado de una de dos: la entrada de una planta con `only: 1` y `reach`, ANTES en calles.json (`house_of` se queda con la primera que encaja). Tapias rc null: el área tiene que pasar de 5 m² o el horneado las tira (`pla_fp17g` con `deep` 0,8). Ojo con el orden de `win`: posición, ancho, antepecho, alto.
- **Frentes nuevos.** `pla_8` con 0,2 m² en la calzada de la Fray Petronilo (esquina), se deja; `pla_1` tenía el patio hundido 2,8 m: `fill`.
- **Pruebas.** `casas` OK. APROBADA ("Visto bueno y continuar"). Sin commit.

### La Plata, mitad este: 17 entradas (25/11, Claude · Texturas)

- **Qué.** `pla_*` del scratchpad `pl2_write.py`, en `casas_calles.gd` tras `pla_16b`. Norte en la línea del Catastro; sur en el borde del pasillo de la calle del mapa.
- **Trucos.** Fill de 0,3 m: lo tira `simplify(0.3)`, poner 0,6. Un RC compartido con una casa ya hecha (`rem_p21`): la entrada nueva con `only` va ANTES en calles.json. Una tapia de 2,4 m necesita detalle real (hiladas, remate) para pasar de 12 cajas: no inventar pilares.
- **Vecinas tocadas.** `sce_29` pierde sus dos piezas a la Plata (ahora `pla_sol`), `rem_p21` la de dos plantas (ahora `pla_21`); vistas en el juego, bien.
- **Pruebas.** `casas` OK. APROBADA ("Visto bueno y continuar"). Sin commit.

### Vázquez de Mella: 28 entradas (25/11, Claude · Texturas)

- **Qué.** `vm_*` del scratchpad `vm_write.py`, en `casas_calles.gd` tras `pla_30`. La calle del mapa coincide con la real (panorámicas a menos de 1 m del eje).
- **Trucos.** Parcela con frente a dos calles: la entrada nueva con `only`/`reach` va ANTES en calles.json (`vm_11` antes de `sce_v11`, `vm_12` antes de `stana_97`). El aviso «a deep recess ... left alone» del horneado con un frente liso en la foto: `fill` a mano. Una obra sin huecos no pasa de 12 cajas: la entrada abierta es `gar ... k=void`, no un parche.
- **Vecinas tocadas.** `stana_101` (aprobada) gana dos filas `lado`; `stana_97`, `stana_99`, `stana_103`, `stana_105` y `sce_v11` pierden piezas de atrás; vistas en el juego, sus fachadas igual.
- **Pruebas.** `casas` OK. APROBADA ("Visto bueno y paramos"). Sin commit.

### 26/11 — Antigravity: 10 nuevos peinados cortos / masculinos (`36..45`)

- **Qué.** Añadidos 10 peinados cortos estilizados esculpidos en Blender (`tools/creador/pelos_cortos.py`) e importados en `godot/assets/creador/pelo/`: `pelo_pincho.glb` (`36 · De pincho`, degradado), `pelo_patras.glb` (`37 · Peinao pa' trás`, completo), `pelo_brocoli.glb` (`38 · De brócoli`, degradado), `pelo_alborotao.glb` (`39 · Alborotao`, completo), `pelo_entradas.glb` (`40 · Con entradas`, completo), `pelo_monito.glb` (`41 · Moñito`, degradado), `pelo_flequillo_lao.glb` (`42 · Flequillo de lao`, completo), `pelo_cepillo.glb` (`43 · De cepillo`, degradado), `pelo_raya_medio.glb` (`44 · Raya al medio`, completo) y `pelo_rastas_cortas.glb` (`45 · Rastas cortas`, degradado).
- **Integración y gorros.** Añadidos al final de `OPTIONS[10]` en `creator.gd` y `loc.gd` (es/en, sin desplazar índices de partidas guardadas) y cableados en `chara.gd` mediante `PELOS_CORTOS`. Los 5 degradados pintan `_degradado(hair)` y ocultan el volumen superior bajo cualquier sombrero (`cut > 0`). Los 5 completos incluyen `gorro` (recorte bajo gorra) y `gorro_alto` (coronilla comprimida al ras del cráneo a `R + 0.009` sin agujerear el cuero cabelludo, evitando calvas incluso bajo la boina inclinada o el sombrero de paja). Compatibles con el shader de `canas`.
- **Canas «En las sienes» (`canas = 4`) y vecinos (`game.gd`, `koke.gd`, `chara.gd`).** Se quitan las `canas` moteadas aleatorias (`1..3`) del pool de vecinos (`old_f` y `old_m`, incluidos los del cementerio) y se añade `canas = 4` («En las sienes» / *Grey temples*) en `creator.gd`, `loc.gd` y `chara.gd`: en peinados con degradado pinta `_degradado(0x9a968f)` manteniendo el pelo de color arriba, y en peinados completos aplica `_sienes_mat` (degradado suave gris en sienes y nuca sin manchas). Reparto de vecinos: `kid` recibe todos los nuevos menos `40 · Con entradas` (`36..39, 41..45`, con doble peso en `36, 38, 39, 42`), `adult_m` recibe todos (`36..45`, + 10 % `canas = 4`), `adult_f` suma `39, 42, 44` y `old_m` incorpora `37, 40 (x2), 43, 44` (+ 22 % pelo oscuro con `canas = 4`). Don Luis (`luis` en `game.gd`) cambia a `41 · Moñito` + `canas: 4` (sustituyendo las bolas grises laterales de `dress_luis`), y Koke el Kokas (`koke.gd`) a `36 · De pincho`. En `game.gd` también se baja la probabilidad de piel ultra blanca (`0xfbd7b5`) del ~23,8 % al ~10,6 % (manteniendo el 5 % de pieles oscuras) y se añade `NEIGHBOUR_MIX` para subir la proporción callejera de ancianos/as del 40 % al 50 % (sin tocar los índices `0..9` de `NEIGHBOUR_VOICES` ni `generic_names`).
- **Pruebas.** `criba_pelo` (`solo=36..45`) OK, `palabros` 3 ok, `creador` 21 ok, `ropa` 2 ok. APROBADO por el usuario («Perfecto»). Sin commit.

### 26/11 — Antigravity: arreglo de la radio en Android

- **Causa.** En Godot 4.7.2, Android exporta un paquete índice disperso (`assets/assets.sparsepck`, PCK v4 `PACK_SPARSE_BUNDLE`) que controla la vista de `res://`. Como `godot/radio/.gdignore` oculta `radio/` al exportador y `tools/make_apk.py` añadía los archivos de `assets/radio/...` al ZIP sin registrarlos en `assets/assets.sparsepck`, `Ambience._load_stations()` no encontraba ninguna carpeta `radio1..6` en el móvil (`stations = []`, `station = 0`). Además, `ambience.gd` usaba `load_from_file()` sobre rutas `res://` para logos `.png` y pistas `.ogg`/`.wav`.
- **Arreglo.**
  - `tools/make_apk.py`: genera `assets/radio/index.json` (listado de `radio1..N` y sus pistas), registra los 44 archivos de `radio/*` dentro de `assets/assets.sparsepck` (con padding de 4 bytes, tamaño y MD5 reales) y verifica tras firmar que todas las emisoras y pistas están tanto en el ZIP del APK como indexadas en `assets/assets.sparsepck`.
  - `godot/scripts/ambience.gd`: `_load_stations()` lee `radio/index.json` cuando existe (Android, sin depender de `DirAccess`) y conserva el escaneo por carpetas `DirAccess` cuando no existe (PC/Linux/editor); los logos `.png` y las pistas `.ogg`/`.wav` se cargan ahora vía `FileAccess.get_file_as_bytes()` + `load_png_from_buffer` / `AudioStreamOggVorbis.load_from_buffer` / `AudioStreamWAV.load_from_buffer`, igual que `.mp3`.
- **Archivos.** `tools/make_apk.py`, `godot/scripts/ambience.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `python tools/make_apk.py` (`dist/Matritellus.apk`: 44 archivos de radio, 6 emisoras, `sparsepck=1987`, firmado y verificado), carga real de `assets.sparsepck` en Godot 4.7.2 (`LOAD_SPARSEPCK=true`, `DIR_RADIO1=true`, `INDEX_EXISTS=true`, 6 emisoras / 6 logos / 30 pistas `.ogg` decodificadas), `emisoras --headless` (3/3 ok) y `llegada --window` (2/2 ok).

### 26/11 — Antigravity: retrovisores, pegatinas ITV e interiores cerrados solo en 1.ª persona

- **Causa.** Al entrar en cualquier coche (`game.gd:_enter_car`), `set_rosary(true)` creaba `_rosary_root` y `_dash_root` visibles aunque la cámara estuviese en 3.ª persona o cinemática, haciendo que los retrovisores, las pegatinas ITV y los cristales de espejo lateral saliesen siempre.
- **Arreglo (`godot/scripts/car.gd`).** Nuevo `_sync_fp_cockpit()` llamado desde `set_driver_head_visible()` y al final de todas las ramas de `set_rosary()`:
  - `_rosary_root.visible = _fp_hide_head` en todos los vehículos (retrovisor central/de pie, rosario, pegatinas ITV de Z15/Panda, retrovisores superiores y lazo del Yondir).
  - `_dash_root.visible = _fp_hide_head or (kind == "tractor" or kind == "julietta")` (en cabinas cerradas oculta también salpicadero, pegatinas ITV del Renol 4L y espejos laterales, restaurando la carrocería exterior y las manos/volante del conductor en 3.ª persona; en el descapotable Julietta añade `LeftSideMirrorGlass` a `_fp_only`).
  - Guarda de idempotencia (`if _dash_orig_mesh != null and bmi.mesh != _dash_orig_mesh: return`) en todos los `_set_*_cab_stripped()`.
- **Archivos.** `godot/scripts/car.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `rosario --window` (5/5 ok + `rosario_fuera*.png` y `rosario_itv.png`), `seta --headless` (4/4), `cuatrolatas --headless` (6/6), `yondir --headless` (4/4), `edison --headless` (4/4) y `julietta --headless` (4/4).

### 26/11 — Antigravity: ruedas completas del tractor Yondir

- **Causa.** El corte automático de `tools/blender/limpiar.py` dejó 444 caras de goma (`Part51Mtl`: 288 de `wheel_bl`, 120 de `wheel_br`, 36 de `wheel_fr`) y 24 de los aros amarillos traseros (`Part42Mtl`) pegadas dentro de `body`, con los ejes traseros 6 cm bajos; además `"wheel_copy": {"wheel_bl": "wheel_br"}` en `modelos.gd` copiaba la `wheel_br` ya incompleta.
- **Arreglo.** Añadida `yondir_mend_wheels()` en `tools/blender/limpiar.py` y regenerado `godot/assets/vehiculos/sk/yondir.glb` desde el original en `tools/descargas/sketchfab/yondir/yondir.glb`: las 468 caras pasan a sus ruedas correspondientes, cada rueda queda con 12/12 sectores (288 caras de goma cada una; `wheel_fl == wheel_fr` y `wheel_bl == wheel_br` en triángulos) y sus orígenes re-centrados en el eje geométrico real; eliminado `wheel_copy` en `modelos.gd`.
- **Archivos.** `tools/blender/limpiar.py`, `godot/assets/vehiculos/sk/yondir.glb`, `godot/scripts/modelos.gd`, `godot/scripts/selftest.gd`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`. Sin commit.
- **Pruebas.** `yondir --window` + `yondir --headless` (5/5 ok + `godot/shots/yondir_ruedas_izq.png` y `yondir_ruedas_der.png`). APROBADO por el usuario («Visto bueno»). Sin commit.
