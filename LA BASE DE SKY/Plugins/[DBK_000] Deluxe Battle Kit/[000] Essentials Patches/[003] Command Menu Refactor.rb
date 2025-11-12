#===============================================================================
# Fight Menu rewrites.
#===============================================================================
# Rewrites code related to the visuals of the fight menu.
#-------------------------------------------------------------------------------
class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  def initialize(viewport, z)
    super(viewport)
    self.x = 0
    self.y = Graphics.height - 96
    @battler = nil
    resetMenuToggles
    @customUI = PluginManager.installed?("Customizable Battle UI")
    folder = @customUI ? "#{$game_variables[53]}/" : ""
    path = "Graphics/UI/Battle/" + folder
    if USE_GRAPHICS
      @buttonBitmap  = AnimatedBitmap.new(_INTL(path + "cursor_fight"))
      @typeBitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
      @shiftBitmap   = AnimatedBitmap.new(_INTL(path + "cursor_shift"))
      @actionButtonBitmap = {}
      addSpecialActionButtons(path)
      background = IconSprite.new(0, Graphics.height - 96, viewport)
      background.setBitmap(path + "overlay_fight")
      addSprite("background", background)
      @buttons = Array.new(Pokemon::MAX_MOVES) do |i|
        button = Sprite.new(viewport)
        button.bitmap = @buttonBitmap.bitmap
        button.x = self.x + 4
        button.x += (i.even? ? 0 : (@buttonBitmap.width / 2) - 4)
        button.y = self.y + 6
        button.y += (((i / 2) == 0) ? 0 : BUTTON_HEIGHT - 4)
        button.src_rect.width  = @buttonBitmap.width / 2
        button.src_rect.height = BUTTON_HEIGHT
        if @customUI
          button.x += (i.even? ? -2 : 2)
          button.y -= 4
        end
        addSprite("button_#{i}", button)
        next button
      end
      @overlay = BitmapSprite.new(Graphics.width, Graphics.height - self.y, viewport)
      @overlay.x = self.x
      @overlay.y = self.y
      pbSetNarrowFont(@overlay.bitmap)
      addSprite("overlay", @overlay)
      @infoOverlay = BitmapSprite.new(Graphics.width, Graphics.height - self.y, viewport)
      @infoOverlay.x = self.x
      @infoOverlay.y = self.y
      pbSetNarrowFont(@infoOverlay.bitmap)
      addSprite("infoOverlay", @infoOverlay)
      @typeIcon = Sprite.new(viewport)
      @typeIcon.bitmap = @typeBitmap.bitmap
      @typeIcon.x      = self.x + 416
      @typeIcon.y      = self.y + 20
      @typeIcon.src_rect.height = TYPE_ICON_HEIGHT
      addSprite("typeIcon", @typeIcon)
      @actionButton = Sprite.new(viewport)
      addSprite("actionButton", @actionButton)
      @shiftButton = Sprite.new(viewport)
      @shiftButton.bitmap = @shiftBitmap.bitmap
      @shiftButton.x      = self.x + 4
      @shiftButton.y      = self.y - @shiftBitmap.height
      addSprite("shiftButton", @shiftButton)
    else
      @msgBox = Window_AdvancedTextPokemon.newWithSize(
        "", self.x + 320, self.y, Graphics.width - 320, Graphics.height - self.y, viewport
      )
      @msgBox.baseColor   = @customUI ? @base_color   : TEXT_BASE_COLOR
      @msgBox.shadowColor = @customUI ? @shadow_color : TEXT_SHADOW_COLOR
      pbSetNarrowFont(@msgBox.contents)
      addSprite("msgBox", @msgBox)
      @cmdWindow = Window_CommandPokemon.newWithSize(
        [], self.x, self.y, 320, Graphics.height - self.y, viewport
      )
      @cmdWindow.columns       = 2
      @cmdWindow.columnSpacing = 4
      @cmdWindow.ignore_input  = true
      pbSetNarrowFont(@cmdWindow.contents)
      addSprite("cmdWindow", @cmdWindow)
    end
    self.z = z
  end

  alias dx_dispose dispose
  def dispose
    dx_dispose
    @actionButtonBitmap.each_value { |bmp| bmp&.dispose }
  end
  
  def chosenButton=(value)
    oldValue = @chosenButton
    @chosenButton = value
    refresh if @chosenButton != oldValue
  end
  
  def refreshSpecialActionButton
    return if !USE_GRAPHICS
    button = @actionButtonBitmap[@chosenButton]
    if !button
      @visibility["actionButton"] = false
    else
      buttonCount, buttonMode = getButtonSettings
      @actionButton.bitmap = button.bitmap    
      @actionButton.x = self.x + ((@shiftMode > 0) ? 204 : 120)
      @actionButton.y = self.y - (button.height / buttonCount)
      @actionButton.src_rect.height = button.height / buttonCount
      @actionButton.src_rect.y = buttonMode * button.height / buttonCount
      @actionButton.z = self.z - 1
      @visibility["actionButton"] = (@mode > 0)
    end
  end
  
  def refreshButtonNames
    moves = (@battler) ? @battler.moves : []
    if !USE_GRAPHICS
      commands = []
      [4, moves.length].max.times do |i|
        commands.push((moves[i]) ? moves[i].name : "-")
      end
      @cmdWindow.commands = commands
      return
    end
    @overlay.bitmap.clear
    textPos = []
    @buttons.each_with_index do |button, i|
      next if !@visibility["button_#{i}"]
      x = button.x - self.x + (button.src_rect.width / 2)
      y = button.y - self.y + 14
      moveNameBase = TEXT_BASE_COLOR
      if GET_MOVE_TEXT_COLOR_FROM_MOVE_BUTTON && moves[i].display_type(@battler)
        moveNameBase = button.bitmap.get_pixel(10, button.src_rect.y + 34)
      end
      base   = @customUI ? @base_color   : moveNameBase
      shadow = @customUI ? @shadow_color : TEXT_SHADOW_COLOR
      textPos.push([moves[i].short_name, x, y, :center, base, shadow])
    end
    pbDrawTextPositions(@overlay.bitmap, textPos)
  end

  def refresh
    return if !@battler
    refreshSelection
    refreshSpecialActionButton
    refreshShiftButton
    refreshButtonNames
  end
