# Herramientas de la almazara «González de la Ruz»

Todo lo que se sabe del sitio está en [referencias/almazara/LEEME.md](../../referencias/almazara/LEEME.md). Aquí, solo las herramientas.

- `capturas.py CARPETA`: baja las fotos de Street View de las dos calles y escribe `views.json`. Son de Google: la carpeta va fuera del repositorio.
- `alzado.py CARPETA AX,AZ BX,BZ SALIDA.jpg vista…`: tiende un frente entero en plano a partir de varias fotos, con rejilla de un metro. Para el frente de la carretera: `264.27,-523.36 396.4,-645.6`.
- `manzana.py [SALIDA.png] [partes=RC,…] [cams=CAMARAS.json]`: las partes de Catastro de la manzana y un plano sobre la ortofoto con las calles del juego.
- `plano.py SALIDA.png x0 z0 x1 z1 [px_por_m] [planta.json]`: un trozo de la ortofoto fina con rejilla, Catastro y la línea del frente con sus metros.
- `vistas.py CARPETA vista…`: la cadena `vistas=…` para fotografiar el juego desde los puntos de Street View.
- `hojas.py`: las hojas del juego (`guion/fotos/almazara/`). Con `CARPETA SALIDA`, las comparaciones con Street View, que tampoco van al repositorio.
- `dibujos.py`: los PNG propios (rótulo, mural, emblema, cartel, tablero de la tienda).

## El retranqueo del Triunfo

El horneado corta los edificios con el pasillo de cada calle (`corridor`, 2,4 m a cada lado del eje en el Triunfo). La pared de Catastro se mete en ese pasillo 0,95 m en el testero de la nave vieja, y va saliendo de él hasta el final del tramo viejo. Por eso `T0` y `T1` de `almazara.gd` están un metro más adentro que Catastro, y `T2` 0,4 m. Antes de mover esos puntos, ensayar con `python tools/colegio/ensayo.py bake …` y mirar la holgura del nodo 1250.
