#===============================================================================
# HP/Status options
#===============================================================================
MenuHandlers.add(:battle_pokemon_debug_menu, :hp_status_menu, {
  "name"   => _INTL("PS/estado..."),
  "parent" => :main,
  "usage"  => :both
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_hp, {
  "name"   => _INTL("Definir PS"),
  "parent" => :hp_status_menu,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.egg?
      pbMessage("\\ts[]" + _INTL("{1} es un Huevo.", pkmn.name))
      next
    elsif battler && pkmn.totalhp == 1
      pbMessage("\\ts[]" + _INTL("No se pueden cambiar los PS, los PS máximos de {1} son 1 y está en combate.", pkmn.name))
      next
    end
    min_hp = (battler) ? 1 : 0
    params = ChooseNumberParams.new
    params.setRange(min_hp, pkmn.totalhp)
    params.setDefaultValue(pkmn.hp)
    new_hp = pbMessageChooseNumber(
      "\\ts[]" + _INTL("Indica los PS de {1} ({2}-{3}).", (battler) ? battler.pbThis(true) : pkmn.name, min_hp, pkmn.totalhp),
      params
    )
    next if new_hp == pkmn.hp
    (battler || pkmn).hp = new_hp
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_status, {
  "name"   => _INTL("Definir estado"),
  "parent" => :hp_status_menu,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.egg?
      pbMessage("\\ts[]" + _INTL("{1} es un Huevo.", pkmn.name))
      next
    elsif pkmn.hp <= 0
      pbMessage("\\ts[]" + _INTL("{1} está debilitado, no se puede cambiar su estado.", pkmn.name))
      next
    end
    cmd = 0
    commands = [_INTL("[Curado]")]
    ids = [:NONE]
    GameData::Status.each do |s|
      next if s.id == :NONE
      commands.push(_INTL("Definir {1}", s.name))
      ids.push(s.id)
    end
    loop do
      msg = _INTL("Estado actual: {1}", GameData::Status.get(pkmn.status).name)
      if pkmn.status == :SLEEP
        msg += " " + _INTL("(turnos: {1})", pkmn.statusCount)
      elsif pkmn.status == :POISON && pkmn.statusCount > 0
        if battler
          msg += " " + _INTL("(tóxico, contador: {1})", battler.effects[PBEffects::Toxic])
        else
          msg += " " + _INTL("(tóxico)")
        end
      end
      cmd = pbMessage("\\ts[]" + msg, commands, -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Cure
        if battler
          battler.status = :NONE
        else
          pkmn.heal_status
        end
      else   # Give status problem
        pkmn_name = (battler) ? battler.pbThis(true) : pkmn.name
        case ids[cmd]
        when :SLEEP
          params = ChooseNumberParams.new
          params.setRange(0, 99)
          params.setDefaultValue((pkmn.status == :SLEEP) ? pkmn.statusCount : 3)
          params.setCancelValue(-1)
          count = pbMessageChooseNumber("\\ts[]" + _INTL("Indica el contador de sueño de {1} (0-99).", pkmn_name), params)
          next if count < 0
          (battler || pkmn).statusCount = count
        when :POISON
          if pbConfirmMessage("\\ts[]" + _INTL("¿Hacer que {1} esté gravemente envenenado (toxic)?", pkmn_name))
            if battler
              params = ChooseNumberParams.new
              params.setRange(0, 16)
              params.setDefaultValue(battler.effects[PBEffects::Toxic])
              params.setCancelValue(-1)
              count = pbMessageChooseNumber(
                "\\ts[]" + _INTL("Indica el contador de tóxico de {1} (0-16).", pkmn_name), params
              )
              next if count < 0
              battler.statusCount = 1
              battler.effects[PBEffects::Toxic] = count
            else
              pkmn.statusCount = 1
            end
          else
            (battler || pkmn).statusCount = 0
          end
        end
        (battler || pkmn).status = ids[cmd]
      end
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :full_heal, {
  "name"   => _INTL("Curar PS y estado"),
  "parent" => :hp_status_menu,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.egg?
      pbMessage("\\ts[]" + _INTL("{1} es un Huevo.", pkmn.name))
      next
    end
    if battler
      battler.hp = battler.totalhp
      battler.status = :NONE
    else
      pkmn.heal_HP
      pkmn.heal_status
    end
  }
})

#===============================================================================
# Level/stats options
#===============================================================================
MenuHandlers.add(:battle_pokemon_debug_menu, :level_stats, {
  "name"   => _INTL("Estadísticas/nivel..."),
  "parent" => :main,
  "usage"  => :both
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_stat_stages, {
  "name"   => _INTL("Definir cambios de estadísticas"),
  "parent" => :level_stats,
  "usage"  => :battler,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.egg?
      pbMessage("\\ts[]" + _INTL("{1} es un Huevo.", pkmn.name))
      next
    end
    cmd = 0
    loop do
      commands = []
      stat_ids = []
      GameData::Stat.each_battle do |stat|
        command_name = stat.name + ": "
        command_name += "+" if battler.stages[stat.id] > 0
        command_name += battler.stages[stat.id].to_s
        commands.push(command_name)
        stat_ids.push(stat.id)
      end
      commands.push(_INTL("[Reiniciar todas]"))
      cmd = pbMessage("\\ts[]" + _INTL("Elige una estadística para cambiarla."), commands, -1, nil, cmd)
      break if cmd < 0
      if cmd < stat_ids.length   # Set a stat
        params = ChooseNumberParams.new
        params.setRange(-Battle::Battler::STAT_STAGE_MAXIMUM, Battle::Battler::STAT_STAGE_MAXIMUM)
        params.setNegativesAllowed(true)
        params.setDefaultValue(battler.stages[stat_ids[cmd]])
        value = pbMessageChooseNumber(
          "\\ts[]" + _INTL("Elige el nivel de cambio de {1}.", GameData::Stat.get(stat_ids[cmd]).name), params
        )
        battler.stages[stat_ids[cmd]] = value
      else   # Reset all stats
        GameData::Stat.each_battle { |stat| battler.stages[stat.id] = 0 }
      end
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_stat_values, {
  "name"   => _INTL("Define valores de estadísticas"),
  "parent" => :level_stats,
  "usage"  => :battler,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.egg?
      pbMessage("\\ts[]" + _INTL("{1} es un Huevo.", pkmn.name))
      next
    end
    stat_ids = []
    stat_vals = []
    GameData::Stat.each_main_battle do |stat|
      stat_ids.push(stat.id)
      case stat.id
      when :ATTACK          then stat_vals.push(battler.attack)
      when :DEFENSE         then stat_vals.push(battler.defense)
      when :SPECIAL_ATTACK  then stat_vals.push(battler.spatk)
      when :SPECIAL_DEFENSE then stat_vals.push(battler.spdef)
      when :SPEED           then stat_vals.push(battler.speed)
      else                       stat_vals.push(1)
      end
    end
    cmd = 0
    loop do
      commands = []
      GameData::Stat.each_main_battle do |stat|
        command_name = stat.name + ": " + stat_vals[stat_ids.index(stat.id)].to_s
        commands.push(command_name)
      end
      commands.push(_INTL("[Reiniciar todas]"))
      cmd = pbMessage("\\ts[]" + _INTL("Elige un valor de estadística para cambiarlo."), commands, -1, nil, cmd)
      break if cmd < 0
      if cmd < stat_ids.length   # Set a stat
        params = ChooseNumberParams.new
        params.setRange(1, 9999)
        params.setDefaultValue(stat_vals[cmd])
        value = pbMessageChooseNumber(
          "\\ts[]" + _INTL("Elige un valor para {1}.", GameData::Stat.get(stat_ids[cmd]).name), params
        )
        case stat_ids[cmd]
        when :ATTACK          then battler.attack  = value
        when :DEFENSE         then battler.defense = value
        when :SPECIAL_ATTACK  then battler.spatk   = value
        when :SPECIAL_DEFENSE then battler.spdef   = value
        when :SPEED           then battler.speed   = value
        end
        stat_vals[cmd] = value
      else   # Reset all stat values
        battler.pbUpdate
        GameData::Stat.each_main_battle do |stat|
          case stat.id
          when :ATTACK          then stat_vals[stat_ids.index(stat.id)] = battler.attack
          when :DEFENSE         then stat_vals[stat_ids.index(stat.id)] = battler.defense
          when :SPECIAL_ATTACK  then stat_vals[stat_ids.index(stat.id)] = battler.spatk
          when :SPECIAL_DEFENSE then stat_vals[stat_ids.index(stat.id)] = battler.spdef
          when :SPEED           then stat_vals[stat_ids.index(stat.id)] = battler.speed
          else                       stat_vals[stat_ids.index(stat.id)] = 1
          end
        end
      end
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_level, {
  "name"   => _INTL("Definir nivel"),
  "parent" => :level_stats,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.egg?
      pbMessage("\\ts[]" + _INTL("{1} es un Huevo.", pkmn.name))
      next
    end
    params = ChooseNumberParams.new
    params.setRange(1, GameData::GrowthRate.max_level)
    params.setDefaultValue(pkmn.level)
    level = pbMessageChooseNumber(
      "\\ts[]" + _INTL("Indica el nivel del Pokémon (máx. {1}).", params.maxNumber), params
    )
    if level != pkmn.level
      pkmn.level = level
      pkmn.calc_stats
      battler&.pbUpdate
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_exp, {
  "name"   => _INTL("Definir Exp"),
  "parent" => :level_stats,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.egg?
      pbMessage("\\ts[]" + _INTL("{1} es un Huevo.", pkmn.name))
      next
    end
    min_exp = pkmn.growth_rate.minimum_exp_for_level(pkmn.level)
    max_exp = pkmn.growth_rate.minimum_exp_for_level(pkmn.level + 1)
    if min_exp == max_exp
      pbMessage("\\ts[]" + _INTL("{1} está al máximo nivel.", pkmn.name))
      next
    end
    params = ChooseNumberParams.new
    params.setRange(min_exp, max_exp - 1)
    params.setDefaultValue(pkmn.exp)
    new_exp = pbMessageChooseNumber(
      "\\ts[]" + _INTL("Elige la Exp del Pokémon (rango {1}-{2}).", min_exp, max_exp - 1), params
    )
    pkmn.exp = new_exp if new_exp != pkmn.exp
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :hidden_values, {
  "name"   => _INTL("EV/IV..."),
  "parent" => :level_stats,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    loop do
      cmd = pbMessage("\\ts[]" + _INTL("Elige los valores ocultos a editar."),
                      [_INTL("Definir EVs"), _INTL("Definir IVs")], -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Set EVs
        cmd2 = 0
        loop do
          total_evs = 0
          ev_commands = []
          ev_id = []
          GameData::Stat.each_main do |s|
            ev_commands.push(s.name + " (#{pkmn.ev[s.id]})")
            ev_id.push(s.id)
            total_evs += pkmn.ev[s.id]
          end
          ev_commands.push(_INTL("Randomizar todos"))
          ev_commands.push(_INTL("Randomizar al máximo todos"))
          cmd2 = pbMessage("\\ts[]" + _INTL("¿Qué EV cambiar?\nTotal: {1}/{2} ({3}%)",
                                            total_evs, Pokemon::EV_LIMIT, 100 * total_evs / Pokemon::EV_LIMIT),
                           ev_commands, -1, nil, cmd2)
          break if cmd2 < 0
          if cmd2 < ev_id.length
            params = ChooseNumberParams.new
            upperLimit = 0
            GameData::Stat.each_main { |s| upperLimit += pkmn.ev[s.id] if s.id != ev_id[cmd2] }
            upperLimit = Pokemon::EV_LIMIT - upperLimit
            upperLimit = [upperLimit, Pokemon::EV_STAT_LIMIT].min
            thisValue = [pkmn.ev[ev_id[cmd2]], upperLimit].min
            params.setRange(0, upperLimit)
            params.setDefaultValue(thisValue)
            params.setCancelValue(thisValue)
            f = pbMessageChooseNumber("\\ts[]" + _INTL("Elige los EV para {1} (máx. {2}).",
                                                       GameData::Stat.get(ev_id[cmd2]).name, upperLimit), params)
            if f != pkmn.ev[ev_id[cmd2]]
              pkmn.ev[ev_id[cmd2]] = f
              pkmn.calc_stats
              battler&.pbUpdate
            end
          else   # (Max) Randomise all
            evTotalTarget = Pokemon::EV_LIMIT
            if cmd2 == ev_commands.length - 2   # Randomize all (not max)
              evTotalTarget = rand(Pokemon::EV_LIMIT)
            end
            GameData::Stat.each_main { |s| pkmn.ev[s.id] = 0 }
            while evTotalTarget > 0
              r = rand(ev_id.length)
              next if pkmn.ev[ev_id[r]] >= Pokemon::EV_STAT_LIMIT
              addVal = 1 + rand(Pokemon::EV_STAT_LIMIT / 4)
              addVal = addVal.clamp(0, evTotalTarget)
              addVal = addVal.clamp(0, Pokemon::EV_STAT_LIMIT - pkmn.ev[ev_id[r]])
              next if addVal == 0
              pkmn.ev[ev_id[r]] += addVal
              evTotalTarget -= addVal
            end
            pkmn.calc_stats
            battler&.pbUpdate
          end
        end
      when 1   # Set IVs
        cmd2 = 0
        loop do
          hiddenpower = pbHiddenPower(pkmn)
          totaliv = 0
          ivcommands = []
          iv_id = []
          GameData::Stat.each_main do |s|
            ivcommands.push(s.name + " (#{pkmn.iv[s.id]})")
            iv_id.push(s.id)
            totaliv += pkmn.iv[s.id]
          end
          msg = _INTL("¿Cambiar qué IV?\nPoder Oculto: {1}, poder {2}\nTotal: {3}/{4} ({5}%)",
                      GameData::Type.get(hiddenpower[0]).name, hiddenpower[1], totaliv,
                      iv_id.length * Pokemon::IV_STAT_LIMIT, 100 * totaliv / (iv_id.length * Pokemon::IV_STAT_LIMIT))
          ivcommands.push(_INTL("Randomizar todos"))
          cmd2 = pbMessage("\\ts[]\\l[3]" + msg, ivcommands, -1, nil, cmd2)
          break if cmd2 < 0
          if cmd2 < iv_id.length
            params = ChooseNumberParams.new
            params.setRange(0, Pokemon::IV_STAT_LIMIT)
            params.setDefaultValue(pkmn.iv[iv_id[cmd2]])
            params.setCancelValue(pkmn.iv[iv_id[cmd2]])
            f = pbMessageChooseNumber("\\ts[]" + _INTL("Elige los IV para {1} (máx. 31).",
                                                       GameData::Stat.get(iv_id[cmd2]).name), params)
            if f != pkmn.iv[iv_id[cmd2]]
              pkmn.iv[iv_id[cmd2]] = f
              pkmn.calc_stats
              battler&.pbUpdate
            end
          else   # Randomise all
            GameData::Stat.each_main { |s| pkmn.iv[s.id] = rand(Pokemon::IV_STAT_LIMIT + 1) }
            pkmn.calc_stats
            battler&.pbUpdate
          end
        end
      end
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_happiness, {
  "name"   => _INTL("Definir felicidad"),
  "parent" => :level_stats,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    params = ChooseNumberParams.new
    params.setRange(0, 255)
    params.setDefaultValue(pkmn.happiness)
    h = pbMessageChooseNumber("\\ts[]" + _INTL("Indica la felicidad del Pokémon (máx. 255)."), params)
    pkmn.happiness = h if h != pkmn.happiness
  }
})

#===============================================================================
# Types
#===============================================================================
MenuHandlers.add(:battle_pokemon_debug_menu, :set_types, {
  "name"   => _INTL("Definir tipos"),
  "parent" => :main,
  "usage"  => :battler,
  "effect" => proc { |pkmn, battler, battle|
    max_main_types = 5   # Arbitrary value, could be any number
    cmd = 0
    loop do
      commands = []
      types = []
      max_main_types.times do |i|
        type = battler.types[i]
        type_name = (type) ? GameData::Type.get(type).name : "-"
        commands.push(_INTL("Tipo {1}: {2}", i + 1, type_name))
        types.push(type)
      end
      extra_type = battler.effects[PBEffects::ExtraType]
      extra_type_name = (extra_type) ? GameData::Type.get(extra_type).name : "-"
      commands.push(_INTL("Tipo secundario: {1}", extra_type_name))
      types.push(extra_type)
      msg = _INTL("Tipos efectivos: {1}", battler.pbTypes(true).map { |t| GameData::Type.get(t).name }.join("/"))
      msg += "\n" + _INTL("(Cambia un tipo por sí mismo para quitarlo.)")
      cmd = pbMessage("\\ts[]" + msg, commands, -1, nil, cmd)
      break if cmd < 0
      old_type = types[cmd]
      new_type = pbChooseTypeList(old_type)
      if new_type
        if new_type == old_type
          if pbConfirmMessage(_INTL("¿Quitar este tipo?"))
            if cmd < max_main_types
              battler.types[cmd] = nil
            else
              battler.effects[PBEffects::ExtraType] = nil
            end
            battler.types.compact!
          end
        elsif cmd < max_main_types
          battler.types[cmd] = new_type
        else
          battler.effects[PBEffects::ExtraType] = new_type
        end
      end
    end
  }
})

#===============================================================================
# Moves options
#===============================================================================
MenuHandlers.add(:battle_pokemon_debug_menu, :moves, {
  "name"   => _INTL("Movimientos..."),
  "parent" => :main,
  "usage"  => :both
})

MenuHandlers.add(:battle_pokemon_debug_menu, :teach_move, {
  "name"   => _INTL("Enseñar movimiento"),
  "parent" => :moves,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.numMoves >= Pokemon::MAX_MOVES
      pbMessage("\\ts[]" + _INTL("{1} ya conoce {2} movimientos. Necesita olvidar un primero.",
                                 pkmn.name, pkmn.numMoves))
      next
    end
    new_move = pbChooseMoveList
    next if !new_move
    move_name = GameData::Move.get(new_move).name
    if pkmn.hasMove?(new_move)
      pbMessage("\\ts[]" + _INTL("{1} ya conoce {2}.", pkmn.name, move_name))
      next
    end
    pkmn.learn_move(new_move)
    battler&.moves&.push(Battle::Move.from_pokemon_move(battle, pkmn.moves.last))
    pbMessage("\\ts[]" + _INTL("¡{1} aprendió {2}!", pkmn.name, move_name))
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :forget_move, {
  "name"   => _INTL("Olvidar movimiento"),
  "parent" => :moves,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    move_names = []
    move_indices = []
    pkmn.moves.each_with_index do |move, index|
      next if !move || !move.id
      if move.total_pp <= 0
        move_names.push(_INTL("{1} (PP: ---)", move.name))
      else
        move_names.push(_INTL("{1} (PP: {2}/{3})", move.name, move.pp, move.total_pp))
      end
      move_indices.push(index)
    end
    cmd = pbMessage("\\ts[]" + _INTL("¿Olvidar qué movimiento?"), move_names, -1)
    next if cmd < 0
    old_move_name = pkmn.moves[move_indices[cmd]].name
    pkmn.forget_move_at_index(move_indices[cmd])
    battler&.moves&.delete_at(move_indices[cmd])
    pbMessage("\\ts[]" + _INTL("{1} olvidó {2}.", pkmn.name, old_move_name))
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_move_pp, {
  "name"   => _INTL("Definir PP de movimientos"),
  "parent" => :moves,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    loop do
      move_names = []
      move_indices = []
      pkmn.moves.each_with_index do |move, index|
        next if !move || !move.id
        if move.total_pp <= 0
          move_names.push(_INTL("{1} (PP: ---)", move.name))
        else
          move_names.push(_INTL("{1} (PP: {2}/{3})", move.name, move.pp, move.total_pp))
        end
        move_indices.push(index)
      end
      commands = move_names + [_INTL("Restaurar todos los PP")]
      cmd = pbMessage("\\ts[]" + _INTL("¿Alterar los PP de qué movimiento?"), commands, -1, nil, cmd)
      break if cmd < 0
      if cmd >= 0 && cmd < move_names.length   # Move
        move = pkmn.moves[move_indices[cmd]]
        move_name = move.name
        if move.total_pp <= 0
          pbMessage("\\ts[]" + _INTL("{1} tiene infinitos PP.", move_name))
        else
          cmd2 = 0
          loop do
            msg = _INTL("{1}: PP {2}/{3} (Más PP {4}/3)", move_name, move.pp, move.total_pp, move.ppup)
            cmd2 = pbMessage("\\ts[]" + msg,
                             [_INTL("Definir PP"), _INTL("PP al máximo"), _INTL("Definir Más PP")], -1, nil, cmd2)
            break if cmd2 < 0
            case cmd2
            when 0   # Change PP
              params = ChooseNumberParams.new
              params.setRange(0, move.total_pp)
              params.setDefaultValue(move.pp)
              h = pbMessageChooseNumber(
                "\\ts[]" + _INTL("Indica los PP de {1} (máx. {2}).", move_name, move.total_pp), params
              )
              move.pp = h
              if battler && battler.moves[move_indices[cmd]].id == move.id
                battler.moves[move_indices[cmd]].pp = move.pp
              end
            when 1   # Full PP
              move.pp = move.total_pp
              if battler && battler.moves[move_indices[cmd]].id == move.id
                battler.moves[move_indices[cmd]].pp = move.pp
              end
            when 2   # Change PP Up
              params = ChooseNumberParams.new
              params.setRange(0, 3)
              params.setDefaultValue(move.ppup)
              h = pbMessageChooseNumber(
                "\\ts[]" + _INTL("Indica los Más PP de {1} (máx. 3).", move_name), params
              )
              move.ppup = h
              move.pp = move.total_pp if move.pp > move.total_pp
              if battler && battler.moves[move_indices[cmd]].id == move.id
                battler.moves[move_indices[cmd]].pp = move.pp
              end
            end
          end
        end
      elsif cmd == commands.length - 1   # Restore all PP
        pkmn.heal_PP
        if battler
          battler.moves.each { |m| m.pp = m.total_pp }
        end
      end
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :reset_moves, {
  "name"   => _INTL("Resetear movimientos"),
  "parent" => :moves,
  "usage"  => :pokemon,
  "effect" => proc { |pkmn, battler, battle|
    next if !pbConfirmMessage(_INTL("¿Reemplazar movimientos del Pokémon con los que tendría si fuese salvaje?"))
    pkmn.reset_moves
    pbMessage("\\ts[]" + _INTL("Los movimientos de {1} se han reseteado.", pkmn.name))
  }
})

#===============================================================================
# Other options
#===============================================================================
MenuHandlers.add(:battle_pokemon_debug_menu, :set_item, {
  "name"   => _INTL("Definir objeto"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    commands = [
      _INTL("Cambiar objeto"),
      _INTL("Quitar objeto")
    ]
    loop do
      msg = (pkmn.hasItem?) ? _INTL("Su objeto es {1}.", pkmn.item.name) : _INTL("Sin objeto.")
      cmd = pbMessage("\\ts[]" + msg, commands, -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Change item
        item = pbChooseItemList(pkmn.item_id)
        if item && item != pkmn.item_id
          (battler || pkmn).item = item
          if GameData::Item.get(item).is_mail?
            pkmn.mail = Mail.new(item, _INTL("Texto"), $player.name)
          end
        end
      when 1   # Remove item
        if pkmn.hasItem?
          (battler || pkmn).item = nil
          pkmn.mail = nil
        end
      else
        break
      end
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_ability, {
  "name"   => _INTL("Definir habilidad"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    commands = []
    commands.push(_INTL("Definir la habilidad del Pokémon"))
    commands.push(_INTL("Definir la habilidad del combatiente")) if battler
    commands.push(_INTL("Resetear"))
    loop do
      if battler
        msg = _INTL("La habilidad del combatiente es {1}. La habilidad del Pokémon es {2}.",
                    battler.abilityName, pkmn.ability.name)
      else
        msg = _INTL("La habilidad del Pokémon es {1}.", pkmn.ability.name)
      end
      cmd = pbMessage("\\ts[]" + msg, commands, -1, nil, cmd)
      break if cmd < 0
      cmd = 2 if cmd >= 1 && !battler   # Correct command for Pokémon (no battler)
      case cmd
      when 0   # Set ability for Pokémon
        new_ability = pbChooseAbilityList(pkmn.ability_id)
        if new_ability && new_ability != pkmn.ability_id
          pkmn.ability = new_ability
          battler.ability = pkmn.ability if battler
        end
      when 1   # Set ability for battler
        if battler
          new_ability = pbChooseAbilityList(battler.ability_id)
          if new_ability && new_ability != battler.ability_id
            battler.ability = new_ability
          end
        else
          pbMessage(_INTL("Este Pokémon no está en combate."))
        end
      when 2   # Reset
        pkmn.ability_index = nil
        pkmn.ability = nil
        battler.ability = pkmn.ability if battler
      end
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_nature, {
  "name"   => _INTL("Definir naturaleza"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    commands = []
    ids = []
    GameData::Nature.each do |nature|
      if nature.stat_changes.length == 0
        commands.push(_INTL("{1} (---)", nature.real_name))
      else
        plus_text = ""
        minus_text = ""
        nature.stat_changes.each do |change|
          if change[1] > 0
            plus_text += "/" if !plus_text.empty?
            plus_text += GameData::Stat.get(change[0]).name_brief
          elsif change[1] < 0
            minus_text += "/" if !minus_text.empty?
            minus_text += GameData::Stat.get(change[0]).name_brief
          end
        end
        commands.push(_INTL("{1} (+{2}, -{3})", nature.real_name, plus_text, minus_text))
      end
      ids.push(nature.id)
    end
    commands.push(_INTL("[Reiniciar]"))
    cmd = ids.index(pkmn.nature_id || ids[0])
    loop do
      msg = _INTL("La naturaleza es {1}.", pkmn.nature.name)
      cmd = pbMessage("\\ts[]" + msg, commands, -1, nil, cmd)
      break if cmd < 0
      if cmd >= 0 && cmd < commands.length - 1   # Set nature
        pkmn.nature = ids[cmd]
      elsif cmd == commands.length - 1   # Reset
        pkmn.nature = nil
      end
      battler&.pbUpdate
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_gender, {
  "name"   => _INTL("Definir género"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.singleGendered?
      pbMessage("\\ts[]" + _INTL("{1} solo tiene un género o no tiene ninguno.", pkmn.speciesName))
      next
    end
    cmd = 0
    loop do
      msg = [_INTL("El género es macho."), _INTL("El género es hembra.")][pkmn.male? ? 0 : 1]
      cmd = pbMessage("\\ts[]" + msg,
                      [_INTL("Hacer macho"), _INTL("Hacer hembra"), _INTL("Resetear")], -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Make male
        pkmn.makeMale
        pbMessage("\\ts[]" + _INTL("El género de {1} no se ha podido cambiar.", pkmn.name)) if !pkmn.male?
      when 1   # Make female
        pkmn.makeFemale
        pbMessage("\\ts[]" + _INTL("El género de {1} no se ha podido cambiar.", pkmn.name)) if !pkmn.female?
      when 2   # Reset
        pkmn.gender = nil
      end
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_form, {
  "name"   => _INTL("Definir forma"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    formcmds = [[], []]
    GameData::Species.each do |sp|
      next if sp.species != pkmn.species
      form_name = sp.form_name
      form_name = _INTL("Forma sin nombre") if !form_name || form_name.empty?
      form_name = sprintf("%d: %s", sp.form, form_name)
      formcmds[0].push(sp.form)
      formcmds[1].push(form_name)
      cmd = formcmds[0].length - 1 if pkmn.form == sp.form
    end
    if formcmds[0].length <= 1
      pbMessage("\\ts[]" + _INTL("La especie {1} solo tiene una forma.", pkmn.speciesName))
      next
    end
    loop do
      cmd = pbMessage("\\ts[]" + _INTL("La forma es {1}.", pkmn.form), formcmds[1], -1, nil, cmd)
      break if cmd < 0
      f = formcmds[0][cmd]
      next if f == pkmn.form
      pkmn.forced_form = nil
      if MultipleForms.hasFunction?(pkmn, "getForm")
        next if !pbConfirmMessage(_INTL("Esta especie decide su propia forma. ¿Sobreescribir?"))
        pkmn.forced_form = f
      end
      pkmn.form_simple = f
      battler.form = pkmn.form if battler
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_species, {
  "name"   => _INTL("Definir especies"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    species = pbChooseSpeciesList(pkmn.species)
    if species && species != pkmn.species
      pkmn.species = species
      battler.species = species if battler
      battler&.pbUpdate(true)
      battler.name = pkmn.name if battler
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_shininess, {
  "name"   => _INTL("Definir variocolor"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    loop do
      msg_idx = pkmn.shiny? ? (pkmn.super_shiny? ? 1 : 0) : 2
      msg = [_INTL("Es variocolor."), _INTL("Es super variocolor."), _INTL("Es normal (no variocolor).")][msg_idx]
      cmd = pbMessage("\\ts[]" + msg,
                      [_INTL("Hacer variocolor"),
                       _INTL("Hacer super variocolor"),
                       _INTL("Hacer normal"),
                       _INTL("Resetear")], -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Make shiny
        pkmn.shiny = true
        pkmn.super_shiny = false
      when 1   # Make super shiny
        pkmn.super_shiny = true
      when 2   # Make normal
        pkmn.shiny = false
        pkmn.super_shiny = false
      when 3   # Reset
        pkmn.shiny = nil
        pkmn.super_shiny = nil
      end
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :shadow_pokemon, {
  "name"   => _INTL("Pokémon Oscuros"),
  "parent" => :main,
  "usage"  => :battler,
  "effect" => proc { |pkmn, battler, battle|
    if battler.shadowPokemon?
      loop do
        if battler.inHyperMode?
          msg = _INTL("Pokémon oscuros (en Hiperestado)")
        else
          msg = _INTL("Pokémon oscuros (no en Hiperestado)")
        end
        cmd = pbMessage("\\ts[]" + msg, [_INTL("Alternar Hiperestado"), _INTL("Cancelar")], -1, nil, 0)
        break if cmd != 0
        if battler.inHyperMode?
          pkmn.hyper_mode = false
        elsif battler.fainted? || !battler.pbOwnedByPlayer?
          pbMessage("\\ts[]" + _INTL("El Pokémon está debilitado o no es del jugador. No se puede oner en Hiper Modo."))
        else
          pkmn.hyper_mode = true
        end
      end
    else
      pbMessage("\\ts[]" + _INTL("El Pokémon no es un Pokémon Oscuro."))
    end
  }
})

MenuHandlers.add(:battle_pokemon_debug_menu, :set_effects, {
  "name"   => _INTL("Definir efectos"),
  "parent" => :main,
  "usage"  => :battler,
  "effect" => proc { |pkmn, battler, battle|
    editor = Battle::DebugSetEffects.new(battle, :battler, battler.index)
    editor.update
    editor.dispose
  }
})

