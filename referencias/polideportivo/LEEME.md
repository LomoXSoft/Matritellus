# Polideportivo Municipal

El pabellón de deportes del pueblo, al este de la Calle de Federico Martín Bahamontes (Catastro 4201010VJ5740S).
Luis, 28/11/2026, por Texturas: «Ese es el polideportivo. Se lo pasamos a pretil»; luego, con fotos del interior:
«Te paso imágenes por dentro. Quiero que se pueda acceder». En el juego pone POLIDEPORTIVO MUNICIPAL.

**Estado**: VISTO BUENO de Luis el 28/11/2026 («Polideportivo está bien, pero no le falta aquí carretera? (C.
Mariano Haro)»); la calle que echaba en falta se añadió ese mismo día (ver «Calle Mariano Haro»). A mis dos
preguntas había contestado «1. Si. 2. Calles con coches y algunos aparcados en el parking»: el azafrán está
PUESTO, hay coches aparcados y las calles son del mapa, con tráfico (ver «Calles, coches y azafrán»). No hay commit.

## Dónde y quién

- Código: `godot/scripts/polideportivo.gd` (la nave por fuera, sobre el kit `obra.gd`) y
  `godot/scripts/polideportivo_dentro.gd` (el interior, un decorado aparte en (1050, −1550)).
- Dibujos: `tools/polideportivo/dibujos.py` → `godot/assets/polideportivo/` (`emblema.png`, `pista.png`,
  `anuncios.png`, `marcador.png`). Si se redibujan hay que importarlos (`--headless --path godot --import`).
- Ortofoto del PNOA: `tools/ign/polideportivo.jpg` y `.json` (con `tools/fetch_ortho.py`).
- **Con rehorneado**: `tools/bake_godot.py` lleva `POLIDEPORTIVO_RC`; la caja del Catastro no se levanta y
  `map.json` lleva la clave `polideportivo` (`o`, `u`). Relieve, calles, árboles, áreas y aceras no cambian.
- En `world.gd`, `map_data.gd`, `entradas.gd`, `selftest.gd` y `bake_godot.py` solo se han añadido líneas.
- `godot/data/aceras_suelos.json` se reescribió con `aceras-suelos escribe` (las losas alrededor de la nave).

## Fuentes

- La ortofoto del IGN, para la planta: el borde blanco de la cubierta. OpenStreetMap va 2 m desviado y el Catastro
  da una caja simple.
- Street View 2024 desde el aparcamiento, el camino del sur y la tierra del oeste (las doce fotos de Texturas).
- Las fotos de Luis: la puerta de frente (da las medidas de la fachada) y cuatro del interior.
- Las fotos de Luis y las capturas de Maps se quedan fuera del proyecto; en `guion/fotos/polideportivo/` solo hay
  capturas del juego.

## La nave (marco del sitio)

- Marco (u, v): u del muro oeste al este, v del muro norte al sur, desde la esquina noroeste
  `A = (−42,4, −1046,4)`, girado 9°. y = 0 es el suelo ante las puertas. El suelo cae 0,6 m hacia el oeste: los
  muros bajan hasta él, sin terraza.
- 31,3 × 44,4 m. Cuatro cubiertas de chapa gris con hastial quebrado: suben suave desde el sur, giran en la
  cumbrera y caen de golpe al norte (ese lado es de chapa traslúcida). Alero 6,9 m, limahoya 8,1, quiebro 9,8,
  cumbrera 10,4.
- Fachada este escalonada: las dos naves de los extremos salen 2,7 m y llevan un cuerpo bajo delante (3,45 m, con
  ventanas de lamas tras rejas). En el entrante, las dos puertas de cristal con paneles rojizos bajo las letras, y
  una escalera de hormigón a cada lado hasta un rellano (3,25 m) y una puerta alta.
