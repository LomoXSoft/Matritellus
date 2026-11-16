# Referencia: la esquina del banco y la copistería («Banco Cantabria» y «Copistería Sancho Panza»)

Pedido por Luis el 17-11-2026: «Te puedes poner con la copistería xijote (que llamaremos copistería Sancho panza) y el
banco Santander (que llamaremos banco Cantabria). Ambos comparten C. Teniente Infante, 8 ... partiendo la planta baja,
debajo de unos pisos». Y con su foto marcada: 1 el banco, 2 la copistería (todo el tramo de ladrillo), 3 el electricista.
Pendiente de su veredicto.

El modelo es `godot/scripts/bancosancho.gd` (sobre `obra.gd`), en `world.bancosancho`. Es la casa `sfran_b004` de Texturas
(Catastro 4190004VJ5649S), que casas.gd deja de dibujar («obra»). Herramientas: `tools/bancosancho/`. Dibujos, todos
nuestros: `godot/assets/bancosancho/`, hechos con `tools/bancosancho/dibujos.py`.

## Fuentes
- **Street View** de noviembre de 2024, por las dos calles (`tools/bancosancho/capturas.py`). Las fotos son de Google y no se
  guardan aquí.
- La foto de Luis con los tres locales marcados.
- **Catastro**: la planta, los vuelos de 1 m de las plantas de arriba sobre las dos aceras, y la foto de 2018.

## Medidas (de la esquina hacia el oeste, por el Teniente Infante; frente de 31,1 m)
Con rumbos desde las cámaras de enfrente (las dos que lo ven más de frente para cada hueco):
- El banco: granito de 0 a 15,6 m, banda roja hasta 14,8 m con su caja al final, escaparates de 1,9 a 3,7 m y de 10,2 a
  12,2 m, puerta de 6,4 a 8,7 m y el cajero junto a la esquina.
- La copistería, ladrillo visto de 15,6 a 24 m. La puerta de madera de dos hojas de las viviendas, de 16,3 a 18,3 m; la
  puerta de cristal, de 19,4 a 20,8 m; el escaparate con el cartel, de 21,5 a 23,6 m. Cada hueco bajo un arco rebajado.
- El electricista, de 24 m al final: ventana con su cartel azul, y escaparate grande y puerta bajo el cartel verde.
- Por San Francisco: el banco dobla 5 m; luego, en revoco blanco, el otro portal de las viviendas (ancho cerco gris,
  cancela de hierro), la puerta de malla con una caja blanca encima y los dos aparatos de aire a su lado, uno sobre otro,
  y la ventana con reja. (Texturas lo había hecho todo de granito por la foto del Catastro de 2018; el Street View de
  2024 lo da blanco, y Texturas está de acuerdo.)
- Arriba, dos plantas que vuelan 0,97 m, con las ventanas de marco blanco y persiana, balcones de hierro y el balcón
  curvo que dobla la esquina en cada planta. Alturas: el vuelo a 3,25 m, las plantas a 3,55 y 6,45 m, cornisa a 9,3 m.

## Nombres y dibujos
- El banco: «Banco Cantabria · Agentes» en blanco sobre rojo. El emblema es nuestro: un aro con tres olas.
- La copistería: el panel del escaparate dice «Copistería Sancho Panza», «papelería · diseño gráfico» y «fotocopias ·
  encuadernaciones», con un burro de dibujo propio.
- El electricista: un cartel con lo que hace, sin nombre, y otro verde que dice «ENERGÍA». El teléfono va garabateado.

## Horarios (Luis, 17-11: «Esos horarios están bien»)
- Banco: de lunes a viernes, de 8:30 a 14:30 (el horario general de oficina del banco real).
- Copistería: de lunes a viernes, de 9:30 a 14:00 y de 17:00 a 20:30; los sábados, de 10:00 a 13:30.
- Electricista: de lunes a viernes, de 9:00 a 14:00 y de 17:00 a 20:00.

Abierto, la sala de detrás del cristal está iluminada (el banco con sus mesas y su mostrador, la copistería con sus
estanterías, la fotocopiadora y el mostrador, el electricista con su mostrador y sus cajas) y la copistería cuelga
«ABIERTO». Cerrado, todo a oscuras y «CERRADO». El cajero está siempre encendido.

## Se puede entrar en la copistería, y la chica está dentro
Luis, 17-11: «No respetes esa puerta. Haz la copistería una tienda que se pueda visitar y metes a la chica dentro». La
puerta de cristal tiene su flecha verde (`entradas.gd`), solo mientras está abierta. El interior es
`copisteria_dentro.gd`, un set aparte en (1450, 1800):
- el mostrador verde con su pantalla, la caja y los carteles de la misión encima;
- dos fotocopiadoras y el plóter con una lona saliendo;
- la estantería de papelería y la mesa de cortar y encuadernar;
- al fondo, las muestras de lonas y vinilos y el panel con el burro.

La chica de los carteles de la misión del Recress se pone detrás del mostrador (`keeper_spot`). El objetivo «Recoge los
carteles» lleva a la puerta de la tienda. Eso toca `recress.gd`, de Sistemas.

Luis, 17-11: «La copistería estará abierta durante la misión. Usaremos los horarios que has puesto ya». Mientras la
misión está en la etapa de recoger los carteles, abre a cualquier hora (`for_the_posters`). El resto del tiempo sigue
sus horarios. Si cierra contigo dentro, la salida sigue ahí.

## Colores (comparados con Street View)
- El revoco de arriba, crema claro: tiene que leerse claro también a la sombra del Teniente Infante.
- El granito del banco, gris claro.
- El ladrillo de la copistería, pálido y asalmonado, no naranja (el tinte sube el azul para quitarle el naranja). Los
  arcos rebajados, del mismo ladrillo y apenas más oscuros.
- La sala del banco empieza a 1,8 m de la esquina: San Francisco va en diagonal, y desde 0,4 m asomaba por su fachada.

## Pruebas
`python tools/run_tests.py bancosancho`: fotos (por la mañana, por la tarde y de noche, el interior, la flecha) y
comprobaciones: está hecha sobre su casa del mapa, que casas.gd ya no dibuja; sus frentes paran; da al Teniente Infante;
cada local cumple su horario; se entra en la copistería por su flecha y se sale. `recress` (y `recress shots` para las
fotos de la escena) y `entradas` también pasan por ella.

Hojas para el usuario: `python tools/bancosancho/hojas.py CARPETA_SV`, después de
`tools/run_tests.py "$(python tools/bancosancho/vistas.py CARPETA_SV d_frente c_frente c_ladrillo f_lejos a_lejos)"`.
Salen en `guion/fotos/bancosancho/`. Las vistas con gente cerca (e_esquina, s1_lado) no entran en las hojas.
