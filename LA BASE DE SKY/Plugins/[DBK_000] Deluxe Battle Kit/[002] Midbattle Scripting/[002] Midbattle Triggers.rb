#===============================================================================
# Module for storing all midbattle scripts.
#===============================================================================
module MidbattleHandlers
  @@scripts = {}

  def self.add(midbattle, id, proc)
    @@scripts[midbattle] = HandlerHash.new if !@@scripts.has_key?(midbattle)
    @@scripts[midbattle].add(id, proc)
  end

  def self.remove(midbattle, id)
    @@scripts[midbattle]&.remove(id)
  end

  def self.clear(midbattle)
    @@scripts[midbattle]&.clear
  end
  
  def self.exists?(midbattle, id)
    return !@@scripts[midbattle][id].nil?
  end
  
  def self.has_any?(midbattle)
    return @@scripts[midbattle]&.keys.length > 0
  end

  def self.script_keys
    return [] if !@@scripts.has_key?(:midbattle_scripts)
    return @@scripts[:midbattle_scripts].keys
  end

  def self.trigger(midbattle, id, battle, idxBattler, idxTarget, params)
    return nil if !@@scripts.has_key?(midbattle)
    return nil if !self.exists?(midbattle, id)
    return @@scripts[midbattle][id].call(battle, idxBattler, idxTarget, params)
  end
  
  def self.trigger_each(midbattle, battle, idxBattler, idxTarget, trigger)
    return if !@@scripts.has_key?(midbattle)
    @@scripts[midbattle].keys.each do |id|
      @@scripts[midbattle][id].call(battle, idxBattler, idxTarget, trigger)
    end
  end
end


################################################################################
#
# Midbattle utilities.
#
################################################################################

#-------------------------------------------------------------------------------
# Sets a new battler as the focus.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "setBattler",
  proc { |battle, idxBattler, idxTarget, params|
    idxBattler = 0 if idxBattler.nil? || !battle.battlers[idxBattler]
    default_battler = battle.battlers[idxBattler]
    if default_battler.fainted?
      side = battle.allSameSideBattlers(idxBattler)
      default_battler = side.first if !side.empty?
    end
    idxTarget = 1 if idxTarget.nil? || !battle.battlers[idxTarget]
    default_target = battle.battlers[idxTarget]
    if default_target.fainted?
      side = battle.allSameSideBattlers(idxTarget)
      default_target = side.first if !side.empty?
    end
    default_target = default_battler.pbDirectOpposing(true) if default_target.index == default_battler.index
    case params
    when Integer        then targ = battle.battlers[params] || default_battler
    when :Self          then targ = default_battler
    when :Ally          then targ = default_battler.allAllies.first || default_battler
    when :Ally2         then targ = default_battler.allAllies.last  || default_battler
    when :Opposing      then targ = default_target
    when :OpposingAlly  then targ = default_target.allAllies.first  || default_target
    when :OpposingAlly2 then targ = default_target.allAllies.last   || default_target
    end
    targ = default_battler if !targ
    PBDebug.log("     'setBattler': finding battler #{targ.name} (#{targ.index})...")
    next targ
  }
)

#-------------------------------------------------------------------------------
# Freezes the entire battle scene in place for a certain duration.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "wait",
  proc { |battle, idxBattler, idxTarget, params|
    PBDebug.log("     'wait': freezing the battle scene in place for #{params} seconds")
    pbWait(params)
  }
)

#-------------------------------------------------------------------------------
# Pauses any further processing in the battle scene for a certain duration.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "pause",
  proc { |battle, idxBattler, idxTarget, params|
    PBDebug.log("     'pause': pausing processing for #{params} seconds")
    battle.scene.pbPauseScene(params)
  }
)

#-------------------------------------------------------------------------------
# Ignores any further script commands until a certain trigger is detected.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "ignoreUntil",
  proc { |battle, idxBattler, idxTarget, params|
    ignore = true
    triggers = battle.activated_triggers
    params = [params] if !params.is_a?(Array)
    params.each do |t|
      next if !triggers.include?(t)
      PBDebug.log("     'ignoreUntil': doesn't exit midbattle commands because #{t} trigger has activated")
      ignore = false
    end
    next ignore
  }
)

#-------------------------------------------------------------------------------
# Ignores any further script commands after a certain trigger is detected.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "ignoreAfter",
  proc { |battle, idxBattler, idxTarget, params|
    ignore = false
    triggers = battle.activated_triggers
    params = [params] if !params.is_a?(Array)
    params.each { |t| ignore = true if triggers.include?(t) }
    params.each do |t|
      next if !triggers.include?(t)
      PBDebug.log("     'ignoreAfter': will exit midbattle commands because #{t} trigger has activated")
      ignore = true
    end
    next ignore
  }
)

#-------------------------------------------------------------------------------
# Toggles the state of a particular game switch.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "toggleSwitch",
  proc { |battle, idxBattler, idxTarget, params|
    if params.is_a?(Integer) && params >= 0
      $game_switches[params] = !$game_switches[params]
      value = ($game_switches[params]) ? "ON" : "OFF"
      PBDebug.log("     'toggleSwitch': game switch #{params} has been turned #{value}")
    end
  }
)

#-------------------------------------------------------------------------------
# Sets the value of the midbattle variable.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "setVariable",
  proc { |battle, idxBattler, idxTarget, params|
    if params.is_a?(Array)
      battle.midbattleVariable = params.sample
    else
      battle.midbattleVariable = params
    end
    battle.midbattleVariable = 0 if battle.midbattleVariable < 0
    PBDebug.log("     'setVariable': midbattle variable set to #{battle.midbattleVariable}")
  }
)

#-------------------------------------------------------------------------------
# Adds to the value of the midbattle variable.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "addVariable",
  proc { |battle, idxBattler, idxTarget, params|
    oldvar = battle.midbattleVariable
    if params.is_a?(Array)
      battle.midbattleVariable += params.sample
    else
      battle.midbattleVariable += params
    end
    battle.midbattleVariable = 0 if battle.midbattleVariable < 0
    PBDebug.log("     'addVariable': midbattle variable changed (#{oldvar} => #{battle.midbattleVariable})")
  }
)

#-------------------------------------------------------------------------------
# Multiplies the value of the midbattle variable.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "multVariable",
  proc { |battle, idxBattler, idxTarget, params|
    oldvar = battle.midbattleVariable
    battle.midbattleVariable *= params
    battle.midbattleVariable.round
    battle.midbattleVariable = 0 if battle.midbattleVariable < 0
    PBDebug.log("     'multVariable': midbattle variable changed (#{oldvar} => #{battle.midbattleVariable})")
  }
)


################################################################################
#
# Text and speech.
#
################################################################################

#-------------------------------------------------------------------------------
# Displays one or more lines of normal battle text.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "text",
  proc { |battle, idxBattler, idxTarget, params|
    battle.scene.pbForceEndSpeech
    params = [params] if !params.is_a?(Array)
    PBDebug.log("     'text': displaying battle text")
    battle.scene.pbProcessText(idxBattler, idxTarget, false, params.clone)
  }
)

#-------------------------------------------------------------------------------
# Displays one or more lines of cinematic speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "speech",
  proc { |battle, idxBattler, idxTarget, params|
    params = [params] if !params.is_a?(Array)
    PBDebug.log("     'speech': displaying midbattle speech")
    battle.scene.pbProcessText(idxBattler, idxTarget, true, params.clone)
  }
)

#-------------------------------------------------------------------------------
# Sets up data for the next choice option in text/speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "setChoices",
  proc { |battle, idxBattler, idxTarget, params|
    battle.midbattleChoices = params.clone
    PBDebug.log("     'setChoices': preparing midbattle text choices")
  }
)
	
