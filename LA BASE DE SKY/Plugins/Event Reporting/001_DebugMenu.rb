MenuHandlers.add(:debug_menu, :event_report_menu, {
  "name"        => _INTL("Reportes de eventos..."),
  "parent"      => :main,
  "description" => _INTL("Generar reportes para localizar eventos con información específica."),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :switch_usage_report, {
  "name"        => _INTL("Reporte de uso de Interruptor"),
  "parent"      => :event_report_menu,
  "description" => _INTL("Encontrar qué eventos usan un interruptor específico."),
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
    ret = pbMessage(_INTL("¿Buscar qué interruptor?"), commands, -1, nil, cmd)
    if ret >= 0
      $game_temp.last_searched_switch_for_report = ret
      search_id = ret + 1
    else
      next false
    end
    type = EventReporting.choose_print
    if type >= 0
      next EventReporting.pbFindSwitchUsage(search_id, (type == 0 ? :Console : :File))
    else
      next false
    end
  }
})

MenuHandlers.add(:debug_menu, :variable_usage_report, {
  "name"        => _INTL("Reporte de uso de Variable"),
  "parent"      => :event_report_menu,
  "description" => _INTL("Encontrar qué eventos usan una variable específica."),
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
    ret = pbMessage(_INTL("¿Buscar qué variable?"), commands, -1,  nil, cmd)
    if ret >= 0
      $game_temp.last_searched_variable_for_report = ret
      search_id = ret + 1
    else
      next false
    end
    type = EventReporting.choose_print
    if type >= 0
      next EventReporting.pbFindVariableUsage(search_id, (type == 0 ? :Console : :File))
    else
      next false
    end
  }
})

