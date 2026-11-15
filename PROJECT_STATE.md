# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Versión

- **Publicada:** 0.0.7 (15/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.7 — completa de las 06:41: 616 ok, 0 fallos. Lleva:
  - El puente del Arroyuelo Medio rehecho a mano (Pretil; `puente.gd` sobre `obra.gd`), con el visto bueno del usuario y sin obreros: no quiere personajes nuevos por ahora. Mantiene lo que usa el resto del juego (`p`, `u`, `across`, `hw`, `half` = 2,6, `open` = +1, `seg`, `top`, `spot()`, `kerb()` = hw + 0,75, `dress()`, `close_off()`, `placard()`). La obra de demolición (`bridge.set_works`, máquinas CC0 en `godot/assets/obra/`) está hasta entregar las firmas y se va sola la primera mañana después, con el jugador a más de 140 m y sin mirar (`stats["obra_h"]`, `stats["obra_fuera"]`); `--puente-limpio` arranca sin ella. El cauce hasta la calle del Santo no tiene tráfico.
  - La escuela infantil José de Calasanz, en la calle del Palo (Pretil; `calasanz.gd`, `world.calasanz`). Sin personajes y sin interior; el usuario aún no ha dado su veredicto. Su patio allana el cruce del Arroyuelo con el Palo.
  - Casas nuevas (Texturas): la calle de la Palma y el primer tramo de Cervantes (21, con el visto bueno del usuario) y Ramón y Cajal (25, hojas en `guion/fotos/tanda9/`, sin veredicto). La Cocina de Henry pasa a su casa real, la Palma 3 B (`henry.gd`).
  - Entran también los datos del Catastro de la tanda siguiente de Texturas (Oliva y Juan Carlos I: `tools/casas/oj_pendiente.json` y sus carpetas). El juego aún no los usa.
- **Publicada antes:** 0.0.6 (15/11/2026): Plaza del Ayuntamiento, Molino del Tío Gerardo (el molinero espera en la era, `MILLER_AT`), Antigua Plaza de Toros (en ruina; `world.toros.set_restored(true)`, `--toros-restaurada`), las calles Real y del Salvador peatonales (`PAVED`, `PAVED_SPANS`, `empedrado.gd`), casas de Colón y del Salvador, La Chiki y las pintadas, y la lista grande del usuario del 15/11.
- **Sin publicar:** nada.

## Cómo trabajar (normas del usuario, 15/11/2026)

- **Pruebas:** siempre con `python tools/run_tests.py <modo>`. Es una sola llamada que espera al final, con tiempo límite. Guarda el registro en `logs/` y devuelve un resumen.
  - Tras cada cambio, la prueba del modo afectado (`--selftest --<modo>`; la lista está en `selftest.gd`, `_run`).
  - La prueba completa (`python tools/run_tests.py`), solo en los hitos, antes de publicar o si lo piden.
  - Nada de vigilar pruebas largas a base de llamadas repetidas.
  - Los modos de fotos (`firmas`, `petril`, `molino`…) van con `--window`: sin ventana no escriben nada y se quedan esperando. El lanzador los corta al llegar a su tiempo límite, aunque Godot no escriba nada (lee en un hilo aparte).
- **Fallos intermitentes:** se investigan uno a uno, con el modo y su `--traza`, y `--repeat N` si hace falta.
- **No releer** archivos ni fotos que no han cambiado.
- **Sesiones a la vez:** cada una toca sus archivos. Se avisa antes de una prueba completa. Para publicar se congela la carpeta.
  - Todas las sesiones trabajan en la misma carpeta, sin carpetas de trabajo (git worktree) separadas: lo decidió el usuario el 15/11. Cada una toca sus archivos y avisa antes de tocar los de otra.

## Fallos conocidos

- **Grúa:** a veces se queda parada a unos 130 m del coche, en la esquina de (871, 254) o (880, 247), detrás de un coche aparcado. Está atenuado con `_room_at` y `_clear_parked`; vigilarlo.
- **Sabotaje:** la furgoneta se atascaba en calles estrechas, sobre todo en (-472, -340), tramos 856-858. Ahora tiene la ruta cerrada; vigilarlo en las completas.
- **Turbo del Julietta:** la segunda pasada se quedaba a 0 km/h de vez en cuando; ahora la prueba usa un coche nuevo.
- **Pruebas con ventana:** `--menu`, `--titulo --shots`, etc. La ventana ya no coge el teclado (`WINDOW_FLAG_NO_FOCUS`).
- **Mirada, «talk to them and they stand still to answer»:** falló una vez en una completa (14/11) y no se ha repetido (`mirada`, `mirada viejo`, `mirada antes` y la completa de la 0.0.3 pasan). Si vuelve, el mensaje dice voz, estado, si el diálogo sigue abierto y cuánto se movió; con «dialogue none», mirar las llamadas de la centralita (desde la 0.0.3 una llamada ya no corta una conversación, que seguramente era la causa).
- **Sin probar en dispositivos reales:** móvil y Steam Machine. Si hay tirones en la Steam Machine, pedir `tirones.txt`.
- **Tokken 9** (publicado desde la 0.0.3; `guion/tokken9.md`): nadie lo ha jugado con las manos. La dificultad del alcalde y de Katakumba69 sale solo de la simulación (`python tools/run_tests.py tokken balance`); cuando el usuario diga cómo lo nota, se retoca `AI["alcalde"]` en `tokken.gd`, sin quitarle que baje la guardia tras el primer golpe. Los botones del móvil y el mando, sin probar.

## Decisiones recientes

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
- Habla (desde la 0.0.3): los mancheguismos, sobre todo para los mayores (`generic_old`, `whisper_old`, `ouch_old`). «Apretar» sin diptongo: apreta, apretes. Todo en `guion/palabros.md`, contado con nuestras palabras porque su web es CC BY-NC-ND. José-María Moreno García va en los créditos. Lo comprueba `python tools/run_tests.py palabros`.
