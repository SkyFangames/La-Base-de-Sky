#===============================================================================
# Adds/edits various Summary utilities.
#===============================================================================
class PokemonSummary_Scene
  #-----------------------------------------------------------------------------
  # Used to set up all of the available pages to the Pokemon.
  #-----------------------------------------------------------------------------
  def setPages
    @page_list = []
    UIHandlers.each_available(:summary, @pokemon, self) do |option, hash, name, suffix|
      next if !@pokemon.egg? && hash["onlyEggs"]
      next if @pokemon.egg? && !hash["onlyEggs"]
      @page_list.push(option)
    end
    if @page_list[@page - 1]
      @page_id = @page_list[@page - 1]
    else
      @page_id = @page_list.first
      @page = 1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Used to draw the relevant page icons in the heading of each page.
  #-----------------------------------------------------------------------------
  def drawPageIcons
    setPages if !@page_list || @page_list.empty?
    iconPos    = 0
    imagepos   = []
    xpos, ypos = PAGE_ICONS_POSITION
    w, h       = PAGE_ICON_SIZE
    size       = MAX_PAGE_ICONS - 1
    range      = [@page_list.length, MAX_PAGE_ICONS]
    page       = @page_list.find_index(@page_id)
    startPage  = (page > size) ? page - size : 0
    endPage    = [startPage + size, @page_list.length - 1].min
    case PAGE_ICONS_ALIGNMENT
    when :left   then offset = 0
    when :right  then offset = (Graphics.width - xpos - 6) - (w * range.min)
    when :center then offset = (Graphics.width - xpos - 6) / 2 - (range.min * (w / 2))
    end
    for i in startPage..endPage
      suffix = UIHandlers.get_info(:summary, @page_list[i], :suffix)
      path = "Graphics/UI/Summary/page_#{suffix}"
      iconRectX = (page == i) ? w : 0
      imagepos.push([path, xpos + offset + (iconPos * w), ypos, iconRectX, 0, w, h])
      iconPos += 1
    end
    if PAGE_ICONS_SHOW_ARROWS
      path = "Graphics/UI/Summary/page_arrows"
      if page > size
        imagepos.push([path, xpos + offset - 14, ypos + 20, 0, 0, 12, 20])
      end
      if page <= size && size < @page_list.length
        imagepos.push([path, xpos + offset + (iconPos * w) + 2, ypos + 20, 14, 0, 12, 20])
      end
    end
    pbDrawImagePositions(@sprites["overlay"].bitmap, imagepos)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to set up the correct page while forgetting a move.
  #-----------------------------------------------------------------------------
  alias modular_pbStartForgetScene pbStartForgetScene
  def pbStartForgetScene(party, partyindex, move_to_learn)
    @page_id = :page_moves
    @page_list = [:page_moves]
    modular_pbStartForgetScene(party, partyindex, move_to_learn)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for redrawing page icons while viewing moves.
  #-----------------------------------------------------------------------------
  alias modular_drawPageFourSelecting drawPageFourSelecting
  def drawPageFourSelecting(move_to_learn)
    modular_drawPageFourSelecting(move_to_learn)
    drawPageIcons if !move_to_learn
  end
  
  #-----------------------------------------------------------------------------
  # Edited to add missing sound effects while selecting a move to forget.
  #-----------------------------------------------------------------------------
  def pbChooseMoveToForget(move_to_learn)
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    selmove = 0
    maxmove = (new_move) ? Pokemon::MAX_MOVES : Pokemon::MAX_MOVES - 1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        selmove = Pokemon::MAX_MOVES
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::ACTION)
        newScene = PokemonSummary_Scene.new
        newScreen = PokemonSummaryScreen.new(newScene)
        newScreen.pbStartScreen(@party, @partyindex, 3)
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove < 0
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = @pokemon.numMoves - 1
        end
        @sprites["movesel"].index = selmove
        pbPlayCursorSE
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove > maxmove
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = (new_move) ? maxmove : 0
        end
        @sprites["movesel"].index = selmove
        pbPlayCursorSE
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      end
    end
    return (selmove == Pokemon::MAX_MOVES) ? -1 : selmove
  end
  
  #-----------------------------------------------------------------------------
  # Edited to allow the party to loop with UP/DOWN.
  #-----------------------------------------------------------------------------
  def pbGoToPrevious
    newindex = @partyindex
    loop do
      newindex -= 1
      newindex = @party.length - 1 if newindex < 0
      if @party[newindex]
        @partyindex = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @partyindex
    loop do
      newindex += 1
      newindex = 0 if newindex > @party.length - 1
      if @party[newindex]
        @partyindex = newindex
        break
      end
    end
  end
end


#===============================================================================
# Used to check if a compatible TM exists in the bag for the "Use TM's" option.
#===============================================================================
class PokemonBag
  def has_compatible_tm?(pokemon)
    GameData::Item.each do |itm|
      move = GameData::Item.get(itm).move
      return true if move && pokemon.compatible_with_move?(move) && !pokemon.hasMove?(move)
    end
    return false
  end
end