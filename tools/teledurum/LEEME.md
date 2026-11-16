# Herramientas del kebab «Tele Dürum» (calle Santa Ana)

Con esto se midió y se comprobó `godot/scripts/teledurum.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo
aproximado: `referencias/tele_durum/LEEME.md`.

## Qué hay
- `capturas.py CARPETA [nombre…]` — baja las vistas de Street View (2024, 2019, 2013).
- `vistas.py CARPETA_SV NOMBRE…` — el juego desde donde estuvo Street View:
  `python tools/run_tests.py "$(python tools/teledurum/vistas.py CARPETA_SV f24 o24 e24 f24_alto)"`.
- `hojas.py [CARPETA_SV]` — las hojas de `guion/fotos/tele_durum/` (sin carpeta, solo la 02 y la 03, la del horario).
- `enganche.py` — lo que añade a `casas_calles.gd` (la casa pasa a `["obra"]`), `world.gd` y `selftest.gd`; ya aplicado.

## Lo que se aprendió aquí
1. **En una calle estrecha, el juego es la mejor regla de medir.** Con la cámara a 3,7 m, medir píxeles a mano daba
   errores de un metro. Lo que funcionó: construir una primera versión, fotografiar el juego desde la cámara de Street
   View, leer en esa foto a qué píxel cae cada medida conocida y pasar con eso los píxeles de la foto real a metros.
   Dos vueltas y los huecos, el cartel y la altura de planta casaron.
2. **Una casa que usa una misión se puede entregar a un sitio hecho a mano sin tocar la misión**, si se conserva su
   entrada en `MapData.houses` (la misión la busca por nombre y calcula su puerta del frente). Avisar a Sistemas y
   pasar su prueba (`sabotaje`).
3. **Cambiar un nombre que sale en textos, misión y pruebas es cosa de quien lleva esos archivos**: se le pide.
4. **No había máquina de bolas libre** (Poly Pizza, OpenGameArt, Sketchfab CC0). Hecha con primitivas: globo de
   material transparente con cuatro capas de bolitas dentro.

5. **Un sitio con horario se hace con dos nodos que se enseñan y se esconden**, no rehaciendo la malla: lo fijo se
   construye y se confirma como siempre; lo que depende de la hora se construye después y se confirma dentro de su
   nodo (`_commit_to`). La hora se lee de `W.get_parent().clock` (el mundo cuelga del juego).
6. **En la completa no se mueve la hora para comprobar un horario**: se prueba la regla como función pura y se pone
   cada estado a mano. Mover la hora y esperar fotogramas despierta a todo lo que lee el reloj.

## Pruebas
`python tools/run_tests.py teledurum`: 18 fotos (`godot/shots/teledurum_*.png`: a las 12:30 cerrado, a las 18:30 y a
las 23:00 abierto, a las 04:30 cerrado) y cuatro comprobaciones (está construido; está sobre su casa del mapa, que
`casas.gd` ya no dibuja, y su frente para; la máquina de bolas está en la acera junto a la puerta, fuera de la
calzada, se choca con ella, y el rótulo dice TELE DÜRUM; abre de 18:00 a 04:00, con persianas, luces y asador como
toca en cada estado, y el frente para en los dos).
