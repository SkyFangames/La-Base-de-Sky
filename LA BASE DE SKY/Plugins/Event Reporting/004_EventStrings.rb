module EventReporting
  module_function

  def pbFindCommentUsage(search_string, print = :Console)
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

        name_strings = []
        n = event.name.downcase
        name_strings.push("        El nombre del evento incluye '#{search_string}'") if n.include?(search_string)
        pages = event.pages
        pages_strings = []
        pages_strings += name_strings if !name_strings.empty?
        pages.each_with_index do |page, page_id|
          page_string = "    Página #{page_id+1}"
      
          list_strings = []
          list = page.list
          list.each_with_index do |cmd, i|
            line_number = i + 1
            next unless [108,408,355,655].include?(cmd.code)
            case cmd.code
            when 108,408 # Comments
              if cmd.parameters[0].downcase.include?(search_string)
                list_strings.push("        [Línea #{line_number}] Comando de comentario: '#{cmd.parameters[0]}'")
              end
            when 355,655 # Script
              comment = cmd.parameters[0].split("#", 2)[1]&.downcase
              if comment&.include?(search_string)
                list_strings.push("        [Línea #{line_number}] Comentario de comando de script: '#{cmd.parameters[0]}'")
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
      pbMessage(_INTL("No usage found."))
      return false
    end
    
    header =  "==== Comentario '#{search_string}' en Eventos ===="
    header2 = "=" * header.length
    lines = [header2, header, header2] + lines
    path = "usage_report_comments.txt"
    print_info(print, lines, path, true)    
  end

end