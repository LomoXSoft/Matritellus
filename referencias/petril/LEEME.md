# Referencia: el Pretil (iglesia y convento de San Francisco) — en el juego, «Iglesia del Petril»

Material enviado por Luis (14-11-2026) para modelar a mano la zona del Pretil: la plazuela elevada, la iglesia y el
convento de San Francisco, todo junto. Oficialmente C. Cruces 9, pero ocupa más de una parcela. En el juego se llama
**Iglesia del Petril** (nombre del usuario).

Construido en `godot/scripts/petril.gd` (ver su cabecera). Fotos de comprobación: `godot/shots/petril_*.png`
(`--selftest --petril`) y hojas comparativas en `guion/fotos/petril/`. Las herramientas con que se midió, y cómo
usarlas para el próximo edificio, están en `tools/petril/` (LEEME.md).

## Archivos de esta carpeta
- `usuario_01_mapa.jpg`, `usuario_02_satelite.jpg` — capturas de Google Maps.
- `usuario_03` … `usuario_08` — Street View desde la calle Cruces (nov. 2024 y oct. 2019).
- `usuario_09` … `usuario_13` — Street View desde la calle San Francisco (oct. 2019): conjunto, escalera, pórtico, fachada.
- `usuario_14` … `usuario_16` — costado de la iglesia a San Francisco y la cabecera (torre del crucero).

## Qué es cada cosa
- **Plazuela**: suelo elevado sobre las dos calles, sujeto por un muro de mampostería ocre con albardilla de granito
  (el «pretil»). Escalera de granito de cinco peldaños en San Francisco, entre dos pilares con bola; rampa desde Cruces
  pegada al convento, con un triángulo empedrado al lado. Bancos de piedra, cipreses, un árbol, una columna con una
  imagen junto a la esquina de la iglesia.
- **Iglesia** (pies al sur, cabecera al norte): fachada estrecha y alta de aparejo toledano (ladrillo en esquinas e
  hiladas, cajones de mampostería), ventana sobre la puerta, hornacina de piedra, pórtico de teja sobre dos columnas
  de granito con techo pintado, puerta de cuarterones con clavos. Espadaña de ladrillo sobre el muro oeste, cerca de
  la fachada. Torre del crucero más alta, con tejado a cuatro aguas y veleta. Al norte, el presbiterio (más bajo) y
  un cuerpo bajo con tejadillo a la calle.
- **Convento**: crujía sur (mampostería, puerta con dintel de madera y lápida: hoy museo) y ala este larga que cierra
  la plazuela (ladrillo con cajones de mampostería, portada de ladrillo con frontón partido y escudo). En la esquina
  interior, el torreón-solana: pilares de ladrillo, entramado de madera con paños blancos y cuatro ventanas, alero
  con canecillos. Claustro central, hoy cubierto con un lucernario.

## De dónde salen las medidas
- **Planta**: Catastro (INSPIRE), parcelas `4289026VJ5648N` (iglesia) y `4289023VJ5648N` (convento), y la ortofoto
  PNOA del IGN (CC BY 4.0). Marco propio: origen en la esquina suroeste de la iglesia, +x al este por su fachada,
  +z al sur hacia la plazuela (mapa: origen (-108.9, 261.7), u = (0.9784, 0.2066)).
- **Alturas**: dos panorámicas de Street View a 22 m (misma medida desde las dos esquinas de la fachada) y la foto
  frontal del Ayuntamiento → cornisa de la nave a 13,0 m sobre la plazuela; alero del convento a 7,5 m por puertas
  y ventanas; torreón a 10,5 m al alero (foto frontal del ala, con la cámara ajustada: está 1,8 m retranqueado).
  Torre del crucero (17,7 m al alero) por proporción con los alzados del estudio de
  F. M. Garoz-Esteban, «Convento de San Francisco», *Cuadernos de Historia y Cultura Popular de Madridejos* 3
  (2017), que además da la descripción de cada parte. Ojo: esos alzados, leídos a la escala de la planta, dan
  alturas un 20 % mayores que las medidas en foto; mandan las fotos.
- **Desnivel**: la plazuela queda 0,82 m sobre San Francisco en la escalera (cinco contrahuellas) y 1,33 m sobre
  Cruces al pie de la rampa, con el relieve del juego (el real ×2,5).