- Medidas de la foto de Luis (unos 95 px por metro): puertas de 1,9 × 2,44 m a 0,44–2,34 m del centro; pares de
  ventanas de 0,95 × 0,73 m con alféizar a 1,77 m; letras de 0,3 m a 3,1 m de alto, POLIDEPORTIVO centrada 2,32 m
  al sur y MUNICIPAL 1,86 m al norte; placa de 0,66 × 0,42 m en las pilastras del centro.
- Sobre la placa, el pabellón real lleva los cinco aros: aquí va **un emblema nuestro** (un balón en una corona).
- Sur y oeste: ladrillo ciego con rejillas negras abajo; portón blanco de chapa al oeste; caseta de ladrillo en la
  esquina suroeste (su puerta y el lado norte son inventados: no hay foto).
- Alrededor: losas, el aparcamiento con 18 plazas al este, la calle del norte con la tapia blanca del campo y sus
  cipreses, y el callejón del sur con cinco árboles en su acera. **Las calles son del mapa desde la segunda tanda**
  (abajo); el asfalto del aparcamiento y de la calle del norte sigue puesto a mano, 3 cm por encima del del mapa.
- Las escaleras de fuera no se suben (la puerta de arriba está cerrada).
- El ladrillo es `brick_wall_003@0.9` con tinte (1,0, 0,9, 0,82): la textura sola salía demasiado naranja.

## Dentro

- Se entra por la flecha verde ante la puerta sur de las dos (`entradas.gd`). **Siempre abierto**: Luis pidió que se
  pudiera pasar y no dio horario. Dentro es siempre de día (las ventanas y los lucernarios brillan a cualquier hora).
- Marco del decorado: x a lo largo de la nave (−22 norte … +22 sur), z desde el muro de las puertas (0) hasta el
  del fondo (28), y = 0 el suelo.
- La grada, a lo largo del muro de las puertas: cinco filas de asientos rojos (290) sobre un frente azul, pasarela
  arriba a 3,2 m con barandilla blanca, la fila de ventanas, un arco en cada extremo.
- El paso cruza la grada por el centro, bajo la pasarela: las dos puertas de cristal y, entre ellas, la puerta doble
  verde con dos ojos de buey (cerrada), en un cajón de 0,55 m.
- **Una escalera a cada lado del paso, que se sube** hasta la pasarela (rampas en `MapData.decks`). Cada mitad de la
  pasarela tiene la suya; el puente sobre el paso está cerrado con barandilla y no se pasa a los asientos.
- La pista: azul, 40 × 20, líneas de balonmano en blanco, baloncesto en azul oscuro y voleibol en amarillo, borde
  naranja; dos porterías de bandas rojas y blancas y dos canastas colgadas del techo.
- En el muro del fondo: el marcador, el portón blanco y **doce carteles con tiendas del propio juego** (MERCAMONA,
  TODOPIZZA, TELE DÜRUM, POLLOS ASADOS JAVI, ÓPTICA CORSA, TALLERES XANDRO, AHORROS RURALES, MASAHORRO, PIZZERÍA
  TOTI, CAFETERÍA RIZE, KEBAB DELUXE, PISACASTAÑA), sin teléfonos ni direcciones.
- No hay nadie dentro: las figuras las decide Luis. 9 luces sin sombras.
- Aviso de Sistemas (28/11): `way_to` mide desde `in_door`, así que todo el interior debe quedar a menos de 60 m
  de ella (el rincón más lejano está a 36 m) y el decorado a más de 60 m de cualquier calle (está a 238 m). Si se
  pone gente dentro, comprobar que `g._reach(su p)` da el `door_out` de la nave.
- La cámara (`room_at`): «vestibulo» (desde pasado el puente, cruzada en el paso: colgada en tu lado quedaba encima
  de tu cabeza), «pista» (va contigo por el pie de la grada) y «grada» (a 3,15 m sobre la pasarela, bajo las cerchas).

## Calles, coches y azafrán (28/11, segunda tanda)

Luis: «1. Si. 2. Calles con coches y algunos aparcados en el parking».

