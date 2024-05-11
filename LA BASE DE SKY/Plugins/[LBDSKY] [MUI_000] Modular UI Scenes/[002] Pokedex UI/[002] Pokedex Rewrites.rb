#===============================================================================
# Pokedex scene edits and additions to both visuals and function.
#===============================================================================
class PokemonPokedexInfo_Scene
  #-----------------------------------------------------------------------------
  # Used to set up all of the available pages to a species.
  #-----------------------------------------------------------------------------
  def setPages
    @page_list = []
    UIHandlers.each_available(:pokedex, @species, self) do |option, hash, name, suffix|
      next if !$player.owned?(@species) && hash["onlyOwned"]
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
    when :right  then offset = ((Graphics.width - xpos - 42) - (w * range.min)).round
    when :center then offset = ((Graphics.width - xpos - 42) / 2 - (range.min * (w / 2))).round
    end
    for i in startPage..endPage
      suffix = UIHandlers.get_info(:pokedex, @page_list[i], :suffix)
      path = "Graphics/UI/Pokedex/page_#{suffix}"
      iconRectY = (page == i) ? h : 0
      imagepos.push([path, xpos + offset + iconPos * (w + 4), ypos, 0, iconRectY, w, h])
      iconPos += 1
    end
    if PAGE_ICONS_SHOW_ARROWS
      path = "Graphics/UI/Pokedex/page_arrows"
      imagepos.push(
        [path, xpos + offset - 22, ypos + 2, 0, (page == 0) ? 0 : 24, 18, 24],
        [path, xpos + offset + iconPos * (w + 4), ypos + 2, 20, (page == @page_list.length - 1) ? 0 : 24, 18, 24]
      )
    end
    pbDrawImagePositions(@sprites["overlay"].bitmap, imagepos)
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten for the display of modular pages.
  #-----------------------------------------------------------------------------
  def drawPage(page)
    setPages
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    drawPageIcons
    @sprites["infosprite"].visible    = false
    @sprites["areamap"].visible       = false if @sprites["areamap"]
    @sprites["areahighlight"].visible = false if @sprites["areahighlight"]
    @sprites["areaoverlay"].visible   = false if @sprites["areaoverlay"]
    @sprites["formfront"].visible     = false if @sprites["formfront"]
    @sprites["formback"].visible      = false if @sprites["formback"]
    @sprites["formicon"].visible      = false if @sprites["formicon"]
    suffix = UIHandlers.get_info(:pokedex, @page_id, :suffix)
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_#{suffix}"))
    UIHandlers.call(:pokedex, @page_id, "layout", @species, self)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for toggling the visibility of certain sprites on each page.
  #-----------------------------------------------------------------------------
  alias modular_drawPageInfo drawPageInfo
  def drawPageInfo
    @sprites["infosprite"].visible    = true
    modular_drawPageInfo
  end
  
  alias modular_drawPageArea drawPageArea
  def drawPageArea
    @sprites["areamap"].visible       = true
    @sprites["areahighlight"].visible = true
    @sprites["areaoverlay"].visible   = true
    modular_drawPageArea
  end

  alias modular_drawPageForms drawPageForms
  def drawPageForms
    @sprites["formfront"].visible     = true
    @sprites["formback"].visible      = true
    @sprites["formicon"].visible      = true
    modular_drawPageForms
  end
  
  #-----------------------------------------------------------------------------
  # Edited to allow Pokedex pages to loop with RIGHT/LEFT.
  # You may now hold a directional key to continuously loop through pages.
  # The USE key now varies in function based on @page_id instead of @page number.
  #-----------------------------------------------------------------------------
  def pbScene
    Pokemon.play_cry(@species, @form)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::ACTION)
        pbSEStop
        Pokemon.play_cry(@species, @form) if @page == 1
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        ret = pbPageCustomUse(@page_id)
        if !ret
          case @page_id
          when :page_info
            pbPlayDecisionSE
            @show_battled_count = !@show_battled_count
            dorefresh = true
          when :page_forms
            if @available.length > 1
              pbPlayDecisionSE
              pbChooseForm
              dorefresh = true
            end
          end
        else
          dorefresh = true
        end
      elsif Input.repeat?(Input::UP)
        oldindex = @index
        pbGoToPrevious
        if @index != oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page == 1) ? Pokemon.play_cry(@species, @form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.repeat?(Input::DOWN)
        oldindex = @index
        pbGoToNext
        if @index != oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page == 1) ? Pokemon.play_cry(@species, @form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.repeat?(Input::LEFT)
        oldpage = @page
        numpages = @page_list.length
        @page -= 1
        @page = numpages if @page < 1
        @page = 1 if @page > numpages 
        if @page != oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.repeat?(Input::RIGHT)
        oldpage = @page
        numpages = @page_list.length
        @page += 1
        @page = numpages if @page < 1
        @page = 1 if @page > numpages
        if @page != oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      end
      drawPage(@page) if dorefresh
    end
    return @index
  end
end