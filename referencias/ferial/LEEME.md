# Referencia: el recinto ferial y mercadillo

Pedido por Luis el 17-11-2026: «Recinto ferial y mercadillo. Son una entrada con fuente, una entrada con columnas con
enredaderas, y tres caminos asfaltados con aceras amplias. Donde se montan ciertos eventos del pueblo». Veredicto (17-11,
con el parque): «Genial. Ha quedado increíble».

El modelo es `godot/scripts/ferial.gd` (sobre `obra.gd`), en `world.ferial`, en el marco del mapa (x este, z sur; cada
pieza a la altura del terreno). Está al sur del Auditorio, entre el final de la calle del Cristo y la carretera del este,
por (150, 600). Usa los caminos, la rotonda, las áreas y los árboles que ya tiene el mapa, y pone lo suyo encima. El único
rehorneado fue para cerrar sus calles al tráfico (más abajo). Herramientas en `tools/ferial/`.

## Fuentes
- **Street View**: el coche entró por los caminos en marzo de 2013. En noviembre de 2024 solo pasó alrededor (la carretera
  del este y la calle del norte). `tools/ferial/capturas.py`; las fotos son de Google y no se guardan aquí.
- La **ortofoto** (PNOA, `tools/ign/ferial.jpg`), con la cuadrícula del mapa y las calles del juego: `tools/ferial/plano.py`.
- Google Maps: sin fotos 360 dentro, sin horario.

## Lo que lleva
- **Los tres caminos**: el asfalto del mapa con bordillos a los dos lados (cortados donde cruza otro camino). Entre ellos y
  alrededor, tierra compactada clara en vez del césped y de las aceras que pone el mapa: las «aceras amplias» donde se
  montan los puestos y las atracciones. Farolas altas de brazo curvo cada 24 m en los tres caminos largos, y cuatro
  parejas de contenedores beige de tapa verde (`world.extra_props`, se pueden tirar).
- **La entrada con fuente**: la isla de la rotonda, con bordillo, un anillo de adoquín rojo, el vaso de piedra con su
  barandilla de hierro, el agua, el surtidor y la tapa de registro. El vaso es sólido. (En el juego la rotonda está unos
  4 m al este de la real; la fuente va en la isla del juego.)
- **La entrada con columnas con enredaderas**: la pérgola junto a la calle del norte, de x 166 a 207. Lleva dos hileras de
  columnas cada 3,2 m cubiertas de hiedra, vigas de hiedra encima, un arco de hiedra entre cada dos columnas del lado de
  la calle y el paseo enlosado debajo. Las columnas son sólidas.
- **La explanada del mercadillo**, junto a la entrada norte: baldosa a cuadros rojos y blancos de bordillo a bordillo (sobre
  las aceras del mapa), y encima filas de pórticos de acero azul. Son postes en una cuadrícula de 5 x 4,4 m paralela al
  camino de la rotonda, con vigas en las dos direcciones a 3,1 m y los extremos volados.

## Sin líneas y sin coches (Luis, 17-11: «El recinto ferial sin líneas de tráfico. Y tampoco deben circular coches por ahí»)
- En el horneado (`FERIAL_ZONE` en `tools/bake_godot.py`) se cierran al tráfico las calles sin nombre de dentro del recinto:
  los tres caminos con la U, la rotonda, la calle de la rotonda al este, la entrada norte y el carril de la explanada (7).
  Pasan a k 2, `pedestrian`, `paved` 4, con el pasillo de calle de coches, así que no se mueve ninguna casa: sin tráfico,
  sin coches aparcados, sin líneas ni pasos de cebra.
- `ferial.gd` pone su asfalto encima (`_asphalt`), y `empedrado.gd` salta `paved` 4, con OK de Texturas.
- La calle del norte (la de la pérgola) y la carretera del este siguen siendo de coches.