- **Azafrán escondido** (`_saffron` en `polideportivo_dentro.gd`, id `polideportivo`, `hidden`): arriba en la grada,
  en el rincón del extremo norte de la pasarela, detrás de la última fila y junto al arco de la escalera de fuera.
  En el decorado es (−21,5, 3,2, 0,38). Se pone antes de `_indoors(self)` para que coja la capa del decorado. Hay
  que subir y andar toda la pasarela; desde la pista se ve su brillo sobre los asientos pero no se alcanza.
- **Coches aparcados** (`polideportivo.gd`, al modo del Merkocarry: `car.gd`, `G.cars`): `bay_spots` (el morro a
  u 36,3, mirando a la nave, en el centro de cada plaza), `cars_wanted` (5 de 8 a 17, 7 de 17 a 22, 2 de noche),
  `_tend_cars` una vez por segundo desde `_process` (aparecen y se van solo donde no se ve), `settle_cars(G)` para
  las fotos de la prueba. Más probables cerca de las puertas. Son coches del juego: se pueden coger.
- **Calles del mapa**: OSM no tiene estas calles, así que van en `tools/bake_godot.py` como `EXTRA_WAYS` (líneas
  insertadas tras `RESHAPE`): una calle `service` (5 m, k 0, sin nombre, doble sentido) en bucle, medida sobre la
  ortofoto: nodo 899 (cruce de Bahamontes con el Camino Viejo) → (−70,07, −1057,11) → (4,41, −1045,31) →
  (−4,39, −989,76) → un nodo nuevo sobre Bahamontes en (−59,80, −998,53), metido en esa calle entre 899 y 900. En
  el marco de la nave: calle del norte por v −6,25, pasillo del aparcamiento por u 46,4, callejón del sur por v 50.
  Los puntos nuevos van al final (3191–3194): ningún índice se mueve. Sin fondo de saco.
- Los cinco árboles del sur pasaron de v 49,6 a v 53,7 (la acera del otro lado del callejón, como en la ortofoto).
- `map.json` tras el horneado, clave a clave: 4 nodos y su `clr` al final, la calle nueva, el nodo en Bahamontes, y
  la casa `bah_8` de Texturas (la arista de su frente pasa a dar a calle, base 25,22 → 25,4). Relieve, aceras,
  áreas, árboles, contornos, muros y POIs, idénticos. (`paz_37` y `paz_39` cambiaron por trabajo de Texturas.)
- `godot/data/aceras_suelos.json` reescrito otra vez (`aceras-suelos escribe`): la cinta de acera de la calle nueva
  queda bajo mi asfalto y mis losas.
- Avisados Sistemas y Texturas antes del horneado, con el diff de un ensayo en seco. **Contestaron después**:
  Sistemas, que arrancar en el nodo 899 le vale (mejor un cruce de 4 brazos que un tramo de 6 m entre dos cruces) y
  que las esquinas de 90° no se achaflanen salvo que alguien se atasque; Texturas, que lo de `bah_8` le vale.
- **Prueba de tráfico** (pedida por Sistemas): un coche del tráfico (`g.traffic.add` con `route`) da la vuelta al
  bucle en los dos sentidos y llega al otro extremo; lo más que estuvo parado, 3,1 s.
- Ensayo en seco del horneado: `fix9.py 899 dry` en el scratchpad hornea en memoria a una copia, sin tocar nada.

## Calle Mariano Haro (28/11, tercera tanda)

Luis, con mi ortofoto y un círculo rojo en la esquina sureste: «Polideportivo está bien, pero no le falta aquí
carretera? (C. Mariano Haro)».

- **Qué faltaba**: el callejón del sur no acaba en el aparcamiento; es la Calle Mariano Haro y sigue al este, entre
  la nave del taller y la casa del sur, hasta la Avenida de la Constitución. OSM (la fuente del horneado) no la
  tiene; Google Maps sí, con ese nombre de Bahamontes a la Avenida (también dibuja dos pasillos en el aparcamiento:
  el segundo se añadió después, ver «Segundo pasillo»; y la calle del norte de un solo sentido: eso no se ha
  tocado, los sentidos únicos salen solo de OSM).
