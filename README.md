# Matritellus

Juego de mundo abierto hecho en **Godot 4.7.2** sobre Madridejos (Toledo). Las calles y casas salen de datos reales (OSM, Catastro, IGN) y de fotos. Los textos van en manchego, con su traducción al inglés en `godot/scripts/loc.gd`.

Repositorio privado: https://github.com/LomoXSoft/Matritellus

## Carpetas

| Carpeta | Qué hay |
|---|---|
| `godot/` | El proyecto de Godot: `scripts/` (todo el código), `assets/`, `data/map.json` (el pueblo horneado), `radio/` (emisoras) |
| `tools/` | Scripts de Python que construyen el pueblo, las texturas, los sonidos, los iconos y los instaladores |
| `guion/` | Diseño y guion: misiones, Puntos Cívicos, Kebab Luis, palabros, árbol de relaciones (`relaciones.html` / `.json`) |
| `referencias/` | Fotos de los sitios construidos a mano (los vídeos de recorrido no se suben: pasan de 100 MB) |
| `dist/` | Lo que se construye (instaladores). **No se sube al repo**: va como descarga de cada versión |

## Jugar y probar

- Jugar desde el proyecto: `play.bat`. Usa Godot en `C:\Users\luis_\Fable\tools\godot\`.
- **Forma de lanzar las pruebas:** `python tools/run_tests.py [modo …] [--window] [--repeat N] [--timeout S]`. Es una sola llamada que espera al final, guarda el registro completo en `logs/` y saca un resumen corto. Si hay un error de sintaxis, corta enseguida. Estado y normas de trabajo en `PROJECT_STATE.md`.
- Prueba completa: tarda unos 10 minutos; lánzala en segundo plano.

  ```bash
  C:/Users/luis_/Fable/tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path godot --fixed-fps 60 -- --selftest
  ```

  Debe terminar en `SELFTEST OK (0 failed)`.
- Pruebas parciales: en lugar de la completa se pasa uno de estos modos.
  - Sistemas: `--selftest --derrape` (incluye claxon), `--emisoras` (radio y registro de tirones), `--grua`, `--kebab`, `--comida`, `--sabotaje`, `--motin`, `--civicos`, `--creator`, `--menu`.
  - Recreativos: `--selftest --recress` (la misión entera), `--llamadas`, `--marcas`, `--tokken` (el minijuego; con `--balance`, todos contra todos).
  - Otros: mira `godot/scripts/selftest.gd` (`has("--...")`).
  - Fotos: añade `--shots`, sin `--headless` y con `--window`. Se guardan en `godot/shots/`.
- Si añades archivos nuevos (imágenes, OGG…), impórtalos antes de probar:

  ```bash
  C:/Users/luis_/Fable/tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path godot --import
  ```

## Instaladores (siempre los tres)

| Plataforma | Comando | Sale en |
|---|---|---|
| Windows | `python tools/make_installer.py` | `dist/Matritellus-Instalador.exe` |
| Android | `python tools/make_apk.py X.Y.Z` | `dist/Matritellus.apk`, firmado y con su versión |
| Linux / Steam Machine | `python tools/make_linux.py` | `dist/Matritellus-Linux.tar.gz` |

- **Versión de Android:** `make_apk.py X.Y.Z` (desde la 0.0.4) escribe la versión en `godot/project.godot` (`application/config/version`) y en el preset de Android: el nombre que ve el móvil (`0.0.4`) y el número que le dice qué versión es más nueva (X·10000 + Y·100 + Z: la 0.0.4 es el 4). Sin número, usa el que ya hay en `project.godot`. El número solo puede subir: si baja, el móvil no deja instalar encima.
- **Firma de Android:** la clave está **fuera del repo**, en `C:/Users/luis_/Fable/tools/android`. Su contraseña nunca se escribe en ningún archivo del proyecto.
- **Linux:** el paquete lleva `instalar.sh`, `desinstalar.sh` y un `LEEME.txt`. Para jugar en la Steam Machine: descomprimir, ejecutar `instalar.sh` y en Steam: Añadir un juego que no es de Steam.

## Cómo se publica una versión

1. **Prueba completa en verde.** Si hay otras sesiones trabajando en la carpeta, avísalas antes: no se lanzan dos pruebas completas a la vez.
2. **Los tres instaladores**, construidos desde ese mismo estado. El de Android, con el número de la versión: `python tools/make_apk.py X.Y.Z`.
3. **Commit y etiqueta.** La versión se numera `X.Y.Z` y la etiqueta es `vX.Y.Z`.

   ```bash
   git add -A
   ```

   ```bash
   git commit -m "Matritellus X.Y.Z"
   ```

   ```bash
   git tag -a vX.Y.Z -m "Matritellus X.Y.Z"
   ```

   ```bash
   git push origin main --tags
   ```

4. **Versión en GitHub con los tres instaladores como descargas.**
   - Se copian a `dist/vX.Y.Z/` con nombres versionados: `Matritellus-X.Y.Z-Windows.exe`, `-Android.apk`, `-Linux.tar.gz`.
   - Después:

     ```bash
     gh release create vX.Y.Z --repo LomoXSoft/Matritellus --title "Matritellus X.Y.Z" --notes "..." Matritellus-X.Y.Z-Windows.exe Matritellus-X.Y.Z-Android.apk Matritellus-X.Y.Z-Linux.tar.gz
     ```

   - Las novedades, en castellano.

Reglas:

- **Cuenta:** `gh` tiene la sesión iniciada como **LomoXSoft**. Los commits llevan el correo privado de GitHub de esa cuenta (`git config user.email`), nunca un correo personal.
- **Rama:** se trabaja en `main`. Ninguna sesión hace commit, push ni cambio de rama sin que el usuario lo pida.
- **Archivos grandes:** nada de más de 100 MB en la historia (GitHub lo rechaza). Los instaladores van siempre como descargas de la versión.
- **Tamaño:** la 0.0.1 ocupa unos 375 MB comprimidos.

Versiones:

| Versión | Fecha | Notas |
|---|---|---|
| 0.0.1 | 13/11/2026 | Primera con control de versiones. https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.1 |
| 0.0.2 | 13/11/2026 | Grafitis de las seis peñas, dos peñas nuevas, coches que no vuelcan, límite del mapa con persecución, sombreadores precompilados, Galaxy Recress, centralita y marcadores, casas nuevas de la Alameda y Matías Pérez. https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.2 |
| 0.0.3 | 14/11/2026 | Tokken 9 (el minijuego de lucha de las máquinas), sala y fachada de los Recress con máquinas de Sketchfab y horario, misión cumplida solo con el sello, seis canciones y logos nuevos en la radio, habla de los mayores, la grúa ya no sale encima de un coche. https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.3 |
| 0.0.4 | 14/11/2026 | La pausa para el mundo (coches y sonido), límite del mapa a 1950 m (la Cooperativa de la primera misión quedaba fuera), conductor visible en el Julietta, caja de choque del Z15 a su forma, derrapes que ya no suenan conduciendo normal, pedales en Android, joystick que camina poco a poco, el bate de Henry, título con calma, ajustes en Gráficos/Sonido/Gameplay con resolución dinámica, FSR, LOD y occlusion culling, sexta emisora (Koka y Ná FM) y diez canciones más; el APK lleva su número de versión. https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.4 |
| 0.0.5 | 14/11/2026 | Convento de San Francisco («Iglesia del Petril»), toro de Osborne en la A-4, el sol sale por el este (salía por el oeste), sombras de día sin tono azul en el blanco, sabotaje sin falsos «te ha visto» al recular la furgoneta. https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.5 |
| 0.0.6 | 15/11/2026 | La Chiki y las pintadas como misión, Plaza del Ayuntamiento, Molino del Tío Gerardo y Antigua Plaza de Toros hechos a mano, calles Real y del Salvador peatonales y empedradas, casas de Colón y del Salvador, mapa grande con joysticks, ajustes en tres páginas con opciones gráficas nuevas y modo desarrollador, título, bate, salto, madrugada, sentido único en calles estrechas, pausa completa. https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.6 |

## Varias sesiones en la misma carpeta

- **Coordinación:** antes y después de una prueba completa se avisa a las demás sesiones. Cada una toca solo sus archivos.
- **Archivos de cada sesión:**
  - Texturas de las casas: `casas.gd`, `casas_calles.gd`, `texturas.gd`, `tela.gd`, `tools/bake_godot.py`, `godot/data/map.json` (y el horneado del mapa).
  - Principal: `touch.gd` (controles táctiles) y el preset 1, Android, de `godot/export_presets.cfg`.
  - Recreativos: `recress.gd`, `recress_sala.gd`, `llamadas.gd` (la centralita), `marcas.gd` (marcadores con foto y flecha), `godot/assets/recress/`, `tools/make_pantallas.py` (las peleas de las pantallas, desde los GIF de `referencias/recress/`) y `tools/make_eureka.py`.
  - Tokken 9 (el minijuego de las máquinas; `guion/tokken9.md`): `tokken.gd`, `tokken_letras.gd`, `tokken_datos.gd` (lo escribe la herramienta: no se edita a mano), `godot/assets/tokken/` y `tools/make_tokken.py` (recorta luchadores y escenarios de los GIF; necesita `opencv-python-headless`).
  - Kebab Luis / sistemas: clientes, comida, sabotaje, motín, derrapes, sonidos, grafitis de las peñas (`props.gd`, `tools/make_penas.py`), límite del mapa (`limite.gd`), precalentado de sombreadores (`calentar.gd`), iconos de botones (`tools/make_botones.py`).
- **Presets de exportación:** el 0 es Windows, el 1 Android y el 2 Linux.

## Datos útiles

- **Sonidos de vehículos:**
  - Grabaciones CC0 de BigSoundBank y Freesound. Créditos en `tools/sonidos_origen/CREDITOS.txt`.
  - Se recortan con `tools/sonidos_vehiculos.py` y quedan en `godot/assets/audio/vehiculos/`.
  - Cada marca tiene motor y cláxones propios (`sfx.gd`: `ENGINES`, `HORNS`).
- **Iconos de botones:**
  - Los dibuja `tools/make_botones.py` en `godot/assets/botones/`: teclado, ratón, Xbox/Steam y PlayStation.
  - En los textos se escriben como `<interact>`, `<ok>`, `<esc>`, `<horn>`… y `Controls.fill` los cambia por el icono del aparato que tengas en la mano.
  - Las etiquetas que los muestran son `RichTextLabel` (`hud.rt`).
  - En pantalla táctil se escriben sin icono.
- **Tirones:**
  - El juego apunta cada fotograma de más de 250 ms en `user://tirones.txt`: qué parte del juego tardó, cuántos sombreadores se compilaban, memoria y fase.
  - En Linux: `~/.local/share/godot/app_userdata/Matritellus/tirones.txt`. En Windows: `%APPDATA%\Godot\app_userdata\Matritellus\`.
  - Pendiente: los tirones a ~1 FPS que se vieron en la Steam Machine. Hay que mirar ese archivo tras jugar allí, y si pasa también en la segunda partida (en la primera los sombreadores aún no están en caché).
- **Vehículos de servicio:**
  - La grúa yendo a un aviso y la policía persiguiendo no frenan por los vecinos: los atropellan, sin culpa para el jugador (`traffic.gd: on_duty`, `game.gd: _duty_hits`).
  - Una futura ambulancia solo necesita `e["duty"] = true`.
- **Radio:** las emisoras suenan siempre de fondo; cada una guarda cuándo empezó su canción (`ambience.gd: _radio_live`).
- **Ajustes (desde la 0.0.4):**
  - Tres páginas: Gráficos, Sonido y Gameplay (idioma, campo de visión, controles).
  - Opciones nuevas de Gráficos:
    - **Resolución dinámica** (`game.gd: _dynres`): baja la escala 3D si caen los FPS.
    - **Escalado espacial:** bilineal, FSR 1 o FSR 2. En Android, que usa el renderizador Mobile, solo hasta FSR 1: `Settings.upscalers()`.
    - **LOD automático:** el umbral de LOD del motor, y los detalles pequeños se dibujan al 70 % de distancia (`Parts.detail`).
    - **Occlusion culling:** los muros del pueblo hacen de oclusores (`game.gd: _make_occluders`).
- **Título:** el nombre en cursiva es una imagen que dibuja `python tools/make_titulo.py`, con Segoe Script Negrita de Windows; se sube la imagen, nunca la fuente. Secuencia en `game.gd: _after_intro` y `_title_go`. Prueba: `--selftest --titulo --shots --window`.
- **El bate:** con el recado del menú de Josefa hecho (`stats.menu_done`, el del jamón), el golpe a pie es de bate y tira al suelo a quien tienes delante (`game.gd: has_bat`, `_bat_swing`; animación en `chara.gd: swing_bat`). Fotos: `--selftest --bate --window`.
- **Android al volante:** «Acelerar» es el botón grande. El freno manda «atrás», que frena si vas hacia delante y da marcha atrás si estás parado, y su texto cambia de Freno a Atrás. El joystick solo gira (`touch.gd`).
- **Fotos de coches:** `--selftest --conductores --window [--solo=edison]` saca cada coche con tu personaje (con gorra) al volante y su caja de choque. `--vidrios=edison` cuenta los colores de la parte alta de la carrocería, para saber de qué color tiene las ventanas.
- **Misión cumplida:**
  - Se avisa solo con el sello ¡APAÑAO! (`hud.stamp(Loc.t("stamp_done"))`) y el dinero que sube en la pizarra (`_refresh_counts`).
  - No lleva cartel naranja: el usuario lo quitó el 14/11/2026.
  - Si la pantalla está en negro (al salir de una escena), el sello espera a que se aclare.
- **Pruebas a la vez:** dos pruebas completas al mismo tiempo comparten `user://` (las partidas de prueba) y pueden pisarse. Se lanzan de una en una, avisando a las demás sesiones.
- **Límite del mapa:** círculo de 1950 m alrededor de (51, −33), y nunca más allá de 80 m antes del borde del mapa construido. La prueba `--limite` comprueba que todos los sitios de las misiones, los talleres y los lugares con nombre quedan 150 m dentro. Fuera, 30 s de aviso en rojo; luego persecución con Pitufos y Tricornios, y cada 30 s fuera un coche más y +5 % de velocidad (`limite.gd`, `police.boost`, `car.speed_boost`).
- **Precalentado de sombreadores:** la primera vez de cada versión en cada gráfica (`calentar.gd`, clave `warm` de los ajustes). Si un día se dibujan cosas nuevas, se sube `VERSION` en `calentar.gd`. Para medirlo: `--selftest --sombreadores --calentar --window` (sin `--headless`).
- **Diseño de Kebab Luis y misiones:** en `guion/kebab_luis_diseno.md` y `guion/misiones_y_puntos_civicos.md`, cada uno con lo construido al final.
