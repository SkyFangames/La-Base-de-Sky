#===============================================================================
# Pokemon properties.
#===============================================================================
class Pokemon
  attr_accessor :hp_level, :immunities
  
  #-----------------------------------------------------------------------------
  # HP utilities.
  #-----------------------------------------------------------------------------
  def real_hp;      return (@hp / hp_boost).floor;      end
  def real_totalhp; return (@totalhp / hp_boost).floor; end
  
  #-----------------------------------------------------------------------------
  # Immunities.
  #-----------------------------------------------------------------------------
  def immunities
    return @immunities || []
  end
  
  #-----------------------------------------------------------------------------
  # Used for calculating boosted HP.
  #-----------------------------------------------------------------------------
  def hp_level 
    return @hp_level || 0
  end
  
  def hp_boost
    return [1, self.hp_level].max
  end
  
  def calcHP(base, level, iv, ev)
    return 1 if base == 1
    iv = ev = 0 if Settings::DISABLE_IVS_AND_EVS
    return ((((base * 2 + iv + (ev / 4)) * level / 100).floor + level + 10) * hp_boost).ceil
  end
end

#===============================================================================
# Battler properties.
#===============================================================================
class Battle::Battler
  #-----------------------------------------------------------------------------
  # HP utilities.
  #-----------------------------------------------------------------------------
  def real_hp;       return @pokemon&.real_hp;       end
  def real_totalhp;  return @pokemon&.real_totalhp;  end
  
  #-----------------------------------------------------------------------------
  # Aliased for calculating the correct HP amounts.
  #-----------------------------------------------------------------------------
  alias dx_pbReduceHP pbReduceHP
  def pbReduceHP(*args)
    if @effects[PBEffects::PerishSongUser] >= 0 && @effects[PBEffects::PerishSong] == 0
      @stopBoostedHPScaling = true
    end
    if !@stopBoostedHPScaling
      if self.dynamax?
        args[0] = (args[0] / self.dynamax_boost).round
      else
        args[0] = (args[0] / @pokemon.hp_boost).round
      end
    end
    ret = dx_pbReduceHP(*args)
    @stopBoostedHPScaling = false
    return ret
  end
  
  alias dx_pbRecoverHP pbRecoverHP
  def pbRecoverHP(*args)
    if !@stopBoostedHPScaling
      if self.dynamax?
        args[0] = (args[0] / self.dynamax_boost).round
      else
        args[0] = (args[0] / @pokemon.hp_boost).round
      end
    end
    ret = dx_pbRecoverHP(*args)
    @stopBoostedHPScaling = false
    return ret
  end
  
  alias dx_pbRecoverHPFromDrain pbRecoverHPFromDrain
  def pbRecoverHPFromDrain(*args)
    @stopBoostedHPScaling = true
    dx_pbRecoverHPFromDrain(*args)
  end
  
  #-----------------------------------------------------------------------------
  # Defines whether the battler is considered a raid boss.
  #-----------------------------------------------------------------------------
  def isRaidBoss?
    return false if self.idxOwnSide == 0
    return false if @battle.pbSideBattlerCount(@index) 
    return @pokemon&.immunities.include?(:RAIDBOSS)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to make PP infinite if HP has been boosted.
  #-----------------------------------------------------------------------------
  alias dx_pbReducePP pbReducePP
  def pbReducePP(move)
    return true if @pokemon.immunities.include?(:PPLOSS)
    if move.powerMove? && @powerMoveIndex >= 0
      i = @powerMoveIndex
      pbSetPP(@baseMoves[i], @baseMoves[i].pp - 1)
    end
    return dx_pbReducePP(move)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for primary status immunities.
  #-----------------------------------------------------------------------------
  alias dx_pbCanInflictStatus? pbCanInflictStatus?
  def pbCanInflictStatus?(newStatus, user, showMessages, move = nil, ignoreStatus = false)
    return false if fainted?
    return false if @battle.raidCaptureMode
    self_inflicted = (user && user.index == @index)
    immunities = @pokemon.immunities
    if (immunities.include?(:ALLSTATUS) || immunities.include?(newStatus)) && !self_inflicted && !ignoreStatus
      case newStatus
      when :SLEEP     then msg = _INTL("{1} is completely immune to being put to sleep!", pbThis)
      when :POISON    then msg = _INTL("{1} is completely immune to poisoning!", pbThis)
      when :BURN      then msg = _INTL("{1} is completely immune to burns!", pbThis)
      when :PARALYSIS then msg = _INTL("{1} is completely immune to paralysis!", pbThis)
      when :FROZEN    then msg = _INTL("{1} is completely immune to being frozen!", pbThis)
      when :FROSTBITE then msg = _INTL("{1} is completely immune to frostbite!", pbThis)
      when :DROWSY    then msg = _INTL("{1} is completely immune to becoming drowsy!", pbThis)
      end
      @battle.pbDisplay(msg) if showMessages
      return false
    end
    return dx_pbCanInflictStatus?(newStatus, user, showMessages, move, ignoreStatus)
  end
  
  alias dx_pbCanSynchronizeStatus? pbCanSynchronizeStatus?
  def pbCanSynchronizeStatus?(newStatus, user)
    return false if @battle.raidCaptureMode
    return false if @pokemon.immunities.include?(:ALLSTATUS)
    return false if @pokemon.immunities.include?(newStatus)
    return dx_pbCanSynchronizeStatus?(newStatus, user)
  end
  
  alias dx_pbCanSleepYawn? pbCanSleepYawn?
  def pbCanSleepYawn?
    return false if @battle.raidCaptureMode
    return false if @pokemon.immunities.include?(:ALLSTATUS)
    return false if @pokemon.immunities.include?(:SLEEP)
    return dx_pbCanSleepYawn?
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for secondary status immunities.
  #-----------------------------------------------------------------------------
  alias dx_pbCanConfuse? pbCanConfuse?
  def pbCanConfuse?(*args)
    return false if fainted?
    return false if @battle.raidCaptureMode
    immunities = @pokemon.immunities
    if immunities.include?(:ALLSTATUS) || immunities.include?(:CONFUSED)
      @battle.pbDisplay(_INTL("{1} is completely immune to confusion!", pbThis)) if args[1]
      return false
    end
    return dx_pbCanConfuse?(*args)
  end
  
  alias dx_pbCanAttract? pbCanAttract?
  def pbCanAttract?(user, showMessages = true)
    return false if fainted?
    return false if !user || user.fainted?
    return false if @battle.raidCaptureMode
    immunities = @pokemon.immunities
    if immunities.include?(:ALLSTATUS) || immunities.include?(:ATTRACT)
      @battle.pbDisplay(_INTL("{1} is completely immune to infatuation!", pbThis)) if showMessages
      return false
    end
    return dx_pbCanAttract?(user, showMessages)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for flinch immunity.
  #-----------------------------------------------------------------------------
  alias dx_pbFlinch pbFlinch
  def pbFlinch(_user = nil)
    return false if dynamax?
    return false if @pokemon && @pokemon.immunities.include?(:FLINCH)
    return dx_pbFlinch(_user)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for stat drop immunity.
  #-----------------------------------------------------------------------------
  alias dx_pbCanLowerStatStage? pbCanLowerStatStage?
  def pbCanLowerStatStage?(*args)
    return false if fainted?
    return false if @battle.raidCaptureMode
    if (!args[1] || args[1].index != @index) && 
      @pokemon.immunities.include?(:STATDROPS) && !hasActiveAbility?(:CONTRARY)
      @battle.pbDisplay(_INTL("¡{1} es completamente inmune a que sus estadísticas se vean reducidas!", pbThis)) if args[3]
      return false
    end
    return dx_pbCanLowerStatStage?(*args)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for type changing immunity.
  #-----------------------------------------------------------------------------
  alias dx_canChangeType? canChangeType?
  def canChangeType?
    return false if tera?
    return false if @battle.raidCaptureMode
    return false if @pokemon.immunities.include?(:TYPECHANGE)
    return dx_canChangeType?
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for indirect damage immunity.
  #-----------------------------------------------------------------------------
  alias dx_takesIndirectDamage? takesIndirectDamage?
  def takesIndirectDamage?(showMsg = false)
    return false if fainted?
    return false if @battle.raidCaptureMode
    if @pokemon.immunities.include?(:INDIRECT)
      @battle.pbDisplay(_INTL("¡{1} es completamente inmune a daño indirecto!", pbThis)) if showMsg
      return false
    end
    return dx_takesIndirectDamage?(showMsg)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for Destiny Bond/Grudge immunity.
  #-----------------------------------------------------------------------------
  alias dx_pbEffectsOnMakingHit pbEffectsOnMakingHit
  def pbEffectsOnMakingHit(move, user, target)
    if target.opposes?(user)
      if target.effects[PBEffects::Grudge] && target.fainted? && 
         user.pokemon.immunities.include?(:PPLOSS)
        target.effects[PBEffects::Grudge] = false
      end
      if target.effects[PBEffects::DestinyBond] && target.fainted? &&
         (user.dynamax? || user.pokemon.immunities.include?(:OHKO))
        target.effects[PBEffects::DestinyBond] = false
      end
    end
    dx_pbEffectsOnMakingHit(move, user, target)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for item removal immunity.
  #-----------------------------------------------------------------------------
  alias dx_unlosableItem? unlosableItem?
  def unlosableItem?(check_item)
    return true if check_item && @battle.raidCaptureMode
    return true if check_item && @pokemon.immunities.include?(:ITEMREMOVAL)
    return dx_unlosableItem?(check_item)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for ability negating/replacing immunity.
  #-----------------------------------------------------------------------------
  alias dx_unstoppableAbility? unstoppableAbility?
  def unstoppableAbility?(abil = nil)
    return true if @battle.raidCaptureMode
    return true if @pokemon.immunities.include?(:ABILITYREMOVAL)
    return dx_unstoppableAbility?(abil)
  end
