# Referencia: la ermita de San Sebastián y su parque

Pedida por Luis el 18-11-2026, con una captura de Google Maps (en rojo la ermita y en verde el parque). Sus palabras:
«Siguiente trabajo. La hermita de san Sebastián y el parque que la rodea (aproximadamente en rojo y verde
respectivamente)».

El modelo es `godot/scripts/sebastian.gd` (sobre `obra.gd`), en `world.sebastian`. Su marco tiene el origen en la
esquina suroeste de la fachada: x va a lo largo de la fachada (hacia el estesureste), z sale de ella (hacia el
sursuroeste) e y = 0 es el suelo ante la puerta. Las herramientas están en `tools/sebastian/`.

## Fuentes
- **Catastro**: la ermita es la parcela `4297712VJ5649N` («servicios públicos», 1975, 424 m²), con tres partes:
  - la 1 es la nave, con sus naves laterales y el cuerpo bajo de la esquina noreste;
  - la 2 es la capillita cuadrada de la terraza;
  - la 3 es el pórtico ante la puerta.
  - Para sacarlas: `python tools/sebastian/manzana.py PLANO.png partes=4297712`.
- **Ortofoto** (PNOA): `tools/ign/sebastian.jpg`, de `python tools/fetch_ortho.py sebastian -190 -520 -20 -370 0.15`.
  De ella salen la plaza redonda (centro en (−112, −450,8), igual que el anillo de sendas de OpenStreetMap), las sendas
  y los árboles.
- **Street View** (`tools/sebastian/capturas.py`; las fotos son de Google y no se guardan aquí):
  - por la Calle del Santo ante la fachada y el costado, en noviembre de 2024, 2021 y 2009;
  - alrededor del parque por la vuelta de la Calle del Santo, en 2024 y 2009;
  - por el norte, en 2019 y 2013.
- **Una foto 360 de un particular** junto al pórtico: puerta, pórtico, explanada, plaza y pérgola. No hay más dentro del
  parque.
- **El terreno del juego**: `python tools/sebastian/alturas.py [x,z ...]` da las alturas en el marco de la ermita.
  - Baja hacia el sur unos 9 cm por metro y algo hacia el este.
  - A lo largo de la nave sube 1,5 m hacia el norte.

## Lo que lleva
- **La ermita**:
  - Blanca, con zócalo color salmón.
  - La nave es más alta que sus dos naves laterales, con ventanucos arriba en sus muros.
  - La fachada da al sursuroeste. La puerta, de cuarterones, va entre dos farolillos, bajo un pórtico de dos columnas
    gruesas de granito con tejado a tres aguas y madera vista.
  - Encima de la fachada, la espadaña con su campana, su tejadillo y su veleta con cruz.
  - El cuerpo bajo de la esquina noreste, junto a la calle.
- **La capillita** de la terraza: cuadrada, con columnas de granito embutidas en las esquinas y en el lado de la calle,
  celosías de baldosín blanco, puerta de madera al sur y tejado a cuatro aguas.
- **La terraza junto a la calle**:
  - Elevada unos 0,8 m sobre la calle, con muro salmón, albardilla y verja de hierro.
  - Su suelo sube con la calle.
  - Tres escalones blancos para subir desde la fachada; bancos, un ciprés y macetas.
  - Abajo, en la acera, un arriate de rosales.
- **La pérgola**:
  - Sale del pórtico hacia el oeste a lo largo de la fachada y dobla rodeando el norte de la plaza redonda.
  - Dos filas de columnas de granito cada 3 m, vigas y listones.
  - Hiedra crecida en pilares.
- **La plaza redonda**:
  - De baldosa gris con un anillo rojo y la fuente baja en el centro, con su pilar y su taza.
  - El terreno del juego cae casi 2 m a lo ancho de la plaza. Con el suelo a nivel, el césped la atravesaba por el
    norte (Luis, 17-11: «Aquí el césped clippea un poco, quitando eso de 10»). Ahora el suelo es un plano que cae hacia
    el mismo lado, pero menos (`SQ_K` = 0,6 de la pendiente), y siempre queda por encima del terreno. Las gradas del
    norte se quitaron: en el juego no caben.
  - Un borde de granito la rodea donde queda sobre el terreno, con escalones donde llegan las cuatro sendas del mapa
    (a 5°, 56°, 141° y 187°).
- **El parque**:
  - El césped y las sendas son los del mapa.
  - Árboles: álamos blancos, pinos, olmos, palmeras canarias, palmitos y olivos.
  - Farolas, bancos, la fuente de piedra junto a la senda del suroeste, el monumento de la esquina y la bandera.

## Pruebas
`python tools/run_tests.py sebastian`: fotos de la fachada, el costado, la terraza, la plaza y el parque, y desde el aire.

Hojas para Luis: `python tools/sebastian/hojas.py CARPETA_SV CARPETA_360`, en `guion/fotos/sebastian/` (la hoja de la foto
360 va solo al scratchpad, porque es de un particular).

## Hecho
- El rehorneado (`SEBASTIAN_RC` en `tools/bake_godot.py`, con `tools/sebastian/enganche.py aplicar`), con el OK de
  Sistemas y Texturas el 17-11-2026. Salió idéntico al ensayo:
  - ninguna casa cambia, y el relieve, los nudos y las calles quedan iguales;
  - solo se quitan la ermita genérica (16 muros, 3 tejados) y 7 árboles del parque;
  - 13 `clr` se mueven ±0,1 m.
- Las sendas del mapa cruzan el parque: árboles, farolas, bancos y la pérgola se apartaron de ellas (la prueba lo
  comprueba). La pérgola acaba antes de la senda del oeste, y los escalones del suroeste van donde sale esa senda.

## Pendiente
- Hecho y aprobado. Luis, 17-11: «quitando eso de 10», y con la plaza corregida: «Perfecto. Visto bueno».
- Es aproximado: la altura de la nave y de las naves laterales (sin medir con cámara), el número de ventanucos, los
  árboles del parque (contados en la ortofoto) y el monumento de la esquina (sin texto).
