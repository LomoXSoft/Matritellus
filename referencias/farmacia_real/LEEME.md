# Referencia: la farmacia de la calle Real, la droguería de la esquina y la casa de ladrillo

Pedido por Luis el 15-11-2026 (`usuario_01_mapa.jpg`: la parcela de la farmacia en el mapa): «Siguiente edificio.
farmacia calle real, y las dos edificios colindantes. Una droguería y un casa de facha de ladrillo, blanca y piedra».
Y al ver cómo estaba la fila en el juego (`usuario_02_quitar_casa_vieja.jpg`, la casita estrecha tachada): «Si
eliminamos esta casa vieja y pequeña. Tendrías más espacio para trabajar solo la droguería y la farmacia?». Hecho así:
la casa estrecha (el nº 24 real) no está y su sitio lo ocupa la droguería.

Al ver la fila hecha preguntó: «Y no dejar el final de la calle de la droguería tan estrecha?». Ensanchar la boca de la
calle de Colón pedía rehornear el mapa; entre calzada más ancha, solo más acera o dejarlo, eligió «Dejarlo como está».
Su veredicto: «Está todo perfecto».

El modelo es `godot/scripts/farmacia.gd` (sobre `obra.gd`). Herramientas: `tools/farmacia/`.

## Marco
Origen en el extremo norte de la fachada de la casa de ladrillo, mapa (-61,17, -89,09). `x` a lo largo de las fachadas
hacia la calle de Colón (hacia el sur; vistas desde la calle, de izquierda a derecha); `z` sale a la calle Real.
- Casa de ladrillo: x 0–5,33 (Catastro `4292807VJ5649S`, nº 30).
- Farmacia: x 5,33–23,55 (Catastro `4292815VJ5649S`, nº 26, más el patio que había al norte: Catastro aún no tiene la
  mitad norte del edificio nuevo).
- Droguería: x 23,55–29,38 a la calle Real y 12 m a la de Colón (Catastro `4292814VJ5649S`, nº 22, y el hueco del 24,
  `4292808VJ5649S`).

## Fuentes
- **Street View**, noviembre de 2024 (y 2019, 2013, 2009). Lista en `tools/farmacia/capturas.py`; las fotos no se
  guardan. Las posiciones de Google van unos 2 m desviadas: `tools/farmacia/medir.py` las corrige contra las
  medianeras de Catastro.
- **Catastro**: `tools/casas/<referencia>/datos.json` de las cuatro parcelas.

## Qué hay (de norte a sur)
- **Casa de ladrillo**: bajo blanco sobre zócalo de mampostería, ventana con reja, puerta con cortina; arriba
  ladrillo rojo con un balcón de obra volado y barandilla de hierro, persianas blancas, toldo verde recogido, losa de
  cubierta volada.
- **Farmacia**: edificio nuevo de tres plantas en revoco crema. Mitad norte, a haces de la calle: ventanales de
  escalera, portón de cuarterones con clavos, dos ventanitas y dos balconeras con celosía por planta. Mitad sur: el
  bajo chapado en blanco (ventana del dispensador, escaparate, entrada retranqueada con puertas de cristal y marco
  azul, escaparate grande), y las dos plantas de arriba voladas 0,6 m con una balconera y las terrazas tras celosía
  marrón; la cruz verde en banderola. Rótulo: solo «FARMACIA».
- **Droguería**: bajo de sillares fingidos blancos con puerta de madera y reja de tijera, rótulos amarillos
  («Droguería» a la calle Real, «Perfumería» a Colón, y el vertical de la esquina), ventanas recercadas en terracota
  con persiana de cañizo y balconcillo, cornisa con dentículos y balaustrada; en Colón, zócalo terracota que sube con
  la calle, ventana de pavés y una puerta.

## En el juego
- Los rótulos dicen qué se vende, nunca el nombre real; ninguna casa lleva su número.
- No se entra en ninguna. Sin personajes.
- Prueba: `python tools/run_tests.py farmacia --window` (10 fotos y 3 comprobaciones).

## Lo que es aproximado
- **La esquina**: en el juego la calle de Colón pasa unos 3 m más al norte que la real, y la manzana está recortada.
  Por eso la droguería empieza donde en la realidad está la casa del 24 (que no se pone) y su costado a Colón mide
  12 m en vez de 18: tres ventanas arriba en vez de cinco.
- **La calle de Colón sube** mucho más que la real (el relieve del juego está exagerado): el zócalo y la puerta de ese
  lado suben con ella.
- **La farmacia**: las posiciones de la entrada y de los escaparates del centro bailan ±0,7 m (las dos cámaras desde
  las que se ven no casan); las alturas de planta, ±0,15 m. Las terrazas tienen 1,4 m de fondo, a ojo. La cubierta es
  plana, sin lo que haya arriba.
- **Lo que no se ve desde la calle** (traseras, patios) son los contornos de Catastro levantados lisos.
- **La casa de ladrillo**: la azotea de detrás no se ha modelado; el zócalo de piedra es algo más alto que el real.
