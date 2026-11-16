# Herramientas de la rotonda de los Tricornios

Con esto se midió y se comprobó `godot/scripts/rotonda.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo
aproximado: `referencias/rotonda_tricornios/LEEME.md`.

- `capturas.py CARPETA [nombre…]` — baja las vistas de Street View de las 11 cámaras del anillo.
- `contactos.py`, `rumbos.py` — hojas de fotos y rumbos dibujados sobre una vista (copias de las de `tools/toledano/`).
- `vistas.py CARPETA nombre…` — el juego desde donde estuvo Street View (aquí las cámaras no necesitan corrección).
- `dibujos.py` — dibuja `godot/assets/rotonda/`: la bandera, el emblema de forja (recorte con transparencia), la placa,
  la grava y el mantillo.
- `hojas.py [CARPETA]` — las hojas de `guion/fotos/rotonda_tricornios/`.

## Lo que se aprendió aquí
1. **Una isleta del mapa sin rehornear**: se busca el anillo al cargar y la isleta se hace con su centro; el suelo,
   cortado por las facetas del relieve y pisable con decks inclinados (la receta de `toledano.gd`).
2. **Un marco a mano tiene que ser de mano derecha**: con `Basis(x, UP, z)`, `x` ha de ser `UP × z`, o lo que se dibuja
   sale en espejo (la placa se leía al revés).
3. **Una bandera que ondea**: un `QuadMesh` subdividido con un sombreador que mueve los vértices según `UV.x` (quieto
   junto al mástil).
4. **Una pieza de forja**: un dibujo con transparencia (`alpha scissor`) en tres capas muy juntas, para que tenga canto.
