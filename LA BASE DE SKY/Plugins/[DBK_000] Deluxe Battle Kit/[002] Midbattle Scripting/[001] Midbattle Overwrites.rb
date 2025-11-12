#===============================================================================
# Midbattle triggers.
#===============================================================================
class Battle
  #-----------------------------------------------------------------------------
  # Initializes midbattle properties.
  #-----------------------------------------------------------------------------
  attr_accessor :midbattleScript     # Used to store the midbattle script for this battle.
  attr_accessor :activated_triggers  # Used to store all triggers activated during this battle.
  attr_accessor :midbattleFailSafe   # Used as a safeguard for situations that may lead to infinite loops.
  attr_accessor :midbattleVariable   # Used to store the value of the midbattle variable.
  attr_accessor :midbattleChoices    # Used to store choices to display for a text or speech event.
  attr_accessor :midbattleDecision   # Used to store the player's decision in a text or speech event with choices.
  
  alias midbattle_initialize initialize
  def initialize(*args)
    midbattle_initialize(*args)
    @midbattleScript    = nil
    @activated_triggers = []
    @midbattleFailSafe  = false
    @midbattleVariable  = 0
    @midbattleChoices   = []
    @midbattleDecision  = nil
  end
  
  #-----------------------------------------------------------------------------
  # Utilities related to tracking activated triggers.
  #-----------------------------------------------------------------------------
  def pbAddToBattleTriggers(triggers)
    triggers = [triggers] if !triggers.is_a?(Array)
    triggers.each do |trigger|
      next if @activated_triggers.include?(trigger)
      @activated_triggers.push(trigger)
    end
  end
  
  def pbTriggerActivated?(*triggers)
    triggers.each do |trigger|
      return true if @activated_triggers.include?(trigger)
    end
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Compiles an array of all possible midbattle triggers.
  #-----------------------------------------------------------------------------
  def pbDeluxeTriggers(idxBattler, idxTarget, *triggers)
    return if !@midbattleScript && !MidbattleHandlers.has_any?(:midbattle_global)
    return if @midbattleFailSafe
    idxBattler = idxBattler.index if idxBattler.respond_to?("index")
    turnCount = (triggers[0].include?("Turn")) ? @battlers[idxBattler].turnCount : @turnCount + 1
    trigger_array = []
    last_string = nil
    triggers.each do |trig|
      turn_trig = triggers[1] && triggers[1].is_a?(Integer)
      case trig
      when String
        last_string = trig
        last_entry = trig
        trigger_array.push(trig) if !turn_trig
      when Symbol, Integer
        next if !last_string
        last_entry = last_string + "_" + trig.to_s
        trigger_array.push(last_entry) if !turn_trig
      end
      next if last_entry.nil?
      next if last_entry.include?("BattleEnd")
      users = [""]
      users.clear if triggers[1] && triggers[1].is_a?(Integer)
      if !idxBattler.nil?
        size = pbSideSize(idxBattler)
        if pbOwnedByPlayer?(idxBattler)
          users.push("_player")
          if size > 1
            case idxBattler
            when 0 then users.push("_player1")
            when 2 then users.push("_player2")
            when 4 then users.push("_player3")
            end
          end
        elsif opposes?(idxBattler)
          users.push("_foe")
          if size > 1
            case idxBattler
            when 1 then users.push("_foe1")
            when 3 then users.push("_foe2")
            when 5 then users.push("_foe3")
            end
          end
        else
          users.push("_ally")
        end
      end
      users.each do |user|
        next if !nil_or_empty?(user) && last_entry.include?(user)
        trigger_array.push(last_entry + user) if !trigger_array.include?(last_entry + user)
        next if @midbattleScript.is_a?(Symbol)
        if !trig.is_a?(Integer)
          trigger_array.push(last_entry + user + "_random")
          trigger_array.push(last_entry + user + "_repeat")
          trigger_array.push(last_entry + user + "_repeat_random")
        end
        if turn_trig && !trig.is_a?(Integer)
          trigger_array.push(last_entry + user + "_repeat_odd") if turnCount.odd?
          trigger_array.push(last_entry + user + "_repeat_even") if turnCount.even?
          trigger_array.push(last_entry + user + "_repeat_every")
        end
      end
    end
    trigger_array.uniq!
    pbMidbattleScripting(idxBattler, idxTarget, trigger_array)
  end
  
  #-----------------------------------------------------------------------------
  # Compiles an array of all possible midbattle variable triggers.
  #-----------------------------------------------------------------------------
  def pbVariableTriggers(oldVar)
    trigger_array = []
    newVar = @midbattleVariable
    suffix = (newVar > oldVar) ? "Up" : "Down"
    2.times do |i|
      case i
      when 0 then trigger = "Variable" + "_" + newVar.to_s
      when 1 then trigger = "Variable" + suffix
      end
      trigger_array.push(trigger)
      trigger_array.push(trigger + "_random")
      trigger_array.push(trigger + "_repeat")
      trigger_array.push(trigger + "_repeat_random")
      if i == 1
        trigger_array.push(trigger + "_repeat_odd") if newVar.odd?
        trigger_array.push(trigger + "_repeat_even") if newVar.even?
        trigger_array.push(trigger + "_repeat_every")
      end
    end
    trigger_array.push("VariableOver_")
    trigger_array.push("VariableUnder_")
    return trigger_array
  end
  
  #-----------------------------------------------------------------------------
  # Executes commands for each midbattle trigger.
  #-----------------------------------------------------------------------------
  def pbMidbattleScripting(idxBattler, idxTarget, trigger_array)
    return if trigger_array.empty?
    midbattle = @midbattleScript
    variableChanged = false
    loop do
      @midbattleChoices.clear
      @midbattleDecision = nil
      oldVar = @midbattleVariable
      trigger_array.each do |trigger|
        MidbattleHandlers.trigger_each(:midbattle_global, self, idxBattler, idxTarget, trigger)
      end
      case midbattle
      when Hash
        user = idxBattler
        target = idxTarget
        @midbattleFailSafe = true
        midbattle.each_key do |trigger|
          if variableChanged
            if trigger.include?("VariableOver_")
              check_val = trigger.split("_")[1].to_i
              next if !check_val || @midbattleVariable <= check_val
              trigger_array.push(trigger)
            elsif trigger.include?("VariableUnder_")
              check_val = trigger.split("_")[1].to_i
              next if !check_val || @midbattleVariable >= check_val
              trigger_array.push(trigger)
            end
          end
          if trigger.include?("_random")
            t = trigger.split("_")
            check_trigger = (t.last == "random") ? trigger : t[0..t.length - 2].join("_")
            next if !trigger_array.include?(check_trigger)
            odds = (t.last == "random") ? 50 : t.last.to_i
            next if rand(100) < odds
          elsif trigger.include?("_repeat_every")
            t = trigger.split("_")
            check_trigger = t[0..t.length - 2].join("_")
            next if !trigger_array.include?(check_trigger)
            count = t.last.to_i
            next if !count || count < 2
            next if trigger.include?("Turn") && @battlers[user].turnCount % count != 0
            next if trigger.include?("Round") && (@turnCount + 1) % count != 0
            next if trigger.include?("Variable") && @midbattleVariable % count != 0
          else
            next if !trigger_array.include?(trigger)
          end
          PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{@battlers[user].pbThis(true)} (#{user})...")
          case midbattle[trigger]
          when String, Array
            MidbattleHandlers.trigger(:midbattle_triggers, "speech", self, user, target, midbattle[trigger])
          when Hash
            old_user = user
            midbattle[trigger].each do |key, params|
              base_key = key.split("_").first
              ret = MidbattleHandlers.trigger(:midbattle_triggers, base_key, self, user, target, params)
              oldVar = @midbattleVariable if base_key == "setVariable"
              if !ret.nil?
                case base_key
                when "setBattler"
                  user = ret.index
                when "ignoreUntil", "ignoreAfter"
                  break if ret
                end
              end
            end
            user = old_user
          end
          PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
          next if trigger.include?("_repeat")
          midbattle.delete(trigger)
        end
        @midbattleFailSafe = false
      when Symbol
        trigger_array.each do |trigger|
          MidbattleHandlers.trigger(:midbattle_scripts, midbattle, self, idxBattler, idxTarget, trigger)
        end
      end
      pbAddToBattleTriggers(trigger_array)
      if @midbattleVariable != oldVar
        trigger_array = pbVariableTriggers(oldVar)
        variableChanged = true
        next
      elsif !@midbattleDecision.nil?
        choice = @midbattleChoices
        decision = @midbattleDecision
        break if choice.empty?
        trigger_array = ["Choice_#{choice[0]}_#{decision}"]
        if choice[1]
          suffix = (decision == choice[1]) ? "Right" : "Wrong"
          trigger_array.push("Choice#{suffix}_#{choice[0]}")
        end
        next
      end
      break
    end
    @scene.pbForceEndSpeech
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon a trainer using an item.
  #-----------------------------------------------------------------------------
  def pbUseItemOnPokemon(item, idxParty, userBattler)
    pbDeluxeTriggers(userBattler, nil, "BeforeItemUse", item)
    trainerName = pbGetOwnerName(userBattler.index)
    pkmn = pbParty(userBattler.index)[idxParty]
    battler = pbFindBattler(idxParty, userBattler.index)
    pbUseItemMessage(item, trainerName, (battler || pkmn))
    ch = @choices[userBattler.index]
    args = [item, pkmn, battler, ch[3], true, self, @scene, false]
    args.push(userBattler.index) if launcherBattle?
    if ItemHandlers.triggerCanUseInBattle(*args)
      (battler) ? @scene.pbItemUseAnimation(battler.index) : pbSEPlay("Use item in party")
      ItemHandlers.triggerBattleUseOnPokemon(item, pkmn, battler, ch, @scene)
      pbDeluxeTriggers(userBattler, nil, "AfterItemUse", item)
      pbReduceLauncherPoints(userBattler, item, true)
      ch[1] = nil
      return
    end
    pbDisplay(_INTL("¡Pero no tuvo efecto!"))
    pbReturnUnusedItemToBag(item, userBattler.index)
  end
  
  def pbUseItemOnBattler(item, idxParty, userBattler)
    pbDeluxeTriggers(userBattler, nil, "BeforeItemUse", item)
    trainerName = pbGetOwnerName(userBattler.index)
    battler = pbFindBattler(idxParty, userBattler.index)
    pbUseItemMessage(item, trainerName, battler)
    ch = @choices[userBattler.index]
    if battler
      args = [item, battler.pokemon, battler, ch[3], true, self, @scene, false]
      args.push(userBattler.index) if launcherBattle?
      if ItemHandlers.triggerCanUseInBattle(*args)
        @scene.pbItemUseAnimation(battler.index)
        ItemHandlers.triggerBattleUseOnBattler(item, battler, @scene)
        ch[1] = nil
        battler.pbItemOnStatDropped
        pbDeluxeTriggers(userBattler, nil, "AfterItemUse", item)
        pbReduceLauncherPoints(userBattler, item, true)
        return
      else
        pbDisplay(_INTL("¡Pero no tuvo efecto!"))
      end
    else
      pbDisplay(_INTL("¡Pero no hay dónde usar este objeto!"))
    end
    pbReturnUnusedItemToBag(item, userBattler.index)
  end
  
  def pbUseItemInBattle(item, idxBattler, userBattler)
    pbDeluxeTriggers(userBattler, idxBattler, "BeforeItemUse", item)
    trainerName = pbGetOwnerName(userBattler.index)
    battler = (idxBattler < 0) ? userBattler : @battlers[idxBattler]
    pbUseItemMessage(item, trainerName, battler)
    pkmn = battler.pokemon
    ch = @choices[userBattler.index]
    args = [item, pkmn, battler, ch[3], true, self, @scene, false]
    args.push(userBattler.index) if launcherBattle?
    if ItemHandlers.triggerCanUseInBattle(*args)
      ItemHandlers.triggerUseInBattle(item, battler, self)
      pbDeluxeTriggers(userBattler, idxBattler, "AfterItemUse", item)
      pbReduceLauncherPoints(userBattler, item, true)
      ch[1] = nil
      return
    end
    pbDisplay(_INTL("¡Pero no tuvo efecto!"))
    pbReturnUnusedItemToBag(item, userBattler.index)
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon a battler being recalled.
  #-----------------------------------------------------------------------------
  alias dx_pbMessageOnRecall pbMessageOnRecall
  def pbMessageOnRecall(battler)
    if !battler.fainted?
      pbDeluxeTriggers(battler, nil, "BeforeSwitchOut", battler.species, *battler.pokemon.types)
    end
    dx_pbMessageOnRecall(battler)
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers prior to a new Pokemon being sent out.
  #-----------------------------------------------------------------------------
  alias dx_pbMessagesOnReplace pbMessagesOnReplace
  def pbMessagesOnReplace(idxBattler, idxParty)
    party = pbParty(idxBattler)
    nextPoke = party[idxParty]
    triggers = ["BeforeSwitchIn", nextPoke.species, *nextPoke.types]
    triggers.push("BeforeLastSwitchIn", nextPoke.species, *nextPoke.types) if pbAbleNonActiveCount(idxBattler) == 1
    pbDeluxeTriggers(idxBattler, nil, *triggers)
    if defined?(pbMessagesOnReplace_WithTitles)
      pbMessagesOnReplace_WithTitles(idxBattler, idxParty)
    else
      dx_pbMessagesOnReplace(idxBattler, idxParty)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers after a new Pokemon has been sent out.
  #-----------------------------------------------------------------------------
  alias dx_pbReplace pbReplace
  def pbReplace(idxBattler, idxParty, batonPass = false)
    dx_pbReplace(idxBattler, idxParty, batonPass)
    battler = @battlers[idxBattler]
    triggers = ["AfterSwitchIn", battler.species, *battler.pokemon.types]
    triggers.push("AfterLastSwitchIn", battler.species, *battler.pokemon.types) if pbAbleNonActiveCount(idxBattler) == 0
    pbDeluxeTriggers(idxBattler, nil, *triggers)
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon weather ending.
  #-----------------------------------------------------------------------------
  alias dx_pbEOREndWeather pbEOREndWeather
  def pbEOREndWeather(priority)
    oldWeather = @field.weather
    dx_pbEOREndWeather(priority)
    newWeather = @field.weather
    if newWeather == :None && oldWeather != :None
      allBattlers.each do |b|
        pbDeluxeTriggers(b, nil, "WeatherEnded", oldWeather)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon terrain ending.
  #-----------------------------------------------------------------------------
  alias dx_pbEOREndTerrain pbEOREndTerrain
  def pbEOREndTerrain
    oldTerrain = @field.terrain
    dx_pbEOREndTerrain
    newTerrain = @field.terrain
    if newTerrain == :None && oldTerrain != :None
      allBattlers.each do |b|
        pbDeluxeTriggers(b, nil, "TerrainEnded", oldTerrain)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers after a battlefield effect ends.
  #-----------------------------------------------------------------------------
  def pbEORCountDownFieldEffect(effect, msg)
    return if @field.effects[effect] <= 0
    @field.effects[effect] -= 1
    return if @field.effects[effect] > 0
    @scene.pbDeleteTRbg() if effect == PBEffects::TrickRoom
    pbDisplay(msg)
    if effect == PBEffects::MagicRoom
      pbPriority(true).each { |battler| battler.pbItemTerrainStatBoostCheck }
    end
    $DELUXE_PBEFFECTS[:field][:counter].each do |id|
      next if !PBEffects.const_defined?(id)
      next if effect != PBEffects.const_get(id)
      allBattlers.each do |b|
        pbDeluxeTriggers(b, nil, "FieldEffectEnded", id)
      end
      break
    end
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers after an effect ends on one side of the field.
  #-----------------------------------------------------------------------------
  def pbEORCountDownSideEffect(side, effect, msg)
    return if @sides[side].effects[effect] <= 0
    @sides[side].effects[effect] -= 1
    if @sides[side].effects[effect] == 0
      pbDisplay(msg)
      $DELUXE_PBEFFECTS[:team][:counter].each do |id|
        next if !PBEffects.const_defined?(id)
        next if effect != PBEffects.const_get(id)
        allSameSideBattlers(side).each do |b|
          pbDeluxeTriggers(b, nil, "TeamEffectEnded", id)
        end
        break
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers after an effect ends on a battler.
  #-----------------------------------------------------------------------------
  def pbEORCountDownBattlerEffect(priority, effect)
    priority.each do |battler|
      next if battler.fainted? || battler.effects[effect] == 0
      battler.effects[effect] -= 1
      yield battler if block_given? && battler.effects[effect] == 0
      $DELUXE_PBEFFECTS[:battler][:counter].each do |id|
        next if !PBEffects.const_defined?(id)
        next if effect != PBEffects.const_get(id)
        pbDeluxeTriggers(battler, nil, "BattlerEffectEnded", id)
        break
      end
    end
  end
  
  alias dx_pbEOREndBattlerSelfEffects pbEOREndBattlerSelfEffects
  def pbEOREndBattlerSelfEffects(battler)
    return if battler.fainted?
    oldEffects = []
    ids = [:Uproar, :SlowStart]
    ids.each { |id| oldEffects.push(battler.effects[PBEffects.const_get(id)]) }
    dx_pbEOREndBattlerSelfEffects(battler)
    ids.each_with_index do |id, i|
      next if oldEffects[i] <= 0
      if battler.effects[PBEffects.const_get(id)] == 0
        pbDeluxeTriggers(battler, nil, "BattlerEffectEnded", id)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon the end of a battle round.
  #-----------------------------------------------------------------------------
  alias dx_pbEndOfRoundPhase pbEndOfRoundPhase
  def pbEndOfRoundPhase
    ret = dx_pbEndOfRoundPhase
    allBattlers.each do |b|
      pbDeluxeTriggers(b, nil, "RoundEnd", 1 + @turnCount)
    end
    return ret
  end
end

#===============================================================================
# Adds midbattle triggers to the capture process.
#===============================================================================
module Battle::CatchAndStoreMixin
  alias dx_pbThrowPokeBall pbThrowPokeBall
  def pbThrowPokeBall(*args)
    idxBattler = args[0]
    if opposes?(idxBattler)
      battler = @battlers[idxBattler]
    else
      battler = @battlers[idxBattler].pbDirectOpposing(true)
    end
    params = [battler.species, *battler.pokemon.types]
    personalID = battler.pokemon.personalID 
    pbDeluxeTriggers(0, battler.index, "BeforeCapture", battler.species, *battler.pokemon.types)
    dx_pbThrowPokeBall(*args)
    captured = false
    @caughtPokemon.each { |p| captured = true if p.personalID == personalID }
    trigger = (captured) ? "AfterCapture" : "FailedCapture"
    pbDeluxeTriggers(0, nil, trigger, *params)
  end
end


#===============================================================================
# Adds midbattle triggers to various spots related to battlers.
#===============================================================================
class Battle::Battler
  #-----------------------------------------------------------------------------
  # Midbattle triggers before a selected move is executed.
  #-----------------------------------------------------------------------------
  alias dx_pbTryUseMove pbTryUseMove
  def pbTryUseMove(*args)
    ret = dx_pbTryUseMove(*args)
    if ret
      move = args[1]
      triggers = ["BeforeMove", @species, move.type, move.id]
      if args[1].damagingMove?
        triggers.push("BeforeDamagingMove", @species, move.type)
        triggers.push("BeforePhysicalMove", @species, move.type) if args[1].physicalMove?
        triggers.push("BeforeSpecialMove",  @species, move.type) if args[1].specialMove?
      else
        triggers.push("BeforeStatusMove", @species, move.type)
      end
      @battle.pbDeluxeTriggers(self, args[0][3], *triggers)
    end
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers after a selected move is executed.
  #-----------------------------------------------------------------------------
  alias dx_pbEffectsAfterMove pbEffectsAfterMove
  def pbEffectsAfterMove(user, targets, move, numHits)
    if user.effects[PBEffects::DestinyBondTarget] >= 0 && !user.fainted?
      user.stopBoostedHPScaling = true
    end
    dx_pbEffectsAfterMove(user, targets, move, numHits)
    triggers = ["AfterMove", user.species, move.type, move.id]
    if move.damagingMove?
      triggers.push("AfterDamagingMove", user.species, move.type)
      triggers.push("AfterPhysicalMove", user.species, move.type) if move.physicalMove?
      triggers.push("AfterSpecialMove",  user.species, move.type) if move.specialMove?
    else
      triggers.push("AfterStatusMove", user.species, move.type)
    end
    if targets.empty?
      @battle.pbDeluxeTriggers(user, user.index, *triggers)
    else
      targ_indecies = []
      targ_triggers = []
      targets.each do |b|
        @battle.pbDeluxeTriggers(user, b.index, *triggers)
        next if b.damageState.unaffected || b.damageState.substitute
        next if b.damageState.calcDamage == 0
        next if !b.damageThreshold
        hpThreshold = (b.totalhp * (b.damageThreshold / 100.0)).round
        hpThreshold = 1 if hpThreshold < 1
        next if b.hp > hpThreshold
        next if b.effects[PBEffects::Endure] && hpThreshold == 1
        targ_indecies.push(b.index)
        targ_triggers.push("BattlerReachedHPCap", b.species, *b.pokemon.types)
        b.damageThreshold = nil
      end
      targ_indecies.each do |i|
        @battle.pbDeluxeTriggers(i, user.index, *targ_triggers)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon move failure.
  #-----------------------------------------------------------------------------
  alias dx_pbSuccessCheckAgainstTarget pbSuccessCheckAgainstTarget
  def pbSuccessCheckAgainstTarget(move, user, target, targets)
    ret = dx_pbSuccessCheckAgainstTarget(move, user, target, targets)
    if !ret
      @battle.pbDeluxeTriggers(user, target.index, "UserMoveNegated", move.id, move.type, user.species)
      @battle.pbDeluxeTriggers(target, user.index, "TargetNegatedMove", move.id, move.type, target.species)
    end	  
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon a move missing.
  #-----------------------------------------------------------------------------
  alias dx_pbMissMessage pbMissMessage
  def pbMissMessage(move, user, target)
    dx_pbMissMessage(move, user, target)
    @battle.pbDeluxeTriggers(user, target.index, "UserMoveDodged", move.id, move.type, user.species)
    @battle.pbDeluxeTriggers(target, user.index, "TargetDodgedMove", move.id, move.type, target.species)
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon a move reaching zero PP.
  #-----------------------------------------------------------------------------
  alias dx_pbSetPP pbSetPP
  def pbSetPP(move, pp)
    dx_pbSetPP(move, pp)
    if move.pp == 0
      @battle.pbDeluxeTriggers(self, nil, "BattlerMoveZeroPP", move.id, move.type, @species)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon a status condition being inflicted or removed.
  #-----------------------------------------------------------------------------
  alias dx_pbInflictStatus pbInflictStatus 
  def pbInflictStatus(*args)
    oldStatus = self.status
    dx_pbInflictStatus(*args)
    return if args[3] && !self.opposes?(args[3])
    if ![:NONE, oldStatus].include?(self.status)
      @battle.pbDeluxeTriggers(self, nil, "BattlerStatusChange", self.status, @species, @pokemon.types)
    end
  end
  
  alias dx_pbCureStatus pbCureStatus
  def pbCureStatus(showMessages = true)
    oldStatus = status
    dx_pbCureStatus(showMessages)
    if oldStatus != :NONE
      @battle.pbDeluxeTriggers(self, nil, "BattlerStatusCured", oldStatus, @species, @pokemon.types)
    end
  end
  
  alias dx_pbConfuse pbConfuse
  def pbConfuse(msg = nil)
    oldEffect = @effects[PBEffects::Confusion]
    dx_pbConfuse(msg)
    if @effects[PBEffects::Confusion] > oldEffect && oldEffect == 0
      @battle.pbDeluxeTriggers(self, nil, "BattlerConfusionStart", @species, @pokemon.types)
    end
  end
  
  alias dx_pbCureConfusion pbCureConfusion
  def pbCureConfusion
    oldEffect = @effects[PBEffects::Confusion]
    dx_pbCureConfusion
    if @effects[PBEffects::Confusion] == 0 && oldEffect > 0
      @battle.pbDeluxeTriggers(self, nil, "BattlerConfusionEnd", @species, @pokemon.types)
    end
  end
  
  alias dx_pbAttract pbAttract
  def pbAttract(user, msg = nil)
    oldEffect = @effects[PBEffects::Attract]
    dx_pbAttract(user, msg)
    if @effects[PBEffects::Attract] > oldEffect && oldEffect == -1
      @battle.pbDeluxeTriggers(self, nil, "BattlerAttractStart", @species, @pokemon.types)
    end
  end
  
  alias dx_pbCureAttract pbCureAttract
  def pbCureAttract
    oldEffect = @effects[PBEffects::Attract]
    dx_pbCureAttract
    if @effects[PBEffects::Attract] == -1 && oldEffect >= 0
      @battle.pbDeluxeTriggers(self, nil, "BattlerAttractEnd", @species, @pokemon.types)
    end
  end

  #-----------------------------------------------------------------------------
  # Midbattle triggers upon a battler fainting.
  #-----------------------------------------------------------------------------
  alias dx_pbAbilitiesOnFainting pbAbilitiesOnFainting
  def pbAbilitiesOnFainting
    dx_pbAbilitiesOnFainting
    triggers = ["BattlerFainted", @species, *@pokemon.types]
    if @battle.pbAllFainted?(@index)
      lastBattler = true
      owner = @battle.pbGetOwnerFromBattlerIndex(@index)
      @battle.battlers.each do |b|
        next if !b || b.opposes?(@index) || !b.fainted? || b.fainted
        thisOwner = @battle.pbGetOwnerFromBattlerIndex(b.index)
        next if thisOwner != owner
        lastBattler = false
      end
      triggers.push("LastBattlerFainted", @species, *@pokemon.types) if lastBattler
    end
    @battle.pbDeluxeTriggers(@index, nil, *triggers)
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon a battler's stats being raised.
  #-----------------------------------------------------------------------------
  alias dx_pbRaiseStatStage pbRaiseStatStage
  def pbRaiseStatStage(*args)
    ret = dx_pbRaiseStatStage(*args)
    @battle.pbDeluxeTriggers(self, nil, "BattlerStatRaised", args[0], @species, @pokemon.types) if ret
    return ret
  end
  
  alias dx_pbRaiseStatStageByCause pbRaiseStatStageByCause
  def pbRaiseStatStageByCause(*args)
    ret = dx_pbRaiseStatStageByCause(*args)
    @battle.pbDeluxeTriggers(self, nil, "BattlerStatRaised", args[0], @species, @pokemon.types) if ret
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon a battler's stats being lowered.
  #-----------------------------------------------------------------------------
  alias dx_pbLowerStatStage pbLowerStatStage
  def pbLowerStatStage(*args)
    ret = dx_pbLowerStatStage(*args)
    @battle.pbDeluxeTriggers(self, nil, "BattlerStatLowered", args[0], @species, @pokemon.types) if ret
    return ret
  end
  
  alias dx_pbLowerStatStageByCause pbLowerStatStageByCause
  def pbLowerStatStageByCause(*args)
    ret = dx_pbLowerStatStageByCause(*args)
    @battle.pbDeluxeTriggers(self, nil, "BattlerStatLowered", args[0], @species, @pokemon.types) if ret
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon the start and end of a specific battler's turn.
  #-----------------------------------------------------------------------------
  alias dx_pbBeginTurn pbBeginTurn
  def pbBeginTurn(_choice)
    dx_pbBeginTurn(_choice)
    @battle.pbDeluxeTriggers(self, nil, "TurnStart", @turnCount, @species, *@pokemon.types)
  end
  
  alias dx_pbEndTurn pbEndTurn
  def pbEndTurn(_choice)
    dx_pbEndTurn(_choice)
    @battle.pbDeluxeTriggers(self, nil, "TurnEnd", @turnCount, @species, *@pokemon.types)
  end
end


#===============================================================================
# Adds midbattle triggers to various spots related to dealing damage with a move.
#===============================================================================
class Battle::Move
  attr_accessor :battler_triggers
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon dealing damage on a substitute or dealing critical hits.
  #-----------------------------------------------------------------------------
  alias dx_pbHitEffectivenessMessages pbHitEffectivenessMessages
  def pbHitEffectivenessMessages(user, target, numTargets = 1)
    @battler_triggers = { :user => [], :targ => [] }
    dx_pbHitEffectivenessMessages(user, target, numTargets)
    return if target.damageState.disguise || target.damageState.iceFace
    if target.damageState.substitute
      if target.effects[PBEffects::Substitute] == 0
        @battler_triggers[:user].push("UserBrokeSub", @id, @type, user.species)
        @battler_triggers[:targ].push("TargetSubBroken", @id, @type, target.species)
      else
        @battler_triggers[:user].push("UserDamagedSub", @id, @type, user.species)
        @battler_triggers[:targ].push("TargetSubDamaged", @id, @type, target.species)
      end
    elsif target.damageState.critical && !target.fainted?
      @battler_triggers[:user].push("UserDealtCriticalHit", @id, @type, user.species)
      @battler_triggers[:targ].push("TargetTookCriticalHit", @id, @type, target.species)
    end
    pbFinalizeMoveTriggers(user, target)
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon dealing damage with a move.
  #-----------------------------------------------------------------------------
  alias dx_pbEffectivenessMessage pbEffectivenessMessage
  def pbEffectivenessMessage(user, target, numTargets = 1)
    return if target.damageState.disguise || target.damageState.iceFace
    dx_pbEffectivenessMessage(user, target, numTargets)
    return if target.damageState.substitute || target.fainted?
    @battler_triggers[:user].push("UserDealtDamage", @id, @type, user.species)
    return if self.is_a?(Battle::Move::FixedDamageMove)
    if Effectiveness.super_effective?(target.damageState.typeMod)
      @battler_triggers[:user].push("UserMoveEffective", @id, @type, user.species)
      @battler_triggers[:targ].push("TargetWeakToMove", @id, @type, target.species)
    elsif Effectiveness.not_very_effective?(target.damageState.typeMod)
      @battler_triggers[:user].push("UserMoveResisted", @id, @type, user.species)
      @battler_triggers[:targ].push("TargetResistedMove", @id, @type, target.species)
    end
    if multiHitMove? || user.effects[PBEffects::ParentalBond] > 0
      pbFinalizeMoveTriggers(user, target)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon a battler's HP getting low due to an attack.
  #-----------------------------------------------------------------------------
  def pbFinalizeMoveTriggers(user, target)  
    if !user.fainted?
      if user.hp <= user.totalhp / 2
        lowHP = user.hp <= user.totalhp / 4
        if @battle.pbParty(user.index).length > @battle.pbSideSize(user.index)
          if @battle.pbAbleNonActiveCount(user.index) == 0
            @battler_triggers[:user].push("LastUserHPHalf", user.species, *user.pokemon.types)
            @battler_triggers[:user].push("LastUserHPLow", user.species, *user.pokemon.types) if lowHP
          else
            @battler_triggers[:user].push("UserHPHalf", user.species, *user.pokemon.types)
            @battler_triggers[:user].push("UserHPLow", user.species, *user.pokemon.types) if lowHP
          end
        else
          @battler_triggers[:user].push("UserHPHalf", user.species, *user.pokemon.types)
          @battler_triggers[:user].push("LastUserHPHalf", user.species, *user.pokemon.types)
          if lowHP
            @battler_triggers[:user].push("UserHPLow", user.species, *user.pokemon.types)
            @battler_triggers[:user].push("LastUserHPLow", user.species, *user.pokemon.types)
          end
        end
      end
    end
    if !target.fainted? && user.opposes?(target.index)
      triggers = []
      if target.hp <= target.totalhp / 2
        lowHP = target.hp <= target.totalhp / 4
        if @battle.pbParty(target.index).length > @battle.pbSideSize(target.index)
          if @battle.pbAbleNonActiveCount(target.index) == 0
            @battler_triggers[:targ].push("LastTargetHPHalf", target.species, *target.pokemon.types)
            @battler_triggers[:targ].push("LastTargetHPLow", target.species, *target.pokemon.types) if lowHP
          else
            @battler_triggers[:targ].push("TargetHPHalf", target.species, *target.pokemon.types)
            @battler_triggers[:targ].push("TargetHPLow", target.species, *target.pokemon.types) if lowHP
          end
        else
          @battler_triggers[:targ].push("TargetHPHalf", target.species, *target.pokemon.types)
          @battler_triggers[:targ].push("LastTargetHPHalf", target.species, *target.pokemon.types)
          if lowHP
            @battler_triggers[:targ].push("TargetHPLow", target.species, *target.pokemon.types)
            @battler_triggers[:targ].push("LastTargetHPLow", target.species, *target.pokemon.types)
          end
        end
      end
    end
    @battler_triggers.each do |battler, triggers|
      next if triggers.empty?
      case battler
      when :user then @battle.pbDeluxeTriggers(user, target.index, *triggers)
      when :targ then @battle.pbDeluxeTriggers(target, user.index, *triggers)
      end
    end
    @battler_triggers[:user].clear
    @battler_triggers[:targ].clear
  end
end


#===============================================================================
# Adds midbattle triggers to HP animation for when a battler's HP changes.
#===============================================================================
class Battle::Scene::PokemonDataBox < Sprite
  def update_hp_animation
    return if !animating_hp?
    @anim_hp_current = lerp(@anim_hp_start, @anim_hp_end, HP_BAR_CHANGE_TIME,
                            @anim_hp_timer_start, System.uptime)
    refresh_hp
    if @anim_hp_current == @anim_hp_end
      if @anim_hp_start > @anim_hp_end
        triggers = ["BattlerHPReduced", @battler.species, *@battler.pokemon.types]
        if !@battler.fainted? && @battler.hasLowHP?
          triggers.push("BattlerHPCritical", @battler.species, *@battler.pokemon.types)
        end
        @battler.battle.pbDeluxeTriggers(@battler, nil, *triggers)
      elsif @anim_hp_start < @anim_hp_end
        triggers = ["BattlerHPRecovered", @battler.species, *@battler.pokemon.types]
        if @battler.hp == @battler.totalhp
          triggers.push("BattlerHPFull", @battler.species, *@battler.pokemon.types)
        end
        @battler.battle.pbDeluxeTriggers(@battler, nil, *triggers)
      end
      @anim_hp_start = nil
      @anim_hp_end = nil
      @anim_hp_timer_start = nil
      @anim_hp_current = nil
    end
  end
end


#===============================================================================
# Miscellaneous triggers.
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Midbattle triggers upon sending out a Pokemon in battle.
  # Functionally the same as "AfterSwitchIn", except this also triggers upon
  # sending out a trainer's lead Pokemon at the start of battle.
  #-----------------------------------------------------------------------------
  alias dx_pbResetCommandsIndex pbResetCommandsIndex
  def pbResetCommandsIndex(idxBattler)
    dx_pbResetCommandsIndex(idxBattler)
    battler = @battle.battlers[idxBattler]
    triggers = ["AfterSendOut", battler.species, *battler.pokemon.types]
    if @battle.pbAbleNonActiveCount(idxBattler) == 0
      triggers.push("AfterLastSendOut", battler.species, *battler.pokemon.types)
    end
    @battle.pbDeluxeTriggers(idxBattler, nil, *triggers)
  end

  #-----------------------------------------------------------------------------
  # Midbattle triggers upon the end of the battle.
  #-----------------------------------------------------------------------------
  alias dx_pbEndBattle pbEndBattle
  def pbEndBattle(_result)
    if !pbInSafari? && !pbInBugContest?
      triggers = ["BattleEnd"]
      case _result
      when 1 then triggers.push("BattleEndWin")
      when 2 then triggers.push("BattleEndLoss")
      when 4 then triggers.push("BattleEndWin", "BattleEndCapture")
      when 5 then triggers.push("BattleEndLoss", "BattleEndDraw")
      when 3
        if @battle.wildBattle?
          trigger = "BattleEndFled"
          @battle.allOtherSideBattlers.each { |b| trigger = "BattleEndRun" }
        else
          trigger = "BattleEndForfeit"
        end
        triggers.push(trigger)
      end
      @battle.pbDeluxeTriggers(1, nil, *triggers)
    end
    dx_pbEndBattle(_result)
  end
end