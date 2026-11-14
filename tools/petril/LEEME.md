# Herramientas del Petril (y de cualquier edificio hecho a mano desde fotos)

Con esto se midió y se afinó `godot/scripts/petril.gd`. Sirven igual para el próximo sitio: lo único propio del
Petril es `marco.py` (su marco de coordenadas) y las cámaras ya ajustadas de `vistas/`.

## La idea
Una foto real no se compara «a ojo»: se **ajusta la cámara** con que se tomó a puntos conocidos del modelo, se
fotografía el juego desde ese mismo sitio y se ponen las dos lado a lado. Lo que no coincide salta a la vista, y los
colores se miden **en el mismo parche** de las dos.

## Paso a paso
1. **Puntos**: en la foto, píxeles de cosas cuya posición en el modelo se conoce (esquinas de Catastro, vanos,
   bases de columnas). `zoom.py foto.jpg trozo.jpg x0 y0 x1 y1 [aumento] [rejilla]` saca un trozo ampliado con
   rejilla en píxeles de la foto. Ojo: las cifras de la rejilla son de la foto, no del trozo ampliado; leer mal eso
   cuesta media hora.
2. **Cámara**: `encaja.py nombre ANCHO ALTO "X,Y,Z,px,py" ...` (X este, Y altura sobre el suelo de la plazuela,
   Z sur; px, py dentro del contenido de la foto). Opciones:
   - `--pp` si la foto está recortada o corregida (el centro de la lente no es el centro de la foto);
   - `--level` si las verticales salen verticales (foto «rectificada»): cabeceo 0;
   - `--eye 1.6` para fijar la altura de la cámara; `--fix-fov F` si todos los puntos están en un plano.
   Escribe `vistas/nombre.json`: la vista para el juego y el recorte de su foto que equivale a la real.
   Un error medio de 1–2 px es un ajuste fino (foto frontal); 10 px, uno aproximado (sirve para comparar, no
   para decidir 30 cm).
3. **Foto del juego**: `--selftest "--vistas=<view del json>" --hora=H` (las vistas llamadas `pt_...` van en el marco
   del Petril, con alturas sobre el suelo de la plazuela; un séptimo número es el campo de visión).
4. **Lado a lado**: `pareja.py hoja.jpg CARPETA_DE_FOTOS nombre ...`.
5. **Color**: `color.py imagen nombre:x0,y0,x1,y1 ...` da el color medio (en luz lineal) de cada parche; mismos
   parches en la foto real y en `juego_<nombre>.jpg`. El tinte que lleva una textura a un color:
   `tinte = srgb(lin(objetivo) / lin(media))`.

## Lo que hay que saber
- **La hora de la foto**: pedir al juego la misma hora (`--hora=16` para una foto de las 16:00), y comprobar en la
  primera imagen que las sombras caen hacia el mismo lado que en la real. (Hasta la 0.0.4 el sol del juego iba al
  revés, salía por el oeste: este trabajo se hizo así, con `--hora=11.6` para las 16:00 y `9.8` para las 18:00. Se
  corrigió en `game.gd`, `_apply_sky`, para la 0.0.5, a raíz de estas comparaciones.)
- Una fachada al sol rasante sale la mitad de clara que de frente: comparar colores solo con la misma luz, y fiarse
  de las **proporciones entre materiales** (cajón/ladrillo, zócalo/ladrillo), no del valor absoluto.
- Las fotos de terceros (Ayuntamiento, Junta) no se guardan en el repositorio: solo las cámaras ajustadas.
- Posiciones, de la ortofoto; alturas, de Street View desde lejos o de una foto frontal ajustada; nunca al revés.

## Archivos
- `marco.py` — marco del Petril: `python marco.py w x,z` (mapa → marco) y `l x,z` (marco → mapa).
- `encaja.py`, `pareja.py`, `color.py`, `zoom.py` — lo de arriba.
- `vistas/ala.json`, `iglesia.json`, `jccm.json` — cámaras de las tres fotos del Ayuntamiento y de la Junta
  (frente del ala este, fachada de la iglesia, conjunto desde la esquina suroeste).
- `vistas_sv.txt` — las siete vistas que copian tus capturas de Street View (posición, rumbo y campo de cada una).
