# Referencia: la Universidad Popular («Universidad Comunal») y la papelería de al lado («Papelería Rocas»)

Pedido por Luis el 16-11-2026: «Otro trabajo: La Universidad Popular (que llamaremos Universidad Comunal) y la Papelería
Arcos (Que llamaremos Papelería Flechas). Son dos edificios que están pegados, así mejor hacerlos juntos. Son calle
Arcos 10 y 12 respectivamente» (con una captura panorámica de Google). Primera versión enseñada el mismo día (hojas en
`guion/fotos/universidad_comunal/`).

Al verla, el mismo día: «Cambiale el nombre a Papelería Rocas y ponle este horario comercial: [lunes a viernes 10-14 y
17:30-21; sábado 10-14; domingo cerrado]. Además necesitamos que parezca que se puede pasar, ahora mismo hay una pared
que bloquea y no da esa impresión». Hecho y enseñado (hoja `03_papeleria_rocas.jpg`). Su veredicto, de todo (fachadas, papelería e interior): «Visto bueno a todo. Pensaba que ya lo había dado» (16/11).

El modelo es `godot/scripts/comunal.gd` (sobre `obra.gd`): los dos edificios en un solo guion. Herramientas: `tools/comunal/`.

## Dónde
Calle de los Arcos, lado oeste. En el juego son tres casas del mapa, que `casas_calles.gd` marca ahora `["obra"]`:
- `arcos_10` (Catastro `4390016VJ5649S`, 1965, enseñanza, una planta): la Universidad.
- `arcos_10t` (sin Catastro): la tapia de su jardín.
- `arcos_12` (Catastro `4390015VJ5649S`): la papelería —un frente de 3,07 m en la calle de los Arcos— y, en la misma
  parcela, el bloque de tres plantas de la calle Cervantes, detrás.
Las describía Texturas (en el historial de git); sirvieron de base. Sin rehorneado.

## Marco
El de `arcos_10`: origen en el extremo sur de la fachada de la Universidad, mapa (105.22, 144.69); `x` a lo largo de la
fachada hacia el norte; `z` sale hacia la calle (este); `y` = 0 la acera delante del porche. La tapia está a 3,5 m de
la fachada en el extremo sur y a 4,4 m en el norte (`_zw`). La calle baja hacia el sur: la tapia sigue al terreno y la
papelería se apoya en su propio suelo.

## Fuentes
- **Street View**, noviembre de 2024 (y 2019, 2013, 2009 de los mismos sitios): 35 vistas en `tools/comunal/capturas.py`,
  desde la calle de los Arcos, el callejón Pando (2019) y la calle Cervantes (2019). Todas las cámaras:
  `python tools/molino/panos.py cerca wAvXPKVYISE48bviztDmuQ 113 135 45`.
- **Una foto esférica privada** tomada en la calle, delante de la verja (su dirección está en `capturas.py`, `SPHERE`).
- **Catastro**: `tools/casas/4390016VJ5649S/` y `tools/casas/4390015VJ5649S/`.

## Lo que hay
- **La Universidad**: una planta alta de ladrillo bajo teja vieja, con cornisa de esquinilla y chimenea. Cinco ventanas
  blancas altas a cada lado de la puerta (la última del norte, tras su contraventana de madera y su reja), la placa de
  azulejo de las antiguas escuelas sobre una de ellas, dos apliques redondos. Detrás, su ala y sus tapias.
- **El porche**, en la línea de la calle: dos pilares de ladrillo, sus vigas, el rótulo blanco con letras rojas y su
  emblema (un aro), dos focos, y su tejadillo de teja a tres aguas que entra en el tejado de la casa. Debajo, la
  verja de hierro de dos hojas, cerrada.
- **La tapia**: mampostería dorada con albardilla de ladrillo y el seto de hiedra encima; machones de ladrillo en los
  extremos y la caja de contadores junto al del sur.
- **En la acera**: el tablón de anuncios sobre sus dos postes rojos, junto al porche; y delante del seto la señal de
  sentido obligatorio con su espejo.
- **La papelería**: tres metros de fachada blanca. Abajo, el arco de medio punto con la malla metálica y el
  escaparate detrás; una banda de ladrillo; arriba, el balcón con sus macetas ante la puerta de madera, el alero
  sobre canecillos de madera, el rótulo verde colgado en bandera, un aplique. En su costado norte, sobre el jardín, la
  banda de ladrillo que sigue la pendiente del tejado.
