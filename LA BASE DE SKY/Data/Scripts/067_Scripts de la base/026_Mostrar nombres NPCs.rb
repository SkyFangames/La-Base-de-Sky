#===============================================================================
#                              Script : NameBox (ver. 4)
#                              Autor : Bezier
#                              Modificado por: dracrixco y  DPertierra
#-------------------------------------------------------------------------------
#  Muestra un cuadro de texto auxiliar encima del cuadro de dialogos.
#  Para usarlo, escribir en un cuadro de script el siguiente código:
#     NameBox.load('Nombre')
#  Desde la versión 4, se recomienda pasar el texto usando comillas simples
#  para poder parsear comandos. Los comandos que están implementados son:
#     NameBox.load('\PN')     # Muestra el nombre del jugador
#     NameBox.load('\v[n]')   # Muestra el contenido de la variable n
#-------------------------------------------------------------------------------
# - UPDATES -
# 23/02/21 -> Versión 2
#   Muestra el nombre del personaje si se le pasa /PN como nombre a mostrar
# 09/03/21 -> Versión 3
#   Usa el mismo WindowSkin que la caja de mensajes para borde del cuadro
#     Créditos por feedback: Pokémon Ultimate (Twitter: @Pkmn_Ultimate)
# 17/06/21 -> Versión 4
#   Parsea comandos versión 1. Debe escribirse con comillas simples
#     Muestra el nombre del personaje con si se pasa '\PN'
#     Muestra el nombre de la variable si se pasa '\v[num]' siendo num el
#       número de la variable que se desea mostrar
#     Créditos por feedback: Ravel
#
#-------------------------------------------------------------------------------
#  Paso 1: ¿Cómo integrarlo?
#
#  Editar la función Kernel.pbMessageDisplay del script Messages:
#
#  Añadir esta línea mas o menos a mitad de la función
#     (busca el comentario con muchas # como referencia)
#  [...]
#  ########## Show text #############################
#  NameBox.show(msgwindow) # <- Añadir esta línea para mostrar el NameBox.
#  msgwindow.text=text
#  [...]
#
#  Y esta otra linea antes de terminar la función
#  [...]
#  end
#    NameBox.hide # <- Añadir esta línea para ocultar el NameBox junto con el cuadro de texto
#    return ret
#  end
#  [...]
#
#-------------------------------------------------------------------------------
#  Paso 2: ¿Cómo se usa?
#
#  Hacer el cambio del Paso 1.
#  Cambiar el nombre de la skin a usar NAMEBOXWINSKIN (más abajo)
#
#  Para usarlo en un evento tan solo hay que llamar al script:
#     NameBox.load("Nombre")
#
#  Esto creará un cuadro con el texto "Nombre" y se mostrará encima del cuadro
#  de dialogo cada vez que se escriba un texto, hasta que se desactive.
#
#  Para desactivarlo, llamar al script:
#     NameBox.dispose
#
#  Si se quiere poner color a un personaje, tan solo hay que añadir una entrada
#  en la lista NPCCOLORS (más abajo) con el nombre del personaje y
#  los colores para la base y la sombra del texto.
#
#-------------------------------------------------------------------------------
#  Paso 3: Compatibilidades (Opcional)
#
#  Si se está usando el script de comandos de JESS, que muestra un cuadro
#  similar a este, hay que editar este script en vez del de Messages para que
#  todos los textos que existan en eventos ya programados sean compatibles.
#  Del mismo modo que en el Paso 1, hay que añadir la llamada al NameBox en la
#  función Kernel.pbMessageDisplay.
#  Si no se encuentra el comentario:
#      ########## Show text #############################
#  habrá que buscar la línea:
#      msgwindow.text=text
#  y hacer la llamada a NameBox antes de asignar el texto:
#
#  [...]
#  atTop=(msgwindow.y==0)
#  NameBox.show(msgwindow) # <- Añadir esta línea para mostrar el NameBox.
#  msgwindow.text=text
#  [...]
#
#  Y esta otra linea antes de terminar la función
#  [...]
#  end
#    NameBox.hide # <- Añadir esta línea para ocultar el NameBox junto con el cuadro de texto
#    return ret
#  end
#  [...]
#===============================================================================

