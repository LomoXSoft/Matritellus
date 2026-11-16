# Herramientas de Kebab Deluxe

Con esto se midió y se comprobó `godot/scripts/kebabdeluxe.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo
aproximado: `referencias/kebab_deluxe/LEEME.md`.

- `capturas.py CARPETA [nombre…]` — baja las vistas de Street View (2024, 2019, 2013).
- `contactos.py`, `rumbos.py` — hojas de fotos, y rumbos dibujados sobre una vista (copias de las de `tools/toledano/`).
- `vistas.py CARPETA nombre…` — el juego desde donde estuvo Street View, con cada cámara sacada 2,6 m hacia la avenida.
- `rotulo.py` — dibuja `godot/assets/kebabdeluxe/rotulo.png`, `bandera.png` y `montante.png`.
- `hojas.py [CARPETA]` — las hojas de `guion/fotos/kebab_deluxe/`.

## Lo que se aprendió aquí
1. **En esta avenida las cámaras de Google están metidas hacia las casas** (la de enfrente, a 1,2 m de la fachada): con
   rumbos tan oblicuos no se puede medir; el frente sale del Catastro.
2. **Un rótulo luminoso**: la emisión encima del sol lo deja blanco. Encendido va sin sombrear (sus colores tal cual,
   de día y de noche); apagado, sombreado como la pared.
3. **Cristal poco brillante** (`metallic_specular` bajo): si refleja el cielo, un ventanal parece un hueco vacío.
4. **Una parada de una misión**: comprobar con la misión entera (`sabotaje`), no solo con el modo del sitio.

## Pruebas
`python tools/run_tests.py kebabdeluxe`: 9 fotos (de día y de noche) y dos comprobaciones (está hecho; está sobre su
casa del mapa, que `casas.gd` ya no dibuja, el frente para, la acera de las cajas del sabotaje está libre y el nombre
es el del juego). Y `python tools/run_tests.py sabotaje`.
