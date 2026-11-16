# Referencia: la tienda de la punta entre San José y Santo Domingo («los chinos del Arroyuelo»)

Pedido por Luis el 15-11-2026: «El siguiente será los chinos del arroyuelo. Texturas ha hecho una buena base pero tú
vas más al detalle» (con una captura de Google Maps). Primera versión enseñada el mismo día (hojas en
`guion/fotos/chinos_arroyuelo/`).

Su veredicto, el mismo día: «Sin figuras en la azotea. Estoy sin palabras, impresionante. Solo queda su horario
comercial de 7:00-21:00 entre semana y de 6:00-2:00 fines de semana». Y, preguntado por cómo cierra: «Puertas
abiertas y cerradas, luces encendidas y apagadas». El horario está hecho así y enseñado (hoja `04_horario.jpg`).

Su veredicto sobre el horario: «Impecable. Solo un pequeño detalle. En la puerta suele tener posters de bebidas
energéticas. He hecho este por si lo podemos poner en pequeño torcido en la puerta. Cámbialo un poco para que pegue
con la estética del juego» (con su cartel de «Roster Energy»). Hecho y enseñado (hoja `05_cartel.jpg`).

Y para cerrar (16-11-2026): «Me encanta así. Deja otro par pegados torcidos en la verja metálica de cuando cierran y
damos esta parte por finalizada». Hecho (hoja `04_horario.jpg`, rehecha). Y sobre el toldo, que yo había dejado
siempre extendido: «No, lo del toldo está bien. Extendido al abrir y recogido al cerrar. Con esto cerramos ya el
chino». Hecho. **Finalizado por su palabra el 16-11-2026.**

El modelo es `godot/scripts/chinos.gd` (sobre `obra.gd`). Herramientas: `tools/chinos/`.

## Dónde
La cuña entre la calle de San José (al norte) y la de Santo Domingo (al sur), con la punta al este, donde las dos se
juntan camino del Arroyuelo. Catastro `3992606VJ5639S` («CL SAN JOSE 1», 1980: vivienda arriba, comercio abajo). En el
juego es la casa `sanjose_1` del mapa. Hasta ahora la describía una línea de `casas_calles.gd` (de Texturas: ladrillo
rojo, un ultramarinos en la punta, ventanas con reja en las dos plantas); ahora va marcada `["obra"]` y la dibuja
`chinos.gd` sobre la misma entrada de `MapData.houses`. Sin rehorneado.

## Marco
El de la casa en el mapa: origen en la esquina norte de la punta, `x` a lo largo de San José hacia el oeste, `z` sale
a San José. **Pero `y` = 0 es el forjado entre plantas** (el pie de la hilada a sardinel), que es lo único horizontal:
las dos calles bajan hacia la punta y cada puerta pisa su propio suelo. Tres paños, cada uno con su marco (`face`):
San José (0 en la punta), Santo Domingo (0 en la medianera del oeste) y la punta (0 en su esquina sur).

## Fuentes
- **Street View**, noviembre de 2024 (lo que manda), con octubre de 2019, marzo de 2013 y mayo de 2009 desde los mismos
  sitios: 35 vistas en `tools/chinos/capturas.py`, desde las diez cámaras de las dos calles y de delante de la punta.
  Todas las cámaras: `python tools/molino/panos.py cerca u-oBM2ipqzDkSoTgh0sUdw -290 9 48`. No hay fotos esféricas
  privadas dentro.
- **Catastro**: el contorno (`tools/casas/3992606VJ5639S/`). Acierta: la punta mide 3,3 m.
- La descripción de Texturas en `casas_calles.gd` (en el historial de git).

## Lo que hay
- **Ladrillo caravista rojo** en las tres fachadas; entre plantas, alrededor de todo, una hilada a sardinel de 24 cm.
  Arriba, un gran alero plano, blanco por debajo, con un borde de teja; azotea plana.
- **La punta**: machón de ladrillo a la izquierda y machón forrado de carteles a la derecha («ALIMENTACIÓN Y BEBIDAS DE
  RUMANÍA», «GOLOSINAS», «BOLLERÍA», «BEBIDAS», «RECARGA DE MÓVILES») sobre un pie de piedra; entre los dos, el
  escaparate de madera: una hoja acristalada con barrotes en aspa, la otra abierta, y una ventana llena de juguetes.
  Encima, el rótulo de madera tallada («ALIMENTACIÓN / PAN · BEBIDAS · FRUTOS SECOS») y el toldo blanco de brazos. Sobre
  la tienda, el balcón que vuela 75 cm: peto de ladrillo, barandilla de hierro, ventana de cuatro hojas bajo un toldo
  de rayas verdes. En la azotea, una jaula de barras de hierro. En la acera, las dos señales: dirección prohibida
  hacia Santo Domingo y paso limitado a 2,7 m hacia San José.