module NameBox

  # Posición del NameBox en pantalla
  NAMEBOX_X = 14
  NAMEBOX_Y = 228 # + 5
  NAMEBOX_Z = 999
  NAMEBOX_IN_TOP = true

  # IMPORTANTCHARACTER está pensado para las personas que piensen usar el sistema 
  # de traducción de essentials, en caso contrario, ignorar.
  IMPORTANTCHARACTER = {
    # "Nombre" = \_INTL("Nombre")
  }

  #CHARACTERNAMES funciona igual que "IMPORTANTCHARACTER", pero esta enfocado a 
  #nombres comunes, como profesiones o roles.
  #NameBox.CHARACTERNAMES puede aceptar un segundo parametro para sacarle provecho
  #a CHARACTERNAMES, por ejemplo, en vez de tener.
  # IMPORTANTCHARACTER = {
  #  "Recluta 1" = _INTL("Recluta 1")
  #  "Recluta 2" = _INTL("Recluta 2")
    # ...
  #  "Recluta N" = _INTL("Recluta N")
  #}
  #Solo necesitas
  #IMPORTANTCHARACTER = {
  #  "Recluta" = \_INTL("Recluta")
  #}


  CHARACTERNAMES = {
    # "Nombre" = \_INTL("Nombre")
  }

  # Colores asociados a cada personaje
  NPCCOLORS = {
    # "Nombre" => [ColorBase, Sombra]
    "Prof. Oak" => [Color.new(48,80,200), Color.new(208,208,208)],
    "Candela" => [Color.new(224,8,8), Color.new(208,208,208)]
  }

  # Si esto está en true el cuadro del nombre del NPC será del mismo estilo que el cuadro de texto elegido
  # Si quieren cambiar este comportamiento y definir un skin específico para cada nombre, entonces hay que cambiar la siguiente constante a false
  USE_TEXT_WINDOW_SKIN_FOR_NAMEBOX = true

  # Si USE_TEXT_WINDOW_SKIN_FOR_NAMEBOX es false, entonces se usarán los siguientes skins para los NPCs
  NAMEBOX_WINDOW_SKINS_FOR_NPC = {
    "Prof. Oak" => "speech hgss 2",
    "Candela" => "speech hgss 1"
  }

  # Si USE_TEXT_WINDOW_SKIN_FOR_NAMEBOX es false, y no se encuentra al NPC en el hash NAMEBOX_WINDOW_SKINS_FOR_NPC,
  # Se verifica la siguiente constante si está en true se utilizará por defecto el Skin de la Text Box como skin de la NameBox
  # Si es false, se usará el skin definido en la constante DEFAULT_NAMEBOXWINSKIN
  USE_TEXT_WINDOW_SKIN_AS_DEFAULT = true

  # Nombre de la skin para el cuadro en "Graphics/Windowskins"
  DEFAULT_NAMEBOXWINSKIN = "speech hgss 2"

  # Carga el NameBox con el nombre indicado pero no lo deja visible
  # Se hará visible cuando se muestre un cuadro de diálogo

  def self.load(name, number = nil)
    @currentName = name.clone
    @currentName = IMPORTANTCHARACTER[name] if IMPORTANTCHARACTER[name]
    @currentName = CHARACTERNAMES[name] if CHARACTERNAMES[name]
    @currentName += " #{number}" if number
    # Parseo antiguo para mostrar el nombre de personaje
    @currentName.gsub!(/\\pn/i,  $player.name) if $player
    # Parseo nuevo para mostrar el nombre de personaje
    @currentName.gsub!(/\\[Pp][Nn]/,$player.name) if $player
    # Parsea la variable con el formato '\v[n]'
    @currentName.gsub!(/\\v\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
    # Temas relacionados al genero
    @currentName.gsub!(/\\@a/i,"a") if $player&.female?
    @currentName.gsub!(/\\@a/i,"") if $player&.male?
    @currentName.gsub!(/\\@/i,"a") if $player&.female?
    @currentName.gsub!(/\\@/i,"o") if $player&.male?
    @currentName.gsub!(/\\&/i,"o") if $player&.female?
    @currentName.gsub!(/\\&/i,"a") if $player&.male?

    @namebox&.dispose
    @namebox = Window_AdvancedTextPokemon.new(@currentName)
    @namebox.visible = true

    skin = if USE_TEXT_WINDOW_SKIN_FOR_NAMEBOX
             MessageConfig.pbGetSpeechFrame
           else
             NAMEBOX_WINDOW_SKINS_FOR_NPC[@currentName] ||
               (USE_TEXT_WINDOW_SKIN_AS_DEFAULT ? MessageConfig.pbGetSpeechFrame : DEFAULT_NAMEBOXWINSKIN)
           end
    @namebox.setSkin("Graphics/Windowskins/#{skin}")

    @namebox.resizeToFit(@namebox.text, Graphics.width)
    @namebox.x = NAMEBOX_X
    @namebox.y = NAMEBOX_Y
    @namebox.z = NAMEBOX_Z if NAMEBOX_IN_TOP
    setTextColor
  end

  # Muestra el NameBox (Debe estár integrada la llamada del Paso 1)
  def self.show(msgwindow)
    return unless @namebox && msgwindow

    @namebox.viewport = msgwindow.viewport
    @namebox.z = msgwindow.z
    @namebox.visible = true
  end

  # Oculta el NameBox pero no lo destruye, para que se muestre junto al próximo texto
  def self.hide
    @namebox.visible = false if @namebox
  end

  # Destruye el NameBox para que no se muestre con el siguiente texto
  def self.dispose
    @namebox&.dispose
    @namebox = nil
  end

  # Devuelve si el NameBox está activo
  def self.isEnabled?
    @namebox != nil
  end

  # Función interna que cambia el color del texto asociado al nombre actual
  def self.setTextColor
    return unless @namebox

    colors = NPCCOLORS[@currentName] || getDefaultTextColors(@namebox.windowskin)

    @namebox.baseColor = colors[0]
    @namebox.shadowColor = colors[1]

    # Es necesario actualizar el texto para que repinte con los colores nuevos
    @namebox.text = @currentName
  end
end