MenuHandlers.add(:debug_menu, :audio_usage_report, {
  "name"        => _INTL("Reporte de uso de Audio"),
  "parent"      => :event_report_menu,
  "description" => _INTL("Encontrar qué eventos usan comandos de audio."),
  "effect"      => proc {
    commands = []
    cmdAll = -1
    cmdAllString = -1
    cmdBGM = -1
    cmdBGS = -1
    cmdME = -1
    cmdSE = -1
    commands[cmdAll = commands.length] = _INTL("Todos los comandos")
    commands[cmdAllString = commands.length] = _INTL("Todos los comandos - texto específica")
    commands[cmdBGM = commands.length] = _INTL("pbBGMPlay")
    commands[cmdBGS = commands.length] = _INTL("pbBGSPlay")
    commands[cmdME = commands.length] = _INTL("pbMEPlay")
    commands[cmdSE = commands.length] = _INTL("pbSEPlay")
    ret = pbMessage(_INTL("¿Buscar qué comando?"), commands, -1,  nil, 0)
    string = ""
    case ret
    when cmdAll
      type = EventReporting.choose_print
      if type >= 0
        next EventReporting.pbFindAudioUsage((type == 0 ? :Console : :File), :All)
      else
        next false
      end
    when cmdAllString
      last_string = $game_temp.last_searched_audio_for_report || ""
      string = pbMessageFreeText(_INTL("¿Buscar qué texto?"), last_string, false, 250, Graphics.width)
      if string == ""
        pbMessage(_INTL("No puedes buscar un texto vacío."))
        next false
      else
        $game_temp.last_searched_audio_for_report = string
      end
      type = EventReporting.choose_print
      if type >= 0
        next EventReporting.pbFindAudioUsage((type == 0 ? :Console : :File), :All, string)
      else
        next false
      end
    when cmdBGM
      files = []
      Dir.chdir("Audio/BGM/") do
        Dir.glob("*.ogg") { |f| files.push(f) }
        Dir.glob("*.wav") { |f| files.push(f) }
        Dir.glob("*.mid") { |f| files.push(f) }
        Dir.glob("*.midi") { |f| files.push(f) }
        Dir.glob("*.mp3") { |f| files.push(f) }
      end
      files.map! { |f| "'" + File.basename(f, ".*") + "'" }
      files.uniq!
      files.sort! { |a, b| a.downcase <=> b.downcase }
      next false if files.empty?
      ret = pbMessage(_INTL("¿Buscar qué BGM?"), [_INTL("Todos los BGM")] + files, -1,  nil, 0)
      if ret > 0
        string = files[ret - 1]
      elsif ret < 0
        next false
      end
      type = EventReporting.choose_print
      if type >= 0
        next EventReporting.pbFindAudioUsage((type == 0 ? :Console : :File), :BGM, string)
      else
        next false
      end
    when cmdBGS
      files = []
      Dir.chdir("Audio/BGS/") do
        Dir.glob("*.ogg") { |f| files.push(f) }
        Dir.glob("*.wav") { |f| files.push(f) }
        Dir.glob("*.mid") { |f| files.push(f) }
        Dir.glob("*.midi") { |f| files.push(f) }
        Dir.glob("*.mp3") { |f| files.push(f) }
      end
      files.map! { |f| "'" + File.basename(f, ".*") + "'" }
      files.uniq!
      files.sort! { |a, b| a.downcase <=> b.downcase }
      next false if files.empty?
      ret = pbMessage(_INTL("¿Buscar qué BGS?"), [_INTL("Todos los BGS")] + files, -1,  nil, 0)
      if ret > 0
        string = files[ret - 1]
      elsif ret < 0
        next false
      end
      type = EventReporting.choose_print
      if type >= 0
        next EventReporting.pbFindAudioUsage((type == 0 ? :Console : :File), :BGS, string)
      else
        next false
      end
    when cmdME
      files = []
      Dir.chdir("Audio/ME/") do
        Dir.glob("*.ogg") { |f| files.push(f) }
        Dir.glob("*.wav") { |f| files.push(f) }
        Dir.glob("*.mid") { |f| files.push(f) }
        Dir.glob("*.midi") { |f| files.push(f) }
        Dir.glob("*.mp3") { |f| files.push(f) }
      end
      files.map! { |f| "'" + File.basename(f, ".*") + "'" }
      files.uniq!
      files.sort! { |a, b| a.downcase <=> b.downcase }
      next false if files.empty?
      ret = pbMessage(_INTL("¿Buscar qué ME?"), [_INTL("Todos los ME")] + files, -1,  nil, 0)
      if ret > 0
        string = files[ret - 1]
      elsif ret < 0
        next false
      end
      type = EventReporting.choose_print
      if type >= 0
        next EventReporting.pbFindAudioUsage((type == 0 ? :Console : :File), :ME, string)
      else
        next false
      end
    when cmdSE
      files = []
      Dir.chdir("Audio/SE/") do
        Dir.glob("*.ogg") { |f| files.push(f) }
        Dir.glob("*.wav") { |f| files.push(f) }
        Dir.glob("*.mid") { |f| files.push(f) }
        Dir.glob("*.midi") { |f| files.push(f) }
        Dir.glob("*.mp3") { |f| files.push(f) }
      end
      files.map! { |f| "'" + File.basename(f, ".*") + "'" }
      files.uniq!
      files.sort! { |a, b| a.downcase <=> b.downcase }
      next false if files.empty?
      ret = pbMessage(_INTL("¿Buscar qué SE?"), [_INTL("Todos los SE")] + files, -1,  nil, 0)
      if ret > 0
        string = files[ret - 1]
      elsif ret < 0
        next false
      end
      type = EventReporting.choose_print
      if type >= 0
        next EventReporting.pbFindAudioUsage((type == 0 ? :Console : :File), :SE, string)
      else
        next false
      end
    else
      next false
    end
  }
})

MenuHandlers.add(:debug_menu, :event_comment_usage_report, {
  "name"        => _INTL("Reporte de uso de Comentario de Evento"),
  "parent"      => :event_report_menu,
  "description" => _INTL("Busca comentarios con un texto específico en los eventos."),
  "effect"      => proc {
    last_string = $game_temp.last_searched_comment_for_report || ""
    string = pbMessageFreeText(_INTL("¿Qué texto buscar en los nombres de eventos, comandos de comentario o comentarios de comandos de script (después de #)?"), last_string, false, 250, Graphics.width)
    if string == ""
      pbMessage(_INTL("No puedes buscar un texto vacío."))
      next false
    else
      $game_temp.last_searched_comment_for_report = string
    end
    type = EventReporting.choose_print
    if type >= 0
      next EventReporting.pbFindCommentUsage(string.downcase, (type == 0 ? :Console : :File))
    else
      next false
    end
  }
})

class Game_Temp
	attr_accessor :last_searched_switch_for_report
	attr_accessor :last_searched_variable_for_report
	attr_accessor :last_searched_audio_for_report
	attr_accessor :last_searched_comment_for_report
end