## El parque del Paseo del Cristo (Luis, 17-11, con su captura en rojo y azul: «te faltaría la parte que se ve desde Paseo de Cristo»)
El «Parque del Recinto Ferial», entre el Paseo del Cristo, la calle de la Huerta y la calle del recinto. Lo hace `_park()`
en `ferial.gd`, con Street View 2024 desde el Paseo y la Huerta, 2013 desde la calle del recinto, y la ortofoto:
- junto al Paseo: una placita de adoquín gris con la fuente ovalada de arenisca (12 x 6,8 m), dentro de una pérgola de hiedra
  en semicírculo (radios 16,2 y 19 m) abierta al Paseo, con un paso hacia dentro;
- la pérgola de hiedra a lo largo de la calle de la Huerta, con su seto bajo junto a la acera (dos pasos);
- tras la pérgola de la calle del recinto, una placita con la fuente pequeña redonda de barandilla y setos alrededor;
- césped, árboles propios (y en los alcorques de la acera del Paseo), las aceras del Paseo y de la Huerta de baldosa a
  cuadros con bordillo, y en la esquina el quiosco negro bajo la hiedra con la caja blanca de la luz;
- en el horneado, `ferial_park` hace que el mapa no plante allí sus árboles (20 menos), con OK de Sistemas y Texturas.

## La calle principal (Luis, 17-11, con una línea dibujada: «La linea roja es la "calle" principal del recinto (las
## fuentes están en mitad). Se divide en camino empedrado (azul) y asfalto (rojo)»)
- Una sola recta, desde el camino del medio del recinto, por la fuente de la rotonda, la explanada, la calle del recinto,
  la fuentecilla y la fuente ovalada, hasta el Paseo del Cristo: `AXIS_P` (el centro de la rotonda) y `AXIS_D` en ferial.gd.
- En el recinto es el asfalto que ya había (el camino del medio y la entrada norte). En el parque, un camino de adoquín
  (la textura del empedrado del pueblo) de 2,4 m, con un círculo de adoquín alrededor de la fuentecilla.
- Las tres fuentes están en la recta. Las pérgolas tienen hueco en ella: en la de la calle del recinto, centrado (el eje
  la cruza algo en diagonal); en la de semicírculo, sin la columna del medio. Los setos de la placita de la fuentecilla
  también tienen su paso. La prueba comprueba que las fuentes están en la línea y que no hay nada sobre el camino.

## Hiedra sobre el camino, las terrazas y el agua (Luis, 17-11, con el parque perfilado en verde: «el camino empedrado
## tiene enredadera por encima y faltan dos fragmentos de enredadera abajo (donde hay dos bares con dos terrazas)»; y «Las
## fuentes funcionan? Creo que ya tenemos un sistema implementado para eso»)
- Un túnel de hiedra sobre el camino empedrado (`_walk_tunnel`), desde la placita de la fuentecilla hasta el semicírculo:
  columnas a 2,4 m a cada lado, vigas por encima y una por el centro.
- Detrás de la pérgola de la calle del recinto, a cada lado de la placita de la fuentecilla, un bloque de hiedra de cuatro
  filas (`_ivy_block`, columnas `BLOCK_W` y `BLOCK_E`), enlosado, con la terraza de un bar debajo (`world.extra_terrazas`:
  mesas, sombrillas y gente, de props.gd). La pérgola de delante va ahora de esquina a esquina, abierta solo en el camino.
- El agua de las tres fuentes es la de la fuente del jardín de la plaza (`plaza.gd`: WATER_SHADER, en movimiento, con ondas
  que salen del surtidor) y sus surtidores, JET_SHADER: uno en la rotonda, uno en la fuentecilla y tres bajos en la ovalada.

