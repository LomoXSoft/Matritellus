# Referencia: la manzana de la Casa Grande, la biblioteca y la escuela de música

Pedida por Luis el 17-11-2026, con una captura de Google Maps (girada: el norte a la izquierda). Sus palabras: «son
varios edificios públicos pegados que ocupan una manzana entera: La casa de la cultura (en rojo), la biblioteca pública
(en medio) y la escuela de música y danza (en frente de Centro Salud). Tiene bastantes detalles así que tómatelo con
calma». Después: «La llamaremos Casa Grande en vez de casa de la cultura».

El modelo es `godot/scripts/cultura.gd` (sobre `obra.gd`), en `world.cultura`, en el marco del mapa (x este, z sur). La
manzana queda entre la calle de los Arcos (oeste), la de Argentina (norte) y el Callejón Pando (sur, y su tramo norte-sur
al este, frente al aparcamiento y el centro de salud). Herramientas en `tools/cultura/`.

## Fuentes
- **Catastro**: toda la manzana es una parcela, `4590001VJ5649S`, con 9 partes; el centro de salud es otra, `4590037`.
  - Partes 9 y 2: la Casa Grande (dos plantas y una nave central de una).
  - Parte 3, con las 6 y 7: la biblioteca.
  - Partes 1, 8, 5 y 4: la escuela de música. La 1 es de cuatro plantas según el Catastro; en las fotos se ven tres. La
    4 es la nave del extremo curvo.
  - Entre la escuela y el Pando el Catastro no tiene nada, pero la ortofoto y la foto de 2019 sí muestran edificio: se
    construye.
  - Para sacarlas: `python tools/cultura/manzana.py PLANO.png partes=4590001`.
- **Ortofoto** (PNOA): `tools/ign/cultura.jpg`, bajada con `python tools/fetch_ortho.py cultura 95 90 210 175 0.15`.
- **Street View** (`tools/cultura/capturas.py`; las fotos son de Google y no se guardan aquí):
  - los Arcos y Argentina, noviembre de 2024 (con 2021, 2019 y 2013 en los mismos sitios);
  - el Callejón Pando, octubre de 2019 y marzo de 2013;
  - el lado del aparcamiento solo se ve desde las esquinas.
- La fachada de los Arcos se midió con la vista larga desde la esquina noroeste (`alzado.py ... a0_s`); las ventanas
  bajas, con la vista de frente `a3` (1,24 × 2,1 m, desde 0,3 m: entran en el zócalo).
- **Web del Ayuntamiento** (madridejos.es, «Casa Grande»; Luis mandó la página el 17-11-2026 «incluido el escudo que
  hay encima de la puerta de entrada»): ocho fotos, que no se guardan aquí. De ellas salen el escudo (DSC_0321), la
  portada y la esquina (DSC_0832).

## Lo que lleva
- **La Casa Grande**: aparejo toledano (ladrillo con cajones de mampostería) y un zócalo de losas de granito
  de 1,15 m.
  - **Fachada a los Arcos**:
    - cuatro ventanas bajas con reja saliente y jambas encaladas, que bajan hasta 0,3 m (el zócalo se corta en ellas),
      con un dintel de ladrillo a sardinel en abanico encima, del color del muro (centros a 4,5, 10,3, 19,9 y 25,6 m
      desde Argentina);
    - la portada en medio (a 15,1 m), como en las fotos de la web: jambas de sillares de granito, largos y cortos
      alternos; dintel de siete dovelas blancas en abanico; cornisa moldurada; y encima el escudo de la familia en su
      marco moldurado de 1,2 × 1,4 m. El relieve (campo de 71 × 91 cm) está dibujado a mano con
      `python tools/cultura/escudo.py` (relieve en PIL, su luz y su mapa de normales: `godot/assets/cultura/`;
      después, la importación de Godot): yelmo con plumas, lambrequines y hojas de acanto, una venera abajo; el
      escudo cuartelado con bordura de aspas (roeles con un bastón; torre con águila en bordura de cuadritos; cinco
      animales pasantes; castillo, león rampante, cruz flordelisada y un jaquelado);
    - cuatro ventanucos arriba con su reja de caja;
    - el tablón rojo de actividades y el panel de la historia de la casa (sin textos reales).
  - **A Argentina**: ventanas sobre el zócalo, con el mismo dintel de ladrillo, y la puerta pequeña con su arco.
  - **El zócalo**: su remate va recto de una punta a otra de cada fachada, a la misma altura sobre la calle, así que
    queda igualado a los dos lados de cada puerta (Luis, 17-11: «Debería estar igualada»).
  - **Al Pando**: más ladrillo y dos ventanucos.
  - **Arriba**: alero a 7,7 m con cornisa de ladrillo en diente de sierra.
