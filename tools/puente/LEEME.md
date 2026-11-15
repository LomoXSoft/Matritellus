# Herramientas del puente de Arroyuelo Medio

Con esto se midió y se comprobó `godot/scripts/puente.gd` (noviembre de 2026). Mismo método que `tools/petril/`,
`tools/plaza/` y `tools/molino/` (léelos primero); aquí solo lo nuevo. Qué es cada cosa y sus medidas:
`referencias/puente_arroyuelo/LEEME.md`.

## Qué hay
- `capturas.py CARPETA` — baja las vistas de Street View con que se midió (mayo de 2009, las únicas con el puente, y
  algunas de 2024 para las casas). Las fotos son de Google y no se guardan; la lista sí.
- `resecar.py` — dónde estaba de verdad la panorámica del cruce, por los rumbos a los que ve los huecos de la casa de
  ladrillo (mínimos cuadrados sobre el sitio de la cámara y un error de rumbo), y dónde pone eso los extremos de los
  pretiles.
- `alturas.py` — el suelo del juego, las casas hechas a mano y los muros de las genéricas en el marco del puente.
- `plano.py ORTOFOTO SALIDA.jpg` — el tramo en el marco del puente sobre una ortofoto, con las manzanas, los frentes
  y los ejes de calle del juego (y un diseño encima, si se le da).
- `vistas_sv.py` — el juego fotografiado desde donde estuvo Street View (`python vistas_sv.py nombre…` da el
  `vistas=…` para `tools/run_tests.py`; añade `puente-limpio` para verlo sin obra ni pancarta) y `hoja`.
- `hojas.py CARPETA_SV` — las tres hojas de `guion/fotos/puente/`.
- `enganche.py` — lo que el puente añade a `selftest.gd` (el modo `--puente` y `_arroyuelo_checks`); ya está aplicado.
- Las máquinas de la obra: `tools/blender/obra.py` (y `obra_lista.py` para ver qué trae un .blend o .fbx bajado, sin
  ejecutar lo que lleve dentro). Créditos en `godot/assets/obra/CREDITOS.txt`.

## Lo que se aprendió aquí
1. **Una ortofoto vieja puede estar corrida metro y medio.** La de 2009 ponía el puente 1,4 m al oeste. Mandan las
   fachadas (Catastro, las casas del juego) y lo que se ve alinearse con ellas desde dos sitios.
2. **Las panorámicas de 2009 están peor puestas que las de ahora**: la del cruce, 2,8 m fuera de sitio y con el rumbo
   4,3° girado. Se reseca con cosas conocidas antes de medir nada desde ella (`FIX` y `TURN` en `vistas_sv.py`).
3. **Lo que parece estar «delante de» algo en una vista en escorzo no está a su altura**: el extremo del puente se ve
   sobre la medianería de dos casas, pero queda cuatro metros más abajo. Los escalones del lado este salieron primero
   pegados al puente por eso; la comparación foto a foto lo cantó.
4. **Con el relieve exagerado 2,5 veces, una acera alta no puede seguir a la vez la calle y las puertas.** Junto al
   puente va a nivel (mandan las puertas) y más arriba sigue la calle. Las casas solo se SUBEN a la acera: una que
   da también a otra calle más alta se queda como está (bajarla la hundía por el otro lado; lo avisó `relief`).
5. **Suelos inclinados**: `MapData.foot` admite `grad` en los suelos `poly` (cuánto suben por metro, como vector
   sobre el mapa).
6. **Las casas hechas a mano enlosan hasta el borde de la calzada** (`casas.gd`, `_acera`), y eso asomaba dentro del
   cauce: `_in_old_bed` lo deja fuera de ese tramo.
7. **Una valla de dos paneles tiene una rendija en medio**: un rayo de prueba por el centro exacto pasa por ella.
8. **OpenGameArt no pide registro** y tiene lotes CC0 de obra; Sketchfab sí lo pide para bajar.

## Pruebas
`python tools/run_tests.py puente --window`: 20 fotos (`godot/shots/puente_obra_*.png`, `puente_limpio_*.png`) y
cinco comprobaciones (casas a nivel de la acera, muros y puente sólidos, la obra entera y luego nada de ella, a pie
por los escalones, el puente y la esquina, y que la obra se va sola cuando toca). Lo de la misión sigue en `firmas`
y `civicos`.
