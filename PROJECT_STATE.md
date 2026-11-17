# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Sin publicar

El detalle de cada pieza está en su LEEME de `referencias/` o `tools/`, en `guion/` y en el historial de git.

Nada todavía: todo lo anterior salió en la 0.0.16.

## Versión

- **Publicada:** 0.0.16 (17/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.16 — completa: 798 ok, 0 fallos.
  - **Sistemas:**
    - Las mallas de las casas a mano, fundidas por cuadros (`lotes.gd`): 40.766 → 1.892. En el PC del usuario, al girar la cámara la peor dirección pasa de 10 a 53 fps y la media de 54 a 94 (modos `--giro` y `--quien`). Colores lisos con color de vértice, piezas finas solo hasta 120 m, revoco y madera con un shader que copia su material, texturas de foto con los ejes de cada casa. `--casas-sueltas` lo deja como antes.
    - La carga espera a que acaben los pipelines que Godot compila en segundo plano (`_settle_pipelines`): para los tirones de la primera vez tras instalar.
    - La riña del jamón: el swing de verdad del bate; armas de modelos libres (`assets/motin/`, `tools/blender/armas.py`, bate y cuchillo por el mango, puño americano delante del puño), alzadas junto a la cara en los planos detalle, sin nadie tapando.
    - Feliciano (`feliciano.gd`): siempre en la riña, el primero en sacar el arma; por el convento de las clarisas el resto de la semana, a la puerta del Henry los jueves; eufórico los jueves, contando los días los demás, quejándose de la campana.
    - Teclado del juego QWERTY en el Padrón y las cartas.
  - **Pretil:** la ermita de San Sebastián y su parque (`sebastian.gd`, rehorneado).
  - **Texturas:** la Calle del Buen Suceso entera y la Travesía de las Cruces.
  - El detalle de cada pieza está en el historial de git (este archivo, antes de la 0.0.16).
- **Publicada antes:** 0.0.15 (17/11/2026): escribir con mando, en el móvil y bajo Steam (el Padrón ya no se queda atascado), la A del mando pulsa, el tres en raya con mando.
- **Pendiente:**
  - Texturas:
    - **La calle de la Cruz (`cruz_*`) salió en la 0.0.13 con 31 casas.** Después, ya en X:, quité `cruz_13` y `cruz_17`, cuyo frente quedaba metido en la manzana, y quedaron 29. A `cruz_vg9` y `cruz_21` les puse alero de teja. Rehorneado sin más cambios, y `casas` OK. Las hojas `guion/fotos/tanda34/cruz_1..5.jpg` se mandaron al usuario el 17/11, que dio su «Visto bueno».
    - La travesía del Clavel, que hay que hacer a mano.
    - El repaso de lo que aún no se parece: `guion/repaso_casas.md`.
  - Creador: el resto de la criba de piezas (ropa, sombreros, lo que quiera quitar), cuando el usuario quiera. Lo hecho hasta ahora tiene su visto bueno (17/11).
  - Sistemas: `sentido` falla a veces (coches en contra al dejar conducir al tráfico); ya pasaba antes de los cambios de rendimiento.

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
- Habla (desde la 0.0.3): los mancheguismos, sobre todo para los mayores (`generic_old`, `whisper_old`, `ouch_old`). «Apretar» sin diptongo: apreta, apretes. Y en boca de todos (desde la 0.0.9): «tiés» por «tienes» y «ande» por «dónde/donde» («por donde» también: «ande puedas»). Desde el 17/11 (sin publicar) la prueba vigila todas las reglas de la casa (lé, la'é, l'á, -ao/-ío, pa, to, na, vía, cá, semos, entoavía, enga, mu) en lo que dice cualquiera, salvo `HABLA_FINA` (el alcalde, menús, pantallas, carteles) y lo que va entre «». Todo en `guion/palabros.md`, contado con nuestras palabras porque su web es CC BY-NC-ND. José-María Moreno García va en los créditos. Lo comprueba `python tools/run_tests.py palabros`.