- **Por detrás, en la calle Cervantes**: el bloque de tres plantas de ladrillo visto sin terminar —zócalo enfoscado
  con un portón de chapa verde y un hueco de puerta, y los huecos de las ventanas vacíos—. Sucio se queda sucio.

## En el juego
- **Nombres**: «UNIVERSIDAD COMUNAL» y «Rocas / LIBRERÍA PAPELERÍA / PRENSA» (primero fue «Flechas»), los dos de Luis.
  El emblema del rótulo de la Universidad es nuestro.
- **La placa de las escuelas** dice solo «ESCUELAS NACIONALES»: la real sigue con el nombre de una persona, y lo he
  dejado fuera (regla de no usar nombres reales). Luis decide si lo quiere, como hizo con el instituto.
- **La papelería sigue su horario** (`open_at(day, hour)`, `set_open(on)`): lunes a viernes de 10:00 a 14:00 y de 17:30
  a 21:00; sábados de 10:00 a 14:00; domingos cerrada. Cerrada, la malla bajada, como en las fotos, y a oscuras.
  Abierta, sin malla: el arco es un hueco y detrás está la tienda entera (6 m de fondo: suelo desde la acera, estantes
  en las dos paredes, mostrador y estantes al fondo, un expositor de postales, tres tubos de luz y un felpudo).
- **Se entra por una flecha, a un espacio aparte** (Luis, 16-11-2026: «En las tiendas como esta o la de VIP que sean
  pequeñas deberíamos poner un arrow marker [...] low-poly animado [...] y pasar sobre él te mandará a la tienda, que
  será un espacio aparte y ahí podremos trabajar sin límites de fachada o tamaño»; verde, «para que vaya a juego con
  la flecha de personaje»). La flecha y el paso son de Sistemas (`entradas.gd`). El frente sigue parando al jugador y
  la sala que se ve por el arco es decorado.
- **El interior** es `godot/scripts/rocas.gd` (`world.comunal.tienda`), un decorado lejos del pueblo, en (-1800, -1800),
  como el del V.I.P.: 7,6 × 12 m y 3,1 de alto. Lo primero que se ve al entrar es la tienda entera: las mesas
  empiezan a 1,5 m del sitio donde apareces (Sistemas avisó de que la primera tapaba la vista). Junto a la puerta, la prensa (revistas en su expositor, los periódicos
  del día en un banco) y las mochilas; a un lado, seis estanterías de libros; al otro, la papelería (archivadores,
  cuadernos, paquetes de folios, botes de bolígrafos, globos terráqueos); en medio, dos mesas de novedades y ofertas
  y el expositor de postales; al fondo, el mostrador verde con su trampilla, la caja, la pantalla, las baldas de
  folios y la fotocopiadora. Todo inventado. Muebles del Furniture Kit de Kenney (CC0): `godot/assets/rocas/`.
  Sin tendero (no se crean personajes): `keeper_spot` y `counter_front` dicen dónde irían. Hoja:
  `guion/fotos/universidad_comunal/04_papeleria_rocas_por_dentro.jpg`. Enseñado el 16-11; visto bueno el mismo día.
- La verja de la Universidad está cerrada. Sin personajes.
- Pruebas: `python tools/run_tests.py comunal` (28 fotos y 5 comprobaciones) y `casas solo=arcos_` por las vecinas.

## Lo que es aproximado
- **Porche, tablón y ventanas del norte**: medidos con las cámaras ajustadas a los extremos de la tapia y de la fachada
  (Google las ponía 2,2 m más al norte); ±0,4 m.
- **Las ventanas del sur y la puerta**: la hiedra y el porche las tapan. Están puestas en espejo de las del norte, con
  la puerta en el centro de la fachada (x 9,93); lo poco que se ve cuadra con eso.
- **La papelería**: su ancho es el del Catastro; alturas y huecos, por proporción sobre las fotos.
- **El tejado de la papelería y su costado**: no se entiende bien desde la calle; es una cubierta a dos aguas con la
  cumbrera cerca de la fachada.
- **El bloque de Cervantes**: sus huecos, a ojo sobre dos fotos de 2019.
- **El interior de la papelería**: inventado (estantes de género de colores, mostrador); desde la calle solo se ve el
  escaparate.
- La acera del juego es estrecha ahí: el tablón y la señal van pegados a la tapia.
