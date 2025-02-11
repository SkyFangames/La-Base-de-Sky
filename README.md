# BASE DE SKY

**Creada por [Skyflyer](https://twitter.com/Sky_fangames) y [DPertierra](https://github.com/dpertierra)**

## Base de Pokémon Essentials en Español creada sobre la versión 21.1

### [DESCARGAR BASE](https://skyfangames.blogspot.com/2024/01/base-de-sky.html)

### AÑADIDOS V 1.1.2

- Agrega funcionalidad de multipartidas.
- Refactoriza el BetterMoveRelearner.
- Agrega opcion de LoseText_F en el PBS de los trainers, este texto será usado cuando un trainer pierda cuando el jugador esté con el personajes femenino.
- La incubadora ahora permite elegir los huevos desde el PC
- Agrega opción para asignarle un estado a N Pokémon del equipo, puede ser en orden o aleatorio, se puede poner una probabilidad y además tiene en cuenta inmunidades por tipos o habilidades.

### AÑADIDOS V 1.1.1

- Múltiples correcciones de bugs
- Agrega una opcion para que las MOs sean olvidables
- Opcion para activar el expshare por evento y no al inicio de la partida
- Actualización del MK
- Corrección de errores en joiplay
- Cambios de textos para que se adapten mejor a la UI
- Mejoras en el scripts_combine y scripts_extract
- La tecla SPECIAL (D) también cerrará el menu de objetos registrados basicamente conviertiendo la D en un toggle de este menú
                                               

### AÑADIDOS V 1.1.0

- Modificaciones de la mochila. Ahora incluye la posibilidad de ordenar los objetos, buscar uno escribiendo su nombre e incluso señalar objetos favoritos.
- Más validaciones para las animaciones de ataques.
- Se ha rehecho completamente el sistema de Regalo Misterioso. Ahora permite crear regalos por internet con contraseña, aparte de muchas mejoras.
- Mejoras en el movimiento del jugador, ahora se mueve con solo darle tap a las teclas.
- Correcciones en el precio de venta de algunos objetos, de acorde a las nuevas generaciones.
- Mejoras en el PluginManager para que detecte cuando se agregan o eliminan carpetas.
- Corrección de stats de mega Scizor.
- Agregado que si se libera a un Pokémon con un objeto equipado, el objeto se guarda en la mochila.
- Cambios en el NPC configurador del random del mapa de Scripts.
- Agrega opción de usar las MOs sin aprenderlas.
- Agrega posibilidad de flag Kicking en el PBS de moves.txt y metodo kickingMove? para saber si es un movimiento de patadas.
- Cambia el precio de venta por defecto de 1/2 a 1/4 del precio de compra, de acuerdo a los cambios en BDSP y SV.
- Agrega opción en el NameBox para que el color del cuadro sea independiente del del text box y tambien definir distintos Skins para distintos NPCs.
- Corrección en el tiempo mostrado al guardar partida, independientemente del turbo.
- Correcciones en el Buscasalvajes.
- El Buscasalvajes ahora está ordenado por probabilidad de aparición
- El buscasalvajes ahora mostrara la silueta del Pokémon en negro para Pokémon no vistos, el icono en escala de grises para Pokémon vistos pero no capturados y el icono a color para los Pokémon capturados.
- Opción para que los objetos consumibles, como bayas, gemas, banda focus, etc. se restauren luego del combate, esto viene por defecto desactivado, para activarlo hay que cambiar la constante `RESTORE_HELD_ITEMS_AFTER_BATTLE` a true
- Actualiza Ladrón a los cambios de 9na.
- Opción para liberar todos los Pokémon de una caja de una sola vez, sus objetos se guardan en la mochila.
- Correcciones al recibir Huevos ahora siempre ofrecerá meterlos a la incubadora si la tienes y ésta tiene espacio disponible.
- Correcciones para la congelación de Hisui.
- Se incluye la Ruby Standard Library (RSL) esto es un compilado de librerias de código que podrán importar en sus scripts para facilitarse distintas cosas, por ejemplo puede importar la libreria de JSON para manejar este tipo de archivos con mayor facilidad. Pueden encontrar mas información [aquí](https://ruby-doc.org/3.3.0/standard_library_rdoc.html)
- Corrección de crash al agregar huevos teniendo la incubadora registrada.
- Agrega opción de desactivar el vsync al menú de opciones.
- Corrección del movimiento Throat Chop
- Cambios menores de traducciones.
- Pequeños arreglos menores.

### AÑADIDOS V 1.0.8

- Añadido buscador instantáneo en la Pokédex al pulsar la tecla D.
- Arreglado el movimiento por los ataques de la Dex ampliada.
- Arreglado error que saltaba en la Incubadora.
- Añadidas validaciones para evitar errores si no se usan bases en combate.
- Actualización de plugins de la base y añadido uno que se borró en la anterior versión por error.
- Actualización de los iconos de todos los Pokémon de Paldea.
- Arreglado bug con los árboles de bayas, que no desaparecían al recogerlas.
- Pequeños arreglos menores.


### AÑADIDOS V 1.0.7

- Mejoras en el script de la dex avanzada, ahora permite moverse en el listado de movimientos manteniendo pulsada las flechas y con la A y la D para moverse de 4 en 4.
- Corrección en el script del Pokevial, no agregaba nuevas cargas cuando el vial aun contenia cargas.
- Arreglados los métodos de evolucion para Applin -> Dipplin y Duraludon -> Archaludon
- Corregido error con las bayas, que no mostraban gráfico al plantarlas.
- Se agregó una opción para desactivar el nuevo repartir experiencia.
- Corrección de los movimientos Tajo Metralla y Hachazo Pétreo
- Correcciones en el script del turbo.
- Añadida la opción de tener mapas sin reflejo, pudiendo definirlos en Settings.
- Actualizada la Pokédex, ahora con opción de buscar con la D un Pokémon rápidamente.
- Arreglado error de la Pokédex, que no mostraba sprites animados dentro de ella (solo si tienes el script).
- Añadidas todas las formas de Pikachu coqueta y de Pikachu con la gorra de Ash.
- Arreglados errores en las formas de Vivillon, que no terminaban de cuadrar.
- Actualización de sprites de huellas de Pokémon para la Pokédex.
- Actualización de varios scripts de la base a la última versión.
- Eliminados archivos innecesarios de la base.
- Correcciones de algunos sprites de OWs.
- Pequeños arreglos menores.


### AÑADIDOS V 1.0.6

- Añadidas las evoluciones faltantes de Pokémon de Hisui y de Paldea en el PBS de Pokémon.
- Corregido error en los sprites de Basculegion hembra.
- Correcciones a los íconos de status en la party y en combate.
- Agrega métodos de evolución para los Pokémon que deben evolucionar a una forma random (Dunsparce y Tandemaus).
- Actualizada la Pokédex avanzada con varias mejoras.
- Añadida compatibilidad de la opción de mostrar el gráfico de un Pokémon en un recuadro con los sprites animados.
- Añadido NPC en Pueblo Inicio que sirve de ejemplo sobre cómo mostrar el grito de un Pokémon.
- Cambia el método de entrada por defecto al teclado en lugar del cursor.
- Solo muestra el boton de "Buscar actualizaciones" en la pantalla de carga si el Plugin "Pokemon Essentials Game Updater" está instalado.
- Arreglados los colores del texto cuando te derrotan y te mandan al centro Pokémon.
- Cambio a la Super Cápsula, ahora avisa que el Pokémon ya tiene esa habilidad y no consume el objeto.
- Se corrigió un error en el script de la Mochila que mostraba el icono de congelado en lugar de debilitado.
- Se corrigió un error en el script del recordador de movimientos que generaba crasheos si el pokemon no tenia movimientos para recordar.
- Correcciones menores de textos.


### AÑADIDOS V 1.0.5
- Actualizados los OWs de Archaludon y las tres líneas evolutivas de starters de Galar.
- Actualización del Plugin de Hotfixex a la versión 1.0.9.
- Corrección de errores en el Panel de experiencia múltiple.
- Actualización del script de Hotfixes.
- Actualizado el archivo de town map generator.
- Corrección de textos y faltas de ortografía.
- Pequeños arreglos menores.


### AÑADIDOS V 1.0.4
- Añadidas las Pokédex Regionales de todas las generaciones (por defecto solo salían la de Kanto y Johto).
- Añadidos NPCs en la planta baja de la casa del prota que muestan funciones de texto extra.
- Corregido un bug al ver los datos de un Huevo.
- Añadido script para la Incubadora, con NPC de ejemplo al lado de la Guardería.
- Añadido script para hacer mejores movimientos random de NPCs con eventos de ejemplo en "Ruta 4 Carril Bici" (mapa 40).
- Modificado el combate contra Brock para ver cómo poner una forma regional a un Entrenador.
- Añadido en Pueblo Inicio un NPC que te explica cómo activar el "debug passability".
- Añadida pantalla de título a la base para hacerla más customizada.
- Añadidos nuevos NPCs en los mapas de la base con ejemplo de uso de más utilidades.
- Corrección de textos en inglés.
- Pequeños arreglos menores.


### AÑADIDOS V 1.0.3

- Corregido error con las mentas que no mostraba el texto y no te dejaba ni confirmar ni cancelar el uso.
- Corregidos los íconos de debilitados y Pokérus en la party, mochila y datos.
- Corregido bug al coger bayas de un árbol de bayas.
- Mejoras para el NameBox aportadas por dracrixco (mostrar el nombre de quien habla).
- Se agrega el shout (mensajes en modo grito) adaptado a la versión 21.1 (por dracrixco).
- Añadidos iconos faltantes de Pokémon de Paldea variocolor.
- Pequeños arreglos menores.


### AÑADIDOS V 1.0.2

- Añadido el OW de Archaludon.
- Arreglo del script de cámara (en settings no estaba bien definido el switch que usa).
- Mapa de Intro colocado el primero, que se había metido dentro del mapa de la Ruta 1.
- Pequeños arreglos menores.


### AÑADIDOS V 1.0.1

- Añadido NPC que muestra un ejemplo del intercambio desde el PC (en Condominio Lugano).
- Añadidos créditos de los iconos de Paldea, que se habían traspapelado.
- Correcciones para incluir el modo random como Plugin.
- Se corregió que al presionar F3 no se abria la pantalla del Easy Debug.
- Se agregó un NPC de configuración del random en el mapa de Plugins.
- Arreglado el NPC que te da la Bicicleta.
- Mejoras del map exporter, se guardan en una carpeta aparte y no sobreescribe archivos.
- Correcciones a la congelacion de hisui, que crasheaba el juego. Se ha puesto que por defecto no esté activa (configurable en settings).
- Modificación del switch del Fancy Camera por otro, por comodidad.
- Añadido en la carpeta del proyecto un acceso directo a la carpeta donde se guarda la partida y las capturas de pantalla.
- Añadidos algunos sprites de OWs que faltaban.
- Añadidos eventos en el Mapa de Scripts para dar soporte a futuros scripts.
- Corrección de la habilidad de Minior.
- Añadidos iconos Shiny de Pokémon de Paldea (aún faltan la mitad).
- Actualización en los botones de correr y abrir el menú.
- Corrección en el MultiExp Panel.
- Corrección de traducciones.
- Pequeños arreglos menores.


### AÑADIDOS V 1.0

- Pokedex Avanzada [Ver detalles](https://reliccastle.com/resources/1380/)
- Debug Passability, para ver la pasabilidad de los tiles (adaptado a esta versión) [Ver original](https://www.pokecommunity.com/threads/debug-passibility-script-find-mapping-mistakes-yourself.352886/)
- Easy Debug Terminal con F3 [Ver detalles](https://reliccastle.com/resources/1094/)
- Animaciones de ataques actualizadas (Ver. 20.04.2022) [Ver detalles](https://www.pokecommunity.com/threads/gen-8-move-animation-project-last-update-2022-04-20.446303/)
- Enhanced Pokémon UI [Ver detalles](https://reliccastle.com/resources/1387/)
- Cápsula para cambiar de habilidad [Ver detalles](https://reliccastle.com/resources/1137/)
- Debug List Search [Ver detalles](https://reliccastle.com/resources/1460/)
- Mejoras del Sistema de Almacenamiento [Ver detalles](https://reliccastle.com/resources/1310/)
- Mostrar Pokémon en cuadro de información [Ver detalles](https://reliccastle.com/resources/1436/)
- Fondos para el pokegear [Ver detalles](https://reliccastle.com/resources/1321/)
- Sprites de Pokémon de 5 a 8 gen actualizados [Ver detalles](https://reliccastle.com/resources/1469/)
- Multiple exp panel [Ver detalles](https://reliccastle.com/resources/1327/)
- Flechas en las puertas al salir de edificios (adaptado a esta versión) [Ver detalles] (https://newpokeliberty.blogspot.com/2017/05/autor-original-xavierux-hoy-os-traigo.html)
- Ver los Pokémon salvajes de la ruta (adaptado a esta versión) [Ver detalles] https://reliccastle.com/resources/658/
- Nuevas funciones para mover la cámara de forma más fluida [Ver detalles] (https://reliccastle.com/resources/1466/)
- Opción de exportar los mapas del juego como png [Ver detalles] (https://reliccastle.com/resources/184/)
- Rep exp desde el equipo adaptado a V21 [Ver detalles] https://newpokeliberty.blogspot.com/2020/06/repartir-experiencia-55.html
- Pokévial [Ver detalles] https://reliccastle.com/resources/405/
- Ataques, habilidades e Items de 9ª Gen [Ver detalles] https://reliccastle.com/resources/1101/
- Intercambiar Pokémon desde el PC [Ver detalles] https://reliccastle.com/resources/1417/
- Reordenador del tileset [Ver detalles] https://reliccastle.com/resources/794/
- Ver los IVs y EVs [Ver detalles] https://reliccastle.com/resources/1328/
- Acceder a las estadísticas del Pokémon desde la pantalla de olvidar un movimiento, presionando la Z.
- Mejor recordador de movimientos, muestra MTs y no se cierra luego de enseñar cada movimiento
- Opción de no mostrar los pies del jugador al pasar de un tile de hierba a otro.
- Mostrar pasos para abrir huevo en datos del huevo.
- Repelente Infinito como objeto clave.
- Acceso directo a la pokédex desde el menu del pokemon y desde el PC.
- Turbo con 3 velocidades, tanto para combates como para el juego en general, arriba a la izquierda muestra la velocidad al cambiarla.
