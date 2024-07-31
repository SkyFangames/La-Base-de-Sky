#===============================================================================
# Fixed AI always switching Pokémon due to unusable moves if the Pokémon is
# asleep or frozen.
#===============================================================================
class Battle::AI
  def pbChooseMove(choices)
    user_battler = @user.battler
    # If no moves can be chosen, auto-choose a move or Struggle
    if choices.length == 0
      @battle.pbAutoChooseMove(user_battler.index)
      PBDebug.log_ai("#{@user.name} will auto-use a move or Struggle")
      return
    end
    # Figure out useful information about the choices
    max_score = 0
    choices.each { |c| max_score = c[1] if max_score < c[1] }
    # Decide whether all choices are bad, and if so, try switching instead
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
    # Calculate a minimum score threshold and reduce all move scores by it
    threshold = (max_score * move_score_threshold.to_f).floor
    choices.each { |c| c[3] = [c[1] - threshold, 0].max }
    total_score = choices.sum { |c| c[3] }
    # Log the available choices
    if $INTERNAL
      PBDebug.log_ai("Move choices for #{@user.name}:")
      choices.each_with_index do |c, i|
        chance = sprintf("%5.1f", (c[3] > 0) ? 100.0 * c[3] / total_score : 0)
        log_msg = "   * #{chance}% to use #{user_battler.moves[c[0]].name}"
        log_msg += " (target #{c[2]})" if c[2] >= 0
        log_msg += ": score #{c[1]}"
        PBDebug.log(log_msg)
      end
    end
    # Pick a move randomly from choices weighted by their scores
    randNum = pbAIRandom(total_score)
    choices.each do |c|
      randNum -= c[3]
      next if randNum >= 0
      @battle.pbRegisterMove(user_battler.index, c[0], false)
      @battle.pbRegisterTarget(user_battler.index, c[2]) if c[2] >= 0
      break
    end
    # Log the result
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

Battle::AI::Handlers::ShouldSwitch.add(:asleep,
  proc { |battler, reserves, ai, battle|
    # Asleep and won't wake up this round or next round
    next false if battler.status != :SLEEP || battler.statusCount <= 2
    # Doesn't want to be asleep (includes checking for moves usable while asleep)
    next false if battler.wants_status_problem?(:SLEEP)
    # Doesn't benefit from being asleep
    next false if battler.has_active_ability?(:MARVELSCALE)
    # Doesn't know Rest (if it does, sleep is expected, so don't apply this check)
    next false if battler.check_for_move { |m| m.function_code == "HealUserFullyAndFallAsleep" }
    # Not trapping another battler in battle
    if ai.trainer.high_skill?
      next false if ai.battlers.any? do |b|
        b.effects[PBEffects::JawLock] == battler.index ||
        b.effects[PBEffects::MeanLook] == battler.index ||
        b.effects[PBEffects::Octolock] == battler.index ||
        b.effects[PBEffects::TrappingUser] == battler.index
      end
      trapping = false
      ai.each_foe_battler(battler.side) do |b, i|
        next if b.ability_active? && Battle::AbilityEffects.triggerCertainSwitching(b.ability, b.battler, battle)
        next if b.item_active? && Battle::ItemEffects.triggerCertainSwitching(b.item, b.battler, battle)
        next if Settings::MORE_TYPE_EFFECTS && b.has_type?(:GHOST)
        next if b.battler.trappedInBattle?   # Relevant trapping effects are checked above
        if battler.ability_active?
          trapping = Battle::AbilityEffects.triggerTrappingByTarget(battler.ability, b.battler, battler.battler, battle)
          break if trapping
        end
        if battler.item_active?
          trapping = Battle::ItemEffects.triggerTrappingByTarget(battler.item, b.battler, battler.battler, battle)
          break if trapping
        end
      end
      next false if trapping
    end
    # Doesn't have sufficiently raised stats that would be lost by switching
    next false if battler.stages.any? { |key, val| val >= 2 }
    # A reserve Pokémon is awake and not frozen
    next false if reserves.none? { |pkmn| ![:SLEEP, :FROZEN].include?(pkmn.status) }
    # 60% chance to not bother
    next false if ai.pbAIRandom(100) < 60
    PBDebug.log_ai("#{battler.name} wants to switch because it is asleep and can't do anything")
    next true
  }
)

