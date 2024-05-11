class Battle::Battler
  #=============================================================================
  # Increase stat stages
  #=============================================================================
  def statStageAtMax?(stat)
    return @stages[stat] >= STAT_STAGE_MAXIMUM
  end

  def pbCanRaiseStatStage?(stat, user = nil, move = nil, showFailMsg = false, ignoreContrary = false)
    return false if fainted?
    # Contrary
    if hasActiveAbility?(:CONTRARY) && !ignoreContrary && !@battle.moldBreaker
      return pbCanLowerStatStage?(stat, user, move, showFailMsg, true)
    end
    # Check the stat stage
    if statStageAtMax?(stat)
      if showFailMsg
        @battle.pbDisplay(_INTL("¡{2} de {1} no puede subir más!",
                                pbThis, GameData::Stat.get(stat).name))
      end
      return false
    end
    return true
  end

  def pbRaiseStatStageBasic(stat, increment, ignoreContrary = false)
    if !@battle.moldBreaker
      # Contrary
      if hasActiveAbility?(:CONTRARY) && !ignoreContrary
        return pbLowerStatStageBasic(stat, increment, true)
      end
      # Simple
      increment *= 2 if hasActiveAbility?(:SIMPLE)
    end
    # Change the stat stage
    increment = [increment, STAT_STAGE_MAXIMUM - @stages[stat]].min
    if increment > 0
      stat_name = GameData::Stat.get(stat).name
      new = @stages[stat] + increment
      PBDebug.log("[Stat change] #{pbThis}'s #{stat_name} changed by +#{increment} (#{@stages[stat]} -> #{new})")
      @stages[stat] += increment
      @statsRaisedThisRound = true
    end
    return increment
  end

  def pbRaiseStatStage(stat, increment, user, showAnim = true, ignoreContrary = false)
    # Contrary
    if hasActiveAbility?(:CONTRARY) && !ignoreContrary && !@battle.moldBreaker
      return pbLowerStatStage(stat, increment, user, showAnim, true)
    end
    # Perform the stat stage change
    increment = pbRaiseStatStageBasic(stat, increment, ignoreContrary)
    return false if increment <= 0
    # Stat up animation and message
    @battle.pbCommonAnimation("StatUp", self) if showAnim
    arrStatTexts = [
      _INTL("¡{2} de {1} ha aumentado!", pbThis, GameData::Stat.get(stat).name),
      _INTL("¡{2} de {1} ha aumentado mucho!", pbThis, GameData::Stat.get(stat).name),
      _INTL("¡{2} de {1} ha aumentado muchísimo!", pbThis, GameData::Stat.get(stat).name)
    ]
    @battle.pbDisplay(arrStatTexts[[increment - 1, 2].min])
    # Trigger abilities upon stat gain
    if abilityActive?
      Battle::AbilityEffects.triggerOnStatGain(self.ability, self, stat, user)
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for Opportunist and Mirror Herb checks. - Paldea - Gen 9
  #-----------------------------------------------------------------------------
  alias paldea_pbRaiseStatStage pbRaiseStatStage
  def pbRaiseStatStage(*args)
    ret = paldea_pbRaiseStatStage(*args)
    if ret && !@mirrorHerbUsed && !(hasActiveAbility?(:CONTRARY) && !args[4] && !@battle.moldBreaker)
      addSideStatUps(args[0], args[1])
    end
    return ret
  end

  def pbRaiseStatStageByCause(stat, increment, user, cause, showAnim = true, ignoreContrary = false)
    # Contrary
    if hasActiveAbility?(:CONTRARY) && !ignoreContrary && !@battle.moldBreaker
      return pbLowerStatStageByCause(stat, increment, user, cause, showAnim, true)
    end
    # Perform the stat stage change
    increment = pbRaiseStatStageBasic(stat, increment, ignoreContrary)
    return false if increment <= 0
    # Stat up animation and message
    @battle.pbCommonAnimation("StatUp", self) if showAnim
    if user.index == @index
      arrStatTexts = [
        _INTL("¡{2} de {1} ha aumentado su {3}!", pbThis, cause, GameData::Stat.get(stat).name),
        _INTL("¡{2} de {1} ha aumentado mucho su {3}!", pbThis, cause, GameData::Stat.get(stat).name),
        _INTL("¡{2} de {1} ha aumentado muchísimo su {3}!", pbThis, cause, GameData::Stat.get(stat).name)
      ]
    else
      arrStatTexts = [
        _INTL("¡{2} de {1} ha aumentado {4} de {3}!", user.pbThis, cause, pbThis(true), GameData::Stat.get(stat).name),
        _INTL("¡{2} de {1} ha aumentado mucho {4} de {3}!", user.pbThis, cause, pbThis(true), GameData::Stat.get(stat).name),
        _INTL("¡{2} de {1} ha aumentado muchísimo {4} de {3}!", user.pbThis, cause, pbThis(true), GameData::Stat.get(stat).name)
      ]
    end
    @battle.pbDisplay(arrStatTexts[[increment - 1, 2].min])
    # Trigger abilities upon stat gain
    if abilityActive?
      Battle::AbilityEffects.triggerOnStatGain(self.ability, self, stat, user)
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for Opportunist and Mirror Herb checks. - Paldea - Gen 9
  #-----------------------------------------------------------------------------
  alias paldea_pbRaiseStatStageByCause pbRaiseStatStageByCause
  def pbRaiseStatStageByCause(*args)
    ret = paldea_pbRaiseStatStageByCause(*args)
    if ret && !@mirrorHerbUsed && !(hasActiveAbility?(:CONTRARY) && !args[5] && !@battle.moldBreaker)
      addSideStatUps(args[0], args[1]) 
    end
    return ret
  end

  def pbRaiseStatStageByAbility(stat, increment, user, splashAnim = true)
    return false if fainted?
    ret = false
    @battle.pbShowAbilitySplash(user) if splashAnim
    if pbCanRaiseStatStage?(stat, user, nil, Battle::Scene::USE_ABILITY_SPLASH)
      if Battle::Scene::USE_ABILITY_SPLASH
        ret = pbRaiseStatStage(stat, increment, user)
      else
        ret = pbRaiseStatStageByCause(stat, increment, user, user.abilityName)
      end
    end
    @battle.pbHideAbilitySplash(user) if splashAnim
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for Opportunist and Mirror Herb checks. - Paldea - Gen 9
  #-----------------------------------------------------------------------------
  alias paldea_pbRaiseStatStageByAbility pbRaiseStatStageByAbility
  def pbRaiseStatStageByAbility(*args)
    ret = paldea_pbRaiseStatStageByAbility(*args)
    pbMirrorStatUpsOpposing
    return ret
  end

  #=============================================================================
  # Decrease stat stages
  #=============================================================================
  def statStageAtMin?(stat)
    return @stages[stat] <= -STAT_STAGE_MAXIMUM
  end

  def pbCanLowerStatStage?(stat, user = nil, move = nil, showFailMsg = false,
                           ignoreContrary = false, ignoreMirrorArmor = false)
    return false if fainted?
    
    # Paldea gen 9
    if !user || user.index != @index
      if itemActive?
        return false if Battle::ItemEffects.triggerStatLossImmunity(self.item, self, stat, @battle, showFailMsg)
      end
    end
    
    if !@battle.moldBreaker
      # Contrary
      if hasActiveAbility?(:CONTRARY) && !ignoreContrary
        return pbCanRaiseStatStage?(stat, user, move, showFailMsg, true)
      end
      # Mirror Armor
      if hasActiveAbility?(:MIRRORARMOR) && !ignoreMirrorArmor &&
         user && user.index != @index && !statStageAtMin?(stat)
        return true
      end
    end
    if !user || user.index != @index   # Not self-inflicted
      if @effects[PBEffects::Substitute] > 0 &&
         (ignoreMirrorArmor || !(move && move.ignoresSubstitute?(user)))
        @battle.pbDisplay(_INTL("¡El sustituto recibe el daño en lugar de {1}!", pbThis)) if showFailMsg
        return false
      end
      if pbOwnSide.effects[PBEffects::Mist] > 0 &&
         !(user && user.hasActiveAbility?(:INFILTRATOR))
        @battle.pbDisplay(_INTL("¡Los efectos de la Neblina han protegido a {1}!", pbThis)) if showFailMsg
        return false
      end
      if abilityActive?
        return false if !@battle.moldBreaker && Battle::AbilityEffects.triggerStatLossImmunity(
          self.ability, self, stat, @battle, showFailMsg
        )
        return false if Battle::AbilityEffects.triggerStatLossImmunityNonIgnorable(
          self.ability, self, stat, @battle, showFailMsg
        )
      end
      if !@battle.moldBreaker
        allAllies.each do |b|
          next if !b.abilityActive?
          return false if Battle::AbilityEffects.triggerStatLossImmunityFromAlly(
            b.ability, b, self, stat, @battle, showFailMsg
          )
        end
      end
    end
    # Check the stat stage
    if statStageAtMin?(stat)
      if showFailMsg
        @battle.pbDisplay(_INTL("¡{2} de {1} no puede subir más!",
                                pbThis, GameData::Stat.get(stat).name))
      end
      return false
    end
    return true
  end

  def pbLowerStatStageBasic(stat, increment, ignoreContrary = false)
    if !@battle.moldBreaker
      # Contrary
      if hasActiveAbility?(:CONTRARY) && !ignoreContrary
        return pbRaiseStatStageBasic(stat, increment, true)
      end
      # Simple
      increment *= 2 if hasActiveAbility?(:SIMPLE)
    end
    # Change the stat stage
    increment = [increment, STAT_STAGE_MAXIMUM + @stages[stat]].min
    if increment > 0
      stat_name = GameData::Stat.get(stat).name
      new = @stages[stat] - increment
      PBDebug.log("[Stat change] #{pbThis}'s #{stat_name} changed by -#{increment} (#{@stages[stat]} -> #{new})")
      @stages[stat] -= increment
      @statsLoweredThisRound = true
      @statsDropped = true
    end
    return increment
  end

  def pbLowerStatStage(stat, increment, user, showAnim = true, ignoreContrary = false,
                       mirrorArmorSplash = 0, ignoreMirrorArmor = false)
    if !@battle.moldBreaker
      # Contrary
      if hasActiveAbility?(:CONTRARY) && !ignoreContrary
        return pbRaiseStatStage(stat, increment, user, showAnim, true)
      end
      # Mirror Armor
      if hasActiveAbility?(:MIRRORARMOR) && !ignoreMirrorArmor &&
         user && user.index != @index && !statStageAtMin?(stat)
        if mirrorArmorSplash < 2
          @battle.pbShowAbilitySplash(self)
          if !Battle::Scene::USE_ABILITY_SPLASH
            @battle.pbDisplay(_INTL("¡Se ha activado {2} de {1}!", pbThis, abilityName))
          end
        end
        ret = false
        if user.pbCanLowerStatStage?(stat, self, nil, true, ignoreContrary, true)
          ret = user.pbLowerStatStage(stat, increment, self, showAnim, ignoreContrary, mirrorArmorSplash, true)
        end
        @battle.pbHideAbilitySplash(self) if mirrorArmorSplash.even?   # i.e. not 1 or 3
        return ret
      end
    end
    # Perform the stat stage change
    increment = pbLowerStatStageBasic(stat, increment, ignoreContrary)
    return false if increment <= 0
    # Stat down animation and message
    @battle.pbCommonAnimation("StatDown", self) if showAnim
    arrStatTexts = [
      _INTL("¡{2} de {1} ha disminuido!", pbThis, GameData::Stat.get(stat).name),
      _INTL("¡{2} de {1} ha disminuido mucho!", pbThis, GameData::Stat.get(stat).name),
      _INTL("¡{2} de {1} ha disminuido muchísimo!", pbThis, GameData::Stat.get(stat).name)
    ]
    @battle.pbDisplay(arrStatTexts[[increment - 1, 2].min])
    # Trigger abilities upon stat loss
    if abilityActive?
      Battle::AbilityEffects.triggerOnStatLoss(self.ability, self, stat, user)
    end
    return true
  end

  def pbLowerStatStageByCause(stat, increment, user, cause, showAnim = true,
                              ignoreContrary = false, ignoreMirrorArmor = false)
    if !@battle.moldBreaker
      # Contrary
      if hasActiveAbility?(:CONTRARY) && !ignoreContrary
        return pbRaiseStatStageByCause(stat, increment, user, cause, showAnim, true)
      end
      # Mirror Armor
      if hasActiveAbility?(:MIRRORARMOR) && !ignoreMirrorArmor &&
         user && user.index != @index && !statStageAtMin?(stat)
        @battle.pbShowAbilitySplash(self)
        if !Battle::Scene::USE_ABILITY_SPLASH
          @battle.pbDisplay(_INTL("¡Se ha activado {2} de {1}!", pbThis, abilityName))
        end
        ret = false
        if user.pbCanLowerStatStage?(stat, self, nil, true, ignoreContrary, true)
          ret = user.pbLowerStatStageByCause(stat, increment, self, abilityName, showAnim, ignoreContrary, true)
        end
        @battle.pbHideAbilitySplash(self)
        return ret
      end
    end
    # Perform the stat stage change
    increment = pbLowerStatStageBasic(stat, increment, ignoreContrary)
    return false if increment <= 0
    # Stat down animation and message
    @battle.pbCommonAnimation("StatDown", self) if showAnim
    if user.index == @index
      arrStatTexts = [
        _INTL("¡{2} de {1} ha disminuido su {3}!", pbThis, cause, GameData::Stat.get(stat).name),
        _INTL("¡{2} de {1} ha disminuido mucho su {3}!", pbThis, cause, GameData::Stat.get(stat).name),
        _INTL("¡{2} de {1} ha disminuido muchísimo su {3}!", pbThis, cause, GameData::Stat.get(stat).name)
      ]
    else
      arrStatTexts = [
        _INTL("¡{2} de {1} ha disminuido {4} de {3}!", user.pbThis, cause, pbThis(true), GameData::Stat.get(stat).name),
        _INTL("¡{2} de {1} ha disminuido mucho {4} de {3}!", user.pbThis, cause, pbThis(true), GameData::Stat.get(stat).name),
        _INTL("¡{2} de {1} ha disminuido muchísimo {4} de {3}!", user.pbThis, cause, pbThis(true), GameData::Stat.get(stat).name)
      ]
    end
    @battle.pbDisplay(arrStatTexts[[increment - 1, 2].min])
    # Trigger abilities upon stat loss
    if abilityActive?
      Battle::AbilityEffects.triggerOnStatLoss(self.ability, self, stat, user)
    end
    return true
  end

  def pbLowerStatStageByAbility(stat, increment, user, splashAnim = true, checkContact = false)
    # Paldea - Gen 9
    if hasActiveAbility?(:GUARDDOG) && user.ability == :INTIMIDATE
      return pbRaiseStatStageByAbility(stat, increment, self, true)
    end
    ret = false
    @battle.pbShowAbilitySplash(user) if splashAnim
    if pbCanLowerStatStage?(stat, user, nil, Battle::Scene::USE_ABILITY_SPLASH) &&
       (!checkContact || affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH))
      if Battle::Scene::USE_ABILITY_SPLASH
        ret = pbLowerStatStage(stat, increment, user)
      else
        ret = pbLowerStatStageByCause(stat, increment, user, user.abilityName)
      end
    end
    @battle.pbHideAbilitySplash(user) if splashAnim
    return ret
  end

  def pbLowerAttackStatStageIntimidate(user)
    return false if fainted?
    
    # Paldea - Gen 9
    if !hasActiveAbility?(:CONTRARY) && @effects[PBEffects::Substitute] == 0
      if itemActive? && Battle::ItemEffects.triggerStatLossImmunity(self.item, self, :ATTACK, @battle, true)
        return false
      end
    end
    # NOTE: Substitute intentionally blocks Intimidate even if self has Contrary.
    if @effects[PBEffects::Substitute] > 0
      if Battle::Scene::USE_ABILITY_SPLASH
        @battle.pbDisplay(_INTL("¡El sustituto recibe el daño en lugar de {1}!", pbThis))
      else
        @battle.pbDisplay(_INTL("¡El sustituto de {1} le protegió de {3} de {2}!",
                                pbThis, user.pbThis(true), user.abilityName))
      end
      return false
    end
    if Settings::MECHANICS_GENERATION >= 8 && hasActiveAbility?([:OBLIVIOUS, :OWNTEMPO, :INNERFOCUS, :SCRAPPY])
      @battle.pbShowAbilitySplash(self)
      if Battle::Scene::USE_ABILITY_SPLASH
        @battle.pbDisplay(_INTL("¡{2} de {1} no puede bajar más!", pbThis, GameData::Stat.get(:ATTACK).name))
      else
        @battle.pbDisplay(_INTL("¡{2} de {1} evitó que bajara su {3}!", pbThis, abilityName,
                                GameData::Stat.get(:ATTACK).name))
      end
      @battle.pbHideAbilitySplash(self)
      return false
    end
    if Battle::Scene::USE_ABILITY_SPLASH
      return pbLowerStatStageByAbility(:ATTACK, 1, user, false)
    end
    # NOTE: These checks exist to ensure appropriate messages are shown if
    #       Intimidate is blocked somehow (i.e. the messages should mention the
    #       Intimidate ability by name).
    if !hasActiveAbility?(:CONTRARY)
      if pbOwnSide.effects[PBEffects::Mist] > 0
        @battle.pbDisplay(_INTL("¡Los efectos de Neblina han protegido a {1} de {2} de {3}!",
                                pbThis, user.pbThis(true), user.abilityName))
        return false
      end
      if abilityActive? &&
         (Battle::AbilityEffects.triggerStatLossImmunity(self.ability, self, :ATTACK, @battle, false) ||
          Battle::AbilityEffects.triggerStatLossImmunityNonIgnorable(self.ability, self, :ATTACK, @battle, false))
        @battle.pbDisplay(_INTL("¡Los efectos de {2} han protegido a {1} de {4} de {3}",
                                pbThis, abilityName, user.pbThis(true), user.abilityName))
        return false
      end
      allAllies.each do |b|
        next if !b.abilityActive?
        if Battle::AbilityEffects.triggerStatLossImmunityFromAlly(b.ability, b, self, :ATTACK, @battle, false)
          @battle.pbDisplay(_INTL("¡Los efectos de {3} de {2} han protegido a {1} de {5} de {4}",
                                  pbThis, user.pbThis(true), user.abilityName, b.pbThis(true), b.abilityName))
          return false
        end
      end
    end
    return false if !pbCanLowerStatStage?(:ATTACK, user)
    return pbLowerStatStageByCause(:ATTACK, 1, user, user.abilityName)
  end

  #=============================================================================
  # Reset stat stages
  #=============================================================================
  def hasAlteredStatStages?
    GameData::Stat.each_battle { |s| return true if @stages[s.id] != 0 }
    return false
  end

  def hasRaisedStatStages?
    GameData::Stat.each_battle { |s| return true if @stages[s.id] > 0 }
    return false
  end

  def hasLoweredStatStages?
    GameData::Stat.each_battle { |s| return true if @stages[s.id] < 0 }
    return false
  end

  def pbResetStatStages
    GameData::Stat.each_battle do |s|
      if @stages[s.id] > 0
        @statsLoweredThisRound = true
        @statsDropped = true
      elsif @stages[s.id] < 0
        @statsRaisedThisRound = true
      end
      @stages[s.id] = 0
    end
  end
  
  #-----------------------------------------------------------------------------
  # Used for triggering and consuming Mirror Herb.
  #-----------------------------------------------------------------------------
  def pbItemOpposingStatGainCheck(statUps, item_to_use = nil)
    return if fainted?
    return if !item_to_use && !itemActive?
    itm = item_to_use || self.item
    if Battle::ItemEffects.triggerOnOpposingStatGain(itm, self, @battle, statUps, !item_to_use)
      pbHeldItemTriggered(itm, item_to_use.nil?, false)
    end
  end
  
  #-----------------------------------------------------------------------------
  # General proc for Opportunist and Mirror Herb.
  #-----------------------------------------------------------------------------
  def pbMirrorStatUpsOpposing
    statUps = @battle.sideStatUps[self.idxOwnSide]
    return if fainted? || statUps.empty?
    @battle.allOtherSideBattlers(@index).each do |b|
      next if !b || b.fainted?
      if b.abilityActive?
        Battle::AbilityEffects.triggerOnOpposingStatGain(b.ability, b, @battle, statUps)
      end
      if b.itemActive?
        b.pbItemOpposingStatGainCheck(statUps)
      end
    end
    statUps.clear
  end
  
  #-----------------------------------------------------------------------------
  # Used to tally up the amount of stats raised on each side.
  #-----------------------------------------------------------------------------
  def addSideStatUps(stat, increment)
    statUps = @battle.sideStatUps[self.idxOwnSide]
    statUps[stat] = 0 if !statUps[stat]
    statUps[stat] += increment
  end
end

