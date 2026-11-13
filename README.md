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

## Varias sesiones en la misma carpeta

- **Coordinación:** antes y después de una prueba completa se avisa a las demás sesiones. Cada una toca solo sus archivos.
- **Archivos de cada sesión:**
  - Texturas de las casas: `casas.gd`, `casas_calles.gd`, `texturas.gd`, `tela.gd`, `tools/bake_godot.py`, `godot/data/map.json` (y el horneado del mapa).
  - Principal: `touch.gd` (controles táctiles) y el preset 1, Android, de `godot/export_presets.cfg`.
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
- **Diseño de Kebab Luis y misiones:** en `guion/kebab_luis_diseno.md` y `guion/misiones_y_puntos_civicos.md`, cada uno con lo construido al final.