#===============================================================================
# Fixed Cramorant's form not reverting after coughing up its Gulp Missile.
#===============================================================================
class Battle::Battler
  alias __hotfixes__pbEffectsOnMakingHit pbEffectsOnMakingHit unless method_defined?(:__hotfixes__pbEffectsOnMakingHit)

  def pbEffectsOnMakingHit(move, user, target)
    if target.damageState.calcDamage > 0 && !target.damageState.substitute
      # Cramorant - Gulp Missile
      if target.isSpecies?(:CRAMORANT) && target.ability == :GULPMISSILE &&
         target.form > 0 && !target.effects[PBEffects::Transform]
        oldHP = user.hp
        # NOTE: Strictly speaking, an attack animation should be shown (the
        #       target Cramorant attacking the user) and the ability splash
        #       shouldn't be shown.
        @battle.pbShowAbilitySplash(target)
        target_form = target.form
        target.pbChangeForm(0, nil)
        if user.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH)
          @battle.scene.pbDamageAnimation(user)
          user.pbReduceHP(user.totalhp / 4, false)
        end
        case target_form
        when 1   # Gulping Form
          user.pbLowerStatStageByAbility(:DEFENSE, 1, target, false)
        when 2   # Gorging Form
          user.pbParalyze(target) if user.pbCanParalyze?(target, false)
        end
        @battle.pbHideAbilitySplash(target)
        user.pbItemHPHealCheck if user.hp < oldHP
      end
    end
    __hotfixes__pbEffectsOnMakingHit(move, user, target)
  end
end

#===============================================================================
# Fixed Pokémon sent from the party to storage in battle not having certain
# battle-only conditions removed.
# Fixed forcing a caught Pokémon into your party not actually forcing it.
#===============================================================================
module Battle::CatchAndStoreMixin
  def pbStorePokemon(pkmn)
    # Nickname the Pokémon (unless it's a Shadow Pokémon)
    if !pkmn.shadowPokemon?
      if $PokemonSystem.givenicknames == 0 &&
         pbDisplayConfirm(_INTL("¿Quieres ponerle un mote a {1}?", pkmn.name))
        nickname = @scene.pbNameEntry(_INTL("Mote de {1}?", pkmn.speciesName), pkmn)
        pkmn.name = nickname
      end
    end
    # Store the Pokémon
    if pbPlayer.party_full? && (@sendToBoxes == 0 || @sendToBoxes == 2)   # Ask/must add to party
      cmds = [_INTL("Agregar al equipo"),
              _INTL("Enviar a una caja"),
              _INTL("Ver datos de {1}", pkmn.name),
              _INTL("Ver equipo")]
      cmds.delete_at(1) if @sendToBoxes == 2   # Remove "Send to a Box" option
      loop do
        cmd = pbShowCommands(_INTL("¿A dónde quieres enviar a {1}?", pkmn.name), cmds, 99)
        next if cmd == 99 && @sendToBoxes == 2   # Can't cancel if must add to party
        break if cmd == 99   # Cancelling = send to a Box
        cmd += 1 if cmd >= 1 && @sendToBoxes == 2
        case cmd
        when 0   # Add to your party
          pbDisplay(_INTL("Elige a un Pokémon de tu equipo para enviar a las cajas."))
          party_index = -1
          @scene.pbPartyScreen(0, (@sendToBoxes != 2), 1) do |idxParty, _partyScene|
            party_index = idxParty
            next true
          end
          next if party_index < 0   # Cancelled
          party_size = pbPlayer.party.length
          # Get chosen Pokémon and clear battle-related conditions
          send_pkmn = pbPlayer.party[party_index]
          @peer.pbOnLeavingBattle(self, send_pkmn, @usedInBattle[0][party_index], true)
          send_pkmn.statusCount = 0 if send_pkmn.status == :POISON   # Bad poison becomes regular
          send_pkmn.makeUnmega
          send_pkmn.makeUnprimal
          # Send chosen Pokémon to storage
          stored_box = @peer.pbStorePokemon(pbPlayer, send_pkmn)
          pbPlayer.party.delete_at(party_index)
          box_name = @peer.pbBoxName(stored_box)
          pbDisplayPaused(_INTL("{1} fue enviado a la caja \"{2}\".", send_pkmn.name, box_name))
          # Rearrange all remembered properties of party Pokémon
          (party_index...party_size).each do |idx|
            if idx < party_size - 1
              @initialItems[0][idx] = @initialItems[0][idx + 1]
              $game_temp.party_levels_before_battle[idx] = $game_temp.party_levels_before_battle[idx + 1]
              $game_temp.party_critical_hits_dealt[idx] = $game_temp.party_critical_hits_dealt[idx + 1]
              $game_temp.party_direct_damage_taken[idx] = $game_temp.party_direct_damage_taken[idx + 1]
            else
              @initialItems[0][idx] = nil
              $game_temp.party_levels_before_battle[idx] = nil
              $game_temp.party_critical_hits_dealt[idx] = nil
              $game_temp.party_direct_damage_taken[idx] = nil
            end
          end
          break
        when 1   # Send to a Box
          break
        when 2   # See X's summary
          pbFadeOutIn do
            summary_scene = PokemonSummary_Scene.new
            summary_screen = PokemonSummaryScreen.new(summary_scene, true)
            summary_screen.pbStartScreen([pkmn], 0)
          end
        when 3   # Check party
          @scene.pbPartyScreen(0, true, 2)
        end
      end
    end
    # Store as normal (add to party if there's space, or send to a Box if not)
    stored_box = @peer.pbStorePokemon(pbPlayer, pkmn)
    if stored_box < 0
      pbDisplayPaused(_INTL("Se agregó a {1} al equipo.", pkmn.name))
      @initialItems[0][pbPlayer.party.length - 1] = pkmn.item_id if @initialItems
      return
    end
    # Messages saying the Pokémon was stored in a PC box
    box_name = @peer.pbBoxName(stored_box)
    pbDisplayPaused(_INTL("Se envió {1} a la caja \"{2}\"!", pkmn.name, box_name))
  end
