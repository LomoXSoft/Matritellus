# Referencia: la rotonda de los Tricornios (delante del cuartel)

Pedida por Luis el 17-11-2026, con una captura aérea y cuatro fotos suyas: «Vamos a trabajar en esta rotonda. Va a ser
un poco complicada porque, aunque la zona y estructura es la misma, han construido varias cosas dentro en los últimos
años. Como una bandera gigante y un monolito tributo a la guardia civil (tricornios). El monolito de piedra tiene el
escudo en metal forjado arriba y una placa conmemorativa con el escudo del pueblo y de la guardia civil de nuevo».
Primera versión enseñada el mismo día (hojas en `guion/fotos/rotonda_tricornios/`). Su veredicto: «Visto bueno» (17/11).

El modelo es `godot/scripts/rotonda.gd` (sobre `obra.gd`), en `world.rotonda`. Herramientas: `tools/rotonda/`.

## Dónde
Donde se juntan la avenida de la Constitución, la de Martín Descalzo, la calle del Santo y la de Víctor Pradera, al
norte del cuartel. En el mapa ya es un anillo de un solo sentido (sin nombre, 9 m de ancho) alrededor de una isleta;
el juego la pintaba como una placita de baldosa clara con un círculo de arena. Sin rehorneado: el guion busca ese
anillo al cargar y saca de él el centro de la isleta.

## Fuentes
- **Ortofoto** del PNOA (`tools/ign/rotonda_tricornios.{jpg,json}`): la isleta, unos 6 m de radio hasta el bordillo.
- **Street View**, noviembre de 2024 (`tools/rotonda/capturas.py`, 26 vistas desde 11 cámaras del anillo): la isleta
  antes de la bandera y el monolito. El báculo central, situado con rumbos desde cuatro cámaras, que coinciden a 25 cm.
- **Las fotos de Luis** (no se guardan: salen personas): el mástil blanco al lado del báculo, el monolito delante
  mirando al sur, el emblema de forja, la placa, las flores, los dos arbustos grandes.

## Lo que hay
Bordillo pintado a tramos rojos y blancos; grava blanca; mantillo oscuro en la parte oeste; arbustos verdes redondos;
cinco ciruelos de hoja morada; las gomas negras del riego; el báculo gris con sus dos focos (se encienden de noche);
las señales azules de rotonda, bajitas, una frente a cada calle que entra. Al lado del báculo, el mástil blanco de
16 m con su bola dorada y la bandera de 3,6 × 2,4 m ondeando hacia el oeste (lisa, roja y amarilla, como la del
cuartel). Delante, el monolito de granito mirando al sur, al cuartel: el emblema de forja arriba, la placa en su cara,
un parterre de flores rojas y amarillas delante y un arbusto grande a cada lado. Alrededor, un faldón de asfalto tapa
lo que el juego pintaba antes.

## Lo que no es como el real (a propósito)
- **El emblema de forja es nuestro**: una corona sobre el tricornio del logo de los Tricornios, con una espada y una
  vara cruzadas detrás (`tools/rotonda/dibujos.py`). No es el emblema real de la Guardia Civil, como en el cuartel.
- **La placa**: el escudo del pueblo (el del juego, con su cinta) y el logo de los Tricornios; dice «MADRIDEJOS / EN HONOR A LOS
  TRICORNIOS, / EJEMPLO DE SERVICIO, ENTREGA / Y COMPROMISO CON NUESTRO PUEBLO / 12 de octubre», sin año. (Hasta el 24/11/2026 ponía MATRITELLUS; Luis: el pueblo del juego se llama Madridejos, y Matritellus es el título. La cinta del escudo sigue diciendo MATRITELLUS: Luis, «No, deja Matritellus en el escudo, ahí puede estar, ya que es su nombre antiguo».)
- **La bandera, sin escudo**, como todas las del juego.
- **La corona de laurel** de las fotos (la del acto) no está: era de ese día.

## Lo que es aproximado
- El mástil y el monolito: por las fotos de Luis (el mástil 1,5 m al este del báculo; el monolito 0,6 m delante, al
  sur); ±0,5 m. Las alturas, por las personas de la foto: el monolito 1,5 m, el emblema 0,9 m, el mástil unos 16 m.
- Los arbustos y los ciruelos: a ojo sobre Street View; ±1 m.

## Pruebas
`python tools/run_tests.py rotonda`: 12 fotos y tres comprobaciones (está hecha; su bordillo no se mete en el carril
del anillo y todo queda dentro; a pie se pisa su suelo, y fuera el de siempre; bordillo, báculo, mástil y monolito
paran; los focos son del pueblo).
