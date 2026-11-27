# Campaña anti-Z-fighting (`obra.gd`) y guía de repaso para Pretil y Texturas

> Auditoría geométrica automatizada (`--zfight` en `godot/scripts/selftest.gd`) y limpieza por tandas sobre los edificios construidos a mano sobre `obra.gd`.
> Publicado en **0.2.6** (`v0.2.6`). Ningún archivo de **Texturas** ni archivos de otras sesiones han sido modificados.

---

## 1. Evolución de resultados (`--zfight`)

Cada edificio e interior de `obra.gd` se analiza buscando pares de triángulos de distinto material cuyas proyecciones 2D se solapan con separación perpendicular en el centroide de cruce `< 1 mm` (**exacto**) o `< 8 mm` (**cercano**).

| Tanda | Alcance | Área exacta (`< 1 mm`) | Área cercana (`< 8 mm`) | Reducción acumulada (exacta) |
| :--- | :--- | :---: | :---: | :---: |
| **Tanda 0 (línea base)** | Estado inicial sin correcciones | `2826.97 m²` | `4093.15 m²` | — |
| **Tanda 1** | `obra.gd` + primeros edificios prioritarios (`molino.gd`, `cementerio.gd`, `cuevas.gd`, `ferial.gd`, etc.) | `2470.05 m²` (`11775` pares) | `1069.12 m²` (`29125` pares) | `-12,6 %` |
| **Tanda 2** | 25 obras principales + helpers estructurales en `obra.gd` y `ring_walls()` | `243.00 m²` (`10471` pares) | `874.55 m²` (`28557` pares) | `-91,4 %` |
| **Tanda 3 + remate** | Corrección de cálculo de pendientes en `_zfight_scan_obra()` + 27 edificios/interiores (`logs/selftest_zfight_20261127_040337.log`, `75` escaneados, `67` con exacto, `73` con alguno, `32368 ms`) | **`110.17 m²`** (`7022` pares) | **`503.48 m²`** (`27956` pares) | **`-96,1 %`** |

### Cómo funciona la auditoría `--zfight`

- Archivo: `godot/scripts/selftest.gd` (`_zfight_tri_overlap`, `_zfight_scan_obra`).
- En la tanda 3 se corrigió un falso positivo en rampas/suelos inclinados: `_zfight_scan_obra()` ahora calcula el centroide 2D `c2d` real del polígono de intersección y evalúa la distancia perpendicular de cada triángulo exactamente en `c2d` usando su normal y constante de plano (`ni`, `nj`), en lugar de comparar vértices arbitrarios.
- Parámetros admitidos:
  - `python tools/run_tests.py zfight --timeout 180` (barrido completo del pueblo).
  - `python tools/run_tests.py zfight solo=<edificio> max=<m2> --timeout 180` (comprobación acotada de un único script frente a un umbral en m²).

---

## 2. Guía para Pretil (`obra.gd` y edificios a mano)

### Las 4 reglas constructivas y los 6 helpers

1. **Marcos y cercos (`door_frame()`, `stone_frame()`, `window()`):** sacar o embutir `>= 1,5–2 cm` en jamba y dintel respecto al plano de fachada (`z = 0.0`) y evitar que las esquinas de jamba y dintel compartan cara coplanar (`0 mm`).
2. **Carteles y placas (`sign_board()`):** levantar la cara frontal de texto o textura al menos `>= 1,2–1,5 cm` (`lift := 0.014` por defecto) sobre la caja/marco de fondo, y separar el tablero de su moldura exterior.
3. **Suelos y capas apiladas (`_lay`, `flat`, `cornice()`):** escalonar capas en altura `>= 1,2–1,5 cm` entre materiales distintos (ej. aceras/alcorques/pavimentos en `paseo.gd` y anillos en `plaza.gd`, escalonados a `0.062` / `0.076`), cortando contra la rejilla de terreno (`MapData.rg`) cuando siga rasante.
4. **Medianeras, bloques pegados y `CULL_DISABLED` (`ring_walls()`):** meter las medianeras de Catastro `2,5 cm` hacia dentro (`ring_walls(..., inset := 0.025)`) y embutir o retranquear pilares, cornisas y anexos `1,5–6 cm` (ej. torre contra ermita en `caridad.gd`, postes contra paños en `almazara.gd`, remate de marquesina en `ies.gd`). Ojo con materiales `CULL_DISABLED` (chapas y tejas): su cara trasera también dibuja y parpadea si enrasa por detrás.

### Comprobación obligatoria tras tocar un edificio

