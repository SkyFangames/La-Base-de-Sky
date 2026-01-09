#===============================================================================
# SISTEMA DE BÚSQUEDA AVANZADA
# Créditos: wrigty12, KRLW890, Zik
#===============================================================================

#-------------------------------------------------------------------------------
# 1. Utilidades de Búsqueda.
#-------------------------------------------------------------------------------

# Removedor de acentos
def pbRemoveAccents(text)
  return "" if text.nil?
  text = text.to_s
  return text.tr(
    "ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÑñÇç",
    "AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuNnCc"
  )
end

# Algoritmo de Levenshtein
def pbLevenshtein(first, second)
  matrix = [(0..first.length).to_a]
  (1..second.length).each do |j|
    matrix << [j] + [0] * first.length
  end

  (1..second.length).each do |i|
    (1..first.length).each do |j|
      if first[j-1] == second[i-1]
        matrix[i][j] = matrix[i-1][j-1]
      else
        matrix[i][j] = [
          matrix[i-1][j],    # Borrado
          matrix[i][j-1],    # Inserción
          matrix[i-1][j-1],  # Sustitución
        ].min + 1
      end
    end
  end
  return matrix.last.last
end

# Lógica de coincidencia por si se escribe mal una palabra
def pbSmartMatch?(text, search_term)
  # Limpieza básica
  text_clean = pbRemoveAccents(text.to_s).downcase
  term_clean = pbRemoveAccents(search_term.to_s).downcase
  
  # Coincidencia exacta parcial
  return true if text_clean.include?(term_clean)
  
  # Si el término es muy corto, exigimos coincidencia exacta
  return false if term_clean.length <= 2
  
  # Tolerancia de errores
  tolerance = (term_clean.length >= 6) ? 2 : 1

  # Dividimos el nombre del objeto en palabras para buscar similitudes
  words = text_clean.split(" ")
  words.each do |word|
     if (word.length - term_clean.length).abs <= tolerance
       dist = pbLevenshtein(word, term_clean)
       return true if dist <= tolerance
     end
  end
  
  # Busqueda de frases completas si las longitudes son similares
  if (text_clean.length - term_clean.length).abs <= tolerance + 2
      dist_full = pbLevenshtein(text_clean, term_clean)
      return true if dist_full <= tolerance
  end
  
  return false
end

def pbOpenGenericListSearch
    term = pbMessageFreeText(_INTL("¿Qué desea buscar?"), "", false, 32)
    return nil if term.nil? || term.empty?
    return term
end

#-------------------------------------------------------------------------------
# 2. pbChooseList
#-------------------------------------------------------------------------------
def pbChooseList(commands, default = 0, cancelValue = -1, sortType = 1)
    cmdwin = pbListWindow([])
    itemID = default
    itemIndex = 0
    sortMode = (sortType >= 0) ? sortType : 0
    sorting = true
    
    full_list_original = commands.clone
    current_search_term = nil

    loop do
      if sorting
        temp_commands = full_list_original.clone
        
        if current_search_term
          # Filtramos en una variable temporal
          filtered = full_list_original.select do |cmd|
            pbSmartMatch?(cmd[1], current_search_term)
          end
          
          if filtered.empty?
            pbMessage(_INTL("No se han encontrado resultados para '{1}'.", current_search_term))
            current_search_term = nil
            temp_commands = full_list_original.clone # Volvemos a mostrar todo
          else
            temp_commands = filtered
          end
        end
        
        commands = temp_commands

        # Ordenamiento
        case sortMode
        when 0 then commands.sort! { |a, b| a[0] <=> b[0] }
        when 1 then commands.sort! { |a, b| a[1] <=> b[1] }
        end

        # Posición
        if itemID.is_a?(Symbol)
          commands.each_with_index { |command, i| itemIndex = i if command[2] == itemID }
        elsif itemID && itemID > 0
          commands.each_with_index { |command, i| itemIndex = i if command[0] == itemID }
        end
        
        itemIndex = 0 if itemIndex >= commands.length

        # Generar
        realcommands = []
        commands.each do |command|
          if sortType <= 0
            realcommands.push(sprintf("%03d: %s", command[0], command[1]))
          else
            realcommands.push(command[1])
          end
        end
        sorting = false
      end

      cmd = pbCommandsSortable(cmdwin, realcommands, -1, itemIndex, (sortType < 0))
      
      case cmd[0]
      when 0
        if cmd[1] < 0
          itemID = cancelValue
        else
          itemID = (commands[cmd[1]][2] || commands[cmd[1]][0])
        end
        break
      when 1
        if commands.length > 0
            itemID = commands[cmd[1]][2] || commands[cmd[1]][0]
        end
        sortMode = (sortMode + 1) % 2
        sorting = true
      when 2
        current_search_term = cmd[1]
        sorting = true
        itemIndex = 0
      end
    end
    cmdwin.dispose
    return itemID
