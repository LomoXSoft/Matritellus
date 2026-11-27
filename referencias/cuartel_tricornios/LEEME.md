# Referencia: el cuartel de la Guardia Civil de la avenida de la Constitución (el de los Tricornios)

Pedido por Luis el 16-11-2026: «Vamos con el cuartel de la guardia civil (tricornios). En Av. de la Constitución, 116,
45710 Madridejos, Toledo» (con una captura de Google Maps de su entrada). Primera versión enseñada el mismo día (hojas
en `guion/fotos/cuartel_tricornios/`). Su veredicto: «Visto bueno a todo. Pensaba que ya lo había dado» (16/11).

Sobre esa primera versión, con una foto de un coche oficial: «Podríamos invertir el logo que has hecho de los
tricornios en la fachada (cambiar negro por dorado y viceversa) y usarlo como su logo. Así lo podríamos poner en el
frontal y en los laterales del coche, además de una franja con la bandera de España, como los oficiales». Hecho y
enseñado (hoja `04_logo_y_coche.jpg`); visto bueno con todo lo demás («Visto bueno a todo. Pensaba que ya lo había dado» (16/11)).

El modelo es `godot/scripts/cuartel.gd` (sobre `obra.gd`). Herramientas: `tools/cuartel/`.

## Dónde
La parcela del Catastro `4397001VJ5649N` (1950, tres plantas, dos partes), en la esquina de la avenida de la
Constitución (al oeste: la fachada principal) con la calle de Víctor Pradera (al norte); al sur, un patio hasta la
calle Nueva; al este, vecinos. No estaba en `casas_calles.gd`: era un bloque genérico.

## Marco
Origen en el extremo norte de la fachada principal (la esquina de la avenida con Víctor Pradera), mapa (46.84,
-534.47); `x` a lo largo de esa fachada hacia el sur, u = (0.165, 0.986); `z` sale de ella hacia la avenida (oeste);
`y` = 0 el suelo delante de la escalinata.

## Fuentes
- **Street View**, noviembre de 2024 (con 2019 y 2013 de un par de sitios): 42 vistas en `tools/cuartel/capturas.py`,
  desde la avenida, su vía de servicio, Víctor Pradera y la calle Nueva. Todas las cámaras:
  `python tools/molino/panos.py cerca l497FompEAUE4gSNDdP4-g 70 -520 62`. No he buscado fotos esféricas de dentro
  (es un cuartel: el patio solo se ve por la verja y por encima del murete).
- **La captura de Luis** de la entrada: de ella salen la puerta, la placa, el rótulo y la placa del ministerio.
- **Catastro** (`tools/casas/4397001VJ5649N/`) y la **foto aérea del IGN** (`tools/ign/cuartel.jpg`;
  `python tools/cuartel/planta.py`).

## Lo que hay
- **Cuatro bloques** blancos de tres plantas, lisos, con una cornisa moldurada y cubierta plana, alrededor de un patio
  en cruz; un cuerpo estrecho los une por el oeste (ahí está la entrada) y otro por el este.
- **Avenida**: dos cuerpos de cuatro ventanas por planta (las de abajo, con reja verde y aparatos de aire entre ellas)
  y, entre los dos, el retranqueo de la entrada: puertas de cristal en carpintería blanca sobre cinco peldaños, la
  placa negra, el rótulo del lema con las tres franjas de la bandera, un farol. Una rampa con barandilla negra baja
  pegada al cuerpo sur. La bandera, en su mástil sobre un pie de mampostería. Delante: plazas en batería pintadas
  (cuatro al norte, cinco al sur), el cajetín amarillo ante la escalinata, dos árboles recortados junto a la rampa,
  un arbolillo y el poste de las cámaras en la esquina.
- **Víctor Pradera**: fachadas aún más lisas, con ventanas con reja, tendederos bajo algunas de arriba, cables, farolas
  de brazo; entre los dos bloques del norte, la verja de barrotes verdes del patio, cerrada.
- **Calle Nueva**: el patio de tierra con tres árboles grandes, tras un murete blanco con malla; su portón corredero
  (chapa verde oxidada); las dos puertas de garaje verdes del bloque sureste.

