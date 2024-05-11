#===============================================================================
# Battler Options
#===============================================================================
MenuHandlers.add(:battle_debug_menu, :battlers, {
  "name"        => _INTL("Combatientes..."),
  "parent"      => :main,
  "description" => _INTL("Ver a los Pokémon en combate y cambia sus propiedades.")
})

MenuHandlers.add(:battle_debug_menu, :list_player_battlers, {
  "name"        => _INTL("Pokémon del jugador"),
  "parent"      => :battlers,
  "description" => _INTL("Edita los Pokémon del bando del jugador."),
  "effect"      => proc { |battle|
    battlers = []
    cmds = []
    battle.allSameSideBattlers.each do |b|
      battlers.push(b)
      text = "[#{b.index}] #{b.name}"
      if b.pbOwnedByPlayer?
        text += " (yours)"
      else
        text += " (ally's)"
      end
      cmds.push(text)
    end
    cmd = 0
    loop do
      cmd = pbMessage("\\ts[]" + _INTL("Elige un Pokémon."), cmds, -1, nil, cmd)
      break if cmd < 0
      battle.pbBattlePokemonDebug(battlers[cmd].pokemon, battlers[cmd])
    end
  }
})

MenuHandlers.add(:battle_debug_menu, :list_foe_battlers, {
  "name"        => _INTL("Pokémon del rival"),
  "parent"      => :battlers,
  "description" => _INTL("Edita los Pokémon del bando del rival."),
  "effect"      => proc { |battle|
    battlers = []
    cmds = []
    battle.allOtherSideBattlers.each do |b|
      battlers.push(b)
      cmds.push("[#{b.index}] #{b.name}")
    end
    cmd = 0
    loop do
      cmd = pbMessage("\\ts[]" + _INTL("Elige un Pokémon."), cmds, -1, nil, cmd)
      break if cmd < 0
      battle.pbBattlePokemonDebug(battlers[cmd].pokemon, battlers[cmd])
    end
  }
})

MenuHandlers.add(:battle_debug_menu, :speed_order, {
  "name"        => _INTL("Ver orden de velocidades"),
  "parent"      => :battlers,
  "description" => _INTL("Muestra a todos los combatientes en orden del más rápido al más lento."),
  "effect"      => proc { |battle|
    battlers = battle.allBattlers.map { |b| [b, b.pbSpeed] }
    battlers.sort! { |a, b| b[1] <=> a[1] }
    commands = []
    battlers.each do |value|
      b = value[0]
      commands.push(sprintf("[%d] %s (velocidad: %d)", b.index, b.pbThis, value[1]))
    end
    pbMessage("\\ts[]" + _INTL("Los combatientes se muestran en una lista del más rápido al más lento. La velocidad incluye modificaciones."),
              commands, -1)
  }
})

