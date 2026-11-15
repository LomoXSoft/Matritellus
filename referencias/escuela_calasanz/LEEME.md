# Referencia: la escuela infantil de la calle del Palo («S. José de Calasanz»)

Pedido por Luis el 15-11-2026 (`usuario_01_zona_plano.jpg`, `usuario_02_zona_satelite.jpg`: la parcela marcada en
rojo): «Vamos a hacer un último edificio antes de hacer commit de todo y que sistemas lance la prueba completa. El
centro de educación infantil de garcilaso de la Vega (C. Palo, 1, 45710 Madridejos, Toledo) al que llamaremos José
de Calasanz en nuestra versión, igual que se llamaba antiguamente. Da prioridad a las fotos de 2009. Ya que entonces
era más colorido, con más juegos. Más infantil». Y con dos fotos más (`usuario_03_puerta_2013.jpg`: la puerta, el
rótulo y el mural del arco; `usuario_04_patio_juegos_2009.jpg`: la valla de colores, la torre de juegos y los
neumáticos): «Como estas de 2009».

El modelo es `godot/scripts/calasanz.gd` (sobre `obra.gd`). Herramientas: `tools/calasanz/`.

## Marco
Origen en la esquina noroeste de la fachada, mapa (-109,41, -217,17), en el suelo del patio. `x` a lo largo de la
fachada (hacia el sureste, calle del Palo abajo); `z` sale de la fachada hacia la calle. El patio queda 0,6 m por
encima de la calle.

## Fuentes
- **Catastro** `4194305VJ5649S`: enseñanza, 1975, dos plantas; el edificio mide 23,36 × 6,78 m, con un cuerpo trasero
  de 4,4 × 6 m. Su foto de fachada: `tools/casas/4194305VJ5649S/fachada.jpg`.
- **Street View**: mayo de 2009 (el patio: juegos, valla, caseta; los árboles con hoja tapan la fachada), marzo de
  2013 (los árboles pelados: la fachada entera) y 2024. Lista en `tools/calasanz/capturas.py`; las fotos no se guardan.
- **Ortofotos del IGN**: `tools/ign/calasanz_*.jpg` (2006, 2009, 2012 y la vigente).

## Medidas (de la vista frontal de marzo de 2013, con el edificio de Catastro como escala)
- **Fachada**: simétrica. En el centro, un arco de ladrillo de 3,4 m que da a un porche pintado; encima, el rótulo
  «S. JOSE DE CALASANZ» en una cartela negra. Seis ventanas a cada lado en cada planta, cada 1,3 m, de 0,9 m; sobre
  el arco, una ventana doble. Las de abajo, con rejas rojas. Blanco, con las esquinas, la imposta entre plantas, los
  recercos y la cornisa de ladrillo. Alero a unos 7,3 m del patio; cubierta de teja a cuatro aguas.
- **Valla**: murete de mampostería de unos 0,75 m desde la acera, con verja de barrotes de 1,3 m pintada por tramos
  de unos 3,3 m en amarillo, azul, rojo y verde. Puerta de 2,6 m entre dos pilares de hormigón con remate de ladrillo
  y una piedra en punta; en 2013, verde (chapa abajo, barrotes arriba), con el tablón de anuncios al lado.
- **Patio**: árboles grandes en fila tras la verja. A la izquierda de la casa (hacia el Arroyuelo), los juegos: en
  2009, una torre de madera pintada de todos los colores con tobogán, neumáticos medio enterrados, una casita, mesas
  amarillas. A la derecha, una caseta blanca prefabricada (un aula más) y un paisaje pintado en el testero.

## En el juego
- El rótulo dice lo mismo que el de la pared: «S. JOSE DE CALASANZ».
- La puerta es la verde de 2013 (la de la foto de Luis); en 2009 era gris oscura. Lo demás, de 2009.
- No se entra: la puerta está cerrada. No hay niños (Luis: nada de personajes nuevos por ahora).
- Los caballitos de muelle y el balancín son del lote libre del parque de la plaza (`godot/assets/parque/`).
- Prueba: `python tools/run_tests.py calasanz --window` (12 fotos y 3 comprobaciones).

## Lo que es aproximado
- La **parcela** es algo más corta por la esquina del Arroyuelo que la real (en el juego esa calle pasa más cerca) y
  sus esquinas van en ángulo, no redondeadas.
- Las **bandas de ladrillo** de la planta alta van seguidas; en la real hay algún paño blanco entre grupos de ventanas.
- Los **murales** (el porche, el testero, la tapia del fondo) son nuestros, con los colores y el aire de los reales,
  sin copiarlos.
- Los **juegos** están donde los pone 2009, a ojo; la casita y la mesa son inventadas a partir de lo que se entrevé.
- El **fondo** del patio y la trasera del edificio no se ven desde la calle: van lisos.
- Los **árboles** son menos frondosos que los de mayo de 2009, para que se vea la fachada.
