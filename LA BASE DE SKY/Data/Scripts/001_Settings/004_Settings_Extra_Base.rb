#==============================================================================#
# AJUSTES DE LOS PLUGINS                                                      #
#                                                                              #
# Aquí encontrarás toda la configuración de los distintos Plugins que          #
# incorpora esta base.                                                         #
#==============================================================================#

module Settings
  
  ################################################################################
  #  CONFIGURACIÓN DEL DELUXE BATTLE SCRIPT
  ################################################################################
  # Almacena la ruta para los gráficos utilizados por este plugin.
  DELUXE_GRAPHICS_PATH = "Graphics/Plugins/Deluxe Battle Kit/"

  # Acorta los nombres largos de los movimientos en el menú de combate para que se
  # ajusten a la interfaz de batalla predeterminada.
  SHORTEN_MOVES = true

  # Activa o desactiva la animación de Mega Evolución utilizada por este plugin.
  SHOW_MEGA_ANIM = true

  # Activa o desactiva la animación de Reversión Primigenia utilizada por este plugin.
  SHOW_PRIMAL_ANIM = true

  # Activa el nuevo repartir experiencia que se puede activar para cada pokemon del equipo.
  USE_NEW_EXP_SHARE = true


  
################################################################################
#  CONFIGURACIÓN DEL ENHANCED BATTLE UI
################################################################################
  # Almacena la ruta para los gráficos utilizados por este plugin.
  BATTLE_UI_GRAPHICS_PATH = "Graphics/Plugins/Enhanced Battle UI/"
  
  # Cuando está activado, aparecerán botones para abrir los menús de interfaz 
  # de usuario al seleccionar comandos.
  SHOW_UI_PROMPTS = true
  
  # Cuando es falso, la pantalla no mostrará la efectividad del tipo de movimientos
  # contra especies nuevas que encuentres por primera vez.
  # Cuando es verdadero, siempre se mostrará la efectividad del tipo, incluso para
  # especies nuevas.
  SHOW_TYPE_EFFECTIVENESS_FOR_NEW_SPECIES = false



################################################################################
#  POKÉDEX AVANZADA
################################################################################
  # Ruta de gráficos para la página de datos de la Pokédex.
  #-----------------------------------------------------------------------------
  # Almacena la ruta para los gráficos utilizados por este plugin.
  POKEDEX_DATA_PAGE_GRAPHICS_PATH = "Graphics/Plugins/Pokedex Data Page/"
  
  # # Interruptor que activa la página de datos de la Pokédex.
  # Esto se ha eliminado, ya que no creo que alguien quiera desactivar la Pokédex
  # avanzada.
  # POKEDEX_DATA_PAGE_SWITCH = 60
  
  # Activa o desactiva la visualización de los nombres alternativos de los grupos
  # huevo.
  ALT_EGG_GROUP_NAMES = false

  # Número de pagina de la Dex Avanzada
  # Si agregan paginas nuevas a la pokédex en medio, cambiar esto
  ADVANCED_DEX_PAGE = 4


  
################################################################################
#  TURBO
################################################################################
# Habilitar o deshabilitar opciones del menú, habilitado por defecto.
  SPEED_OPTIONS = true
  
  
  
################################################################################
#  ENHANCED POKEMON UI
################################################################################
  # Ruta de gráficos
  # Almacena la ruta para los gráficos utilizados por este plugin.
  POKEMON_UI_GRAPHICS_PATH = "Graphics/Plugins/Enhanced Pokemon UI/"
  
  # Party Ball
  # Habilita la visualización de iconos de Poké Ball que coinciden con la Poké Ball
  # de cada Pokémon en el menú del equipo.
  SHOW_PARTY_BALL = true
  
  # Medidor de felicidad
  # Habilita la visualización de un medidor de felicidad en la pantalla de resumen
  # del Pokémon.
  SUMMARY_HAPPINESS_METER = true
  
  # Hoja brillante
  # Habilita la visualización de las Hojas Brillantes recopiladas por un Pokémon
  # en las pantallas de resumen/almacenamiento.
  SUMMARY_SHINY_LEAF = false
  STORAGE_SHINY_LEAF = false
  
  # Datos heredados
  # Habilita la opción de abrir el menú de Datos Heredados en el resumen.
  SUMMARY_LEGACY_DATA = true
  
  # Valoraciones de IV
  # Habilita la visualización de valoraciones para los IV de un Pokémon en las 
  # pantallas de resumen/almacenamiento.
  SUMMARY_IV_RATINGS = true
  STORAGE_IV_RATINGS = false
  IV_DISPLAY_STYLE   = 1  # 0 = Estrellas, 1 = Letras
  
  # Visualización mejorada de estadísticas
  # El número de interruptor utilizado para permitir al jugador acceder a la 
  # visualización mejorada de estadísticas. 
  DISPLAY_ENHANCED_STATS = false
  
  # Visualizacion de IVs y EVs
  SHOW_ADVANCED_STATS = true
  
  # Mostrar cuadro de descripción al obtener un objeto nuevo
  SHOW_ITEM_DESCRIPTIONS_ON_RECEIVE = true
  
  # Mostrar MTs y MOs en el recordador
  SHOW_MTS_MOS_IN_MOVE_RELEARNER = true
  
  # Cerrar el recordador luego de cada ataque
  CLOSE_MOVE_RELEARNER_AFTER_TEACHING_MOVE = false