#===============================================================================
# Pokémon
#===============================================================================
MenuHandlers.add(:battle_debug_menu, :pokemon_teams, {
  "name"        => _INTL("Equipos Pokémon"),
  "parent"      => :main,
  "description" => _INTL("Mira y edita todos los Pokémon de cada equipo."),
  "effect"      => proc { |battle|
    player_party_starts = battle.pbPartyStarts(0)
    foe_party_starts = battle.pbPartyStarts(1)
    cmd = 0
    loop do
      # Find all teams and how many Pokémon they have
      commands = []
      team_indices = []
      if battle.opponent
        battle.opponent.each_with_index do |trainer, i|
          first_index = foe_party_starts[i]
          last_index = (i < foe_party_starts.length - 1) ? foe_party_starts[i + 1] : battle.pbParty(1).length
          num_pkmn = last_index - first_index
          commands.push(_INTL("Oponente {1}: {2} ({3} Pokémon)", i + 1, trainer.full_name, num_pkmn))
          team_indices.push([1, i, first_index])
        end
      else
        commands.push(_INTL("Oponente: {1} Pokémon salvajes", battle.pbParty(1).length))
        team_indices.push([1, 0, 0])
      end
      battle.player.each_with_index do |trainer, i|
        first_index = player_party_starts[i]
        last_index = (i < player_party_starts.length - 1) ? player_party_starts[i + 1] : battle.pbParty(0).length
        num_pkmn = last_index - first_index
        if i == 0   # Player
          commands.push(_INTL("Tú: {1} ({2} Pokémon)", trainer.full_name, num_pkmn))
        else
          commands.push(_INTL("Aliado {1}: {2} ({3} Pokémon)", i, trainer.full_name, num_pkmn))
        end
        team_indices.push([0, i, first_index])
      end
      # Choose a team
      cmd = pbMessage("\\ts[]" + _INTL("Elige un equipo."), commands, -1, nil, cmd)
      break if cmd < 0
      # Pick a Pokémon to look at
      pkmn_cmd = 0
      loop do
        pkmn = []
        pkmn_cmds = []
        battle.eachInTeam(team_indices[cmd][0], team_indices[cmd][1]) do |p|
          pkmn.push(p)
          pkmn_cmds.push("[#{pkmn_cmds.length + 1}] #{p.name} Lv.#{p.level} (HP: #{p.hp}/#{p.totalhp})")
        end
        pkmn_cmd = pbMessage("\\ts[]" + _INTL("Elige un Pokémon."), pkmn_cmds, -1, nil, pkmn_cmd)
        break if pkmn_cmd < 0
        battle.pbBattlePokemonDebug(pkmn[pkmn_cmd],
                                    battle.pbFindBattler(team_indices[cmd][2] + pkmn_cmd, team_indices[cmd][0]))
      end
    end
  }
})

#===============================================================================
# Trainer Options
#===============================================================================
MenuHandlers.add(:battle_debug_menu, :trainers, {
  "name"        => _INTL("Opciones de entrenador..."),
  "parent"      => :main,
  "description" => _INTL("Variables que se aplican a los entrenadores.")
})

MenuHandlers.add(:battle_debug_menu, :trainer_items, {
  "name"        => _INTL("Objetos de entrenadores NPC"),
  "parent"      => :trainers,
  "description" => _INTL("Ver y cambiar los objetos al que cada entrenador NPC tiene acceso."),
  "effect"      => proc { |battle|
    cmd = 0
    loop do
      # Find all NPC trainers and their items
      commands = []
      item_arrays = []
      trainer_indices = []
      if battle.opponent
        battle.opponent.each_with_index do |trainer, i|
          items = battle.items ? battle.items[i].clone : []
          commands.push(_INTL("Oponente {1}: {2} ({3} objetos)", i + 1, trainer.full_name, items.length))
          item_arrays.push(items)
          trainer_indices.push([1, i])
        end
      end
      if battle.player.length > 1
        battle.player.each_with_index do |trainer, i|
          next if i == 0   # Player
          items = battle.ally_items ? battle.ally_items[i].clone : []
          commands.push(_INTL("Aliado {1}: {2} ({3} objetos)", i, trainer.full_name, items.length))
          item_arrays.push(items)
          trainer_indices.push([0, i])
        end
      end
      if commands.length == 0
        pbMessage("\\ts[]" + _INTL("No hay entrenadores NPC en este combate."))
        break
      end
      # Choose a trainer
      cmd = pbMessage("\\ts[]" + _INTL("Elige un entrenador."), commands, -1, nil, cmd)
      break if cmd < 0
      # Get trainer's items
      items = item_arrays[cmd]
      indices = trainer_indices[cmd]
      # Edit trainer's items
      item_list_property = GameDataPoolProperty.new(:Item)
      new_items = item_list_property.set(nil, items)
      if indices[0] == 0   # Ally
        battle.ally_items = [] if !battle.ally_items
        battle.ally_items[indices[1]] = new_items
      else   # Opponent
        battle.items = [] if !battle.items
        battle.items[indices[1]] = new_items
      end
    end
  }
})

