# Herramientas de la Universidad Comunal y la Papelería Rocas (calle de los Arcos)

Con esto se midió y se comprobó `godot/scripts/comunal.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo
aproximado: `referencias/universidad_comunal/LEEME.md`.

## Qué hay
- `capturas.py CARPETA [nombre…]` — baja las 35 vistas de Street View y la foto esférica privada (ocho rumbos).
- `contactos.py CARPETA SALIDA nombre…` — varias fotos en una hoja con su nombre.
- `medir.py CARPETA NOMBRE PLANO px,py…` / `… fit px,py=x…` — de píxel a metros sobre la fachada o la tapia.
- `vistas.py CARPETA NOMBRE…` — el juego desde donde estuvo Street View (cámaras corregidas 2,2 m).
- `hojas.py [CARPETA]` — las hojas de `guion/fotos/universidad_comunal/`.
- `enganche.py` — lo que añade a `casas_calles.gd` (tres casas a `["obra"]`), `world.gd` y `selftest.gd`; ya aplicado.

## Lo que se aprendió aquí
1. **Dos edificios pegados, un solo guion**: el marco es el de la casa principal y la otra se construye con `face()`
   sobre su propio frente del mapa (`_loc` pasa de mapa a marco; `_rings` da los contornos de una casa en el marco).
2. **Una casa del mapa puede tener dos contornos** (aquí, la papelería y su bloque de la otra calle): al marcarla
   `"obra"` deja de dibujarse entera, así que hay que hacer también el de detrás.
3. **Cuando dos cámaras ven lo mismo, una ajusta a la otra**: la cámara C se ajustó a dos puntos del extremo sur (el
   de la tapia y el de la fachada, en planos distintos); la B, al extremo norte de la fachada y al pilar del porche
   que ya daba C. Las dos salieron 2,2 m al sur de donde las pone Google, y dieron la misma altura de alero.
4. **Lo que se ve a través de un hueco no está donde parece** (las ventanas vistas por dentro del porche): hay que
   medirlas en SU plano, el de la fachada.
5. **Un `Label3D` en una banderola**: dos etiquetas, una por cara, con `double_sided = false` y giradas ±90°.
6. **Una malla en un arco**: barras en diagonal recortadas a la forma muestreando cada recta (`_mesh`, `_in_arch`).
7. Antes de dar por malo algo que no se ve en una foto de prueba, mirar desde dónde está hecha: la cámara estaba
   dentro de la casa de enfrente.
8. **Para que un hueco parezca una entrada, detrás tiene que haber sitio**: con estantes a 0,4 m del arco se leía
   como una pared. Ahora hay una sala de 6 m (suelo desde la acera, estantes a los lados que fugan, mostrador al fondo,
   tubos de luz en el techo) y un felpudo en el umbral.
9. **Un horario partido**: `open_at(day, hour)` es una función pura (mañana y tarde; sábado solo mañana; domingo no);
   la prueba la consulta sin mover el reloj y pone cada estado con `set_open`.

## El interior de la papelería (`rocas.gd`)
Un decorado aparte sobre `obra.gd`, con el suelo como `deck` de `MapData` (una sola altura, haga lo que haga el campo
debajo) y todas sus mallas en la capa 11, a la que no llega el sol (`_indoors`). Los muebles: `tools/rocas/muebles.py`
(Blender) pasa a GLB los OBJ del Furniture Kit de Kenney. Para llenar una estantería del kit con libros hechos aquí,
sus medidas salen de los vértices del OBJ (la librería: 4 × 2,5 × 8,8 unidades, baldas a 1,3, 3,7 y 6,1).
Un `Label3D` mira a +z: girado PI mira a la puerta; lo que va a la derecha según se lee va en -x.

## Pruebas
`python tools/run_tests.py comunal`: 28 fotos (`godot/shots/comunal_*.png`; las de la papelería a varias horas, porque
este modo corre solo y puede mover el reloj) y cinco comprobaciones (está construido; está sobre sus tres casas del
mapa, que `casas.gd` ya no dibuja, y tapia, verja, tienda y bloque trasero paran; el tablón y la señal no pisan
calzada y los nombres son los del juego; la papelería sigue su horario y se abre y se cierra; su interior aparte está lejos del pueblo, cerrado, a nivel,
amueblado y abre con ella). Y
`python tools/run_tests.py casas solo=arcos_`.