## Segunda pasada (14-11-2026): cámaras ajustadas a las fotos
A tres fotos de terceros (frente del ala este, fachada de la iglesia, conjunto desde la esquina suroeste) se les
ajustó la cámara con puntos del modelo (`tools/petril/encaja.py`); el juego se fotografió desde el mismo sitio y se
comparó parche a parche. De ahí salieron:
- **Colores**: el ladrillo es más pálido y amarillo en esas fotos (tarde de verano) que en Street View de 2019
  (anaranjado); se dejó entre los dos. Los cajones del ala son casi del color del ladrillo, con la piedra apenas
  asomando; el zócalo es gris claro; la teja, gris parda (teja vieja), no naranja.
- **Ala este**: sus cajones copiados uno a uno de la foto frontal (tres hiladas en planta baja, una banda bajo las
  ventanas altas, columnas entre ellas hasta la cornisa); marcos de ventana finos y grises; portada rehecha
  (pedestales de piedra con tambor y dado, medias columnas de ladrillo, entablamento, frontón que se rompe en un
  arco sobre el escudo oval, puerta de cuarterones); puerta baja de la rampa hasta 2,0 m; zócalo de 0,95 m.
- **Crujía sur** (junto a la iglesia): ventanas altas 0,55 m más arriba, la enrejada pegada a la esquina, puerta del
  museo 0,56 m más a la derecha, ventana verde y tablón donde están; bajante junto a la iglesia.
- **Iglesia**: puerta de 2,2 m de luz con arco a 2,7 m dentro de un marco cuadrado de granito claro; ventana alta
  de 0,96 × 1,7 m; cornisa el doble de grande; pedestales del pórtico de 0,95 m; esquinas de ladrillo más anchas.
- **Plazuela**: murete entre la plazuela y la rampa (0,62 m en la cabeza de la rampa, la altura del pretil donde
  lo encuentra), que la foto frontal del ala enseña con su poste; escalera donde la pone tu vista de 2019 desde la
  esquina (pilares a 7,7 y 10,0 m de la iglesia).
- **Árboles**: como en Street View de noviembre de 2024 — los dos cipreses del lado de Cruces, altos y anchos; el
  de la esquina interior, fino; el árbol joven cerca de la esquina suroeste. (Las fotos del Ayuntamiento son más
  antiguas: allí esos cipreses eran plantones.)

- **Lo que tapa** (occlusion culling): el juego saca los oclusores de los muros genéricos del mapa y el Petril no
  tiene ninguno allí, así que trae los suyos (`_occluders()`: sus muros grandes, 0,2 m hacia dentro).

Hojas: `guion/fotos/petril/01_…` y `02_…` (tus capturas de Street View frente al juego desde el mismo sitio),
`03_…` y `04_…` (el juego desde la plazuela, las dos calles y el aire), `00_antes.jpg` (cómo estaba).

Al comparar salió que **el sol del juego iba al revés** (salía por el oeste): las hojas de este trabajo se hicieron
así, imitando una foto real de las 16:00 con `--hora=11.6`. Quedó corregido en `game.gd` para la 0.0.5; desde
entonces se pide la misma hora que la de la foto.

## Fotos de terceros usadas solo como referencia (no están en el repositorio)
- Ayuntamiento de Madridejos, ficha «Iglesia y Convento de San Francisco» (fotos de 2019 de la fachada de la
  iglesia, del ala este de frente y del conjunto desde Cruces): madridejos.es/monumentos-y-museos/.
- Portal de cultura de Castilla-La Mancha (vista de la plazuela desde su esquina suroeste).
- El estudio citado arriba (planta, secciones y alzados), publicado por el Ayuntamiento en Calaméo.

## Texturas (todas CC0, Poly Haven; créditos en `godot/assets/texturas/CREDITOS.txt`)
`medieval_red_brick` (ladrillo de tejar, recoloreado al tono real), `plaster_stone_wall_02` (cajones),
`rock_wall` (pretil), `rock_wall_15` (zócalo oscuro), `granular_concrete` (granito abujardado y suelo),
`square_cobblestone` (empedrado). Las del resto del pueblo no se han tocado.

## Lo que no está hecho o es aproximado
- No hay interiores (ni iglesia ni claustro ni museo).
- Los lados norte y este no se ven desde ninguna calle: son muros lisos de ladrillo.
- Los cajones del ala este están copiados de la foto hasta donde llega (20 de sus 21,9 m); los del resto de muros
  (iglesia, torre, extremo a Cruces) siguen un patrón regular.
- La anchura de la rampa (1,8 m) sale de la ortofoto; la foto frontal del ala sugiere que puede ser algo mayor.
- Alturas del convento con un margen de ±0,3 m (las dos fotos frontales no coinciden del todo entre sí).
- El panel de azulejos de la Virgen (muro de la torre a San Francisco) es una figura esquemática.
- La acera de San Francisco junto a la iglesia y el pretil es más estrecha que la real (la calle del juego llega
  casi al muro).
