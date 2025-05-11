#==============================================================================#
# AJUSTES DE LOS PLUGINS                                                      #
#                                                                              #
# Aquí encontrarás toda la configuración de los distintos Plugins que          #
# incorpora esta base.                                                         #
#==============================================================================#

module Settings

  # Activa es to si quieres que los objetos consumibles
  # como gemas, bayas, banda focus, etc. sean restaurados luego del combate
  RESTORE_HELD_ITEMS_AFTER_BATTLE = false

  # Lista de objetos consumibles que NO serán recuperados luego del combate
  # el formato es [:IDOBJETO] por ejemplo [:SITRUSBERRY]
  RESTORE_HELD_ITEMS_BLACKLIST = []

  
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

  ## HABILITAR EL REAPATIR EXPERIENCIA desde el inicio de la partida, sin necesidad de dar ningun objeto
  ## o de activar el $player.has_exp_all, si desean activar el expshare para todos los pokemons, con alguno
  ## de los 2 metodos mencionados anteriormente, deben dejar esta variable en false.
  EXPSHARE_ENABLED = true


  
################################################################################
#  CONFIGURACIÓN DEL ENHANCED BATTLE UI
################################################################################
  # Almacena la ruta para los gráficos utilizados por este plugin.
  BATTLE_UI_GRAPHICS_PATH = "Graphics/Plugins/Enhanced Battle UI/"
  
  #-----------------------------------------------------------------------------
  # The display style for button prompts used to open UI menus that appear when selecting commands.
  # 0 => No prompts shown
  # 1 => Always show prompt
  # 2 => Show prompt, but hide after 2 seconds.
  #-----------------------------------------------------------------------------
  UI_PROMPT_DISPLAY = 2
  

  #-----------------------------------------------------------------------------
  # When true, Move UI background will reflect the color of the move type.
  #-----------------------------------------------------------------------------
  USE_MOVE_TYPE_BACKGROUNDS = true


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

  # # Mostrar Siluetas para los Pokemon no vistos en la dex
  SHOW_SILHOUETTES_IN_DEX = false


  
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


################################################################################
# LISTADO DE POKÉMON CON FORMAS REGIONALES
# Los Pokémon que estén en el listado de abajo son los que el cambia formas
# podrá cambiar
################################################################################
REGIONAL_SPECIES = [:RATTATA,:RATICATE,:RAICHU,:SANDSHREW,:SANDSLASH,:VULPIX,:NINETALES,:DIGLETT,:DUGTRIO,
                    :MEOWTH,:PERSIAN,:GEODUDE,:GRAVELER,:GOLEM,:PONYTA,:RAPIDASH,:SLOWPOKE,:SLOWBRO,:FARFETCHD,:GRIMER,:MUK,
                    :EXEGGUTOR,:MAROWAK,:WEEZING,:MRMIME,:ARTICUNO,:ZAPDOS,:MOLTRES,:SLOWKING,:CORSOLA,
                    :ZIGZAGOON,:LINOONE, :DARUMAKA,:DARMANITAN,:YAMASK,:STUNFISK,:LYCANROC, :GROWLITHE,:ARCANINE,
                    :VOLTORB,:ELECTRODE,:TAUROS,:CYNDAQUIL,:QUILAVA,:TYPHLOSION,:WOOPER,:QWILFISH,:SNEASEL,:OSHAWOTT,:DEWOTT,:SAMUROTT,
                    :PETILIL,:LILLIGANT,:ZORUA,:ZOROARK,:RUFFLET,:BRAVIARY,:GOOMY,:SLIGGOO,:GOODRA,:BERGMITE,:AVALUGG,:ROWLET,:DARTRIX,:DECIDUEYE]

#######################################################################################
# LISTADO DE FORMAS DE POKÉMON NO PERMITIDAS
# Este listado es para configurar determinadas formas de Pokémon del listado de arriba
# Para que el cambia formas no las muestre
########################################################################################
FORMS_BLACKLIST = {:DARMANITAN => [1, 3]}


