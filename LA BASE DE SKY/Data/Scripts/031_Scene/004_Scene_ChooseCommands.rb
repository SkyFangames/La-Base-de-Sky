#===============================================================================
#
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # The player chooses a main command for a Pokémon.
  #-----------------------------------------------------------------------------

  def pbCommandMenu(idxBattler, firstAction)
    cmds = []
    # Commands for top row
    if @battle.pbCanShift?(idxBattler)
      cmds.push(:fight2)
      cmds.push(:shift)
    else
      cmds.push(:fight)
    end
    cmds.push(nil)
    # Commands for bottom row
    cmds.push(:bag)
    cmds.push(:call) if @battle.battlers[idxBattler].shadowPokemon?
    cmds.push(firstAction ? :run : :cancel)
    cmds.push(:pokemon)
    # Open the menu
    ret = pbCommandMenuEx(idxBattler, cmds)
    return ret
  end

  def pbCommandMenuEx(idxBattler, commands)
    pbShowWindow(COMMAND_BOX)
    cw = @sprites["commandWindow"]
    cw.set_index_and_commands(@lastCmd[idxBattler], commands)
    cw.active = true
    pbSelectBattler(idxBattler)
    ret = :cancel
    loop do
      pbUpdate(cw)
      # Actions
      if Input.trigger?(Input::USE)   # Confirm choice
        pbPlayDecisionSE
        ret = cw.command
        @lastCmd[idxBattler] = ret
        break
      elsif Input.trigger?(Input::BACK) && commands.include?(:cancel)   # Cancel
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::F9) && $DEBUG   # Debug menu
        pbPlayDecisionSE
        ret = :debug
        break
      end
    end
    cw.active = false
    return ret
  end

  def update_zygarde_move(battler, idxBattler, cw)
    # After toggling, change Zygarde's move based on the NEW registration state
    if battler.isSpecies?(:ZYGARDE) && [2, 3].include?(battler.form)
      newMode = (@battle.pbRegisteredMegaEvolution?(idxBattler)) ? 2 : 1
      battler.moves.each_with_index do |move, i|
        new_move_id = nil
        if newMode == 2 && move.id == :COREENFORCER
          new_move_id = :NIHILLIGHT
        elsif newMode == 1 && move.id == :NIHILLIGHT
          new_move_id = :COREENFORCER
        end
        
        if new_move_id
          # Store current PP values
          current_pp = move.pp
          
          # Create a new Pokemon::Move with the new ID
          pokemon_move = Pokemon::Move.new(new_move_id)
          pokemon_move.pp = current_pp
          # pokemon_move.total_pp = total_pp
          
          # Create a new Battle::Move from the Pokemon::Move
          new_battle_move = Battle::Move.from_pokemon_move(@battle, pokemon_move)
          
          # Replace the move in the battler's moves array
          battler.moves[i] = new_battle_move
        end
      end
      # Immediately refresh the UI to show the new move name
      cw.refresh
    end
  end

  #=============================================================================
  # The player chooses a move for a Pokémon to use
  #=============================================================================
  def pbFightMenu(idxBattler, megaEvoPossible = false)
    pbShowWindow(FIGHT_BOX)
    battler = @battle.battlers[idxBattler]
    cw = @sprites["fightWindow"]
    move_index = 0
    move_index = @lastMove[idxBattler] if battler.moves[@lastMove[idxBattler]]&.id
    cw.set_battler_and_index(battler, move_index)
    cw.mega_evolution_state = (megaEvoPossible) ? 1 : 0
    cw.active = true
    pbSelectBattler(idxBattler)
    need_full_refresh = false
    need_refresh = false
    loop do
      # Refresh view if necessary
      if need_full_refresh
        pbShowWindow(FIGHT_BOX)
        pbSelectBattler(idxBattler)
        need_full_refresh = false
        need_refresh = true
      end
      if need_refresh
        if megaEvoPossible
          cw.mega_evolution_state = (@battle.pbRegisteredMegaEvolution?(idxBattler)) ? 2 : 1
        end
        need_refresh = false
      end
      # General update
      pbUpdate(cw)
      # Actions
      if Input.trigger?(Input::USE)      # Confirm choice
        pbPlayDecisionSE
        break if yield cw.index
        need_full_refresh = true
        need_refresh = true
      elsif Input.trigger?(Input::BACK)   # Cancel fight menu
        pbPlayCancelSE
        break if yield -1
        need_refresh = true
      elsif Input.trigger?(Input::ACTION)   # Toggle Mega Evolution
        if cw.mega_evolution_state > 0
          pbPlayDecisionSE
          break if yield -2
          update_zygarde_move(battler, idxBattler, cw)
          need_refresh = true
        end
      # elsif Input.trigger?(Input::SPECIAL)   # Shift
      #   if cw.shiftMode > 0
      #     pbPlayDecisionSE
      #     break if yield -2
      #     need_refresh = true
      #   end
      end
    end
    cw.active = false
    @lastMove[idxBattler] = cw.index
  end

  #-----------------------------------------------------------------------------
  # Opens the party screen to choose a Pokémon to switch in (or just view its
  # summary screens).
  # mode: 0=Pokémon command, 1=choose a Pokémon to send to the Boxes, 2=view
  #       summaries only, 3=select a Pokémon
  #-----------------------------------------------------------------------------

  def pbPartyScreen(idxBattler, canCancel = false, mode = 0)
    # Fade out and hide all sprites
    visibleSprites = pbFadeOutAndHide(@sprites)
    # Get player's party
    partyPos = @battle.pbPartyOrder(idxBattler)
    partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
    modParty = @battle.pbPlayerDisplayParty(idxBattler)
    # Start party screen
    party_mode = :battle_choose_pokemon
    party_mode = :battle_choose_to_box if mode == 1
    party_mode = :battle_choose_to_revive if mode == 3
    screen = UI::Party.new(modParty, mode: party_mode)
    screen.choose_pokemon do |pkmn, party_index|
      next canCancel if party_index < 0
      # Choose a command for the selected Pokémon
      commands = {}
      commands[:switch_in] = _INTL("Cambiar") if mode == 0 && pkmn.able? &&
                                                                     (!@battle.rules[:cannot_switch] || !canCancel)
      commands[:send_to_boxes] = _INTL("Enviar al PC") if mode == 1
      commands[:select] = _INTL("Seleccionar") if mode == 3
      commands[:summary] = _INTL("Datos")
      commands[:cancel] = _INTL("Cancelar")
      choice = screen.pbShowCommands(_INTL("¿Qué hacer con {1}?", pkmn.name), commands)
      next canCancel if choice.nil?
      case choice
      when :select, :switch_in, :send_to_boxes
        real_party_index = -1
        partyPos.each_with_index do |pos, i|
          next if pos != party_index + partyStart
          real_party_index = i
          break
        end
        next true if yield real_party_index, screen
      when :summary
        screen.perform_action(:summary)
      end
      next false
    end
    # Fade back into battle screen
    pbFadeInAndShow(@sprites, visibleSprites)
  end

  #-----------------------------------------------------------------------------
  # Opens the Bag screen and chooses an item to use.
  #-----------------------------------------------------------------------------

  def pbItemMenu(idxBattler, _firstAction)
    # Fade out and hide all sprites
    visibleSprites = pbFadeOutAndHide(@sprites)
    # Set Bag starting positions
    oldLastPocket = $bag.last_viewed_pocket
    oldChoices    = $bag.last_pocket_selections.clone
    if @bagLastPocket
      $bag.last_viewed_pocket     = @bagLastPocket
      $bag.last_pocket_selections = @bagChoices
    else
      $bag.reset_last_selections
    end
    wasTargeting = false
    # Start Bag screen
    itemScene = PokemonBag_Scene.new
    itemScene.pbStartScene($bag, true,
                           proc { |item|
                             useType = GameData::Item.get(item).battle_use
                             next useType && useType > 0
                           }, false)
    # Loop while in Bag screen
    wasTargeting = false
    loop do
      # Select an item
      item = itemScene.pbChooseItem
      break if !item
      # Choose a command for the selected item
      item = GameData::Item.get(item)
      itemName = item.name
      useType = item.battle_use
      cmdUse = -1
      commands = []
      commands[cmdUse = commands.length] = _INTL("Usar") if useType && useType != 0
      commands[commands.length]          = _INTL("Cancelar")
      command = itemScene.pbShowCommands(_INTL("Has seleccionado {1}.", itemName), commands)
      next unless cmdUse >= 0 && command == cmdUse   # Use
      # Use types:
      # 0 = not usable in battle
      # 1 = use on Pokémon (lots of items, Blue Flute)
      # 2 = use on Pokémon's move (Ethers)
      # 3 = use on battler (X items, Persim Berry, Red/Yellow Flutes)
      # 4 = use on opposing battler (Poké Balls)
      # 5 = use no target (Poké Doll, Guard Spec., Poké Flute, Launcher items)
      case useType
      when 1, 2, 3   # Use on Pokémon/Pokémon's move/battler
        # Auto-choose the Pokémon/battler whose action is being decided if they
        # are the only available Pokémon/battler to use the item on
        case useType
        when 1   # Use on Pokémon
          if @battle.pbTeamLengthFromBattlerIndex(idxBattler) == 1
            break if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, itemScene
          end
        when 3   # Use on battler
          if @battle.pbPlayerBattlerCount == 1
            if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, bag_screen
              break
            else
              next
            end
          end
        end
        # Fade out and hide Bag screen
        itemScene.pbFadeOutScene
        # Get player's party
        party    = @battle.pbParty(idxBattler)
        partyPos = @battle.pbPartyOrder(idxBattler)
        partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
        modParty = @battle.pbPlayerDisplayParty(idxBattler)
        # Start party screen
        party_idx = -1
        party_screen = UI::Party.new(modParty, mode: :battle_use_item)
        party_screen.choose_pokemon do |pkmn, party_index|
          party_idx = party_index
          next true if party_index < 0
          # Use the item on the selected Pokémon
          real_party_index = -1
          partyPos.each_with_index do |pos, i|
            next if pos != party_index + partyStart
            real_party_index = i
            break
          end
          next false if real_party_index < 0
          next false if !pkmn || pkmn.egg?
          move_index = -1
          if useType == 2   # Use on Pokémon's move
            move_index = party_screen.choose_move(pkmn, _INTL("¿Restaurar qué movimiento?"))
            next false if move_index < 0
          end
          if yield item.id, useType, real_party_index, move_index, party_screen
            itemScene.pbFadeInScene
            next true
          end
          party_idx = -1
          next false
        end
        break if party_idx >= 0   # Item was used; close the Bag screen
        # Cancelled choosing a Pokémon; show the Bag screen again
        itemScene.pbFadeInScene
      when 4   # Use on opposing battler (Poké Balls)
        idxTarget = -1
        if @battle.pbOpposingBattlerCount(idxBattler) == 1
          @battle.allOtherSideBattlers(idxBattler).each { |b| idxTarget = b.index }
          break if yield item.id, useType, idxTarget, -1, itemScene
        else
          wasTargeting = true
          # Fade out and hide Bag screen
          itemScene.pbFadeOutScene
          # Fade in and show the battle screen, choosing a target
          tempVisibleSprites = visibleSprites.clone
          tempVisibleSprites["commandWindow"] = false
          tempVisibleSprites["targetWindow"]  = true
          idxTarget = pbChooseTarget(idxBattler, GameData::Target.get(:Foe), tempVisibleSprites)
          if idxTarget >= 0
            break if yield item.id, useType, idxTarget, -1, self
          end
          # Target invalid/cancelled choosing a target; show the Bag screen again
          wasTargeting = false
          pbFadeOutAndHide(@sprites)
          itemScene.pbFadeInScene
        end
      when 5   # Use with no target
        break if yield item.id, useType, idxBattler, -1, itemScene
      end
      next true
    end
    @bagLastPocket = $bag.last_viewed_pocket
    @bagChoices    = $bag.last_pocket_selections.clone
    $bag.last_viewed_pocket     = oldLastPocket
    $bag.last_pocket_selections = oldChoices
    # Close Bag screen
    itemScene.pbEndScene
    # Fade back into battle screen (if not already showing it)
    pbFadeInAndShow(@sprites, visibleSprites) if !wasTargeting
  end

  #-----------------------------------------------------------------------------
  # The player chooses a target battler for a move/item (non-single battles
  # only).
  #-----------------------------------------------------------------------------

  # Returns an array containing battler names to display when choosing a move's
  # target.
  # nil means can't select that position, "" means can select that position but
  # there is no battler there, otherwise is a battler's name.
  def pbCreateTargetTexts(idxBattler, target_data)
    texts = Array.new(@battle.battlers.length) do |i|
      next nil if !@battle.battlers[i]
      showName = false
      # NOTE: Targets listed here are ones with num_targets of 0, plus
      #       RandomNearFoe which should look like it targets the user. All
      #       other targets are handled by the "else" part.
      case target_data.id
      when :None, :User, :RandomNearFoe
        showName = (i == idxBattler)
      when :UserSide
        showName = !@battle.opposes?(i, idxBattler)
      when :FoeSide
        showName = @battle.opposes?(i, idxBattler)
      when :BothSides
        showName = true
      else
        showName = @battle.pbMoveCanTarget?(idxBattler, i, target_data)
      end
      next nil if !showName
      next "" if @battle.battlers[i].fainted? ||
                 @battle.battlers[i].effects[PBEffects::Commanding] >= 0
      next @battle.battlers[i].name
    end
    return texts
  end

  # Returns the initial position of the cursor when choosing a target for a move
  # in a non-single battle.
  def pbFirstTarget(idxBattler, target_data)
    case target_data.id
    when :NearAlly
      @battle.allSameSideBattlers(idxBattler).each do |b|
        next if b.index == idxBattler || !@battle.nearBattlers?(b, idxBattler)
        next if b.fainted?
        return b.index
      end
      @battle.allSameSideBattlers(idxBattler).each do |b|
        next if b.index == idxBattler || !@battle.nearBattlers?(b, idxBattler)
        return b.index
      end
    when :NearFoe, :NearOther
      indices = @battle.pbGetOpposingIndicesInOrder(idxBattler)
      indices.delete_if { |i| @battle.battlers[i]&.effects[PBEffects::Commanding] >= 0 }
      indices.each { |i| return i if @battle.nearBattlers?(i, idxBattler) && !@battle.battlers[i].fainted? }
      indices.each { |i| return i if @battle.nearBattlers?(i, idxBattler) }
    when :Foe, :Other
      indices = @battle.pbGetOpposingIndicesInOrder(idxBattler)
      indices.delete_if { |ind| @battle.battlers[ind]&.effects[PBEffects::Commanding] >= 0 }
      indices.each { |i| return i if !@battle.battlers[i].fainted? }
      return indices.first if !indices.empty?
    end
    return idxBattler   # Target the user initially
  end

  def pbChooseTarget(idxBattler, target_data, visibleSprites = nil)
    pbShowWindow(TARGET_BOX)
    cw = @sprites["targetWindow"]
    # Create an array of battler names (only valid targets are named)
    texts = pbCreateTargetTexts(idxBattler, target_data)
    # Determine mode based on target_data
    mode = (target_data.num_targets == 1) ? 0 : 1
    cw.set_texts_and_mode(texts, mode)
    cw.index = pbFirstTarget(idxBattler, target_data)
    pbSelectBattler((mode == 0) ? cw.index : texts, 2)   # Select initial battler/data box
    pbFadeInAndShow(@sprites, visibleSprites) if visibleSprites
    cw.active = true
    ret = -1
    loop do
      old_index = cw.index
      pbUpdate(cw)
      pbSelectBattler(cw.index, 2) if cw.index != old_index   # Select the new battler/data box
      if Input.trigger?(Input::USE)   # Confirm
        ret = cw.index
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::BACK)   # Cancel
        ret = -1
        pbPlayCancelSE
        break
      end
    end
    pbSelectBattler(-1)   # Deselect all battlers/data boxes
    cw.active = false
    return ret
  end

  #-----------------------------------------------------------------------------
  # Opens a Pokémon's summary screen to try to learn a new move.
  #-----------------------------------------------------------------------------

  # Called whenever a Pokémon should forget a move. It should return -1 if the
  # selection is canceled, or 0 to 3 to indicate the move to forget. It should
  # not allow HM moves to be forgotten.
  def pbForgetMove(pkmn, moveToLearn)
    ret = -1
    pbFadeOutIn do
      screen = UI::PokemonSummary.new([pkmn], 0, mode: :choose_move, new_move: moveToLearn)
      ret = screen.choose_move
    end
    return ret
  end

  #-----------------------------------------------------------------------------
  # Opens the nicknaming screen for a newly caught Pokémon.
  #-----------------------------------------------------------------------------

  def pbNameEntry(helpText, pkmn)
    return pbEnterPokemonName(helpText, 0, Pokemon::MAX_NAME_SIZE, "", pkmn)
  end

  #-----------------------------------------------------------------------------
  # Shows the Pokédex entry screen for a newly caught Pokémon.
  #-----------------------------------------------------------------------------

  def pbShowPokedex(species)
    pbFadeOutIn do
      scene = PokemonPokedexInfo_Scene.new
      screen = PokemonPokedexInfoScreen.new(scene)
      screen.pbDexEntry(species)
    end
  end
end

