class Battle
  #=============================================================================
  # End Of Round end weather check and weather effects
  #=============================================================================
  def pbEOREndWeather(priority)
    # NOTE: Primordial weather doesn't need to be checked here, because if it
    #       could wear off here, it will have worn off already.
    # Count down weather duration
    @field.weatherDuration -= 1 if @field.weatherDuration > 0
    # Weather wears off
    if @field.weatherDuration == 0
      case @field.weather
      when :Sun       then pbDisplay(_INTL("El sol vuelve a brillar como siempre."))
      when :Rain      then pbDisplay(_INTL("Ha dejado de llover."))
      when :Sandstorm then pbDisplay(_INTL("La tormenta de arena ha amainado."))
      when :Hail      then pbDisplay(_INTL("Ha dejado de granizar."))
      when :ShadowSky then pbDisplay(_INTL("El cielo recuperó su luz."))
      end
      @field.weather = :None
      # Check for form changes caused by the weather changing
      allBattlers.each { |battler| battler.pbCheckFormOnWeatherChange }
      # Start up the default weather
      pbStartWeather(nil, @field.defaultWeather) if @field.defaultWeather != :None
      return if @field.weather == :None
    end
    # Weather continues
    weather_data = GameData::BattleWeather.try_get(@field.weather)
    pbCommonAnimation(weather_data.animation) if weather_data
    case @field.weather
    when :Sun         then pbDisplay(_INTL("El sol pega fuerte."))
    when :Rain        then pbDisplay(_INTL("Sigue lloviendo."))
    when :Sandstorm   then pbDisplay(_INTL("La tormenta de arena arrecia."))
    when :Hail        then pbDisplay(_INTL("Sigue nevando."))
    when :HarshSun    then pbDisplay(_INTL("El sol es realmente abrasador."))
    when :HeavyRain   then pbDisplay(_INTL("La lluvia está siendo muy intensa."))
    when :StrongWinds then pbDisplay(_INTL("El aire está lleno de turbulencias."))
    when :ShadowSky   then pbDisplay(_INTL("El cielo está muy oscuro."))
    end
    # Effects due to weather
    priority.each do |battler|
      # Weather-related abilities
      if battler.abilityActive?
        Battle::AbilityEffects.triggerEndOfRoundWeather(battler.ability, battler.effectiveWeather, battler, self)
        battler.pbFaint if battler.fainted?
      end
      # Weather damage
      pbEORWeatherDamage(battler)
    end
  end

  def pbEORWeatherDamage(battler)
    return if battler.fainted?
    amt = -1
    case battler.effectiveWeather
    when :Sandstorm
      return if !battler.takesSandstormDamage?
      pbDisplay(_INTL("¡La tormenta de arena zarandea a {1}!", battler.pbThis))
      amt = battler.totalhp / 16
    when :Hail
      return if !battler.takesHailDamage?
      pbDisplay(_INTL("¡El granizo golpea a {1}!", battler.pbThis))
      amt = battler.totalhp / 16
    when :ShadowSky
      return if !battler.takesShadowSkyDamage?
      pbDisplay(_INTL("¡El cielo sombrío daña a {1}!", battler.pbThis))
      amt = battler.totalhp / 16
    end
    return if amt < 0
    @scene.pbDamageAnimation(battler)
    battler.pbReduceHP(amt, false)
    battler.pbItemHPHealCheck
    battler.pbFaint if battler.fainted?
  end

  #=============================================================================
  # End Of Round use delayed moves (Future Sight, Doom Desire)
  #=============================================================================
  def pbEORUseFutureSight(position, position_index)
    return if !position || position.effects[PBEffects::FutureSightCounter] == 0
    position.effects[PBEffects::FutureSightCounter] -= 1
    return if position.effects[PBEffects::FutureSightCounter] > 0
    return if !@battlers[position_index] || @battlers[position_index].fainted?   # No target
    moveUser = nil
    allBattlers.each do |battler|
      next if battler.opposes?(position.effects[PBEffects::FutureSightUserIndex])
      next if battler.pokemonIndex != position.effects[PBEffects::FutureSightUserPartyIndex]
      moveUser = battler
      break
    end
    return if moveUser && moveUser.index == position_index   # Target is the user
    if !moveUser   # User isn't in battle, get it from the party
      party = pbParty(position.effects[PBEffects::FutureSightUserIndex])
      pkmn = party[position.effects[PBEffects::FutureSightUserPartyIndex]]
      if pkmn&.able?
        moveUser = Battler.new(self, position.effects[PBEffects::FutureSightUserIndex])
        moveUser.pbInitDummyPokemon(pkmn, position.effects[PBEffects::FutureSightUserPartyIndex])
      end
    end
    return if !moveUser   # User is fainted
    move = position.effects[PBEffects::FutureSightMove]
    pbDisplay(_INTL("¡{1} ha sido alcanzado por {2}!", @battlers[position_index].pbThis,
                    GameData::Move.get(move).name))
    # NOTE: Future Sight failing against the target here doesn't count towards
    #       Stomping Tantrum.
    userLastMoveFailed = moveUser.lastMoveFailed
    @futureSight = true
    moveUser.pbUseMoveSimple(move, position_index)
    @futureSight = false
    moveUser.lastMoveFailed = userLastMoveFailed
    @battlers[position_index].pbFaint if @battlers[position_index].fainted?
    position.effects[PBEffects::FutureSightCounter]        = 0
    position.effects[PBEffects::FutureSightMove]           = nil
    position.effects[PBEffects::FutureSightUserIndex]      = -1
    position.effects[PBEffects::FutureSightUserPartyIndex] = -1
  end

  #=============================================================================
  # End Of Round healing from Wish
  #=============================================================================
  def pbEORWishHealing
    @positions.each_with_index do |pos, idxPos|
      next if !pos || pos.effects[PBEffects::Wish] == 0
      pos.effects[PBEffects::Wish] -= 1
      next if pos.effects[PBEffects::Wish] > 0
      next if !@battlers[idxPos] || !@battlers[idxPos].canHeal?
      wishMaker = pbThisEx(idxPos, pos.effects[PBEffects::WishMaker])
      @battlers[idxPos].pbRecoverHP(pos.effects[PBEffects::WishAmount])
      pbDisplay(_INTL("¡{1} se ha hecho realidad!", wishMaker))
    end
  end

  #=============================================================================
  # End Of Round Sea of Fire damage (Fire Pledge + Grass Pledge combination)
  #=============================================================================
  def pbEORSeaOfFireDamage(priority)
    2.times do |side|
      next if sides[side].effects[PBEffects::SeaOfFire] == 0
      sides[side].effects[PBEffects::SeaOfFire] -= 1
      next if sides[side].effects[PBEffects::SeaOfFire] == 0
      pbCommonAnimation("SeaOfFire") if side == 0
      pbCommonAnimation("SeaOfFireOpp") if side == 1
      priority.each do |battler|
        next if battler.opposes?(side)
        next if !battler.takesIndirectDamage? || battler.pbHasType?(:FIRE)
        @scene.pbDamageAnimation(battler)
        battler.pbTakeEffectDamage(battler.totalhp / 8, false) do |hp_lost|
          pbDisplay(_INTL("¡El mar de llamas ha dañado a {1}!", battler.pbThis))
        end
      end
    end
  end

  #=============================================================================
  # End Of Round healing from Grassy Terrain
  #=============================================================================
  def pbEORTerrainHealing(battler)
    return if battler.fainted?
    # Grassy Terrain (healing)
    if @field.terrain == :Grassy && battler.affectedByTerrain? && battler.canHeal?
      PBDebug.log("[Lingering effect] Grassy Terrain heals #{battler.pbThis(true)}")
      battler.pbRecoverHP(battler.totalhp / 16)
      pbDisplay(_INTL("¡{1} ha recuperado PS!", battler.pbThis))
    end
  end

  #=============================================================================
  # End Of Round various healing effects
  #=============================================================================
  def pbEORHealingEffects(priority)
    # Aqua Ring
    priority.each do |battler|
      next if !battler.effects[PBEffects::AquaRing]
      next if !battler.canHeal?
      hpGain = battler.totalhp / 16
      hpGain = (hpGain * 1.3).floor if battler.hasActiveItem?(:BIGROOT)
      battler.pbRecoverHP(hpGain)
      pbDisplay(_INTL("¡{1} ha recuperado algunos PS gracias al manto de agua que rodea su cuerpo!", battler.pbThis(true)))
    end
    # Ingrain
    priority.each do |battler|
      next if !battler.effects[PBEffects::Ingrain]
      next if !battler.canHeal?
      hpGain = battler.totalhp / 16
      hpGain = (hpGain * 1.3).floor if battler.hasActiveItem?(:BIGROOT)
      battler.pbRecoverHP(hpGain)
      pbDisplay(_INTL("¡{1} ha absorbido nutrientes gracias a sus raíces!", battler.pbThis))
    end
    # Leech Seed
    priority.each do |battler|
      next if battler.effects[PBEffects::LeechSeed] < 0
      next if !battler.takesIndirectDamage?
      recipient = @battlers[battler.effects[PBEffects::LeechSeed]]
      next if !recipient || recipient.fainted?
      pbCommonAnimation("LeechSeed", recipient, battler)
      battler.pbTakeEffectDamage(battler.totalhp / 8) do |hp_lost|
        recipient.pbRecoverHPFromDrain(hp_lost, battler,
                                       _INTL("¡Las drenadoras han restado salud a {1}!", battler.pbThis(true)))
        recipient.pbAbilitiesOnDamageTaken
      end
      recipient.pbFaint if recipient.fainted?
    end
  end

  #=============================================================================
  # End Of Round deal damage from status problems
  #=============================================================================
  def pbEORStatusProblemDamage(priority)
    # Damage from poisoning
    priority.each do |battler|
      next if battler.fainted?
      next if battler.status != :POISON
      if battler.statusCount > 0
        battler.effects[PBEffects::Toxic] += 1
        battler.effects[PBEffects::Toxic] = 16 if battler.effects[PBEffects::Toxic] > 16
      end
      if battler.hasActiveAbility?(:POISONHEAL)
        if battler.canHeal?
          anim_name = GameData::Status.get(:POISON).animation
          pbCommonAnimation(anim_name, battler) if anim_name
          pbShowAbilitySplash(battler)
          battler.pbRecoverHP(battler.totalhp / 8)
          if Scene::USE_ABILITY_SPLASH
            pbDisplay(_INTL("{1} ha recuperado PS.", battler.pbThis))
          else
            pbDisplay(_INTL("{1} ha recuperado PS gracias a {2}.", battler.pbThis, battler.abilityName))
          end
          pbHideAbilitySplash(battler)
        end
      elsif battler.takesIndirectDamage?
        battler.droppedBelowHalfHP = false
        dmg = battler.totalhp / 8
        dmg = battler.totalhp * battler.effects[PBEffects::Toxic] / 16 if battler.statusCount > 0
        battler.pbContinueStatus { battler.pbReduceHP(dmg, false) }
        battler.pbItemHPHealCheck
        battler.pbAbilitiesOnDamageTaken
        battler.pbFaint if battler.fainted?
        battler.droppedBelowHalfHP = false
      end
    end
    # Damage from burn
    priority.each do |battler|
      next if battler.status != :BURN || !battler.takesIndirectDamage?
      battler.droppedBelowHalfHP = false
      dmg = (Settings::MECHANICS_GENERATION >= 7) ? battler.totalhp / 16 : battler.totalhp / 8
      dmg = (dmg / 2.0).round if battler.hasActiveAbility?(:HEATPROOF)
      battler.pbContinueStatus { battler.pbReduceHP(dmg, false) }
      battler.pbItemHPHealCheck
      battler.pbAbilitiesOnDamageTaken
      battler.pbFaint if battler.fainted?
      battler.droppedBelowHalfHP = false
    end
    
    # Damage from frostbite
    priority.each do |battler|
      next if battler.status != :FROSTBITE || !battler.takesIndirectDamage?
      battler.droppedBelowHalfHP = false
      dmg = battler.totalhp / 16
      battler.pbContinueStatus { battler.pbReduceHP(dmg, false) }
      battler.pbItemHPHealCheck
      battler.pbAbilitiesOnDamageTaken
      battler.pbFaint if battler.fainted?
      battler.droppedBelowHalfHP = false
    end
  end

  #=============================================================================
  # End Of Round deal damage from effects (except by trapping)
  #=============================================================================
  def pbEOREffectDamage(priority)
    # Damage from sleep (Nightmare)
    priority.each do |battler|
      battler.effects[PBEffects::Nightmare] = false if !battler.asleep?
      next if !battler.effects[PBEffects::Nightmare] || !battler.takesIndirectDamage?
      battler.pbTakeEffectDamage(battler.totalhp / 4) do |hp_lost|
        pbDisplay(_INTL("¡{1} está inmerso en una pesadilla!", battler.pbThis))
      end
    end
    # Curse
    priority.each do |battler|
      next if !battler.effects[PBEffects::Curse] || !battler.takesIndirectDamage?
      battler.pbTakeEffectDamage(battler.totalhp / 4) do |hp_lost|
        pbDisplay(_INTL("¡{1} es víctima de una maldición!", battler.pbThis))
      end
    end
    
    priority.each do |battler|
      next if battler.effects[PBEffects::Splinters] == 0 || !battler.takesIndirectDamage?
      pbCommonAnimation("Splinters", battler)
      battlerTypes = battler.pbTypes(true)
      splinterType = battler.effects[PBEffects::SplintersType] || :QMARKS
      effectiveness = [1, Effectiveness.calculate(splinterType, *battlerTypes)].max
      damage = ((((2.0 * battler.level / 5) + 2).floor * 25 * battler.attack / battler.defense).floor / 50).floor + 2
      damage *= effectiveness.to_f / Effectiveness::NORMAL_EFFECTIVE
      battler.pbTakeEffectDamage(damage) { |hp_lost|
        pbDisplay(_INTL("¡{1} es dañado por las astillas dentadas!", battler.pbThis))
      }
    end
    priority.each do |battler|
      next if !battler.effects[PBEffects::SaltCure] || !battler.takesIndirectDamage?
      pbCommonAnimation("SaltCure", battler)
      fraction = (battler.pbHasType?(:STEEL) || battler.pbHasType?(:WATER)) ? 4 : 8
      battler.pbTakeEffectDamage(battler.totalhp / fraction) { |hp_lost|
        pbDisplay(_INTL("¡{1} es dañado por la salazón!", battler.pbThis))
      }
    end
  end

  #=============================================================================
  # End Of Round deal damage to trapped battlers
  #=============================================================================
  TRAPPING_MOVE_COMMON_ANIMATIONS = {
    :BIND        => "Bind",
    :CLAMP       => "Clamp",
    :FIRESPIN    => "FireSpin",
    :MAGMASTORM  => "MagmaStorm",
    :SANDTOMB    => "SandTomb",
    :WRAP        => "Wrap",
    :INFESTATION => "Infestation"
  }

  def pbEORTrappingDamage(battler)
    return if battler.fainted? || battler.effects[PBEffects::Trapping] == 0
    battler.effects[PBEffects::Trapping] -= 1
    move_name = GameData::Move.get(battler.effects[PBEffects::TrappingMove]).name
    if battler.effects[PBEffects::Trapping] == 0
      pbDisplay(_INTL("¡{1} se liberó de {2}!", battler.pbThis, move_name))
      return
    end
    anim = TRAPPING_MOVE_COMMON_ANIMATIONS[battler.effects[PBEffects::TrappingMove]] || "Wrap"
    pbCommonAnimation(anim, battler)
    return if !battler.takesIndirectDamage?
    hpLoss = (Settings::MECHANICS_GENERATION >= 6) ? battler.totalhp / 8 : battler.totalhp / 16
    if @battlers[battler.effects[PBEffects::TrappingUser]].hasActiveItem?(:BINDINGBAND)
      hpLoss = (Settings::MECHANICS_GENERATION >= 6) ? battler.totalhp / 6 : battler.totalhp / 8
    end
    @scene.pbDamageAnimation(battler)
    battler.pbTakeEffectDamage(hpLoss, false) do |hp_lost|
      pbDisplay(_INTL("¡{1} es dañado por {2}!", battler.pbThis, move_name))
    end
  end

  #=============================================================================
  # End Of Round end effects that apply to a battler
  #=============================================================================
  def pbEORCountDownBattlerEffect(priority, effect)
    priority.each do |battler|
      next if battler.fainted? || battler.effects[effect] == 0
      battler.effects[effect] -= 1
      yield battler if block_given? && battler.effects[effect] == 0
    end
  end

  def pbEOREndBattlerEffects(priority)
    # Taunt
    pbEORCountDownBattlerEffect(priority, PBEffects::Taunt) do |battler|
      pbDisplay(_INTL("¡{1} ya se ha olvidado de la mofa!", battler.pbThis))
    end
    # Encore
    priority.each do |battler|
      next if battler.fainted? || battler.effects[PBEffects::Encore] == 0
      idxEncoreMove = battler.pbEncoredMoveIndex
      if idxEncoreMove >= 0
        battler.effects[PBEffects::Encore] -= 1
        if battler.effects[PBEffects::Encore] == 0 || battler.moves[idxEncoreMove].pp == 0
          battler.effects[PBEffects::Encore] = 0
          pbDisplay(_INTL("¡{1} ya no sufre los efectos de Otra Vez!", battler.pbThis))
        end
      else
        PBDebug.log("[End of effect] #{battler.pbThis}'s encore ended (encored move no longer known)")
        battler.effects[PBEffects::Encore]     = 0
        battler.effects[PBEffects::EncoreMove] = nil
      end
    end
    # Disable/Cursed Body
    pbEORCountDownBattlerEffect(priority, PBEffects::Disable) do |battler|
      battler.effects[PBEffects::DisableMove] = nil
      pbDisplay(_INTL("¡El movimiento de {1} ya no está anulado!", battler.pbThis))
    end
    # Magnet Rise
    pbEORCountDownBattlerEffect(priority, PBEffects::MagnetRise) do |battler|
      pbDisplay(_INTL("¡El campo electromagnético de {1} se ha disipado!", battler.pbThis))
    end
    # Telekinesis
    pbEORCountDownBattlerEffect(priority, PBEffects::Telekinesis) do |battler|
      pbDisplay(_INTL("¡{1} se ha liberado de telequinesis!", battler.pbThis))
    end
    # Heal Block
    pbEORCountDownBattlerEffect(priority, PBEffects::HealBlock) do |battler|
      pbDisplay(_INTL("¡Se han pasado los efectos de Anticura en {1}!", battler.pbThis))
    end
    # Embargo
    pbEORCountDownBattlerEffect(priority, PBEffects::Embargo) do |battler|
      pbDisplay(_INTL("¡{1} ya puede usar objetos de nuevo!", battler.pbThis))
      battler.pbItemTerrainStatBoostCheck
    end
    # Yawn
    pbEORCountDownBattlerEffect(priority, PBEffects::Yawn) do |battler|
      if battler.pbCanSleepYawn?
        PBDebug.log("[Lingering effect] #{battler.pbThis} fell asleep because of Yawn")
        battler.pbSleep
      end
    end
    # Perish Song
    perishSongUsers = []
    priority.each do |battler|
      next if battler.fainted? || battler.effects[PBEffects::PerishSong] == 0
      battler.effects[PBEffects::PerishSong] -= 1
      pbDisplay(_INTL("El contador de {1} bajó a {2}!", battler.pbThis, battler.effects[PBEffects::PerishSong]))
      if battler.effects[PBEffects::PerishSong] == 0
        perishSongUsers.push(battler.effects[PBEffects::PerishSongUser])
        battler.pbReduceHP(battler.hp)
      end
      battler.pbItemHPHealCheck
      battler.pbFaint if battler.fainted?
    end
    # Judge if all remaining Pokemon fainted by a Perish Song triggered by a single side
    if perishSongUsers.length > 0 &&
       ((perishSongUsers.find_all { |idxBattler| opposes?(idxBattler) }.length == perishSongUsers.length) ||
       (perishSongUsers.find_all { |idxBattler| !opposes?(idxBattler) }.length == perishSongUsers.length))
      pbJudgeCheckpoint(@battlers[perishSongUsers[0]])
    end
    
    pbEORCountDownBattlerEffect(priority, PBEffects::Splinters) { |battler|
      pbDisplay(_INTL("¡{1} se liberó de las astillas dentadas!", battler.pbThis))
      battler.effects[PBEffects::SplintersType] = nil
    }
    
    return if @decision > 0
  end

  #=============================================================================
  # End Of Round end effects that apply to one side of the field
  #=============================================================================
  def pbEORCountDownSideEffect(side, effect, msg)
    return if @sides[side].effects[effect] <= 0
    @sides[side].effects[effect] -= 1
    pbDisplay(msg) if @sides[side].effects[effect] == 0
  end

  def pbEOREndSideEffects(side, priority)
    # Reflect
    pbEORCountDownSideEffect(side, PBEffects::Reflect,
                             _INTL("El efecto de Reflejo en {1} se ha disipado.", @battlers[side].pbTeam(true)))
    # Light Screen
    pbEORCountDownSideEffect(side, PBEffects::LightScreen,
                             _INTL("El efecto de Pantalla de Luz en {1} se ha disipado.", @battlers[side].pbTeam(true)))
    # Safeguard
    pbEORCountDownSideEffect(side, PBEffects::Safeguard,
                             _INTL("El efecto de Velo Sagrado en {1} se ha disipado.", @battlers[side].pbTeam(true)))
    # Mist
    pbEORCountDownSideEffect(side, PBEffects::Mist,
                             _INTL("El efecto de Neblina en {1} se ha disipado.", @battlers[side].pbTeam(true)))
    # Tailwind
    pbEORCountDownSideEffect(side, PBEffects::Tailwind,
                             _INTL("Ha cesado el Viento Afín de {1}.", @battlers[side].pbTeam(true)))
    # Lucky Chant
    pbEORCountDownSideEffect(side, PBEffects::LuckyChant,
                             _INTL("El conjuro de {1} se ha desvanecido.", @battlers[side].pbTeam(true)))
    # Pledge Rainbow
    pbEORCountDownSideEffect(side, PBEffects::Rainbow,
                             _INTL("El arcoiris sobre {1} ha desaparecido.", @battlers[side].pbTeam(true)))
    # Pledge Sea of Fire
    pbEORCountDownSideEffect(side, PBEffects::SeaOfFire,
                             _INTL("El mar de llamas que rodeaba a {1} ha desaparecido.", @battlers[side].pbTeam(true)))
    # Pledge Swamp
    pbEORCountDownSideEffect(side, PBEffects::Swamp,
                             _INTL("El pantano que rodeaba a {1} ha desaparecido!", @battlers[side].pbTeam(true)))
    # Aurora Veil
    pbEORCountDownSideEffect(side, PBEffects::AuroraVeil,
                             _INTL("El efecto de Velo Aurora en {1} se ha disipado.", @battlers[side].pbTeam(true)))
  end

  #=============================================================================
  # End Of Round end effects that apply to the whole field
  #=============================================================================
  def pbEORCountDownFieldEffect(effect, msg)
    return if @field.effects[effect] <= 0
    @field.effects[effect] -= 1
    return if @field.effects[effect] > 0
    pbDisplay(msg)
    if effect == PBEffects::MagicRoom
      pbPriority(true).each { |battler| battler.pbItemTerrainStatBoostCheck }
    end
  end

  def pbEOREndFieldEffects(priority)
    # Trick Room
    pbEORCountDownFieldEffect(PBEffects::TrickRoom,
                              _INTL("Se han restaurado las dimensiones alteradas."))
    # Gravity
    pbEORCountDownFieldEffect(PBEffects::Gravity,
                              _INTL("La gravedad ha vuelto a su estado normal."))
    # Water Sport
    pbEORCountDownFieldEffect(PBEffects::WaterSportField,
                              _INTL("Los efectos de Hidrochorro han desaparecido."))
    # Mud Sport
    pbEORCountDownFieldEffect(PBEffects::MudSportField,
                              _INTL("Los efectos de Chapoteo Lodo han desaparecido."))
    # Wonder Room
    pbEORCountDownFieldEffect(PBEffects::WonderRoom,
                              _INTL("¡Los efectos de Zona Extraña sobre la Defensa y la Defensa Especial han desaparecido!"))
    # Magic Room
    pbEORCountDownFieldEffect(PBEffects::MagicRoom,
                              _INTL("Los efectos de Zona Mágica sobre los objetos han desaparecido."))
  end

  #=============================================================================
  # End Of Round end terrain check
  #=============================================================================
  def pbEOREndTerrain
    # Count down terrain duration
    @field.terrainDuration -= 1 if @field.terrainDuration > 0
    # Terrain wears off
    if @field.terrain != :None && @field.terrainDuration == 0
      case @field.terrain
      when :Electric
        @battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
      when :Grassy
        @battle.pbDisplay(_INTL("La hierba ha desaparecido."))
      when :Misty
        @battle.pbDisplay(_INTL("La niebla se ha disipado."))
      when :Psychic
        @battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que se percibía en el terreno de combate."))
      end
      @field.terrain = :None
      allBattlers.each { |battler| battler.pbAbilityOnTerrainChange }
      # Start up the default terrain
      if @field.defaultTerrain != :None
        pbStartTerrain(nil, @field.defaultTerrain, false)
        allBattlers.each { |battler| battler.pbAbilityOnTerrainChange }
        allBattlers.each { |battler| battler.pbItemTerrainStatBoostCheck }
      end
      return if @field.terrain == :None
    end
    # Terrain continues
    terrain_data = GameData::BattleTerrain.try_get(@field.terrain)
    pbCommonAnimation(terrain_data.animation) if terrain_data
    case @field.terrain
    when :Electric then pbDisplay(_INTL("¡Se ha formado un campo de corriente eléctrica en el terreno de combate!"))
    when :Grassy then pbDisplay(_INTL("¡El terreno de combate se ha cubierto de hierba!"))
    when :Misty then pbDisplay(_INTL("¡La niebla ha envuelto el terreno de combate!"))
    when :Psychic then pbDisplay(_INTL("¡El terreno de combate se ha vuelto muy extraño!"))
    end
  end

  #=============================================================================
  # End Of Round end self-inflicted effects on battler
  #=============================================================================
  def pbEOREndBattlerSelfEffects(battler)
    return if battler.fainted?
    # Hyper Mode (Shadow Pokémon)
    if battler.inHyperMode?
      if pbRandom(100) < 10
        battler.pokemon.hyper_mode = false
        pbDisplay(_INTL("¡{1} volvió en sí!", battler.pbThis))
      else
        pbDisplay(_INTL("¡{1} está imbuido de un poder salvaje!", battler.pbThis))
      end
    end
    # Uproar
    if battler.effects[PBEffects::Uproar] > 0
      battler.effects[PBEffects::Uproar] -= 1
      if battler.effects[PBEffects::Uproar] == 0
        pbDisplay(_INTL("{1} se ha calmado.", battler.pbThis))
      else
        pbDisplay(_INTL("¡{1} ha montado un alboroto!", battler.pbThis))
      end
    end
    # Slow Start's end message
    if battler.effects[PBEffects::SlowStart] > 0
      battler.effects[PBEffects::SlowStart] -= 1
      if battler.effects[PBEffects::SlowStart] == 0
        pbDisplay(_INTL("¡{1} finalmente actuó con su potencial!", battler.pbThis))
      end
    end
    
    if battler.effects[PBEffects::Syrupy] > 0
      pbCommonAnimation("Syrupy", battler)
      battler.effects[PBEffects::Syrupy] -= 1
      battler.pbLowerStatStage(:SPEED, 1, battler) if battler.pbCanLowerStatStage?(:SPEED)
      pbDisplay(_INTL("¡{1} se liberó del caramelo pegajoso!", battler.pbThis)) if battler.effects[PBEffects::Syrupy] == 0
    end
  end

  #=============================================================================
  # End Of Round shift distant battlers to middle positions
  #=============================================================================
  def pbEORShiftDistantBattlers
    # Move battlers around if none are near to each other
    # NOTE: This code assumes each side has a maximum of 3 battlers on it, and
    #       is not generalised to larger side sizes.
    if !singleBattle?
      swaps = []   # Each element is an array of two battler indices to swap
      2.times do |side|
        next if pbSideSize(side) == 1   # Only battlers on sides of size 2+ need to move
        # Check if any battler on this side is near any battler on the other side
        anyNear = false
        allSameSideBattlers(side).each do |battler|
          anyNear = allOtherSideBattlers(battler).any? { |other| nearBattlers?(other.index, battler.index) }
          break if anyNear
        end
        break if anyNear
        # No battlers on this side are near any battlers on the other side; try
        # to move them
        # NOTE: If we get to here (assuming both sides are of size 3 or less),
        #       there is definitely only 1 able battler on this side, so we
        #       don't need to worry about multiple battlers trying to move into
        #       the same position. If you add support for a side of size 4+,
        #       this code will need revising to account for that, as well as to
        #       add more complex code to ensure battlers will end up near each
        #       other.
        allSameSideBattlers(side).each do |battler|
          # Get the position to move to
          pos = -1
          case pbSideSize(side)
          when 2 then pos = [2, 3, 0, 1][battler.index]   # The unoccupied position
          when 3 then pos = (side == 0) ? 2 : 3    # The centre position
          end
          next if pos < 0
          # Can't move if the same trainer doesn't control both positions
          idxOwner = pbGetOwnerIndexFromBattlerIndex(battler.index)
          next if pbGetOwnerIndexFromBattlerIndex(pos) != idxOwner
          swaps.push([battler.index, pos])
        end
      end
      # Move battlers around
      swaps.each do |pair|
        next if pbSideSize(pair[0]) == 2 && swaps.length > 1
        next if !pbSwapBattlers(pair[0], pair[1])
        case pbSideSize(pair[1])
        when 2
          pbDisplay(_INTL("¡{1} avanzó!", @battlers[pair[1]].pbThis))
        when 3
          pbDisplay(_INTL("¡{1} se movió al centro!", @battlers[pair[1]].pbThis))
        end
      end
    end
  end

  #=============================================================================
  # Main End Of Round phase method
  #=============================================================================
  def pbEndOfRoundPhase
    PBDebug.log("")
    PBDebug.log("[End of round #{@turnCount + 1}]")
    @endOfRound = true
    @scene.pbBeginEndOfRoundPhase
    pbCalculatePriority           # recalculate speeds
    priority = pbPriority(true)   # in order of fastest -> slowest speeds only
    # Weather
    pbEOREndWeather(priority)
    # Future Sight/Doom Desire
    @positions.each_with_index { |pos, idxPos| pbEORUseFutureSight(pos, idxPos) }
    # Wish
    pbEORWishHealing
    # Sea of Fire damage (Fire Pledge + Grass Pledge combination)
    pbEORSeaOfFireDamage(priority)
    # Status-curing effects/abilities and HP-healing items
    priority.each do |battler|
      pbEORTerrainHealing(battler)
      # Healer, Hydration, Shed Skin
      if battler.abilityActive?
        Battle::AbilityEffects.triggerEndOfRoundHealing(battler.ability, battler, self)
      end
      # Black Sludge, Leftovers
      if battler.itemActive?
        Battle::ItemEffects.triggerEndOfRoundHealing(battler.item, battler, self)
      end
    end
    # Self-curing of status due to affection
    if Settings::AFFECTION_EFFECTS && @internalBattle
      priority.each do |battler|
        next if battler.fainted? || battler.status == :NONE
        next if !battler.pbOwnedByPlayer? || battler.affection_level < 4 || battler.mega?
        next if pbRandom(100) < 80
        old_status = battler.status
        battler.pbCureStatus(false)
        case old_status
        when :SLEEP
          pbDisplay(_INTL("¡{1} se despertó para no decepcionarte!", battler.pbThis))
        when :POISON
          pbDisplay(_INTL("¡{1} logró expulsar el veneno para no decepcionarte!", battler.pbThis))
        when :BURN
          pbDisplay(_INTL("¡{1} curó su quemadura con su pura determinación para no decepcionarte!", battler.pbThis))
        when :PARALYSIS
          pbDisplay(_INTL("¡{1} reunió toda su energía para romper su parálisis para no decepcionarte!", battler.pbThis))
        when :FROZEN
          pbDisplay(_INTL("¡{1} derritió el hielo con su ardiente determinación para no decepcionarte!", battler.pbThis))
        end
      end
    end
    # Healing from Aqua Ring, Ingrain, Leech Seed
    pbEORHealingEffects(priority)
    # Damage from Hyper Mode (Shadow Pokémon)
    priority.each do |battler|
      next if !battler.inHyperMode? || @choices[battler.index][0] != :UseMove
      hpLoss = battler.totalhp / 24
      @scene.pbDamageAnimation(battler)
      battler.pbReduceHP(hpLoss, false)
      pbDisplay(_INTL("¡El poder salvaje hiere a {1}!", battler.pbThis(true)))
      battler.pbFaint if battler.fainted?
    end
    # Damage from poison/burn
    pbEORStatusProblemDamage(priority)
    # Damage from Nightmare and Curse
    pbEOREffectDamage(priority)
    # Trapping attacks (Bind/Clamp/Fire Spin/Magma Storm/Sand Tomb/Whirlpool/Wrap)
    priority.each { |battler| pbEORTrappingDamage(battler) }
    # Octolock
    priority.each do |battler|
      next if battler.fainted? || battler.effects[PBEffects::Octolock] < 0
      pbCommonAnimation("Octolock", battler)
      battler.pbLowerStatStage(:DEFENSE, 1, nil) if battler.pbCanLowerStatStage?(:DEFENSE)
      battler.pbLowerStatStage(:SPECIAL_DEFENSE, 1, nil) if battler.pbCanLowerStatStage?(:SPECIAL_DEFENSE)
      battler.pbItemOnStatDropped
    end
    # Effects that apply to a battler that wear off after a number of rounds
    pbEOREndBattlerEffects(priority)
    # Check for end of battle (i.e. because of Perish Song)
    if @decision > 0
      pbGainExp
      return
    end
    # Effects that apply to a side that wear off after a number of rounds
    2.times { |side| pbEOREndSideEffects(side, priority) }
    # Effects that apply to the whole field that wear off after a number of rounds
    pbEOREndFieldEffects(priority)
    # End of terrains
    pbEOREndTerrain
    priority.each do |battler|
      # Self-inflicted effects that wear off after a number of rounds
      pbEOREndBattlerSelfEffects(battler)
      # Bad Dreams, Moody, Speed Boost
      if battler.abilityActive?
        Battle::AbilityEffects.triggerEndOfRoundEffect(battler.ability, battler, self)
      end
      # Flame Orb, Sticky Barb, Toxic Orb
      if battler.itemActive?
        Battle::ItemEffects.triggerEndOfRoundEffect(battler.item, battler, self)
      end
      # Harvest, Pickup, Ball Fetch
      if battler.abilityActive?
        Battle::AbilityEffects.triggerEndOfRoundGainItem(battler.ability, battler, self)
      end
    end
    pbGainExp
    return if @decision > 0
    # Form checks
    priority.each { |battler| battler.pbCheckForm(true) }
    # Switch Pokémon in if possible
    pbEORSwitch
    return if @decision > 0
    # In battles with at least one side of size 3+, move battlers around if none
    # are near to any foes
    pbEORShiftDistantBattlers
    # Try to make Trace work, check for end of primordial weather
    priority.each { |battler| battler.pbContinualAbilityChecks }
    # Reset/count down battler-specific effects (no messages)
    allBattlers.each do |battler|
      battler.effects[PBEffects::BanefulBunker]    = false
      battler.effects[PBEffects::SilkTrap]         = false
      battler.effects[PBEffects::BurningBulwark]   = false
      battler.effects[PBEffects::Charge]           -= 1 if battler.effects[PBEffects::Charge] > 0
      battler.effects[PBEffects::Counter]          = -1
      battler.effects[PBEffects::CounterTarget]    = -1
      battler.effects[PBEffects::Electrify]        = false
      battler.effects[PBEffects::Endure]           = false
      battler.effects[PBEffects::FirstPledge]      = nil
      battler.effects[PBEffects::Flinch]           = false
      battler.effects[PBEffects::FocusPunch]       = false
      battler.effects[PBEffects::FollowMe]         = 0
      battler.effects[PBEffects::HelpingHand]      = false
      battler.effects[PBEffects::HyperBeam]        -= 1 if battler.effects[PBEffects::HyperBeam] > 0
      battler.effects[PBEffects::KingsShield]      = false
      battler.effects[PBEffects::LaserFocus]       -= 1 if battler.effects[PBEffects::LaserFocus] > 0
      if battler.effects[PBEffects::LockOn] > 0   # Also Mind Reader
        battler.effects[PBEffects::LockOn]         -= 1
        battler.effects[PBEffects::LockOnPos]      = -1 if battler.effects[PBEffects::LockOn] == 0
      end
      battler.effects[PBEffects::MagicBounce]      = false
      battler.effects[PBEffects::MagicCoat]        = false
      battler.effects[PBEffects::MirrorCoat]       = -1
      battler.effects[PBEffects::MirrorCoatTarget] = -1
      battler.effects[PBEffects::Obstruct]         = false
      battler.effects[PBEffects::Powder]           = false
      battler.effects[PBEffects::Prankster]        = false
      battler.effects[PBEffects::PriorityAbility]  = false
      battler.effects[PBEffects::PriorityItem]     = false
      battler.effects[PBEffects::Protect]          = false
      battler.effects[PBEffects::RagePowder]       = false
      battler.effects[PBEffects::Roost]            = false
      battler.effects[PBEffects::Snatch]           = 0
      battler.effects[PBEffects::SpikyShield]      = false
      battler.effects[PBEffects::Spotlight]        = 0
      battler.effects[PBEffects::ThroatChop]       -= 1 if battler.effects[PBEffects::ThroatChop] > 0
      battler.effects[PBEffects::AllySwitch]       = false
      battler.lastHPLost                           = 0
      battler.lastHPLostFromFoe                    = 0
      battler.droppedBelowHalfHP                   = false
      battler.statsDropped                         = false
      battler.tookMoveDamageThisRound              = false
      battler.tookDamageThisRound                  = false
      battler.tookPhysicalHit                      = false
      battler.statsRaisedThisRound                 = false
      battler.statsLoweredThisRound                = false
      battler.canRestoreIceFace                    = false
      battler.lastRoundMoveFailed                  = battler.lastMoveFailed
      battler.lastAttacker.clear
      battler.lastFoeAttacker.clear
      if Settings::MECHANICS_GENERATION >= 9
        battler.effects[PBEffects::Charge]   += 1 if battler.effects[PBEffects::Charge]     > 0
      end
      battler.effects[PBEffects::GlaiveRush] -= 1 if battler.effects[PBEffects::GlaiveRush] > 0
    end
    # Reset/count down side-specific effects (no messages)
    2.times do |side|
      @sides[side].effects[PBEffects::CraftyShield]         = false
      if !@sides[side].effects[PBEffects::EchoedVoiceUsed]
        @sides[side].effects[PBEffects::EchoedVoiceCounter] = 0
      end
      @sides[side].effects[PBEffects::EchoedVoiceUsed]      = false
      @sides[side].effects[PBEffects::MatBlock]             = false
      @sides[side].effects[PBEffects::QuickGuard]           = false
      @sides[side].effects[PBEffects::Round]                = false
      @sides[side].effects[PBEffects::WideGuard]            = false
    end
    # Reset/count down field-specific effects (no messages)
    @field.effects[PBEffects::IonDeluge]   = false
    @field.effects[PBEffects::FairyLock]   -= 1 if @field.effects[PBEffects::FairyLock] > 0
    @field.effects[PBEffects::FusionBolt]  = false
    @field.effects[PBEffects::FusionFlare] = false
    @endOfRound = false
  end
end
