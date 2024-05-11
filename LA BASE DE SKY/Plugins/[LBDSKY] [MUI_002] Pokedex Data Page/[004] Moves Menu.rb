#===============================================================================
# Relacionado con el menú de movimientos dentro de la página de datos.
#===============================================================================
class PokemonPokedexInfo_Scene
  #-----------------------------------------------------------------------------
  # Utilidad para generar listas de movimientos aprendibles por una especie.
  #-----------------------------------------------------------------------------
  def pbGenerateMoveList
    @moveCommands.clear
    @moveList.clear
    species_data = GameData::Species.get_species_form(@species, @form)
    case @moveListIndex
    when 0  # Level-up moves
      species_data.moves.each do |m|
        @moveCommands.push(GameData::Move.get(m[1]).name)
        @moveList.push(m)
      end
    when 1  # Tutor moves
      species_data.tutor_moves.each do |m| 
        @moveCommands.push(GameData::Move.get(m).name)
        @moveList.push(m)
      end
      @moveCommands.uniq!
      @moveList.uniq!
    when 2  # Egg moves
      species_data.get_egg_moves.each do |m| 
        @moveCommands.push(GameData::Move.get(m).name)
        @moveList.push(m)
      end
      @moveCommands.uniq!
      @moveList.uniq!
    end
    @sprites["movecmds"].commands = @moveCommands
    @sprites["movecmds"].index = 0
  end
  
  #-----------------------------------------------------------------------------
  # Controla la navegación de la interfaz de la lista de movimientos.
  #-----------------------------------------------------------------------------
  def pbChooseMove
    oldcmd = -1
    pbResetFamilyIcons
    pbPlayDecisionSE
    @moveListIndex = 0
    pbGenerateMoveList
    pbDrawMoveList
    pbActivateWindow(@sprites, "movecmds") do
      loop do
        oldcmd = @sprites["movecmds"].index
        Graphics.update
        Input.update
        pbUpdate
        if Input.trigger?(Input::LEFT)
          @moveListIndex -= 1
          @moveListIndex = 2 if @moveListIndex < 0
          pbGenerateMoveList
          pbPlayCursorSE
          pbDrawMoveList
        elsif Input.trigger?(Input::RIGHT)
          @moveListIndex += 1
          @moveListIndex = 0 if @moveListIndex > 2
          pbGenerateMoveList
          pbPlayCursorSE
          pbDrawMoveList
        elsif Input.trigger?(Input::BACK)
          @moveListIndex = 0
          @sprites["movecmds"].index = 0
          @sprites["leftarrow"].visible = false
          @sprites["rightarrow"].visible = false
          pbPlayCancelSE
          drawPage(@page)
          pbDrawDataNotes
          break
        elsif Input.trigger?(Input::UP)
          @sprites["movecmds"].index -= 1 if @sprites["movecmds"].index > 0
        elsif Input.trigger?(Input::DOWN)
          @sprites["movecmds"].index += 1 if @sprites["movecmds"].index < @moveCommands.length - 1
        end
        if @sprites["movecmds"].index != oldcmd
          pbDrawMoveList
        end
      end
    end
    pbDeactivateWindows(@sprites)
  end
  
  #-----------------------------------------------------------------------------
  # Usado para dibujar la interfaz de la lista de movimientos.
  #-----------------------------------------------------------------------------
  def pbDrawMoveList
    @sprites["familyicon0"].x = 320
    @sprites["familyicon0"].y = 80
    @sprites["familyicon0"].visible = true
    @sprites["itemicon"].item = nil
    @sprites["leftarrow"].visible = true
    @sprites["rightarrow"].visible = true
    path = Settings::POKEDEX_DATA_PAGE_GRAPHICS_PATH
    @sprites["background"].setBitmap(_INTL(path + "bg_moves"))
    @sprites["data_overlay"].bitmap.clear
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    drawPageIcons
    base     = Color.new(248, 248, 248)
    shadow   = Color.new(72, 72, 72)
    base2    = Color.new(88, 88, 80)
    shadow2  = Color.new(168, 184, 184)
    imagepos = []
    textpos  = []
    yPos     = 90
    species_data = GameData::Species.get_species_form(@species, @form)
    species_data.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      type_x = (species_data.types.length == 1) ? 400 : 366 + (70 * i)
      overlay.blt(type_x, 66, @typebitmap2.bitmap, type_rect)
    end
    case @moveListIndex
    when 0 then title = _INTL("Nivel")
    when 1 then title = _INTL("MT/TUTOR")
    when 2 then title = _INTL("Huevo/Crianza")
    end
    textpos.push([title, 130, 51, :center, base, shadow, :outline])
    #---------------------------------------------------------------------------
    # Dibuja la lista de movimientos.
    #---------------------------------------------------------------------------
    4.times do |i|
      moveobject = @moveList[@sprites["movecmds"].top_item + i]
      next if moveobject.nil?
      if moveobject.is_a?(Array)
        moveLevel = moveobject[0]
        moveData = GameData::Move.get(moveobject[1])
      else
        moveData = GameData::Move.get(moveobject)
      end
      type_number = GameData::Type.get(moveData.type).icon_position
      imagepos.push([_INTL("Graphics/UI/types"), 56, yPos + 24, 0, type_number * 28, 64, 28])
      textpos.push([moveData.name, 58, yPos, :left, base, shadow, :outline],
                   [_INTL("PP"), 144, yPos + 30, :left, base2, shadow2],
                   [moveData.total_pp > 0 ? moveData.total_pp.to_s : "--", 230, yPos + 30, :right, base2, shadow2])
      case @moveListIndex
      #-------------------------------------------------------------------------
      when 0  # Movimientos por nivel
      #-------------------------------------------------------------------------
        if moveLevel == 0
          textpos.push(["Ev.", 29, yPos + 16, :center, base, shadow, :outline])
        elsif moveLevel == 1 || moveLevel < 0
          imagepos.push([_INTL("Graphics/UI/Party/overlay_lv"), 17, yPos + 4])
          textpos.push(["--", 29, yPos + 26, :center, base, shadow, :outline])
        else moveLevel > 0
          imagepos.push([_INTL("Graphics/UI/Party/overlay_lv"), 17, yPos + 4])
          textpos.push([moveLevel.to_s, (moveLevel < 100) ? 29 : 28, yPos + 26, :center, base, shadow, :outline])
        end
      #-------------------------------------------------------------------------
      when 1  # Movimientos por MT/Tutor
      #-------------------------------------------------------------------------
        machine = "??"
        GameData::Item.each do |item|
          next if !item.is_machine?
          next if item.move != moveData.id
          next if !$bag.has?(item.id)
          machine = item.id
        end
        case machine
        when Symbol
          name = GameData::Item.get(machine).name
          textpos.push([name[0..1], 29, yPos + 4, :center, base, shadow, :outline],
                       [name[2..machine.length], (machine.length < 5) ? 29 : 28, yPos + 28, :center, base, shadow, :outline])
        else
          textpos.push([machine, 29, yPos + 17, :center, base, shadow, :outline])
        end
      #-------------------------------------------------------------------------
      when 2  # Movimientos Huevo
      #-------------------------------------------------------------------------
        imagepos.push([_INTL("Graphics/Pokemon/Eggs/000_icon"), -4, yPos - 14, 0, 0, 64, 64])
      end
      yPos += 64
    end
    #---------------------------------------------------------------------------
    # Dibuja la información del movimiento seleccionado.
    #---------------------------------------------------------------------------
    if !@moveCommands.empty?
      cursorY = 80 + ((@sprites["movecmds"].index - @sprites["movecmds"].top_item) * 64)
      imagepos.push([path + "page_cursor", 0, cursorY, 0, 0, 258, 70])
      selMoveID = (@moveListIndex == 0) ? @moveList[@sprites["movecmds"].index][1] : @moveList[@sprites["movecmds"].index]
      selMoveData = GameData::Move.get(selMoveID)
      power = selMoveData.power
      category = selMoveData.category
      accuracy = selMoveData.accuracy
      movecount = (@sprites["movecmds"].index + 1).to_s + "/" + @moveCommands.length.to_s
      textpos.push(
        [_INTL("CATEGORÍA"), 344, 116, :center, base, shadow, :outline],
        [_INTL("POTENCIA"), 344, 150, :center, base, shadow, :outline],
        [power <= 1 ? power == 1 ? "???" : "---" : power.to_s, 468, 150, :center, base2, shadow2],
        [_INTL("PRECISIÓN"), 344, 184, :center, base, shadow, :outline],
        [accuracy == 0 ? "---" : "#{accuracy}%", 468, 184, :center, base2, shadow2],
        [movecount, 50, 357, :center, base, shadow, :outline]
      )
      imagepos.push(["Graphics/UI/category", 436, 110, 0, category * 28, 64, 28])
      if @sprites["movecmds"].index < @moveCommands.length - 1
        imagepos.push([path + "page_cursor", 100, 350, 0, 70, 76, 32])
      end
      if @sprites["movecmds"].index > 0
        imagepos.push([path + "page_cursor", 178, 350, 76, 70, 76, 32])
      end
      drawTextEx(overlay, 272, 216, 230, 5, selMoveData.description, base2, shadow2)
    end
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
  end
end