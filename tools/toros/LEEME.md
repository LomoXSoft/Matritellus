# Herramientas de la Antigua Plaza de Toros

Para `godot/scripts/toros.gd` (noviembre de 2026). Mismo método que el Petril, la plaza y el molino; las herramientas
generales están en `tools/molino/` (`panos.py`, `catastro.py`, `plano.py`) y `tools/plaza/` (`aerea_wmts.py`,
`historico.py`). Medidas y fuentes: `referencias/plaza_toros/LEEME.md`.

- `capturas.py CARPETA` — baja las 23 vistas de Street View con que se midió, de tres épocas: mayo de 2009 (antes de
  la restauración; solo hay desde Vista Alegre), marzo de 2013 y noviembre de 2024. No se guardan (son de Google).
- `vistas_sv.py` — el juego desde esos mismos puntos (vistas `tr_…`, en el marco de la plaza: el centro del ruedo y
  los ejes del mapa) y `hoja` para montar «Street View | juego». Para las vistas de 2013 y 2024 hay que arrancar el
  juego con la plaza restaurada: `python tools/run_tests.py "vistas=…" toros-restaurada --window`.
- `enganche.py` — cómo se enganchó a los archivos compartidos (`world.gd`, `map_data.gd`, `tools/bake_godot.py`,
  `selftest.gd`). Se aplicó una vez; queda como constancia de qué líneas son de la plaza de toros.

## Lo que se aprendió aquí
1. **Un sitio con dos épocas pide las fuentes de cada una**: las ortofotos históricas del IGN (2006 y 2009 antes;
   2012 y 2015 después) y las panorámicas antiguas de Street View, que `panos.py info` da con su fecha. De la época
   vieja solo había panorámicas desde una calle: lo demás de la ruina se deduce de lo restaurado.
2. **Dos estados en un solo sitio**: lo común se construye una vez; cada estado va a un nodo propio con sus sólidos
   (se apunta qué sólidos son de cada uno) y `set_restored` enseña uno y desactiva los sólidos del otro.
3. **Lo que se rompe «al azar» debe romperse igual siempre**: los desperfectos de la ruina salen de una cuenta fija
   por número de contrafuerte, no del azar del motor, para que las fotos y las pruebas no cambien de una vez a otra.
4. **Avisar antes de tocar archivos compartidos y esperar respuesta** si otra sesión puede estar lanzando la prueba
   completa: aquí los enganches entraron 25 segundos antes de que arrancara una, con el mapa aún sin hornear, y mi
   comprobación salió en rojo en su registro.
