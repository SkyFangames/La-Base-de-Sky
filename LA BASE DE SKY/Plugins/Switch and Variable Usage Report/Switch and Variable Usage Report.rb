def pbFindSwitchUsage(id, print = :Console)
	return pbFindSwitchVariable(id, :Switch, print)
end

def pbFindVariableUsage(id, print = :Console)
	return pbFindSwitchVariable(id, :Variable, print)
end

def pbFindSwitchVariable(search_id, type = :Switch, print = :Console)
  mapinfos = pbLoadMapInfos
  lines = []
  mapinfos.keys.sort.each do |map_id|
    map = load_data(sprintf("Data/Map%03d.rxdata", map_id))
    next if !map
    map_string = "\nMap #{map_id} - #{mapinfos[map_id].name}"

    events = map.events
    events_strings = []
    events.keys.sort.each do |event_id|
      event = map.events[event_id]
      event_string = "  Event #{event_id} - #{event.name} [#{event.x}, #{event.y}]"

      pages = event.pages
      pages_strings = []
      pages.each_with_index do |page, page_id|
        page_string = "    Página #{page_id+1}"
        condition_strings = []
        c = page.condition
        case type
        when :Switch
          if c.switch1_valid && c.switch1_id == search_id
            condition_strings.push("        Switch 1")
          end
          if c.switch2_valid && c.switch2_id == search_id
            condition_strings.push("        Switch 2")
          end
        when :Variable
          condition_strings.push("        Variable") if c.variable_valid && c.variable_id == search_id
          
        end
		
        list_strings = []
        list = page.list
        list.each_with_index do |cmd, i|
          line_number = i + 1
          next unless [111,121,122,355,655].include?(cmd.code)
          case cmd.code
          when 111 # Conditional Branch            
            next unless [0, 1, 12].include?(cmd.parameters[0])
            case type
            when :Switch
              list_strings.push("        [Línea #{line_number}] Conditional Branch Switch") if cmd.parameters[0] == 0 && cmd.parameters[1] == search_id
              if cmd.parameters[0] == 12 && cmd.parameters[1].include?("$game_switches[")
                values = cmd.parameters[1].scan(/\$game_switches\[(\d+)\]/i).flatten.map!(&:to_i)
                list_strings.push("        [Línea #{line_number}] Conditional Branch Script command: $game_switches") if values.include?(search_id)
              end
            when :Variable
              list_strings.push("        [Línea #{line_number}] Conditional Branch Variable") if cmd.parameters[0] == 1 && cmd.parameters[1] == search_id
              if cmd.parameters[0] == 12
                if cmd.parameters[1].include?("$game_variables[")
                values = cmd.parameters[1].scan(/\$game_variables\[(\d+)\]/i).flatten.map!(&:to_i)
                  list_strings.push("        [Línea #{line_number}] Conditional Branch Script command: $game_variables") if values.include?(search_id)
                end
                if cmd.parameters[1].include?("pbGet(")
                  values = cmd.parameters[1].scan(/pbGet\((\d+)\)/i).flatten.map!(&:to_i)
                  list_strings.push("        [Línea #{line_number}] Conditional Branch Script command: pbGet") if values.include?(search_id)
                end
                if cmd.parameters[1].include?("pbSet(")
                  values = cmd.parameters[1].scan(/pbSet\((\d+),/i).flatten.map!(&:to_i)
                  list_strings.push("        [Línea #{line_number}] Conditional Branch Script command: pbSet") if values.include?(search_id)
                end
              end
            end
          when 121 # Switches
            if type == :Switch
              if cmd.parameters[0] == cmd.parameters[1]
                list_strings.push("        [Línea #{line_number}] Control Switches command") if cmd.parameters[0] == search_id
              else
                list_strings.push("        [Línea #{line_number}] Control Switches command (Batch)") if search_id.between?(cmd.parameters[0], cmd.parameters[1])
              end
            end
          when 122 # Variables
            if type == :Variable
              if cmd.parameters[0] == cmd.parameters[1]
                list_strings.push("        [Línea #{line_number}] Control Variables command") if cmd.parameters[0] == search_id
              else
                list_strings.push("        [Línea #{line_number}] Control Variables command (Batch)") if search_id.between?(cmd.parameters[0], cmd.parameters[1])
              end
            end
          when 355,655 # Script
            if type == :Switch && cmd.parameters[0].include?("$game_switches[")
              values = cmd.parameters[0].scan(/\$game_switches\[(\d+)\]/i).flatten.map!(&:to_i)
              list_strings.push("        [Línea #{line_number}] Script command: $game_switches") if values.include?(search_id)
            end
            if type == :Variable
              if cmd.parameters[0].include?("$game_variables[")
                values = cmd.parameters[0].scan(/\$game_variables\[(\d+)\]/i).flatten.map!(&:to_i)
                list_strings.push("        [Línea #{line_number}] Script command: $game_variables") if values.include?(search_id)
              end
              if cmd.parameters[0].include?("pbGet(")
                values = cmd.parameters[0].scan(/pbGet\((\d+)\)/i).flatten.map!(&:to_i)
                list_strings.push("        [Línea #{line_number}] Script command: pbGet") if values.include?(search_id)
              end
              if cmd.parameters[0].include?("pbSet(")
                values = cmd.parameters[0].scan(/pbSet\((\d+),/i).flatten.map!(&:to_i)
                list_strings.push("        [Línea #{line_number}] Script command: pbSet") if values.include?(search_id)
              end
            end
          end
        end
        
        page_strings = []
        if !condition_strings.empty?
          page_strings.push("      Conditions")
          page_strings += condition_strings
        end
        if !list_strings.empty?
          page_strings.push("      Event Commands")
          page_strings += list_strings
        end
        next if page_strings.empty?
        pages_strings.push(page_string)
        pages_strings += page_strings
      end
      next if pages_strings.empty?
      events_strings.push(event_string)
      events_strings += pages_strings
    end
    next if events_strings.empty?
    lines.push(map_string)
    lines += events_strings
  end
  
  if lines.empty?
	pbMessage(_INTL("No se encontró uso."))
	return false
  end
  
  case type
  when :Switch
    header =  "==== Uso del Switch #{search_id} en Eventos ===="
    header2 = "=" * header.length
    lines = [header2, header, header2] + lines
    path = "usage_report_switch_#{search_id}.txt"
  when :Variable
    header =  "==== Uso de la Variable #{search_id} en Eventos ===="
    header2 = "=" * header.length
    lines = [header2, header, header2] + lines
    path = "usage_report_variable_#{search_id}.txt"
  end
  case print
  when :Console
    lines.each {|line| echoln line}
  when :File
    File.open(path, "wb") { |f|
      idx = 0
      lines.each do |a|
        f.write(a)
        f.write("\n")
      end
    }
    pbMessage(_INTL("Resultados impresos en {1} en la carpeta del proyecto.", path))
	return true
  end
  
end

class Game_Temp
	attr_accessor :last_searched_switch_for_report
	attr_accessor :last_searched_variable_for_report
end

MenuHandlers.add(:debug_menu, :switch_usage_report, {
  "name"        => _INTL("Reporte de Uso de Switch"),
  "parent"      => :field_menu,
  "description" => _INTL("Encuentra qué eventos usan un switch específico."),
  "effect"      => proc {
	commands = []
	search_id = -1
	cmd = $game_temp.last_searched_switch_for_report || 0
	$data_system.switches.each_with_index do |s, i|
		next if i == 0
		name = sprintf("%04d: ", i, s) + s
		commands.push(name)
	end
	next false if commands.empty?
	ret = pbMessage(_INTL("Search for which switch?"), commands, -1, nil, cmd)
	if ret >= 0
		$game_temp.last_searched_switch_for_report = ret
		search_id = ret + 1
	else
		next false
	end
	commands_type = [_INTL("Console"), _INTL("Text File")]
	type = pbMessage(_INTL("Display the results where?"), commands_type, -1, nil, 0)
	if type >= 0
		next pbFindSwitchUsage(search_id, (type == 0 ? :Console : :File))
	else
		next false
	end
  }
})

MenuHandlers.add(:debug_menu, :variable_usage_report, {
  "name"        => _INTL("Reporte de Uso de Variable"),
  "parent"      => :field_menu,
  "description" => _INTL("Encuentra qué eventos usan una variable específica."),
  "effect"      => proc {
	commands = []
	search_id = -1
	cmd = $game_temp.last_searched_variable_for_report || 0
	$data_system.variables.each_with_index do |v, i|
		next if i == 0
		name = sprintf("%04d: ", i) + v
		commands.push(name)
	end
	next false if commands.empty?
	ret = pbMessage(_INTL("Buscar qué variable?"), commands, -1,  nil, cmd)
	if ret >= 0
		$game_temp.last_searched_variable_for_report = ret
		search_id = ret + 1
	else
		next false
	end
	commands_type = [_INTL("Consola"), _INTL("Archivo de Texto")]
	type = pbMessage(_INTL("¿Dónde quieres que se muestren los resultados?"), commands_type, -1, nil, 0)
	if type >= 0
		next pbFindVariableUsage(search_id, (type == 0 ? :Console : :File))
	else
		next false
	end
  }
})