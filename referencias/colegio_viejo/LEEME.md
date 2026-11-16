# Referencia: el viejo colegio de la avenida de Juan Carlos I (el Instituto Garcilaso de la Vega)

Pedido por Luis el 16-11-2026: «Pasamos al siguiente edificio: el viejo colegio. Ocupa toda la manzana (en rojo)» (una
captura de Google Maps con la manzana sombreada y dos de Street View de marzo de 2013). Y enseguida, con la captura
garabateada: «No ocupa todo lo rojo. Está zona más o menos»: el extremo sur de la manzana, lo que da a la avenida.
Primera versión enseñada el mismo día (hojas en `guion/fotos/colegio_viejo/`).

Su veredicto: «Increíble. Solo dos notas: 1. Los focos están apoyados en las vallas, no en mitad de la pista (creo
que lo hiciste bien en una de tus primeras iteraciones). 2. Estaría bien añadir la parada de autobús que hay en la
acera también, la blanca y azul». Hechas las dos y enseñadas (hoja `04_parada_y_focos.jpg`).

Y sobre la parada: «Quita el "Castilla", deja solo "La Mancha" y céntrala. Pega dentro un cartel de Roster
torcido». Hecho y enseñado (la misma hoja, rehecha); pendiente de su palabra.

De paso, a la pregunta de si quitaba «Castilla» también en el centro de salud: «Sí, quítalo también». Los dos
rótulos de `godot/scripts/salud.gd` (el cartel de la calle de Argentina y la caja de urgencias) dicen ahora
«La Mancha» (hoja `05_centro_de_salud_la_mancha.jpg`). En los rótulos del juego la región es «La Mancha».

Y para cerrar, con una foto de la placa de azulejo real de la puerta: «El último retoque y cerramos. Tenía un cartel
con su nombre muy bonito en azulejo (adjunta). Creo que podríamos dejarla y usar su nombre, total, lleva años
cerrado». Hecho (hoja `06_placa.jpg`). **Cerrado por su palabra el 16-11-2026.**

El modelo es `godot/scripts/colegio.gd` (sobre `obra.gd`). Herramientas: `tools/colegio/`.

## Dónde
La parcela del Catastro `3891715VJ5639S` («AV JUAN CARLOS I 46(D)», uso cultural/enseñanza, tres partes), entre la
calle del Peso (oeste), la de Santa Clara (este) y la avenida de Juan Carlos I (sur), junto a la ermita de la Caridad.
El resto de la manzana son casas corrientes y sigue como estaba.

## Marco
Origen en la esquina suroeste de la torre oeste, mapa (-427.35, 121.61); `x` a lo largo de la fachada hacia Santa
Clara, u = (0.9706, -0.2407); `z` sale hacia la pista y la avenida; `y` = 0 la pista delante de la puerta.
La planta (Catastro, que aquí es ortogonal en ese marco): torre oeste x 0–7,5; cuerpo 7,5–32,64 retranqueado 1,88 m;
torre este hasta 40,35; el bloque oeste llega a z -13,3 y el ala este a -21,7.

## Fuentes
- **Street View**: 64 vistas en `tools/colegio/capturas.py`, desde las tres calles; noviembre de 2024 (lo que manda),
  octubre de 2019, **marzo de 2013 (los árboles sin hojas: la única fecha en que se ve la fachada entera)**, octubre de
  2012 y mayo de 2009. Todas las cámaras: `python tools/molino/panos.py cerca nqFJDD-6qHoodVtdivBnnA -408 122 52`.
  No hay fotos esféricas privadas dentro.
- **Catastro**: contorno y partes (`tools/casas/3891715VJ5639S/`).
- **Foto aérea del IGN** (PNOA): `tools/ign/colegio_viejo.jpg`; con ella se trazó la pista, la verja y los árboles
  (`python tools/colegio/planta.py`).

## Lo que hay
- **El edificio**: escuela neomudéjar de los años veinte, de ladrillo claro con cajones de mampostería entre hiladas
  y machones de ladrillo. Zócalo de mampostería oscura bajo una banda de piedra; friso de ladrillo en esquinilla entre
  plantas; cornisa y aleros anchos sobre canecillos; teja vieja.
- **Fachada a la pista**: dos torres cuadradas en las esquinas (ventana con reja, ventana encima, tres arquillos bajo
  el alero, pararrayos) y entre ellas el cuerpo de dos plantas: tres ventanas a cada lado de la puerta en cada planta,
  la puerta en arco de piedra dentro de un paño de celosía de ladrillo con dos escudos y la placa, y encima el balcón
  de piedra con barandilla y tres mástiles. Carpinterías granates de cuarterones.
- **Calle de Santa Clara**: el ala este, con dos ventanas con reja, el portón de piedra en su paño ancho de celosía
  (pisa el suelo de la calle) y tres ventanas arriba.
- **Calle del Peso**: el bloque oeste, con dos ventanas viejas de madera oscura.
- **La pista**: suelo rojo, una cancha de baloncesto pintada con sus dos canastas y otra canasta suelta, ocho
  árboles, dos mallas altas junto a las calles laterales; cerrada por una verja de barrotes sobre murete de ladrillo
  con una puerta de pilares a cada calle lateral. **Cuatro focos** en sus postes altos, **pegados a la verja de la
  avenida**, entre los árboles, mirando a la pista (primero los puse en fila por mitad de la pista; Luis lo corrigió).
