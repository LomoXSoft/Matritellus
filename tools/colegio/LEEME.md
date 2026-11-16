# Herramientas del viejo colegio (avenida de Juan Carlos I)

Con esto se midió, se preparó el mapa y se comprobó `godot/scripts/colegio.gd` (noviembre de 2026). Qué es cada cosa,
las fuentes y lo aproximado: `referencias/colegio_viejo/LEEME.md`.

## Qué hay
- `capturas.py CARPETA [nombre…]` — baja las 64 vistas de Street View. No se guardan en el repositorio.
- `contactos.py CARPETA SALIDA nombre…` — varias fotos en una hoja con su nombre: para repasarlas deprisa.
- `medir.py CARPETA NOMBRE PLANO px,py…` / `… fit px,py=x…` — de píxel a metros sobre la fachada sur, y ajuste de la
  cámara a puntos conocidos. PLANO: 0 las torres, -1.88 el cuerpo.
- `planta.py SALIDA [x0 z0 x1 z1 [zoom]]` — la foto aérea bajo una cuadrícula en metros del mapa, con el Catastro.
- `vistas.py CARPETA NOMBRE…` — el juego desde donde estuvo Street View.
- `hojas.py [CARPETA]` — las hojas de `guion/fotos/colegio_viejo/`.
- `placa.py [SALIDA]` — pinta la placa de azulejo con el nombre, según la foto de Luis.
- `enganche.py` — lo que añade a `bake_godot.py`, `map_data.gd`, `world.gd` y `selftest.gd`; ya aplicado. No hace nada
  al importarlo: sus cambios al horneado están en `BAKE_EDITS`.
- **`ensayo.py`** — ensayar un horneado sin tocar el mapa y comparar dos mapas:
  `python tools/colegio/ensayo.py bake SALIDA.json [con]` (ejecuta el `bake_godot.py` del disco y escribe en otro
  sitio; con `con`, aplicando antes en memoria los cambios de `enganche.py`) y
  `python tools/colegio/ensayo.py diff VIEJO.json NUEVO.json x z radio`. Sirve para cualquier horneado.

## Lo que se aprendió aquí
1. **Las fechas antiguas de Street View no están tomadas donde la de 2024.** `panos.py` da para todas el sitio de la
   cámara actual; la de marzo de 2013 estaba a 4,6 m. Hay que ajustarla (`medir.py … fit`) con puntos de planos
   conocidos (aquí, las esquinas de las torres).
2. **Buscar la fecha en que se ve.** En 2024 los árboles tapan la fachada; en marzo de 2013 están pelados.
3. **El horneado es determinista y se puede ensayar.** Horneando el script tal cual sale un archivo idéntico al mapa
   del disco; así se sabe antes de tocar nada qué cambia, y que nadie tiene cambios a medias. Al quitar o añadir una
   parte, unos 440 contornos de otras manzanas salen hasta 0,3 m distintos: es la simplificación arrancando en otro
   vértice, no un cambio real (los muros que se dibujan no cambian).
4. **Dos horneados seguidos de dos sesiones**: cada uno hornea encima del otro, en orden, con su diff; no mezclar.
5. **Los cajones de mampostería** son lo que da el aire neomudéjar: `_boxes()` reparte cajas con un machón de ladrillo
   entre una y otra, y `masonry()` las recorta alrededor de los huecos. Con bandas corridas no se parecía.
6. **Una pista sobre terreno en cuesta**: un plano ajustado por mínimos cuadrados al terreno al pie de la fachada y a
   lo largo de la verja, con la pendiente limitada, y levantado hasta librarlo (`_fit`, `_cy`).
7. **Un suelo sobre el terreno tal cual** (`_drape`): triangular y partir cada triángulo hasta 2,4 m de lado, cada
   vértice a la altura del terreno. Para la acera en damero, una textura de 2 × 2 píxeles hecha en el momento.
8. Al comparar con Street View, recortar la foto del juego por el centro (es más ancha): estirarla engaña.
9. **`bar(a, b, ancho, alto)`**: el primer grosor es el horizontal perpendicular al recorrido; en una pared, el que
   sale de ella. Para una barra plana pegada a la pared va primero el fino (`0.03, 0.05`), no al revés: al revés
   salen aletas de canto. Y una celosía que cubre un paño no puede pasar por delante de lo que hay en él (puerta,
   placa): se pinta solo donde se ve.

## Pruebas
`python tools/run_tests.py colegio`: 18 fotos (`godot/shots/colegio_*.png`) y tres comprobaciones (está construido,
con su placa, sus árboles, sus dos puertas y la marquesina; sus fachadas y su verja paran; nada suyo pisa una calzada, el mapa sabe que está y
la pista queda sobre la acera de la avenida). Y `relief` y `caridad`.