MenuHandlers.add(:battle_debug_menu, :mega_evolution, {
  "name"        => _INTL("Megaevolución"),
  "parent"      => :trainers,
  "description" => _INTL("Si cada entrenador puede megaevolucionar."),
  "effect"      => proc { |battle|
    cmd = 0
    loop do
      commands = []
      cmds = []
      battle.megaEvolution.each_with_index do |side_values, side|
        trainers = (side == 0) ? battle.player : battle.opponent
        next if !trainers
        side_values.each_with_index do |value, i|
          next if !trainers[i]
          text = (side == 0) ? "Tu bando:" : "El bando rival:"
          text += sprintf(" %d: %s", i, trainers[i].name)
          text += " [APTO]" if value == -1
          text += " [NO APTO]" if value == -2
          commands.push(text)
          cmds.push([side, i])
        end
      end
      cmd = pbMessage("\\ts[]" + _INTL("Elige entrenador para alternar si pueden o no usar Megaevolución."),
                      commands, -1, nil, cmd)
      break if cmd < 0
      real_cmd = cmds[cmd]
      if battle.megaEvolution[real_cmd[0]][real_cmd[1]] == -1
        battle.megaEvolution[real_cmd[0]][real_cmd[1]] = -2   # Make unable
      else
        battle.megaEvolution[real_cmd[0]][real_cmd[1]] = -1   # Make able
      end
    end
  }
})

#===============================================================================
# Field Options
#===============================================================================
MenuHandlers.add(:battle_debug_menu, :field, {
  "name"        => _INTL("Efectos del campo..."),
  "parent"      => :main,
  "description" => _INTL("Efectos que aplican a todo el campo.")
})

