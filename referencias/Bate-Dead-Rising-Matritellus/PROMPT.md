# Prompt para Godot · Riña del jamón

Copia el bloque en una sesión con el repositorio activo de Matritellus y la carpeta del dossier descomprimida.

```text
Implementa en Matritellus una mejora jugable de la riña del jamón de La Cocina de Henry. Usa el README del dossier Bate-Dead-Rising-Matritellus y sus cuatro láminas. La referencia es el combate con objetos del primer Dead Rising para Xbox 360, especialmente el ritmo entre pulsación, barrido, reacción y recuperación. Emplea los personajes, escenarios, animaciones, HUD y sonidos propios de Matritellus.

1. Localiza la copia activa del juego y su versión de Godot. Lee las instrucciones del proyecto y la sección de la riña en guion/misiones_y_puntos_civicos.md. Inspecciona godot/scripts/motin.gd, game.gd, chara.gd, touch.gd, controls.gd, loc.gd y selftest.gd. Reutiliza el combate de Henry, su cámara sobre el hombro, la acción punch, las reacciones de los participantes y el marcador. Confirma en la copia activa los tiempos y las rutas de entrada que cita el dossier.

2. Implementa dos gestos sobre Golpe. Inicia la preparación visual al pulsar. Si se suelta antes de 0,25 s, confirma el golpe básico con contacto a 0,40 s y fin a 0,70 s desde la pulsación inicial. Si el botón sigue abajo al alcanzar 0,25 s, mantén una pose legible y una indicación de carga lista. Al soltar, ejecuta el cargado con contacto 0,22 s después y recuperación de 0,50 s tras ese contacto. Son valores de arranque ajustables. La duración de la carga cuenta en tiempo de juego. Gestiona los flancos reales de entrada y una única resolución por ataque. Comprueba clic, X del mando y el botón táctil Golpe, además de la liberación al salir de la aplicación o cambiar de dispositivo.

3. Calcula los participantes alcanzados en el instante de contacto usando el frente y la posición del avatar. Reaprovecha el filtro de motin.gd, incluida su excepción de proximidad, y aplica una vez _hurt() por participante. El normal alcanza hasta dos y el cargado hasta tres, priorizando los más próximos. Mantén 25 de daño por contacto y la puntuación existente por impacto y derribo. Distingue el aire, la carga y el contacto con sonido y pose. Sincroniza el cruce visible del bate con el paso que resuelve el impacto. Una caída o un fin de ronda previo al contacto cancelan el ataque. Si coinciden reloj agotado y contacto, resuelve primero el reloj. Evita que un temporizador anterior afecte a la revancha. Respeta las reglas de pausa, entrada y retorno a exploración.

4. Revisa el encuadre durante una partida con varios vecinos y junto a una fachada. Deben leerse el avatar, el barrido, el objetivo que reacciona y parte del espacio circundante. Ajusta el comportamiento de cámara solo donde la prueba revele un problema. Conserva la puesta en escena de Henry, sus 60 segundos, el encargo de Josefa, los jueves, las recompensas diarias, el récord y las repeticiones desde la Agenda. Comprueba el bate de exploración por separado porque comparte animación con la riña. Integra las ayudas en español e inglés con las convenciones existentes.

5. Amplía las pruebas del motín para toque, carga, borde de 0,25 s, golpes al aire, múltiples participantes, interrupción y dos partidas seguidas. Comprueba que el táctil no duplica la orden y que la puntuación sigue las reglas. Ejecuta el filtro --selftest --motin con el comando del repositorio y las comprobaciones de regresión afectadas. Verifica con imagen el contacto, el giro de cámara y la densidad del grupo. Documenta qué dispositivos pudiste probar, los resultados y cualquier comprobación pendiente.

Trabaja hasta tener la mejora implementada y verificada. Al terminar, indica dónde jugarla, los controles finales y los valores que ajustaste durante las pruebas.
```