end

#===============================================================================
# Other menus.
#===============================================================================
# Adds new options to the Command and Target menus.
#-------------------------------------------------------------------------------
class Battle::Scene::CommandMenu < Battle::Scene::MenuBase
  MODES += [
    [0, 2, 1, 10], # 5 = Fight, Bag, Pokemon, Cheer
    [0, 11, 1, 3], # 6 = Fight, Launch, Pokemon, Run
    [0, 11, 1, 9], # 7 = Fight, Launch, Pokemon, Cancel
    [0, 11, 1, 4], # 8 = Fight, Launch, Pokemon, Call
  ]
end

class Battle::Scene::TargetMenu < Battle::Scene::MenuBase
  MODES += [
    [0, 2, 1, 10], # 5 = Fight, Bag, Pokemon, Cheer
    [0, 11, 1, 3], # 6 = Fight, Launch, Pokemon, Run
    [0, 11, 1, 9], # 7 = Fight, Launch, Pokemon, Cancel
    [0, 11, 1, 4], # 8 = Fight, Launch, Pokemon, Call
  ]
end

#===============================================================================
# Battle::Scene rewrites.
#===============================================================================
# Rewrites code related to the functionality of the fight menu.
#-------------------------------------------------------------------------------
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Edited for command menu display.
  #-----------------------------------------------------------------------------
  def pbCommandMenu(idxBattler, firstAction)
    bagCommand = _INTL("Mochila")
    shadowTrainer = (GameData::Type.exists?(:SHADOW) && @battle.trainerBattle?)
    runCommand = (shadowTrainer) ? _INTL("Llamar") : (firstAction) ? _INTL("Huir") : _INTL("Cancelar")
    if @battle.raidBattle?
      runCommand = _INTL("Animar")
      mode = 5
    elsif @battle.launcherBattle?
      bagCommand = _INTL("Launch")
      mode = (shadowTrainer) ? 8 : (firstAction) ? 6 : 7
    else
      mode = (shadowTrainer) ? 2 : (firstAction) ? 0 : 1
    end
    cmds = [
      _INTL("¿Qué debería\nhacer {1}?", @battle.battlers[idxBattler].name),
      _INTL("Luchar"), bagCommand,
      _INTL("Pokémon"), runCommand
    ]
    ret = pbCommandMenuEx(idxBattler, cmds, mode)
    ret = 4 if ret == 3 && shadowTrainer || @battle.raidBattle?
    ret = -1 if ret == 3 && !firstAction && !@battle.raidBattle?
    return 3 if ret > 3 && ($DEBUG && Input.press?(Input::CTRL))
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Edited for fight menu functionality.
  #-----------------------------------------------------------------------------
  def pbFightMenu(idxBattler, specialAction = nil)
    battler = @battle.battlers[idxBattler]
    cw = @sprites["fightWindow"]
    cw.battler = battler
    moveIndex = 0
    if battler.moves[@lastMove[idxBattler]]&.id
      moveIndex = @lastMove[idxBattler]
    end
    cw.setIndexAndMode(moveIndex, (!specialAction.nil?) ? 1 : 0)
    pbSetSpecialActionModes(idxBattler, specialAction, cw)
    cw.refresh
    needFullRefresh = true
    needRefresh = false
    loop do
      if needFullRefresh
        pbShowWindow(FIGHT_BOX)
        pbSelectBattler(idxBattler)
        needFullRefresh = false
      end
      if needRefresh
        newMode = (@battle.pbBattleMechanicIsRegistered?(idxBattler, specialAction)) ? 2 : 1
        if newMode != cw.mode
          cw.mode = newMode 
          pbFightMenu_Update(battler, specialAction, cw)
        end
        needRefresh = false
      end
      oldIndex = cw.index
      pbUpdate(cw)
      if Input.trigger?(Input::LEFT)
        cw.index -= 1 if (cw.index & 1) == 1
      elsif Input.trigger?(Input::RIGHT)
        cw.index += 1 if battler.moves[cw.index + 1]&.id && (cw.index & 1) == 0
      elsif Input.trigger?(Input::UP)
        cw.index -= 2 if (cw.index & 2) == 2
      elsif Input.trigger?(Input::DOWN)
        cw.index += 2 if battler.moves[cw.index + 2]&.id && (cw.index & 2) == 0
      end
      if cw.index != oldIndex
        pbPlayCursorSE
        pbFightMenu_Update(battler, specialAction, cw)		
      end
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break if yield pbFightMenu_Confirm(battler, specialAction, cw)
        needFullRefresh = true
        needRefresh = true
      elsif Input.trigger?(Input::BACK)
        break if yield pbFightMenu_Cancel(battler, specialAction, cw)
        needRefresh = true
      elsif Input.trigger?(Input::ACTION)
        if specialAction
          needFullRefresh = pbFightMenu_Action(battler, specialAction, cw)
          break if yield specialAction
          needRefresh = true
        end
      elsif Input.trigger?(Input::SPECIAL)
        if cw.shiftMode > 0
          break if yield pbFightMenu_Shift(battler, cw)
          needRefresh = true
        end
      end
      pbFightMenu_Extra(battler, specialAction, cw)
    end
    pbFightMenu_End(battler, specialAction, cw)
    @lastMove[idxBattler] = cw.index
  end