end
  
def pbCommandsSortable(cmdwindow, commands, cmdIfCancel, defaultindex = -1, sortable = false)
    cmdwindow.commands = commands
    cmdwindow.index    = defaultindex if defaultindex >= 0
    cmdwindow.index    = 0 if cmdwindow.index >= commands.length 
    
    cmdwindow.x        = 0
    cmdwindow.y        = 0
    cmdwindow.width    = Graphics.width / 2 if cmdwindow.width < Graphics.width / 2
    cmdwindow.height   = Graphics.height
    cmdwindow.z        = 99999
    cmdwindow.active   = true
    command = 0
    
    loop do
      Graphics.update
      Input.update
      cmdwindow.update
      
      if Input.trigger?(Input::ACTION) && sortable
        command = [1, cmdwindow.index]
        break
      elsif Input.trigger?(Input::BACK)
        command = [0, (cmdIfCancel > 0) ? cmdIfCancel - 1 : cmdIfCancel]
        break
      elsif Input.triggerex?(:F)
          searchTerm = pbOpenGenericListSearch
          if searchTerm
            command = [2, searchTerm]
            break
          end
      elsif Input.trigger?(Input::USE)
        command = [0, cmdwindow.index]
        break
      end
    end
    ret = command
    cmdwindow.active = false
    return ret
end

#-------------------------------------------------------------------------------
# 3. pbListScreen
#-------------------------------------------------------------------------------
def pbListScreen(title, lister)
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  list = pbListWindow([])
  list.viewport = viewport
  list.z        = 2
  title = Window_UnformattedTextPokemon.newWithSize(
    title, Graphics.width / 2, 0, Graphics.width / 2, 64, viewport
  )
  title.z = 2
  lister.setViewport(viewport)
  selectedmap = -1
  
  full_original_list = lister.commands.clone
  
  commands = lister.commands
  selindex = lister.startIndex
  if commands.length == 0
    value = lister.value(-1)
    lister.dispose
    title.dispose
    list.dispose
    viewport.dispose
    return value
  end
  list.commands = commands
  list.index    = selindex
  
  loop do
    Graphics.update
    Input.update
    list.update
    if list.index != selectedmap
      lister.refresh(list.index)
      selectedmap = list.index
    end
    
    if Input.trigger?(Input::BACK)
      selectedmap = -1
      break
    elsif Input.triggerex?(:F)
        searchTerm = pbOpenGenericListSearch
        if searchTerm
            newSearch = full_original_list.select do |cmd|
                pbSmartMatch?(cmd.to_s, searchTerm)
            end
            
            if newSearch.length > 0
                lister.commands_override = newSearch
                list.commands = lister.commands
                list.index = 0
                lister.refresh(0)
                selectedmap = -1
            else
                pbMessage(_INTL("No se han encontrado resultados."))
            end
        end
    elsif Input.trigger?(Input::USE)
      break
    end
  end
  
  value = lister.value(selectedmap)
  lister.dispose
  title.dispose
  list.dispose
  viewport.dispose
  Input.update
  return value
end