#-------------------------------------------------------------------------------
# Slides a speaker on screen to begin cinematic speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "setSpeaker",
  proc { |battle, idxBattler, idxTarget, params|
    if !battle.scene.pbInCinematicSpeech?
      battle.scene.pbToggleDataboxes 
      battle.scene.pbToggleBlackBars(true)
    end
    battle.scene.pbHideSpeaker
    if params == :Hide
      PBDebug.log("     'setSpeaker': hiding speaker sprite")
      next
    else
      params = battle.battlers[idxBattler] if params == :Battler
      battle.scene.pbShowSpeaker(idxBattler, idxTarget, params)
      speaker = battle.scene.pbGetSpeaker
      battle.scene.pbShowSpeakerWindows(speaker)
      PBDebug.log("     'setSpeaker': showing new speaker (#{speaker.name})")
    end
  }
)

#-------------------------------------------------------------------------------
# Sets a new speaker sprite during speech instead of swapping out speakers.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "editSpeaker",
  proc { |battle, idxBattler, idxTarget, params|
    next if !battle.scene.pbInCinematicSpeech?
    if params.is_a?(Array) && params[0].is_a?(Array)
      speaker, window = params[0], [params[1], params[2]]
    else
      speaker, window = params, []
    end
    if params == :Hide
      battle.scene.pbHideSpeaker
      PBDebug.log("     'editSpeaker': hiding speaker sprite")
    else
      battle.scene.pbUpdateSpeakerSprite(*speaker)
      speaker = battle.scene.pbGetSpeaker
      if window.empty?
        battle.scene.pbUpdateSpeakerWindows(speaker)
      else
        battle.scene.pbUpdateSpeakerWindows(*window)
      end
      PBDebug.log("     'editSpeaker': replacing speaker sprite (#{speaker.name})")
    end
  }
)

#-------------------------------------------------------------------------------
# Edits the display of the speaker's text windows during speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "editWindow",
  proc { |battle, idxBattler, idxTarget, params|
    next if !battle.scene.pbInCinematicSpeech?
    case params
    when :Hide
      battle.scene.pbHideSpeakerWindows(true)
      PBDebug.log("     'editWindow': hiding speaker window")
    when :Show
      speaker = battle.scene.pbGetSpeaker
      battle.scene.pbShowSpeakerWindows(speaker)
      PBDebug.log("     'editWindow': displaying speaker window")
    else
      battle.scene.pbShowSpeakerWindows(*params)
      PBDebug.log("     'editWindow': speaker window changed")
    end
  }
)

#-------------------------------------------------------------------------------
# Ends cinematic speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "endSpeech",
  proc { |battle, idxBattler, idxTarget, params|
    battle.scene.pbForceEndSpeech
    PBDebug.log("     'endSpeech': exiting midbattle speech")
  }
)

################################################################################
#
# Audio and animations.
#
################################################################################

#-------------------------------------------------------------------------------
# Plays a SE.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "playSE",
  proc { |battle, idxBattler, idxTarget, params|
    pbSEPlay(params)
    PBDebug.log("     'playSE': playing SE (#{params})")
  }
)

#-------------------------------------------------------------------------------
# Plays a Pokemon cry.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "playCry",
  proc { |battle, idxBattler, idxTarget, params|
    idx = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, params)
    if idx.is_a?(Integer)
      next if !battle.battlers[idx]
      battle.battlers[idx].displayPokemon.play_cry
      PBDebug.log("     'playCry': playing #{battle.battlers[idx].name}'s cry")
      
    else
      GameData::Species.play_cry(params)
      PBDebug.log("     'playCry': playing cry for species #{GameData::Species.get(params).name}")
      
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the BGM.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeBGM",
  proc { |battle, idxBattler, idxTarget, params|
    if params.is_a?(Array)
      bgm, fade, vol, pitch = params[0], params[1] * 1.0, params[2], params[3]
    else
      bgm, fade, vol, pitch = params, 0.0, nil, nil
    end
    pbBGMFade(fade)
    pbWait(fade)
    pbBGMPlay(bgm, vol, pitch)
    battle.default_bgm = bgm
    battle.playing_bgm = bgm
    battle.bgm_paused = false
    PBDebug.log("     'changeBGM': playing new BGM (#{bgm})")
  }
)

#-------------------------------------------------------------------------------
# Fades out and ends the current BGM.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "endBGM",
  proc { |battle, idxBattler, idxTarget, params|
    pbBGMFade(params)
    battle.bgm_paused = true
    PBDebug.log("     'endBGM': ending current BGM")
  }
)

#-------------------------------------------------------------------------------
# Pauses current BGM and begins playing a new one.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "pauseAndPlayBGM",
  proc { |battle, idxBattler, idxTarget, params|
    battle.pbPauseAndPlayBGM(params)
    PBDebug.log("     'pauseAndPlayBGM': pausing old BGM and playing new one (#{params})")
  }
)

#-------------------------------------------------------------------------------
# Resumes playing the previously paused BGM.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "resumeBGM",
  proc { |battle, idxBattler, idxTarget, params|
    battle.pbResumeBattleBGM
    PBDebug.log("     'resumeBGM': playing previously paused BGM")
  }
)

#-------------------------------------------------------------------------------
# Plays an animation.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "playAnim",
  proc { |battle, idxBattler, idxTarget, params|
    if params.is_a?(Array)
      anim = params[0]
      user = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, params[1])
      target = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, params[2])
    else
      anim, user, target = params, idxBattler, nil
    end
    if target.nil? && GameData::Move.exists?(anim)
      case GameData::Move.get(anim).target
      when :NearAlly
        target = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, :Ally)
      when :Foe, :NearFoe, :RandomNearFoe, :NearOther, :Other
        target = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, :Opposing)
      else
        target = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, :Self)
      end
    end
    target = user if !target
    user = battle.battlers[user]
    target = battle.battlers[target]
    case anim
    when "Recall"
      battle.scene.pbRecall(target.index || user.index)
      PBDebug.log("     'playAnim': playing recall animation")
    when Symbol
      battle.pbAnimation(anim, user, target)
      PBDebug.log("     'playAnim': playing move animation (#{GameData::Move.get(anim).name})")
    when String 
      battle.pbCommonAnimation(anim, user, target)
      PBDebug.log("     'playAnim': playing common animation (#{anim})")
    end
  }
)


################################################################################
#
# Manipulates the usage of battle mechanics.
#
################################################################################

#-------------------------------------------------------------------------------
# Forces a trainer to use an item.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "useItem",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    item = (params.is_a?(Array)) ? params.sample : params
    next if !item || !GameData::Item.exists?(item) 
    battler = battle.battlers[idxBattler]
    if GameData::Item.get(item).is_poke_ball?
      battler = battler.pbDirectOpposing(true) if !battler.opposes?
    end
    next if !battler || battler.fainted?
    ch = battle.choices[battler.index]
    if [:ETHER, :MAXETHER, :LEPPABERRY].include?(item)
      lowest_pp_idx = ch[1]
      lowest_pp = battler.moves[lowest_pp_idx].pp
      battler.pokemon.moves.each_with_index do |m, i|
        next if m.pp >= m.total_pp
        next if m.pp >= lowest_pp
        lowest_pp = m.pp
        lowest_pp_idx = i
      end
      ch[1] = lowest_pp_idx
    end
    next if !ItemHandlers.triggerCanUseInBattle(
      item, battler.pokemon, battler, ch[1], true, battle, battle.scene, false)
    battle.scene.pbForceEndSpeech
    PBDebug.log("     'useItem': #{battler.name} (#{battler.index}) set to use item #{GameData::Item.get(item).name}")
    if !GameData::Item.get(item).is_poke_ball?
      trainerName = (battler.wild?) ? battler.name : battle.pbGetOwnerName(battler.index) 
      battle.pbUseItemMessage(item, trainerName)
    end
    if ItemHandlers.hasUseInBattle(item)
      ItemHandlers.triggerUseInBattle(item, battler, battle)
    elsif ItemHandlers.hasBattleUseOnBattler(item)
      ItemHandlers.triggerBattleUseOnBattler(item, battler, battle.scene)
      battler.pbItemOnStatDropped
    elsif ItemHandlers.hasBattleUseOnPokemon(item)
      ItemHandlers.triggerBattleUseOnPokemon(item, battler.pokemon, battler, ch, battle.scene)
    else
      battle.pbDisplay(_INTL("¡Pero no tuvo efecto!"))
    end
  }
)

