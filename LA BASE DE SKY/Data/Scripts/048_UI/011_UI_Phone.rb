#===============================================================================
# Phone list of contacts
#===============================================================================
class Window_PhoneList < Window_CommandPokemon
  attr_accessor :switching

  CURSOR_Y_OFFSET = 2
  RECT_X_OFFSET = 28
  RECT_Y_OFFSET = 8
  RECT_WIDTH_OFFSET = -16
  RECT_HEIGHT_OFFSET = 0

  def drawCursor(index, rect)
    if self.index == index
      selarrow = AnimatedBitmap.new("Graphics/UI/Phone/cursor")
      pbCopyBitmap(self.contents, selarrow.bitmap, rect.x, rect.y + CURSOR_Y_OFFSET)
    end
    return Rect.new(rect.x + RECT_X_OFFSET, rect.y + RECT_Y_OFFSET, rect.width + RECT_WIDTH_OFFSET, rect.height + RECT_HEIGHT_OFFSET)
  end

  def drawItem(index, count, rect)
    return if index >= self.top_row + self.page_item_max
    if self.index == index && @switching
      rect = drawCursor(index, rect)
      pbDrawShadowText(self.contents, rect.x, rect.y + (self.contents.text_offset_y || 0),
                       rect.width, rect.height, @commands[index], Color.new(224, 0, 0), Color.new(224, 144, 144))
    else
      super
    end
    drawCursor(index - 1, itemRect(index - 1))
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPhone_Scene
  # Posición X de la lista de contactos en la pantalla
  LIST_X                    = 152
  # Posición Y de la lista de contactos en la pantalla
  LIST_Y                    = 32
  # Ajuste del ancho de la lista respecto a Graphics.width (valor sumado)
  LIST_WIDTH_OFFSET         = -142
  # Ajuste de la altura de la lista respecto a Graphics.height (valor sumado)
  LIST_HEIGHT_OFFSET        = -80
  # Posición X base para los iconos de revancha (rematch)
  REMATCH_ICON_X            = 468
  # Posición Y base para los iconos de revancha (se incrementa por fila)
  REMATCH_ICON_Y            = 62
  # Espacio vertical entre iconos de revancha (pixels)
  REMATCH_ICON_SPACING      = 32
  # Offset X para colocar el icono de señal relativo a Graphics.width
  SIGNAL_ICON_X_OFFSET      = -32
  # Posición Y del icono de señal
  SIGNAL_ICON_Y             = 0
  # Posición X de la ventana de encabezado (título)
  HEADER_TEXT_WINDOW_X      = 2
  # Posición Y de la ventana de encabezado (título)
  HEADER_TEXT_WINDOW_Y      = -18
  # Ancho de la ventana de encabezado (título)
  HEADER_TEXT_WINDOW_WIDTH  = 128
  # Alto de la ventana de encabezado (título)
  HEADER_TEXT_WINDOW_HEIGHT = 64
  # Posición X de la ventana de información sobre contactos
  INFO_TEXT_WINDOW_X        = -8
  # Posición Y de la ventana de información sobre contactos
  INFO_TEXT_WINDOW_Y        = 224
  # Ancho de la ventana de información sobre contactos
  INFO_TEXT_WINDOW_WIDTH    = 180
  # Alto de la ventana de información sobre contactos
  INFO_TEXT_WINDOW_HEIGHT   = 160
  # Posición X de la ventana inferior (ubicación del contacto)
  BOTTOM_TEXT_WINDOW_X      = 162
  # Posición Y de la ventana inferior; se basa en la altura de la pantalla
  BOTTOM_TEXT_WINDOW_Y      = Graphics.height - 64
  # Ancho de la ventana inferior; se adapta a la anchura de la pantalla
  BOTTOM_TEXT_WINDOW_WIDTH  = Graphics.width - 158
  # Alto de la ventana inferior
  BOTTOM_TEXT_WINDOW_HEIGHT = 64
  # Posición X del retrato/ícono del contacto
  ICON_X                    = 86
  # Posición Y del retrato/ícono del contacto
  ICON_Y                    = 134
  def pbStartScene
    @sprites = {}
    # Create viewport
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    # Background
    addBackgroundPlane(@sprites, "bg", "Phone/bg", @viewport)
    # List of contacts
    @sprites["list"] = Window_PhoneList.newEmpty(LIST_X, LIST_Y, Graphics.width + LIST_WIDTH_OFFSET, Graphics.height + LIST_HEIGHT_OFFSET, @viewport)
    @sprites["list"].windowskin = nil
    # Rematch readiness icons
    if Phone.rematches_enabled
      @sprites["list"].page_item_max.times do |i|
        @sprites["rematch_#{i}"] = IconSprite.new(REMATCH_ICON_X, REMATCH_ICON_Y + (i * REMATCH_ICON_SPACING), @viewport)
      end
    end
    # Phone signal icon
    @sprites["signal"] = IconSprite.new(Graphics.width + SIGNAL_ICON_X_OFFSET, SIGNAL_ICON_Y, @viewport)
    if Phone::Call.can_make?
      @sprites["signal"].setBitmap("Graphics/UI/Phone/icon_signal")
    else
      @sprites["signal"].setBitmap("Graphics/UI/Phone/icon_nosignal")
    end
    # Title text
    @sprites["header"] = Window_UnformattedTextPokemon.newWithSize(
      _INTL("Teléfono"), HEADER_TEXT_WINDOW_X, HEADER_TEXT_WINDOW_Y, HEADER_TEXT_WINDOW_WIDTH, HEADER_TEXT_WINDOW_HEIGHT, @viewport
    )
    @sprites["header"].baseColor   = Color.new(248, 248, 248)
    @sprites["header"].shadowColor = Color.black
    @sprites["header"].windowskin = nil
    # Info text about all contacts
    @sprites["info"] = Window_AdvancedTextPokemon.newWithSize("", INFO_TEXT_WINDOW_X, INFO_TEXT_WINDOW_Y, INFO_TEXT_WINDOW_WIDTH, INFO_TEXT_WINDOW_HEIGHT, @viewport)
    @sprites["info"].windowskin = nil
    # Portrait of contact
    @sprites["icon"] = IconSprite.new(70, 102, @viewport)
    # Contact's location text
    @sprites["bottom"] = Window_AdvancedTextPokemon.newWithSize(
      "", BOTTOM_TEXT_WINDOW_X, BOTTOM_TEXT_WINDOW_Y, BOTTOM_TEXT_WINDOW_WIDTH, BOTTOM_TEXT_WINDOW_HEIGHT, @viewport
    )
    @sprites["bottom"].windowskin = nil
    # Start scene
    pbRefreshList
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbRefreshList
    @contacts = []
    $PokemonGlobal.phone.contacts.each do |contact|
      @contacts.push(contact) if contact.visible?
    end
    # Create list of commands (display names of contacts) and count rematches
    commands = []
    rematch_count = 0
    @contacts.each do |contact|
      commands.push(contact.display_name)
      rematch_count += 1 if contact.can_rematch?
    end
    # Set list's commands
    @sprites["list"].commands = commands
    @sprites["list"].index = commands.length - 1 if @sprites["list"].index >= commands.length
    if @sprites["list"].top_row > @sprites["list"].itemCount - @sprites["list"].page_item_max
      @sprites["list"].top_row = @sprites["list"].itemCount - @sprites["list"].page_item_max
    end
    # Set info text
    infotext = _INTL("Registrado") + "<br>"
    infotext += "<r>" + @sprites["list"].commands.length.to_s + "<br>"
    infotext += _INTL("Esperando revancha") + "<r>" + rematch_count.to_s
    @sprites["info"].text = infotext
    pbRefreshScreen
  end

  def pbRefreshScreen
    @sprites["list"].refresh
    # Redraw rematch readiness icons
    if @sprites["rematch_0"]
      @sprites["list"].page_item_max.times do |i|
        @sprites["rematch_#{i}"].clearBitmaps
        j = i + @sprites["list"].top_item
        if j < @contacts.length && @contacts[j].can_rematch?
          @sprites["rematch_#{i}"].setBitmap("Graphics/UI/Phone/icon_rematch")
        end
      end
    end
    # Get the selected contact
    contact = @contacts[@sprites["list"].index]
    if contact
      # Redraw contact's portrait
      if contact.trainer?
        filename = GameData::TrainerType.charset_filename(contact.trainer_type)
      else
        filename = sprintf("Graphics/Characters/phone%03d", contact.common_event_id)
      end
      @sprites["icon"].setBitmap(filename)
      charwidth  = @sprites["icon"].bitmap.width
      charheight = @sprites["icon"].bitmap.height
      @sprites["icon"].x        = ICON_X - (charwidth / 8)
      @sprites["icon"].y        = ICON_Y - (charheight / 8)
      @sprites["icon"].src_rect = Rect.new(0, 0, charwidth / 4, charheight / 4)
      # Redraw contact's location text
      map_name = (contact.map_id > 0) ? pbGetMapNameFromId(contact.map_id) : ""
      @sprites["bottom"].text = "<ac>" + map_name
    else
      @sprites["icon"].setBitmap(nil)
      @sprites["bottom"].text = ""
    end
  end

  def pbChooseContact
    pbActivateWindow(@sprites, "list") do
      index = -1
      switch_index = -1
      loop do
        Graphics.update
        Input.update
        pbUpdateSpriteHash(@sprites)
        # Cursor moved, update display
        if @sprites["list"].index != index
          if switch_index >= 0
            real_contacts = $PokemonGlobal.phone.contacts
            real_contacts.insert(@sprites["list"].index, real_contacts.delete_at(index))
            pbRefreshList
          else
            pbRefreshScreen
          end
        end
        index = @sprites["list"].index
        # Get inputs
        if switch_index >= 0
          if Input.trigger?(Input::ACTION) ||
             Input.trigger?(Input::USE)
            pbPlayDecisionSE
            @sprites["list"].switching = false
            switch_index = -1
            pbRefreshScreen
          elsif Input.trigger?(Input::BACK)
            pbPlayCancelSE
            real_contacts = $PokemonGlobal.phone.contacts
            real_contacts.insert(switch_index, real_contacts.delete_at(@sprites["list"].index))
            @sprites["list"].index = switch_index
            @sprites["list"].switching = false
            switch_index = -1
            pbRefreshList
          end
        else
          if Input.trigger?(Input::ACTION)
            switch_index = @sprites["list"].index
            @sprites["list"].switching = true
            pbRefreshScreen
          elsif Input.trigger?(Input::BACK)
            pbPlayCloseMenuSE
            return nil
          elsif Input.trigger?(Input::USE)
            return @contacts[index] if index >= 0
          end
        end
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPhoneScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    if $PokemonGlobal.phone.contacts.none? { |con| con.visible? }
      pbMessage(_INTL("No tienes números de teléfono guardados."))
      return
    end
    @scene.pbStartScene
    loop do
      contact = @scene.pbChooseContact
      break if !contact
      commands = []
      commands.push(_INTL("Llamar"))
      commands.push(_INTL("Eliminar")) if contact.can_hide?
      commands.push(_INTL("Ordenar Contactos"))
      commands.push(_INTL("Cancelar"))
      cmd = pbShowCommands(nil, commands, -1)
      cmd += 1 if cmd >= 1 && !contact.can_hide?
      case cmd
      when 0   # Call
        Phone::Call.make_outgoing(contact)
      when 1   # Delete
        name = contact.display_name
        if pbConfirmMessage(_INTL("¿Estás segur{1} de que quieres eliminar a {2} de tus contactos?", $player.female? ? 'a' : 'o', name))
          contact.visible = false
          $PokemonGlobal.phone.sort_contacts
          @scene.pbRefreshList
          pbMessage(_INTL("Has eliminado a {1} de tus contactos.", name))
          if $PokemonGlobal.phone.contacts.none? { |con| con.visible? }
            pbMessage(_INTL("No tienes contactos guardados."))
            break
          end
        end
      when 2   # Sort Contacts
        case pbMessage(_INTL("¿Cómo quieres ordenar los contactos?"),
                       [_INTL("Por nombre"),
                        _INTL("Por tipo de Entrenador"),
                        _INTL("Contactos especiales primero"),
                        _INTL("Cancelar")], -1, nil, 0)
        when 0   # By name
          $PokemonGlobal.phone.contacts.sort! { |a, b| a.name <=> b.name }
          $PokemonGlobal.phone.sort_contacts
          @scene.pbRefreshList
        when 1   # By trainer type
          $PokemonGlobal.phone.contacts.sort! { |a, b| a.display_name <=> b.display_name }
          $PokemonGlobal.phone.sort_contacts
          @scene.pbRefreshList
        when 2   # Special contacts first
          new_contacts = []
          2.times do |i|
            $PokemonGlobal.phone.contacts.each do |con|
              next if (i == 0 && con.trainer?) || (i == 1 && !con.trainer?)
              new_contacts.push(con)
            end
          end
          $PokemonGlobal.phone.contacts = new_contacts
          $PokemonGlobal.phone.sort_contacts
          @scene.pbRefreshList
        end
      end
    end
    @scene.pbEndScene
  end
end

