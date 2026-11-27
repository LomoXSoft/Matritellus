# Referencia: la Plazuela del Toledano

Pedida por Luis el 16-11-2026: «Cuando tengas la carpeta libre puedes ponerte con la Plazuela del Toledano». Primera
versión enseñada el mismo día (hojas en `guion/fotos/plazuela_toledano/`). Su veredicto: «Visto bueno a todo. Pensaba que ya lo había dado» (16/11).

El modelo es `godot/scripts/toledano.gd` (sobre `obra.gd`), en `world.toledano`. Herramientas: `tools/toledano/`.

## Dónde
La isleta de tres puntas donde se juntan la calle del Santo, la de la Amargura, la de San José, la de Jesús y María y
la calle sin nombre del suroeste. En el mapa ya era un anillo peatonal («Plaza del Toledano», `k` 2): el juego lo
dibujaba como un camino de baldosa clara alrededor de un parche de arena.

## Cómo está hecha (sin rehorneado)
- La isleta es ese anillo, leído tal cual al cargar, y recortado a 3,9 m del eje de cada calle **del juego** (la calle
  sin nombre pasa a 2,3 m del anillo: por ese lado pierde metro y medio). Queda en unos 190 m².
- Debajo, un faldón de asfalto tapa el camino claro del mapa.
- El suelo **sigue el relieve** (baja casi un metro de la punta norte a la sur): cada pieza plana se corta por las
  facetas del propio relieve (`_lay`), y lo que se pisa son decks inclinados, uno por faceta (`_walkable`), con 40 cm
  de margen fuera del bordillo para no tener que trepar.
- El bordillo (14 cm) es sólido para los coches con un chaflán: se suben, no chocan.

## Fuentes
- **Street View**, noviembre de 2024 (y 2013, 2009, 2019 de los mismos sitios): 25 vistas en `tools/toledano/capturas.py`.
  Todas las cámaras: `python tools/molino/panos.py cerca CzCj5kSG7s9inuIdgT9lgA -365 -44 55`.
- **Una foto esférica privada** tomada en la propia isleta (su dirección en `capturas.py`, `SPHERE`): de ahí la farola,
  las señales de la punta y la vista desde dentro.
- **Ortofoto** del PNOA (IGN, CC BY 4.0): `tools/ign/toledano.{jpg,json}`.
- Cada cosa, situada por **rumbos desde dos o más cámaras** (`tools/toledano/rumbos.py`).

## Lo que hay
Losas irregulares de pizarra (gris, gris azulado, ocre, alguna oxidada; textura dibujada aquí, `losas.py`) entre
franjas de piedra clara: una al borde, varias de través y una a lo largo; alcorques rojos. Dos cipreses altos, el árbol
grande, el pino del alcorque redondo en la punta sur, el arbolito con su jaula; cuatro bancos de forja negra con el
respaldo calado; la farola (se enciende de noche), dos papeleras en poste; el ceda el paso y el dirección prohibida en
la punta oeste; y en el centro, el **lápiz** de tres metros sobre su goma. Los tres contenedores grandes, en la acera
de enfrente (`props.gd`: se los lleva un coche).

## Lo que es aproximado
- La forma de la isleta: la del mapa recortada, no medida; ±0,5 m.
- Árboles, bancos, farola, papeleras y lápiz: por rumbos, ±0,4 m. Las copas, a ojo.
- Los contenedores: no he comprobado en foto que salgan donde están (en la acera de la calle que va a lo largo de su
  lado más largo).
- La isleta real sigue un poco más hacia el oeste bajo los árboles inclinados; en el juego la corta la calle.

## 27/11/2026: el suelo, una sola lámina

Luis: «Que no se apilen las capas del suelo». La campaña anti-solapes había separado las cinco capas 1,5 cm cada una:
la última quedaba 7 cm alta y los bancos y el lápiz, hundidos.

- Ahora no hay ninguna piedra encima de otra: bordillo, losas, bandas claras y parterres rojos son trozos de UNA lámina
  a la altura del bordillo (`KERB`), cada uno recortado de los que taparía (`_minus`) y tendidos canto con canto
  (`_lay_tight`). Debajo solo queda el asfalto de alrededor.
- `_gy` (donde se apoyan las cosas), la lámina y los pisos por donde se anda están a la misma altura: se pisa
  exactamente el suelo que se ve.
- **Trampa:** se recorta con los parterres y las bandas enteros, no con lo que de ellos se tiende. Si un recorte acaba
  justo en un canto, Clipper deja las dos mitades unidas por un puente sin anchura, Godot no sabe triangularlo y esa
  piedra desaparece sin dar error.
- Comprobar tras tocarlo: `python tools/run_tests.py zfight solo=toledano.gd --timeout 180` (0,000 exactos) y el modo
  `toledano`; mirar el suelo a ras (rayitas oscuras = falta una piedra).