#-------------------------------------------------------------------------------
# Forces a battler to use a specific move on a specific target.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "useMove",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    next if battler.movedThisRound? ||
            battler.effects[PBEffects::ChoiceBand]    ||
            battler.effects[PBEffects::Instructed]    ||
            battler.effects[PBEffects::TwoTurnAttack] ||
            battler.effects[PBEffects::Encore]    > 0 ||
            battler.effects[PBEffects::HyperBeam] > 0 ||
            battler.effects[PBEffects::Outrage]   > 0 ||
            battler.effects[PBEffects::Rollout]   > 0 ||
            battler.effects[PBEffects::Uproar]    > 0 ||
            battler.effects[PBEffects::SkyDrop] >= 0
    ch = battle.choices[battler.index]
    next if ch[0] != :UseMove
    next if ch[2].powerMove?
    if params.is_a?(Array)
      id = params[0]
      target = params[1] || -1
    else
      id, target = params, -1
    end
    targFlag = nil
    target = battle.battlers[target]
    has_target = target && !target.fainted? && target.near?(battler)
    case id
    when Integer
      idxMove = id
    when Symbol
      idxMove = -1
      battler.eachMoveWithIndex { |m, i| idxMove = i if m.id == id }
    when String
      st = id.split("_")
      eligible_moves = []
      battler.eachMoveWithIndex do |m, i|
        case st[0]
        when "Damage" then next if !m.damagingMove?
        when "Status" then next if !m.statusMove? || m.healingMove?
        when "Heal"   then next if !m.healingMove?
        end
        if has_target && m.damagingMove?
          effect = Effectiveness.calculate(m.pbCalcType(battler), *target.pbTypes(true))
          next if Effectiveness.ineffective?(effect)
          next if Effectiveness.not_very_effective?(effect)
        end
        targ = GameData::Target.get(GameData::Move.get(m.id).target)
        targFlag = st[1]
        case targFlag
        when "self"
          next if ![:User, :UserOrNearAlly, :UserAndAllies].include?(targ.id)
        when "ally"
          next if targ.num_targets == 0
          next if ![:NearAlly, :UserOrNearAlly, :AllAllies, :NearOther, :Other].include?(targ.id)
        when "foe"
          next if targ.num_targets == 0
          next if !targ.targets_foe
        end
        eligible_moves.push(i)
      end
      idxMove = eligible_moves.sample || -1
    end
    next if !battler.moves[idxMove]
    next if !battle.pbCanChooseMove?(battler.index, idxMove, false)
    battle.scene.pbForceEndSpeech
    targ = GameData::Target.get(battler.moves[idxMove].target)
    if !has_target
      if targFlag.nil? && targ.num_targets != 0
        targFlag = (targ == :NearAlly) ? "ally" : "foe"
      end
      case targFlag
      when "ally"
        if !target || target.idxOwnSide != battler.idxOwnSide
          battler.allAllies.each { |b| target = b if battler.near?(b) }
        end
      when "foe"
        if !target || target.idxOwnSide == battler.idxOwnSide
          target = battler.pbDirectOpposing(true)
        end
      else
        target = battler
      end
    end
    ch[1] = idxMove
    ch[2] = battler.moves[idxMove]
    ch[3] = target.index
    battle.pbCalculatePriority(false, [idxBattler]) if ch[2].priority != 0
    PBDebug.log("     'useMove': #{battler.name} (#{battler.index}) set to use move #{ch[2].name}")
  }
)

#-------------------------------------------------------------------------------
# Forces a trainer to switch Pokemon.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "switchOut",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battler.wild? || battle.decision > 0
    next if !battle.pbCanSwitchOut?(idxBattler)
    if params.is_a?(Array)
      switch, msg = params[0], params[1]
    else
      switch, msg = params, nil
    end
    newPkmn = nil
    canSwitch = false
    battle.eachInTeamFromBattlerIndex(idxBattler) do |pkmn, i|
      next if !battle.pbCanSwitchIn?(idxBattler, i)
      case switch
      when :Choose, :Random, :Forced
      when Integer
        next if switch != i
        newPkmn = i
      when Symbol
        next if !GameData::Species.exists?(switch)
        next if switch != pkmn.species
        newPkmn = i
      end
      canSwitch = true
      break
    end
    if canSwitch
      battle.scene.pbForceEndSpeech
      if newPkmn.nil?
        case switch
        when :Choose
          newPkmn = battle.pbSwitchInBetween(battler.index)
        else
          newPkmn = battle.pbGetReplacementPokemonIndex(battler.index, true)
        end
      end
      if newPkmn && newPkmn >= 0
        trainerName = battle.pbGetOwnerName(battler.index)
        PBDebug.log("     'switchOut': #{trainerName} set to switch out #{battler.name} (#{battler.index})")
        if msg
          lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
          msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName)
          battle.pbDisplay(msg.gsub(/\\PN/i, battle.pbPlayer.name))
        end
        case switch
        when :Forced
          battle.pbDisplay(_INTL("¡{1} volvió con {2}!", battler.pbThis, trainerName))
          battle.pbRecallAndReplace(battler.index, newPkmn, true)
          battle.pbDisplay(_INTL("¡{1} fue arrastrado al campo!", battler.pbThis))
        else
          battle.pbMessageOnRecall(battler)
          battle.pbRecallAndReplace(battler.index, newPkmn)
        end
        battle.pbClearChoice(battler.index)
        battle.pbOnBattlerEnteringBattle(battler.index)
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Forces a trainer to Mega Evolve.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "megaEvolve",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !params || !battler || battler.fainted? || battle.decision > 0
    ch = battle.choices[battler.index]
    next if ch[0] != :UseMove
    oldMode = battle.wildBattleMode
    battle.wildBattleMode = :mega if battler.wild? && oldMode != :mega
    if battle.pbCanMegaEvolve?(battler.index)
      PBDebug.log("     'megaEvolve': #{battler.name} (#{battler.index}) set to Mega Evolve")
      battle.scene.pbForceEndSpeech
      battle.pbDisplay(params.gsub(/\\PN/i, battle.pbPlayer.name)) if params.is_a?(String)
      battle.pbMegaEvolve(battler.index)
    end
    battle.wildBattleMode = oldMode
  }
)

#-------------------------------------------------------------------------------
# Toggles the availability of Mega Evolution for trainers.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableMegas",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler 
    side = (battler.opposes?) ? 1 : 0
    owner = battle.pbGetOwnerIndexFromBattlerIndex(idxBattler)
    battle.megaEvolution[side][owner] = (params) ? -2 : -1
    value = (params) ? "disabled" : "enabled"
    trainerName = battle.pbGetOwnerName(idxBattler)
    PBDebug.log("     'disableMegas': Mega Evolution #{value} for #{trainerName}")
  }
)

