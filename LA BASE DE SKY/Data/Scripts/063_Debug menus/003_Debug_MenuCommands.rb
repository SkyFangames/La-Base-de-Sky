#===============================================================================
# Field options
#===============================================================================
MenuHandlers.add(:debug_menu, :field_menu, {
  "name"        => _INTL("Opciones de campo..."),
  "parent"      => :main,
  "description" => _INTL("Saltar a otro mapa, editar interruptores/variables, usar el PC, editar la Guardería, etc."),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :warp, {
  "name"        => _INTL("Saltar a mapa"),
  "parent"      => :field_menu,
  "description" => _INTL("Saltar instantáneamente a otro mapa que elijas."),
  "effect"      => proc { |sprites, viewport|
    map = pbWarpToMap
    next false if !map
    pbFadeOutAndHide(sprites)
    pbDisposeMessageWindow(sprites["textbox"])
    pbDisposeSpriteHash(sprites)
    viewport.dispose
    if $scene.is_a?(Scene_Map)
      $game_temp.player_new_map_id    = map[0]
      $game_temp.player_new_x         = map[1]
      $game_temp.player_new_y         = map[2]
      $game_temp.player_new_direction = 2
      $scene.transfer_player
    else
      pbCancelVehicles
      $map_factory.setup(map[0])
      $game_player.moveto(map[1], map[2])
      $game_player.turn_down
      $game_map.update
      $game_map.autoplay
    end
    $game_map.refresh
    next true   # Closes the debug menu to allow the warp
  }
})

MenuHandlers.add(:debug_menu, :use_pc, {
  "name"        => _INTL("Usar PC"),
  "parent"      => :field_menu,
  "description" => _INTL("Usa un PC para acceder el almacenamiento de Pokémon y el PC del jugador."),
  "effect"      => proc {
    pbPokeCenterPC
  }
})

MenuHandlers.add(:debug_menu, :switches, {
  "name"        => _INTL("Interruptores"),
  "parent"      => :field_menu,
  "description" => _INTL("Editar todos los Interruptores del juego (excepto Interruptores de Scripts)."),
  "effect"      => proc {
    pbDebugVariables(0)
  }
})

MenuHandlers.add(:debug_menu, :variables, {
  "name"        => _INTL("Variables"),
  "parent"      => :field_menu,
  "description" => _INTL("Editar todas las Variables del juego. Se pueden establecer con números o texto."),
  "effect"      => proc {
    pbDebugVariables(1)
  }
})

MenuHandlers.add(:debug_menu, :safari_zone_and_bug_contest, {
  "name"        => _INTL("Zona Safari y Concurso de Captura de Bichos"),
  "parent"      => :field_menu,
  "description" => _INTL("Editar pasos/tiempo restante y el número de Poké Balls restantes."),
  "effect"      => proc {
    if pbInSafari?
      safari = pbSafariState
      cmd = 0
      loop do
        cmds = [_INTL("Pasos restantes: {1}", (Settings::SAFARI_STEPS > 0) ? safari.steps : _INTL("infinito")),
                GameData::Item.get(:SAFARIBALL).name_plural + ": " + safari.ballcount.to_s]
        cmd = pbShowCommands(nil, cmds, -1, cmd)
        break if cmd < 0
        case cmd
        when 0   # Steps remaining
          if Settings::SAFARI_STEPS > 0
            params = ChooseNumberParams.new
            params.setRange(0, 99999)
            params.setDefaultValue(safari.steps)
            safari.steps = pbMessageChooseNumber(_INTL("Establece los pasos restantes en esta partida de Safari."), params)
          end
        when 1   # Safari Balls
          params = ChooseNumberParams.new
          params.setRange(0, 99999)
          params.setDefaultValue(safari.ballcount)
          safari.ballcount = pbMessageChooseNumber(
            _INTL("Elige la cantidad de {1}.", GameData::Item.get(:SAFARIBALL).name_plural), params)
        end
      end
    elsif pbInBugContest?
      contest = pbBugContestState
      cmd = 0
      loop do
        cmds = []
        if Settings::BUG_CONTEST_TIME > 0
          time_left = Settings::BUG_CONTEST_TIME - (System.uptime - contest.timer_start).to_i
          time_left = 0 if time_left < 0
          min = time_left / 60
          sec = time_left % 60
          time_string = _ISPRINTF("{1:02d}m {2:02d}s", min, sec)
        else
          time_string = _INTL("infinito")
        end
        cmds.push(_INTL("Tiempo restante: {1}", time_string))
        cmds.push(GameData::Item.get(:SPORTBALL).name_plural + ": " + contest.ballcount.to_s)
        cmd = pbShowCommands(nil, cmds, -1, cmd)
        break if cmd < 0
        case cmd
        when 0   # Steps remaining
          if Settings::BUG_CONTEST_TIME > 0
            params = ChooseNumberParams.new
            params.setRange(0, 99999)
            params.setDefaultValue(min)
            new_time = pbMessageChooseNumber(_INTL("Establece el tiempo restante (en minutos) en este Concurso de Captura de Bichos."), params)
            contest.timer_start += (new_time - min) * 60
            $scene.spriteset.usersprites.each do |sprite|
              next if !sprite.is_a?(TimerDisplay)
              sprite.start_time = contest.timer_start
              break
            end
          end
        when 1   # Safari Balls
          params = ChooseNumberParams.new
          params.setRange(0, 99999)
          params.setDefaultValue(contest.ballcount)
          contest.ballcount = pbMessageChooseNumber(
            _INTL("Establece la cantidad de {1}.", GameData::Item.get(:SPORTBALL).name_plural), params)
        end
      end
    else
      pbMessage(_INTL("¡No estás en la Zona Safari 0 en un Concurso de Captura de Bichos!"))
    end
  }
})

MenuHandlers.add(:debug_menu, :edit_field_effects, {
  "name"        => _INTL("Cambiar efectos de campo"),
  "parent"      => :field_menu,
  "description" => _INTL("Editar pasos de Repelente, uso de Fuerza y Destello, y efectos de flauta Negra/Blanca."),
  "effect"      => proc {
    cmd = 0
    loop do
      cmds = []
      cmds.push(_INTL("Pasos de repelente: {1}", $PokemonGlobal.repel))
      cmds.push(($PokemonMap.strengthUsed ? "[X]" : "[  ]") + " " + _INTL("Fuerza usada"))
      cmds.push(($PokemonGlobal.flashUsed ? "[X]" : "[  ]") + " " + _INTL("Destello usado"))
      cmds.push(($PokemonMap.lower_encounter_rate ? "[X]" : "[  ]") + " " + _INTL("Ratio de encuentro bajo"))
      cmds.push(($PokemonMap.higher_encounter_rate ? "[X]" : "[  ]") + " " + _INTL("Ratio de encuentro alto"))
      cmds.push(($PokemonMap.lower_level_wild_pokemon ? "[X]" : "[  ]") + " " + _INTL("Pokémon salvajes con nivel bajo"))
      cmds.push(($PokemonMap.higher_level_wild_pokemon ? "[X]" : "[  ]") + " " + _INTL("Pokémon salvajes con nivel alto"))
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      break if cmd < 0
      case cmd
      when 0   # Repel steps
        params = ChooseNumberParams.new
        params.setRange(0, 99999)
        params.setDefaultValue($PokemonGlobal.repel)
        $PokemonGlobal.repel = pbMessageChooseNumber(_INTL("Elige el nivel del Pokémon."), params)
      when 1   # Strength used
        $PokemonMap.strengthUsed = !$PokemonMap.strengthUsed
      when 2   # Flash used
        if $game_map.metadata&.dark_map && $scene.is_a?(Scene_Map)
          $PokemonGlobal.flashUsed = !$PokemonGlobal.flashUsed
          darkness = $game_temp.darkness_sprite
          darkness.dispose if darkness && !darkness.disposed?
          $game_temp.darkness_sprite = DarknessSprite.new
          $scene.spriteset&.addUserSprite($game_temp.darkness_sprite)
          if $PokemonGlobal.flashUsed
            $game_temp.darkness_sprite.radius = $game_temp.darkness_sprite.radiusMax
          end
        else
          pbMessage(_INTL("¡No estás en un mapa oscuro!"))
        end
      when 3   # Lower encounter rate
        $PokemonMap.lower_encounter_rate ||= false
        $PokemonMap.lower_encounter_rate = !$PokemonMap.lower_encounter_rate
      when 4   # Higher encounter rate
        $PokemonMap.higher_encounter_rate ||= false
        $PokemonMap.higher_encounter_rate = !$PokemonMap.higher_encounter_rate
      when 5   # Lower level wild Pokémon
        $PokemonMap.lower_level_wild_pokemon ||= false
        $PokemonMap.lower_level_wild_pokemon = !$PokemonMap.lower_level_wild_pokemon
      when 6   # Higher level wild Pokémon
        $PokemonMap.higher_level_wild_pokemon ||= false
        $PokemonMap.higher_level_wild_pokemon = !$PokemonMap.higher_level_wild_pokemon
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :refresh_map, {
  "name"        => _INTL("Actualizar mapa"),
  "parent"      => :field_menu,
  "description" => _INTL("Actualiza todos los eventos y eventos comunes del mapa."),
  "effect"      => proc {
    $game_map.need_refresh = true
    pbMessage(_INTL("Se va a actualizar el mapa."))
  }
})

MenuHandlers.add(:debug_menu, :day_care, {
  "name"        => _INTL("Guardería"),
  "parent"      => :field_menu,
  "description" => _INTL("Ver Pokémon en la Guardaría y editarlos."),
  "effect"      => proc {
    pbDebugDayCare
  }
})

MenuHandlers.add(:debug_menu, :storage_wallpapers, {
  "name"        => _INTL("Alternar fondos del almacenamiento"),
  "parent"      => :field_menu,
  "description" => _INTL("Desbloquea y bloquea los fondos especiales del sistema de almacenamiento (PC)."),
  "effect"      => proc {
    w = $PokemonStorage.allWallpapers
    if w.length <= PokemonStorage::BASICWALLPAPERQTY
      pbMessage(_INTL("No se han definido fondos del PC especiales."))
    else
      paperscmd = 0
      unlockarray = $PokemonStorage.unlockedWallpapers
      loop do
        paperscmds = []
        paperscmds.push(_INTL("Desbloquear todos"))
        paperscmds.push(_INTL("Bloquear todos"))
        (PokemonStorage::BASICWALLPAPERQTY...w.length).each do |i|
          paperscmds.push((unlockarray[i] ? "[X]" : "[  ]") + " " + w[i])
        end
        paperscmd = pbShowCommands(nil, paperscmds, -1, paperscmd)
        break if paperscmd < 0
        case paperscmd
        when 0   # Unlock all
          (PokemonStorage::BASICWALLPAPERQTY...w.length).each do |i|
            unlockarray[i] = true
          end
        when 1   # Lock all
          (PokemonStorage::BASICWALLPAPERQTY...w.length).each do |i|
            unlockarray[i] = false
          end
        else
          paperindex = paperscmd - 2 + PokemonStorage::BASICWALLPAPERQTY
          unlockarray[paperindex] = !$PokemonStorage.unlockedWallpapers[paperindex]
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :skip_credits, {
  "name"        => _INTL("Saltar créditos"),
  "parent"      => :field_menu,
  "description" => _INTL("Alterna si los créditos se pueden saltar con el botón Usar."),
  "effect"      => proc {
    $PokemonGlobal.creditsPlayed = !$PokemonGlobal.creditsPlayed
    pbMessage(_INTL("Los créditos se pueden saltar cuando se vean en el futuro.")) if $PokemonGlobal.creditsPlayed
    pbMessage(_INTL("Los créditos no se pueden saltar la próxima vez que se vean.")) if !$PokemonGlobal.creditsPlayed
  }
})

#===============================================================================
# Battle options
#===============================================================================
MenuHandlers.add(:debug_menu, :battle_menu, {
  "name"        => _INTL("Opciones de combate..."),
  "parent"      => :main,
  "description" => _INTL("Empezar combate, resetear entrenadores del mapa, editar Pokémon errantes, etc."),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :test_wild_battle, {
  "name"        => _INTL("Testear combate salvaje"),
  "parent"      => :battle_menu,
  "description" => _INTL("Empezar combate individual contra un Pokémon salvaje. Eliges la especie/nivel."),
  "effect"      => proc {
    species = pbChooseSpeciesList
    if species
      params = ChooseNumberParams.new
      params.setRange(1, GameData::GrowthRate.max_level)
      params.setInitialValue(5)
      params.setCancelValue(0)
      level = pbMessageChooseNumber(_INTL("Elige el nivel del {1} salvaje.",
                                          GameData::Species.get(species).name), params)
      if level > 0
        $game_temp.encounter_type = nil
        setBattleRule("canLose")
        WildBattle.start(species, level)
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :test_wild_battle_advanced, {
  "name"        => _INTL("Testear combate salvaje (avanzado)"),
  "parent"      => :battle_menu,
  "description" => _INTL("Empezar combate contra 1 o más Pokémon salvajes. Puedes elegir el tamaño del bando."),
  "effect"      => proc {
    pkmn = []
    size0 = 1
    pkmnCmd = 0
    loop do
      pkmnCmds = []
      pkmn.each { |p| pkmnCmds.push(sprintf("%s Nv.%d", p.name, p.level)) }
      pkmnCmds.push(_INTL("[Añadir Pokémon]"))
      pkmnCmds.push(_INTL("[Elegir tamaño bando jugador]"))
      pkmnCmds.push(_INTL("[Empezar combate {1}vs{2}]", size0, pkmn.length))
      pkmnCmd = pbShowCommands(nil, pkmnCmds, -1, pkmnCmd)
      break if pkmnCmd < 0
      if pkmnCmd == pkmnCmds.length - 1      # Start battle
        if pkmn.length == 0
          pbMessage(_INTL("No se han elegido Pokémon, no se puede empezar el combate."))
          next
        end
        setBattleRule(sprintf("%dv%d", size0, pkmn.length))
        setBattleRule("canLose")
        $game_temp.encounter_type = nil
        WildBattle.start(*pkmn)
        break
      elsif pkmnCmd == pkmnCmds.length - 2   # Set player side size
        if !pbCanDoubleBattle?
          pbMessage(_INTL("Solo tienes un Pokémon."))
          next
        end
        maxVal = (pbCanTripleBattle?) ? 3 : 2
        params = ChooseNumberParams.new
        params.setRange(1, maxVal)
        params.setInitialValue(size0)
        params.setCancelValue(0)
        newSize = pbMessageChooseNumber(
          _INTL("Elige el número de combatientes del bando del jugador (máx. {1}).", maxVal), params
        )
        size0 = newSize if newSize > 0
      elsif pkmnCmd == pkmnCmds.length - 3   # Add Pokémon
        species = pbChooseSpeciesList
        if species
          params = ChooseNumberParams.new
          params.setRange(1, GameData::GrowthRate.max_level)
          params.setInitialValue(5)
          params.setCancelValue(0)
          level = pbMessageChooseNumber(_INTL("Elige el nivel del {1} salvaje.",
                                              GameData::Species.get(species).name), params)
          if level > 0
            pkmn.push(pbGenerateWildPokemon(species, level))
            size0 = pkmn.length
          end
        end
      else                                   # Edit a Pokémon
        if pbConfirmMessage(_INTL("¿Cambiar este Pokémon?"))
          scr = PokemonDebugPartyScreen.new
          scr.pbPokemonDebug(pkmn[pkmnCmd], -1, nil, true)
          scr.pbEndScreen
        elsif pbConfirmMessage(_INTL("¿Eliminar este Pokémon?"))
          pkmn.delete_at(pkmnCmd)
          size0 = [pkmn.length, 1].max
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :test_trainer_battle, {
  "name"        => _INTL("Testear combate entrenador"),
  "parent"      => :battle_menu,
  "description" => _INTL("Empieza un combate contra el entrenador que tú elijas."),
  "effect"      => proc {
    trainerdata = pbListScreen(_INTL("ENTRENADOR INDIVIDUAL"), TrainerBattleLister.new(0, false))
    if trainerdata
      setBattleRule("canLose")
      TrainerBattle.start(trainerdata[0], trainerdata[1], trainerdata[2])
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :test_trainer_battle_advanced, {
  "name"        => _INTL("Testear combate entrenador (avanzado)"),
  "parent"      => :battle_menu,
  "description" => _INTL("Empieza un combate contra 1 o más entrenadores con el tamaño de cada bando que elijas."),
  "effect"      => proc {
    trainers = []
    size0 = 1
    size1 = 1
    trainerCmd = 0
    loop do
      trainerCmds = []
      trainers.each { |t| trainerCmds.push(sprintf("%s x%d", t[1].full_name, t[1].party_count)) }
      trainerCmds.push(_INTL("[Añadir entrenador]"))
      trainerCmds.push(_INTL("[Elegir tamaño bando jugador]"))
      trainerCmds.push(_INTL("[Elegir tamaño bando rival]"))
      trainerCmds.push(_INTL("[Empezar batalla {1}vs{2}]", size0, size1))
      trainerCmd = pbShowCommands(nil, trainerCmds, -1, trainerCmd)
      break if trainerCmd < 0
      if trainerCmd == trainerCmds.length - 1      # Start battle
        if trainers.length == 0
          pbMessage(_INTL("No se han elegido entrenadores, no se puede empezar el combate."))
          next
        elsif size1 < trainers.length
          pbMessage(_INTL("Tamaño del bando rival no válido. Debe ser al menos {1}.", trainers.length))
          next
        elsif size1 > trainers.length && trainers[0][1].party_count == 1
          pbMessage(
            _INTL("El tamaño del bando rival no puede ser {1}, ya que eso requiere que el primer entrenador tenga 2 o más Pokémon.",
                  size1)
          )
          next
        end
        setBattleRule(sprintf("%dv%d", size0, size1))
        setBattleRule("canLose")
        battleArgs = []
        trainers.each { |t| battleArgs.push(t[1]) }
        TrainerBattle.start(*battleArgs)
        break
      elsif trainerCmd == trainerCmds.length - 2   # Set opponent side size
        if trainers.length == 0 || (trainers.length == 1 && trainers[0][1].party_count == 1)
          pbMessage(_INTL("O no se han elegido entrenadores o el entrenador solo tiene un Pokémon."))
          next
        end
        maxVal = 2
        maxVal = 3 if trainers.length >= 3 ||
                      (trainers.length == 2 && trainers[0][1].party_count >= 2) ||
                      trainers[0][1].party_count >= 3
        params = ChooseNumberParams.new
        params.setRange(1, maxVal)
        params.setInitialValue(size1)
        params.setCancelValue(0)
        newSize = pbMessageChooseNumber(
          _INTL("Elige el número de combatientes del bando del rival (máx. {1}).", maxVal), params
        )
        size1 = newSize if newSize > 0
      elsif trainerCmd == trainerCmds.length - 3   # Set player side size
        if !pbCanDoubleBattle?
          pbMessage(_INTL("Solo tienes un Pokémon."))
          next
        end
        maxVal = (pbCanTripleBattle?) ? 3 : 2
        params = ChooseNumberParams.new
        params.setRange(1, maxVal)
        params.setInitialValue(size0)
        params.setCancelValue(0)
        newSize = pbMessageChooseNumber(
          _INTL("Elige el número de combatientes del bando del jugador (máx. {1}).", maxVal), params
        )
        size0 = newSize if newSize > 0
      elsif trainerCmd == trainerCmds.length - 4   # Add trainer
        trainerdata = pbListScreen(_INTL("ELIGE UN ENTRENADOR"), TrainerBattleLister.new(0, false))
        if trainerdata
          tr = pbLoadTrainer(trainerdata[0], trainerdata[1], trainerdata[2])
          EventHandlers.trigger(:on_trainer_load, tr)
          trainers.push([0, tr])
          size0 = trainers.length
          size1 = trainers.length
        end
      else                                         # Edit a trainer
        if pbConfirmMessage(_INTL("¿Cambiar este entrenador?"))
          trainerdata = pbListScreen(_INTL("ELIGE UN ENTRENADOR"),
                                     TrainerBattleLister.new(trainers[trainerCmd][0], false))
          if trainerdata
            tr = pbLoadTrainer(trainerdata[0], trainerdata[1], trainerdata[2])
            EventHandlers.trigger(:on_trainer_load, tr)
            trainers[trainerCmd] = [0, tr]
          end
        elsif pbConfirmMessage(_INTL("¿Eliminar este entrenador?"))
          trainers.delete_at(trainerCmd)
          size0 = [trainers.length, 1].max
          size1 = [trainers.length, 1].max
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :encounter_version, {
  "name"        => _INTL("Elegir la versión de encuentros salvajes"),
  "parent"      => :battle_menu,
  "description" => _INTL("Elige qué versión de encuentros salvajes debe usarse."),
  "effect"      => proc {
    params = ChooseNumberParams.new
    params.setRange(0, 99)
    params.setInitialValue($PokemonGlobal.encounter_version)
    params.setCancelValue(-1)
    value = pbMessageChooseNumber(_INTL("¿Qué número de versión de encuentros usar?"), params)
    $PokemonGlobal.encounter_version = value if value >= 0
  }
})

MenuHandlers.add(:debug_menu, :roamers, {
  "name"        => _INTL("Pokémon errante"),
  "parent"      => :battle_menu,
  "description" => _INTL("Activa y edita los Pokémon errantes."),
  "effect"      => proc {
    pbDebugRoamers
  }
})

MenuHandlers.add(:debug_menu, :reset_trainers, {
  "name"        => _INTL("Reiniciar entrenadores del mapa"),
  "parent"      => :battle_menu,
  "description" => _INTL("Apaga los interruptores locales A y B de todos los eventos con \"Trainer\" en su nombre."),
  "effect"      => proc {
    if $game_map
      $game_map.events.each_value do |event|
        if event.name[/trainer/i]
          $game_self_switches[[$game_map.map_id, event.id, "A"]] = false
          $game_self_switches[[$game_map.map_id, event.id, "B"]] = false
        end
      end
      $game_map.need_refresh = true
      pbMessage(_INTL("Se han reseteado todos los entrenadores del mapa."))
    else
      pbMessage(_INTL("Este comando no se puede usar aquí."))
    end
  }
})

MenuHandlers.add(:debug_menu, :toggle_exp_all, {
  "name"        => _INTL("Alterna el efecto del Rep. Exp. Global"),
  "parent"      => :battle_menu,
  "description" => _INTL("Alterna el efecto de dar experiencia del Rep. Exp. Global a Pokémon que no participen en combate."),
  "effect"      => proc {
    $player.has_exp_all = !$player.has_exp_all
    pbMessage(_INTL("Activa el efecto del Rep. Exp. Global.")) if $player.has_exp_all
    pbMessage(_INTL("Desactiva el efecto del Rep. Exp. Global.")) if !$player.has_exp_all
  }
})

MenuHandlers.add(:debug_menu, :toggle_logging, {
  "name"        => _INTL("Alterna los log de los mensajes en batalla"),
  "parent"      => :battle_menu,
  "description" => _INTL("Guarda los logs del debug para comhates en Data/debuglog.txt."),
  "effect"      => proc {
    $INTERNAL = !$INTERNAL
    pbMessage(_INTL("Hacer logs de Debug de combates en la carpeta Data.")) if $INTERNAL
    pbMessage(_INTL("No hacer logs de Debug para combates.")) if !$INTERNAL
  }
})

#===============================================================================
# Pokémon options
#===============================================================================
MenuHandlers.add(:debug_menu, :pokemon_menu, {
  "name"        => _INTL("Opciones de Pokémon..."),
  "parent"      => :main,
  "description" => _INTL("Curar el equipo, dar Pokémon, llenar/vaciar el PC, etc."),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :heal_party, {
  "name"        => _INTL("Curar equipo"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("Restaura completamente los PS/estado/PP de los Pokémon del equipo."),
  "effect"      => proc {
    $player.party.each { |pkmn| pkmn.heal }
    pbMessage(_INTL("Tus Pokémon se han curado completamente."))
  }
})

MenuHandlers.add(:debug_menu, :add_pokemon, {
  "name"        => _INTL("Añadir Pokémon"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("Entregarte un Pokémon con el nivel que elijas. Si no tienes espacio, lo envía al PC."),
  "effect"      => proc {
    species = pbChooseSpeciesList
    if species
      params = ChooseNumberParams.new
      params.setRange(1, GameData::GrowthRate.max_level)
      params.setInitialValue(5)
      params.setCancelValue(0)
      level = pbMessageChooseNumber(_INTL("Elige el nivel del Pokémon."), params)
      if level > 0
        goes_to_party = !$player.party_full?
        if pbAddPokemonSilent(species, level)
          if goes_to_party
            pbMessage(_INTL("{1} se ha añadido a tu equipo.", GameData::Species.get(species).name))
          else
            pbMessage(_INTL("{1} se ha añadido al PC.", GameData::Species.get(species).name))
          end
        else
          pbMessage(_INTL("No se puede añadir el Pokémon porque tu equipo y el PC están llenos."))
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :fill_boxes, {
  "name"        => _INTL("Llenar cajas del PC"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("Llena el PC con un Pokémon de cada especie (al nivel 50)."),
  "effect"      => proc {
    added = 0
    box_qty = $PokemonStorage.maxPokemon(0)
    completed = true
    GameData::Species.each do |species_data|
      sp = species_data.species
      f = species_data.form
      # Record each form of each species as seen and owned
      if f == 0
        if species_data.single_gendered?
          g = (species_data.gender_ratio == :AlwaysFemale) ? 1 : 0
          $player.pokedex.register(sp, g, f, 0, false)
          $player.pokedex.register(sp, g, f, 1, false)
        else   # Both male and female
          $player.pokedex.register(sp, 0, f, 0, false)
          $player.pokedex.register(sp, 0, f, 1, false)
          $player.pokedex.register(sp, 1, f, 0, false)
          $player.pokedex.register(sp, 1, f, 1, false)
        end
        $player.pokedex.set_owned(sp, false)
      elsif species_data.real_form_name && !species_data.real_form_name.empty?
        g = (species_data.gender_ratio == :AlwaysFemale) ? 1 : 0
        $player.pokedex.register(sp, g, f, 0, false)
        $player.pokedex.register(sp, g, f, 1, false)
      end
      # Add Pokémon (if form 0, i.e. one of each species)
      next if f != 0
      if added >= Settings::NUM_STORAGE_BOXES * box_qty
        completed = false
        next
      end
      added += 1
      $PokemonStorage[(added - 1) / box_qty, (added - 1) % box_qty] = Pokemon.new(sp, 50)
    end
    $player.pokedex.refresh_accessible_dexes
    pbMessage(_INTL("Las cajas del PC se han llenado con un Pokémon de cada especie."))
    if !completed
      pbMessage(_INTL("Nota: El número de espacio en el PC ({1} cajas de {2}) es menor que el número de especies.",
                      Settings::NUM_STORAGE_BOXES, box_qty))
    end
  }
})

MenuHandlers.add(:debug_menu, :clear_boxes, {
  "name"        => _INTL("Vaciar cajas del PC"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("Eliminar todos los Pokémon del PC."),
  "effect"      => proc {
    $PokemonStorage.maxBoxes.times do |i|
      $PokemonStorage.maxPokemon(i).times do |j|
        $PokemonStorage[i, j] = nil
      end
    end
    pbMessage(_INTL("Las cajas del PC se han vaciado."))
  }
})

def darEquipoDePrueba()
  party = []
    species = [:PIKACHU, :PIDGEOTTO, :KADABRA, :GYARADOS, :DIGLETT, :CHANSEY]
    species.each { |id| party.push(id) if GameData::Species.exists?(id) }
    $player.party.clear
    # Generate Pokémon of each species at level 20
    party.each do |spec|
      pkmn = Pokemon.new(spec, 20)
      $player.party.push(pkmn)
      $player.pokedex.register(pkmn)
      $player.pokedex.set_owned(spec)
      case spec
      when :PIDGEOTTO
        pkmn.learn_move(:FLY)
      when :KADABRA
        pkmn.learn_move(:FLASH)
        pkmn.learn_move(:TELEPORT)
      when :GYARADOS
        pkmn.learn_move(:SURF)
        pkmn.learn_move(:DIVE)
        pkmn.learn_move(:WATERFALL)
      when :DIGLETT
        pkmn.learn_move(:DIG)
        pkmn.learn_move(:CUT)
        pkmn.learn_move(:HEADBUTT)
        pkmn.learn_move(:ROCKSMASH)
      when :CHANSEY
        pkmn.learn_move(:SOFTBOILED)
        pkmn.learn_move(:STRENGTH)
        pkmn.learn_move(:SWEETSCENT)
      end
      pkmn.record_first_moves
    end
end

MenuHandlers.add(:debug_menu, :give_demo_party, {
  "name"        => _INTL("Dar equipo de prueba"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("Te da 6 Pokémon predefinidos. Sobreescriben el equipo actual."),
  "effect"      => proc {
    darEquipoDePrueba()
    pbMessage(_INTL("Equipo entregado con Pokémon de prueba."))
  }
})

MenuHandlers.add(:debug_menu, :quick_hatch_party_eggs, {
  "name"        => _INTL("Reducir pasos de Huevos del equipo"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("Hace que los Huevos del equipo solo necesiten un paso para abrirse."),
  "effect"      => proc {
    $player.party.each { |pkmn| pkmn.steps_to_hatch = 1 if pkmn.egg? }
    pbMessage(_INTL("Todos los Huevos de tu equipo ahora requieren un único paso para abrirse."))
  }
})

MenuHandlers.add(:debug_menu, :open_storage, {
  "name"        => _INTL("Acceder al sistema de almacenamiento (PC)"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("Abre el sistema de almacenamiento en modo 'Mover Pokémon'."),
  "effect"      => proc {
    pbFadeOutIn do
      scene = PokemonStorageScene.new
      screen = PokemonStorageScreen.new(scene, $PokemonStorage)
      screen.pbStartScreen(0)
    end
  }
})

#===============================================================================
# Shadow Pokémon options
#===============================================================================
MenuHandlers.add(:debug_menu, :shadow_pokemon_menu, {
  "name"        => _INTL("Opciones de Pokémon Oscuros..."),
  "parent"      => :pokemon_menu,
  "description" => _INTL("PokéCepo y purificación."),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :toggle_snag_machine, {
  "name"        => _INTL("Alternar PokéCepo"),
  "parent"      => :shadow_pokemon_menu,
  "description" => _INTL("Alterna que todas las Poké Ball puedan capturar Pokémon Oscuros."),
  "effect"      => proc {
    $player.has_snag_machine = !$player.has_snag_machine
    pbMessage(_INTL("Activar el PokéCepo.")) if $player.has_snag_machine
    pbMessage(_INTL("Perder el PokéCepo.")) if !$player.has_snag_machine
  }
})

MenuHandlers.add(:debug_menu, :toggle_purify_chamber_access, {
  "name"        => _INTL("Alternar acceso a la Cámara de Purificación"),
  "parent"      => :shadow_pokemon_menu,
  "description" => _INTL("Alterna el acceso a la Cámara de Purificación a través del PC."),
  "effect"      => proc {
    $player.seen_purify_chamber = !$player.seen_purify_chamber
    pbMessage(_INTL("Acceso activado a la Cámara de Purificación.")) if $player.seen_purify_chamber
    pbMessage(_INTL("Acceso revocado a la Cámara de Purificación.")) if !$player.seen_purify_chamber
  }
})

MenuHandlers.add(:debug_menu, :purify_chamber, {
  "name"        => _INTL("Usar Cámara de Purificación"),
  "parent"      => :shadow_pokemon_menu,
  "description" => _INTL("Abre la Cámara de Purificación para purificar a Pokémon Oscuros."),
  "effect"      => proc {
    pbPurifyChamber
  }
})

MenuHandlers.add(:debug_menu, :relic_stone, {
  "name"        => _INTL("Usar Pilar Legendario"),
  "parent"      => :shadow_pokemon_menu,
  "description" => _INTL("Elige un Pokémon Oscuro para ser mostrado en el Pilar Legendario para purificarlo."),
  "effect"      => proc {
    pbRelicStone
  }
})

#===============================================================================
# Item options
#===============================================================================
MenuHandlers.add(:debug_menu, :items_menu, {
  "name"        => _INTL("Opciones de Objetos..."),
  "parent"      => :main,
  "description" => _INTL("Dar y quitar objetos."),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :add_item, {
  "name"        => _INTL("Añadir objeto"),
  "parent"      => :items_menu,
  "description" => _INTL("Elige un Objeto y la cantidad para añadirlo en la Mochila."),
  "effect"      => proc {
    pbListScreenBlock(_INTL("AÑADIR OBJETO"), ItemLister.new) do |button, item|
      if button == Input::USE && item
        params = ChooseNumberParams.new
        params.setRange(1, Settings::BAG_MAX_PER_SLOT)
        params.setInitialValue(1)
        params.setCancelValue(0)
        qty = pbMessageChooseNumber(_INTL("¿Cuántos {1} añadir?",
                                          GameData::Item.get(item).name_plural), params)
        if qty > 0
          $bag.add(item, qty)
          pbMessage(_INTL("Has entregado {1}x {2}.", qty, GameData::Item.get(item).name))
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :fill_bag, {
  "name"        => _INTL("Llenar Mochila"),
  "parent"      => :items_menu,
  "description" => _INTL("Vacía la Mochila y la llena con la cantidad de objetos de cada uno que elijas."),
  "effect"      => proc {
    params = ChooseNumberParams.new
    params.setRange(1, Settings::BAG_MAX_PER_SLOT)
    params.setInitialValue(1)
    params.setCancelValue(0)
    qty = pbMessageChooseNumber(_INTL("Elige el número de objetos."), params)
    if qty > 0
      $bag.clear
      # NOTE: This doesn't simply use $bag.add for every item in turn, because
      #       that's really slow when done in bulk.
      pocket_sizes = Settings::BAG_MAX_POCKET_SIZE
      bag = $bag.pockets   # Called here so that it only rearranges itself once
      GameData::Item.each do |i|
        next if !pocket_sizes[i.pocket - 1] || pocket_sizes[i.pocket - 1] == 0
        next if pocket_sizes[i.pocket - 1] > 0 && bag[i.pocket].length >= pocket_sizes[i.pocket - 1]
        item_qty = (i.is_important?) ? 1 : qty
        bag[i.pocket].push([i.id, item_qty])
      end
      # NOTE: Auto-sorting pockets don't need to be sorted afterwards, because
      #       items are added in the same order they would be sorted into.
      pbMessage(_INTL("Se ha llenado la mochila con {1} de cada objeto.", qty))
    end
  }
})

MenuHandlers.add(:debug_menu, :empty_bag, {
  "name"        => _INTL("Vaciar Mochila"),
  "parent"      => :items_menu,
  "description" => _INTL("Elimina todos los objetos de la Mochila."),
  "effect"      => proc {
    $bag.clear
    pbMessage(_INTL("La Mochila se ha vaciado."))
  }
})

#===============================================================================
# Player options
#===============================================================================
MenuHandlers.add(:debug_menu, :player_menu, {
  "name"        => _INTL("Opciones del Jugador..."),
  "parent"      => :main,
  "description" => _INTL("Definir dinero, medallas, Pokédex, apariencia y nombre del jugador, etc."),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :set_money, {
  "name"        => _INTL("Definir dinero"),
  "parent"      => :player_menu,
  "description" => _INTL("Editar la cantidad de dinero, Fichas del Casino y Puntos de Batalla."),
  "effect"      => proc {
    cmd = 0
    loop do
      cmds = [_INTL("Dinero: {1}$", $player.money.to_s_formatted),
              _INTL("Fichas: {1}", $player.coins.to_s_formatted),
              _INTL("Puntos de Batalla: {1}", $player.battle_points.to_s_formatted)]
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      break if cmd < 0
      case cmd
      when 0   # Money
        params = ChooseNumberParams.new
        params.setRange(0, Settings::MAX_MONEY)
        params.setDefaultValue($player.money)
        $player.money = pbMessageChooseNumber("\\ts[]" + _INTL("Elige el dinero del jugador."), params)
      when 1   # Coins
        params = ChooseNumberParams.new
        params.setRange(0, Settings::MAX_COINS)
        params.setDefaultValue($player.coins)
        $player.coins = pbMessageChooseNumber("\\ts[]" + _INTL("Elige las Fichas del jugador."), params)
      when 2   # Battle Points
        params = ChooseNumberParams.new
        params.setRange(0, Settings::MAX_BATTLE_POINTS)
        params.setDefaultValue($player.battle_points)
        $player.battle_points = pbMessageChooseNumber("\\ts[]" + _INTL("Elige la cantidad de PB."), params)
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :set_badges, {
  "name"        => _INTL("Define las Medallas de Gimnasio"),
  "parent"      => :player_menu,
  "description" => _INTL("Alterna la posesión de cada Medalla de Gimnasio."),
  "effect"      => proc {
    badgecmd = 0
    loop do
      badgecmds = []
      badgecmds.push(_INTL("Dar todas"))
      badgecmds.push(_INTL("Quitar todas"))
      24.times do |i|
        badgecmds.push(($player.badges[i] ? "[X]" : "[  ]") + " " + _INTL("Medalla {1}", i + 1))
      end
      badgecmd = pbShowCommands(nil, badgecmds, -1, badgecmd)
      break if badgecmd < 0
      case badgecmd
      when 0   # Give all
        24.times { |i| $player.badges[i] = true }
      when 1   # Remove all
        24.times { |i| $player.badges[i] = false }
      else
        $player.badges[badgecmd - 2] = !$player.badges[badgecmd - 2]
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :toggle_running_shoes, {
  "name"        => _INTL("Alternar zapatillas de correr"),
  "parent"      => :player_menu,
  "description" => _INTL("Alterna la posesión de las zapatillas de correr."),
  "effect"      => proc {
    $player.has_running_shoes = !$player.has_running_shoes
    pbMessage(_INTL("Dar zapatillas de correr.")) if $player.has_running_shoes
    pbMessage(_INTL("Quitar zapatillas de correr.")) if !$player.has_running_shoes
  }
})

MenuHandlers.add(:debug_menu, :toggle_pokedex, {
  "name"        => _INTL("Alternar Pokédex y Dexes Regionales"),
  "parent"      => :player_menu,
  "description" => _INTL("Alterna la posesión de la Pokédex, y edita el acceso a la dex regional."),
  "effect"      => proc {
    dexescmd = 0
    loop do
      dexescmds = []
      dexescmds.push(_INTL("Activar Pokédex: {1}", $player.has_pokedex ? "[SÍ]" : "[NO]"))
      dex_names = Settings.pokedex_names
      dex_names.length.times do |i|
        name = (dex_names[i].is_a?(Array)) ? dex_names[i][0] : dex_names[i]
        unlocked = $player.pokedex.unlocked?(i)
        dexescmds.push((unlocked ? "[X]" : "[  ]") + " " + name)
      end
      dexescmd = pbShowCommands(nil, dexescmds, -1, dexescmd)
      break if dexescmd < 0
      dexindex = dexescmd - 1
      if dexindex < 0   # Toggle Pokédex ownership
        $player.has_pokedex = !$player.has_pokedex
      elsif $player.pokedex.unlocked?(dexindex)   # Toggle Regional Dex accessibility
        $player.pokedex.lock(dexindex)
      else
        $player.pokedex.unlock(dexindex)
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :toggle_pokegear, {
  "name"        => _INTL("Alternar Pokégear"),
  "parent"      => :player_menu,
  "description" => _INTL("Alterna la posesión del Pokégear."),
  "effect"      => proc {
    $player.has_pokegear = !$player.has_pokegear
    pbMessage(_INTL("Dar Pokégear.")) if $player.has_pokegear
    pbMessage(_INTL("Quitar Pokégear.")) if !$player.has_pokegear
  }
})

MenuHandlers.add(:debug_menu, :edit_phone_contacts, {
  "name"        => _INTL("Editar teléfono y contactos"),
  "parent"      => :player_menu,
  "description" => _INTL("Editar propiedades del teléfono y los contactos registrados."),
  "effect"      => proc {
    if !$PokemonGlobal.phone
      pbMessage(_INTL("El teléfono no está definido."))
      next
    end
    cmd = 0
    loop do
      cmds = []
      time = $PokemonGlobal.phone.time_to_next_call.to_i   # time is in seconds
      min = time / 60
      sec = time % 60
      cmds.push(_INTL("Tiempo para la siguiente llamada: {1}m {2}s", min, sec))
      cmds.push((Phone.rematches_enabled ? "[X]" : "[  ]") + " " + _INTL("Revanchas posibles"))
      cmds.push(_INTL("Versión de revancha máximo : {1}", Phone.rematch_variant))
      if $PokemonGlobal.phone.contacts.length > 0
        cmds.push(_INTL("Hacer a todos los contactos listos para revancha"))
        cmds.push(_INTL("Editar contactos individuales: {1}", $PokemonGlobal.phone.contacts.length))
      end
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      break if cmd < 0
      case cmd
      when 0   # Time until next call
        params = ChooseNumberParams.new
        params.setRange(0, 99999)
        params.setDefaultValue(min)
        params.setCancelValue(-1)
        new_time = pbMessageChooseNumber(_INTL("Define el tiempo (en minutos) para la próxima llamada."), params)
        $PokemonGlobal.phone.time_to_next_call = new_time * 60 if new_time >= 0
      when 1   # Rematches possible
        Phone.rematches_enabled = !Phone.rematches_enabled
      when 2   # Maximum rematch version
        params = ChooseNumberParams.new
        params.setRange(0, 99)
        params.setDefaultValue(Phone.rematch_variant)
        new_version = pbMessageChooseNumber(_INTL("Define el número máximo de versión que puede alcanzar un entrenador de un contacto."), params)
        Phone.rematch_variant = new_version
      when 3   # Make all contacts ready for a rematch
        $PokemonGlobal.phone.contacts.each do |contact|
          next if !contact.trainer?
          contact.rematch_flag = 1
          contact.set_trainer_event_ready_for_rematch
        end
        pbMessage(_INTL("Todos los entrenadores del teléfono están listos para revancha."))
      when 4   # Edit individual contacts
        contact_cmd = 0
        loop do
          contact_cmds = []
          $PokemonGlobal.phone.contacts.each do |contact|
            visible_string = (contact.visible?) ? "[X]" : "[  ]"
            if contact.trainer?
              battle_string = (contact.can_rematch?) ? "(puede pelear)" : ""
              contact_cmds.push(sprintf("%s %s (%i) %s", visible_string, contact.display_name, contact.variant, battle_string))
            else
              contact_cmds.push(sprintf("%s %s", visible_string, contact.display_name))
            end
          end
          contact_cmd = pbShowCommands(nil, contact_cmds, -1, contact_cmd)
          break if contact_cmd < 0
          contact = $PokemonGlobal.phone.contacts[contact_cmd]
          edit_cmd = 0
          loop do
            edit_cmds = []
            edit_cmds.push((contact.visible? ? "[X]" : "[  ]") + " " + _INTL("Contacto visible"))
            if contact.trainer?
              edit_cmds.push((contact.can_rematch? ? "[X]" : "[  ]") + " " + _INTL("Puede pelear"))
              ready_time = contact.time_to_ready   # time is in seconds
              ready_min = ready_time / 60
              ready_sec = ready_time % 60
              edit_cmds.push(_INTL("Tiempo para estar listo para pelear: {1}m {2}s", ready_min, ready_sec))
              edit_cmds.push(_INTL("Última versión derrotada: {1}", contact.variant))
            end
            break if edit_cmds.length == 0
            edit_cmd = pbShowCommands(nil, edit_cmds, -1, edit_cmd)
            break if edit_cmd < 0
            case edit_cmd
            when 0   # Visibility
              contact.visible = !contact.visible if contact.can_hide?
            when 1   # Can battle
              contact.rematch_flag = (contact.can_rematch?) ? 0 : 1
              contact.time_to_ready = 0 if contact.can_rematch?
            when 2   # Time until ready to battle
              params = ChooseNumberParams.new
              params.setRange(0, 99999)
              params.setDefaultValue(ready_min)
              params.setCancelValue(-1)
              new_time = pbMessageChooseNumber(_INTL("Define el tiempo (en minutos) para que el entrenador está listo para combatir."), params)
              contact.time_to_ready = new_time * 60 if new_time >= 0
            when 3   # Last defeated version
              params = ChooseNumberParams.new
              params.setRange(0, 99)
              params.setDefaultValue(contact.variant)
              new_version = pbMessageChooseNumber(_INTL("Define el número de la última versión del entrenador que ha sido derrotada."), params)
              contact.version = contact.start_version + new_version
            end
          end
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :toggle_box_link, {
  "name"        => _INTL("Alternar acceso al almacenamiento desde el equipo"),
  "parent"      => :player_menu,
  "description" => _INTL("Alterna el acceso al PC desde el equipo del jugador."),
  "effect"      => proc {
    $player.has_box_link = !$player.has_box_link
    pbMessage(_INTL("Activado el acceso al sistema de almacenamiento desde el equipo.")) if $player.has_box_link
    pbMessage(_INTL("Desactivado el acceso al sistema de almacenamiento desde el equipo")) if !$player.has_box_link
  }
})

MenuHandlers.add(:debug_menu, :set_player_character, {
  "name"        => _INTL("Define el personaje del jugador"),
  "parent"      => :player_menu,
  "description" => _INTL("Editar el personaje del jugador como está definido en \"metadata.txt\"."),
  "effect"      => proc {
    index = 0
    cmds = []
    ids = []
    GameData::PlayerMetadata.each do |player|
      index = cmds.length if player.id == $player.character_ID
      cmds.push(player.id.to_s)
      ids.push(player.id)
    end
    if cmds.length == 1
      pbMessage(_INTL("Sólo hay definido un personaje para el jugador."))
      break
    end
    cmd = pbShowCommands(nil, cmds, -1, index)
    if cmd >= 0 && cmd != index
      pbChangePlayer(ids[cmd])
      pbMessage(_INTL("Se ha cambiado el personaje del jugador."))
    end
  }
})

MenuHandlers.add(:debug_menu, :change_outfit, {
  "name"        => _INTL("Define el outfit del personaje"),
  "parent"      => :player_menu,
  "description" => _INTL("Editar el número de ropa del jugador."),
  "effect"      => proc {
    oldoutfit = $player.outfit
    params = ChooseNumberParams.new
    params.setRange(0, 99)
    params.setDefaultValue(oldoutfit)
    $player.outfit = pbMessageChooseNumber(_INTL("Elige la ropa del jugador."), params)
    pbMessage(_INTL("Se ha cambiado la ropa del jugador.")) if $player.outfit != oldoutfit
  }
})

MenuHandlers.add(:debug_menu, :rename_player, {
  "name"        => _INTL("Define el nombre del jugador"),
  "parent"      => :player_menu,
  "description" => _INTL("Renombra el jugador."),
  "effect"      => proc {
    trname = pbEnterPlayerName("¿Tu nombre?", 0, Settings::MAX_PLAYER_NAME_SIZE, $player.name)
    if nil_or_empty?(trname) && pbConfirmMessage(_INTL("¿Poner un nombre predeterminado?"))
      trainertype = $player.trainer_type
      gender      = pbGetTrainerTypeGender(trainertype)
      trname      = pbSuggestTrainerName(gender)
    end
    if nil_or_empty?(trname)
      pbMessage(_INTL("El nombre del jugador {1} no se ha cambiado.", $player.name))
    else
      $player.name = trname
      pbMessage(_INTL("El nombre del jugador se ha cambiado a {1}.", $player.name))
    end
  }
})

MenuHandlers.add(:debug_menu, :random_id, {
  "name"        => _INTL("Randomizar el ID del jugador"),
  "parent"      => :player_menu,
  "description" => _INTL("Generar un nuevo ID al azar para el jugador."),
  "effect"      => proc {
    $player.id = rand(2**16) | (rand(2**16) << 16)
    pbMessage(_INTL("El ID del jugador se ha cambiado a {1} (ID completo: {2}).", $player.public_ID, $player.id))
  }
})

#===============================================================================
# PBS file editors
#===============================================================================
MenuHandlers.add(:debug_menu, :pbs_editors_menu, {
  "name"        => _INTL("Editores de archivos PBS..."),
  "parent"      => :main,
  "description" => _INTL("Editar información en los archivos PBS.")
})

MenuHandlers.add(:debug_menu, :set_map_connections, {
  "name"        => _INTL("Editar map_connections.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Editar conexiones de mapas. También encuentros y metadatos."),
  "effect"      => proc {
    pbFadeOutIn { pbConnectionsEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_encounters, {
  "name"        => _INTL("Editar encounters.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Editar los Pokémon salvajes de cada mapa, y cómo pueden encontrarse."),
  "effect"      => proc {
    pbFadeOutIn { pbEncountersEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_trainers, {
  "name"        => _INTL("Editar trainers.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Editar entrenadores, sus Pokémon y objetos."),
  "effect"      => proc {
    pbFadeOutIn { pbTrainerBattleEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_trainer_types, {
  "name"        => _INTL("Editar trainer_types.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Editar las propiedades de los tipos de entrenador."),
  "effect"      => proc {
    pbFadeOutIn { pbTrainerTypeEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_map_metadata, {
  "name"        => _INTL("Editar map_metadata.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Editar metadatos de mapa."),
  "effect"      => proc {
    pbMapMetadataScreen(pbDefaultMap)
  }
})

MenuHandlers.add(:debug_menu, :set_metadata, {
  "name"        => _INTL("Editar metadata.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Editar metadatos globales y metadatos del personaje del jugador."),
  "effect"      => proc {
    pbMetadataScreen
  }
})

MenuHandlers.add(:debug_menu, :set_items, {
  "name"        => _INTL("Editar items.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Editar los datos de objetos."),
  "effect"      => proc {
    pbFadeOutIn { pbItemEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_species, {
  "name"        => _INTL("Editar pokemon.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Editar los datos de las especies de Pokémon."),
  "effect"      => proc {
    pbFadeOutIn { pbPokemonEditor }
  }
})

MenuHandlers.add(:debug_menu, :position_sprites, {
  "name"        => _INTL("Editar pokemon_metrics.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Reposicionar los sprites de Pokémon en combate."),
  "effect"      => proc {
    pbFadeOutIn do
      sp = SpritePositioner.new
      sps = SpritePositionerScreen.new(sp)
      sps.pbStart
    end
  }
})

MenuHandlers.add(:debug_menu, :auto_position_sprites, {
  "name"        => _INTL("Auto definir pokemon_metrics.txts"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Reposicionar automáticamente la posición de los sprites de Pokémon."),
  "effect"      => proc {
    if pbConfirmMessage(_INTL("¿Estás seguro de que quieres reposicionar todos los sprites?"))
      msgwindow = pbCreateMessageWindow
      pbMessageDisplay(msgwindow, _INTL("Reposicionando todos los sprites. Por favor, espera."), false)
      Graphics.update
      pbAutoPositionAll
      pbDisposeMessageWindow(msgwindow)
    end
  }
})

MenuHandlers.add(:debug_menu, :set_pokedex_lists, {
  "name"        => _INTL("Editar regional_dexes.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("Crear, reorganizar y eliminar listas de Pokédex Regionales."),
  "effect"      => proc {
    pbFadeOutIn { pbRegionalDexEditorMain }
  }
})

#===============================================================================
# Other editors
#===============================================================================
MenuHandlers.add(:debug_menu, :editors_menu, {
  "name"        => _INTL("Otros editores..."),
  "parent"      => :main,
  "description" => _INTL("Editar animaciones de combate, tags de terreno, datos de mapas, etc.")
})

MenuHandlers.add(:debug_menu, :animation_editor, {
  "name"        => _INTL("Editor de animaciones de combate"),
  "parent"      => :editors_menu,
  "description" => _INTL("Editar the battle animations."),
  "effect"      => proc {
    pbFadeOutIn { pbAnimationEditor }
  }
})

MenuHandlers.add(:debug_menu, :animation_organiser, {
  "name"        => _INTL("Organizador de animaciones de combate"),
  "parent"      => :editors_menu,
  "description" => _INTL("Reorganizar/añadir/eliminar animaciones de combate."),
  "effect"      => proc {
    pbFadeOutIn { pbAnimationsOrganiser }
  }
})

MenuHandlers.add(:debug_menu, :import_animations, {
  "name"        => _INTL("Exportar animaciones de combate"),
  "parent"      => :editors_menu,
  "description" => _INTL("Importar todas las animaciones de combate de la carpeta \"Animations\"."),
  "effect"      => proc {
    pbImportAllAnimations
  }
})

MenuHandlers.add(:debug_menu, :export_animations, {
  "name"        => _INTL("Exportar animaciones de combate"),
  "parent"      => :editors_menu,
  "description" => _INTL("Exporta todas las animaciones de comabte deforma individual a la carpeta \"Animations\"."),
  "effect"      => proc {
    pbExportAllAnimations
  }
})

MenuHandlers.add(:debug_menu, :set_terrain_tags, {
  "name"        => _INTL("Editar tags de terreno"),
  "parent"      => :editors_menu,
  "description" => _INTL("Editar los tags de terreno de los tiles, para valores mayores a 8."),
  "effect"      => proc {
    pbFadeOutIn { pbTilesetScreen }
  }
})

MenuHandlers.add(:debug_menu, :fix_invalid_tiles, {
  "name"        => _INTL("Arreglar tiles inválidos"),
  "parent"      => :editors_menu,
  "description" => _INTL("Escanea todos los mapas y elimina los tiles no existentes."),
  "effect"      => proc {
    pbDebugFixInvalidTiles
  }
})

#===============================================================================
# Other options
#===============================================================================
MenuHandlers.add(:debug_menu, :files_menu, {
  "name"        => _INTL("Opciones de archivos..."),
  "parent"      => :main,
  "description" => _INTL("Compila, genera archivos PBS, traducciones, Regalos Misteriosos, etc.")
})

MenuHandlers.add(:debug_menu, :compile_data, {
  "name"        => _INTL("Compilar datos"),
  "parent"      => :files_menu,
  "description" => _INTL("Compila todos los datos del juego."),
  "effect"      => proc {
    msgwindow = pbCreateMessageWindow
    Compiler.compile_all(true)
    pbMessageDisplay(msgwindow, _INTL("Se ha compilado todos los datos del juego."))
    pbDisposeMessageWindow(msgwindow)
  }
})

MenuHandlers.add(:debug_menu, :create_pbs_files, {
  "name"        => _INTL("Crear achivos PBS"),
  "parent"      => :files_menu,
  "description" => _INTL("Elige uno o todos los archivos PBS y créalos."),
  "effect"      => proc {
    cmd = 0
    cmds = [
      _INTL("[Crear todos]"),
      "abilities.txt",
      "battle_facility_lists.txt",
      "berry_plants.txt",
      "dungeon_parameters.txt",
      "dungeon_tilesets.txt",
      "encounters.txt",
      "items.txt",
      "map_connections.txt",
      "map_metadata.txt",
      "metadata.txt",
      "moves.txt",
      "phone.txt",
      "pokemon.txt",
      "pokemon_forms.txt",
      "pokemon_metrics.txt",
      "regional_dexes.txt",
      "ribbons.txt",
      "shadow_pokemon.txt",
      "town_map.txt",
      "trainer_types.txt",
      "trainers.txt",
      "types.txt"
    ]
    loop do
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      case cmd
      when 0  then Compiler.write_all
      when 1  then Compiler.write_abilities
      when 2  then Compiler.write_trainer_lists
      when 3  then Compiler.write_berry_plants
      when 4  then Compiler.write_dungeon_parameters
      when 5  then Compiler.write_dungeon_tilesets
      when 6  then Compiler.write_encounters
      when 7  then Compiler.write_items
      when 8  then Compiler.write_connections
      when 9  then Compiler.write_map_metadata
      when 10 then Compiler.write_metadata
      when 11 then Compiler.write_moves
      when 12 then Compiler.write_phone
      when 13 then Compiler.write_pokemon
      when 14 then Compiler.write_pokemon_forms
      when 15 then Compiler.write_pokemon_metrics
      when 16 then Compiler.write_regional_dexes
      when 17 then Compiler.write_ribbons
      when 18 then Compiler.write_shadow_pokemon
      when 19 then Compiler.write_town_map
      when 20 then Compiler.write_trainer_types
      when 21 then Compiler.write_trainers
      when 22 then Compiler.write_types
      else break
      end
      pbMessage(_INTL("File written."))
    end
  }
})

MenuHandlers.add(:debug_menu, :rename_files, {
  "name"        => _INTL("Renombrar archivos anticuados"),
  "parent"      => :files_menu,
  "description" => _INTL("Revisa y renombra archivos con nombres anticuados. Puede alterar datos de mapas."),
  "effect"      => proc {
    if pbConfirmMessage(_INTL("¿Estás seguro de que quieres renombrar automáticamente archivos anticuados?"))
      FilenameUpdater.rename_files
      pbMessage(_INTL("Listo."))
    end
  }
})

MenuHandlers.add(:debug_menu, :extract_text, {
  "name"        => _INTL("Extraer texto para traducción"),
  "parent"      => :files_menu,
  "description" => _INTL("Extrae todos los textos del juego en archivos para su traducción."),
  "effect"      => proc {
    if Settings::LANGUAGES.length == 0
      pbMessage(_INTL("No se han definido idiomas en el array de LANGUAGES en Settings."))
      pbMessage(_INTL("Tienes que añadir al menos un idioma en LANGUAGES primero, para poder elegir a cuál se va a extraer el texto."))
      next
    end
    # Choose a language from Settings to name the extraction folder after
    cmds = []
    Settings::LANGUAGES.each { |val| cmds.push(val[0]) }
    cmds.push(_INTL("Cancelar"))
    language_index = pbMessage(_INTL("Elige un idioma del que extraer el texto."), cmds, cmds.length)
    next if language_index == cmds.length - 1
    language_name = Settings::LANGUAGES[language_index][1]
    # Choose whether to extract core text or game text
    text_type = pbMessage(_INTL("Elige un idioma del que extraer el texto."),
                          [_INTL("Texto específico del juego"), _INTL("Texto interno"), _INTL("Cancelar")], 3)
    next if text_type == 2
    # If game text, choose whether to extract map texts to map-specific files or
    # to one big file
    map_files = 0
    if text_type == 0
      map_files = pbMessage(_INTL("¿En cuántos archivos de texto quieres extraer los textos de eventos de mapas?"),
                            [_INTL("Un archivo grande"), _INTL("Un archivo por mapa"), _INTL("Cancelar")], 3)
      next if map_files == 2
    end
    # Extract the chosen set of text for the chosen language
    Translator.extract_text(language_name, text_type == 1, map_files == 1)
  }
})

MenuHandlers.add(:debug_menu, :compile_text, {
  "name"        => _INTL("Compilar texto traducido"),
  "parent"      => :files_menu,
  "description" => _INTL("Importa archivos de texto y los convierte en un archivo de idioma."),
  "effect"      => proc {
    # Find all folders with a particular naming convention
    cmds = Dir.glob("Text_*_*")
    if cmds.length == 0
      pbMessage(_INTL("No se han encontrado carpetas de idioma para compilar."))
      pbMessage(_INTL("Las carpetas de idiomas se tienen que llamar \"Text_ALGO_core\" o \"Text_ALGO_game\" y estar en la carpeta principal."))
      next
    end
    cmds.push(_INTL("Cancelar"))
    # Ask which folder to compile into a .dat file
    folder_index = pbMessage(_INTL("Elige una carpeta de idioma para compilar."), cmds, cmds.length)
    next if folder_index == cmds.length - 1
    # Compile the text files in the chosen folder
    dat_filename = cmds[folder_index].gsub!(/^Text_/, "")
    Translator.compile_text(cmds[folder_index], dat_filename)
  }
})

MenuHandlers.add(:debug_menu, :mystery_gift, {
  "name"        => _INTL("Gestionar Regalos Misteriosos"),
  "parent"      => :files_menu,
  "description" => _INTL("Editar y activar/desactivar Regalos Misteriosos."),
  "effect"      => proc {
    pbManageMysteryGifts
  }
})

MenuHandlers.add(:debug_menu, :reload_system_cache, {
  "name"        => _INTL("Recargar caché del sistema"),
  "parent"      => :files_menu,
  "description" => _INTL("Refresca el archivo de caché. Por si cambias un archivo mientras juegas."),
  "effect"      => proc {
    System.reload_cache
    pbMessage(_INTL("Listo."))
  }
})

