# Referencia: la casa de la Calle de Matías Pérez 16

Pedida por Luis el 17-11-2026 con una captura de Street View de su fachada (noviembre de 2024). Sus palabras: «Nuevo
proyecto. Matias Pérez 16».

El modelo es `godot/scripts/matias.gd` (sobre `obra.gd`), en `world.matias`. Se levanta sobre la casa del mapa
`matias_16`, que Texturas pasó como `["obra"]` en `casas_calles.gd`, así que `casas.gd` no la dibuja. No hace falta
rehornear. En las hojas de repaso de casas, que solo dibujan `casas.gd`, sale como hueco; en el juego, no.

Su marco tiene el origen en el extremo oeste de la fachada (a la izquierda, mirando desde la calle): x va a lo largo de
la fachada, z sale de ella hacia la calle e y = 0 es la acera ante su centro. Las herramientas están en `tools/matias/`.

## Fuentes
- **Catastro**: fachada de 6,9 m. Contando los ladrillos de la foto (25 cm cada uno) sale lo mismo.
- **Street View** (`tools/matias/capturas.py`; las fotos son de Google y no se guardan aquí): noviembre de 2024,
  octubre de 2019 y mayo de 2009, desde los mismos sitios de la calle. Las cámaras salen de
  `python tools/molino/panos.py cerca zUPnD-kJCxRwgKgGczw46A -266.4 -338.4 25`.

## Lo que lleva
- **El ladrillo**: caravista salmón, de hiladas regulares y llaga clara (`brick_wall_003` a 0,9 m, para que cada ladrillo
  mida 25 cm).
- **Abajo**:
  - el portalón ancho, tras dos cortinas crema con rosas grandes de gris malva y jambas de madera oscura;
  - la puerta de la casa, tras una cortina blanca;
  - la ventana, tras una reja de pletina blanca (nueve barrotes, travesaños solo arriba y abajo) y con su persiana
    beige bajada;
  - un zócalo de cemento gris de unos 45 cm.
- **Los sardineles** (ladrillos a sardinel, del mismo tono que el muro): uno sobre cada hueco de abajo, una faja a lo
  largo de toda la fachada a 2,85 m y uno encima de cada ventana de arriba.
- **Arriba**: dos ventanas, la del oeste más grande, en recercados de ladrillo. Llevan las persianas blancas bajadas
  hasta el alféizar (de color liso, con sus lamas, como las de las casas del pueblo), un alféizar blanco y una
  barandilla blanca pequeña.
- **En la fachada**: el cable negro a la altura de los alféizares, con sus grapas, y dos cajitas blancas junto al
  extremo este.
- **Arriba del todo**: una cornisa de tres hiladas de ladrillo bajo el alero de teja, y el tejado a dos aguas.
- No se ve el número de la casa (el juego no lleva números).

## Pruebas
`python tools/run_tests.py matias`: fotos de frente, por la calle en los dos sentidos, de los huecos de abajo, de las
ventanas de arriba y de noche. Comprueba que la casa está hecha a mano, que su fachada te para y que nada pisa el asfalto.

Hojas para Luis: `python tools/matias/hojas.py CARPETA_SV`, que escribe en `guion/fotos/matias/`. Antes hay que sacar
las vistas del juego desde las cámaras de Street View:
`python tools/run_tests.py "$(python tools/merkocarry/vistas.py CARPETA_SV m0 m1 m2 m3 m0_up m1_up)"`.
La vista m4 se deja fuera porque sale gente, y el transeúnte lejano de m1 va difuminado.