#-------------------------------------------------------------------------------
# Toggles the player's ability to use Poke Balls.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableBalls",
  proc { |battle, idxBattler, idxTarget, params|
    battle.disablePokeBalls = params
    value = (params) ? "disabled" : "enabled"
    PBDebug.log("     'disableBalls': usage of Poke Balls has been #{value}")
  }
)

#-------------------------------------------------------------------------------
# Toggles all trainer's ability to use items from their inventory.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableItems",
  proc { |battle, idxBattler, idxTarget, params|
    battle.noBag = params
    value = (params) ? "disabled" : "enabled"
    PBDebug.log("     'disableItems': all trainers usage of items from the inventory has been #{value}")
  }
)

#-------------------------------------------------------------------------------
# Toggles the player's controls being handled by the AI.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableControl",
  proc { |battle, idxBattler, idxTarget, params|
    battle.controlPlayer = params
    value = (params) ? "disabled" : "enabled"
    PBDebug.log("     'disableControl': player controls have been #{value}")
  }
)

#-------------------------------------------------------------------------------
# Prematurely forces the battle to end.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "endBattle",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    params = 1 if params == 4
    PBDebug.log("     'endBattle': forcing the battle to end prematurely")
    battle.scene.pbForceEndSpeech
    battle.decision = params
  }
)

#-------------------------------------------------------------------------------
# Forces a wild Pokemon to flee.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "wildFlee",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if battle.decision > 0 || !battler || !battler.wild?
    PBDebug.log("     'wildFlee': forcing the wild #{battler.name} (#{battler.index}) to flee")
    battle.scene.pbForceEndSpeech
    battler.wild_flee(params) 
  }
)


################################################################################
#
# Battler conditions.
#
################################################################################

#-------------------------------------------------------------------------------
# Changes a battler's name.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerName",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    if !nil_or_empty?(params)
      PBDebug.log("     'battlerName': changing #{battler.name} (#{battler.index})'s name to #{params}")
      battler.pokemon.name = params
      battler.name = params
      battle.scene.pbRefresh
    end
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's HP.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerHP",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    battle.scene.pbForceEndSpeech
    if params.is_a?(Array)
      amt, msg = params[0], params[1]
    else
      amt, msg = params, nil
    end
    lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
    trainerName = (battler.wild?) ? "" : battle.pbGetOwnerName(battler.index)
    msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName) if msg
    old_hp = battler.hp
    if amt > 0
      PBDebug.log("     'battlerHP': restoring #{battler.name} (#{battler.index})'s HP by #{amt}%")
	    battler.stopBoostedHPScaling = true
      battler.pbRecoverHP(amt)
    elsif amt <= 0
      if amt == 0
        battler.hp = 1
      else
        battler.hp += amt
        battler.hp = 0 if battler.hp < 0
      end
      PBDebug.log("     'battlerHP': reducing #{battler.name} (#{battler.index})'s HP (#{old_hp} => #{battler.hp})")
      battle.scene.pbHitAndHPLossAnimation([[battler, old_hp, 0]])
    end
    if battler.hp != old_hp
      battle.pbDisplay(msg.gsub(/\\PN/i, battle.pbPlayer.name)) if msg
      battler.pbFaint(true) if battler.fainted?
    end
  }
)

#-------------------------------------------------------------------------------
# Sets a cap for how much HP the battler is capable of losing from attacks.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerHPCap",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    battler.damageThreshold = params
    PBDebug.log("     'battlerHPCap': setting maximum damage threshold for #{battler.name} (#{battler.index})")
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's status condition.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerStatus",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    battle.scene.pbForceEndSpeech
    if params.is_a?(Array)
      status, msg = params[0], params[1]
    else
      status, msg = params, false
    end
    status = status.sample if status.is_a?(Array)
    case status
    when :Random
      statuses = []
      GameData::Status.each { |s| statuses.push(s.id) if s.id != :NONE }
      statuses.shuffle.each do |s|
        next if !battler.pbCanInflictStatus?(s, battler)
        statusName = GameData::Status.get(s).name
        PBDebug.log("     'battlerStatus': #{battler.name} (#{battler.index}) to be inflicted with #{statusName} status")
        count = ([:SLEEP, :DROWSY].include?(s)) ? battler.pbSleepDuration : 0
        battler.pbInflictStatus(status, count)
        break
      end
    when :NONE
      PBDebug.log("     'battlerStatus': #{battler.name} (#{battler.index}) to be cured of any status conditions")
      battler.pbCureAttract
      battler.pbCureConfusion
      battler.pbCureStatus(msg)
    when :CONFUSE, :CONFUSED, :CONFUSION
      if battler.pbCanConfuse?(battler, msg)
        PBDebug.log("     'battlerStatus': #{battler.name} (#{battler.index}) to be inflicted with confusion")
        battler.pbConfuse(msg)
      end
    when :BAD_POISON, :TOXIC, :TOXIC_POISON
      if battler.pbCanPoison?(battler, msg)
        PBDebug.log("     'battlerStatus': #{battler.name} (#{battler.index}) to be inflicted with badly poisoned status")
        battler.pbPoison(nil, msg, true)
      end
    else
      if GameData::Status.exists?(status) && battler.pbCanInflictStatus?(status, battler, msg)
        statusName = GameData::Status.get(status).name
        PBDebug.log("     'battlerStatus': #{battler.name} (#{battler.index}) to be inflicted with #{statusName} status")
        count = ([:SLEEP, :DROWSY].include?(status)) ? battler.pbSleepDuration : 0
        battler.pbInflictStatus(status, count)
      end
    end
    battler.pbCheckFormOnStatusChange
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's typing.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerType",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0 || !battler.canChangeType?
    changed_types = false
    old_types = battler.pbTypes
    params = params[0] if params.is_a?(Array) && params.length == 1
    case params
    when :Reset
      next if battler.types == battler.pokemon.types
      battler.pbResetTypes
      PBDebug.log("     'battlerType': #{battler.name} (#{battler.index}) typing reset to normal")
      battle.pbDisplay(_INTL("¡{1} recuperó su tipo original!", battler.pbThis))
    when Symbol
      next if !GameData::Type.exists?(params)
      next if !battler.pbHasOtherType?(params)
      battler.pbChangeTypes(params)
      typeName = GameData::Type.get(params).name
      PBDebug.log("     'battlerType': #{battler.name} (#{battler.index}) typing became #{typeName}")
      battle.pbDisplay(_INTL("¡El tipo de {1} cambió a {2}!", battler.pbThis, typeName))
    when Array
      types = []
      params.each { |type| types.push(type) if GameData::Type.exists?(type) }
      next if types.empty?
      new_types = types.sort_by { |t| GameData::Type.get(t).icon_position }
      old_types = old_types.sort_by { |t| GameData::Type.get(t).icon_position }
      next if new_types == old_types
      battler.types = types
      battler.effects[PBEffects::ExtraType] = nil
      battler.effects[PBEffects::BurnUp] = false
      battler.effects[PBEffects::Roost]  = false
      typeNames = ""
      types.each_with_index do |t, i|
        typeNames += ((i == types.length - 1) ? " y " : ", ") if i > 0
        typeNames += GameData::Type.get(t).name
      end
      PBDebug.log("     'battlerType': #{battler.name} (#{battler.index}) typing became #{typeNames}")
      battle.pbDisplay(_INTL("¡El tipo de {1} cambió a {2}!", battler.pbThis, typeNames))
    end
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's form.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerForm",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0 || !battler.getActiveState.nil?
    next if battler.effects[PBEffects::SkyDrop] >= 0 || battler.semiInvulnerable?
    if params.is_a?(Array)
      form, msg = params[0], params[1]
    else
      form, msg = params, nil
    end
    if msg.is_a?(String)
      lowercase = (msg[0] == "{" && msg[1] == "1") ? false : true
      trainerName = (battler.wild?) ? "" : battle.pbGetOwnerName(battler.index)
      msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName)
    end
    case form
    when :Cycle
      form = battler.form + 1
    when :Random
      total_forms = []
      GameData::Species.each do |s|
        next if s.species != battler.species
        next if s.form == battler.form || s.form == 0
        next if s.has_special_form?
        total_forms.push(s.form)
      end
      form = total_forms.sample
    end
    next if !form
    species = GameData::Species.get_species_form(battler.species, form)
    if species.has_special_form?
      form = 0
    else
      form = species.form
    end
    next if battler.form == form
    PBDebug.log("     'battlerForm': #{battler.name} (#{battler.index}) to change into form #{form}")
    battle.scene.pbForceEndSpeech
    battler.pbSimpleFormChange(form, msg)
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's species.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerSpecies",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0 || !battler.getActiveState.nil?
    next if battler.effects[PBEffects::SkyDrop] >= 0 || battler.semiInvulnerable?
    if params.is_a?(Array)
      species, msg = params[0], params[1]
    else
      species, msg = params, nil
    end
    try_species = GameData::Species.try_get(species)
    next if !try_species
    battle.scene.pbForceEndSpeech
    speciesName = GameData::Species.get(species).name
    PBDebug.log("     'battlerSpecies': #{battler.name} (#{battler.index}) to change into species #{speciesName}")
    if msg.is_a?(String)
      lowercase = (msg[0] == "{" && msg[1] == "1") ? false : true
      trainerName = (battler.wild?) ? "" : battle.pbGetOwnerName(battler.index)
      msg = _INTL("#{msg}", battler.pbThis(lowercase), speciesName, trainerName)
    end
    battle.scene.pbAnimateSubstitute(idxBattler, :hide)
    old_ability = battler.ability_id
    if battler.hasActiveAbility?(:ILLUSION)
      Battle::AbilityEffects.triggerOnBeingHit(battler.ability, nil, battler, nil, battle)
    end
    battler.pokemon.species = try_species.species
    battler.pokemon.form_simple = try_species.form
    battler.species = try_species.species
    battler.form = try_species.form
    battler.pbUpdate(true)
    battler.name = speciesName if !battler.pokemon.nicknamed?
    battle.scene.pbRefreshOne(idxBattler)
    battler.mosaicChange = true if defined?(battler.mosaicChange)
    battle.scene.pbChangePokemon(battler, battler.pokemon)
    battle.pbDisplay(msg.gsub(/\\PN/i, battle.pbPlayer.name)) if msg.is_a?(String)
    battler.pbOnLosingAbility(old_ability)
    battler.pbTriggerAbilityOnGainingIt
    battle.pbCalculatePriority(false, [idxBattler]) if !battler.movedThisRound?
    battle.scene.pbAnimateSubstitute(idxBattler, :show)
  }
)

