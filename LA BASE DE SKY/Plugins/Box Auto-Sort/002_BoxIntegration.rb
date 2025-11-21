#===============================================================================
# Box Auto-Sort - Box Integration
#===============================================================================

module BoxAutoSort
  # Main sort menu
  def self.show_sort_menu(storage, current_box = nil)
    current_box ||= storage.currentBox
    
    commands = [
      _INTL("Nivel (Menor a Mayor)"),
      _INTL("Nivel (Mayor a Menor)"),
      _INTL("Alfabetico (A-Z)"),
      _INTL("Alfabetico (Z-A)"),
      _INTL("Tipo Primario"),
      _INTL("Combinación de Tipos"),
      _INTL("Fecha de Captura"),
      _INTL("Shiny Primero"),
      _INTL("Dex Nacional"),
      _INTL("Formas"),
      _INTL("Amistad"),
      _INTL("Naturaleza"),
      _INTL("Cancelar")
    ]
    
    choice = pbMessage(_INTL("¿Cómo quieres ordenar esta caja?"), commands, commands.length - 1)
    
    return if choice < 0 || choice >= commands.length - 1
    
    sort_method = case choice
    when 0 then :LEVEL_ASC
    when 1 then :LEVEL_DESC
    when 2 then :ALPHABET
    when 3 then :ALPHABET_REV
    when 4 then :TYPE_PRIMARY
    when 5 then :TYPE_DUAL
    when 6 then :CATCH_DATE
    when 7 then :SHINY_FIRST
    when 8 then :SPECIES_ID
    when 9 then :FORM_ID
    when 10 then :FRIENDSHIP
    when 11 then :NATURE
    end
    
    perform_sort(storage, current_box, sort_method)
  end

  # Perform sorting
  def self.perform_sort(storage, box, method)
    sorter = BoxSorter.new(storage, box)
    
    # Show preview
    preview_list = sorter.preview_sort(method)
    if preview_list.empty?
      pbMessage("Esta caja está vacía!")
      return
    end
    
    # Create preview text (show only first 8 Pokemon)
    confirm = true
    if BoxAutoSort::SHOW_PREVIEW
      preview_count = [preview_list.length, BoxAutoSort::PREVIEW_COUNT].min
      preview_text = "Vista previa de los primeros #{preview_count} Pokémon:\n"
      preview_list[0, preview_count].each_with_index do |pokemon_data, i|
        pokemon = pokemon_data[0]  # Pokemon is the first element in the array
        name = pokemon.name
        level = pokemon.level
        preview_text += "#{i+1}. #{name} (Lv.#{level})\n"
      end
      preview_text += "\n¿Deseas aplicar este ordenamiento?"
      confirm = pbConfirmMessage(preview_text)
    end

    if confirm
      pbMessage("Ordenando caja...") if BoxAutoSort::SHOW_PREVIEW
      success = sorter.sort_pokemon(method)
      if success
        pbMessage("Caja ordenada!") if BoxAutoSort::SHOW_PREVIEW
        pbPlayDecisionSE
      else
        pbMessage("El ordenamiento falló!")
        pbPlayBuzzerSE
      end
    end
  end
end

# =============================================================================
# PC MENU INTEGRATION - Direct Access
# =============================================================================

MenuHandlers.add(:pc_menu, :box_auto_sort, {
  "name"      => _INTL("Ordenamiento del PC"),
  "order"     => 15,
  "effect"    => proc { |menu|
    pbMessage("\\se[PC access]" + _INTL("Sistema de Ordenamiento del PC abierto."))
    
    # Seleccionar caja
    commands = []
    $PokemonStorage.maxBoxes.times do |i|
      box = $PokemonStorage[i]
      if box
        commands.push(_INTL("{1} ({2}/{3})", box.name, box.nitems, box.length))
      end
    end
    commands.push(_INTL("Cancelar"))
    
    choice = pbMessage(_INTL("Qué caja quieres ordenar?"), commands, commands.length - 1)
    
    if choice >= 0 && choice < $PokemonStorage.maxBoxes
      selected_box = choice
      BoxAutoSort.show_sort_menu($PokemonStorage, selected_box)
    end
    
    next false
  }
})

# =============================================================================
# DIRECT OVERRIDE - Loads immediately!
# =============================================================================

# Define the pbBoxCommands override in a standalone module
module BoxAutoSortOverride
  def pbBoxCommands
    commands = [
      _INTL("Saltar"),
      _INTL("Fondo"),
      _INTL("Nombre"),
      _INTL("Ordenar Caja"),
      _INTL("Liberar Caja"),
      _INTL("Cancelar")
    ]
    
    # Add Swap if Storage System Utilities is active
    if defined?(CAN_SWAP_BOXES) && CAN_SWAP_BOXES
      commands.insert(1, _INTL("Intercambiar"))
    end
    
    command = pbShowCommands(_INTL("¿Qué quieres hacer?"), commands)
    
    case command
    when commands.index(_INTL("Saltar"))
      destbox = @scene.pbChooseBox(_INTL("¿Saltar a qué Caja?"))
      @scene.pbJumpToBox(destbox) if destbox >= 0
      
    when commands.index(_INTL("Intercambiar"))
      if defined?(CAN_SWAP_BOXES) && CAN_SWAP_BOXES && @scene.respond_to?(:pbSwapBoxes)
        destbox = @scene.pbChooseBox(_INTL("¿Intercambiar con qué Caja?"))
        @scene.pbSwapBoxes(destbox) if destbox >= 0
      end
      
    when commands.index(_INTL("Fondo"))
      papers = @storage.availableWallpapers
      index = 0
      papers[1].length.times do |i|
        if papers[1][i] == @storage[@storage.currentBox].background
          index = i
          break
        end
      end
      wpaper = pbShowCommands(_INTL("¿Qué fondo quieres usar?"), papers[0], index)
      @scene.pbChangeBackground(papers[1][wpaper]) if wpaper >= 0
      
    when commands.index(_INTL("Nombre"))
      @scene.pbBoxName(_INTL("¿Nombre de la Caja?"), 0, 12)
      
    when commands.index(_INTL("Ordenar Caja"))
      BoxAutoSort.show_sort_menu(@storage, @storage.currentBox)
      @scene.pbHardRefresh if @scene.respond_to?(:pbHardRefresh)
      @scene.pbRefresh if @scene.respond_to?(:pbRefresh)
    
    when commands.index(_INTL("Liberar Caja"))
      pbReleaseBox(@storage.currentBox)
    end
  end
end

# Wait briefly and then override ALL storage classes
Thread.new do
  sleep(2) # Wait 2 seconds for all plugins to load
  
  # Standard Storage Screen
  if defined?(PokemonStorageScreen)
    PokemonStorageScreen.prepend(BoxAutoSortOverride)
  end
  
  # BW Storage Screen
  if defined?(PokemonStorageScreenBW)
    PokemonStorageScreenBW.prepend(BoxAutoSortOverride)
  end
end

# =============================================================================
# Debug Commands for Testing
# =============================================================================

if $DEBUG
  MenuHandlers.add(:debug_menu, :box_auto_sort_test, {
    "name"        => "Test Box Auto-Sort",
    "parent"      => :plugins_menu,
    "description" => "Test the Box Auto-Sort functionality",
    "effect"      => proc {
      if $player&.storage
        pbMessage("Testing Box Auto-Sort directly...")
        BoxAutoSort.show_sort_menu($PokemonStorage)
      else
        pbMessage("No storage system available!")
      end
    }
  })
end 