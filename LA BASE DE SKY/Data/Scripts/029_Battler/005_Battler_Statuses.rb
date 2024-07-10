class Battle::Battler
  #=============================================================================
  # Generalised checks for whether a status problem can be inflicted
  #=============================================================================
  # NOTE: Not all "does it have this status?" checks use this method. If the
  #       check is leading up to curing self of that status condition, then it
  #       will look at the value of @status directly instead - if it is that
  #       status condition then it is curable. This method only checks for
  #       "counts as having that status", which includes Comatose which can't be
  #       cured.
  def pbHasStatus?(checkStatus)
    ret = false
    if Battle::AbilityEffects.triggerStatusCheckNonIgnorable(self.ability, self, checkStatus)
      ret = true
    end
    return ret if ret
    case checkStatus
      when :FROZEN
        return true if @status == :FROSTBITE && Settings::FREEZE_EFFECTS_CAUSE_FROSTBITE
    end
    return ret
  end

  def pbHasAnyStatus?
    if Battle::AbilityEffects.triggerStatusCheckNonIgnorable(self.ability, self, nil)
      return true
    end
    return @status != :NONE
  end

  def pbCanInflictStatus?(newStatus, user, showMessages, move = nil, ignoreStatus = false)
    originalStatus = newStatus
    case newStatus
      when :FROZEN then newStatus = :FROSTBITE if Settings::FREEZE_EFFECTS_CAUSE_FROSTBITE
    end
    return false if fainted?
    self_inflicted = (user && user.index == @index)   # Rest and Flame Orb/Toxic Orb only
    # Already have that status problem
    if self.status == newStatus && !ignoreStatus
      if showMessages
        msg = ""
        case self.status
        when :SLEEP     then msg = _INTL("¡{1} ya está dormido!", pbThis)
        when :POISON    then msg = _INTL("¡{1} ya está envenenado!", pbThis)
        when :BURN      then msg = _INTL("¡{1} ya está quemado!", pbThis)
        when :PARALYSIS then msg = _INTL("¡{1} ya está paralizado!", pbThis)
        when :FROZEN    then msg = _INTL("¡{1} ya está congelado!", pbThis)
        end
        @battle.pbDisplay(msg)
      end
      return false
    end
    # Trying to replace a status problem with another one
    if self.status != :NONE && !ignoreStatus && !(self_inflicted && move)   # Rest can replace a status problem
      @battle.pbDisplay(_INTL("No afecta a {1}...", pbThis(true))) if showMessages
      return false
    end
    # Trying to inflict a status problem on a Pokémon behind a substitute
    if @effects[PBEffects::Substitute] > 0 && !(move && move.ignoresSubstitute?(user)) &&
       !self_inflicted
      @battle.pbDisplay(_INTL("No afecta a {1}...", pbThis(true))) if showMessages
      return false
    end
    # Weather immunity
    if newStatus == :FROZEN && [:Sun, :HarshSun].include?(effectiveWeather)
      @battle.pbDisplay(_INTL("No afecta a {1}...", pbThis(true))) if showMessages
      return false
    end
    # Terrains immunity
    if affectedByTerrain?
      case @battle.field.terrain
      when :Electric
        if newStatus == :SLEEP
          if showMessages
            @battle.pbDisplay(_INTL("¡El campo eléctrico ha protegido a {1}!", pbThis(true)))
          end
          return false
        end
      when :Misty
        @battle.pbDisplay(_INTL("¡El campo de niebla ha protegido a {1}!", pbThis(true))) if showMessages
        return false
      end
    end
    # Uproar immunity
    if newStatus == :SLEEP && !(hasActiveAbility?(:SOUNDPROOF) && !@battle.moldBreaker)
      @battle.allBattlers.each do |b|
        next if b.effects[PBEffects::Uproar] == 0
        @battle.pbDisplay(_INTL("¡El alboroto mantiene a {1} despierto!", pbThis(true))) if showMessages
        return false
      end
    end
    # Type immunities
    hasImmuneType = false
    case newStatus
    when :SLEEP
      # No type is immune to sleep
    when :POISON
      if !(user && user.hasActiveAbility?(:CORROSION))
        hasImmuneType |= pbHasType?(:POISON)
        hasImmuneType |= pbHasType?(:STEEL)
      end
    when :BURN
      hasImmuneType |= pbHasType?(:FIRE)
    when :PARALYSIS
      hasImmuneType |= pbHasType?(:ELECTRIC) && Settings::MORE_TYPE_EFFECTS
    when :FROZEN
      hasImmuneType |= pbHasType?(:ICE)
    end
    if hasImmuneType
      @battle.pbDisplay(_INTL("No afecta a {1}...", pbThis(true))) if showMessages
      return false
    end
    # Ability immunity
    immuneByAbility = false
    immAlly = nil
    if Battle::AbilityEffects.triggerStatusImmunityNonIgnorable(self.ability, self, newStatus)
      immuneByAbility = true
    elsif self_inflicted || !@battle.moldBreaker
      if abilityActive? && Battle::AbilityEffects.triggerStatusImmunity(self.ability, self, newStatus)
        immuneByAbility = true
      else
        allAllies.each do |b|
          next if !b.abilityActive?
          next if !Battle::AbilityEffects.triggerStatusImmunityFromAlly(b.ability, self, newStatus)
          immuneByAbility = true
          immAlly = b
          break
        end
      end
    end
    if immuneByAbility
      if showMessages
        @battle.pbShowAbilitySplash(immAlly || self)
        msg = ""
        if Battle::Scene::USE_ABILITY_SPLASH
          case newStatus
          when :SLEEP     then msg = _INTL("¡{1} permanece despierto!", pbThis)
          when :POISON    then msg = _INTL("¡{1} no puede ser envenenado!", pbThis)
          when :BURN      then msg = _INTL("¡{1} no puede ser quemado!", pbThis)
          when :PARALYSIS then msg = _INTL("¡{1} no puede ser paralizado!", pbThis)
          when :FROZEN    then msg = _INTL("¡{1} no puede ser congelado!", pbThis)
          end
        elsif immAlly
          case newStatus
          when :SLEEP
            msg = _INTL("¡{1} permanece despierto por la habilidad {3} de {2}!",
                        pbThis, immAlly.pbThis(true), immAlly.abilityName)
          when :POISON
            msg = _INTL("¡{1} no puede ser envenenado por la habilidad {3} de {2}!",
                        pbThis, immAlly.pbThis(true), immAlly.abilityName)
          when :BURN
            msg = _INTL("¡{1} no puede ser quemado por la habilidad {3} de {2}!",
                        pbThis, immAlly.pbThis(true), immAlly.abilityName)
          when :PARALYSIS
            msg = _INTL("¡{1} no puede ser paralizado por la habilidad {3} de {2}!",
                        pbThis, immAlly.pbThis(true), immAlly.abilityName)
          when :FROZEN
            msg = _INTL("¡{1} no puede ser congelado because of {2}'s {3}!",
                        pbThis, immAlly.pbThis(true), immAlly.abilityName)
          end
        else
          case newStatus
          when :SLEEP     then msg = _INTL("¡{1} permanece despierto por la habilidad {2}!", pbThis, abilityName)
          when :POISON    then msg = _INTL("¡La habilidad {1} de {2} previene envenenamiento!", pbThis, abilityName)
          when :BURN      then msg = _INTL("¡La habilidad {1} de {2} previene quemaduras!", pbThis, abilityName)
          when :PARALYSIS then msg = _INTL("¡La habilidad {1} de {2} previene paralisis!", pbThis, abilityName)
          when :FROZEN    then msg = _INTL("¡La habilidad {1} de {2} previene congelación!", pbThis, abilityName)
          end
        end
        @battle.pbDisplay(msg)
        @battle.pbHideAbilitySplash(immAlly || self)
      end
      return false
    end
    # Safeguard immunity
    if pbOwnSide.effects[PBEffects::Safeguard] > 0 && !self_inflicted && move &&
       !(user && user.hasActiveAbility?(:INFILTRATOR))
      @battle.pbDisplay(_INTL("¡{1} se ha protegido con Velo Sagrado!", pbThis)) if showMessages
      return false
    end
    return true
  end

  def pbCanSynchronizeStatus?(newStatus, user)
    return false if fainted?
    # Trying to replace a status problem with another one
    return false if self.status != :NONE
    # Terrain immunity
    return false if @battle.field.terrain == :Misty && affectedByTerrain?
    # Type immunities
    hasImmuneType = false
    case newStatus
    when :POISON
      # NOTE: user will have Synchronize, so it can't have Corrosion.
      if !(user && user.hasActiveAbility?(:CORROSION))
        hasImmuneType |= pbHasType?(:POISON)
        hasImmuneType |= pbHasType?(:STEEL)
      end
    when :BURN
      hasImmuneType |= pbHasType?(:FIRE)
    when :PARALYSIS
      hasImmuneType |= pbHasType?(:ELECTRIC) && Settings::MORE_TYPE_EFFECTS
    end
    return false if hasImmuneType
    # Ability immunity
    if Battle::AbilityEffects.triggerStatusImmunityNonIgnorable(self.ability, self, newStatus)
      return false
    end
    if abilityActive? && Battle::AbilityEffects.triggerStatusImmunity(self.ability, self, newStatus)
      return false
    end
    allAllies.each do |b|
      next if !b.abilityActive?
      next if !Battle::AbilityEffects.triggerStatusImmunityFromAlly(b.ability, self, newStatus)
      return false
    end
    # Safeguard immunity
    # NOTE: user will have Synchronize, so it can't have Infiltrator.
    if pbOwnSide.effects[PBEffects::Safeguard] > 0 &&
       !(user && user.hasActiveAbility?(:INFILTRATOR))
      return false
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to check if Synchronize should fail to pass Drowsy/Frostbite.
  #-----------------------------------------------------------------------------
  alias paldea_pbCanSynchronizeStatus? pbCanSynchronizeStatus?
  def pbCanSynchronizeStatus?(newStatus, target)
    ret = paldea_pbCanSynchronizeStatus?(newStatus, target)
    return false if !ret
    return false if newStatus == :FROSTBITE && pbHasType?(:ICE)
    case newStatus
    when :FROSTBITE then newStatus = :FROZEN
    end
    return false if Battle::AbilityEffects.triggerStatusImmunityNonIgnorable(self.ability, self, newStatus)
    return false if abilityActive? && Battle::AbilityEffects.triggerStatusImmunity(self.ability, self, newStatus)
    allAllies.each do |b|
      next if !b.abilityActive?
      next if !Battle::AbilityEffects.triggerStatusImmunityFromAlly(b.ability, self, newStatus)
      return false
    end
    return true
  end

  #=============================================================================
  # Generalised infliction of status problem
  #=============================================================================
  def pbInflictStatus(newStatus, newStatusCount = 0, msg = nil, user = nil)
    case newStatus
      when :FROZEN then newStatus = :FROSTBITE if Settings::FREEZE_EFFECTS_CAUSE_FROSTBITE
    end
    
    # Inflict the new status
    self.status      = newStatus
    self.statusCount = newStatusCount
    @effects[PBEffects::Toxic] = 0
    # Show animation
    if newStatus == :POISON && newStatusCount > 0
      @battle.pbCommonAnimation("Toxic", self)
    else
      anim_name = GameData::Status.get(newStatus).animation
      @battle.pbCommonAnimation(anim_name, self) if anim_name
    end
    # Show message
    if msg && !msg.empty?
      @battle.pbDisplay(msg)
    else
      case newStatus
      when :SLEEP
        @battle.pbDisplay(_INTL("¡{1} se durmió!", pbThis))
      when :POISON
        if newStatusCount > 0
          @battle.pbDisplay(_INTL("¡{1} ha sido gravemente envenendo!", pbThis))
        else
          @battle.pbDisplay(_INTL("¡{1} se ha envenenado!", pbThis))
        end
      when :BURN
        @battle.pbDisplay(_INTL("¡{1} se ha quemado!", pbThis))
      when :PARALYSIS
        @battle.pbDisplay(_INTL("¡{1} sufre parálisis! ¡Quizás no se pueda mover!", pbThis))
      when :FROZEN
        @battle.pbDisplay(_INTL("¡{1} está congelado!", pbThis))
      end
    end
    PBDebug.log("[Status change] #{pbThis}'s sleep count is #{newStatusCount}") if newStatus == :SLEEP
    # Form change check
    pbCheckFormOnStatusChange
    # Synchronize
    if abilityActive?
      Battle::AbilityEffects.triggerOnStatusInflicted(self.ability, self, user, newStatus)
    end
    # Status cures
    pbItemStatusCureCheck
    pbAbilityStatusCureCheck
    # Petal Dance/Outrage/Thrash get cancelled immediately by falling asleep
    # NOTE: I don't know why this applies only to Outrage and only to falling
    #       asleep (i.e. it doesn't cancel Rollout/Uproar/other multi-turn
    #       moves, and it doesn't cancel any moves if self becomes frozen/
    #       disabled/anything else). This behaviour was tested in Gen 5.
    if @status == :SLEEP && @effects[PBEffects::Outrage] > 0
      @effects[PBEffects::Outrage] = 0
      @currentMove = nil
    end
  end

  #=============================================================================
  # Sleep
  #=============================================================================
  def asleep?
    return pbHasStatus?(:SLEEP)
  end

  def pbCanSleep?(user, showMessages, move = nil, ignoreStatus = false)
    return pbCanInflictStatus?(:SLEEP, user, showMessages, move, ignoreStatus)
  end

  def pbCanSleepYawn?
    return false if self.status != :NONE
    if affectedByTerrain? && [:Electric, :Misty].include?(@battle.field.terrain)
      return false
    end
    if !hasActiveAbility?(:SOUNDPROOF) && @battle.allBattlers.any? { |b| b.effects[PBEffects::Uproar] > 0 }
      return false
    end
    if Battle::AbilityEffects.triggerStatusImmunityNonIgnorable(self.ability, self, :SLEEP)
      return false
    end
    # NOTE: Bulbapedia claims that Flower Veil shouldn't prevent sleep due to
    #       drowsiness, but I disagree because that makes no sense. Also, the
    #       comparable Sweet Veil does prevent sleep due to drowsiness.
    if abilityActive? && Battle::AbilityEffects.triggerStatusImmunity(self.ability, self, :SLEEP)
      return false
    end
    allAllies.each do |b|
      next if !b.abilityActive?
      next if !Battle::AbilityEffects.triggerStatusImmunityFromAlly(b.ability, self, :SLEEP)
      return false
    end
    # NOTE: Bulbapedia claims that Safeguard shouldn't prevent sleep due to
    #       drowsiness. I disagree with this too. Compare with the other sided
    #       effects Misty/Electric Terrain, which do prevent it.
    return false if pbOwnSide.effects[PBEffects::Safeguard] > 0
    return true
  end

  def pbSleep(msg = nil)
    pbInflictStatus(:SLEEP, pbSleepDuration, msg)
  end

  def pbSleepSelf(msg = nil, duration = -1)
    pbInflictStatus(:SLEEP, pbSleepDuration(duration), msg)
  end

  def pbSleepDuration(duration = -1)
    duration = 2 + @battle.pbRandom(3) if duration <= 0
    duration = (duration / 2).floor if hasActiveAbility?(:EARLYBIRD)
    return duration
  end

  #=============================================================================
  # Poison
  #=============================================================================
  def poisoned?
    return pbHasStatus?(:POISON)
  end

  def pbCanPoison?(user, showMessages, move = nil)
    return pbCanInflictStatus?(:POISON, user, showMessages, move)
  end

  def pbCanPoisonSynchronize?(target)
    return pbCanSynchronizeStatus?(:POISON, target)
  end

  def pbPoison(user = nil, msg = nil, toxic = false)
    pbInflictStatus(:POISON, (toxic) ? 1 : 0, msg, user)
  end

  #=============================================================================
  # Burn
  #=============================================================================
  def burned?
    return pbHasStatus?(:BURN)
  end

  def pbCanBurn?(user, showMessages, move = nil)
    return pbCanInflictStatus?(:BURN, user, showMessages, move)
  end

  def pbCanBurnSynchronize?(target)
    return pbCanSynchronizeStatus?(:BURN, target)
  end

  def pbBurn(user = nil, msg = nil)
    pbInflictStatus(:BURN, 0, msg, user)
  end
  
  #-----------------------------------------------------------------------------
  # Frostbite utilities. 
  #-----------------------------------------------------------------------------
  def frostbite?
    return pbHasStatus?(:FROSTBITE)
  end

  def pbCanFrostbite?(user, showMessages, move = nil)
    return pbCanInflictStatus?(:FROSTBITE, user, showMessages, move)
  end

  def pbCanFrostbiteSynchronize?(target)
    return pbCanSynchronizeStatus?(:FROSTBITE, target)
  end

  def pbFrostbite(user = nil, msg = nil)
    pbInflictStatus(:FROSTBITE, 0, msg, user)
  end

  #=============================================================================
  # Paralyze
  #=============================================================================
  def paralyzed?
    return pbHasStatus?(:PARALYSIS)
  end

  def pbCanParalyze?(user, showMessages, move = nil)
    return pbCanInflictStatus?(:PARALYSIS, user, showMessages, move)
  end

  def pbCanParalyzeSynchronize?(target)
    return pbCanSynchronizeStatus?(:PARALYSIS, target)
  end

  def pbParalyze(user = nil, msg = nil)
    pbInflictStatus(:PARALYSIS, 0, msg, user)
  end

  #=============================================================================
  # Freeze
  #=============================================================================
  def frozen?
    return pbHasStatus?(:FROZEN)
  end

  def pbCanFreeze?(user, showMessages, move = nil)
    return pbCanInflictStatus?(:FROZEN, user, showMessages, move)
  end

  def pbFreeze(msg = nil)
    pbInflictStatus(:FROZEN, 0, msg)
  end

  #=============================================================================
  # Generalised status displays
  #=============================================================================
  def pbContinueStatus
    if self.status == :POISON && @statusCount > 0
      @battle.pbCommonAnimation("Toxic", self)
    else
      anim_name = GameData::Status.get(self.status).animation
      @battle.pbCommonAnimation(anim_name, self) if anim_name
    end
    yield if block_given?
    case self.status
    when :SLEEP
      @battle.pbDisplay(_INTL("{1} está dormido como un tronco.", pbThis))
    when :POISON
      @battle.pbDisplay(_INTL("¡El veneno resta PS a el {1}!", pbThis))
    when :BURN
      @battle.pbDisplay(_INTL("¡El {1} se resiente de la quemadura!", pbThis))
    when :PARALYSIS
      @battle.pbDisplay(_INTL("¡{1} está paralizado! ¡No se puede mover!", pbThis))
    when :FROZEN
      @battle.pbDisplay(_INTL("¡{1} está congelado!", pbThis))
    when :FROSTBITE
      @battle.pbDisplay(_INTL("¡{1} se resiente de la congelación!", pbThis))
    end
    PBDebug.log("[Status continues] #{pbThis}'s sleep count is #{@statusCount}") if self.status == :SLEEP
  end

  def pbCureStatus(showMessages = true)
    oldStatus = status
    self.status = :NONE
    if showMessages
      case oldStatus
      when :SLEEP     then @battle.pbDisplay(_INTL("{1} se ha despertado.", pbThis))
      when :POISON    then @battle.pbDisplay(_INTL("{1} se ha curado del envenenamiento.", pbThis))
      when :BURN      then @battle.pbDisplay(_INTL("La quemadura de {1} se ha curado.", pbThis))
      when :PARALYSIS then @battle.pbDisplay(_INTL("{1} se ha curado de paralisis.", pbThis))
      when :FROZEN    then @battle.pbDisplay(_INTL("{1} se ha descongelado", pbThis))
      when :FROSTBITE then @battle.pbDisplay(_INTL("{1} se ha descongelado", pbThis))
      end
    end
    PBDebug.log("[Status change] #{pbThis}'s status was cured") if !showMessages
  end

  #=============================================================================
  # Confusion
  #=============================================================================
  def pbCanConfuse?(user = nil, showMessages = true, move = nil, selfInflicted = false)
    return false if fainted?
    if @effects[PBEffects::Confusion] > 0
      @battle.pbDisplay(_INTL("{1} ya está confuso.", pbThis)) if showMessages
      return false
    end
    if @effects[PBEffects::Substitute] > 0 && !(move && move.ignoresSubstitute?(user)) &&
       !selfInflicted
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if showMessages
      return false
    end
    # Terrains immunity
    if affectedByTerrain? && @battle.field.terrain == :Misty && Settings::MECHANICS_GENERATION >= 7
      @battle.pbDisplay(_INTL("¡El campo de niebla ha protegido a {1}!", pbThis(true))) if showMessages
      return false
    end
    if (selfInflicted || !@battle.moldBreaker) && hasActiveAbility?(:OWNTEMPO)
      if showMessages
        @battle.pbShowAbilitySplash(self)
        if Battle::Scene::USE_ABILITY_SPLASH
          @battle.pbDisplay(_INTL("¡{1} no se ha confundido!", pbThis))
        else
          @battle.pbDisplay(_INTL("¡{2} de {1} previene la confusión!", pbThis, abilityName))
        end
        @battle.pbHideAbilitySplash(self)
      end
      return false
    end
    if pbOwnSide.effects[PBEffects::Safeguard] > 0 && !selfInflicted &&
       !(user && user.hasActiveAbility?(:INFILTRATOR))
      @battle.pbDisplay(_INTL("¡{1} se ha protegido con Velo Sagrado!", pbThis)) if showMessages
      return false
    end
    return true
  end

  def pbCanConfuseSelf?(showMessages)
    return pbCanConfuse?(nil, showMessages, nil, true)
  end

  def pbConfuse(msg = nil)
    @effects[PBEffects::Confusion] = pbConfusionDuration
    @battle.pbCommonAnimation("Confusion", self)
    msg = _INTL("¡{1} se ha confundido!", pbThis) if nil_or_empty?(msg)
    @battle.pbDisplay(msg)
    PBDebug.log("[Lingering effect] #{pbThis}'s confusion count is #{@effects[PBEffects::Confusion]}")
    # Confusion cures
    pbItemStatusCureCheck
    pbAbilityStatusCureCheck
  end

  def pbConfusionDuration(duration = -1)
    duration = 2 + @battle.pbRandom(4) if duration <= 0
    return duration
  end

  def pbCureConfusion
    @effects[PBEffects::Confusion] = 0
  end

  #=============================================================================
  # Attraction
  #=============================================================================
  def pbCanAttract?(user, showMessages = true)
    return false if fainted?
    return false if !user || user.fainted?
    if @effects[PBEffects::Attract] >= 0
      @battle.pbDisplay(_INTL("No afecta a {1}...", pbThis)) if showMessages
      return false
    end
    agender = user.gender
    ogender = gender
    if agender == 2 || ogender == 2 || agender == ogender
      @battle.pbDisplay(_INTL("No afecta a {1}...", pbThis)) if showMessages
      return false
    end
    if !@battle.moldBreaker
      if hasActiveAbility?([:AROMAVEIL, :OBLIVIOUS])
        if showMessages
          @battle.pbShowAbilitySplash(self)
          if Battle::Scene::USE_ABILITY_SPLASH
            @battle.pbDisplay(_INTL("No afecta a {1}...", pbThis))
          else
            @battle.pbDisplay(_INTL("¡La habilidad {2} de {1} evita el enamoramiento!", pbThis, abilityName))
          end
          @battle.pbHideAbilitySplash(self)
        end
        return false
      else
        allAllies.each do |b|
          next if !b.hasActiveAbility?(:AROMAVEIL)
          if showMessages
            @battle.pbShowAbilitySplash(b)
            if Battle::Scene::USE_ABILITY_SPLASH
              @battle.pbDisplay(_INTL("No afecta a {1}...", pbThis))
            else
              @battle.pbDisplay(_INTL("¡La habilidad {2} de {1} evita el enamoramiento!", b.pbThis, b.abilityName))
            end
            @battle.pbHideAbilitySplash(b)
          end
          return false
        end
      end
    end
    return true
  end

  def pbAttract(user, msg = nil)
    @effects[PBEffects::Attract] = user.index
    @battle.pbCommonAnimation("Attract", self)
    msg = _INTL("¡{1} se ha enamorado!", pbThis) if nil_or_empty?(msg)
    @battle.pbDisplay(msg)
    # Destiny Knot
    if hasActiveItem?(:DESTINYKNOT) && user.pbCanAttract?(self, false)
      user.pbAttract(self, _INTL("¡{1} se ha enamorado por el {2}!", user.pbThis(true), itemName))
    end
    # Attraction cures
    pbItemStatusCureCheck
    pbAbilityStatusCureCheck
  end

  def pbCureAttract
    @effects[PBEffects::Attract] = -1
  end

  #=============================================================================
  # Flinching
  #=============================================================================
  def pbFlinch(_user = nil)
    return if hasActiveAbility?(:INNERFOCUS) && !@battle.moldBreaker
    @effects[PBEffects::Flinch] = true
  end
end