- **En el horneado** (`EXTRA_WAYS`, mis líneas): ahora son dos calles `service` de 5 m, k 0, doble sentido.
  La del norte con el pasillo, sin nombre: `[899, 3191, 3192, 3193]`. Y «Calle Mariano Haro»:
  `[3194, 3193, 3195]`, del nodo que ya había sobre Bahamontes al pie del pasillo y de ahí a un nodo nuevo sobre la
  Avenida, (61,33, −979,39), metido entre 834 y 835 (el corte de la recta v = 50 con la Avenida, calculado). Una
  entrada de `pts` puede ser `('at', x, z)`: un punto que el mapa ya tiene. Ningún número anterior cambia.
- Es `service` y no `residential` a propósito: la real tiene unos 5 m de calzada entre dos filas de árboles, y así
  no le salen rayas, pasos de cebra en su boca (que cae en mi asfalto del aparcamiento) ni badenes. El nombre sí
  llega al jugador (`hud.show_street`).
- **Árboles** (`polideportivo.gd`, tras los del paseo del sur): cinco al norte (u 66,8 + 9,2 k, v 46,6) y tres al
  sur (u 63,6 + 9,7 k, v 53,7), sobre las aceras de la calle, medidos en `tools/ign/polideportivo_haro.jpg`.
  Entre la acera del norte y la nave del taller queda una franja de tierra de unos 3 m (la real está pavimentada).
- `map.json`, clave a clave contra un horneado en seco sin mi cambio: un nodo y su `clr`, las calles, y la base de
  dos bloques genéricos junto a la calle (la casa de (37, −962) sube 27 cm, la nave del taller baja 1 cm). Ninguna
  casa de Texturas cambia por esto. El horneado cogió además lo que Texturas tenía en disco sin hornear (`paz_46`
  a `paz_57`, `paz_44`); se le avisó antes con la lista.
- `godot/data/aceras_suelos.json` reescrito por tercera vez (faltaban 10 cuadros y sobraban 37).
- **Contestaron después del horneado**: Sistemas, de acuerdo con el rehorneado y con que reescribiera yo el
  archivo de aceras, y que el mobiliario rebarajado no le molesta; Texturas, que sus ocho `paz_*` estaban listas
  para hornear, y que después hornea él (solo mueve frentes de `paz_46` a `paz_57`).
- En la Avenida salen solos dos pasos de cebra a los lados del cruce nuevo (la real tiene uno al sur).
- Ensayo en seco: `fix13.py dry` (con mi cambio) y `dry0.py` (el horneado tal como está en disco), los dos a una
  copia en el scratchpad; `dif_haro.py antes después` compara clave a clave.
- Foto (capturas del juego): `guion/fotos/polideportivo/polideportivo_haro.jpg`.

## Segundo pasillo del aparcamiento (28/11, cuarta tanda)

Le dije a Luis que Google Maps dibuja dos pasillos en el aparcamiento y yo tenía uno; contestó «Dibújalo».

- **La ortofoto** (`tools/ign/polideportivo.jpg` con la rejilla u, v): el asfalto real no acaba en u 52; llega al
  muro del taller del este. Su borde este, de norte a sur: u 65,6 (v −10,5), 63,8 (v 6,2), 61,1 (v 24,9), 58,35
  (v 43,4). No hay rayas de plazas en ese lado ni nada que separe dos pasillos: es una sola explanada.