end


# Poner a verdadero para poder usar la cámara elegante con las nuevas funciones.
# Es el número del Switch
CAMERA_FANCY = 59



#===============================================================================
# Pantalla de la Bolsa con Equipo interactivo: Ajustes
#===============================================================================
module BagScreenWiInParty
# Si deseas que tu pantalla de la Bolsa tenga un panorama desplazable (true o 
# false):
  PANORAMA = true
 
# Color de fondo de la interfaz:
 # 0 para solo naranja (estilo de generaciones más recientes);
 # 1 para un color diferente según el género del jugador (estilo BW);
 # 2 para un color diferente para cada bolsillo (estilo HGSS).
  BGSTYLE = 0

# Si deseas que aparezca un icono de Pokérus y/o un icono brillante, respectivamente
# (true o false):
  SHINYICON = true
  PKRSICON  = true
end



#===============================================================================
# OPCIONES ESPECIALES DEL ALMACENAMIENTO DE POKÉMON
#===============================================================================
STORAGE_ARROW_PATH = "Graphics/UI/Storage/"

# Si se pueden intercambiar rápidamente las cajas seleccionando "Intercambiar" desde
# el encabezado de la caja
CAN_SWAP_BOXES   = true

# Sie pueden seleccionar/mover varios Pokémon al mismo tiempo usando la mano verde
CAN_MULTI_SELECT = true

# Si se pueden liberar varios Pokémon presionando la tecla de acción mientras se tienen
# varios Pokémon agarrados
# Necesitas tener seleccionada la opción CAN_MULTI_SELECT
CAN_MASS_RELEASE = true

# Si se pueden "dejar" Pokémon en una caja
# Esto te permite almacenar rápidamente Pokémon en una caja haciendo clic en el botón
# de uso en el encabezado de la página mientras mueves un Pokémon agarrado
CAN_BOX_POUR     = true



################################################################################
#  CONFIGURACIÓN DE LOS SPRITES ANIMADOS
################################################################################
#===============================================================================
# * Constantes para sprites animados de Pokémon
# * Para cambiar la posición del sprites de espalda de Pokémon en la batalla, 
#   selecciona y presiona
# * CTRL + Shift + F en la siguiente línea de código:
# * sprite.y += (metrics[MetricBattlerPlayerY][species] || 0)*2
#===============================================================================
FRONTSPRITE_SCALE = 1 #2
BACKSPRITE_SCALE  = 1 #3


################################################################################
#  PANEL DE EXPERIENCIA MÚLTIPLE
################################################################################
# Mostrar un panel con todos los Pokémon que ganan experiencia tras el combate.

MOSTRAR_PANEL_REP_EXP = true


# Los colores del texto utilizados en el panel
PANEL_BASE_COLOUR   = Color.new(80, 80, 88)
PANEL_SHADOW_COLOUR = Color.new(160, 160, 168)