end

def pbPlayActionSE
  file = pbResolveAudioFile("DX Action Button", 80)
  if file.name && file.name != ""
    pbSEPlay(file)
  else
    pbPlayDecisionSE
  end
end

#===============================================================================
# Battle rewrites.
#===============================================================================
# Rewrites code related to the fight menu and the command loop during battle.
#-------------------------------------------------------------------------------
class Battle
  def pbFightMenu(idxBattler)
    return pbAutoChooseMove(idxBattler) if !pbCanShowFightMenu?(idxBattler)
    return true if pbAutoFightMenu(idxBattler)
    ret = false
    @scene.pbFightMenu(idxBattler, pbGetEligibleBattleMechanic(idxBattler)) do |cmd|
      case cmd
      when :cancel
      when :shift
        pbUnregisterAllSpecialActions(idxBattler)
        pbRegisterShift(idxBattler)
        ret = true
      when Symbol
        pbToggleSpecialActions(idxBattler, cmd)
        next false
      else
        next false if cmd < 0 || !@battlers[idxBattler].moves[cmd] ||
                      !@battlers[idxBattler].moves[cmd].id
        next false if !pbRegisterMove(idxBattler, cmd)
        next false if !singleBattle? &&
                      !pbChooseTarget(@battlers[idxBattler], @battlers[idxBattler].moves[cmd])
        ret = true
      end
      next true
    end
    return ret
  end
  
  def pbCanShowFightMenu?(idxBattler)
    battler = @battlers[idxBattler]
    return false if battler.effects[PBEffects::Encore] > 0 &&
                    !pbCanUseAnyBattleMechanic?(idxBattler)
    usable = false
    battler.eachMoveWithIndex do |_m, i|
      next if !pbCanChooseMove?(idxBattler, i, false)
      usable = true
      break
    end
    return usable
  end
  
  def pbCanChooseMove?(idxBattler, idxMove, showMessages, sleepTalk = false)
    battler = @battlers[idxBattler]
    move = (idxMove.is_a?(Integer)) ? battler.moves[idxMove] : idxMove
    return false unless move
    if move.pp == 0 && move.total_pp > 0 && !sleepTalk
      pbDisplayPaused(_INTL("¡No quedan PP para este movimiento!")) if showMessages
      return false
    end
    if battler.effects[PBEffects::Encore] > 0
      if !move.powerMove? && move.id != battler.effects[PBEffects::EncoreMove]
        if showMessages
          encoreMove = GameData::Move.get(battler.effects[PBEffects::EncoreMove]).name
          pbDisplayPaused(_INTL("¡{1} solo puede usar {2} debido a Otra vez!", battler.name, encoreMove))
        end
        return false
      end
    end
    return battler.pbCanChooseMove?(move, true, showMessages, sleepTalk)
  end
  
  def pbCancelChoice(idxBattler)
    if @choices[idxBattler][0] == :UseItem
      item = @choices[idxBattler][1]
      pbReturnUnusedItemToBag(item, idxBattler) if item
    end
    pbUnregisterAllSpecialActions(idxBattler)
    pbClearChoice(idxBattler)
  end
  
  alias dx_pbItemUsesAllActions? pbItemUsesAllActions?
  def pbItemUsesAllActions?(item)
    return true if GameData::Item.get(item).has_flag?("UsesAllBattleActions")
    return dx_pbItemUsesAllActions?(item)
  end
  
  def pbCommandPhase
    $CanToggle = true
    @command_phase = true
    @scene.pbBeginCommandPhase
    @battlers.each_with_index do |b, i|
      next if !b
      pbClearChoice(i) if pbCanShowCommands?(i)
      pbDeluxeTriggers(i, nil, "RoundStartCommand", 1 + @turnCount) if !b.fainted?
    end
    2.times { |side| pbActionCommands(side) }
    pbCommandPhaseLoop(true)
    if @decision != 0
      @command_phase = false
      return
    end
    pbCommandPhaseLoop(false)
    @command_phase = false
  end
  
  def pbAttackPhase
    @scene.pbBeginAttackPhase
    @battlers.each_with_index do |b, i|
      next if !b
      pbDeluxeTriggers(i, nil, "RoundStartAttack", 1 + @turnCount) if !b.fainted?
      b.turnCount += 1 if !b.fainted?
      @successStates[i].clear
      if @choices[i][0] != :UseMove && @choices[i][0] != :Shift && @choices[i][0] != :SwitchOut
        b.effects[PBEffects::DestinyBond] = false
        b.effects[PBEffects::Grudge]      = false
      end
      b.effects[PBEffects::Rage] = false if !pbChoseMoveFunctionCode?(i, "StartRaiseUserAtk1WhenDamaged")
    end
    pbCalculatePriority(true)
    PBDebug.log("")
    pbAttackPhaseSpecialActions1
    pbAttackPhasePriorityChangeMessages
    pbAttackPhaseCall
    pbAttackPhaseSpecialActions2
    pbAttackPhaseSwitch
    return if @decision > 0
    pbAttackPhaseItems
    return if @decision > 0
    pbAttackPhaseSpecialActions3
    pbAttackPhaseMoves
  end
  
  def pbPursuit(idxSwitcher)
    @switching = true
    pbPriority.each do |b|
      next if b.fainted? || !b.opposes?(idxSwitcher)
      next if b.movedThisRound? || !pbChoseMoveFunctionCode?(b.index, "PursueSwitchingFoe")
      next unless pbMoveCanTarget?(b.index, idxSwitcher, @choices[b.index][2].pbTarget(b))
      next unless pbCanChooseMove?(b.index, @choices[b.index][1], false)
      next if b.status == :SLEEP || b.status == :FROZEN
      next if b.effects[PBEffects::SkyDrop] >= 0
      next if b.hasActiveAbility?(:TRUANT) && b.effects[PBEffects::Truant]
      owner = pbGetOwnerIndexFromBattlerIndex(b.index)
      pbPursuitSpecialActions(b, owner)
      @choices[b.index][3] = idxSwitcher
      b.pbProcessTurn(@choices[b.index], false)
      break if @decision > 0 || @battlers[idxSwitcher].fainted?
    end
    @switching = false
  end
