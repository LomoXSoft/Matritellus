# Herramientas de la Plazuela del Toledano

Con esto se midió y se comprobó `godot/scripts/toledano.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo
aproximado: `referencias/plazuela_toledano/LEEME.md`.

- `capturas.py CARPETA [nombre…]` — baja las vistas de Street View y la foto esférica privada (ocho rumbos).
- `contactos.py CARPETA SALIDA nombre…` — varias fotos en una hoja con su nombre.
- `rumbos.py CARPETA SALIDA nombre…` — cada vista con los rumbos dibujados cada 5°: dos rumbos a lo mismo desde dos
  cámaras lo sitúan en el mapa.
- `vistas.py CARPETA nombre…` / `vistas.py aire` — el juego desde donde estuvo Street View.
- `losas.py [px]` — la textura de las losas (`godot/assets/toledano/losas.png`), dibujada: celdas de puntos al azar.
- `hojas.py [CARPETA]` — las hojas de `guion/fotos/plazuela_toledano/`.

## Lo que se aprendió aquí
1. **Una plaza sobre una pendiente sin rehornear**: cortar cada pieza plana por las facetas del relieve
   (`MapData.rg`, `rx0`, `rz0`; dos triángulos por celda, como `MapData.height`) y levantarla un tanto. Así ni flota
   ni se hunde.
2. **Lo que se pisa en pendiente**: un deck con `grad` por faceta (`MapData.foot` ya lo entiende).
3. **El anillo peatonal del mapa como contorno**: se recorta contra las calles del juego, no contra las reales, que es
   lo que ve el jugador.

## Pruebas
`python tools/run_tests.py toledano`: 11 fotos (`godot/shots/toledano_*.png`) y cuatro comprobaciones (está hecha; su
bordillo guarda 3,9 m del eje de cada calle y todo lo que hay en ella queda dentro; a pie se pisa su suelo y fuera el
suelo de siempre; bordillo, lápiz y árbol paran, las losas no, y la farola es del pueblo).