#-------------------------------------------------------------------------------
# Forces a battler to evolve during battle.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerEvolve",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    if params.is_a?(Array)
      species, form = params[0], params[1]
    else
      species, form = params, nil
    end
    next if battler.pokemon.species == species
    if !GameData::Species.exists?(species)
      evolutions = []
      GameData::Species.get(battler.pokemon.species).get_evolutions.each do |evo|
        next if evolutions.include?(evo[0]) || evo[0] == battler.pokemon.species
        evolutions.push(evo[0])
      end
      next if evolutions.empty?
      species = (params == :Random) ? evolutions.shuffle.first : evolutions.first
    end
    battle.scene.pbForceEndSpeech
    oldName = battler.name
    if battler.pbEvolveBattler(species, form)
      PBDebug.log("     'battlerEvolve': #{oldName} (#{battler.index}) to evolved into species #{battler.pokemon.speciesName}")
    end
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's ability.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerAbility",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    if params.is_a?(Array)
      abil, msg = params[0], params[1]
    else
      abil, msg = params, nil
    end
    abil = abil.sample if abil.is_a?(Array)
    abil = battler.pokemon.ability_id if abil == :Reset
    next if !abil || !GameData::Ability.exists?(abil)
    next if battler.ability_id == abil
    next if battler.ungainableAbility?(abil)
    next if battler.unstoppableAbility?
    abilName = GameData::Ability.get(abil).name
    PBDebug.log("     'battlerAbility': #{battler.name} (#{battler.index}) to acquire the #{abilName} ability")
    battle.pbShowAbilitySplash(battler, true, false) if msg
    oldAbil = battler.ability
    break_illusion = false
    if battler.hasActiveAbility?(:ILLUSION)
      battle.scene.pbAnimateSubstitute(idxBattler, :hide)
      Battle::AbilityEffects.triggerOnBeingHit(battler.ability, nil, battler, nil, battle)
      break_illusion = true
    end
    battler.ability = abil
    battle.scene.pbForceEndSpeech
    if msg
      battle.pbReplaceAbilitySplash(battler)
      if msg.is_a?(String)
        lowercase = (msg[0] == "{" && msg[1] == "1") ? false : true
        trainerName = (battler.wild?) ? "" : battle.pbGetOwnerName(battler.index)
        msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName)
        battle.pbDisplay(msg.gsub(/\\PN/i, battle.pbPlayer.name))
      else
        battle.pbDisplay(_INTL("¡{1} obtuvo {2}!", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
    battler.pbOnLosingAbility(oldAbil)
    battler.pbTriggerAbilityOnGainingIt
    battle.scene.pbAnimateSubstitute(idxBattler, :show) if break_illusion
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's held item.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerItem",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    if params.is_a?(Array)
      item, msg = params[0], params[1]
    else
      item, msg = params, nil
    end
    item = item.sample if item.is_a?(Array)
    next if !item || !GameData::Item.exists?(item)
    next if battler.unlosableItem?(item)
    next if battler.item_id == item
    if msg.is_a?(String)
      lowercase = (msg[0] == "{" && msg[1] == "1") ? false : true
      trainerName = (battler.wild?) ? "" : battle.pbGetOwnerName(battler.index)
      msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName)
    end
    olditem = battler.item
    battle.scene.pbForceEndSpeech
    case item
    when :Remove
      next if !battler.item
      PBDebug.log("     'battlerItem': #{battler.name} (#{battler.index})'s held item #{battler.itemName} to be removed")
      battler.item = nil
      if msg && !msg.is_a?(String)
        itemName = GameData::Item.get(olditem).portion_name
        battle.pbDisplay(_INTL("¡{1} perdió {2}!", battler.pbThis, itemName))
      end
    else
      battler.item = item
      PBDebug.log("     'battlerItem': #{battler.name} (#{battler.index}) given the item #{battler.itemName} to hold")
      if msg && !msg.is_a?(String)
        itemName = GameData::Item.get(battler.item).portion_name
        battle.pbDisplay(_INTL("¡{1} obtuvo {2}!", battler.pbThis, itemName))
      end
    end
    if msg.is_a?(String)
      battle.pbDisplay(msg.gsub(/\\PN/i, battle.pbPlayer.name))
    end
    battler.pbCheckFormOnHeldItemChange
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's moves.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerMoves",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    case params
    when Array
      Pokemon::MAX_MOVES.times do |i|
        new_move = params[i]
        old_move = battler.moves[i]
        if new_move && GameData::Move.exists?(new_move)
          move = Pokemon::Move.new(new_move)
          battler.moves[i] = Battle::Move.from_pokemon_move(battle, move)
          if old_move
            PBDebug.log("     'battlerMoves': #{battler.name} (#{battler.index}) replaced the move #{old_move.name} with #{battler.moves[i].name}")
          else
            PBDebug.log("     'battlerMoves': #{battler.name} (#{battler.index}) learned the move #{battler.moves[i].name}")
          end
        elsif old_move && new_move.nil?
          PBDebug.log("     'battlerMoves': #{battler.name} (#{battler.index}) forgot the move #{old_move.name}")
          battler.moves[i] = nil
        end
      end
      battler.moves.compact!
      battler.moves.uniq!
    when :Reset
      battler.moves.clear
      battler.pokemon.numMoves.times do |i|
        move = battler.pokemon.moves[i]
        battler.moves[i] = Battle::Move.from_pokemon_move(battle, move)
      end
      PBDebug.log("     'battlerMoves': #{battler.name} (#{battler.index})'s moveset reset to its original moves")
    else
      move_data = GameData::Move.try_get(params)
      next if !move_data || battler.pbHasMove?(params)
      move = Pokemon::Move.new(params)
      battler.moves.push(Battle::Move.from_pokemon_move(battle, move))
      battler.moves.shift if battler.moves.length > Pokemon::MAX_MOVES
      PBDebug.log("     'battlerMoves': #{battler.name} (#{battler.index}) learned the move #{move.name}")
    end
    battler.pbCheckFormOnMovesetChange
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's stat stages.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerStats",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    battle.scene.pbForceEndSpeech
    case params
    when :Reset
      if battler.hasAlteredStatStages?
        battler.pbResetStatStages
        PBDebug.log("     'battlerStats': #{battler.name} (#{battler.index})'s stat changes returning to normal")
        battle.pbDisplay(_INTL("¡Los cambios de estadísticas de {1} han desaparecido!", battler.pbThis))
      end
    when :ResetRaised
      if battler.hasRaisedStatStages?
        battler.statsDropped = true
        battler.statsLoweredThisRound = true
        GameData::Stat.each_battle { |s| battler.stages[s.id] = 0 if battler.stages[s.id] > 0 }
        PBDebug.log("     'battlerStats': #{battler.name} (#{battler.index})'s raised stat stages returning to normal")
        battle.pbDisplay(_INTL("¡Las subidas de estadísticas de {1} han desaparecido!", battler.pbThis))
      end
    when :ResetLowered
      if battler.hasLoweredStatStages?
        battler.statsRaisedThisRound = true
        GameData::Stat.each_battle { |s| battler.stages[s.id] = 0 if battler.stages[s.id] < 0 }
        PBDebug.log("     'battlerStats': #{battler.name} (#{battler.index})'s raised stat stages returning to normal")
        battle.pbDisplay(_INTL("¡Las bajadas de estadísticas de {1} han desaparecido!", battler.pbThis))
      end
    when Array
      showAnim = true
      last_change = 0
      rand_stats = []
      GameData::Stat.each_battle do |s| 
        next if params.include?(s.id)
        rand_stats.push(s.id)
      end
      for i in 0...params.length / 2
        stat, stage = params[i * 2], params[i * 2 + 1]
        next if !stage.is_a?(Integer) || stage == 0
        if stat == :Random
          loop do
            break if rand_stats.empty?
            randstat = rand_stats.sample
            rand_stats.delete(randstat) if randstat
            next if params.include?(randstat)
            stat = randstat
            break
          end
        end
        next if !stat.is_a?(Symbol)
        try_stat = GameData::Stat.try_get(stat)
        next if !try_stat
        if stage > 0
          next if !battler.pbCanRaiseStatStage?(stat, battler)
          showAnim = true if !showAnim && last_change < 0
          PBDebug.log("     'battlerStats': #{battler.name} (#{battler.index})'s #{try_stat.name} to be raised")
          if battler.pbRaiseStatStage(stat, stage, battler, showAnim)
            last_change = stage
            showAnim = false
          end
        else
          next if !battler.pbCanLowerStatStage?(stat, battler)
          showAnim = true if !showAnim && last_change > 0
          PBDebug.log("     'battlerStats': #{battler.name} (#{battler.index})'s #{try_stat.name} to be lowered")
          if battler.pbLowerStatStage(stat, stage.abs, battler, showAnim)
            last_change = stage
            showAnim = false
          end
          break if battler.pbItemOnStatDropped
        end
      end
      battler.pbItemStatRestoreCheck
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the effects on a battler.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerEffects",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    effects = (params[0].is_a?(Array)) ? params : [params]
    effects.each do |array|
      id, value, msg = *array
      effect = PBEffects.const_get(id)
      subeffect = nil
      next if !effect
      lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
      battler_name = battler.pbThis(lowercase)
      battle.scene.pbForceEndSpeech if msg
      if $DELUXE_PBEFFECTS[:battler][:boolean].include?(id)
        next if battler.effects[effect] == value
        next if [:TwoTurnAttack, :Transform].include?(id)
        case id
        when :Nightmare
          next if !battler.asleep?
        when :ExtraType
          next if !value.nil? && (!GameData::Type.exists?(value) || battler.pbHasType?(value))
        end
        battler.effects[effect] = value
        PBDebug.log("     'battlerEffects': #{battler.name} (#{battler.index})'s #{id} effect set to #{value}")
        battle.pbDisplay(_INTL(msg, battler_name)) if msg
        if id == :SmackDown && value && defined?(battler.battlerSprite)
          next if battler.battlerSprite.vanishMode != 2
          battle.scene.pbChangePokemon(battler, battler.visiblePokemon, 0)
        end
      elsif $DELUXE_PBEFFECTS[:battler][:counter].include?(id)
        next if battler.effects[effect] == 0 && value == 0
        case id
        when :Yawn
          next if battler.status != :NONE
        when :FuryCutter
          maxMult = 1
          power = GameData::Move.get(:FURYCUTTER).power
          while (power << (maxMult - 1)) < 160
            maxMult += 1
          end
          next if battler.effects[effect] >= maxMult
        when :MagnetRise, :Telekinesis
          next if battle.field.effects[PBEffects::Gravity] > 0
          next if id == :Telekinesis && battler.mega? && battler.isSpecies?(:GENGAR)
        when :Substitute, :WeightChange, :FocusEnergy
          oldVal = battler.effects[effect]
          battler.effects[effect] += value
          if id == :Substitute && oldVal == 0 && value > 0
            battle.scene.pbAnimateSubstitute(battler, :create)
          end
          PBDebug.log("     'battlerEffects': #{battler.name} (#{battler.index})'s #{id} effect increased by #{value}")
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
          next
        when :Stockpile
          next if battler.effects[effect] == 3
          battler.effects[effect] += (value).clamp(1, 3 - battler.effects[effect])
          battler.effects[PBEffects::StockpileDef] = battler.effects[effect]
          battler.effects[PBEffects::StockpileSpDef] = battler.effects[effect]
          PBDebug.log("     'battlerEffects': #{battler.name} (#{battler.index})'s #{id} effect increased by #{value}")
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
          next
        end
        next if battler.effects[effect] > 0 && value > 0
        case id
        when :LockOn, :Trapping, :Syrupy
          opposing = battler.pbDirectOpposing(true)
          next if !opposing || opposing.fainted?
          case id
          when :LockOn   then subeffect = PBEffects::LockOnPos
          when :Trapping then subeffect = PBEffects::TrappingUser
          when :Syrupy   then subeffect = PBEffects::SyrupyUser
          end
          battler.effects[subeffect] = opposing.index
        when :Disable, :Encore
          next if !battler.lastMoveUsed
          case id
          when :Disable then subeffect = PBEffects::DisableMove
          when :Encore  then subeffect = PBEffects::EncoreMove
          end
          battler.effects[subeffect] = battler.lastMoveUsed
        end
        battler.effects[effect] = value
        if subeffect
          sub = battler.effects[subeffect]
          PBDebug.log("     'battlerEffects': #{battler.name} (#{battler.index})'s #{id} effect set to #{value} (#{sub})")
        else
          PBDebug.log("     'battlerEffects': #{battler.name} (#{battler.index})'s #{id} effect set to #{value}")
        end
        battle.pbDisplay(_INTL(msg, battler_name)) if msg
      elsif $DELUXE_PBEFFECTS[:battler][:index].include?(id)
        next if battler.effects[effect] == -1 && value == -1
        next if value >= 0 && !battle.battlers[value]
        next if id == :SkyDrop
        battler.effects[effect] = value
        PBDebug.log("     'battlerEffects': #{battler.name} (#{battler.index})'s #{id} effect set to #{value}")
        battle.pbDisplay(_INTL(msg, battler_name)) if msg
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Sets the Wish effect on a battler's position.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerWish",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battle.decision > 0
    next if battle.positions[idxBattler].effects[PBEffects::Wish] > 0
    if params.is_a?(Array)
      count, amount = *params
    elsif params.is_a?(Integer)
      count = params
      amount = (battler.totalhp / 2.0).round
    else
      count = 2
      amount = (battler.totalhp / 2.0).round
    end
    battle.positions[idxBattler].effects[PBEffects::Wish]       = count
    battle.positions[idxBattler].effects[PBEffects::WishAmount] = amount
    battle.positions[idxBattler].effects[PBEffects::WishMaker]  = battler.pokemonIndex
    PBDebug.log("     'battlerWish': Wish effect to trigger in #{count} turns on #{battler.name} (#{battler.index})'s position")
    battle.pbDisplay(_INTL("¡El deseo de {1} se cumplió!", battler.pbThis))
  }
)