## El Auditorio y los aseos públicos (Luis, 17-11, con su captura en verde y rojo: «Crees que podrías añadir el auditorio
## (en verde) y los baños públicos (en rojo)? ... para el auditorio solo un hueco en el muro por donde pasar y para los
## baños una entrada con flecha a otra ubicación»)
`_auditorio()` y `_aseos()` en `ferial.gd`, sin rehorneado (el mapa no tiene nada allí). Fuentes: la ortofoto (las filas
de bancos calcadas sobre ella), Street View 2013 desde la carretera, la rotonda y el final de la calle (por encima del
muro se ve el interior), y 2024 desde el aparcamiento de poniente y desde el final de la calle.
- **El muro**: crema, de 2 m, desde la esquina de los aseos por el norte, el este, la curva y el sur; el de poniente, el
  del aparcamiento, blanco y de 2,4 m, con los dos carteles azules de las plazas de minusválidos. Al pie del muro crema,
  por fuera, un poyo corrido de 0,45 m de alto y 0,4 de fondo para sentarse (Luis, 17-11, de la línea que había dejado:
  «en realidad está salida hacia fuera, así la gente se puede sentar ahí»); el blanco no lo tiene (fotos de 2024).
  Esquinas a inglete. Fuera, por el este, la curva y el sur, la acera de baldosa roja y blanca hasta
  el bordillo de la carretera. Pintadas de peñas por fuera (`world.hand_tags`, estrechas porque el muro es bajo).
- **La entrada**: un hueco de 2,5 m en el muro norte pegado a la esquina de los aseos (`AUD_GAP`), con la puerta verde
  abierta y plegada contra el muro por dentro (es la de la foto). Nada más: se entra andando.
- **Dentro**: suelo de hormigón; junto al muro de poniente, el escenario de piedra (Luis, 17-11: «la zona que has hecho
  de tierra y plana, en realidad de piedra también»; Street View 2013 lo ve por encima del muro): una plataforma de un
  metro con la forma de la mancha parda de la ortofoto, su frente curvo de bloques de piedra gris con albardilla de
  granito y su suelo de losas de piedra (`_stage()`); se puede andar por encima (`MapData.decks`) y se sube por una
  escalerita de tres peldaños en su extremo norte, junto a la entrada (la escalera la he puesto yo: no se ve en las
  fotos). Nueve filas de bancos bajos de hormigón blanco en cuatro bloques con pasillos, en cuartos de elipse alrededor
  del escenario (centro (132, 541), semiejes 15,5 y 21 m: así encajan con las rayas blancas de la ortofoto); se cortan a
  1,1 m del muro. Tres postes de madera con dos focos cada uno donde los ve Street View 2013 por
  encima del muro (esquina noreste, junto al muro este, uno entre dos filas de bancos); dan luz de noche.
- **Los aseos**: casita de 7,5 x 10 m con tejado a cuatro aguas y dos chimeneas, de enlucido crema (como en las fotos de
  la calle; desde el aparcamiento en 2024 se ve blanca). Hacia la calle: una puerta, tres ventanas altas con reja y la
  puerta doble de madera con su reja encima y su farolillo; hacia el aparcamiento, cuatro ventanas con la persiana
  marrón bajada. Su pared sur cierra el Auditorio por ahí.
- **Su interior** (`aseos_dentro.gd`, un decorado aparte en (-1280, -1870), como el de Correa): se entra por la flecha
  verde de la puerta doble (una línea en `entradas.gd`, con OK de Sistemas). Azulejo blanco con franja azul, suelo gris,
  tres cabinas (la última ancha, con la silla en la puerta y su barra), dos urinarios con mamparas, dos lavabos bajo el
  espejo, secamanos, papelera, luces de techo. Sin nadie. Abiertos siempre.

## Lo que no he cambiado
- Los cables de la luz y la caseta naranja junto al camino de poniente.
- El aparcamiento de poniente (en las fotos de 2024 es de hormigón con plazas pintadas; en el juego es la tierra del mapa).
- Los eventos («donde se montan ciertos eventos del pueblo»): por ahora solo el recinto, vacío.

## Pruebas
`python tools/run_tests.py ferial`: fotos de la fuente, la pérgola, la explanada y los caminos, de día y de noche, y
desde el aire. Comprueba que la fuente está en la isla, fuera del asfalto, y es sólida; que nada invade la calzada; y
que las farolas son del pueblo. Del Auditorio: que el muro te para y el hueco te deja pasar, los bancos y los postes;
de los aseos: que te paran, que el mapa los conoce y que se entra y se sale por la flecha verde. Hojas para Luis:
`python tools/ferial/hojas.py CARPETA_SV`, en `guion/fotos/ferial/` (la 04 y la 05 son del Auditorio y los aseos).
