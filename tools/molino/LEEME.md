# Herramientas del molino (Molino del Tío Gerardo)

Con esto se midió `godot/scripts/molino.gd` (noviembre de 2026). Mismo método que `tools/petril/` y `tools/plaza/`
(léelos primero); aquí solo lo nuevo. Qué es cada cosa del recinto y sus medidas: `referencias/molino_tio_gerardo/`.

## Qué hay
- `marco.py` — el marco del molino (origen en el centro de la torre, x al este a lo largo del muro norte del corral,
  z al sur): `python marco.py w x,z` (mapa → marco) y `l x,z` (marco → mapa).
- `catastro.py x0 z0 x1 z1 salida.json` — las partes de Catastro dentro de un rectángulo del mapa, con su uso, año y
  plantas. Vale para cualquier sitio.
- `plano.py` — una ortofoto (de `tools/plaza/aerea_wmts.py`) con rejilla en metros del mapa y, si se quiere, las
  partes de Catastro encima. `aerea_marco.py` — la misma ortofoto girada al marco del molino.
- `panos.py` — panorámicas de Street View: `info ID` dice dónde está una, su fecha, su altitud y **todas las que
  nombra a su lado** (vecinas a lo largo de las calles y las antiguas del mismo punto); `foto ID salida.jpg rumbo
  cabeceo [campo]` baja una vista. El primer identificador se copia de la barra de direcciones de Google Maps (las
  22 letras tras `!1s`).
- `capturas.py CARPETA` — baja las 36 vistas con que se midió (qué panorámica, hacia dónde, con qué campo). Las fotos
  son de Google y no se guardan en el repositorio; esta lista sí.
- `vistas_sv.py` — el juego fotografiado desde esos mismos puntos (`python vistas_sv.py nombre…` da el `vistas=…`
  para `tools/run_tests.py`, en el marco del molino: vistas `ml_…`) y `hoja` para montar «Street View | juego».

## Lo que se aprendió aquí
1. **El buscador de panorámicas por coordenadas ya no existe** (Google lo retiró en 2026). Lo que funciona: los datos
   de una panorámica conocida traen las de alrededor en 100 m. Con una sola sacada del navegador se tiene la calle
   entera, los caminos de atrás y los años anteriores.
2. **Las miniaturas de Street View son fotos rectilíneas de 1024 × 640 y su campo es el horizontal** (comprobado
   girando 5° y midiendo el desplazamiento: 78 px con campo 60). El juego quiere el vertical.
3. **La altitud que da Google de cada panorámica sirve para alturas**: con dos vistas lejanas (58 y 61 m) y sus
   altitudes, el alero del molino salió a la misma cota (704,8 m) por los dos lados. Desde cerca, tras una tapia, no
   se puede medir la altura de nada.
4. **Lo que tapa una tapia depende de su altura más que de nada**: con la tapia 35 cm más alta de la cuenta el molino
   «salía bajo» en todas las vistas de la calle. La altura de la tapia se sacó de una puerta (2 m) que hay en ella.
5. **Catastro puede tener el edificio principal mal puesto**: su círculo del molino está 11 m al norte del real.
   La ortofoto manda; y lo redondo (la era) da el centro mejor que la caperuza, que sale desplazada por la altura.
6. **Hacia dónde miran las aspas** se saca de la ortofoto (la sombra y la línea de las aspas, vistas desde arriba, son
   perpendiculares al eje) y se comprueba en una vista: el buje a un lado u otro de la caperuza.
7. **La posición de Google en una misma calle puede fallar distinto en cada tramo**: aquí 1,5 m al este en la mitad
   sur y casi nada en la portada del norte. Cada panorámica se comprueba contra algo conocido antes de comparar.
8. **Un sitio hecho a mano debe decirle al mapa dónde tiene muros** (`MapData.outlines`): el juego pregunta por el
   sitio libre (`room_at`) para aparcar coches y poner mesas, y sin eso solo ve un solar vacío.

## Pruebas
`python tools/run_tests.py molino --window` fotografía el recinto desde doce sitios (`godot/shots/molino_*.png`) y
comprueba que los muros, la torre y el corral paran, que la puerta roja, el camino y la era están libres, que las aspas
giran, que nada pisa la calzada y que se entra a pie hasta la puerta del molino.
