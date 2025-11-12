#===============================================================================
# Poke Ball UI.
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Toggles the visibility of the Poke Ball selection menu.
  #-----------------------------------------------------------------------------
  def pbToggleBallInfo(idxBattler)
    return false if pbInSafari?
    return false if !@battle.pbCanUsePokeBall?(idxBattler)
    return false if $bag.get_ball_pocket < 0
    return false if ballPocket < 0
    pbHideInfoUI if @enhancedUIToggle != :ball
    @enhancedUIToggle = (@enhancedUIToggle.nil?) ? :ball : nil
    (@enhancedUIToggle) ? pbSEPlay("GUI party switch") : pbPlayCloseMenuSE
    @sprites["enhancedUI"].visible = !@enhancedUIToggle.nil?
    return pbSelectBallInfo(idxBattler, ballPocket)
  end
  
  #-----------------------------------------------------------------------------
  # Updates a Poke Ball icon.
  #-----------------------------------------------------------------------------
  def pbUpdateBallIcon(index, item, blank = false)
    @sprites["ball_icon#{index}"].item = item
    @sprites["ball_icon#{index}"].visible = true
    if blank
      @sprites["ball_icon#{index}"].blankzero = true
      pbShowOutline("ball_icon#{index}", false)
    else
      @sprites["ball_icon#{index}"].blankzero = false
      pbUpdateOutline("ball_icon#{index}", item)
      pbShowOutline("ball_icon#{index}", true)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws the Poke Ball menu.
  #-----------------------------------------------------------------------------
  def pbUpdateBallSelection(items, index, showDesc = false)
    @enhancedUIOverlay.clear
    return if @enhancedUIToggle != :ball
    ypos = @sprites["messageBox"].y - 128
    imagePos = [[@path + "pokeball_bg", 0, ypos]]
    imagePos.push([@path + "pokeball_desc", 0, ypos - 69]) if showDesc
    textY = (showDesc) ? ypos - 55 : ypos + 14
    action = (showDesc) ? _INTL("Z: Esconder") : _INTL("Z: Detalles")
    item = GameData::Item.try_get(items[index][0])
    name = (item) ? _INTL("{1}", item.name) : _INTL("Volver")
    desc = (item) ? item.description : _INTL("Volver al menú.")
    textPos = [
      [_INTL("C: Usar"), 46, textY, :center, BASE_LIGHT],
      [action, Graphics.width - 56, textY, :center, BASE_LIGHT],
      [name, Graphics.width / 2, textY, :center, BASE_LIGHT, SHADOW_LIGHT, :outline]
    ]
    ballY = @sprites["messageBox"].y - 25
    range = ((index - 2)..(index + 2)).to_a
    range.each_with_index do |pos, i|
      if pos < 0 || pos > items.length - 1
        pbUpdateBallIcon(i, nil, true)
      else
        try_item = items[pos][0]
        pbUpdateBallIcon(i, try_item)
        if try_item
          x = @sprites["ball_icon#{i}"].x
          x += 2 if i == index
          text_colors = (pos == index) ? [BASE_LIGHT, SHADOW_LIGHT, :outline] : [BASE_DARK, SHADOW_DARK]
          textPos.push([items[pos][1].to_s, x, ballY, :center, *text_colors])
        end
      end
    end
    pbDrawImagePositions(@enhancedUIOverlay, imagePos)
    pbDrawTextPositions(@enhancedUIOverlay, textPos)
    drawTextEx(@enhancedUIOverlay, 10, ypos - 21, Graphics.width - 10, 2, 
      desc, BASE_DARK, SHADOW_DARK) if showDesc
  end
  
  #-----------------------------------------------------------------------------
  # Handles the controls for the Poke Ball menu.
  #-----------------------------------------------------------------------------
  def pbSelectBallInfo(idxBattler, pocket)
    return false if @enhancedUIToggle != :ball
    pbHideUIPrompt
    useBall = false
    showDesc = false
    items = $bag.pockets[pocket].clone
    items.push([nil])
    items.unshift([nil])
    index = $bag.last_viewed_index(pocket) + 1
    maxIdx = items.length - 1
    battler = @battle.battlers[idxBattler].pbDirectOpposing(true)
    pbUpdateBallSelection(items, index, showDesc)
    @sprites["leftarrow"].x = 174
    @sprites["leftarrow"].y = @sprites["ball_icon0"].y
    @sprites["rightarrow"].x = 298
    @sprites["rightarrow"].y = @sprites["ball_icon0"].y
    loop do
      pbUpdate
      pbUpdateInfoSprites
      dorefresh = false
      item = items[index][0]
      @sprites["leftarrow"].visible = index > 0
      @sprites["rightarrow"].visible = index < maxIdx
      if Input.trigger?(Input::USE)
        if !item
          pbPlayCloseMenuSE
          break
        end
        pbPlayDecisionSE
        if ItemHandlers.triggerCanUseInBattle(item, battler.pokemon, battler, nil, true, @battle, self)
          useBall = @battle.pbRegisterItem(idxBattler, item, battler.index)
          $bag.set_last_viewed_index(pocket, index - 1)
          break
        end
        pbShowWindow(COMMAND_BOX)
      elsif Input.trigger?(Input::ACTION)
        showDesc = !showDesc
        pbPlayDecisionSE
        dorefresh = true
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.repeat?(Input::LEFT)
        index -= 1
        index = maxIdx if index < 0
        pbPlayCursorSE
        dorefresh = true
      elsif Input.repeat?(Input::RIGHT) 
        index += 1
        index = 0 if index > maxIdx
        pbPlayCursorSE
        dorefresh = true
      elsif Input.trigger?(Input::JUMPUP) && index > 0
        index = 0
        pbPlayCursorSE
        dorefresh = true
      elsif Input.trigger?(Input::JUMPDOWN) && index < maxIdx
        index = maxIdx
        pbPlayCursorSE
        dorefresh = true
      end
      if dorefresh
        pbUpdateBallSelection(items, index, showDesc)
      end
    end
    pbHideInfoUI
    @sprites["leftarrow"].visible = false
    @sprites["rightarrow"].visible = false
    pbRefreshUIPrompt(idxBattler) if !useBall
    return useBall
  end
end


#===============================================================================
# Battle utilities.
#===============================================================================
class Battle
  #-----------------------------------------------------------------------------
  # Utility for checking if Poke Balls are usable.
  #-----------------------------------------------------------------------------
  def pbCanUsePokeBall?(idxBattler)
    return false if pbInSafari? || pbInBugContest?
    return false if !@internalBattle
    return false if @disablePokeBalls
    return false if trainerBattle?
    return false if $bag.get_ball_pocket < 0
    idxBattler = idxBattler.index if idxBattler.respond_to?("index")
    return false if !pbOwnedByPlayer?(idxBattler || 0)
    return false if pbOpposingBattlerCount(idxBattler || 0) > 1
    allSameSideBattlers(idxBattler || 0).each do |b|
      return false if @choices[b.index][0] != :None
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to end the command phase if a Poke Ball was selected.
  #-----------------------------------------------------------------------------
  alias enhanced_pbItemMenu pbItemMenu
  def pbItemMenu(idxBattler, firstAction)
    return true if @choices[idxBattler][0] == :UseItem
    return enhanced_pbItemMenu(idxBattler, firstAction)
  end
end


#===============================================================================
# Bag utilities.
#===============================================================================
class PokemonBag
  def get_ball_pocket
    @pockets.each_with_index do |p, i|
      next if p.empty?
      next if !GameData::Item.get(p[0][0]).is_poke_ball?
      return i
    end
    return -1
  end
end