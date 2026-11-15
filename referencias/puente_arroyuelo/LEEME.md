# Referencia: el puente de Arroyuelo Medio

Pedido por Luis el 15-11-2026: «Tratar de reworkear el puente de arroyuelo medio. Puede ser difícil, ya que hay pocas
fotos. Aquí también quiero dos versiones, una con excavadoras y equipo de trabajo de demolición cerca además de
carteles de peligro porque se va a demoler y otro limpio de carteles y sin equipo de demolición ni excavadoras cerca.
El primer modelo saldrá antes de la misión de las firmas y el segundo a la mañana siguiente si el jugador no está
mirando ni cerca de la zona».

Y antes, el 13-11-2026, sobre el puente de entonces: «El puente lo has hecho plano, obviamente los lados estaban
elevados (a altura más o menos de la cintura) para no caerte y la gente podía pasar por enmedio, quizás tengas que
hacerlo más ancho para que quede bien con estos ajustes. También habría que trabajar lo hundido que está el arroyuelo
respecto a las aceras/casa en algunos puntos. Podrías usar street view para ello».

El modelo es `godot/scripts/puente.gd` (sobre `obra.gd`). Herramientas: `tools/puente/`.

## Qué hay en esta carpeta
- `foto_1.jpg`: fotograma de una película de 1984 (José-María Moreno García, «Puentecillo del Arroyuelo»): los
  chiquillos saltando de un pretil a otro. `usuario_06_…1984…jpg`: otro fotograma de la misma.
- `foto_2.jpg` a `foto_4.jpg` y `usuario_01` a `usuario_05`: capturas de Luis de Street View, mayo de 2009, desde la
  calle del Santo, el cruce con Matías Pérez, Arroyuelo Alto y el Palo. `foto_5.jpg`: el plano con el sitio marcado.

## Marco
Origen en el centro del puente, mapa (-149,61, -261,23). `x` cruza el cauce hacia las casas de los pares (este-
noreste); `z` baja por el cauce hacia el cruce con Matías Pérez (la calle del Santo queda hacia z = -47). Alturas
desde el tablero, que está al nivel de las aceras de al lado.

## Fuentes
- **Street View, mayo de 2009** (la única pasada con el puente en pie; el coche no cabía por debajo y las fotos son
  desde las calles de alrededor): lista en `tools/puente/capturas.py`. Las fotos no se guardan: son de Google.
- **Ortofotos del IGN**: 2006 y 2009 (con puente), 2012 (ya sin él: lo quitaron entre 2009 y 2012) y la vigente
  (`tools/ign/puente_*.jpg`).
- **Catastro y las casas del juego**: la línea de fachadas de la fila este (`arroyuelo_34`, `arroyuelo_36`) y la de
  la manzana de enfrente. El puente se colocó respecto a ellas.

## Medidas
- **Cauce**: 6,45 m de muro a muro, de hormigón; aceras altas a los dos lados (1,45 m la de los pares junto al
  puente, más ancha hacia la calle del Santo; 1,2 m la de enfrente), de baldosa en damero crema y granate, sobre
  muro de mampostería con albardilla de hormigón, de unos 0,75 m de alto.
- **Puente**: de acera a acera, una losa de hormigón sobre una pila en medio (ladrillo sobre un bloque de piedra
  medio enterrado); un pretil de ladrillo a cada lado, de medio metro, con la coronación redondeada y los extremos
  bajando en cuarto de círculo hasta la acera. Hueco bajo la losa: unos 0,7 m. Ancho real: unos 2 m.
- **Sitio**: su extremo este queda delante de donde se juntan la casa crema (`arroyuelo_36`) y la de ladrillo
  (`arroyuelo_34`), cuyo portal y ventanas dan a la acera alta. La acera sigue 2,4 m más y baja en escalones que
  acaban en la jamba de la cochera de esa casa, que está a pie de calle.
- **Lado oeste**: la esquina empedrada entre el cauce y Matías Pérez, con su árbol, cerrada hacia el cauce por un
  muro de mampostería; el puente llega a su esquina.
- **Arriba, junto a la calle del Santo**: la acera oeste acaba en punta con un arbolito.

Cómo se fijó el sitio: la ortofoto de 2009 daba el puente 1,4 m al oeste de lo que dicen las fachadas; se corrigió
resecando la panorámica del cruce con los huecos de la casa de ladrillo (`tools/puente/resecar.py`: la cámara estaba
2,8 m más allá de donde dice Google y su rumbo 4,3° girado).

## En el juego
- El tablero queda 1,05 m sobre el cauce (algo más que el real) y el puente mide 2,6 m de ancho (más que el real),
  para que se pueda pasar con alguien encima; los pretiles, 0,56 m.
- Las aceras van a nivel con el tablero desde 14,6 m cauce arriba hasta los escalones; más arriba siguen la
  pendiente de la calle, 0,55 m sobre ella. El horneado (`PUENTE` en `tools/bake_godot.py`) sube a la acera las
  casas de la fila este que quedaban por debajo.
- La cochera de `arroyuelo_34` es un hueco en la casa (`k=hueco`) y la puerta, desde la calle, la pone `puente.gd`.
- `set_works(true/false)`: la obra de demolición. Empieza puesta. Se va sola la primera mañana después de entregar
  las firmas, con el jugador a más de 140 m y sin mirar (`_process`; guarda `stats["obra_h"]` y `stats["obra_fuera"]`).
  Con `--puente-limpio` en la línea de órdenes arranca sin obra ni pancarta (para verlo o fotografiarlo).
- La cinta del ayuntamiento (`close_off`) y lo de la manifestación (`dress`) siguen como estaban.
- Prueba: `python tools/run_tests.py puente --window` (20 fotos, 10 de cada estado, y 5 comprobaciones).

## Lo que es aproximado
- El **alto** de todo sobre el cauce: el relieve del juego exagera las pendientes 2,5 veces, así que las aceras no
  pueden seguir a la vez la calle y las puertas. Junto al puente mandan las puertas.
- La **punta de la acera oeste** junto a la calle del Santo es más corta que la real (en el juego esa calle pasa por
  donde estaba) y la acera este acaba antes, en unos escalones, donde acaba la manzana del juego.
- La **esquina empedrada** tiene muro también hacia Matías Pérez, con escalones: en la realidad esa calle sube y
  queda a su nivel, con solo un bordillo.
- Las **casas** de los dos lados, salvo las dos de la fila este hechas a mano, son las genéricas del juego.
- El año «1911» de la piedra es invención nuestra (ya estaba en el puente anterior).
- La **obra** (máquinas, vallas amarillas, carteles) es inventada: en la realidad no consta cómo lo quitaron.