- **San José** (de la punta al oeste): tres ventanas con reja (la primera, con carteles), una rejilla de ventilación
  bajo un aparato de aire, la ventana alta en arco de la escalera, y al fondo dos verjas de tijera con un poste de
  piedra entre ellas. Arriba, cuatro ventanas en sus rejas de buche. Zócalo de piedra que crece según baja la calle.
- **Santo Domingo** (del oeste a la punta): una verja de tijera y una puerta de hierro entre postes de piedra; la
  puerta de la casa, de chapa repujada color bronce verdoso, con su marco claro y su buzón; dos ventanas en arco;
  tres con reja (una, con una sábana colgada por dentro, tal cual); y la de la tienda, con carteles, bajo el aparato
  de aire grande. Arriba, seis ventanas.
- **En la azotea**, la caseta con su chapa ondulada.

## En el juego
- El rótulo dice solo qué se vende, como el real. Los carteles son nuestros (sin marcas). No se muestra el número.
- **Las dos figurillas blancas** que hay en la azotea real, sobre los postes de la jaula, **no están**: Luis dijo
  «Sin figuras en la azotea».
- No se entra. Por la puerta abierta se ven estanterías con género. Sin personajes.
- Prueba: `python tools/run_tests.py chinos` (25 fotos y 5 comprobaciones); además `casas solo=sanjose_` por las
  vecinas.

## El cartel de la puerta
- **«Roster Energy»** es una bebida que no existe: el cartel lo hizo Luis (`roster_energy_original.png`, en esta
  carpeta: una lata negra y verde lima, «CARGA TU DÍA»).
- `tools/chinos/poster.py` lo pasa al estilo del juego: seis colores planos (negro, dos grises, blanco roto, lima y
  verde oscuro), sin grano, gotas ni fotografía, y con un borde de papel. Sale `godot/assets/chinos/poster_roster.png`
  (314 × 414); tras regenerarlo, `Godot --headless --path godot --import`.
- En el juego: 27 × 36 cm, pegado con dos trozos de cinta en la hoja fija de la puerta, a media altura y girado
  unos 7°. Material `"cartel"`, función `_poster(at, giro, ancho)`.
- **Otros dos en la persiana**, de 36 y 31 cm de ancho, torcidos a un lado y a otro: se ven con la tienda cerrada.

## El horario
De lunes a viernes, de 7:00 a 21:00; sábados y domingos, de 6:00 a 2:00 de la madrugada siguiente (`WEEK`, `WEEKEND`,
`open_at(dia, hora)`, con 0 = lunes; las horas de 0:00 a 2:00 son de la apertura del día anterior: la madrugada del
sábado está cerrada, la del domingo y la del lunes abiertas). `_process` lee `game.weekday` y `game.clock`.
- **Abierta**: la segunda hoja de la puerta abierta hacia dentro, el toldo blanco extendido, las dos lámparas de
  debajo del balcón y la de dentro encendidas (nodo `_open` y dos luces); lo de dentro se ve iluminado.
- **Cerrada**: las dos hojas cerradas, todas las luces apagadas y la **persiana metálica** gris bajada sobre todo el
  escaparate, con dos carteles pegados, y el toldo recogido bajo su cajón con los brazos plegados (nodo `_shut`; el
  interior deja de dar luz).
- La persiana tuvo ida y vuelta: la primera versión del horario la tenía; a la pregunta de si valía así, Luis
  contestó «Puertas abiertas y cerradas, luces encendidas y apagadas» y la quité; luego pidió carteles «en la verja
  metálica de cuando cierran», así que la quería; y lo mismo el toldo recogido. La versión final es la primera que
  vio, más los carteles. Cómo cierra la tienda real no se ve en Street View.
- La comprobación no mueve ni la hora ni el día del juego (regla de Sistemas): prueba `open_at` como función pura y
  pone cada estado a mano. Solo las fotos del modo `--chinos`, que va solo, cambian `g.weekday` y la hora.

## Lo que es aproximado
- **Las posiciones de puertas y ventanas**: ±0,3 m (ver `tools/chinos/LEEME.md`, cómo se midieron).
- **El desnivel**: en la realidad las dos calles bajan medio metro de la medianera a la punta; en el juego bajan un
  metro, y Santo Domingo va medio metro más baja que San José. El forjado se ha puesto a 2,97 m sobre la media de las
  dos calles en el extremo oeste; así, la planta baja de la punta sale de unos 4 m (3,5 a 3,8 en la realidad) y las
  puertas de Santo Domingo tienen más ladrillo encima que las reales.
- **La calle delante de la punta** sube hacia el este en el juego (en la realidad sigue bajando): desde ahí la tienda
  se ve algo más desde arriba que en Street View.
- **El alero**: 60 cm de vuelo. **La jaula y la caseta de la azotea**: a ojo. **El interior**: inventado.
- La barandilla de la acera junto a la señal de 2,7 m no se ha puesto (la acera del juego ahí es estrecha).