```powershell
python tools/run_tests.py zfight solo=<edificio> max=1.0 --timeout 180
```

Y antes de cerrar bloques grandes de mapa o release:

```powershell
python tools/run_tests.py zfight --timeout 180
```

### Qué repasar visualmente y residuos conocidos

- Repasar de cerca puertas, escaparates, vitrinas, rótulos de negocio, petos/albardillas y uniones entre nave principal y anexos (cuestas y esquinas oblícuas).
- **Residuos externos en `.glb` (no editables desde `.gd`):**
  - `godot/scripts/puente.gd` (`9.417 m²` exactos): piezas amarillas/negras/grises dentro de `obra.glb` / grúa.
  - `godot/scripts/casa_dentro.gd` (`6.377 m²` exactos): cama externa GLB (`#f5b995 vs #fcffff`).
  - `godot/scripts/planta_solar.gd` (`2.215 m²` exactos): incluye el coche GLB estático `cuatrolatas`; los bidones de chatarra ya quedaron separados en anillo.
- **Resto de scripts manuales:** todos los edificios no GLB quedan por debajo de `5,6 m²` exactos (`cultura.gd` `5.576 m²`, `cuevas.gd` `4.775 m²`, `sopiss.gd` `4.592 m²`, etc.), repartidos en pares menudos (`< 0.55 m²` por foco), con `molino.gd` en `0.933 m²` (toda la puerta roja y fachada limpias).

---

## 3. Guía para Texturas (casas de calle, fachadas y telas)

> **Confirmación explícita:** en estas tres tandas **no se ha modificado** ningún archivo de Texturas (`godot/scripts/casas.gd`, `godot/scripts/casas_calles.gd`, `godot/scripts/texturas.gd`, `godot/scripts/tela.gd`, `tools/bake_godot.py`, `godot/data/map.json`). Todo ese bloque queda pendiente de su propio repaso visual/geométrico.

### Checklist de 5 puntos para Texturas

1. **Rótulos, zócalos y molduras sobre `fly` (`casas.gd`, `casas_calles.gd`):**
   - Revisar `cartel ... z=...`, `plinth=...` y bandas de cornisa (`trim`) cuando haya plantas voladas (`fly`, `prev_fly`) para que ningún cartel ni zócalo quede coplanar (`< 1,2–1,5 cm`) con el paño de pared o el intradós del vuelo inferior.
2. **Huecos (`win`, `door`, `gar`, `bal`):**
   - Comprobar en ángulos rasantes que vidrio, persiana, cortina y reja mantienen separación limpia entre sí y respecto al marco y la hoja de puerta/garaje.
3. **Toldos (`tela.gd`) y tejados (`BaseMaterial3D.CULL_DISABLED` en `casas.gd`):**
   - `tela.gd` usa `render_mode cull_disabled;` y `casas.gd` activa `CULL_DISABLED` en faldones/tejas; vigilar que los lienzos de toldo y caídas no queden pegados (`0 mm`) contra dinteles, balcones o fachadas colindantes.
4. **Medianeras, `paño`/`pano`, `lado` y porches (`casas.gd`, `casas_calles.gd`, `tools/bake_godot.py`, `godot/data/map.json`):**
   - Revisar cambios parciales de textura (`paño`), caras laterales (`lado`) y porches adosados para no duplicar polígonos coplanares en esquinas ni en lindes entre casas vecinas.
5. **Alineación entre fachada (`_facade`), cuerpo lateral de Catastro (`_edges`) y tejado (`_eaves`/`_roof_y`) en Calle de Santa Ana:**
   - Revisado visualmente en pruebas de 0.2.6; comprobar `stana_96` y viviendas del frente opuesto en Santa Ana donde la fachada delantera aparece ligeramente adelantada/separada como «careta» respecto a la medianera lateral, y casas bajas con huecos visibles entre el remate superior de fachada y el alero/tejado.

### Hecho por Texturas (27/11, sin commit; APROBADO por el usuario el 27/11)