end

class Battle
  include Battle::CatchAndStoreMixin
end

#===============================================================================
# Fixed long messages in battle not appearing/lingering properly, especially
# when making them appear faster by pressing Use/Back.
#===============================================================================
class Window_AdvancedTextPokemon < SpriteWindow_Base
  def skipAhead
    return if !busy?
    return if @textchars[@curchar] == "\n"
    resume
    if curcharSkip(true)
      visiblelines = (self.height - self.borderY) / @lineHeight
      if @textchars[@curchar] == "\n" && @linesdrawn >= visiblelines - 1
        @scroll_timer_start = System.uptime
      elsif @textchars[@curchar] == "\1"
        @pausing = true if @curchar < @numtextchars - 1
        self.startPause
        refresh
      end
    end
  end
end

class Battle::Scene
  def pbDisplayMessage(msg, brief = false)
    pbWaitMessage
    pbShowWindow(MESSAGE_BOX)
    cw = @sprites["messageWindow"]
    cw.setText(msg)
    PBDebug.log_message(msg)
    yielded = false
    timer_start = nil
    loop do
      pbUpdate(cw)
      if !cw.busy?
        if !yielded
          yield if block_given?   # For playing SE as soon as the message is all shown
          yielded = true
        end
        if brief
          # NOTE: A brief message lingers on-screen while other things happen. A
          #       regular message has to end before the game can continue.
          @briefMessage = true
          break
        end
        timer_start = System.uptime if !timer_start
        if System.uptime - timer_start >= MESSAGE_PAUSE_TIME   # Autoclose after 1 second
          cw.text = ""
          cw.visible = false
          break
        end
      end
      if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE) || @abortable
        if cw.busy?
          pbPlayDecisionSE if cw.pausing? && !@abortable
          cw.skipAhead
        elsif !@abortable
          cw.text = ""
          cw.visible = false
          break
        end
      end
    end
  end
  alias pbDisplay pbDisplayMessage

  def pbDisplayPausedMessage(msg)
    pbWaitMessage
    pbShowWindow(MESSAGE_BOX)
    cw = @sprites["messageWindow"]
    cw.text = msg + "\1"
    PBDebug.log_message(msg)
    yielded = false
    timer_start = nil
    loop do
      pbUpdate(cw)
      if !cw.busy?
        if !yielded
          yield if block_given?   # For playing SE as soon as the message is all shown
          yielded = true
        end
        if !@battleEnd
          timer_start = System.uptime if !timer_start
          if System.uptime - timer_start >= MESSAGE_PAUSE_TIME * 3   # Autoclose after 3 seconds
            cw.text = ""
            cw.visible = false
            break
          end
        end
      end
      if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE) || @abortable
        if cw.busy?
          pbPlayDecisionSE if cw.pausing? && !@abortable
          cw.skipAhead
        elsif !@abortable
          cw.text = ""
          pbPlayDecisionSE
          break
        end
      end
    end
  end
end

#===============================================================================
# Fixed abilities triggering twice when a Pokémon with Neutralizing Gas faints
# and is switched out.
#===============================================================================
class Battle::Battler
  def pbAbilitiesOnSwitchOut
    if abilityActive?
      Battle::AbilityEffects.triggerOnSwitchOut(self.ability, self, false)
    end
    # Reset form
    @battle.peer.pbOnLeavingBattle(@battle, @pokemon, @battle.usedInBattle[idxOwnSide][@index / 2])
    # Check for end of Neutralizing Gas/Unnerve
    if hasActiveAbility?(:NEUTRALIZINGGAS)
      # Treat self as fainted
      @hp = 0
      @fainted = true
      pbAbilitiesOnNeutralizingGasEnding
    elsif hasActiveAbility?([:UNNERVE, :ASONECHILLINGNEIGH, :ASONEGRIMNEIGH])
      # Treat self as fainted
      @hp = 0
      @fainted = true
      pbItemsOnUnnerveEnding
    end
    # Treat self as fainted
    @hp = 0
    @fainted = true
    # Check for end of primordial weather
    @battle.pbEndPrimordialWeather
  end