class Swdfm_Exp_Screen
  # El ancho en píxeles entre el lado izquierdo/derecho de la pantalla y el lado
  # izquierdo/derecho del panel
  BORDER_WIDTH      = 64
  # La altura en píxeles entre la parte superior/inferior de la pantalla y la 
  # parte superior/inferior del panel
  BORDER_HEIGHT     = 64
  # Color es el borde del panel
  PANEL_EDGE_COLOUR = Color.new(57, 69, 81)
  PANEL_EDGE_SIZE   = 8
  # Color principal del panel
  PANEL_FILL_COLOUR = Color.new(206, 206, 206)
  # Color es el borde de las barras de experiencia
  EXP_EDGE_COLOUR   = PANEL_EDGE_COLOUR
  # Color de relleno de la barra de experiencia (sin experiencia)
  EXP_FILL_COLOUR   = PANEL_FILL_COLOUR
  # Color es la experiencia en la barra de experiencia
  EXP_EXP_COLOUR    = Color.new(68, 223, 250)
  # La altura en píxeles de la barra de experiencia
  EXP_BAR_HEIGHT    = 24
  # (¡Bastante complicado!)
  # La mitad de la diferencia, en píxeles, entre 1/3 del ancho del panel y el 
  # ancho de una barra de experiencia
  # Básicamente, hazlo más pequeño para una barra de experiencia más ancha
  EXP_WIDTH_GAP     = 16
  # El tamaño, en píxeles, del borde de cada barra de experiencia
  EXP_BAR_EDGE_SIZE = 4
  # Tiempo más corto (En segundos, asumiendo 40fps) que tarda en animarse la 
  # barra de experiencia
  FASTEST_TIME      = 0.4
  # El tiempo más largo (En segundos, asumiendo 40fps) que tarda en  animarse
  # la barra de experiencia
  SLOWEST_TIME      = 2.3
  # Tiempo (En segundos, asumiendo 40fps) permanece allí la cantidad 
  # de experiencia ganada
  ANNOUCE_TIME      = 1
  # En experiencia por fotograma, asumiendo 40fps, qué tan rápido es la barra
  # Cualquier valor menor que 0 se trata como 0
  # Cualquier valor mayor que 199 se trata como 199
  BAR_SPEED         = 100
  # Píxeles A LA IZQUIERDA del lado derecho de la barra es el punto medio del 
  # Nivel del Pokémon
  LEVEL_X           = 64
  # Píxeles ARRIBA de la barra está el Nivel del Pokémon
  LEVEL_Y           = 48
  # Píxeles A LA DERECHA del lado izquierdo de la barra está el lado izquierdo
  # del Pokémon
  POKE_X            = 0
  # Píxeles DEBAJO de donde estaría el Pokémon si estuviera encima de la parte
  # superior de la barra está el Pokémon
  # (No estoy seguro por qué cambiarías esto, pero está aquí)
  POKE_Y            = 0
  # Píxeles a la derecha del punto medio de la barra está la experiencia anunciada
  EXP_X             = 0
  # Píxeles DEBAJO del lado inferior de la barra está la experiencia anunciada
  EXP_Y             = 4
  # Decide las posiciones de dónde van las barras
  # (Mejor dejar esto como está)
  #...
  # Pero si quieres modificar esto, aquí tienes una breve explicación
  # Los decimales aquí explican dónde está el punto medio de la barra en relación 
  # con la pantalla [ancho, altura].
  # Por ejemplo, un valor de 0.5 significa que la barra está a la mitad de la pantalla. 
  # 0.33 significa que la barra está a un tercio de la pantalla.
  CO_ORDINATES = [
    [[0.5, 0.5]],   # Grupo de 1: 1er Pokémon
    [[0.33, 0.5],   # Grupo de 2: 1er Pokémon
    [0.67, 0.5]], 
    [[0.25, 0.5],   # Equipo de 3, 1er Pokémon
    [0.5,  0.5],   #             2do Pokémon
    [0.75, 0.5]],  #             3er Pokémon
    [[0.33, 0.25],  # Equipo de 4, 1er Pokémon
    [0.67, 0.25],  #             2do Pokémon
    [0.33, 0.67],  #             3er Pokémon
    [0.67, 0.67]], #             4to Pokémon
    [[0.25, 0.25],  # Equipo de 5, 1er Pokémon
    [0.5,  0.25],  #             2do Pokémon
    [0.75, 0.25],  #             3er Pokémon
    [0.33, 0.67],  #             4to Pokémon
    [0.67, 0.67]], #             5to Pokémon
    [[0.18, 0.25],  # Equipo de 6, 1er Pokémon
    [0.5,  0.25],  #             2do Pokémon
    [0.82, 0.25],  #             3er Pokémon
    [0.18, 0.67],  #             4to Pokémon
    [0.5,  0.67],  #             5to Pokémon
    [0.82, 0.67]]  #             6to Pokémon
  ]
  # Cuántos píxeles se arrastra hacia abajo todo en la pantalla (excepto el panel 
  # de fondo)
  MOVE_DOWN_PIXELS = 16
end


################################################################################
# Mostrar el número de pasos restantes para la eclosión de un HUEVO en la
# pantalla de Datos.
################################################################################

MOSTRAR_PASOS_HUEVO = false



################################################################################
# MAPAS SIN REFLEJOS
# IDs de los mapas en los que no quieres que el personaje tenga reflejo.
# Ejemplo: MAPAS_SIN_REFLEJO = [12,157,536]
################################################################################

MAPAS_SIN_REFLEJO = []