end


#===============================================================================
# Battle::AI rewrites.
#===============================================================================
# Rewrites code related to special action selection by the AI.
#-------------------------------------------------------------------------------
class Battle::AI
  def pbDefaultChooseEnemyCommand(idxBattler)
    set_up(idxBattler)
    ret = false
    PBDebug.logonerr { ret = pbChooseToSwitchOut }
    if ret
      PBDebug.log("")
      return
    end
    ret = false
    PBDebug.logonerr { ret = pbChooseToUseItem }
    if ret
      PBDebug.log("")
      return
    end
    PBDebug.logonerr { ret = pbChooseToUseSpecialCommand }
    if ret
      PBDebug.log("")
      return
    end
    if @battle.pbAutoFightMenu(idxBattler)
      PBDebug.log("")
      return
    end
    pbRegisterEnemySpecialAction(idxBattler)
    choices = pbGetMoveScores
    pbChooseMove(choices)
    PBDebug.log("")
    pbRegisterEnemySpecialAction2(idxBattler)
  end
  
  def pbGetMovesToScore
    moves_to_score = [] 
    Pokemon::MAX_MOVES.times do |i|
      move = @user.battler.moves[i]
      moves_to_score.push(move)
    end
    return moves_to_score
  end
  
  def pbGetMoveScores
    choices = []
    moves_to_score = pbGetMovesToScore
    moves_to_score.each_with_index do |orig_move, idxMove|
      next if !orig_move
      if idxMove >= Pokemon::MAX_MOVES
        until idxMove < Pokemon::MAX_MOVES
          idxMove -= Pokemon::MAX_MOVES
        end
      end
      if !@battle.pbCanChooseMove?(@user.index, orig_move, false)
        if orig_move.pp == 0 && orig_move.total_pp > 0
          PBDebug.log_ai("#{@user.name} cannot use #{orig_move.name} (no PP left)")
        else
          PBDebug.log_ai("#{@user.name} cannot choose to use #{orig_move.name}")
        end
        next
      end
      set_up_move_check(orig_move)
      if @trainer.has_skill_flag?("PredictMoveFailure") && pbPredictMoveFailure
        PBDebug.log_ai("#{@user.name} is considering using #{orig_move.name}...")
        PBDebug.log_score_change(MOVE_FAIL_SCORE - MOVE_BASE_SCORE, "move will fail")
        add_move_to_choices(choices, idxMove, MOVE_FAIL_SCORE, -1, orig_move)
        next
      end
      target_data = @move.pbTarget(@user.battler)
      if @move.function_code == "CurseTargetOrLowerUserSpd1RaiseUserAtkDef1" &&
         @move.rough_type == :GHOST && @user.has_active_ability?([:LIBERO, :PROTEAN])
        target_data = GameData::Target.get((Settings::MECHANICS_GENERATION >= 8) ? :RandomNearFoe : :NearFoe)
      end
      case target_data.num_targets
      when 0
        PBDebug.log_ai("#{@user.name} is considering using #{orig_move.name}...")
        score = MOVE_BASE_SCORE
        PBDebug.logonerr { score = pbGetMoveScore }
        add_move_to_choices(choices, idxMove, score, -1, orig_move)
      when 1
        redirected_target = get_redirected_target(target_data)
        num_targets = 0
        @battle.allBattlers.each do |b|
          next if redirected_target && b.index != redirected_target
          next if !pbAbleToTarget?(@user.battler, b, target_data) # For rival species
          PBDebug.log_ai("#{@user.name} is considering using #{orig_move.name} against #{b.name} (#{b.index})...")
          score = MOVE_BASE_SCORE
          PBDebug.logonerr { score = pbGetMoveScore([b]) }
          add_move_to_choices(choices, idxMove, score, b.index, orig_move)
          num_targets += 1
        end
        PBDebug.log("     no valid targets") if num_targets == 0
      else
        targets = []
        @battle.allBattlers.each do |b|
          next if !@battle.pbMoveCanTarget?(@user.battler.index, b.index, target_data)
          targets.push(b)
        end
        PBDebug.log_ai("#{@user.name} is considering using #{orig_move.name}...")
        score = MOVE_BASE_SCORE
        PBDebug.logonerr { score = pbGetMoveScore(targets) }
        add_move_to_choices(choices, idxMove, score, -1, orig_move)
      end
    end
    @battle.moldBreaker = false
    return choices
  end
  
  def add_move_to_choices(choices, idxMove, score, idxTarget = -1, orig_move = nil)
    choices.push([idxMove, score, idxTarget, 0, orig_move])
    if @user.wild? && @user.pokemon.personalID % @user.battler.moves.length == idxMove
      choices.push([idxMove, score, idxTarget, 0, orig_move])
    end
  end
  
  def pbChooseMove(choices)
    user_battler = @user.battler
    if choices.length == 0
      @battle.pbAutoChooseMove(user_battler.index)
      PBDebug.log_ai("#{@user.name} will auto-use a move or Struggle")
      return
    end
    max_score = 0
    choices.each { |c| max_score = c[1] if max_score < c[1] }
    if @trainer.high_skill? && @user.can_switch_lax?
      badMoves = false
      if max_score <= MOVE_USELESS_SCORE
        badMoves = user.can_attack?
        badMoves = true if !badMoves && pbAIRandom(100) < 25
      elsif max_score < MOVE_BASE_SCORE * move_score_threshold && user_battler.turnCount > 2
        badMoves = true if pbAIRandom(100) < 80
      end
      if badMoves
        PBDebug.log_ai("#{@user.name} wants to switch due to terrible moves")
        if pbChooseToSwitchOut(true)
          @battle.pbUnregisterMegaEvolution(@user.index)
          return
        end
        PBDebug.log_ai("#{@user.name} won't switch after all")
      end
    end
    threshold = (max_score * move_score_threshold.to_f).floor
    choices.each { |c| c[3] = [c[1] - threshold, 0].max }
    total_score = choices.sum { |c| c[3] }
    if $INTERNAL
      PBDebug.log_ai("Move choices for #{@user.name}:")
      choices.each_with_index do |c, i|
        chance = sprintf("%5.1f", (c[3] > 0) ? 100.0 * c[3] / total_score : 0)
        log_msg = "   * #{chance}% to use #{c[4].name}"
        log_msg += " (target #{c[2]})" if c[2] >= 0
        log_msg += ": score #{c[1]}"
        PBDebug.log(log_msg)
      end
    end
    randNum = pbAIRandom(total_score)
    choices.each do |c|
      randNum -= c[3]
      next if randNum >= 0
      pbRegisterEnemySpecialActionFromMove(user_battler, c[4])
      @battle.pbRegisterMove(user_battler.index, c[0], false)
      @battle.pbRegisterTarget(user_battler.index, c[2]) if c[2] && c[2] >= 0
      break
    end
    if @battle.choices[user_battler.index][2]
      move_name = @battle.choices[user_battler.index][2].name
      if @battle.choices[user_battler.index][3] >= 0
        PBDebug.log("   => will use #{move_name} (target #{@battle.choices[user_battler.index][3]})")
      else
        PBDebug.log("   => will use #{move_name}")
      end
    end
  end
end