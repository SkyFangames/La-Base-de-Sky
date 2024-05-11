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
  
  # Nombre de la skin para el cuadro en "Graphics/Windowskins"
  NAMEBOXWINSKIN = "speech hgss 2"
  
  # Posición del NameBox en pantalla
  NAMEBOX_X = 14
  NAMEBOX_Y = 228 #+ 5
  
  #IMPORTANTCHARACTER está pensado para las personas que piensen usar el sistema 
  #de traducción de essentials, en caso contrario, ignorar.
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
      @currentName.gsub!(/\\@a/i,"a") if $player && $player.female?
      @currentName.gsub!(/\\@a/i,"") if $player && $player.male?
      @currentName.gsub!(/\\@/i,"a") if $player && $player.female?
      @currentName.gsub!(/\\@/i,"o") if $player && $player.male?
      @currentName.gsub!(/\\&/i,"o") if $player && $player.female?
      @currentName.gsub!(/\\&/i,"a") if $player && $player.male?
      @namebox.dispose if @namebox
      @namebox = Window_AdvancedTextPokemon.new(@currentName)
      @namebox.visible = true
      # @namebox.setSkin("Graphics/Windowskins/#{NAMEBOXWINSKIN}") [OBSOLETO]
      
      # Usa la skin de la caja de mensajes para el cuadro del namebox
      # Cambio realizado por Pokémon Ultimate
      @namebox.setSkin(MessageConfig.pbGetSpeechFrame())
      
      @namebox.resizeToFit(@namebox.text, Graphics.width)
      @namebox.x = NAMEBOX_X
      @namebox.y = NAMEBOX_Y
      setTextColor()
    end
  
      # Muestra el NameBox (Debe estár integrada la llamada del Paso 1)
    def self.show(msgwindow)
      if @namebox && msgwindow
        @namebox.viewport = msgwindow.viewport
        @namebox.z = msgwindow.z
        @namebox.visible = true
      end
    end
 
    # Oculta el NameBox pero no lo destruye, para que se muestre junto al próximo texto
    def self.hide
      @namebox.visible = false if @namebox 
    end
    
    # Destruye el NameBox para que no se muestre con el siguiente texto
    def self.dispose
      @namebox.dispose if @namebox
      @namebox = nil
    end
    
    # Devuelve si el NameBox está activo
    def self.isEnabled?
      return @namebox != nil
    end
    
    # Función interna que cambia el color del texto asociado al nombre actual
    def self.setTextColor()
      if @namebox
        if NPCCOLORS[@currentName]
          colors = NPCCOLORS[@currentName]
        else
          colors = getDefaultTextColors(@namebox.windowskin)
        end
        
        @namebox.baseColor = colors[0]
        @namebox.shadowColor = colors[1]
        
        # Es necesario actualizar el texto para que repinte con los colores nuevos
        @namebox.text = @currentName
      end
    end
end
