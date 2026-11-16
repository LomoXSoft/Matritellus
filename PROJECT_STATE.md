# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Sin publicar

Nada todavía: todo lo anterior salió en la 0.0.9. Lo detallado de cada pieza está en su LEEME de `referencias/` o `tools/`, en `guion/` y en el historial de git.

Veredictos que faltan de lo publicado: el cuartel de los Tricornios (la rotulación sí está aprobada) y la Universidad Comunal con la Papelería Rocas.

## Versión

- **Publicada:** 0.0.9 (16/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.9 — completa de las 04:30: 680 ok, 0 fallos.
  - **Sistemas:**
    - El gacha (`gacha.gd`): 1 € en la máquina del Tele Dürum, figuras de los 24 vecinos con nombre, la página «Colección» de la Agenda (que ya tiene 6 páginas), confeti y trombón triste.
    - El sentido único de OpenStreetMap: `"ow"` en el bake, `traffic.one_way_ok`.
    - Dolores Fuertes D'Varriga en la calle de la Amargura (`walker` con `beat`), con su confesión a 100 de confianza.
    - El coche de los Tricornios en la puerta del cuartel (`cuartel_coche.gd`).
    - El reloj sigue corriendo mientras se juega al ajedrez.
    - Modos de prueba nuevos: `gacha`, `sentido`, `tricornio`, `dolores` y `conduccion`.
  - **Ajedrez humano** (su propia sesión; `ajedrez.gd`, `ajedrez_humano.gd`, `guion/ajedrez.md`): la misión del alcalde y el minijuego, con cuatro niveles que dan 4, 6, 8 y 12 PC, sin límite diario.
  - **Pretil (sobre `obra.gd`):**
    - el Tele Dürum, con horario;
    - los chinos del Arroyuelo;
    - el viejo colegio, con la placa «Instituto Garcilaso de la Vega» como única excepción de nombre real;
    - el cuartel de los Tricornios y las marcas de sus coches;
    - la Universidad Comunal y la Papelería Rocas.
    - En los carteles se escribe «La Mancha».
  - **Texturas:**
    - calles enteras: Valencia, Regidor, Roma, Portugal, Argentina, San Isidro y los Arcos;
    - además, la Rosa de Santa María, la Amargura y la Travesía del Santo.
  - **Worldbuilding:** «tiés» y «ande» (prueba `palabros`).
- **Publicada antes:** 0.0.8 (15/11/2026): farmacia, Caridad, convento de Santa Ana, Mercamona y Todopizza, más las calles de Texturas de ese día.
- **Pendiente (después de la 0.0.9):**
  - **Sistemas:**
    - la flecha verde de entrada a tiendas pequeñas: al pisarla, entras a un interior aparte (`places_in`), empezando por el V.I.P. y la Papelería Rocas;
    - verde = objetivo: la flecha de objetivo y los círculos de misión, en tonos verdes.
  - **Pretil:** el interior de la Papelería Rocas, como decorado aparte.
  - **Texturas:** la calle del Santo.

## Cómo trabajar (normas del usuario, 15/11/2026)

- **Pruebas:** siempre con `python tools/run_tests.py <modo>`. Es una sola llamada que espera al final, con tiempo límite. Guarda el registro en `logs/` y devuelve un resumen.
  - Tras cada cambio, la prueba del modo afectado (`--selftest --<modo>`; la lista está en `selftest.gd`, `_run`).
  - La prueba completa (`python tools/run_tests.py`), solo en los hitos, antes de publicar o si lo piden.
  - Nada de vigilar pruebas largas a base de llamadas repetidas.
  - Los modos de fotos (`firmas`, `relief`, `casas`, `caridad`…) necesitan ventana: sin ella no escriben nada y se quedan esperando. Desde el 15/11 por la tarde el lanzador la pone solo: si el bloque del modo en `selftest.gd` empieza con `shots = true`, o si se pide `shots` o `vistas=`. `--headless` lo fuerza sin ventana. El tiempo límite corta aunque Godot no escriba nada.
- **Fallos intermitentes:** se investigan uno a uno, con el modo y su `--traza`, y `--repeat N` si hace falta.
- **No releer** archivos ni fotos que no han cambiado.
- **Sesiones a la vez:** cada una toca sus archivos. Se avisa antes de una prueba completa. Para publicar se congela la carpeta.
  - Todas las sesiones trabajan en la misma carpeta, sin carpetas de trabajo (git worktree) separadas: lo decidió el usuario el 15/11. Cada una toca sus archivos y avisa antes de tocar los de otra.

## Fallos conocidos

- **Límite, «everybody comes after you»:** intermitente. A veces el calor sale 98 cuando se pide ≥ 99: baja un poco si el juego va lento, por ejemplo con otro Godot abierto. Falló una vez el 16/11 y pasó 3/3 con `--repeat` justo después.
- **Grúa:** a veces se queda parada a unos 130 m del coche, en la esquina de (871, 254) o (880, 247), detrás de un coche aparcado. Está atenuado con `_room_at` y `_clear_parked`; vigilarlo.
- **Sabotaje:** la furgoneta se atascaba en calles estrechas, sobre todo en (-472, -340), tramos 856-858. Ahora tiene la ruta cerrada; vigilarlo en las completas.
- **Turbo del Julietta:** la segunda pasada se quedaba a 0 km/h de vez en cuando; ahora la prueba usa un coche nuevo.
- **Pruebas con ventana:** `--menu`, `--titulo --shots`, etc. La ventana ya no coge el teclado (`WINDOW_FLAG_NO_FOCUS`).
- **Mirada, «talk to them and they stand still to answer»:** falló una vez en una completa (14/11) y no se ha repetido (`mirada`, `mirada viejo`, `mirada antes` y la completa de la 0.0.3 pasan). Si vuelve, el mensaje dice voz, estado, si el diálogo sigue abierto y cuánto se movió; con «dialogue none», mirar las llamadas de la centralita (desde la 0.0.3 una llamada ya no corta una conversación, que seguramente era la causa).
- **Sin probar en dispositivos reales:** móvil y Steam Machine. Si hay tirones en la Steam Machine, pedir `tirones.txt`.
- **Tokken 9** (publicado desde la 0.0.3; `guion/tokken9.md`): nadie lo ha jugado con las manos. La dificultad del alcalde y de Katakumba69 sale solo de la simulación (`python tools/run_tests.py tokken balance`); cuando el usuario diga cómo lo nota, se retoca `AI["alcalde"]` en `tokken.gd`, sin quitarle que baje la guardia tras el primer golpe. Los botones del móvil y el mando, sin probar.

## Decisiones recientes

- **Pendiente apuntado por el usuario (15/11): niños en la escuela «S. José de Calasanz» en horario escolar.** Preguntó «Habrá niños en Calasanz en horario escolar?» y pidió dejarlo anotado. Hoy el patio está vacío. Para cuando pula los personajes (no antes: no quiere personajes nuevos por ahora): niños solo de lunes a viernes en horario de clase, siempre dentro del patio cerrado (ni en la calle ni atropellables), jugando en el recreo en la torre, el tobogán, los caballitos y la rayuela, y oyéndose al pasar el resto del horario. Falta el modelo de niño y el sistema que los saque y los guarde según la hora (Sistemas). Lo propuesto es idea de Pretil; el usuario solo ha dicho que se anote.
- Misión cumplida: solo el sello ¡APAÑAO! y el dinero en la pizarra, sin cartel.
- Galaxy Recress: el alcalde pide 100 € y devuelve 200 € (lo dijo el usuario). En Tokken 9, por confirmar con él: el alcalde lleva a El Monstruo y Katakumba69 a Drácula, la partida libre es gratis y los nombres de los poderes.
- Límite del mapa: 1950 m, recortado al borde del mapa construido.
- Cristales del Edison: opacos (al usuario no le gustaron los tintados).
- El sol sale por el este desde la 0.0.5.
- Blanco en sombra (desde la 0.0.5): de día la luz ambiente se mezcla más con blanco (`game.gd`, `_apply_sky`), para que el enfoscado blanco se lea blanco en sombra. De noche sigue azul.
- Toro de Osborne (desde la 0.0.5): en la A-4, km 120, pasado el borde sur del mapa; se ve desde la autovía (`toro.gd`, `data/toro.json`, `tools/toro/`).
- Costados de las casas que dan a otra calle: terminados. 42 de 71 descritos (y 5 más de los cortos, de 6 a 8 m) con Street View (líneas `lado` en `casas_calles.gd`, `"flank"` en `casas.gd`); los otros 29 se quedan lisos porque no se ven desde ninguna calle (dan a patios o tienen otra casa pegada delante) o no hay foto.
- Música «urbana»: en Rap-A-Polvo. El usuario no ha dicho nada en contra.
- Galaxy Recress (desde la 0.0.3; diseño en `guion/recress.md`, prueba `recress`): abre de 15:00 a 2:00 y, si estás dentro a la hora de cierre, espera a que salgas. El alcalde pide 100 € y devuelve 200 €. Una llamada no corta una conversación ni una escena (`llamadas.gd`). Pendiente del usuario: los nombres provisionales (el alcalde, la de la copistería, la mujer y la madre del alcalde, el comentarista).
- Habla (desde la 0.0.3): los mancheguismos, sobre todo para los mayores (`generic_old`, `whisper_old`, `ouch_old`). «Apretar» sin diptongo: apreta, apretes. Y en boca de todos (15/11, sin publicar): «tiés» por «tienes» y «ande» por «dónde/donde». Todo en `guion/palabros.md`, contado con nuestras palabras porque su web es CC BY-NC-ND. José-María Moreno García va en los créditos. Lo comprueba `python tools/run_tests.py palabros`.
