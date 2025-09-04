#===============================================================================
# * Item Ball Printer - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It prints all item ball events
# locations on txt/Output Window.
#
#== INSTALLATION ===============================================================
#
# To this script works, put it above main OR convert into a plugin.
#
#== HOW TO USE =================================================================
#
# The options will appears at debug on pause menu (on "Item options..." 
# submenu). 
#
#=== NOTES =====================================================================
#
# This script doesn't check Common Events.
# 
#===============================================================================

if !PluginManager.installed?("Item Ball Printer")
  PluginManager.register({                                                 
    :name    => "Item Ball Printer",                                        
    :version => "1.1.2",                                                     
    :link    => "https://www.pokecommunity.com/showthread.php?p=10382457",             
    :credits => "FL"
  })
end

module ItemBallPrinter
  # Exported txt file name.
  TXT_FILE_NAME_ITEM_BALLS = "ItemBalls"
  TXT_FILE_NAME_RECEIVE_ITEMS = "ReceiveItems"

  # Sorting mode (besides normal item vs hidden items): 
  # 0 = event id, 1 = item name, 2 = X, 3 = Y
  SORTING = 0
  
  # When false, only check scripts on branches.
  INCLUDE_SCRIPT_COMMANDS = true

  # Include hidden items: 0 = Yes, 1 = No, 2 = Only Hidden Items.
  @@include_hidden_items = 0
  
  def self.include_hidden_items?
    return @@include_hidden_items!=1
  end
  
  def self.include_non_hidden_items?
    return @@include_hidden_items!=2
  end
  
  def self.include_hidden_items
    return @@include_hidden_items
  end
  
  def self.include_hidden_items=(value)
    @@include_hidden_items = value
  end
  
  def self.file_full_name(type = :item_balls)
    case type
    when :item_balls
      return TXT_FILE_NAME_ITEM_BALLS+".txt"
    when :receive_items
      return TXT_FILE_NAME_RECEIVE_ITEMS+".txt"
    end
  end

  def self.print_items(type = :item_balls)
    self.print_current_map(type)
    self.generate_txt(type)
  end

  def self.generate_txt(type = :item_balls)
    string = "Creado el "+Time.now.strftime("%Y-%m-%d %H:%M:%S")
    mapinfos = load_data("Data/MapInfos.rxdata")
    for map_id in 1..999
      item_ball_string = self.get_item_ball_string(map_id, mapinfos, type)
      next if item_ball_string.count("\n") == 0
      string+=sprintf("\n-------------------------------\n%s",item_ball_string)
    end
    File.open(self.file_full_name(type), "w"){|file| file.write(string)}
  end

  def self.print_current_map(type = :item_balls)
    string = self.get_item_ball_string($game_map.map_id, nil, type)
    string+="\nNo item balls" if string.count("\n") == 0
    echoln(string)
  end

  def self.get_item_ball_string(map_id, mapinfos=nil, type = :item_balls)
    mapinfos = load_data(File.join("Data", "MapInfos.rxdata")) if !mapinfos
    map_file_name = sprintf(File.join("Data", "Map%03d.rxdata"), map_id)
    return "" if !FileTest.exist?(map_file_name)
    map = load_data(map_file_name)
    ret = sprintf("Map ID: %03d. %s", map_id, mapinfos[map_id].name)
    event_and_scripts = self.get_events_and_ball_scripts(map.events.values, type)
    for i in 0...event_and_scripts.size
      event = event_and_scripts[i][0]
      script = event_and_scripts[i][1]
      item = script.gsub("pbItemBall","").gsub("(","").gsub(")","").gsub(":","").chomp if type == :item_balls
      item = script.gsub("pbReceiveItem","").gsub("(","").gsub(")","").gsub(":","").chomp if type == :receive_items
      line = sprintf(
        "%03d. ID: %03d (%03d,%03d) item: %s  event: %s", 
        i+1, event.id, event.x, event.y, item, event.name
      )
      ret += "\n"+line
    end
    return ret
  end

  # Return an array of arrays with two items: the valid event, script text with item ball
  def self.get_events_and_ball_scripts(events, type = :item_balls)
    ret = []
    event_name = type == :item_balls ? "pbItemBall" : "pbReceiveItem"
    
    for event in events
      next if !self.include_hidden_items? && self.is_hidden_item?(event)
      next if !self.include_non_hidden_items? && !self.is_hidden_item?(event)
      
      for page_index in 0...event.pages.size
        page = event.pages[page_index]
        
        # Track conditional branch conditions to understand context
        condition_stack = []
        
        command_index = 0
        while command_index < page.list.size
          command = page.list[command_index]
          case command.code
          when 111  # Conditional Branch
            # Parse and track the condition
            condition_text = self.parse_condition(command)
            condition_stack.push(condition_text)
            
            if command.parameters[0] == 12 # Script
              ret.push([event, command.parameters[1]]) if command.parameters[1].include?(event_name)
            end
            
          when 411  # Else
            # Negate the current condition when entering else branch
            if !condition_stack.empty?
              condition_stack[-1] = "NOT(#{condition_stack[-1]})"
            end
            
          when 412  # End branch
            # Pop condition when exiting conditional branch
            condition_stack.pop if !condition_stack.empty?
            
          when 355  # Script
            next if !INCLUDE_SCRIPT_COMMANDS
            script = command.parameters[0]
            
            i = command_index + 1
            # Collect continuation lines (code 655)
            while i < page.list.size && page.list[i].code == 655
              script += ";" + page.list[i].parameters[0] 
              i += 1
            end
            
            if script.include?(event_name)
              # Don't include condition information - just the script
              ret.push([event, script])
            end
            command_index = i - 1  # Skip the continuation lines we already processed
          end
          command_index += 1
        end
      end
    end
    
    return ret.sort{|a,b| 
      self.give_priority_to_event(a[0], a[1]) <=> self.give_priority_to_event(b[0], b[1])
    }
  end

  # Parse condition from conditional branch command
  def self.parse_condition(command)
    case command.parameters[0]
    when 0   # Switch
      switch_id = command.parameters[1]
      state = command.parameters[2] == 0 ? "ON" : "OFF"
      return "Switch #{switch_id} = #{state}"
    when 1   # Variable
      var_id = command.parameters[1]
      value = command.parameters[3]
      op = ["==", ">=", "<=", ">", "<", "!="][command.parameters[4]] || "=="
      return "Variable #{var_id} #{op} #{value}"
    when 2   # Self Switch
      switch_ch = command.parameters[1]
      state = command.parameters[2] == 0 ? "ON" : "OFF"
      return "Self Switch #{switch_ch} = #{state}"
    when 3   # Timer
      return "Timer condition"
    when 6   # Character direction
      return "Character direction condition"
    when 7   # Gold
      return "Gold condition"
    when 11  # Button
      return "Button condition"
    when 12  # Script
      return "Script: #{command.parameters[1]}"
    else
      return "Unknown condition type #{command.parameters[0]}"
    end
  end

  # Return a score for event. Used for sorting events
  def self.give_priority_to_event(event, script)
    if SORTING==1
      ret = script
      ret = "\x7F" + ret if self.is_hidden_item?(event)
    else
      ret = event.id
      if SORTING>1
        ret+=event.x*(SORTING==2 ? 1_000_000 : 1_000) # SORTING==2 means sort by X
        ret+=event.y*(SORTING==3 ? 1_000_000 : 1_000)
      end
      ret+= 1_000_000_000 if self.is_hidden_item?(event)
    end
    return ret
  end

  def self.is_hidden_item?(event)
    return event.name[/hiddenitem/i]
  end

  def self.on_print_current_map_press
    print_current_map
    pbMessage(_INTL("¡Impreso!"))
  end

  def self.on_print_all_press
  end

  def self.on_change_hidden_items_press
    self.include_hidden_items = pbShowCommands(
      nil,
      [_INTL("Sí"), _INTL("No"), _INTL("Solo objetos ocultos")],
      include_hidden_items,
      include_hidden_items
    )
  end
