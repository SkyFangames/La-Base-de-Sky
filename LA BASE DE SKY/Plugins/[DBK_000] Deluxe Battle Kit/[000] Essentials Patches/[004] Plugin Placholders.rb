#===============================================================================
# Plugin utility methods.
#===============================================================================
# All of the below methods are meant to act as dummy methods that other plugins
# may utilize by aliasing them to add their own functionality.
#-------------------------------------------------------------------------------
class Battle
  #-----------------------------------------------------------------------------
  # Initializes battle mechanics for new enemy trainers.
  #-----------------------------------------------------------------------------
  def pbInitializeSpecialActions(idxTrainer)
    return if !idxTrainer
    @megaEvolution[1][idxTrainer] = -1
  end

  #-----------------------------------------------------------------------------
  # Checks if any battle mechanic may be used.
  #-----------------------------------------------------------------------------
  def pbCanUseAnyBattleMechanic?(idxBattler)
    return pbCanMegaEvolve?(idxBattler)
  end
  
  #-----------------------------------------------------------------------------
  # Checks if the given battle mechanic may be used.
  #-----------------------------------------------------------------------------
  def pbCanUseBattleMechanic?(idxBattler, mechanic)
    return mechanic == :mega && pbCanMegaEvolve?(idxBattler)
  end
  
  #-----------------------------------------------------------------------------
  # Unregister all battle mechanics.
  #-----------------------------------------------------------------------------
  def pbUnregisterAllSpecialActions(idxBattler)
    pbUnregisterMegaEvolution(idxBattler)
  end
  
  #-----------------------------------------------------------------------------
  # Toggles a given battle mechanic.
  #-----------------------------------------------------------------------------
  def pbToggleSpecialActions(idxBattler, cmd)
    pbToggleRegisteredMegaEvolution(idxBattler) if cmd == :mega
  end
  
  #-----------------------------------------------------------------------------
  # Returns true if the given battle mechanic is registered.
  #-----------------------------------------------------------------------------
  def pbBattleMechanicIsRegistered?(idxBattler, mechanic)
    return mechanic == :mega && pbRegisteredMegaEvolution?(idxBattler)
  end
  
  #-----------------------------------------------------------------------------
  # Returns the ID of a battler's eligible battle mechanic.
  #-----------------------------------------------------------------------------
  def pbGetEligibleBattleMechanic(idxBattler)
    return :mega if pbCanMegaEvolve?(idxBattler)
    return nil
  end
  
  #-----------------------------------------------------------------------------
  # Sets up battle mechanics prior to the command loop.
  #-----------------------------------------------------------------------------
  def pbActionCommands(side)
    @megaEvolution[side].each_with_index do |megaEvo, i|
      @megaEvolution[side][i] = -1 if megaEvo >= 0
    end
  end
  
  #-----------------------------------------------------------------------------
  # Special actions to take place prior to all actions during the attack phase.
  #-----------------------------------------------------------------------------
  def pbAttackPhaseSpecialActions1; end
  
  #-----------------------------------------------------------------------------
  # Special actions to take place prior to switching during the attack phase.
  #-----------------------------------------------------------------------------
  def pbAttackPhaseSpecialActions2; end
  
  #-----------------------------------------------------------------------------
  # Special actions to take place prior to using moves during the attack phase.
  #-----------------------------------------------------------------------------
  def pbAttackPhaseSpecialActions3
    pbAttackPhaseMegaEvolution
  end
  
  #-----------------------------------------------------------------------------
  # Special actions to take place prior to using Pursuit during the attack phase.
  #-----------------------------------------------------------------------------
  def pbPursuitSpecialActions(battler, owner)
    pbMegaEvolve(battler.index) if @megaEvolution[battler.idxOwnSide][owner] == battler.index
  end
end


class Battle::AI
  #-----------------------------------------------------------------------------
  # Registers a special action for an AI battler prior to move selection.
  #-----------------------------------------------------------------------------
  def pbRegisterEnemySpecialAction(idxBattler)
    @battle.pbRegisterMegaEvolution(idxBattler) if pbEnemyShouldMegaEvolve?
  end
  
  #-----------------------------------------------------------------------------
  # Registers a special action for an AI battler after move selection.
  #-----------------------------------------------------------------------------
  def pbRegisterEnemySpecialAction2(idxBattler); end
  
  #-----------------------------------------------------------------------------
  # Registers a special action for an AI battler based on its selected move.
  #-----------------------------------------------------------------------------
  def pbRegisterEnemySpecialActionFromMove(user, move_sel); end
   
  #-----------------------------------------------------------------------------
  # Determines if the AI should use a special command that isn't Switch/Item/Fight.
  #-----------------------------------------------------------------------------
  def pbChooseToUseSpecialCommand; return false; end