MenuHandlers.add(:battle_debug_menu, :weather, {
  "name"        => _INTL("Clima"),
  "parent"      => :field,
  "description" => _INTL("Define el clima y su duración."),
  "effect"      => proc { |battle|
    weather_types = []
    weather_cmds = []
    GameData::BattleWeather.each do |weather|
      next if weather.id == :None
      weather_types.push(weather.id)
      weather_cmds.push(weather.name)
    end
    cmd = 0
    loop do
      weather_data = GameData::BattleWeather.try_get(battle.field.weather)
      msg = _INTL("Clima actual: {1}", weather_data.name || _INTL("Desconocido"))
      if weather_data.id != :None
        if battle.field.weatherDuration > 0
          msg += "\n"
          msg += _INTL("Duración : {1} ronda(s) más", battle.field.weatherDuration)
        elsif battle.field.weatherDuration < 0
          msg += "\n"
          msg += _INTL("Duración : Infinito")
        end
      end
      cmd = pbMessage("\\ts[]" + msg, [_INTL("Cambiar tipo"),
                                       _INTL("Cambiar duración"),
                                       _INTL("Eliminar clima")], -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Change type
        weather_cmd = weather_types.index(battle.field.weather) || 0
        new_weather = pbMessage(
          "\\ts[]" + _INTL("Elige un nuevo tipo de clima."), weather_cmds, -1, nil, weather_cmd
        )
        if new_weather >= 0
          battle.field.weather = weather_types[new_weather]
          battle.field.weatherDuration = 5 if battle.field.weatherDuration == 0
        end
      when 1   # Change duration
        if battle.field.weather == :None
          pbMessage("\\ts[]" + _INTL("No hay clima."))
          next
        end
        params = ChooseNumberParams.new
        params.setRange(0, 99)
        params.setInitialValue([battle.field.weatherDuration, 0].max)
        params.setCancelValue([battle.field.weatherDuration, 0].max)
        new_duration = pbMessageChooseNumber(
          "\\ts[]" + _INTL("Elige la duración del nuevo clima (0=infinito)."), params
        )
        if new_duration != [battle.field.weatherDuration, 0].max
          battle.field.weatherDuration = (new_duration == 0) ? -1 : new_duration
        end
      when 2   # Clear weather
        battle.field.weather = :None
        battle.field.weatherDuration = 0
      end
    end
  }
})

MenuHandlers.add(:battle_debug_menu, :terrain, {
  "name"        => _INTL("Terreno"),
  "parent"      => :field,
  "description" => _INTL("Define el terreno y su duración."),
  "effect"      => proc { |battle|
    terrain_types = []
    terrain_cmds = []
    GameData::BattleTerrain.each do |terrain|
      next if terrain.id == :None
      terrain_types.push(terrain.id)
      terrain_cmds.push(terrain.name)
    end
    cmd = 0
    loop do
      terrain_data = GameData::BattleTerrain.try_get(battle.field.terrain)
      msg = _INTL("Terreno actual: {1}", terrain_data.name || _INTL("Desconocido"))
      if terrain_data.id != :None
        if battle.field.terrainDuration > 0
          msg += "\n"
          msg += _INTL("Duración : {1} ronda(s) más", battle.field.terrainDuration)
        elsif battle.field.terrainDuration < 0
          msg += "\n"
          msg += _INTL("Duración : Infinito")
        end
      end
      cmd = pbMessage("\\ts[]" + msg, [_INTL("Cambiar tipo"),
                                       _INTL("Cambiar duración"),
                                       _INTL("Eliminar terreno")], -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Change type
        terrain_cmd = terrain_types.index(battle.field.terrain) || 0
        new_terrain = pbMessage(
          "\\ts[]" + _INTL("Elige el nuevo tipo de terreno."), terrain_cmds, -1, nil, terrain_cmd
        )
        if new_terrain >= 0
          battle.field.terrain = terrain_types[new_terrain]
          battle.field.terrainDuration = 5 if battle.field.terrainDuration == 0
        end
      when 1   # Change duration
        if battle.field.terrain == :None
          pbMessage("\\ts[]" + _INTL("No hay terreno."))
          next
        end
        params = ChooseNumberParams.new
        params.setRange(0, 99)
        params.setInitialValue([battle.field.terrainDuration, 0].max)
        params.setCancelValue([battle.field.terrainDuration, 0].max)
        new_duration = pbMessageChooseNumber(
          "\\ts[]" + _INTL("Elige la duración del nuevo terreno (0=infinito)."), params
        )
        if new_duration != [battle.field.terrainDuration, 0].max
          battle.field.terrainDuration = (new_duration == 0) ? -1 : new_duration
        end
      when 2   # Clear terrain
        battle.field.terrain = :None
        battle.field.terrainDuration = 0
      end
    end
  }
})

MenuHandlers.add(:battle_debug_menu, :environment_time, {
  "name"        => _INTL("Ambiente/hora"),
  "parent"      => :field,
  "description" => _INTL("Define el ambiente y hora del día del combate."),
  "effect"      => proc { |battle|
    environment_types = []
    environment_cmds = []
    GameData::Environment.each do |environment|
      environment_types.push(environment.id)
      environment_cmds.push(environment.name)
    end
    cmd = 0
    loop do
      environment_data = GameData::Environment.try_get(battle.environment)
      msg = _INTL("Ambiente: {1}", environment_data.name || _INTL("Desconocido"))
      msg += "\n"
      msg += _INTL("Hora del día: {1}", [_INTL("Día"), _INTL("Tarde"), _INTL("Noche")][battle.time])
      cmd = pbMessage("\\ts[]" + msg, [_INTL("Cambiar ambiente"),
                                       _INTL("Cambiar hora del día")], -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Change environment
        environment_cmd = environment_types.index(battle.environment) || 0
        new_environment = pbMessage(
          "\\ts[]" + _INTL("Elige el nuevo ambiente."), environment_cmds, -1, nil, environment_cmd
        )
        if new_environment >= 0
          battle.environment = environment_types[new_environment]
        end
      when 1   # Change time of day
        new_time = pbMessage("\\ts[]" + _INTL("Elige la nueva hora."),
                             [_INTL("Día"), _INTL("Tarde"), _INTL("Noche")], -1, nil, battle.time)
        battle.time = new_time if new_time >= 0 && new_time != battle.time
      end
    end
  }
})

MenuHandlers.add(:battle_debug_menu, :backdrop, {
  "name"        => _INTL("Nombres del fondo"),
  "parent"      => :field,
  "description" => _INTL("Define los nombres de los gráficos del fondo y las bases."),
  "effect"      => proc { |battle|
    loop do
      cmd = pbMessage("\\ts[]" + _INTL("¿Qué nombre de fondo usar?"),
                      [_INTL("Fondo"),
                       _INTL("Modificador de la base")], -1)
      break if cmd < 0
      case cmd
      when 0   # Backdrop
        text = pbMessageFreeText("\\ts[]" + _INTL("Indica el nombre del fondo."),
                                 battle.backdrop, false, 100, Graphics.width)
        battle.backdrop = (nil_or_empty?(text)) ? "Indoor1" : text
      when 1   # Base modifier
        text = pbMessageFreeText("\\ts[]" + _INTL("Indica el nombre del modificador de la base."),
                                 battle.backdropBase, false, 100, Graphics.width)
        battle.backdropBase = (nil_or_empty?(text)) ? nil : text
      end
    end
  }
})

MenuHandlers.add(:battle_debug_menu, :set_field_effects, {
  "name"        => _INTL("Otros efectos del campo..."),
  "parent"      => :field,
  "description" => _INTL("Ver/definir otros efectos que aplican en todo el campo de batalla."),
  "effect"      => proc { |battle|
    editor = Battle::DebugSetEffects.new(battle, :field)
    editor.update
    editor.dispose
  }
})

MenuHandlers.add(:battle_debug_menu, :player_side, {
  "name"        => _INTL("Efectos del bando del jugador..."),
  "parent"      => :field,
  "description" => _INTL("Efectos que se aplican en el bando en el que está el jugador."),
  "effect"      => proc { |battle|
    editor = Battle::DebugSetEffects.new(battle, :side, 0)
    editor.update
    editor.dispose
  }
})

MenuHandlers.add(:battle_debug_menu, :opposing_side, {
  "name"        => _INTL("Efectos del bando del rival..."),
  "parent"      => :field,
  "description" => _INTL("Efectos que se aplican en el bando en el que están los rivales."),
  "effect"      => proc { |battle|
    editor = Battle::DebugSetEffects.new(battle, :side, 1)
    editor.update
    editor.dispose
  }
})

MenuHandlers.add(:battle_debug_menu, :position_effects, {
  "name"        => _INTL("Efectos de la posición..."),
  "parent"      => :field,
  "description" => _INTL("Efectos que se aplican en la posición individial de los combatientes."),
  "effect"      => proc { |battle|
    positions = []
    cmds = []
    battle.positions.each_with_index do |position, i|
      next if !position
      positions.push(i)
      battler = battle.battlers[i]
      if battler && !battler.fainted?
        text = "[#{i}] #{battler.name}"
      else
        text = "[#{i}] " + _INTL("(vacío)")
      end
      if battler.pbOwnedByPlayer?
        text += " " + _INTL("(tuyos)")
      elsif battle.opposes?(i)
        text += " " + _INTL("(rivales)")
      else
        text += " " + _INTL("(del aliado)")
      end
      cmds.push(text)
    end
    cmd = 0
    loop do
      cmd = pbMessage("\\ts[]" + _INTL("Elige la posición de un combatiente."), cmds, -1, nil, cmd)
      break if cmd < 0
      editor = Battle::DebugSetEffects.new(battle, :position, positions[cmd])
      editor.update
      editor.dispose
    end
  }
})