end


#===============================================================================
# Battle properties.
#===============================================================================
class Battle
  #-----------------------------------------------------------------------------
  # Aliased for escape immunity.
  #-----------------------------------------------------------------------------
  alias dx_pbCanRun? pbCanRun?
  def pbCanRun?(idxBattler)
    battler = @battlers[idxBattler]
    return false if battler.pokemon.immunities.include?(:ESCAPE) || battler.isRaidBoss?
    return dx_pbCanRun?(idxBattler)
  end
  
  #-----------------------------------------------------------------------------
  # Returns true if this battle is a raid battle.
  #-----------------------------------------------------------------------------
  def raidBattle?
    allOtherSideBattlers.each { |b| return true if b.isRaidBoss? }
    return false
  end
end

#===============================================================================
# Battle move properties.
#===============================================================================
class Battle::Move  
  #-----------------------------------------------------------------------------
  # Aliased for immunities to Taunt, Torment, Encore, Disable, & Heal Block.
  #-----------------------------------------------------------------------------
  alias dx_pbMoveFailedAromaVeil? pbMoveFailedAromaVeil?
  def pbMoveFailedAromaVeil?(user, target, showMessage = true)
    if target.pokemon.immunities.include?(:DISABLE)
      @battle.pbDisplay(_INTL("{1} is completely immune to effects that may disable its moves!", target.pbThis)) if showMessage
      return true
    end
    return dx_pbMoveFailedAromaVeil?(user, target, showMessage)
  end
end