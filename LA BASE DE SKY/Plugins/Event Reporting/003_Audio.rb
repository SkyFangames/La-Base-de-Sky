module EventReporting
  module_function

  def pbFindAudioUsage(print = :Console, type = :All, search_string = nil)
    if search_string == ""
      search_string = nil 
    elsif search_string
      search_string = search_string.downcase
    end
    mapinfos = pbLoadMapInfos
    lines = []
    mapinfos.keys.sort.each do |map_id|
      map = load_data(sprintf("Data/Map%03d.rxdata", map_id))
      next if !map
      map_string = "\nMapa #{map_id} - #{mapinfos[map_id].name}"

      events = map.events
      events_strings = []
      events.keys.sort.each do |event_id|
        event = map.events[event_id]
        event_string = "  Evento #{event_id} - #{event.name} [#{event.x}, #{event.y}]"

        pages = event.pages
        pages_strings = []
        pages.each_with_index do |page, page_id|
          page_string = "    Página #{page_id+1}"
      
          list_strings = []
          list = page.list
          list.each_with_index do |cmd, i|
            line_number = i + 1
            next unless [241,245,249,250,355,655].include?(cmd.code)
            case cmd.code
            when 241 # BGM
              if [:All, :BGM].include?(type) && cmd.parameters[0]
                file = cmd.parameters[0].name
                next if search_string && !file.downcase.include?(search_string)
                list_strings.push("        [Línea #{line_number}] Play BGM command: '#{file}'")
              end
            when 245 # BGS
              if [:All, :BGS].include?(type) && cmd.parameters[0]
                file = cmd.parameters[0].name
                next if search_string && !file.downcase.include?(search_string)
                list_strings.push("        [Línea #{line_number}] Play BGS command: '#{file}'")
              end
            when 249 # ME
              if [:All, :ME].include?(type) && cmd.parameters[0]
                file = cmd.parameters[0].name
                next if search_string && !file.downcase.include?(search_string)
                list_strings.push("        [Línea #{line_number}] Play ME command: '#{file}'")
              end
            when 250 # SE
              if [:All, :SE].include?(type) && cmd.parameters[0]
                file = cmd.parameters[0].name
                next if search_string && !file.downcase.include?(search_string)
                list_strings.push("        [Línea #{line_number}] Play SE command: '#{file}'")
              end
            when 355,655 # Script
              if [:All, :BGM].include?(type) && cmd.parameters[0].include?("pbBGMPlay(")
                values = cmd.parameters[0].scan(/pbBGMPlay\(([^)]*)\)/).map(&:first)
                values.map! { |v| v[/^"([^"]*)"/, 1]&.downcase}
                value_string = ""
                values.each_with_index do |v, i|
                  value_string += ", " if i > 0
                  value_string += "'#{v}'"
                end
                if search_string
                  list_strings.push("        [Línea #{line_number}] Script command: pbBGMPlay - #{value_string}") if values.any? { |s| s.include?(search_string) }
                else
                  value_string = ""
                  values.each_with_index do |v, i|
                    value_string += ", " if i > 0
                    value_string += "'#{v}'"
                  end
                  list_strings.push("        [Línea #{line_number}] Script command: pbBGMPlay - #{value_string}")
                end
              end
              if [:All, :BGS].include?(type) && cmd.parameters[0].include?("pbBGSPlay(")
                values = cmd.parameters[0].scan(/pbBGSPlay\(([^)]*)\)/).map(&:first)
                values.map! { |v| v[/^"([^"]*)"/, 1]&.downcase}
                value_string = ""
                values.each_with_index do |v, i|
                  value_string += ", " if i > 0
                  value_string += "'#{v}'"
                end
                if search_string
                  list_strings.push("        [Línea #{line_number}] Script command: pbBGSPlay - #{value_string}") if values.any? { |s| s.include?(search_string) }
                else
                  value_string = ""
                  values.each_with_index do |v, i|
                    value_string += ", " if i > 0
                    value_string += "'#{v}'"
                  end
                  list_strings.push("        [Línea #{line_number}] Script command: pbBGSPlay - #{value_string}")
                end
              end
              if [:All, :ME].include?(type) && cmd.parameters[0].include?("pbMEPlay(")
                values = cmd.parameters[0].scan(/pbMEPlay\(([^)]*)\)/).map(&:first)
                values.map! { |v| v[/^"([^"]*)"/, 1]&.downcase}
                value_string = ""
                values.each_with_index do |v, i|
                  value_string += ", " if i > 0
                  value_string += "'#{v}'"
                end
                if search_string
                  list_strings.push("        [Línea #{line_number}] Script command: pbMEPlay - #{value_string}") if values.any? { |s| s.include?(search_string) }
                else
                  list_strings.push("        [Línea #{line_number}] Script command: pbMEPlay - #{value_string}")
                end
              end
              if [:All, :SE].include?(type) && cmd.parameters[0].include?("pbSEPlay(")
                values = cmd.parameters[0].scan(/pbSEPlay\(([^)]*)\)/).map(&:first)
                values.map! { |v| v[/^"([^"]*)"/, 1]&.downcase}
                value_string = ""
                values.each_with_index do |v, i|
                  value_string += ", " if i > 0
                  value_string += "'#{v}'"
                end
                if search_string
                  list_strings.push("        [Línea #{line_number}] Script command: pbSEPlay - #{value_string}") if values.any? { |s| s.include?(search_string) }
                else
                  value_string = ""
                  values.each_with_index do |v, i|
                    value_string += ", " if i > 0
                    value_string += "'#{v}'"
                  end
                  list_strings.push("        [Línea #{line_number}] Script command: pbSEPlay - #{value_string}")
                end
              end
            end
          end
          
          page_strings = []
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
      pbMessage(_INTL("No se encontraron usos."))
      return false
    end
    
    case type
    when :All
      if search_string
        header =  "==== Todos los usos de Audio '#{search_string}' ===="
        header2 = "=" * header.length
        lines = [header2, header, header2] + lines
        path = "usage_report_audio_all_string.txt"
      else
        header =  "==== Todos los usos de Audio ===="
        header2 = "=" * header.length
        lines = [header2, header, header2] + lines
        path = "usage_report_audio_all.txt"
      end
    when :BGM
      header =  "==== Usos de pbPlayBGM ===="
      header2 = "=" * header.length
      lines = [header2, header, header2] + lines
      path = "usage_report_audio_bgm.txt"
    when :BGS
      header =  "==== Usos de pbPlayBGS ===="
      header2 = "=" * header.length
      lines = [header2, header, header2] + lines
      path = "usage_report_audio_bgs.txt"
    when :ME
      header =  "==== Usos de pbPlayME ===="
      header2 = "=" * header.length
      lines = [header2, header, header2] + lines
      path = "usage_report_audio_me.txt"
    when :SE
      header =  "==== Usos de pbPlaySE ===="
      header2 = "=" * header.length
      lines = [header2, header, header2] + lines
      path = "usage_report_audio_se.txt"
    end
    print_info(print, lines, path)    
  end
end