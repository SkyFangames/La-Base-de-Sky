#===============================================================================
# CREDITOS
# wrigty12, KRLW890
#===============================================================================
#-------------------------------------------------------------------------------
# Funciones de búsqueda rápida para listas
#-------------------------------------------------------------------------------
# Based on KRLW890's Better Battle Animation Editor https://reliccastle.com/resources/1314/
def pbOpenGenericListSearch(commands, type = 0)
    term = pbMessageFreeText(_INTL("¿Qué desea buscar?"), "", false, 32)
    return false if term == "" || term == nil
    stack = 1
    newSearch = []
    commands.length.times do |i|
        if commands[i].downcase.include?(term.downcase)
          newSearch[newSearch.length] = (type == 0 ? i : commands[i]) # 0 = index, 1 = string
        end
    end
    if newSearch.length < 1
      pbMessage(_INTL("No hay resultados."))
      return []
    else
      return newSearch
    end
    return []
end

#-------------------------------------------------------------------------------
# Listado Básico
#-------------------------------------------------------------------------------
def pbChooseList(commands, default = 0, cancelValue = -1, sortType = 1)
    cmdwin = pbListWindow([])
    itemID = default
    itemIndex = 0
    sortMode = (sortType >= 0) ? sortType : 0   # 0=ID, 1=alphabetical
    sorting = true
    loop do
      if sorting
        case sortMode
        when 0
          commands.sort! { |a, b| a[0] <=> b[0] }
        when 1
          commands.sort! { |a, b| a[1] <=> b[1] }
        end
        if itemID.is_a?(Symbol)
          commands.each_with_index { |command, i| itemIndex = i if command[2] == itemID }
        elsif itemID && itemID > 0
          commands.each_with_index { |command, i| itemIndex = i if command[0] == itemID }
        end
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
      when 0   # Eligió una acción o canceló
        itemID = (cmd[1] < 0) ? cancelValue : (commands[cmd[1]][2] || commands[cmd[1]][0])
        break
      when 1   # Habilita/Deshabilita el ordenamiento
        itemID = commands[cmd[1]][2] || commands[cmd[1]][0]
        sortMode = (sortMode + 1) % 2
        sorting = true
      when 2 # Agregado para búsqueda rápida
        old_commands ||= commands.clone
        commands = []
        cmd[1].each { |val| commands.push(old_commands[val]) }
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
      elsif Input.triggerex?(:F) #Added for quick search
          newSearch = pbOpenGenericListSearch(commands)
          if newSearch != false && newSearch != nil && newSearch.length > 0
            command = [2, newSearch]
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
# Bloque de Listas
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
      elsif Input.triggerex?(:F) # Agregado para búsqueda rápida
        newSearch = pbOpenGenericListSearch(list.commands, 1)
        if newSearch != false && newSearch != nil && newSearch.length > 0
            lister.commands_override = newSearch
            list.commands = lister.commands
            lister.refresh(0)
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

# Setting command overwrites for listers
class SpeciesLister

    def commands_override=(value)
        @commands_override = value
        @needs_id_refresh = true
    end

    alias tdw_debug_search_commands_s commands
    def commands
        if @commands_override
            if @needs_id_refresh
                new_ids = []
                @commands_override.each { |cmd| new_ids.push(@ids[@commands.index(cmd)]) }
                @ids = new_ids
                @needs_id_refresh = false
            end
            return @commands_override 
        end
        return tdw_debug_search_commands_s
    end
end
class ItemLister

    def commands_override=(value)
        @commands_override = value
        @needs_id_refresh = true
    end

    alias tdw_debug_search_commands_i commands
    def commands
        if @commands_override
            if @needs_id_refresh
                new_ids = []
                @commands_override.each { |cmd| new_ids.push(@ids[@commands.index(cmd)]) }
                @ids = new_ids
                @needs_id_refresh = false
            end
            return @commands_override 
        end
        return tdw_debug_search_commands_i
    end
end
class TrainerTypeLister

    def commands_override=(value)
        @commands_override = value
        @needs_id_refresh = true
    end

    alias tdw_debug_search_commands_tt commands
    def commands
        if @commands_override
            if @needs_id_refresh
                new_ids = []
                @commands_override.each { |cmd| new_ids.push(@ids[@commands.index(cmd)]) }
                @ids = new_ids
                @needs_id_refresh = false
            end
            return @commands_override 
        end
        return tdw_debug_search_commands_tt
    end
end
class TrainerBattleLister

    def commands_override=(value)
        @commands_override = value
        @needs_id_refresh = true
    end

    alias tdw_debug_search_commands_tb commands
    def commands
        if @commands_override
            if @needs_id_refresh
                new_ids = []
                @commands_override.each { |cmd| new_ids.push(@ids[@commands.index(cmd)]) }
                @ids = new_ids
                @needs_id_refresh = false
            end
            return @commands_override 
        end
        return tdw_debug_search_commands_tb
    end
end
