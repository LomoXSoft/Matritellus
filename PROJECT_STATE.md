# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Sin publicar

Nada todavía: todo lo anterior salió en la 0.0.12. El detalle de cada pieza está en su LEEME de `referencias/` o `tools/`, en `guion/` y en el historial de git.

## Versión

- **Publicada:** 0.0.12 (16/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.12 — completa: 735 ok, 0 fallos.
  - **Android vuelve a arrancar (Sistemas):** la 0.0.11 se cerraba en la pantalla de carga («Vulkan device was lost»). Durante la carga se dibujaba el pueblo a medio construir detrás de la pantalla negra; ahora no se dibuja nada en 3D (`disable_3d`) hasta que está todo construido. Probado en el Realme RMX5051 del usuario: llega al título.
  - **Texturas:** calle de Jesús y María, 27 entradas (`jym_*`), y las casas de otras calles que dan a ella (Arroyuelo Bajo 42, Reina Sofía 45 y 26, Plaza del Toledano 1).
    - Comparadas con el Catastro, cuyas fotos aquí son buenas; el 30, que no tiene foto, va por Street View 2024. Son todas viviendas.
    - Lo que aún no se parece (también en `guion/repaso_casas.md`):
    - En el `b410` faltan los ojos de buey redondos.
    - El zócalo de piedra blanca de dibujo del 11, el 9 y el 7 sale liso.
    - Los toldos verdes del `b015` salen como rayas finas.
    - Bake: 27 casas nuevas; solo cambian las piezas de `domingo_23`, `clara_1a` y `tinf_jm19`. Un nudo de `clr` baja de 3,1 a 2,5. `casas solo=jym_`: OK. Pretil lo ha comprobado con `toledano` (4/4): `jym_tol1` no pisa la plazuela. Hojas en `guion/fotos/tanda34/jym_1..5.jpg`.
  - **Texturas:** calle del Romero, 29 entradas (`romero_*`), con las casas de otras calles que dan a ella (Delicias 16, Roma 7).
    - Comparadas con el Catastro, cuyas fotos son buenas, y con Street View 2024 en la casa nueva de la calle Roma (2024, sin foto) y en el 24.
    - Los portones de madera clara de tono `b8904a` o `a8803a` salen amarillos. En las calles nuevas van ya en `7a5a38`; los de calles aprobadas quedan en la lista del repaso.
    - Bake: 29 casas nuevas; cambian las piezas de `stana_9`, `valencia_7`, `valencia_8`, `valencia_10`, `regidor_7` y `rafael_6`. Un nudo de `clr` baja de 3,5 a 2,5. `casas`: OK. Hojas en `guion/fotos/tanda34/romero_1..6.jpg`.
- **Publicada antes:** 0.0.11 (16/11/2026): el rendimiento (la rejilla de los suelos: de 65 a 84 fps en la Plaza), el salto, los niños, los chismes, el Padrón, el creador nuevo y tu casa, la rotonda, el IES, el MasAhorro, la Noche, el banco y la copistería, y muchas calles.
- **Pendiente:**
  - Texturas:
    - El visto bueno de Jesús y María, el Romero, Santa María, Toledo, Parto, Mirador, Ejon, San Francisco, Teniente Infante y la Rosa vieja. El usuario quiere terminar antes el casco urbano. Cervantes y la travesía de Zaragoza tienen ya su «Visto bueno» (16/11). La calle del Clavel está entera y aprobada.
    - La travesía del Clavel, que hay que hacer a mano.
    - El repaso de lo que aún no se parece: `guion/repaso_casas.md`.
  - Creador: la criba de piezas que hará el usuario.
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
- Habla (desde la 0.0.3): los mancheguismos, sobre todo para los mayores (`generic_old`, `whisper_old`, `ouch_old`). «Apretar» sin diptongo: apreta, apretes. Y en boca de todos (desde la 0.0.9): «tiés» por «tienes» y «ande» por «dónde/donde» («por donde» también: «ande puedas»). Todo en `guion/palabros.md`, contado con nuestras palabras porque su web es CC BY-NC-ND. José-María Moreno García va en los créditos. Lo comprueba `python tools/run_tests.py palabros`.
