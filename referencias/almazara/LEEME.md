# La almazara «González de la Ruz»

Luis, 21/11/2026: «Ahora ponte con aceites García de la Cruz (que llamaremos Gonzalez de la Ruz) tiene fachada tanto en calle triunfo como en carretera de villacañas».

Es la almazara real de la carretera de Villacañas (Catastro 4699012VJ5649N, Calle Reyes Católicos 23, de 1953 en adelante), con la trasera en la calle del Triunfo. **En el juego se llama siempre «González de la Ruz»**, con tilde (Luis, al aprobarla: «Mejor con tilde. Visto bueno»): rótulo, emblema (una aceituna en su ramita) y mural son dibujos propios (`tools/almazara/dibujos.py`). No llevan el nombre real, ni su cruz, ni su aniversario.

## Scripts y datos

- `godot/scripts/almazara.gd` (`const READY := true`, `world.almazara`, paso «the oil mill» de `world.gd`). Marco: el del mapa; y = 0 es el patio. `P(s, d)`: s metros a lo largo del frente de la carretera desde su esquina suroeste, d metros hacia dentro.
- **Con rehorneado**: bloque ALMAZARA de `tools/bake_godot.py`. Salta ese RC, mete sus contornos en `block_list`, no planta árboles en su zona y deja la clave `almazara` en el mapa.
- Dibujos en `godot/assets/almazara/`. La chapa nervada reutiliza `assets/masahorro/chapa.png`.
- Prueba: `python tools/run_tests.py almazara` (21 capturas y 3 comprobaciones); `_almazara_checks()` va también en la completa.

## Qué hay

Por la carretera, de suroeste a noreste (s en metros):

- **s 0–15, el testero de la nave vieja**: blanco sobre zócalo azul, cubierta a un agua (9,6 m junto al taller, 6,6 m junto a la entrada) y el mural pintado.
- **s 15–26,5, la entrada**, abierta, entre dos setos. Dentro, el patio:
  - el costado de la nave vieja con la puerta de la tienda, el tablero «TIENDA», el cartel alto y la banda de chapa arriba;
  - al fondo, las oficinas color salmón, de dos plantas y teja;
  - a su lado, la nave de recepción, abierta por el frente y por el lado de las oficinas, con su cabina, su tolva, su cinta y depósitos.
- **s 26,5–89, el muro largo**, blanco con zócalo azul y el rótulo cada veinte metros. Detrás: banderas, cobertizo de madera, cuatro depósitos de acero y un edificio bajo de instalaciones.
- **s 89–97,5**, un tramo más alto (un edificio pequeño).
- **s 97,5–165, la nave alta**, de 14,7 m, con el rótulo grande. Acaba en punta; el rótulo se repite en la pared oblicua de detrás. Después, 7 m de valla de chapa blanca.

Por la calle del Triunfo, de suroeste a noreste: el otro testero de la nave vieja (ventanas con reja, dos respiraderos), un bloque blanco de dos plantas con azotea, un tramo viejo bajo con alero de teja y el muro largo de las naves bajo el borde de una cubierta de chapa (ventanas altas, aparatos de aire, bajantes).

Hay un azafrán escondido en el rincón entre el edificio de instalaciones y el edificio pequeño, tras el muro (`"id": "almazara"`, `"hidden": true`).

## Fuentes

- Catastro (plantas y alturas en plantas), con `python tools/house_data.py 4699012VJ5649N`.
- Ortofoto del IGN (`tools/ign/almazara.jpg` y `almazara_fina.jpg`), para lo que Catastro no tiene: la nave alta y la cubierta con placas de la nave de recepción.
- Street View de noviembre de 2024 por las dos calles (`tools/almazara/capturas.py`; las fotos no se guardan en el repositorio).

## Trampas

- **El relieve del juego hace caer la carretera 4 m hacia el noreste** entre s 30 y s 100 (es 2,5 veces el real). El muro, su zócalo y sus rótulos siguen el terreno a tramos de 2,5 m (`_follow`).
- **El muro del Triunfo va retranqueado**: un metro en el testero de la nave vieja y 0,4 m al final del bloque. El horneado reserva 2,4 m a cada lado del eje de esa calle y la pared de Catastro se metía hasta 0,95 m. Con la línea de Catastro, la holgura de un nodo bajaba de 2,3 a 1,5 m.
- **La nave alta no está en Catastro.** Su planta sale de la ortofoto: un triángulo con el frente en la carretera. Las cámaras de Street View de ese extremo no cuadran entre sí (dan la esquina entre s 168 y s 179); se ha tomado la punta de la ortofoto, s 165.
- **La nave de recepción es la cubierta con placas de la ortofoto**, no el contorno de Catastro, que es menor. Se fijó con la foto desde la entrada: su esquina está a unos 32 m de esa cámara y mide 9,2 m de alto.
- **El frente del taller Errejota acaba en la pared suroeste de la nave vieja**, 3,7 m por detrás de la esquina: ese trozo de pared se ve y lleva zócalo azul.
- Después de añadir o cambiar los PNG hay que pasar Godot con `--headless --path godot --import`.

## Lo que es aproximado

- No tiene interior: la tienda no se puede visitar.
- Las naves entre el Triunfo y el patio son un solo cuerpo con cubierta plana de chapa; las reales son varias, a dos aguas.
- La nave grande de detrás de la alta (el lóbulo noreste de Catastro) es un cuerpo liso de 10 m.
- Las alturas del Triunfo salen de cámaras a 2,5–5 m del muro: valen con un margen de medio metro.
- El mural es propio: recuerda al real (cuarto de círculo gris, motivo en la esquina, nombre, rama de olivo), pero no lo copia.
- No hay cables ni postes de la luz, ni coches aparcados en el arcén.