- **Delante, en la avenida**: la acera de baldosa en damero rojo y crema y **la marquesina del autobús**, blanca y
  azul, frente a la puerta y de espaldas al colegio: techo blanco con su frontal y el rótulo **«La Mancha»** en
  azul, centrado (la real dice «Castilla-La Mancha»; Luis pidió quitar «Castilla»), cuatro postes azules, trasera
  blanca con dos avisos, **el cartel de Roster Energy pegado torcido** (el de Luis, el mismo de la puerta de los
  chinos: `godot/assets/chinos/poster_roster.png`) y lo que le han garabateado, una pantalla blanca en cada
  extremo y el banco azul. `_shelter()`.

## En el juego
- **La placa lleva su nombre real, «INSTITUTO GARCILASO DE LA VEGA»**: es una excepción expresa de Luis a la regla
  de no usar nombres reales (el centro lleva años cerrado). Solo en esa placa. Sin número.
- No se entra y las puertas de la verja están cerradas: el patio no se pisa. Sin personajes (los niños, como en el
  Calasanz, cuando Luis pula los personajes y lo pida).
- La marquesina es la de las fotos de 2013 (las de Luis); en 2024 ya no está, pero él la quiere.
- La papelera verde que queda delante de la marquesina es del mapa (ya estaba ahí), no de este modelo.
- Pruebas: `python tools/run_tests.py colegio` (18 fotos y 3 comprobaciones); además `relief` y `caridad`.

## La placa y el paño de la puerta
- La foto de Luis está en esta carpeta (`placa_original.webp`). De ella salen las medidas, tomando como regla los
  4,84 m del paño: la placa mide 2,07 × 0,49 m; el paño de celosía tiene un marco moldurado de piedra que sube un
  escalón en el centro (4,89 m a los lados, 5,33 m en medio); los dos escudos lisos miden 0,50 × 0,88 m; el arco es
  de dos roscas de sillares.
- `tools/colegio/placa.py` pinta la placa (`godot/assets/colegio/placa_instituto.png`, 1242 × 294): azulejo
  blanco con sus juntas, doble filete azul, una voluta azul en cada esquina y el nombre en capitales azules con las
  iniciales grandes en dorado. Tras regenerarla, `Godot --headless --path godot --import`. Material `"placa"`.
- La celosía real es de piezas de barro con calados de cuatro lóbulos; en el juego es un enrejado de barras en
  diagonal sobre fondo oscuro (`_lattice`), con un solo dibujo para toda la pared.

## El rehorneado
A diferencia de las tres últimas casas, este sitio necesita el mapa rehorneado: `tools/bake_godot.py` lleva un bloque
`COLEGIO` (la parcela no se levanta, no hay árboles del mapa en ella ni en la pista, y `colegio_built` cuenta para el
ancho de las calles). Horneado el 16-11-2026 detrás del de los sentidos únicos de Sistemas. Diferencias: desaparece el
bloque genérico (18 muros, 3 tejados; aparecen 2 medianeras de las vecinas), `clr` cambia 0,1 m en dos nudos; relieve,
nudos, calles, árboles y casas, iguales.

## Lo que es aproximado
- **Las medidas de la fachada**: sacadas de UNA foto (marzo de 2013) con la cámara ajustada a las esquinas de las
  torres; ±0,3 m. Las alturas, ±0,3 m.
- **El desnivel**: el relieve del juego es 2,5 veces el real. La pista es un plano ajustado al terreno y levantado
  hasta librarlo; el murete de la verja se lleva la diferencia y sale más alto que el real (1,3 m en la avenida, por
  0,7), y el zócalo de la calle del Peso también.
- **Los laterales**: las ventanas de Peso y de Santa Clara, colocadas a ojo sobre las fotos (no ajustadas).
- **La trasera** (lo que no da a ninguna calle): el contorno del Catastro, liso.
- **La calle de Santa Clara** del juego es más ancha que la real: la verja queda a medio metro de la calzada, y la
  acera en damero se corta antes de la esquina.
- **Los árboles**: ocho, más pequeños que los reales para que se vea la fachada.

## La tapia de la calle Santa Clara (16-11-2026)
Luis la echó en falta (a través de Texturas): el tramo de unos 8 m entre el ala del colegio y la casa de al lado (la
última de la acera par). Hecha en `colegio.gd` (`_tapia`) por la foto del Catastro de esa casa
(`tools/casas/3891714VJ5639S/fachada.jpg`): tapia de ladrillo de 1,5 m con su albardilla, reja de forja encima hasta
2,45 m (una fila de roleos abajo, anillos y barrotes con lanzas arriba), una puerta oscura junto al machón de ladrillo
de la esquina de la casa. Detrás, el patio. El asfalto del juego llega hasta la esquina de esa casa, así que la
comprobación de calzada solo mira el extremo del colegio. Hoja: `guion/fotos/colegio_viejo/07_tapia_santa_clara.jpg`.
Su veredicto: «Ambos visto bueno» (16/11).
