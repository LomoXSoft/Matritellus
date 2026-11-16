# Herramientas de la tienda de la punta entre San José y Santo Domingo («los chinos del Arroyuelo»)

Con esto se midió y se comprobó `godot/scripts/chinos.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo
aproximado: `referencias/chinos_arroyuelo/LEEME.md`.

## Qué hay
- `capturas.py CARPETA [nombre…]` — baja las 35 vistas de Street View (cada una: cámara, a qué punto del mapa mira,
  inclinación, campo). No se guardan en el repositorio.
- `rejilla.py FOTO x0 y0 x1 y1 SALIDA [zoom [paso]]` — un trozo de foto ampliado bajo una cuadrícula numerada en los
  píxeles de la foto: para leer dónde cae cada cosa.
- `medir.py CARPETA NOMBRE PARED px,py…` — metros a lo largo de la pared (n, s, p) y altura de un píxel, dada la cámara.
- `ajuste.py CARPETA n|s` — **lo importante**: ajusta a la vez dónde estuvo cada cámara y dónde está cada hueco, con
  todas las lecturas de varias fotos (`OBS`, dentro del archivo).
- `vistas.py CARPETA NOMBRE…` — el juego desde donde estuvo de verdad Street View (las cámaras ajustadas):
  `python tools/run_tests.py "$(python tools/chinos/vistas.py CARPETA e24 n24 s24 …)"`.
- `hojas.py [CARPETA]` — las hojas de `guion/fotos/chinos_arroyuelo/`.
- `poster.py [ORIGINAL] [SALIDA]` — el cartel de la puerta: redibuja el de Luis en colores planos.
- `enganche.py` — lo que añade a `casas_calles.gd`, `world.gd` y `selftest.gd`; ya aplicado.

## Lo que se aprendió aquí
1. **Google coloca cada cámara con uno o dos metros de error, y en una calle de seis metros eso lo descoloca todo.**
   La cámara de delante de la punta estaba a 10 m, no a los 12,8 que dice; las de los lados, entre 2,1 y 3,8 m de la
   pared (Google daba 3,4 a 3,8 a todas). Ajustar la cámara solo con los dos extremos de la pared no vale: el extremo
   lejano se ve rasante y un píxel son metros.
2. **Hace falta una regla, y la da el ladrillo.** La hilada a sardinel entre plantas mide lo que un ladrillo de largo,
   24 cm, esté donde esté: leída en cada foto dice a qué distancia estaba la cámara. Con eso, los dos extremos de la
   pared (Catastro) y que una misma ventana vista desde dos cámaras está en un solo sitio, `ajuste.py` resuelve todo
   junto. Se comprobó con la altura de planta (2,6 a 2,8 m) y con el ancho de la punta (3,3 m: Catastro acierta).
   Cuidado al contar ladrillos «a ojo» en una foto reducida: se confunden dos hiladas con una.
3. **En un edificio en cuesta, lo horizontal es el forjado.** Las ventanas se miden desde la hilada a sardinel; las
   puertas, desde su suelo. El zócalo absorbe la diferencia.
4. **Antes de construir, fotografiar el juego desde los sitios de Street View** enseña el terreno que hay (aquí, que
   la punta está en una hondonada del relieve del juego).
5. `"sardinel"`: el mismo ladrillo con las UV giradas (metros, primero hacia arriba), para hiladas de pie.

## Pruebas
`python tools/run_tests.py chinos`: 25 fotos (`godot/shots/chinos_*.png`; doce son del horario: lunes a las 6:40 y a
las 22:00, sábado a las 23:00, domingo a la 1:00) y cinco comprobaciones (está construido;
está sobre su casa del mapa, que `casas.gd` ya no dibuja, y sus tres frentes paran; el forjado está nivelado sobre dos
calles que bajan; las dos señales están en la acera de la punta, fuera de la calzada, la puerta da a la punta y el
rótulo dice ALIMENTACIÓN; y el horario, sin mover el reloj del juego). Y `python tools/run_tests.py casas solo=sanjose_` por las casas vecinas.
