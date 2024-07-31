class Battle
  #=============================================================================
  # Choosing Pokémon to switch
  #=============================================================================
  # Checks whether the replacement Pokémon (at party index idxParty) can enter
  # battle.
  # NOTE: Messages are only shown while in the party screen when choosing a
  #       command for the next round.
  def pbCanSwitchIn?(idxBattler, idxParty, partyScene = nil)
    return true if idxParty < 0
    party = pbParty(idxBattler)
    return false if idxParty >= party.length
    return false if !party[idxParty]
    if party[idxParty].egg?
      partyScene&.pbDisplay(_INTL("¡Un huevo no puede combatir!"))
      return false
    end
    if !pbIsOwner?(idxBattler, idxParty)
      if partyScene
        owner = pbGetOwnerFromPartyIndex(idxBattler, idxParty)
        partyScene.pbDisplay(_INTL("¡No puedes cambiar un Pokémon de {1} por uno de los tuyos!", owner.name))
      end
      return false
    end
    if party[idxParty].fainted?
      partyScene&.pbDisplay(_INTL("¡A {1} no le quedan energías para luchar!", party[idxParty].name))
      return false
    end
    if pbFindBattler(idxParty, idxBattler)
      partyScene&.pbDisplay(_INTL("¡{1} ya está en combate!", party[idxParty].name))
      return false
    end
    return true
  end

  # Check whether the currently active Pokémon (at battler index idxBattler) can
  # switch out.
  def pbCanSwitchOut?(idxBattler, partyScene = nil)
    battler = @battlers[idxBattler]
    return true if battler.fainted?
    # Ability/item effects that allow switching no matter what
    if battler.abilityActive? && Battle::AbilityEffects.triggerCertainSwitching(battler.ability, battler, self)
      return true
    end
    if battler.itemActive? && Battle::ItemEffects.triggerCertainSwitching(battler.item, battler, self)
      return true
    end
    # Other certain switching effects
    return true if Settings::MORE_TYPE_EFFECTS && battler.pbHasType?(:GHOST)
    # Other certain trapping effects
    if battler.trappedInBattle?
      partyScene&.pbDisplay(_INTL("¡{1} no puede ser cambiado!", battler.pbThis))
      return false
    end
    # Trapping abilities/items
    allOtherSideBattlers(idxBattler).each do |b|
      next if !b.abilityActive?
      if Battle::AbilityEffects.triggerTrappingByTarget(b.ability, battler, b, self)
        partyScene&.pbDisplay(_INTL("¡{1} de {2} previene el cambio!", b.pbThis, b.abilityName))
        return false
      end
    end
    allOtherSideBattlers(idxBattler).each do |b|
      next if !b.itemActive?
      if Battle::ItemEffects.triggerTrappingByTarget(b.item, battler, b, self)
        partyScene&.pbDisplay(_INTL("¡{1} de {2} previene el cambio!", b.pbThis, b.itemName))
        return false
      end
    end
    return true
  end

  # Check whether the currently active Pokémon (at battler index idxBattler) can
  # switch out (and that its replacement at party index idxParty can switch in).
  # NOTE: Messages are only shown while in the party screen when choosing a
  #       command for the next round.
  def pbCanSwitch?(idxBattler, idxParty = -1, partyScene = nil)
    # Check whether party Pokémon can switch in
    return false if !pbCanSwitchIn?(idxBattler, idxParty, partyScene)
    # Make sure another battler isn't already choosing to switch to the party
    # Pokémon
    allSameSideBattlers(idxBattler).each do |b|
      next if choices[b.index][0] != :SwitchOut || choices[b.index][1] != idxParty
      partyScene&.pbDisplay(_INTL("{1} ya ha sido seleccionado.",
                                  pbParty(idxBattler)[idxParty].name))
      return false
    end
    # Check whether battler can switch out
    return pbCanSwitchOut?(idxBattler, partyScene)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to ensure Pokemon affected by Commander cannot switch out for any reason.
  #-----------------------------------------------------------------------------
  alias paldea_pbCanSwitch? pbCanSwitch?
  def pbCanSwitch?(idxBattler, idxParty = -1, partyScene = nil)
    ret = paldea_pbCanSwitch?(idxBattler, idxParty, partyScene)
    if ret && @battlers[idxBattler].effects[PBEffects::Commander]
      partyScene&.pbDisplay(_INTL("¡{1} no puede ser cambiado!", battler.pbThis))
      return false
    end
    return ret
  end
  

  def pbCanChooseNonActive?(idxBattler)
    pbParty(idxBattler).each_with_index do |_pkmn, i|
      return true if pbCanSwitchIn?(idxBattler, i)
    end
    return false
  end

  def pbRegisterSwitch(idxBattler, idxParty)
    return false if !pbCanSwitch?(idxBattler, idxParty)
    @choices[idxBattler][0] = :SwitchOut
    @choices[idxBattler][1] = idxParty   # Party index of Pokémon to switch in
    @choices[idxBattler][2] = nil
    return true
  end

  #=============================================================================
  # Open the party screen and potentially pick a replacement Pokémon (or AI
  # chooses replacement)
  #=============================================================================
  # Open party screen and potentially choose a Pokémon to switch with. Used in
  # all instances where the party screen is opened.
  def pbPartyScreen(idxBattler, checkLaxOnly = false, canCancel = false, shouldRegister = false)
    ret = -1
    @scene.pbPartyScreen(idxBattler, canCancel) do |idxParty, partyScene|
      if checkLaxOnly
        next false if !pbCanSwitchIn?(idxBattler, idxParty, partyScene)
      elsif !pbCanSwitch?(idxBattler, idxParty, partyScene)
        next false
      end
      if shouldRegister && (idxParty < 0 || !pbRegisterSwitch(idxBattler, idxParty))
        next false
      end
      ret = idxParty
      next true
    end
    return ret
  end

  # For choosing a replacement Pokémon when prompted in the middle of other
  # things happening (U-turn, Baton Pass, in def pbEORSwitch).
  def pbSwitchInBetween(idxBattler, checkLaxOnly = false, canCancel = false)
    return pbPartyScreen(idxBattler, checkLaxOnly, canCancel) if !@controlPlayer && pbOwnedByPlayer?(idxBattler)
    return @battleAI.pbDefaultChooseNewEnemy(idxBattler)
  end

  #=============================================================================
  # Switching Pokémon
  #=============================================================================
  # General switching method that checks if any Pokémon need to be sent out and,
  # if so, does. Called at the end of each round.
  def pbEORSwitch(favorDraws = false)
    return if @decision > 0 && !favorDraws
    return if @decision == 5 && favorDraws
    pbJudge
    return if @decision > 0
    # Check through each fainted battler to see if that spot can be filled.
    switched = []
    loop do
      switched.clear
      @battlers.each do |b|
        next if !b || !b.fainted?
        idxBattler = b.index
        next if !pbCanChooseNonActive?(idxBattler)
        if !pbOwnedByPlayer?(idxBattler)   # Opponent/ally is switching in
          next if b.wild?   # Wild Pokémon can't switch
          idxPartyNew = pbSwitchInBetween(idxBattler)
          opponent = pbGetOwnerFromBattlerIndex(idxBattler)
          # NOTE: The player is only offered the chance to switch their own
          #       Pokémon when an opponent replaces a fainted Pokémon in single
          #       battles. In double battles, etc. there is no such offer.
          if @internalBattle && @switchStyle && trainerBattle? && pbSideSize(0) == 1 &&
             opposes?(idxBattler) && !@battlers[0].fainted? && !switched.include?(0) &&
             pbCanChooseNonActive?(0) && @battlers[0].effects[PBEffects::Outrage] == 0
            idxPartyForName = idxPartyNew
            enemyParty = pbParty(idxBattler)
            if enemyParty[idxPartyNew].ability == :ILLUSION && !pbCheckGlobalAbility(:NEUTRALIZINGGAS)
              new_index = pbLastInTeam(idxBattler)
              idxPartyForName = new_index if new_index >= 0 && new_index != idxPartyNew
            end
            if pbDisplayConfirm(_INTL("{1} va a sacar a {2}. ¿Quieres cambiar de Pokémon?",
                                      opponent.full_name, enemyParty[idxPartyForName].name))
              idxPlayerPartyNew = pbSwitchInBetween(0, false, true)
              if idxPlayerPartyNew >= 0
                pbMessageOnRecall(@battlers[0])
                pbRecallAndReplace(0, idxPlayerPartyNew)
                switched.push(0)
              end
            end
          end
          pbRecallAndReplace(idxBattler, idxPartyNew)
          switched.push(idxBattler)
        elsif trainerBattle?   # Player switches in in a trainer battle
          idxPlayerPartyNew = pbGetReplacementPokemonIndex(idxBattler)   # Owner chooses
          pbRecallAndReplace(idxBattler, idxPlayerPartyNew)
          switched.push(idxBattler)
        else   # Player's Pokémon has fainted in a wild battle
          switch = false
          if pbDisplayConfirm(_INTL("¿Quieres sacar a otro Pokémon?"))
            switch = true
          else
            switch = (pbRun(idxBattler, true) <= 0)
          end
          if switch
            idxPlayerPartyNew = pbGetReplacementPokemonIndex(idxBattler)   # Owner chooses
            pbRecallAndReplace(idxBattler, idxPlayerPartyNew)
            switched.push(idxBattler)
          end
        end
      end
      break if switched.length == 0
      pbOnBattlerEnteringBattle(switched)
    end
  end

  def pbGetReplacementPokemonIndex(idxBattler, random = false)
    if random
      choices = []   # Find all Pokémon that can switch in
      eachInTeamFromBattlerIndex(idxBattler) do |_pkmn, i|
        choices.push(i) if pbCanSwitchIn?(idxBattler, i)
      end
      return -1 if choices.length == 0
      return choices[pbRandom(choices.length)]
    else
      return pbSwitchInBetween(idxBattler, true)
    end
  end

  # Actually performs the recalling and sending out in all situations.
  def pbRecallAndReplace(idxBattler, idxParty, randomReplacement = false, batonPass = false)
    @scene.pbRecall(idxBattler) if !@battlers[idxBattler].fainted?
    @battlers[idxBattler].pbAbilitiesOnSwitchOut   # Inc. primordial weather check
    @scene.pbShowPartyLineup(idxBattler & 1) if pbSideSize(idxBattler) == 1
    pbMessagesOnReplace(idxBattler, idxParty) if !randomReplacement
    pbReplace(idxBattler, idxParty, batonPass)
  end

  def pbMessageOnRecall(battler)
    if battler.pbOwnedByPlayer?
      if battler.hp <= battler.totalhp / 4
        pbDisplayBrief(_INTL("¡Buen trabajo {1}! ¡Regresa!", battler.name))
      elsif battler.hp <= battler.totalhp / 2
        pbDisplayBrief(_INTL("¡OK, {1}! ¡Regresa!", battler.name))
      elsif battler.turnCount >= 5
        pbDisplayBrief(_INTL("¡{1}, es suficiente ! ¡Regresa!", battler.name))
      elsif battler.turnCount >= 2
        pbDisplayBrief(_INTL("¡{1}, regresa!", battler.name))
      else
        pbDisplayBrief(_INTL("¡{1}, cambia! ¡Regresa!", battler.name))
      end
    else
      owner = pbGetOwnerName(battler.index)
      pbDisplayBrief(_INTL("¡{1} retiró a {2}!", owner, battler.name))
    end
  end

  # Only called from def pbRecallAndReplace and Battle Arena's def pbSwitch.
  def pbMessagesOnReplace(idxBattler, idxParty)
    party = pbParty(idxBattler)
    newPkmnName = party[idxParty].name
    if party[idxParty].ability == :ILLUSION && !pbCheckGlobalAbility(:NEUTRALIZINGGAS)
      new_index = pbLastInTeam(idxBattler)
      newPkmnName = party[new_index].name if new_index >= 0 && new_index != idxParty
    end
    if pbOwnedByPlayer?(idxBattler)
      opposing = @battlers[idxBattler].pbDirectOpposing
      if opposing.fainted? || opposing.hp == opposing.totalhp
        pbDisplayBrief(_INTL("¡Te toca, {1}!", newPkmnName))
      elsif opposing.hp >= opposing.totalhp / 2
        pbDisplayBrief(_INTL("¡Adelante, {1}!", newPkmnName))
      elsif opposing.hp >= opposing.totalhp / 4
        pbDisplayBrief(_INTL("¡Solo un poco más! ¡Aguanta, {1}!", newPkmnName))
      else
        pbDisplayBrief(_INTL("¡Tu oponente está debil! ¡A por ellos, {1}!", newPkmnName))
      end
    else
      owner = pbGetOwnerFromBattlerIndex(idxBattler)
      pbDisplayBrief(_INTL("¡{1} sacó a {2}!", owner.full_name, newPkmnName))
    end
  end

  # Only called from def pbRecallAndReplace above and Battle Arena's def
  # pbSwitch.
  def pbReplace(idxBattler, idxParty, batonPass = false)
    party = pbParty(idxBattler)
    idxPartyOld = @battlers[idxBattler].pokemonIndex
    # Initialise the new Pokémon
    @battlers[idxBattler].pbInitialize(party[idxParty], idxParty, batonPass)
    # Reorder the party for this battle
    partyOrder = pbPartyOrder(idxBattler)
    partyOrder[idxParty], partyOrder[idxPartyOld] = partyOrder[idxPartyOld], partyOrder[idxParty]
    # Send out the new Pokémon
    pbSendOut([[idxBattler, party[idxParty]]])
    pbCalculatePriority(false, [idxBattler]) if Settings::RECALCULATE_TURN_ORDER_AFTER_SPEED_CHANGES
  end

  # Called from def pbReplace above and at the start of battle.
  # sendOuts is an array; each element is itself an array: [idxBattler,pkmn]
  def pbSendOut(sendOuts, startBattle = false)
    sendOuts.each { |b| @peer.pbOnEnteringBattle(self, @battlers[b[0]], b[1]) }
    @scene.pbSendOutBattlers(sendOuts, startBattle)
    sendOuts.each do |b|
      @scene.pbResetCommandsIndex(b[0])
      pbSetSeen(@battlers[b[0]])
      @usedInBattle[b[0] & 1][b[0] / 2] = true
    end
  end

  #=============================================================================
  # Effects upon a Pokémon entering battle
  #=============================================================================
  # Called at the start of battle only.
  def pbOnAllBattlersEnteringBattle
    pbCalculatePriority(true)
    battler_indices = []
    allBattlers.each { |b| battler_indices.push(b.index) }
    pbOnBattlerEnteringBattle(battler_indices)
    pbCalculatePriority
    # Check forms are correct
    allBattlers.each { |b| b.pbCheckForm }
  end

  # Called when one or more Pokémon switch in. Does a lot of things, including
  # entry hazards, form changes and items/abilities that trigger upon switching
  # in.
  def pbOnBattlerEnteringBattle(battler_index, skip_event_reset = false)
    battler_index = [battler_index] if !battler_index.is_a?(Array)
    battler_index.flatten!
    # NOTE: This isn't done for switch commands, because they previously call
    #       pbRecallAndReplace, which could cause Neutralizing Gas to end, which
    #       in turn could cause Intimidate to trigger another Pokémon's Eject
    #       Pack. That Eject Pack should trigger at the end of this method, but
    #       this resetting would prevent that from happening, so it is skipped
    #       and instead done earlier in def pbAttackPhaseSwitch.
    if !skip_event_reset
      allBattlers.each do |b|
        b.droppedBelowHalfHP = false
        b.statsDropped = false
      end
    end
    # For each battler that entered battle, in speed order
    pbPriority(true).each do |b|
      next if !battler_index.include?(b.index) || b.fainted?
      pbRecordBattlerAsParticipated(b)
      pbMessagesOnBattlerEnteringBattle(b)
      # Position/field effects triggered by the battler appearing
      pbEffectsOnBattlerEnteringPosition(b)   # Healing Wish/Lunar Dance
      pbEntryHazards(b)
      # Battler faints if it is knocked out because of an entry hazard above
      if b.fainted?
        b.pbFaint
        pbGainExp
        pbJudge
        next
      end
      b.pbCheckForm
      # Primal Revert upon entering battle
      pbPrimalReversion(b.index)
      # Ending primordial weather, checking Trace
      b.pbContinualAbilityChecks(true)
      # Abilities that trigger upon switching in
      if (!b.fainted? && b.unstoppableAbility?) || b.abilityActive?
        Battle::AbilityEffects.triggerOnSwitchIn(b.ability, b, self, true)
      end
      pbEndPrimordialWeather   # Checking this again just in case
      # Items that trigger upon switching in (Air Balloon message)
      if b.itemActive?
        Battle::ItemEffects.triggerOnSwitchIn(b.item, b, self)
      end
      # Berry check, status-curing ability check
      b.pbHeldItemTriggerCheck
      b.pbAbilityStatusCureCheck
    end
    # Check for triggering of Emergency Exit/Wimp Out/Eject Pack (only one will
    # be triggered)
    pbPriority(true).each do |b|
      break if b.pbItemOnStatDropped
      break if b.pbAbilitiesOnDamageTaken
    end
    allBattlers.each do |b|
      b.droppedBelowHalfHP = false
      b.statsDropped = false
    end
  end

  def pbRecordBattlerAsParticipated(battler)
    # Record money-doubling effect of Amulet Coin/Luck Incense
    if !battler.opposes? && [:AMULETCOIN, :LUCKINCENSE].include?(battler.item_id)
      @field.effects[PBEffects::AmuletCoin] = true
    end
    # Update battlers' participants (who will gain Exp/EVs when a battler faints)
    allBattlers.each { |b| b.pbUpdateParticipants }
  end

  def pbMessagesOnBattlerEnteringBattle(battler)
    # Introduce Shadow Pokémon
    if battler.shadowPokemon?
      pbCommonAnimation("Shadow", battler)
      pbDisplay(_INTL("¡Oh!\n¡Un Pokémon Oscuro!")) if battler.opposes?
    end
  end

  # Called when a Pokémon enters battle, and when Ally Switch is used.
  def pbEffectsOnBattlerEnteringPosition(battler)
    position = @positions[battler.index]
    # Healing Wish
    if position.effects[PBEffects::HealingWish]
      if battler.canHeal? || battler.status != :NONE
        pbCommonAnimation("HealingWish", battler)
        pbDisplay(_INTL("¡¡El deseo de curación se hizo realidad para {1}!", battler.pbThis(true)))
        battler.pbRecoverHP(battler.totalhp)
        battler.pbCureStatus(false)
        position.effects[PBEffects::HealingWish] = false
      elsif Settings::MECHANICS_GENERATION < 8
        position.effects[PBEffects::HealingWish] = false
      end
    end
    # Lunar Dance
    if position.effects[PBEffects::LunarDance]
      full_pp = true
      battler.eachMove { |m| full_pp = false if m.pp < m.total_pp }
      if battler.canHeal? || battler.status != :NONE || !full_pp
        pbCommonAnimation("LunarDance", battler)
        pbDisplay(_INTL("¡Un místico halo de luz de luna envuelve a {1}!", battler.pbThis))
        battler.pbRecoverHP(battler.totalhp)
        battler.pbCureStatus(false)
        battler.eachMove { |m| battler.pbSetPP(m, m.total_pp) }
        position.effects[PBEffects::LunarDance] = false
      elsif Settings::MECHANICS_GENERATION < 8
        position.effects[PBEffects::LunarDance] = false
      end
    end
  end

  def pbEntryHazards(battler)
    battler_side = battler.pbOwnSide
    # Stealth Rock
    if battler_side.effects[PBEffects::StealthRock] && battler.takesIndirectDamage? &&
       GameData::Type.exists?(:ROCK) && !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
      bTypes = battler.pbTypes(true)
      eff = Effectiveness.calculate(:ROCK, *bTypes)
      if !Effectiveness.ineffective?(eff)
        battler.pbReduceHP(battler.totalhp * eff / 8, false)
        pbDisplay(_INTL("¡Unas piedras puntiagudas han dañado a {1}!", battler.pbThis))
        battler.pbItemHPHealCheck
      end
    end
    # Spikes
    if battler_side.effects[PBEffects::Spikes] > 0 && battler.takesIndirectDamage? &&
       !battler.airborne? && !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
      spikesDiv = [8, 6, 4][battler_side.effects[PBEffects::Spikes] - 1]
      battler.pbReduceHP(battler.totalhp / spikesDiv, false)
      pbDisplay(_INTL("¡Las púas han herido al {1}!", battler.pbThis))
      battler.pbItemHPHealCheck
    end
    # Toxic Spikes
    if battler_side.effects[PBEffects::ToxicSpikes] > 0 && !battler.fainted? && !battler.airborne?
      if battler.pbHasType?(:POISON)
        battler_side.effects[PBEffects::ToxicSpikes] = 0
        pbDisplay(_INTL("¡Las púas tóxicas lanzadas a {1} han desaparecido!", battler.pbThis))
      elsif battler.pbCanPoison?(nil, false) && !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
        if battler_side.effects[PBEffects::ToxicSpikes] == 2
          battler.pbPoison(nil, _INTL("¡{1} ha sido envenenado por las púas tóxicas!", battler.pbThis), true)
        else
          battler.pbPoison(nil, _INTL("¡{1} ha sido gravemente envenenado por las púas tóxicas!", battler.pbThis))
        end
      end
    end
    # Sticky Web
    if battler_side.effects[PBEffects::StickyWeb] && !battler.fainted? && !battler.airborne? &&
       !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
      pbDisplay(_INTL("¡{1} ha caído en una red viscosa!", battler.pbThis))
      if battler.pbCanLowerStatStage?(:SPEED)
        battler.pbLowerStatStage(:SPEED, 1, nil)
        battler.pbItemStatRestoreCheck
      end
    end
  end
end

