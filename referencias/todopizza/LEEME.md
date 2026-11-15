# Referencia: la pizzería junto al supermercado («Todopizza»)

Pedido por Luis el 15-11-2026, al aprobar el Mercamona: «Puede empezar con el Telepizza que hay al lado. Lo llamaremos
Todopizza». Primera versión enseñada el mismo día (hojas en `guion/fotos/todopizza/`); aprobada por el usuario tal como está
(«Perfecto. Lo damos por finalizado», 15-11).

El modelo es `godot/scripts/todopizza.gd` (sobre `obra.gd`). Herramientas: `tools/todopizza/`.

## Dónde
Pegada al norte del Mercamona, entre la carretera antigua de Madrid a Cádiz y el ramal del este; Google la sitúa en
39,46636, -3,52289, mapa (911, 292). Catastro `5187001VJ5658N` («servicios públicos, 1970», 176 m²): un cuadrado de
13,3 m que es el contorno del TEJADO con sus aleros; la casa en sí mide unos 10,9 m de lado. Es la misma parcela que
el horneado ya deja sin levantar para el supermercado (`MERCAMONA_RCS`): no hizo falta rehornear.

## Marco
Origen en el extremo norte de su frente, mapa (907,0, 288,27). `x` a lo largo del frente hacia el sur, hacia el
supermercado (u = (-0,1583, 0,9874)); `z` sale hacia la carretera antigua (oeste). `y` = 0, su suelo.

## Fuentes
- **Street View**, noviembre de 2024, desde las tres calles: 13 vistas en `tools/todopizza/capturas.py` (el rumbo se
  calcula hacia el centro de la casa). Todas las cámaras: `python tools/molino/panos.py cerca 0kuTvD40S4ObcE2J8Y1McQ 912 294 45`.
- No hay fotos 360 de particulares en el sitio (se buscó en su posición).
- Catastro y ortofoto: las del Mercamona (`referencias/mercamona/LEEME.md`).

## Lo que hay
- **La casa**: pabellón cuadrado bajo un tejado de teja vieja a cuatro aguas, en punta, con veleta; aleros muy volados
  sobre postes de madera marrón con zapatas, en cinco vanos por lado, sobre dados de piedra.
- **Frente (oeste)** y primer vano del lado norte: todo cristal sobre un murete blanco; puertas de cristal en el
  segundo vano.
- **Norte**: pared blanca con una ventanita enrejada y una rejilla. **Sur**: pared blanca.
- **Trasera (este)**, con la pintura desconchada: puerta marrón, dos aparatos de aire, un tubo plateado de extracción
  que sube atravesando el alero, depósito blanco de gas en su jaula, valla de malla.
- **Alrededor**: explanada de losa delante, tras una valla baja de alambre, con farolas negras y un banco; al norte, un
  jardincillo de rocas y matas con dos árboles y una jardinera blanca; en la esquina de las calles, el cartel en un
  poste alto; detrás, los contenedores (iglú verde y marrón, azul y amarillo).

## En el juego
- El nombre es «TODOPIZZA» (de Luis): en un rótulo rojo sobre las puertas y en el cartel del poste. El distintivo del
  cartel es nuestro (una pizza en un aro rojo), no el de la marca real. Donde iría el teléfono, un garabato.
- No se entra. Por el cristal se ve el interior: suelo de baldosa, mostrador rojo, la carta iluminada, una nevera,
  mesas y taburetes. Sin personajes.
- Prueba: `python tools/run_tests.py todopizza` (9 fotos y 3 comprobaciones).

## Lo que es aproximado
- **El tamaño**: 10,9 m de lado, deducido de que el contorno de Catastro es el tejado; ±0,5 m. Las cámaras de Google
  no casan entre sí aquí (una la ve más grande y otra más pequeña), así que su sitio baila ±2 m.
- **El interior** es inventado: en las fotos el cristal refleja y apenas se ve. El rótulo rojo sobre las puertas
  también es nuestro (la real lleva vinilos en el cristal).
- **La valla** es de alambre oxidado en la realidad; en el juego, tres hilos sobre postes finos.
- **El jardín, la jardinera y los contenedores**: colocados a ojo.
- **Alturas**: postes de 2,5 m, tejado de 3,3 m de alto; a ojo sobre las fotos.