#-------------------------------------------------------------------------------
# 4. pbListScreenBlock
#-------------------------------------------------------------------------------
def pbListScreenBlock(title, lister)
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  list = pbListWindow([], Graphics.width / 2)
  list.viewport = viewport
  list.z        = 2
  title = Window_UnformattedTextPokemon.newWithSize(
    title, Graphics.width / 2, 0, Graphics.width / 2, 64, viewport
  )
  title.z = 2
  lister.setViewport(viewport)
  selectedmap = -1
  
  # Lista Maestra
  full_original_list = lister.commands.clone
  
  commands = lister.commands
  selindex = lister.startIndex
  if commands.length == 0
    value = lister.value(-1)
    lister.dispose
    title.dispose
    list.dispose
    viewport.dispose
    return value
  end
  list.commands = commands
  list.index = selindex
  
  loop do
    Graphics.update
    Input.update
    list.update
    if list.index != selectedmap
      lister.refresh(list.index)
      selectedmap = list.index
    end
    
    if Input.trigger?(Input::ACTION)
      yield(Input::ACTION, lister.value(selectedmap))
      list.commands = lister.commands
      list.index = list.commands.length if list.index == list.commands.length
      lister.refresh(list.index)
    elsif Input.trigger?(Input::BACK)
      break
    elsif Input.triggerex?(:F) # BÚSQUEDA AÑADIDA AQUÍ
        searchTerm = pbOpenGenericListSearch
        if searchTerm
            clean_term = pbRemoveAccents(searchTerm).downcase
            newSearch = full_original_list.select do |cmd|
                pbSmartMatch?(cmd.to_s, searchTerm)
            end
            
            if newSearch.length > 0
                lister.commands_override = newSearch
                list.commands = lister.commands
                list.index = 0
                lister.refresh(0)
                selectedmap = -1
            else
                pbMessage(_INTL("No hay resultados."))
            end
        end
    elsif Input.trigger?(Input::USE)
      yield(Input::USE, lister.value(selectedmap))
      list.commands = lister.commands
      list.index = list.commands.length if list.index == list.commands.length
      lister.refresh(list.index)
    end
  end
  lister.dispose
  title.dispose
  list.dispose
  viewport.dispose
  Input.update
end

#-------------------------------------------------------------------------------
# 5. Inyección automática de búsqueda en los Listers
#-------------------------------------------------------------------------------

# Para no repetir código, y agregar facilmente futuros listers si se requiere
TARGET_LISTERS = [
  :SpeciesLister,
  :ItemLister,
  :MoveLister,
  :AbilityLister,
  :TrainerTypeLister,
  :TrainerBattleLister,
  :MapLister,
  :GraphicsLister,
  :MusicFileLister
]

TARGET_LISTERS.each do |klass_name|
  next unless Object.const_defined?(klass_name)
  klass = Object.const_get(klass_name)
  
  klass.class_eval do
    def commands_override=(value)
        @commands_override = value
        @needs_id_refresh = true
    end

    # Alias del método original
    unless method_defined?(:commands_original_for_search)
      alias_method :commands_original_for_search, :commands
    end

    def commands
        if @commands_override
            if @needs_id_refresh
                new_ids = []
                new_maps = []

                # Obtenemos la lista completa original
                original_cmds = commands_original_for_search
                original_offset = (defined?(@addGlobalOffset)) ? @addGlobalOffset : 0
                
                # Reconstruimos los IDs basándonos en el índice original
                @commands_override.each do |cmd| 
                  original_index = original_cmds.index(cmd)
                  if original_index
                    if defined?(@ids) && @ids
                        new_ids.push(@ids[original_index]) 
                    end
                  if defined?(@maps) && @maps
                      # Calculamos el índice real en el array @maps original
                      map_real_index = original_index - original_offset
                      if map_real_index >= 0 && map_real_index < @maps.length
                        new_maps.push(@maps[map_real_index])
                      end
                    end
                  end
                end
                
                if defined?(@ids) && @ids
                    @ids = new_ids
                end
                if defined?(@maps) && @maps
                  @maps = new_maps
                  @addGlobalOffset = 0 if defined?(@addGlobalOffset)
                end
                @needs_id_refresh = false
            end
            return @commands_override 
        end
        return commands_original_for_search
    end
  end
end