################################################################################
#
# Battlefield conditions.
#
################################################################################

#-------------------------------------------------------------------------------
# Changes the effects on one side of the battlefield.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "teamEffects",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battle.decision > 0
    index = battler.idxOwnSide
    if battler.index.odd?
      index = (battler.idxOwnSide == 0) ? 1 : 0
    end
    case index
    when 0 then side = battler.pbOwnSide
    when 1 then side = battler.pbOpposingSide
    end
    effects = (params[0].is_a?(Array)) ? params : [params]
    effects.each do |array|
      id, value, msg = *array
      effect = PBEffects.const_get(id)
      next if !effect
      battle.scene.pbForceEndSpeech if msg
      lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
      case index
      when 0 then team_name = battler.pbTeam(lowercase)
      when 1 then team_name = battler.pbOpposingTeam(lowercase)
      end
      if $DELUXE_PBEFFECTS[:team][:boolean].include?(id)
        next if side.effects[effect] == value
        side.effects[effect] = value
        PBDebug.log("     'teamEffects': #{id} effect set to #{value} on #{team_name}")
        battle.pbDisplay(_INTL(msg, team_name)) if msg
      elsif $DELUXE_PBEFFECTS[:team][:counter].include?(id)
        case id
        when :Spikes, :ToxicSpikes
          max = (id == :Spikes) ? 3 : 2
          if value > 0
            next if side.effects[effect] >= max
            oldVal = side.effects[effect]
            side.effects[effect] += (value).clamp(1, max - side.effects[effect])
            PBDebug.log("     'teamEffects': #{id} effect increased (#{oldVal} => #{side.effects[effect]}) on #{team_name}")
          else
            next if side.effects[effect] == 0
            side.effects[effect] = 0
            PBDebug.log("     'teamEffects': #{id} effect set to 0 on #{team_name}")
          end
        else
          next if side.effects[effect] > 0 && value > 0
          next if side.effects[effect] == 0 && value == 0
          side.effects[effect] = value
          PBDebug.log("     'teamEffects': #{id} effect set to #{value} on #{team_name}")
        end
        battle.pbDisplay(_INTL(msg, team_name)) if msg
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the effects affecting the entire battlefield.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "fieldEffects",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    battler = battle.battlers[idxBattler]
    effects = (params[0].is_a?(Array)) ? params : [params]
    effects.each do |array|
      id, value, msg = *array
      effect = PBEffects.const_get(id)
      next if !effect
      battle.scene.pbForceEndSpeech if msg
      lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
      battler_name = (battler) ? battler.pbThis(lowercase) : ""
      if $DELUXE_PBEFFECTS[:field][:boolean].include?(id)
        next if battle.field.effects[effect] == value
        battle.field.effects[effect] = value
        PBDebug.log("     'fieldEffects': #{id} effect set to #{value}")
        battle.pbDisplay(_INTL(msg, battler_name)) if msg
      elsif $DELUXE_PBEFFECTS[:field][:counter].include?(id)
        next if battle.field.effects[effect] > 0 && value > 0
        next if battle.field.effects[effect] == 0 && value == 0
        case id
        when :PayDay
          oldVal = battle.field.effects[effect]
          battle.field.effects[effect] += value
          PBDebug.log("     'fieldEffects': #{id} effect increased (#{oldVal} => #{battle.field.effects[effect]})")
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
        when :TrickRoom
          battle.field.effects[effect] = value
          PBDebug.log("     'fieldEffects': #{id} effect set to #{value}")
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
          if battle.field.effects[effect] > 0
            battle.allBattlers.each do |b|
              next if !b.hasActiveItem?(:ROOMSERVICE)
              next if !b.pbCanLowerStatStage?(:SPEED)
              battle.pbCommonAnimation("UseItem", b)
              b.pbLowerStatStage(:SPEED, 1, nil)
              b.pbConsumeItem
            end
          end
        when :Gravity
          battle.field.effects[effect] = value
          PBDebug.log("     'fieldEffects': #{id} effect set to #{value}")
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
          if battle.field.effects[effect] > 0
            battle.allBattlers.each do |b|
              showMessage = false
              if b.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                                    "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
                                    "TwoTurnAttackInvulnerableInSkyTargetCannotAct")
                b.effects[PBEffects::TwoTurnAttack] = nil
                battle.pbClearChoice(b.index) if !b.movedThisRound?
                showMessage = true
              end
              if b.effects[PBEffects::MagnetRise]  >  0 ||
                 b.effects[PBEffects::Telekinesis] >  0 ||
                 b.effects[PBEffects::SkyDrop]     >= 0
                b.effects[PBEffects::MagnetRise]    = 0
                b.effects[PBEffects::Telekinesis]   = 0
                b.effects[PBEffects::SkyDrop]       = -1
                showMessage = true
              end
              battle.pbDisplay(_INTL("¡{1} no pudo mantenerse en el aire debido a la gravedad!", b.pbThis)) if showMessage
              if defined?(b.battlerSprite)
                next if b.battlerSprite.vanishMode != 2
                battle.scene.pbChangePokemon(b, b.visiblePokemon, 0)
              end
            end
          end
        else
          battle.field.effects[effect] = value
          PBDebug.log("     'fieldEffects': #{id} effect set to #{value}")
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
        end
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the battlefield weather.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeWeather",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    next if [:HarshSun, :HeavyRain, :StrongWinds].include?(battle.field.weather)
    battler = battle.battlers[idxBattler]
    battle.scene.pbForceEndSpeech
    case params
    when :Random
      array = []
      GameData::BattleWeather::DATA.keys.each do |key|
        next if [:None, :HarshSun, :HeavyRain, :StrongWinds, :ShadowSky, battle.field.weather].include?(key)
        array.push(key)
      end
      weather = array.sample
      PBDebug.log("     'changeWeather': starting random weather")
      battle.pbStartWeather(battler, weather, true)
    when :None
      PBDebug.log("     'changeWeather': ending current weather")
      case battle.field.weather
      when :Sun       then battle.pbDisplay(_INTL("El sol vuelve a brillar como siempre."))
      when :Rain      then battle.pbDisplay(_INTL("Ha dejado de llover."))
      when :Sandstorm then battle.pbDisplay(_INTL("La tormenta de arena ha amainado."))
      when :ShadowSky then battle.pbDisplay(_INTL("El cielo recuperó su luz."))
      when :Hail    
        if defined?(Settings::HAIL_WEATHER_TYPE)
          case Settings::HAIL_WEATHER_TYPE
          when 0 then battle.pbDisplay(_INTL("Ha dejado de granizar."))
          when 1 then battle.pbDisplay(_INTL("Ha dejado de nevar."))
          when 2 then battle.pbDisplay(_INTL("Ha dejado de granizar."))
          end
        else
          battle.pbDisplay(_INTL("Ha dejado de nevar."))
        end
      else
        battle.pbDisplay(_INTL("El tiempo se ha calmado."))
      end
      battle.pbStartWeather(battler, :None, true)
    else
      params = :Hail if params == :Snow
      try_weather = GameData::BattleWeather.try_get(params)
      if try_weather && battle.field.weather != try_weather.id
        PBDebug.log("     'changeWeather': starting #{try_weather.name} weather")
        battle.pbStartWeather(battler, try_weather.id, true)
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the battlefield terrain.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeTerrain",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    battler = battle.battlers[idxBattler]
    battle.scene.pbForceEndSpeech
    case params
    when :Random
      array = []
      GameData::BattleTerrain::DATA.keys.each do |key|
        next if [:None, battle.field.terrain].include?(key)
        array.push(key)
      end
      terrain = array.sample
      PBDebug.log("     'changeTerrain': starting random terrain")
      battle.pbStartTerrain(battler, terrain)
    when :None
      PBDebug.log("     'changeTerrain': ending current terrain")
      case battle.field.terrain
      when :Electric  then battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
      when :Grassy    then battle.pbDisplay(_INTL("La hierba ha desaparecido."))
      when :Misty     then battle.pbDisplay(_INTL("La niebla se ha disipado."))
      when :Psychic   then battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que se percibía en el terreno de combate."))
      else                 battle.pbDisplay(_INTL("El terreno de combate ha vuelto a la normalidad."))
      end
      battle.pbStartTerrain(battler, :None)
    else
      try_terrain = GameData::BattleTerrain.try_get(params)
      if try_terrain && battle.field.terrain != try_terrain.id
        PBDebug.log("     'changeTerrain': starting #{try_terrain.name} Terrain")
        battle.pbStartTerrain(battler, try_terrain.id)
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the battlefield environment.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeEnvironment",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    battler = battle.battlers[idxBattler]
    case params
    when :Random
      array = []
      GameData::Environment::DATA.keys.each do |key|
        next if [:None, battle.environment].include?(key)
        array.push(key)
      end
      env = GameData::Environment.get(array.sample)
      PBDebug.log("     'changeEnvironment': set random battle environment (#{env.name})")
      battle.environment = env.id
    else
      try_env = GameData::Environment.try_get(params)
      if try_env && battle.environment != try_env.id
        PBDebug.log("     'changeEnvironment': setting battle environment to #{try_env.name}")
        battle.environment = try_env.id
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the battle backdrop and bases.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeBackdrop",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    if params.is_a?(Array)
      backdrop, base = params[0], params[1]
    else
      backdrop = base = params
    end
    PBDebug.log("     'changeBackdrop': setting new battle background (#{backdrop})")
    battle.backdrop = backdrop if pbResolveBitmap("Graphics/Battlebacks/#{backdrop}_bg")
    if base && pbResolveBitmap("Graphics/Battlebacks/#{base}_base0")
      PBDebug.log("     'changeBackdrop': setting new battle bases (#{base})")
      oldEnv = battle.environment
      battle.backdropBase = base
      if base.include?("city")          then battle.environment = :None
      elsif base.include?("grass")      then battle.environment = :Grass
      elsif base.include?("water")      then battle.environment = :MovingWater
      elsif base.include?("puddle")     then battle.environment = :Puddle
      elsif base.include?("underwater") then battle.environment = :Underwater
      elsif base.include?("cave")       then battle.environment = :Cave
      elsif base.include?("rocky")      then battle.environment = :Rock
      elsif base.include?("volcano")    then battle.environment = :Volcano
      elsif base.include?("sand")       then battle.environment = :Sand
      elsif base.include?("forest")     then battle.environment = :Forest
      elsif base.include?("snow")       then battle.environment = :Snow
      elsif base.include?("ice")        then battle.environment = :Ice
      elsif base.include?("distortion") then battle.environment = :Graveyard
      elsif base.include?("sky")        then battle.environment = :Sky
      elsif base.include?("space")      then battle.environment = :Space
      end
      if battle.environment != oldEnv
        envName = GameData::Environment.get(battle.environment).name
        PBDebug.log("     'changeBackdrop': battle environment set to #{envName} to match new bases")
      end
    end
    battle.scene.pbFlashRefresh
  }
  )

