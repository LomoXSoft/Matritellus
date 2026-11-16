# Referencia: Kebab Deluxe (el kebab de la avenida de Castilla-La Mancha)

Pedido por Luis el 16-11-2026: «Ponte ahora con Kebab Deluxe (kebab Premium Av. Castilla la Mancha, 17 ...) el
edificio siempre apareciendo como el antiguo negocio La Meseta así que no hay muchas fotos de su estado actual.
Arquitectónicamente y colores es exactamente el mismo, solo quitaron los logos de la peseta y pusieron su cartel en
la fachada» (con una foto suya de noche). El nombre «Kebab Deluxe» es suyo (13-11-2026). Primera versión enseñada el
mismo día (hojas en `guion/fotos/kebab_deluxe/`). Su veredicto, ya con el horario: «Ambos visto bueno» (16/11).

El modelo es `godot/scripts/kebabdeluxe.gd` (sobre `obra.gd`), en `world.kebabdeluxe`. Herramientas: `tools/kebabdeluxe/`.

## Dónde
La casa `castilla_17` del mapa (Catastro `4390034VJ5649S`, 2010, comercio en las dos plantas), que `casas_calles.gd`
marca ahora `["obra"]` (con el OK de Texturas). Sin rehorneado. El frente mide lo que dice el Catastro, 5,75 m.

## Fuentes
- **Street View**, noviembre de 2024 (aún La Meseta), y 2019 y 2013 (antes, de ladrillo): 14 vistas en
  `tools/kebabdeluxe/capturas.py`. Las cámaras de Google en esta avenida están 2-3 m metidas hacia las casas.
- **La foto de Luis** del local de ahora: el rótulo, la banderola, los cuadros del montante, la hoja abierta, el
  comedor con bancos rojos y la tele, la escalera tras la puerta de la izquierda, el taburete de la acera.

## Lo que hay
Fachada azul marino de dos plantas. Abajo, el escaparate blanco: la puerta acristalada de la escalera, la puerta
doble con una hoja abierta y su montante de cuatro hamburguesas, y un mirador de tres paños con las cartas pegadas.
Encima, el rótulo luminoso de lado a lado y la banderola colgada a la derecha, los dos dibujados aquí
(`tools/kebabdeluxe/rotulo.py`): «Kebab Deluxe» en letra manuscrita (Segoe Script, la del título del juego), la cinta
amarilla «PIZZAS · TACOS · POLLO ASADO», los teléfonos como garabatos y sin la dirección. Un foco y el mazo de cables.
Arriba, el gran ventanal de medio punto en blanco (sin el medallón de La Meseta). En el tejado, la terraza tras su
barandilla de acero y el torreón de la escalera. Por el cristal se ve el comedor: tarima, bancos rojos espalda con
espalda, mesas oscuras, la tele, la barra negra con la carta iluminada; y la escalera subiendo.

## En el juego
- **No se entra todavía**: el frente para al jugador. Si Luis lo quiere, Sistemas tiene la flecha verde (`entradas.gd`)
  y bastaría un decorado aparte como el de la Papelería Rocas.
- **Su horario** (Luis, 16-11-2026): todos los días desde las 13:00; cierra a la 1:30 la noche de lunes a jueves y a
  las 2:00 la de viernes a domingo (`open_at(day, hour)`: la madrugada cuenta como el día anterior). Abierto, la hoja
  derecha abierta hacia dentro, las luces encendidas y los rótulos con sus colores (sin sombrear, como luminosos).
  Cerrado, las dos hojas cerradas, todo apagado, y los rótulos con la luz de la calle. Hoja `03_horario.jpg`.
- **Es la primera parada del sabotaje de Don Luis** (`sabotaje.gd`): lee la casa del mapa, que no cambia; la acera hasta
  2,1 m del frente queda libre para las cajas. `sabotaje` entero: 45/45.

## Lo que es aproximado
- Alturas, el ventanal y el escaparate: a ojo sobre las vistas, con los 5,75 m del frente como regla; ±0,3 m.
- El torreón y la terraza: por dos vistas oblicuas.
- El comedor y la escalera: por la foto de Luis, de noche y desde fuera.
- Los vecinos (de Texturas) son blancos en el juego y de ladrillo en la realidad.
- En la foto de Luis la parte baja y la pilastra derecha salen anaranjadas; por lo que dijo («colores exactamente
  el mismo») las he dejado azules: lo decide él.
