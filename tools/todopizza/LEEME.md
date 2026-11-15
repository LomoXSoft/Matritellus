# Herramientas de la pizzería «Todopizza»

Con esto se midió y se comprobó `godot/scripts/todopizza.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo
aproximado: `referencias/todopizza/LEEME.md`.

## Qué hay
- `capturas.py CARPETA [nombre…]` — baja las vistas de Street View (el rumbo se calcula hacia el centro de la casa).
- `vistas.py CARPETA_SV NOMBRE…` — el juego desde donde estuvo Street View (lee `views.json`):
  `python tools/run_tests.py "$(python tools/todopizza/vistas.py CARPETA_SV o1 o1_zoom n2 e1_zoom)"`.
- `hojas.py CARPETA_SV` — las dos hojas de `guion/fotos/todopizza/`.
- `enganche.py` — lo que añade a `world.gd` y `selftest.gd`, y lo que quita de `mercamona.gd`; ya aplicado.

## Lo que se aprendió aquí
1. **El contorno de Catastro puede ser el del tejado, no el de las paredes.** En un pabellón con aleros muy volados,
   la primera versión salió un 40 % más grande que en las fotos. Se ve comparando el juego con Street View desde el
   mismo sitio: medir el ancho aparente (en píxeles, con la tangente) en las dos y dividir.
2. **Un sitio nuevo en una parcela que el horneado ya deja libre no necesita rehornear**: el script se construye
   cuando el mapa trae la entrada del vecino (`MapData.mercamona`), y lo dice en su cabecera y en `world.gd`.
3. **Cristal de verdad**: material con transparencia (alfa 0,28, sin descarte de caras) y, detrás, un interior con
   caras hacia dentro (las paredes de fuera son de una sola cara y desde dentro no se verían) y material con luz propia.
4. **Los parches de texto con `\n` no se pueden pasar por un heredoc de bash** (se comen las barras): escribir el
   script de parche con la herramienta de escribir archivos, o editar a mano.

## Pruebas
`python tools/run_tests.py todopizza`: 9 fotos (`godot/shots/todopizza_*.png`) y tres comprobaciones (está construida;
es maciza, su valla solo deja pasar delante de las puertas y nada pisa una calzada; el mapa sabe que está ahí, las
puertas dan a su explanada y el cartel dice TODOPIZZA junto a la esquina). Como `mercamona.gd` cambió, además `mercamona`.
