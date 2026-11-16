# Herramientas del cuartel de los Tricornios (avenida de la Constitución)

Con esto se midió, se preparó el mapa y se comprobó `godot/scripts/cuartel.gd` (noviembre de 2026). Qué es cada cosa,
las fuentes y lo aproximado: `referencias/cuartel_tricornios/LEEME.md`.

## Qué hay
- `capturas.py CARPETA [nombre…]` — baja las 42 vistas de Street View. No se guardan en el repositorio.
- `contactos.py CARPETA SALIDA nombre…` — varias fotos en una hoja con su nombre.
- `medir.py CARPETA NOMBRE CARA PLANO px,py…` / `… fit px,py=x…` — de píxel a metros sobre una fachada (`o` la de la
  avenida, `n` las del norte, `s` las del sur) y ajuste de la cámara.
- `planta.py SALIDA [x0 z0 x1 z1 [zoom]]` — la foto aérea bajo una cuadrícula en metros del mapa, con el Catastro.
- `vistas.py CARPETA NOMBRE…` — el juego desde donde estuvo Street View (con las cámaras ajustadas).
- `hojas.py [CARPETA]` — las hojas de `guion/fotos/cuartel_tricornios/`.
- `logo.py` — pinta el logo de los Tricornios y la franja de bandera de sus coches (`godot/assets/tricornios/`).
- `vistas.py coche` — el coche patrulla aparcado ante la escalinata, desde todos los lados.
- `enganche.py` — lo que añade a `bake_godot.py`, `map_data.gd`, `world.gd` y `selftest.gd`; ya aplicado.
- `ensayo.py` — ensayar el horneado con este `enganche.py` sin tocar el mapa, y comparar dos mapas (copia del del
  colegio).

## Lo que se aprendió aquí
1. **El Catastro puede equivocarse en los huecos entre cuerpos** (aquí, 2 m de más en cada uno) aunque acierte en el
   contorno de fuera. Se ve al ajustar la cámara: con las esquinas interiores el ajuste no cierra (0,8 m de error);
   con las de fuera y pidiendo que las ventanas de los dos cuerpos midan lo mismo, sí (0,2 m).
2. **Un edificio simétrico se mide mejor por su eje**: las ventanas, a distancias iguales del retranqueo a cada lado.
3. **Dos fachadas del mismo edificio deben dar las mismas alturas.** Las del norte salían un 23 % más altas que las de
   la avenida: la cámara del norte estaba más cerca de lo que decía Google (3,8 m, no 4,8).
4. **En las fotos de una fachada que mira al norte, el este queda a la izquierda**: cuidado al numerar ventanas.
5. **Lo que cuelga de cada fachada, en métodos propios** (`_x_…`), no en funciones anónimas de varias líneas dentro de
   un diccionario; `_block(contorno, alto, {lado: {...}})` hace una fachada por lado.
6. **Decir dónde, no hacer**: lo que es de otra sesión (el coche patrulla, la persecución) se le pide; el edificio
   solo expone los sitios (`patrol`, `door`, `gate`, `bays`). Sistemas tuvo el coche hecho antes de que el cuartel
   estuviera horneado.
8. **Marcas sobre un modelo comprado: calcomanías (`Decal`), no piezas.** Una caja pegada a la puerta no sigue su
   curva; un `Decal` se proyecta sobre lo que haya. Un decal de Godot proyecta a lo largo de su −Y y la parte de
   arriba de la imagen es su −Z: la base se monta con `y = −hacia_dentro`, `z = −arriba`, `x = y × z`. Para que no
   caiga sobre el suelo, la fachada o un vecino: `cull_mask` a una capa propia (la 15) y esa capa añadida a las
   mallas de la carrocería. `normal_fade` quita lo que queda de canto. En «mobile» caben 8 por malla.
9. Las marcas no pueden ir en `_extras("tricornio")`: los Pitufos toman de ahí sus luces y saldrían con el logo.
7. Un `"\n"` dentro de un script de Python escrito con heredoc en esta consola llega como salto de línea de verdad:
   los parches con barras invertidas, con la herramienta de escribir archivos.

## Pruebas
`python tools/run_tests.py cuartel`: 14 fotos (`godot/shots/cuartel_*.png`) y cuatro comprobaciones (está construido,
con sus tres rótulos, sus plazas y el sitio del coche; sus fachadas, su escalinata, la verja y el murete paran; nada
suyo pisa una calzada y el mapa sabe que está; la entrada da a la avenida, la verja a Víctor Pradera y los rótulos
son los del juego). Y `relief` y `sentido`. El coche: `tricornio` (de Sistemas).
