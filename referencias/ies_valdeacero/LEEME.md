# Referencia: el IES Valdehierro («IES Valdeacero»)

Pedido por Luis el 17-11-2026, con una captura aérea con el recinto marcado en rojo: «Tu siguiente proyecto será el
IES Valdehierro (que llamaremos IES Valdeacero). Mas o menos dentro del recinto rojo. En el C. Viejo de Tembleque».
Primera versión enseñada el mismo día (hojas en `guion/fotos/ies_valdeacero/`). Tras rehacer la entrada, su veredicto
(17-11): «Mucho mejor. Visto bueno».

El modelo es `godot/scripts/ies.gd` (sobre `obra.gd`), en `world.ies`. Herramientas: `tools/ies/`.

## Dónde
Al norte del pueblo, junto al Camino Viejo de Tembleque (la avenida con aparcamientos del este). En el mapa del juego
ahí no había nada (campo): sin rehorneado. El recinto: x -190..-57, z -1305..-1135 (unos 110 × 170 m).

## Fuentes
- **Ortofoto** del PNOA (`tools/ign/ies_valdeacero.{jpg,json}` y `ies_valdeacero_sur`): todas las plantas trazadas
  sobre recortes con rejilla de 5 m (`tools/ies/recortes.py`). Es la fuente principal.
- **Street View**, noviembre de 2024 (`tools/ies/capturas.py`, 15 cámaras de la avenida): la valla azul con malla y
  seto, la puerta del aparcamiento, el pabellón blanco de la entrada con el nombre y las tres banderas, el gimnasio
  de paneles verde grisáceo con su banda de cristal, el anexo blanco, los focos de las pistas.
- El Catastro no lo tiene (es suelo rústico: «Pl. Rústica-86»).

## Lo que hay
- **El edificio principal**: un peine de dos plantas, un espinazo al oeste y cinco barras hacia el este con patios
  estrechos entre ellas; un patio de árboles bajo un tejadillo azul; dos piezas bajas al oeste; un porche cubierto a lo
  largo de las pistas.
- **Las pistas**: dos, una de baloncesto con sus canastas y otra de fútbol sala con sus porterías; sus líneas; cuatro
  focos altos (se encienden de noche).
- **El gimnasio**: paneles verde grisáceo con nervios, una banda de cristal bajo el alero, cubierta blanca a dos
  aguas; un anexo bajo al norte y otro blanco al sur.
- **Al norte**: el salón de tejado rojo a cuatro aguas sobre su plataforma; el bloque gris de FP (dos alturas y una
  pieza baja) con su jardín escalonado y el árbol morado; el paseo bajo la hilera de árboles.
- **El aparcamiento**: asfalto, plazas pintadas, su fila de árboles en medio.
- **El huerto**: el campo con sus surcos, el invernadero largo de plástico, la caseta; los cipreses de la linde oeste.
- **La valla de la avenida**: murete azul con albardilla blanca, malla encima, seto detrás; la puerta del aparcamiento
  entre dos pilares blancos.
- **La entrada** (rehecha el 17-11 tras la palabra de Luis: «creo que la entrada podrías haberla hecho más fiel. No se
  parece casi en nada ni tiene las tres banderas (Castilla la mancha / España / Europa)», con su foto). Medida con
  rumbos desde cuatro cámaras de la avenida (coinciden a 7 cm): frente de 13,8 m. Una marquesina larga con el canto
  oscuro y encima el rótulo con «I.E.S. VALDEACERO» en letras en relieve gris azulado; debajo, al sur, el pilar blanco
  con el cartel del centro y el paso con las dos hojas de la verja abiertas; al norte, la conserjería blanca con zócalo
  azul, dos ventanas de lamas grises y la puerta gris; suelo claro delante. Detrás, a 6 m, los tres mástiles con sus
  banderas ondeando: la de la región (carmesí con el castillo amarillo y blanco), la de España (lisa, como todas las
  del juego) y la de Europa (`tools/ies/banderas.py`). Hoja `04_entrada.jpg`.
- En los lados que dan a los campos, malla y seto.
- **Delante de la valla**, hasta la acera de la avenida: la franja de tierra donde se aparca, con su fila de árboles,
  y suelo claro ante la entrada (Street View). Se calcula con la calle del juego (`_street_side`).

## Lo que es inventado o aproximado
- **Las fachadas del edificio principal y del bloque de FP no se ven desde ninguna calle**: están hechas a juego con
  lo que sí se ve (revoco crema, zócalo y banda de ladrillo, ventanas blancas en filas). Las alturas, por las sombras
  de la ortofoto y por lo que asoma desde la avenida.
- Las plantas: ±1 m (la ortofoto es de 0,25 m por píxel, ampliada).
- Fuera del recuadro rojo de Luis, y fuera del juego: los invernaderos y los edificios de tejado azul del noreste.
- No se entra en ningún edificio. Sin personajes.

## Pruebas
`python tools/run_tests.py ies`: 11 fotos y tres comprobaciones (está hecho; sus edificios paran y el mapa los conoce,
nada pisa una calzada; su entrada da al Camino Viejo de Tembleque, su nombre es el del juego y los focos son del
pueblo).