end


class Battle::Scene
  #-----------------------------------------------------------------------------
  # Initializes the settings for buttons related to a given battle mechanic.
  #-----------------------------------------------------------------------------
  def pbSetSpecialActionModes(idxBattler, specialAction, cw)
    cw.chosenButton = specialAction
    cw.shiftMode = (@battle.pbCanShift?(idxBattler)) ? 1 : 0
  end
  
  #-----------------------------------------------------------------------------
  # Runs code upon pressing the "USE" key.
  #-----------------------------------------------------------------------------
  def pbFightMenu_Confirm(battler, specialAction, cw)
    pbPlayDecisionSE
    return cw.index
  end
  
  #-----------------------------------------------------------------------------
  # Runs code upon pressing the "BACK" key.
  #-----------------------------------------------------------------------------
  def pbFightMenu_Cancel(battler, specialAction, cw)
    pbPlayCancelSE
    return :cancel
  end
  
  #-----------------------------------------------------------------------------
  # Runs code upon pressing the "ACTION" key while a special action is available.
  #-----------------------------------------------------------------------------
  def pbFightMenu_Action(battler, specialAction, cw)
	(cw.mode == 1) ? pbPlayActionSE : pbPlayCancelSE
    return false if specialAction == :mega
  end
  
  #-----------------------------------------------------------------------------
  # Runs code upon pressing the "SPECIAL" key while the Shift command is available.
  #-----------------------------------------------------------------------------
  def pbFightMenu_Shift(battler, cw)
    pbPlayDecisionSE
    return :shift
  end
  
  #-----------------------------------------------------------------------------
  # Runs extra code added by certain plugins while updating move index.
  #-----------------------------------------------------------------------------
  def pbFightMenu_Update(battler, specialAction, cw); end
  
  #-----------------------------------------------------------------------------
  # Runs extra code added by certain plugins when certain keys are pressed.
  #-----------------------------------------------------------------------------
  def pbFightMenu_Extra(battler, specialAction, cw); end
  
  #-----------------------------------------------------------------------------
  # Runs extra code added by certain plugins at the very end of the fight menu call.
  #-----------------------------------------------------------------------------
  def pbFightMenu_End(battler, specialAction, cw); end
end


class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  #-----------------------------------------------------------------------------
  # Resets all special toggles related to the fight menu.
  #-----------------------------------------------------------------------------
  def resetMenuToggles
    @chosenButton = :none
    @shiftMode = 0
  end
  
  #-----------------------------------------------------------------------------
  # Adds the button bitmaps for each battle mechanic.
  #-----------------------------------------------------------------------------
  def addSpecialActionButtons(path)
    @actionButtonBitmap[:mega] = AnimatedBitmap.new(_INTL(path + "cursor_mega"))
  end
  
  #-----------------------------------------------------------------------------
  # Gets the correct display button for each battle mechanic.
  #-----------------------------------------------------------------------------
  def getButtonSettings
    return 2, @mode - 1
  end
end


#===============================================================================
# Plugin compatibility methods.
#===============================================================================
# Placeholder methods to allow for compatibility with multiple plugins.
#-------------------------------------------------------------------------------
class Pokemon
  def ultra?;          return false; end
  def dynamax?;        return false; end
  def tera?;           return false; end
  def tera_form?;      return false; end
  def celestial?;      return false; end
  def super_shiny_hue; return 0;     end
end

class Battle::Battler
  def ultra?;          return false; end
  def dynamax?;        return false; end
  def style?;          return false; end
  def tera?;           return false; end
  def tera_form?;      return false; end
  def celestial?;      return false; end
  
  def hasZMove?;       return false; end
  def hasUltra?;       return false; end
  def hasDynamax?;     return false; end
  def hasStyle?;       return false; end
  def hasTera?;        return false; end
  def hasZodiacPower?; return false; end
  def isRivalSpecies?(arg); return false; end
end

class Battle::FakeBattler
  def ultra?;          return false; end
  def dynamax?;        return false; end
  def style?;          return false; end
  def tera?;           return false; end
  def celestial?;      return false; end
  def visiblePokemon;  return @pokemon; end
end

class Battle
  def launcherBattle?; return false; end
  def pbReduceLauncherPoints(*args); end
end

class SafariBattle
  def wildBattleMode;  return nil;   end
  def pbDeluxeTriggers(*args);       end
  def launcherBattle?; return false; end
  def databoxStyle;    return nil;   end
end

class Battle::Move
  def pbBaseDamageTera(baseDmg, user, type)
    return baseDmg
  end
end

class Battle::Scene
  def pbAnimateSubstitute(*args); end
end