end

MenuHandlers.add(:debug_menu, :item_ball_printer, {
  "parent"      => :items_menu,
  "name"        => _INTL("Imprimir eventos de objetos"),
  "description" => _INTL("Imprime los eventos de objetos en el mapa."),
})

MenuHandlers.add(:debug_menu, :item_ball_print_current_map, {
  "parent"      => :item_ball_printer,
  "name"        => _INTL("Imprimir objetos en mapa actual"),
  "description" => _INTL("Imprime los eventos de objetos en el mapa actual."),
  "effect"      => proc{
    receive_items = pbConfirmMessage(_INTL("¿Quieres imprimir tambien los objetos que dan los NPCs? (pbReceiveItem)"))
    ItemBallPrinter.print_current_map(:item_balls)
    ItemBallPrinter.print_current_map(:receive_items) if receive_items
    pbMessage(_INTL("¡Impreso!"))}
})

MenuHandlers.add(:debug_menu, :item_ball_print_all, {
  "parent"      => :item_ball_printer,
  "name"        => _INTL("Imprime todos los mapas"),
  "description" => _INTL("Imprime todos los mapas en {1}.", ItemBallPrinter.file_full_name),
  "effect"      => proc{
    msgwindow = pbCreateMessageWindow
    if FileTest.exist?(ItemBallPrinter.file_full_name) && !pbConfirmMessageSerious(
       _INTL("{1} ya existe. ¿Quieres sobrescribirlo?",ItemBallPrinter.file_full_name)
    )
      pbDisposeMessageWindow(msgwindow)
      next
    end
    receive_items = pbConfirmMessage(_INTL("¿Quieres imprimir tambien los objetos que dan los NPCs? (pbReceiveItem)"))
    pbMessageDisplay(msgwindow,_INTL("Por favor, espera.\\wtnp[0]"))
    ItemBallPrinter.generate_txt(:item_balls)
    ItemBallPrinter.generate_txt(:receive_items) if receive_items
    pbMessageDisplay(msgwindow,_INTL("¡Impreso!"))
    pbDisposeMessageWindow(msgwindow)
  }
})

MenuHandlers.add(:debug_menu, :item_ball_print_hidden_mode, {
  "parent"      => :item_ball_printer,
  "name"        => _INTL("Cambiar modo de objetos ocultos"),
  "description" => _INTL("Incluir objetos ocultos en la impresión?"),
  "effect"      => proc{
    ItemBallPrinter.include_hidden_items = pbShowCommands(
      nil,
      [_INTL("Sí"), _INTL("No"), _INTL("Solo objetos ocultos")],
      ItemBallPrinter.include_hidden_items,
      ItemBallPrinter.include_hidden_items
    )
  }
})