#-------------------------------------------------------------------------------
# Changes the style applied to all battler's databoxes.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeDataboxes",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    old_style = battle.databoxStyle || :None
    old_style = old_style.first if old_style.is_a?(Array)
    style = (params.is_a?(Array)) ? params.first : params
    next if battle.raidBattle? && !GameData::DataboxStyle.exists?(style)
    battle.scene.pbRefreshStyle(*params)
    PBDebug.log("     'changeDataboxes': changed databox style (#{old_style}=>#{style})") if style != old_style
  }
)







def change_background_in_battle(battle, battlback, flash = false, blanco = true)
    return if battle.decision > 0
    if battlback.is_a?(Array)
      backdrop, base = battlback[0], battlback[1]
    else
      backdrop = base = battlback
    end
    PBDebug.log("     'changeBackdrop': setting new battle background (#{backdrop})")
    battle.backdrop = backdrop if pbResolveBitmap("Graphics/Battlebacks/#{backdrop}_bg")
    if base && pbResolveBitmap("Graphics/Battlebacks/#{base}_base0")
      PBDebug.log("     'changeBackdrop': setting new battle bases (#{base})")
      oldEnv = battle.environment
      battle.backdropBase = base
      if base.include?("city")          then battle.environment = :None
      elsif base.include?("grass")      then battle.environment = :Grass
      elsif base.include?("water")      then battle.environment = :MovingWater
      elsif base.include?("puddle")     then battle.environment = :Puddle
      elsif base.include?("underwater") then battle.environment = :Underwater
      elsif base.include?("cave")       then battle.environment = :Cave
      elsif base.include?("rocky")      then battle.environment = :Rock
      elsif base.include?("volcano")    then battle.environment = :Volcano
      elsif base.include?("sand")       then battle.environment = :Sand
      elsif base.include?("forest")     then battle.environment = :Forest
      elsif base.include?("snow")       then battle.environment = :Snow
      elsif base.include?("ice")        then battle.environment = :Ice
      elsif base.include?("distortion") then battle.environment = :Graveyard
      elsif base.include?("sky")        then battle.environment = :Sky
      elsif base.include?("space")      then battle.environment = :Space
      end
      if battle.environment != oldEnv
        envName = GameData::Environment.get(battle.environment).name
        PBDebug.log("     'changeBackdrop': battle environment set to #{envName} to match new bases")
      end
    end
    if flash
      if blanco
        battle.scene.pbFlashRefresh
      else
        battle.scene.pbFlashBlackRefresh
      end
    else
      battle.scene.pbCreateBackdropSprites
    end
end
