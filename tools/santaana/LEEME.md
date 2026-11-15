# Herramientas del convento de Santa Ana (las Clarisas, calle de las Monjas)

Con esto se midió y se comprobó `godot/scripts/santaana.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo
aproximado: `referencias/convento_santa_ana/LEEME.md`.

## Qué hay
- `capturas.py CARPETA [nombre…]` — baja las vistas de Street View con que se midió (24 cámaras, 40 vistas).
- `vistas.py NOMBRE…` — el juego fotografiado desde donde estuvo Street View: imprime el `vistas=…` para
  `python tools/run_tests.py "$(python tools/santaana/vistas.py M5_f M6_f M7_sw M5_sw)"` (salen `vista_sv_<nombre>.png`).
- `hojas.py CARPETA_SV` — las dos hojas de `guion/fotos/convento_santa_ana/`.
- `enganche.py` — lo que el convento añade a `selftest.gd` (el modo `--santaana`, `_santaana_checks`); ya aplicado.
- En `tools/molino/panos.py` hay una orden nueva: `cerca ID x z [radio]` anda desde una cámara conocida hasta la más
  cercana al punto y lista todas las de alrededor con sus pasadas antiguas. Es lo primero que hay que lanzar en un sitio.

## Lo que se aprendió aquí
1. **El nombre que da el usuario puede no ser la calle.** «Convento de Santa Ana» no está en la calle Santa Ana: se
   buscó en Google Maps (`https://www.google.com/maps/search/…`) y las coordenadas salen de la dirección de la ficha.
2. **Poner el sitio sobre las calles del JUEGO antes de medir** (otra vez): la calle de Santiago Apóstol del juego pasa
   3 m al sur de la real y atravesaba el final de la iglesia. El edificio se recorta a la calle del juego.
3. **Una parcela que deja de levantarse deja de estrechar sus calles.** El horneado mide el ancho libre de cada nudo
   (`clr`) contra los bloques del mapa; sin el convento, Santiago Apóstol pasaba de 2,3 a 5,7 m libres y su calzada se
   ensanchaba contra el muro nuevo. Arreglo: el horneado añade la huella de lo que construye el script
   (`santaana_built`) a lo que cuenta para `clr`, sin hacerla bloque del mapa. Mirar siempre `clr` en el diff.
4. **Calle empedrada con tráfico**: `PAVED_STREETS` en el horneado parte el tramo como calle propia que sigue siendo
   k 0 con `"paved": 3`; `empedrado.gd` pone ladrillo de casa a casa (0,185) y adoquín en el centro (0,19) por encima
   del asfalto (0,18) y por debajo de la pintura de los pasos (0,2). Tráfico, aparcados y rutas no cambian.
5. **Los ladrillos del juego se tiñen multiplicando una textura rojiza**: para un ladrillo claro hay que subir verde y
   azul (aquí 1,21 / 1,32 / 1,5); con el azul solo sale rosa, con el verde solo sale mostaza. Comparar siempre contra
   la foto desde el mismo sitio.
6. **Lo alto que está detrás de un alero no se ve desde una calle estrecha**: la torre y la torrecilla hubo que
   acercarlas a la fachada y subirlas para que asomen como en las fotos.

## Pruebas
`python tools/run_tests.py santaana`: 12 fotos (`godot/shots/santaana_*.png`) y tres comprobaciones (está construido;
sus muros paran por todo el contorno, nada pisa una calzada y el mapa sabe que está ahí; la calle de las Monjas va
empedrada delante y sigue siendo de coches, y pasado el cruce vuelve el asfalto). Tras rehornear, además `relief`.
