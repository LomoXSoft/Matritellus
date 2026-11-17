# Referencia: Correa, la oficina de correos de la calle Zaragoza

Pedido por Luis el 17-11-2026: «Vamos con la oficina de correos». Y el nombre: «En vez de Correos la llamaremos Correa
(Servicio Postal Correa). El rótulo debería ser Correa, no Correos». Veredicto (17-11, con abierto/cerrado e interior): «Está increíble, visto bueno».

El modelo es `godot/scripts/correos.gd` (sobre `obra.gd`), en `world.correos`, en el marco del mapa (x este, z sur; y = 0
la calle ante su puerta). Está en la calle Zaragoza 1, junto a la Plaza del Ayuntamiento, en la parcela 4193608VJ5649S del
Catastro: un edificio público de dos plantas. Antes era la casa `zaragoza_b608` de Texturas, que ahora es `["obra"]`; al
saltar su RC, el horneado la quita. Herramientas en `tools/correos/` y dibujos propios en `godot/assets/correos/`, hechos
con `tools/correos/dibujos.py`.

## Fuentes
- **Street View** de noviembre de 2024 (y de 2013) por la calle Zaragoza (`tools/correos/capturas.py`; las fotos son de
  Google y no se guardan aquí), enderezadas sobre la fachada con `tools/merkocarry/alzado.py`.
- La **foto del Catastro** de su fachada y su planta (`tools/casas/4193608VJ5649S/`).
- **Google Maps**: el horario, de lunes a viernes de 8:30 a 14:30, cerrado los fines de semana. Luego Luis, para la mecánica de las cartas (la hace Sistemas, cartas.gd): de lunes a viernes de 8:00 a 20:00, con dos funcionarios, Diurno Correa de 8 a 14 y Nocturno Correa de 14 a 20. La placa ya lo dice, la prueba lee el horario de correos.gd y correos_dentro.gd da las tres ventanillas (windows).

## Medidas (fachada de 18,72 m a la calle Zaragoza, desde la esquina sur, junto al Ayuntamiento)
- Planta baja, de ladrillo visto rojo, hasta 3,95 m:
  - el gran arco del portón de madera oscura con clavos (1,1 a 3,9 m; arranque a 2,62 m, flecha de 0,75 m);
  - el contador (4,25 m) y tres ventanas de marco marrón (5,0 a 9,1 m, de 1,6 a 3,3 m de alto);
  - la entrada, metida 3 m bajo otro arco rebajado (9,6 a 12,2 m), con la rampa, la barandilla de acero, la puerta de
    cristal al fondo y la placa del horario;
  - la ventana de la esquina norte entre dos pilastras de revoco crema (14,2 a 15,8 m), la alarma (17,2 m) y la bajante en
    la esquina.
- Los rótulos amarillos con la base y los extremos azules, abombados: uno corto sobre el arco y otro largo de 4,8 a 12,6 m.
- Planta alta: revoco crema entre fajas de ladrillo, ventanas con la persiana a medio bajar, la terraza metida sobre la
  entrada con su barandilla, la cornisa gris con el canalón a 7,2 m y el tejado de teja a cuatro aguas sobre la crujía de
  la calle.
- Como dos medidas de las cámaras de Google no cuadraban entre sí a lo largo de la calle, he ajustado la posición de la
  entrada para que, como en la foto desde el norte, queden metro y medio de ladrillo entre ella y la pilastra de la
  ventana de la esquina.

## Nombre y dibujos
- Los rótulos dicen «CORREA», con una corneta nuestra, sin corona, y no la de la empresa real. La placa del horario dice
  «Servicio Postal Correa».

## Abierto, cerrado e interior (Luis, 17-11: «añade abierto/cerrado (verja en la entrada, iluminación del cartel,...) e interiores»)
- Cerrada: una verja de barrotes cae desde su caja bajo el arco de la entrada y la cierra (y es sólida); a oscuras.
  Abierta: la verja recogida en la caja, la sala del fondo iluminada.
- Los rótulos son cajas de luz: se encienden al anochecer (de 18:30 a 0:30), abierta o cerrada, con sus colores.
- El interior es `godot/scripts/correos_dentro.gd`, un set aparte en (1300, -1850), a 312 m de cualquier calle: 9 x 12 m.
  Se entra por la flecha verde ante la entrada, solo mientras está abierta (`entradas.gd`, `shops()`). Dentro: las tres
  ventanillas tras el cristal con sus números y la pantalla de turnos, la paquetería con la báscula grande, la máquina de
  turnos, la fila de sillas, la pared de apartados, las cajas y sobres a la venta, el expositor de postales, el pupitre
  para escribir, el buzón amarillo, la placa del horario; tras el mostrador, el casillero de clasificar, los paquetes, las
  sacas y el rótulo. Sin nadie detrás (no hago personajes nuevos).

## Pruebas
`python tools/run_tests.py correos`: fotos de frente, desde la plaza, desde el norte, del portón, de la entrada, de los
rótulos, cerrada y desde el aire. Comprueba que está donde estaba la casa de Texturas, que su fachada para, que el mapa la
conoce, que no invade la calzada, que da a la calle Zaragoza y que cumple el horario; la verja, los rótulos de noche y
el interior (aparte, cerrado, en la lista de entradas, abierto con la oficina); entrar por la flecha y salir. Tras el
horneado pasa también `plaza`; tras tocar `entradas.gd`, `entradas`. Hojas para Luis: `python tools/correos/hojas.py CARPETA_SV`, en `guion/fotos/correos/`.