- **1 (rótulos, zócalos, molduras sobre `fly`):** revisado en el código; los desfases de `cartel`, placas, parches y bandas ya separan más de 1,5 cm. Sin cambios.
- **2 (huecos):** el alféizar, el suelo del arco y el poyete de escaparate estaban en el mismo plano que el pie del hueco: ahora 1,5 cm por encima. La persiana va 1,2 cm detrás de sus lamas, que quedan 9 mm detrás del marco.
- **3 (toldos y tejados):** revisado; sin pegados a 0 mm visibles. La losa de las terrazas de `_adosado` entra 1,5 cm en los muros.
- **4 (paño, lado, porches):** el paño corta la pared, no la dobla; `lado` va 5 cm dentro. Sin cambios.
- **5 (Santa Ana):** `stana_96` está de verdad ~0,9 m por delante de su vecina (Street View 2024): no se mueve. La rendija de lado a lado en su esquina venía de `_plain` (paredes de Catastro metidas 5 cm sin alargarse donde el contorno gira hacia dentro): ahora siguen 10 cm. La ranura bajo el alero de las casas bajas (la fachada acaba en `top` y el tejado empieza ~0,34 m más arriba): relleno de pared con el color de la última planta y sus paños.
- **Medida:** `python tools/run_tests.py zfight casas-sueltas --timeout 1200 --headless` (modo nuevo de `selftest.gd`). 3406 casas: exacto 10382 → 3348 m² (−68 %), cercano 2997 → 2100. Lo que queda es casi todo oculto (dorsos a z −0,30/−0,24 dentro del muro, suelos enterrados de `rosa_*`, azoteas que cruzan el muro).
- **Hoja:** `fotos/zfighting/santana_esquina_antes_despues.jpg`.

### Cómo verificar cambios en casas de calle

```powershell
python tools/cache_casas_check.py
```

(O con `--window` para tiempos de render reales.) Recuerda actualizar `left` en `casas.gd:build()` si una casa pasa a dejar estado nuevo fuera de sus nodos hijos, `world.hand_tags` o `MapData.outlines`.

---

## 4. Archivos modificados en la campaña (sin commit)

- **Auditoría y helpers base:** `godot/scripts/obra.gd`, `godot/scripts/selftest.gd`.
- **Tandas 1–3 (`godot/scripts/`):** `aceras_altas.gd`, `afueras.gd`, `almazara.gd`, `asador.gd`, `bancosancho.gd`, `calasanz.gd`, `caridad.gd`, `casa_dentro.gd`, `cementerio.gd`, `chinos.gd`, `colegio.gd`, `comunal.gd`, `correos.gd`, `cuartel.gd`, `cuevas.gd`, `cultura.gd`, `entrada.gd`, `farmacia.gd`, `ferial.gd`, `garage.gd`, `ies.gd`, `kebabdeluxe.gd`, `masahorro.gd`, `matias.gd`, `maxiprecio.gd`, `maxiprecio_dentro.gd`, `mercamona.gd`, `merkocarry.gd`, `merkocarry_dentro.gd`, `molino.gd`, `noche.gd`, `noche_dentro.gd`, `optica.gd`, `optica_dentro.gd`, `paseo.gd`, `pisacastana.gd`, `pisacastana_dentro.gd`, `planta_solar.gd`, `plaza.gd`, `puente.gd`, `residencia.gd`, `rize.gd`, `rocas.gd`, `salvador2.gd`, `sopiss.gd`, `teledurum.gd`, `tetoqa.gd`, `tetoqa_dentro.gd`, `toledano.gd`, `toti.gd`.
- **Documentación:** `guion/zfighting_repaso.md`, `README.md`, `PROJECT_STATE.md`, `TRASPASO_CLAUDE.md`.

---

## Notas de uso de `--zfight` (Pretil, 27/11; comprobadas por Sistemas en `selftest.gd` y en `logs/selftest_zfight_20261127_040337.log`)

- **`max` se compara con el área exacta total de todo lo que casa con `solo`** (subcadena del nombre del archivo). En la 0.2.6 sin tocar, 36 sitios a mano pasan ya de 1,0 m² (de `puente.gd` 9,417 y `cultura.gd` 5,576 a `chinos.gd` 1,026): en ellos `max=1.0` falla de entrada, sin que nadie haya roto nada. **Lectura práctica: no subir del valor de antes.** Se pasa `python tools/run_tests.py zfight solo=<archivo>.gd --timeout 180` sin `max` antes y después de tocar, y se comparan las dos áreas.
- **Solo se miran los nodos hechos sobre `obra.gd` que estén visibles al correr, y no se entra en uno para buscar otro dentro** (`_zfight_collect_obras`). No salen en el informe los decorados ocultos hasta que entras (por ejemplo `cuevas_dentro.gd`) ni lo que no va sobre `obra.gd` (por ejemplo `petril.gd`). Un resultado limpio no dice nada de ellos.
- **No hay batería completa en `logs/` posterior a la campaña:** la última (`selftest_full_20261126_214200.log`, 0 fallos) es de antes de la 0.2.4; la 0.2.5 y la 0.2.6 no tienen ninguna.
