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
| Android | `python tools/make_apk.py` | `dist/Matritellus.apk`, firmado |
| Linux / Steam Machine | `python tools/make_linux.py` | `dist/Matritellus-Linux.tar.gz` |

- **Firma de Android:** la clave está **fuera del repo**, en `C:/Users/luis_/Fable/tools/android`. Su contraseña nunca se escribe en ningún archivo del proyecto.
- **Linux:** el paquete lleva `instalar.sh`, `desinstalar.sh` y un `LEEME.txt`. Para jugar en la Steam Machine: descomprimir, ejecutar `instalar.sh` y en Steam: Añadir un juego que no es de Steam.

## Cómo se publica una versión

1. **Prueba completa en verde.** Si hay otras sesiones trabajando en la carpeta, avísalas antes: no se lanzan dos pruebas completas a la vez.
2. **Los tres instaladores**, construidos desde ese mismo estado.
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
- **Misión cumplida:**
  - Se avisa solo con el sello ¡APAÑAO! (`hud.stamp(Loc.t("stamp_done"))`) y el dinero que sube en la pizarra (`_refresh_counts`).
  - No lleva cartel naranja: el usuario lo quitó el 14/11/2026.
  - Si la pantalla está en negro (al salir de una escena), el sello espera a que se aclare.
- **Pruebas a la vez:** dos pruebas completas al mismo tiempo comparten `user://` (las partidas de prueba) y pueden pisarse. Se lanzan de una en una, avisando a las demás sesiones.
- **Límite del mapa:** círculo de 1100 m alrededor de (51, −33). Fuera, 30 s de aviso en rojo; luego persecución con Pitufos y Tricornios, y cada 30 s fuera un coche más y +5 % de velocidad (`limite.gd`, `police.boost`, `car.speed_boost`).
- **Precalentado de sombreadores:** la primera vez de cada versión en cada gráfica (`calentar.gd`, clave `warm` de los ajustes). Si un día se dibujan cosas nuevas, se sube `VERSION` en `calentar.gd`. Para medirlo: `--selftest --sombreadores --calentar --window` (sin `--headless`).
- **Diseño de Kebab Luis y misiones:** en `guion/kebab_luis_diseno.md` y `guion/misiones_y_puntos_civicos.md`, cada uno con lo construido al final.
