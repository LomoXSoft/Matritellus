# Referencia: la ermita de San Cristóbal

Pedida por Luis el 17-11-2026, con una captura de Street View (marzo de 2021) y otra de Google Maps. Sus palabras:
«Ahora la hermita de san Cristóbal. Una pequeña hermita hecha por ciudadanos del pueblo que hace esquina con Ortega y
Gasset y Carretera antigua Madrid Cádiz (está carretera tiene alias: ruta del colesterol)».

El modelo es `godot/scripts/cristobal.gd` (sobre `obra.gd`), en `world.cristobal`. Su marco tiene el origen en la
esquina suroeste de la casita: x va a lo largo de la calle (hacia la carretera), z sale de su hastial hacia la calle e
y = 0 es la acera ante ella. Las herramientas están en `tools/cristobal/`.

## Fuentes
- **Catastro**: el edificio `4602021VJ5740S` (14 m², una planta). Hasta ahora el horneado levantaba ahí un bloque
  genérico de 5,5 m.
  - Para sacarlo: `python tools/cristobal/manzana.py PLANO.png partes=4602021`.
- **Ortofoto** (PNOA): `tools/ign/cristobal.jpg`, de `python tools/fetch_ortho.py cristobal 380 -1040 490 -930 0.12`.
- **Street View** (`tools/cristobal/capturas.py`; las fotos son de Google y no se guardan aquí):
  - desde la carretera vieja: 2024, 2021, 2015 y 2009;
  - por Ortega y Gasset, ante su hastial: marzo de 2013 y mayo de 2009.
- El terreno apenas cae: unos 3 cm por metro hacia el sureste.

## Lo que lleva
- **La casita**:
  - Encalada, de 3,75 × 3,8 m, con el hastial a la calle.
  - Tejado de teja vieja a dos aguas, con los bordes y la cumbrera rematados de cal, y la cupulita blanca al norte de
    la cumbrera.
  - Dos puertas, una en el lado este y otra en el lado oeste (Luis, 17-11: «Le falta una puerta en este lado»; Street
    View o3), cada una tras una reja de hierro verde oscuro con copete de volutas y un azulejo redondo encima.
  - Piedra parda en las esquinas y en las jambas de las puertas (los hastiales, blancos lisos).
- **Un patinillo ante cada puerta**: suelo de baldosa; murete de mampostería parda con albardilla de ladrillo y verja
  negra con puntas de lanza, con su cancela (la del este, al este; la del oeste, al norte, porque al oeste pasa la valla
  del solar); junto a la puerta del este, un arbusto y una maceta.
- **El muro blanco** de cal a lo largo de la acera, grueso y con la coronación redondeada.
- **El solar de al lado** (al oeste): murete de bloques con valla de malla y postes, y la valla que sube hacia el norte
  junto al patinillo del oeste.
- **Alrededor**: los árboles del solar y del descampado, el poste de los focos, la torreta de celosía con su caja, la
  farola de brazo y un poste de madera en la acera.

## Pruebas
`python tools/run_tests.py cristobal`: fotos desde la carretera vieja, la puerta, Ortega y Gasset, el norte, de noche y
desde el aire. Comprueba que los muros te paran, que el suelo ante el patinillo está libre y que nada pisa el asfalto.

Hojas para Luis: `python tools/cristobal/hojas.py CARPETA_SV`, en `guion/fotos/cristobal/`.

## Hecho
- El rehorneado (`CRISTOBAL_RC` en `tools/bake_godot.py`, con `tools/cristobal/enganche.py aplicar`), con el OK de
  Sistemas y Texturas el 17-11-2026. Salió idéntico al ensayo: solo se quita el bloque genérico (4 muros, 1 tejado);
  ninguna casa, calle, árbol ni `clr` cambia.
- Tras comparar con Street View: cal blanca y lisa (sin manchas), teja vieja grisácea (`roof_tiles`), la piedra parda
  solo en el lado de la puerta (los hastiales son blancos lisos) y menos árboles junto a la ermita.

## Pendiente
- Hecho y aprobado. Luis, 17-11, con la puerta del oeste añadida: «Visto bueno».
- Es aproximado: las alturas (alero 2,55 m, cumbrera 3,55 m), el tamaño del patinillo y la colocación de los árboles,
  los postes y la torreta.
