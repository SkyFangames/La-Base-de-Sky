class Battle::Battler
  #=============================================================================
  # Change HP
  #=============================================================================
  def pbReduceHP(amt, anim = true, registerDamage = true, anyAnim = true)
    amt = amt.round
    amt = @hp if amt > @hp
    amt = 1 if amt < 1 && !fainted?
    oldHP = @hp
    self.hp -= amt
    PBDebug.log("[HP change] #{pbThis} lost #{amt} HP (#{oldHP} -> #{@hp})") if amt > 0
    raise _INTL("PS menores que 0") if @hp < 0
    raise _INTL("PS más grandes que PS totales") if @hp > @totalhp
    @battle.scene.pbHPChanged(self, oldHP, anim) if anyAnim && amt > 0
    if amt > 0 && registerDamage
      @droppedBelowHalfHP = true if @hp < @totalhp / 2 && @hp + amt >= @totalhp / 2
      @tookDamageThisRound = true
      @tookMoveDamageThisRound = true
    end
    return amt
  end

  def pbRecoverHP(amt, anim = true, anyAnim = true)
    amt = amt.round
    amt = @totalhp - @hp if amt > @totalhp - @hp
    amt = 1 if amt < 1 && @hp < @totalhp
    oldHP = @hp
    self.hp += amt
    PBDebug.log("[HP change] #{pbThis} gained #{amt} HP (#{oldHP} -> #{@hp})") if amt > 0
    raise _INTL("PS menores que 0") if @hp < 0
    raise _INTL("PS más grandes que PS totales") if @hp > @totalhp
    @battle.scene.pbHPChanged(self, oldHP, anim) if anyAnim && amt > 0
    @droppedBelowHalfHP = false if @hp >= @totalhp / 2
    return amt
  end

  def pbRecoverHPFromDrain(amt, target, msg = nil)
    if target.hasActiveAbility?(:LIQUIDOOZE, true)
      @battle.pbShowAbilitySplash(target)
      pbReduceHP(amt)
      @battle.pbDisplay(_INTL("¡{1} ha absorbido el lodo líquido!", pbThis))
      @battle.pbHideAbilitySplash(target)
      pbItemHPHealCheck
    else
      msg = _INTL("¡{1} ha perdido energía!", target.pbThis) if nil_or_empty?(msg)
      @battle.pbDisplay(msg)
      if canHeal?
        amt = (amt * 1.3).floor if hasActiveItem?(:BIGROOT)
        pbRecoverHP(amt)
      end
    end
  end

  def pbTakeEffectDamage(amt, show_anim = true)
    @droppedBelowHalfHP = false
    hp_lost = pbReduceHP(amt, show_anim)
    yield hp_lost if block_given?   # Show message
    pbItemHPHealCheck
    pbAbilitiesOnDamageTaken
    pbFaint if fainted?
    @droppedBelowHalfHP = false
  end

  def pbFaint(showMessage = true)
    
    commanderMsg = nil
    if @effects[PBEffects::Commander]
      pairedBattler = @battle.battlers[@effects[PBEffects::Commander][0]]
      batSprite = @battle.scene.sprites["pokemon_#{pairedBattler.index}"]
      if isCommander?
        order = [pbThis, pairedBattler.pbThis(true)]
      else
        order = [pairedBattler.pbThis, pbThis(true)]
        pairedBattler.effects[PBEffects::Commander] = nil
      end
      commanderMsg = _INTL("¡{1} sale de la boca de {2}!", *order)
    end
    
    if !fainted?
      PBDebug.log("!!!***Can't faint with HP greater than 0")
      return
    end
    return if @fainted   # Has already fainted properly
    @battle.pbDisplayBrief(_INTL("¡{1} se debilitó!", pbThis)) if showMessage
    PBDebug.log("[Pokémon fainted] #{pbThis} (#{@index})") if !showMessage
    @battle.scene.pbFaintBattler(self)
    @battle.pbSetDefeated(self) if opposes?
    pbInitEffects(false)
    # Reset status
    self.status      = :NONE
    self.statusCount = 0
    # Lose happiness
    if @pokemon && @battle.internalBattle
      badLoss = @battle.allOtherSideBattlers(@index).any? { |b| b.level >= self.level + 30 }
      @pokemon.changeHappiness((badLoss) ? "faintbad" : "faint")
    end
    # Reset form
    @battle.peer.pbOnLeavingBattle(@battle, @pokemon, @battle.usedInBattle[idxOwnSide][@index / 2])
    @pokemon.makeUnmega if mega?
    @pokemon.makeUnprimal if primal?
    # Do other things
    @battle.pbClearChoice(@index)   # Reset choice
    pbOwnSide.effects[PBEffects::LastRoundFainted] = @battle.turnCount
    if $game_temp.party_direct_damage_taken &&
       $game_temp.party_direct_damage_taken[@pokemonIndex] &&
       pbOwnedByPlayer?
      $game_temp.party_direct_damage_taken[@pokemonIndex] = 0
    end
    # Check other battlers' abilities that trigger upon a battler fainting
    pbAbilitiesOnFainting
    # Check for end of primordial weather
    @battle.pbEndPrimordialWeather
    
    @battle.pbAddFaintedAlly(self)
    if commanderMsg
      @battle.pbDisplay(commanderMsg)
      batSprite.visible = true
    end
  end

  #=============================================================================
  # Move PP
  #=============================================================================
  def pbSetPP(move, pp)
    move.pp = pp
    # No need to care about @effects[PBEffects::Mimic], since Mimic can't copy
    # Mimic
    if move.realMove && move.id == move.realMove.id && !@effects[PBEffects::Transform]
      move.realMove.pp = pp
    end
  end

  def pbReducePP(move)
    return true if usingMultiTurnAttack?
    return true if move.pp < 0          # Don't reduce PP for special calls of moves
    return true if move.total_pp <= 0   # Infinite PP, can always be used
    return false if move.pp == 0        # Ran out of PP, couldn't reduce
    pbSetPP(move, move.pp - 1) if move.pp > 0
    return true
  end

  def pbReducePPOther(move)
    pbSetPP(move, move.pp - 1) if move.pp > 0
  end

  #=============================================================================
  # Change type
  #=============================================================================
  def pbChangeTypes(newType)
    if newType.is_a?(Battle::Battler)
      newTypes = newType.pbTypes
      newTypes.push(:NORMAL) if newTypes.length == 0
      newExtraType = newType.effects[PBEffects::ExtraType]
      newExtraType = nil if newTypes.include?(newExtraType)
      @types = newTypes.clone
      @effects[PBEffects::ExtraType] = newExtraType
    else
      newType = GameData::Type.get(newType).id
      @types = [newType]
      @effects[PBEffects::ExtraType] = nil
    end
    @effects[PBEffects::BurnUp] = false
    @effects[PBEffects::Roost]  = false
    
    #Paldea - Gen 9
    @effects[PBEffects::DoubleShock] = false
    if abilityActive? && @proteanTrigger # Protean/Libero
      Battle::AbilityEffects.triggerOnTypeChange(self.ability, self, newType)
    end 
  end

  def pbResetTypes
    @types = @pokemon.types
    @effects[PBEffects::ExtraType] = nil
    @effects[PBEffects::BurnUp] = false
    @effects[PBEffects::Roost]  = false
    @effects[PBEffects::DoubleShock] = false
  end

  #=============================================================================
  # Forms
  #=============================================================================
  def pbChangeForm(newForm, msg)
    return if fainted? || @effects[PBEffects::Transform] || @form == newForm
    oldForm = @form
    oldDmg = @totalhp - @hp
    self.form = newForm
    pbUpdate(true)
    @hp = @totalhp - oldDmg
    @effects[PBEffects::WeightChange] = 0 if Settings::MECHANICS_GENERATION >= 6
    @battle.scene.pbChangePokemon(self, @pokemon)
    @battle.scene.pbRefreshOne(@index)
    @battle.pbDisplay(msg) if msg && msg != ""
    PBDebug.log("[Form changed] #{pbThis} changed from form #{oldForm} to form #{newForm}")
    @battle.pbSetSeen(self)
  end

  def pbCheckFormOnStatusChange
    return if fainted? || @effects[PBEffects::Transform]
    # Shaymin - reverts if frozen
    if isSpecies?(:SHAYMIN) && ( frozen? || frostbite? )
      pbChangeForm(0, _INTL("¡{1} ha cambiado de forma!", pbThis))
    end
  end

  def pbCheckFormOnMovesetChange
    return if fainted? || @effects[PBEffects::Transform]
    # Keldeo - knowing Secret Sword
    if isSpecies?(:KELDEO)
      newForm = 0
      newForm = 1 if pbHasMove?(:SECRETSWORD)
      pbChangeForm(newForm, _INTL("¡{1} ha cambiado de forma!", pbThis))
    end
  end

  def pbCheckFormOnWeatherChange(ability_changed = false)
    if hasActiveAbility?(:PROTOSYNTHESIS)
      Battle::AbilityEffects.triggerOnSwitchIn(self.ability, self, @battle, false)
    end
    return if fainted? || @effects[PBEffects::Transform]
    # Castform - Forecast
    if isSpecies?(:CASTFORM)
      if hasActiveAbility?(:FORECAST)
        newForm = 0
        case effectiveWeather
        when :Sun, :HarshSun   then newForm = 1
        when :Rain, :HeavyRain then newForm = 2
        when :Hail             then newForm = 3
        end
        if @form != newForm
          @battle.pbShowAbilitySplash(self, true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(newForm, _INTL("¡{1} se ha transformado!", pbThis))
        end
      else
        pbChangeForm(0, _INTL("¡{1} se ha transformado!", pbThis))
      end
    end
    # Cherrim - Flower Gift
    if isSpecies?(:CHERRIM)
      if hasActiveAbility?(:FLOWERGIFT)
        newForm = 0
        newForm = 1 if [:Sun, :HarshSun].include?(effectiveWeather)
        if @form != newForm
          @battle.pbShowAbilitySplash(self, true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(newForm, _INTL("¡{1} se ha transformado!", pbThis))
        end
      else
        pbChangeForm(0, _INTL("¡{1} se ha transformado!", pbThis))
      end
    end
    # Eiscue - Ice Face
    if !ability_changed && isSpecies?(:EISCUE) && self.ability == :ICEFACE &&
       @form == 1 && effectiveWeather == :Hail
      @canRestoreIceFace = true   # Changed form at end of round
    end
  end

  # Checks the Pokémon's form and updates it if necessary. Used for when a
  # Pokémon enters battle (endOfRound=false) and at the end of each round
  # (endOfRound=true).
  def pbCheckForm(endOfRound = false)
    return if fainted? || @effects[PBEffects::Transform]
    
    # Paldea - Gen 9
    if isSpecies?(:TERAPAGOS) && self.ability == :TERASHIFT
      if @form == 0
        @battle.pbShowAbilitySplash(self, true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(1, _INTL("¡{1} se transformó!", pbThis))
      end
    end
    
    # Form changes upon entering battle and when the weather changes
    pbCheckFormOnWeatherChange if !endOfRound
    # Darmanitan - Zen Mode
    if isSpecies?(:DARMANITAN) && self.ability == :ZENMODE
      if @hp <= @totalhp / 2
        if @form.even?
          @battle.pbShowAbilitySplash(self, true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(@form + 1, _INTL("¡{1} activado!", abilityName))
        end
      elsif @form.odd?
        @battle.pbShowAbilitySplash(self, true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(@form - 1, _INTL("¡{1} activado!", abilityName))
      end
    end
    # Minior - Shields Down
    if isSpecies?(:MINIOR) && self.ability == :SHIELDSDOWN
      if @hp > @totalhp / 2   # Turn into Meteor form
        newForm = (@form >= 7) ? @form - 7 : @form
        if @form != newForm
          @battle.pbShowAbilitySplash(self, true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(newForm, _INTL("¡{1} desactivado!", abilityName))
        end
      elsif @form < 7   # Turn into Core form
        @battle.pbShowAbilitySplash(self, true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(@form + 7, _INTL("¡{1} activado!", abilityName))
      end
    end
    # Wishiwashi - Schooling
    if isSpecies?(:WISHIWASHI) && self.ability == :SCHOOLING
      if @level >= 20 && @hp > @totalhp / 4
        if @form != 1
          @battle.pbShowAbilitySplash(self, true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(1, _INTL("¡{1} ha formado un banco!", pbThis))
        end
      elsif @form != 0
        @battle.pbShowAbilitySplash(self, true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(0, _INTL("¡El banco de {1} se ha dispersado!", pbThis))
      end
    end
    # Zygarde - Power Construct
    if isSpecies?(:ZYGARDE) && self.ability == :POWERCONSTRUCT && endOfRound &&
       @hp <= @totalhp / 2 && @form < 2   # Turn into Complete Forme
      newForm = @form + 2
      @battle.pbDisplay(_INTL("¡Sientes la presencia de muchos!"))
      @battle.pbShowAbilitySplash(self, true)
      @battle.pbHideAbilitySplash(self)
      pbChangeForm(newForm, _INTL("¡{1} se ha transformado en su Forma Completa!", pbThis))
    end
    # Morpeko - Hunger Switch
    if isSpecies?(:MORPEKO) && hasActiveAbility?(:HUNGERSWITCH) && endOfRound
      # Intentionally doesn't show the ability splash or a message
      newForm = (@form + 1) % 2
      pbChangeForm(newForm, nil)
    end
  end

  def pbTransform(target)
    oldAbil = @ability_id
    @effects[PBEffects::Transform]        = true
    @effects[PBEffects::TransformSpecies] = target.species
    pbChangeTypes(target)
    self.ability = target.ability
    @attack  = target.attack
    @defense = target.defense
    @spatk   = target.spatk
    @spdef   = target.spdef
    @speed   = target.speed
    GameData::Stat.each_battle { |s| @stages[s.id] = target.stages[s.id] }
    if Settings::NEW_CRITICAL_HIT_RATE_MECHANICS
      @effects[PBEffects::FocusEnergy] = target.effects[PBEffects::FocusEnergy]
      @effects[PBEffects::LaserFocus]  = target.effects[PBEffects::LaserFocus]
    end
    @moves.clear
    target.moves.each_with_index do |m, i|
      @moves[i] = Battle::Move.from_pokemon_move(@battle, Pokemon::Move.new(m.id))
      @moves[i].pp       = 5
      @moves[i].total_pp = 5
    end
    @effects[PBEffects::Disable]      = 0
    @effects[PBEffects::DisableMove]  = nil
    @effects[PBEffects::WeightChange] = target.effects[PBEffects::WeightChange]
    @battle.scene.pbRefreshOne(@index)
    @battle.pbDisplay(_INTL("¡{1} se ha transformado en {2}!", pbThis, target.pbThis(true)))
    pbOnLosingAbility(oldAbil)
    
    # Paldea Gen 9
    rage_counter = @battle.rage_hit_count[@index & 1][@pokemonIndex]
    rage_counter = @battle.pbRageHitCount(target)
  end

  def pbHyperMode; end
end