- **El arco del Callejón Pando** con su torrecilla, donde el callejón sale a los Arcos (pegado a la esquina suroeste):
  - arco de medio punto con techo de vigas en el paso;
  - un balcón de hierro sobre el arco hacia los Arcos y dos ventanucos hacia el callejón;
  - tejado a cuatro aguas.
  - Por debajo se puede pasar.
- **La biblioteca**, en medio. Rehecha el 17-11 con dos fotos de Luis («La entrada de la biblioteca no se parece en
  nada. No hace falta poner las dos rampas pero la fachada más parecida»), Street View n4 y n5_w y la ortofoto:
  - Su fachada a Argentina **no está en la línea de la calle** (el Catastro la pone ahí): al oeste sobresale un cuerpo
    suyo de 5,2 m hasta la calle, con paños grandes de piedra y la esquina redondeada; desde ahí al este la fachada va
    2,8 m más atrás, hasta la escuela de música (`LIB_NE`, `LIB_HONDO`). Las fuentes no casan del todo (Street View
    daba 4 m y la ortofoto unos 2,8): es aproximado.
  - En ese entrante, la puerta de vidrio a 2 m de la esquina, bajo un tejadillo de tejas viejas sobre tres vigas de
    madera; la placa azul «BIBLIOTECA» (propia), una gris debajo y una hoja de avisos al otro lado.
  - Ventanas con reja rematada en volutas y la persiana medio bajada, abajo y arriba; paños pequeños de piedra en
    columnas entre ellas; una banda de ladrillos de canto en diente entre las plantas y otra bajo el alero (8,5 m).
  - Delante, un rellano de granito medio metro sobre la acera de la puerta, con escalones delante de la puerta y una
    barandilla marrón oscuro; sin las dos rampas, como dijo Luis. Se puede subir y andar por él (`MapData.decks`).
- **La escuela de música y danza**, al este. Su calle está unos 2 m más alta que la puerta de la Casa Grande, así que
  sus alturas van desde su propio suelo (aleros a 12 m el cuerpo alto y 9,3 m los bajos).
  - A Argentina (n5, n6): ladrillo rojo con paños de piedra blanca en columnas entre las ventanas; ventanas con reja y
    vierteaguas de granito en cada planta; las del sótano en el zócalo.
  - Al aparcamiento (n7_este, n8_este): ladrillo marrón claro, de obra moderna; una fila de ventanucos arriba, la caja
    acristalada sobre la entrada; la entrada metida bajo la planta de arriba, acristalada, con sus escalones; una
    ventana grande con reja al lado y otra encima; la placa «ESCUELA DE MÚSICA Y DANZA».
  - El extremo curvo de su sala, del mismo ladrillo claro, con ventanucos altos y la puerta lateral con escalones.
  - Al Pando: ventanas y las del sótano.
- **Los tejados**: de teja, a cuatro aguas sobre cada cuerpo (en el centro, plano).

## Pruebas
`python tools/run_tests.py cultura`: fotos de las cuatro fachadas, el arco por los dos lados, de noche y desde el aire.
Comprueba que la manzana está hecha donde estaba la parcela del Catastro, que las fachadas te paran, que se pasa bajo el
arco y que nada pisa el asfalto.

Hojas para Luis: `python tools/cultura/hojas.py CARPETA_SV`, en `guion/fotos/cultura/`.

Hojas para comparar con la web (solo en el scratchpad, porque las fotos son del Ayuntamiento):
`python tools/cultura/hojas.py CARPETA_SV CARPETA_WEB`.

## Hecho
- El rehorneado (`CULTURA_RC` en `tools/bake_godot.py`, con `tools/cultura/enganche.py aplicar`), con el OK de
  Sistemas y Texturas el 17-11-2026: solo cambió la manzana.

## Pendiente
- Hecho y aprobado. Luis, 17-11: «Casa grande está perfecta», y con la biblioteca y la escuela rehechas: «Perfecto.
  Visto bueno».
- La esquina noreste de la escuela, abierta en planta baja según n6, sin hacer: no está clara.
- Si hace falta: los cajones de piedra en columnas como en las fotos (ahora van al tresbolillo), y la fachada de
  Argentina medida ventana por ventana.

## 27/11/2026: los pilares del arco del Callejón Pando y la torre

Luis, sobre una foto del arco: «Aquí parece que falta pared, no?». Los pilares no tenían cara hacia el pasaje: las
paredes del pasaje estaban en los bordes del cuerpo, 0,655 m más afuera que el hueco, y mirando en diagonal se veía
a través.

- `_arco()`: caras de jamba en los bordes del hueco, del suelo al arranque del arco, todo el fondo (`ARCH_DEEP`), con
  zócalo y remate de granito; los sólidos ocupan ahora todo el pilar.
- La torre de encima no tenía paredes laterales por encima del arranque del arco (hueca vista desde los tejados):
  ahora suben hasta `TOWER_EAVES` con su cornisa. Esto no lo pidió Luis; se le avisó.
- `zfight solo=cultura.gd`: 5,576 → 5,567 m² exactos.