- **En el horneado** (`EXTRA_WAYS`, tercera entrada): `service`, sin nombre, `[3192, 3196, 3197, 3198]`. Sale de
  la cabeza del primer pasillo (3192), sigue al este hasta (18,83, −1043,03) (u 61, v −6,25), baja en diagonal,
  como el muro, por (10,48, −1012,71) (u 57,5, v 25) y entra en la Calle Mariano Haro en (3,61, −988,49)
  (u 54,5, v 50), un nodo nuevo (3198) entre 3193 y 3195. Mariano Haro queda `[3194, 3193, 3198, 3195]`.
  Ningún número anterior cambia.
- Quedan dos cruces a 8,1 m en Mariano Haro (3193 y 3198) y un tramo de 14,6 m en la calle del norte. Sistemas:
  vale así si los coches de la prueba no se atascan; si no, juntar los dos pasillos en un nodo. No se atascan.
- **`polideportivo.gd`**: `EAST` (el borde este), el asfalto del aparcamiento es ahora ese polígono, la losa del
  pie del muro del campo llega a u 65,6, el muro blanco a u 67,2 y hay dos cipreses más. `BARE` llega a u 66.
- **`paz_56` (de Texturas)**: con este horneado su frente pasa de una diagonal a un escalón de 0,3 m. No es por la
  calle en sí: el solar crece igual en los dos casos (7,5 m del frente, 0,3 m; los 2,6 m del este no, por la
  calzada de la bocacalle), y `add_part` simplifica con tolerancia 0,3: según en qué vértice empiece el anillo
  que devuelve la unión, el escalón de 0,24 m se queda o desaparece. Cualquier cambio de calles le da la vuelta.
  Texturas avisado antes de hornear; dijo que horneara. Después, a petición de Luis, lo fijó con `"grow": 0` en
  `paz_54` y `paz_56` y horneó él: frente recto, sin escalón; nodos y calles iguales.
- `map.json`, clave a clave contra el horneado en seco sin mi cambio: tres nodos y su `clr`, las calles, la base
  de la nave del taller (+9 cm) y `paz_56` con el contorno de su manzana.
- `godot/data/aceras_suelos.json` reescrito por cuarta vez (el asfalto nuevo: 879 cuadros).
- Ensayo en seco: `fix15.py dry` y `dry0.py`, comparados con `dif_haro.py`.
- Foto (capturas del juego): `guion/fotos/polideportivo/polideportivo_pasillo.jpg`.

## Pruebas (28/11)

- Tras el segundo pasillo: `polideportivo` OK (10), con cinco calles comprobadas y siete viajes de un coche del
  tráfico (los cinco de antes, y bajar y subir por el segundo pasillo; lo más que estuvo parado, 0,2 s) y las
  vistas `pasillo_este` y `aire_parking`; `aceras-suelos` OK (12) tras `escribe`; `relief` OK (19);
  `zfight solo=polideportivo.gd` OK; `tools/cache_casas_check.py` OK. No se ha pasado la prueba completa.

- Tras la Calle Mariano Haro: `polideportivo` OK (10), con las cuatro calles comprobadas por su nombre y cinco
  viajes de un coche del tráfico (la vuelta por el norte y el pasillo en los dos sentidos, Mariano Haro en los dos
  sentidos, y de la Avenida al pasillo; lo más que estuvo parado, 0,7 s) y las vistas `haro`, `haro_avenida` y
  `aire_haro`; `aceras-suelos` OK (12) tras `escribe`; `relief` OK (19); `zfight solo=polideportivo.gd` OK;
  `tools/cache_casas_check.py` OK (3501 casas). No se ha pasado la prueba completa.

- `polideportivo`: OK (10) tras la segunda tanda (azafrán, coches, calles, la vuelta de un coche del tráfico y
  las zonas sin muebles: cinco comprobaciones más, y vistas
  `parking`, `calle_norte`, `callejon`, `callejon_oeste`, `aire_sur`, `dentro_azafran`). 17 vistas de fuera, 2 de
  noche, 16 de dentro y 5 con la cámara del juego, entrando por la puerta. Comprueba: construido; los muros te paran, el mapa y el minimapa conocen la nave y la caseta, nada en el
  asfalto; el decorado está lejos, cerrado y con sus suelos donde deben; se anda del vestíbulo a la pista, se suben
  las dos escaleras, se vuelve a la salida y no se pasa de donde no se debe; la puerta mete y saca.