## En el juego
- **Rótulos** (decididos por mí y aprobados por Luis: «Vale»): el lema «TODO POR LA PATRIA» se queda; la placa negra
  dice «EL HONOR / ES LA PRINCIPAL DIVISA DEL TRICORNIO»; la placa del ministerio es nuestra (el logo de los
  Tricornios y «LOS TRICORNIOS»), sin ministerio ni emblema real; la bandera, rojigualda sin escudo, como la del
  ayuntamiento del juego.
- **El logo de los Tricornios** (idea de Luis: el tricornio que dibujé para la placa, con los colores cambiados): una
  placa negra de borde dorado con el tricornio en dorado —el ala vuelta atrás, la copa baja, el borde—. Lo pinta
  `tools/cuartel/logo.py` en `godot/assets/tricornios/logo.png`, junto con la franja de bandera inclinada
  (`bandera.png` y su espejo `bandera_i.png`). Está en la placa de la fachada (material `"logo"`) y en sus coches.
- **Las marcas del coche** (`godot/scripts/tricornio_marcas.gd`, `dress(root, kind, size)`; lo llama `modelos.gd` al
  construir cualquier coche `tricornio`: el aparcado, los de una persecución, el robado): el logo en el capó y en
  cada puerta delantera, y la franja de bandera detrás en cada lateral. Son **calcomanías proyectadas** (`Decal`),
  así se adaptan al capó y a las puertas de cualquiera de los tres juegos de modelos. Para que no manchen nada más,
  la carrocería de esos coches lleva además la capa de render 15 y las calcomanías solo miran esa capa. Sin
  «GUARDIA CIVIL» ni emblema real: el modelo traía sus pegatinas y siguen ocultas.
- **El coche patrulla** (Luis: «deja siempre un coche aparcado de los tricornios en la puerta, sin ocupantes»; robarlo
  sigue la regla que ya había —empieza la persecución—, y «al día siguiente vuelve a aparecer uno»): lo lleva Sistemas
  en `godot/scripts/cuartel_coche.gd` (prueba `tricornio`). `cuartel.gd` solo dice dónde: `patrol` = `{at, to}`, en
  el cajetín amarillo. Además expone `door`, `gate` y `bays`.
- No se entra; el patio y el corral quedan cerrados. Sin personajes.
- Pruebas: `python tools/run_tests.py cuartel` (14 fotos y 4 comprobaciones); además `relief` y `sentido` (la avenida
  es de sentido único). Por las marcas del coche: `tricornio` y `limite` (de Sistemas), y las fotos de
  `python tools/run_tests.py "$(python tools/cuartel/vistas.py coche)"`.

## El rehorneado
Como el colegio: `tools/bake_godot.py` lleva un bloque `CUARTEL` (la parcela no se levanta, no hay árboles del mapa en
ella ni delante ni en el patio, y `cuartel_built` cuenta para el ancho de las calles). Horneado el 16-11-2026. Solo
desapareció el bloque genérico (48 muros, 2 tejados planos); relieve, nudos, calles, árboles y casas, iguales.

## Lo que es aproximado
- **El Catastro pone los huecos entre bloques unos 2 m más anchos de lo que son**: el retranqueo de la entrada mide
  3,9 m (no 5,74) y el hueco de la verja unos 6 m (no 7,6). Hecho como en las fotos.
- **La fachada de la avenida**: medida con la cámara ajustada a sus esquinas; ±0,3 m. Las ventanas se han puesto
  simétricas respecto al retranqueo (así se ven), a 2,0 + k × 2,42 m de él.
- **Las de Víctor Pradera**: ±0,7 m (calle estrecha; la cámara estaba a 3,8 m de la fachada, no a los 4,8 de Google).
- **Las del sur y las del patio**: a ojo; desde la calle apenas se ven.
- **El cajetín amarillo** tiene en el juego menos de 5 m de fondo (la calzada de la avenida queda más cerca que en la
  realidad): el coche patrulla va paralelo a la fachada, no de morro.
- **El desnivel**: casi llano; los muros bajan hasta el terreno.
- La escalinata y la rampa son sólidas: no se sube por ellas.

## 27/11/2026: la pared del enlace de atrás

La campaña anti-solapes (0.2.6) había dejado sin pared este el bloque de enlace de atrás (`ELINK`, lado 1 en
`"skip"`). Luis: «Hemos perdido una pared aquí?». Vuelve a ser `plain`. `zfight solo=cuartel.gd`: 3,522 m² exactos,
igual que antes.