end

#===============================================================================
# Fixed the default battle weather being a primal weather causing an endless
# loop of that weather starting and ending.
#===============================================================================
class Battle
  alias __hotfixes__pbEndPrimordialWeather pbEndPrimordialWeather unless method_defined?(:__hotfixes__pbEndPrimordialWeather)

  def pbEndPrimordialWeather
    return if @field.weather == @field.defaultWeather
    __hotfixes__pbEndPrimordialWeather
  end
end

#===============================================================================
# Fixed the AI thinking it will take End of Round damage when it won't, and
# switching because of that.
#===============================================================================
Battle::AI::Handlers::ShouldSwitch.add(:significant_eor_damage,
  proc { |battler, reserves, ai, battle|
    eor_damage = battler.rough_end_of_round_damage
    next false if eor_damage <= 0
    # Switch if battler will take significant EOR damage
    if eor_damage >= battler.hp / 2 || eor_damage >= battler.totalhp / 4
      PBDebug.log_ai("#{battler.name} wants to switch because it will take a lot of EOR damage")
      next true
    end
    # Switch to remove certain effects that cause the battler EOR damage
    if ai.trainer.high_skill?
      if battler.effects[PBEffects::LeechSeed] >= 0 && ai.pbAIRandom(100) < 50
        PBDebug.log_ai("#{battler.name} wants to switch to get rid of its Leech Seed")
        next true
      end
      if battler.effects[PBEffects::Nightmare]
        PBDebug.log_ai("#{battler.name} wants to switch to get rid of its Nightmare")
        next true
      end
      if battler.effects[PBEffects::Curse]
        PBDebug.log_ai("#{battler.name} wants to switch to get rid of its Curse")
        next true
      end
      if battler.status == :POISON && battler.statusCount > 0 && !battler.has_active_ability?(:POISONHEAL)
        poison_damage = battler.totalhp / 8
        next_toxic_damage = battler.totalhp * (battler.effects[PBEffects::Toxic] + 1) / 16
        if (battler.hp <= next_toxic_damage && battler.hp > poison_damage) ||
           next_toxic_damage > poison_damage * 2
          PBDebug.log_ai("#{battler.name} wants to switch to reduce toxic to regular poisoning")
          next true
        end
      end
    end
    next false
  }
)

#===============================================================================
# Fixed the AI wanting to trigger a target's ability/item instead of not wanting
# to.
#===============================================================================
Battle::AI::Handlers::GeneralMoveAgainstTargetScore.add(:trigger_target_ability_or_item_upon_hit,
  proc { |score, move, user, target, ai, battle|
    if ai.trainer.high_skill? && move.damagingMove? && target.effects[PBEffects::Substitute] == 0
      if target.ability_active?
        if Battle::AbilityEffects::OnBeingHit[target.ability] ||
           (Battle::AbilityEffects::AfterMoveUseFromTarget[target.ability] &&
           (!user.has_active_ability?(:SHEERFORCE) || move.move.addlEffect == 0))
          old_score = score
          score -= 8
          PBDebug.log_score_change(score - old_score, "can trigger the target's ability")
        end
      end
      if target.battler.isSpecies?(:CRAMORANT) && target.ability == :GULPMISSILE &&
         target.battler.form > 0 && !target.effects[PBEffects::Transform]
        old_score = score
        score -= 8
        PBDebug.log_score_change(score - old_score, "can trigger the target's ability")
      end
      if target.item_active?
        if Battle::ItemEffects::OnBeingHit[target.item] ||
           (Battle::ItemEffects::AfterMoveUseFromTarget[target.item] &&
           (!user.has_active_ability?(:SHEERFORCE) || move.move.addlEffect == 0))
          old_score = score
          score -= 8
          PBDebug.log_score_change(score - old_score, "can trigger the target's item")
        end
      end
    end
    next score
  }
)

#===============================================================================
# Fixed a replacement Pokémon being invisible if its predecessor fainted and
# used the same sprite as it.
#===============================================================================
class Battle::Scene
  def pbFaintBattler(battler)
    @briefMessage = false
    old_height = @sprites["pokemon_#{battler.index}"].src_rect.height
    # Pokémon plays cry and drops down, data box disappears
    faintAnim   = Animation::BattlerFaint.new(@sprites, @viewport, battler.index, @battle)
    dataBoxAnim = Animation::DataBoxDisappear.new(@sprites, @viewport, battler.index)
    loop do
      faintAnim.update
      dataBoxAnim.update
      pbUpdate
      break if faintAnim.animDone? && dataBoxAnim.animDone?
    end
    faintAnim.dispose
    dataBoxAnim.dispose
    @sprites["pokemon_#{battler.index}"].src_rect.height = old_height
  end
end