- `zfight solo=polideportivo.gd`: quedan unos 0,4 m² exactos, de caras escondidas (traseras de peldaños y marcos).
  `zfight solo=polideportivo_dentro.gd`: menos de 0,1 m². La primera pasada dio unos 5,6 y 2,7 m², ya arreglados
  (alféizares, paneles de las puertas, los remates de los hastiales en el plano de la cubierta, la escalera metida
  en su murete, un banco sobre dos sillas).
- `aceras-suelos`: OK (12), después de reescribir el archivo con `escribe` (las dos veces: la nave y las calles).
- `tools/cache_casas_check.py`: OK (también tras el horneado de las calles). Una primera pasada, en la primera
  tanda, falló porque otra sesión cambió `lotes.gd` entre arranques.
- Tras las calles: `zfight solo=polideportivo.gd` OK, lo mismo que antes (caras escondidas).
- `map.json` comparado clave a clave con el publicado: de este sitio solo se van un contorno, cuatro muros y un
  tejado plano (la caja del Catastro) y entra la clave `polideportivo`. Lo demás son las casas `paz_*` de Texturas.

## Pendiente

- **Nave del taller, sin pared al patio: ARREGLADO** (Luis: «Dejalo ensanchado y arreglado el fallo viejo de la
  nave»; el aparcamiento ensanchado se queda). Al bloque genérico del este le faltaba en `walls` el tramo
  (14,2, −1012,2)–(32,2, −1009,9), ya en el mapa publicado. Causa: el horneado pregunta en la mitad de cada pared
  si un vecino la entierra; esa pared es un solo tramo de 46 m y un anexo tapa solo su mitad este. Arreglo:
  `WALL_CUTS = [(32.2, -1009.9)]` en `tools/bake_godot.py` (antes de `polys = [...]`): mete un vértice en la pared
  del edificio genérico que pasa por el punto y cada mitad se pregunta por separado. En `map.json` solo entra esa
  pared (y un quinto punto, en la misma recta, en el tejado plano de la nave). `tools/mira_nave.py` del scratchpad
  hornea en memoria y dice qué parte esconde cada pared de una zona. Foto: `polideportivo_nave_taller.jpg`.
  Pruebas tras ese horneado: `polideportivo` OK (10), `relief` OK (19), caché de casas OK.
- Nada de Luis: dio el visto bueno el 28/11. Sin commit (los hace Sistemas).
- El mobiliario al azar del pueblo se ha vuelto a barajar con la Calle Mariano Haro (la Avenida tiene un tramo más).
- **Zonas sin muebles** (resuelto): `props.gd` puso un contenedor verde al azar en el pasillo del aparcamiento,
  delante de las puertas. Sistemas hizo `world.sin_muebles` (Rect2 en x, z del mapa: ni muebles al azar ni coches
  aparcados al azar del arranque) y `polideportivo.gd` mete en `build`, antes de `_grounds()`, las cajas de su
  asfalto (`BARE`: el aparcamiento con su pasillo y la calle del norte). El callejón del sur se deja al pueblo:
  tiene aceras. La prueba comprueba que no hay ni mueble ni coche al azar ahí.
- **El mobiliario al azar del pueblo se ha rebarajado**: ese reparto gasta la misma secuencia aleatoria tramo a
  tramo, y Bahamontes tiene un tramo más. Pasa con cualquier horneado que parta o añada tramos. Avisado Sistemas.
- Los coches aparcados al azar del arranque (`game.gd`) ya no caen en el aparcamiento ni en la calle del norte;
  en el callejón del sur sí pueden, como en cualquier otra calle.
- `relief`: OK (19) tras el horneado. No he pasado la prueba completa.
- Horario: no tiene.
