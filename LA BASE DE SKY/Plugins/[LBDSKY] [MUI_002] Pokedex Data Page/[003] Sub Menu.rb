#===============================================================================
# Used for drawing entire pages worth of species icon sprites at a time.
#===============================================================================
class PokemonDataPageSprite < Sprite
  PAGE_SIZE = 12  # The number of species icons per page.
  ROW_SIZE  = 6   # The number of species icons per row.
  ICON_GAP  = 72  # The pixel gap between each species icon.
  PAGE_X    = 43  # The x coordinates of where the icons are placed.
  PAGE_Y    = 26  # The y coordinates of where the icons are placed.

  def initialize(list, page, viewport = nil)
    super(viewport)
    @pokemonsprites = []
    xpos = PAGE_X
    ypos = PAGE_Y
    offset = 1
    list = [list] * PAGE_SIZE if !list.is_a?(Array)
    PAGE_SIZE.times do |i|
      index = PAGE_SIZE * page + i
      break if index > list.length - 1
      pokemon = list[index]
      offset += 1 if i >= ROW_SIZE * offset
      @pokemonsprites[i] = PokemonSpeciesIconSprite.new(pokemon, viewport)
      @pokemonsprites[i].viewport = self.viewport
      xpos = PAGE_X if xpos >= ROW_SIZE * ICON_GAP
      xpos += ICON_GAP
      @pokemonsprites[i].x = xpos - ICON_GAP
      @pokemonsprites[i].y = ypos + ICON_GAP * offset
    end
    @contents = BitmapWrapper.new(44, 100)
    self.bitmap = @contents
    self.x = 0
    self.y = 0
  end
  
  def dispose
    if !disposed?
      PAGE_SIZE.times do |i|
        @pokemonsprites[i]&.dispose
      end
      @contents.dispose
      super
    end
  end
  
  def visible=(value)
    super
    PAGE_SIZE.times do |i|
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].visible = value
      end
    end
  end
  
  def setPokemon(list, page, gender = 0)
    PAGE_SIZE.times do |i|
      index = PAGE_SIZE * page + i
      pokemon = list[index]
      species = GameData::Species.try_get(pokemon)
      if species
        sp_form = sp_gender = 0
        if species.form > 0
          base = GameData::Species.icon_filename(species.species)
          test = GameData::Species.icon_filename(species.species, species.form)
          sp_form = species.form if base != test
        end
        if gender > 0
          base = GameData::Species.icon_filename(species.species, sp_form)
          test = GameData::Species.icon_filename(species.species, sp_form, gender)
          sp_gender = gender if base != test
        end
        @pokemonsprites[i].pbSetParams(species.species, sp_gender, sp_form)
        @pokemonsprites[i].visible = true
        if !$player.owned?(pokemon)
          @pokemonsprites[i].tone = Tone.new(-255,-255,-255,0)
        else
          @pokemonsprites[i].tone = Tone.new(0,0,0,0)
        end
      elsif pokemon == :RETURN
        @pokemonsprites[i].pbSetParams(pokemon, 0, 0)
        @pokemonsprites[i].tone = Tone.new(0,0,0,0)
        @pokemonsprites[i].visible = true
      else
        @pokemonsprites[i].visible = false
      end
    end
  end
  
  def getPokemon(index)
    return @pokemonsprites[index]
  end
  
  def getPageSize(list, page)
    count = 0
    PAGE_SIZE.times do |i|
      index = PAGE_SIZE * page + i
      break if index > list.length - 1
      count += 1 if list[index]
    end
    return count
  end
  
  def update
    @pokemonsprites.each { |s| s.update }
  end
end


#===============================================================================
# Handles the various Data Page sub menus.
#===============================================================================
class PokemonPokedexInfo_Scene
  #-----------------------------------------------------------------------------
  # Controls for navigating sub menus that display pages of species icons.
  #-----------------------------------------------------------------------------
  def pbChooseSpeciesDataList(cursor = nil)
    cursor = @cursor if !cursor
    list = pbFilterDataList(cursor, @data_hash[cursor].clone)
    return if list.empty?
    list.uniq!
    newEntry  = -1
    row_size  = PokemonDataPageSprite::ROW_SIZE
    page_size = PokemonDataPageSprite::PAGE_SIZE
    page      = 0
    index     = 0
    maxpage   = ((list.length - 1) / page_size).floor
    pbSEPlay("GUI storage show party panel")
    pbDrawSpeciesDataList(list, index, page, maxpage, cursor)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      count = 0
      sound = 0
      dorefresh = false
      #-------------------------------------------------------------------------
      if Input.repeat?(Input::UP)
        if index >= row_size
          index -= row_size
          dorefresh = true
        else
          if page > 0
            page -= 1
            index += row_size
            dorefresh = true
          elsif maxpage > 0
            page = maxpage
            count = @sprites["pokelist"].getPageSize(list, page) - 1
            if index + row_size <= count
              index += row_size
            elsif index > count
              index = count
            end
            dorefresh = true
          end
        end
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::DOWN)
        if index < row_size
          count = @sprites["pokelist"].getPageSize(list, page) - 1
          if count < index + row_size
            if page == maxpage && maxpage > 0
              page = 0
              index -= row_size if index >= row_size
              dorefresh = true
            end
          else
            index += row_size
            dorefresh = true
          end
        else
          if page < maxpage
            page += 1
            count = @sprites["pokelist"].getPageSize(list, page) - 1
            index -= row_size
            index = count if index > count
            dorefresh = true
          elsif maxpage > 0
            page = 0
            index -= row_size if index >= row_size
            dorefresh = true
          end
        end
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::LEFT)
        if index > 0
          index -= 1
          dorefresh = true
        else
          if page > 0
            page -= 1
            count = @sprites["pokelist"].getPageSize(list, page) - 1
            index = count
            dorefresh = true
          else
            page = maxpage
            count = @sprites["pokelist"].getPageSize(list, page) - 1
            next if count == 0 && page == 0
            index = count
            dorefresh = true
          end
        end
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::RIGHT)
        count = @sprites["pokelist"].getPageSize(list, page) - 1
        next if count == 0 && page == 0
        if index < count
          index += 1
          dorefresh = true
        else
          if page < maxpage
            page += 1
            index = 0
            dorefresh = true
          else
            page = 0
            index = 0
            dorefresh = true
          end
        end
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::JUMPUP)
        if page > 0
          page -= 1
          index = 0
          sound = 1
          dorefresh = true
        end
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::JUMPDOWN)
        if page < maxpage
          page += 1
          index = 0
          sound = 1
          dorefresh = true
        end
      #-------------------------------------------------------------------------
      elsif Input.trigger?(Input::USE)
        page_size = PokemonDataPageSprite::PAGE_SIZE
        idxList = (page * page_size) + index
        sp = GameData::Species.try_get(list[idxList])
        if !sp
          pbSEPlay("GUI storage hide party panel")
          @sprites["pokelist"].visible = false
          if @viewingMoves
            pbDrawMoveList
          else
            drawPage(@page)
            pbDrawDataNotes
          end
          break
        end
        if sp.form > 0 && sp.form_name
          if sp.form_name.include?(sp.name)
            full_name = _INTL("{1}", sp.form_name)
          else
            full_name = _INTL("{2} {1}", sp.form_name, sp.name)
          end
        else
          full_name = _INTL("{1}", sp.name)
        end
        if $player.owned?(sp) && pbConfirmMessage(_INTL("¿Saltar a la Página de la Pokédex de <c2=043c3aff>{1}</c2>?", full_name))
          @dexlist.each_with_index do |dex, i|
            next if dex[:species] != sp.species
            newEntry = i
            break
          end
          @cursor = :general
          @moveListIndex = 0
          @viewingMoves = false
          @sprites["movecmds"].index = 0
          @sprites["leftarrow"].visible = false
          @sprites["rightarrow"].visible = false
          @sprites["pokelist"].visible = false
          @sprites["data_overlay"].bitmap.clear
          @index = newEntry
          gender = @sprites["pokelist"].getPokemon(index).gender
          $player.pokedex.set_last_form_seen(sp.species, gender, sp.form)
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEPlay("GUI naming tab swap start")
          @forceRefresh = true
          break
        end
      #-------------------------------------------------------------------------
      elsif Input.trigger?(Input::ACTION)
        next if !@viewingMoves
        next if @data_hash[:egg].empty?
        move = GameData::Move.try_get(pbCurrentMoveID)
        next if !move
        case cursor
        when :move
          msg = _INTL("¿Ver solo las <c2=043c3aff>especies compatibles</c2> que conocen <c2=65467b14>{1}</c2>?", move.name)
          if pbConfirmMessage(msg)
            try_list = pbFilterDataList(:egg, @data_hash[:egg])
            if try_list.empty?
              pbMessage(_INTL("No se han encontrado especies compatibles."))
            else
              cursor = :egg
              dorefresh = true
            end
          end
        when :egg
          msg = _INTL("¿Ver <c2=043c3aff>todas las especies</c2> que conocen <c2=65467b14>{1}</c2>?", move.name)
          if pbConfirmMessage(msg)
            try_list = pbFilterDataList(:move, @data_hash[:move])
            if try_list.empty?
              pbMessage(_INTL("No se ha encontrado ninguna especie."))
            else
              cursor = :move
              dorefresh = true
            end
          end
        end
        if dorefresh
          sound = 1
          index = page = 0
          list = try_list
          maxpage = ((list.length - 1) / page_size).floor
        end
      #-------------------------------------------------------------------------
      elsif Input.trigger?(Input::BACK)
        pbSEPlay("GUI storage hide party panel")
        @sprites["pokelist"].visible = false
        if @viewingMoves
          pbDrawMoveList
        else
          drawPage(@page)
          pbDrawDataNotes
        end
        break
      end
      #-------------------------------------------------------------------------
      if dorefresh
        (sound == 0) ? pbPlayCursorSE : pbSEPlay("GUI naming tab swap start")
        pbDrawSpeciesDataList(list, index, page, maxpage, cursor)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Filters species list for specific areas of compatibility.
  #-----------------------------------------------------------------------------
  def pbFilterDataList(cursor, list)
    species = GameData::Species.get_species_form(@species, @form)
    #---------------------------------------------------------------------------
    # When viewing move lists.
    #---------------------------------------------------------------------------
    if @viewingMoves
      moveID = pbCurrentMoveID
      case cursor
      when :move   # Displays all owned species that may learn the move.
        list = []
        GameData::Species.each do |sp|
          next if !sp.display_species?(@dexlist, species, true)
          regional_form = sp.form > 0 && sp.is_regional_form?
          base_form = (sp.form > 0) ? GameData::Species.get_species_form(sp.species, sp.base_pokedex_form) : nil
          next if base_form && !regional_form && 
		          sp.moves == base_form.moves && 
              sp.get_tutor_moves == base_form.get_tutor_moves
          if sp.moves.any? { |m| m[1] == moveID } ||
             sp.get_tutor_moves.include?(moveID) ||
             sp.get_egg_moves.include?(moveID)
            list.push(sp.id)
          end
        end
        list = pbSortDataList(list)
      when :egg    # Displays only species in a compatible Egg Group.
        compatible = []
        list.each do |s|
          next if s == :RETURN
          sp = GameData::Species.try_get(s)
          if sp && sp.moves.any? { |m| m[1] == moveID } ||
             sp.get_tutor_moves.include?(moveID) ||
             sp.get_egg_moves.include?(moveID)
            compatible.push(s)
          end
        end
        list = pbSortDataList(compatible)
      end
    #---------------------------------------------------------------------------
    # When viewing ability lists.
    #-------------------------------------------------------------------------
    elsif GameData::Ability.exists?(cursor)
      list = []
      GameData::Species.each do |sp|
        next if !sp.display_species?(@dexlist, species)
        regional_form = sp.form > 0 && sp.is_regional_form?
        base_form = (sp.form > 0) ? GameData::Species.get_species_form(sp.species, sp.base_pokedex_form) : nil
        next if base_form && !regional_form && 
		        sp.abilities == base_form.abilities && 
            sp.hidden_abilities == base_form.hidden_abilities
        if sp.abilities.include?(cursor) || sp.hidden_abilities.include?(cursor)
          list.push(sp.id)
        end
      end
      list = pbSortDataList(list)
    #---------------------------------------------------------------------------
    # When viewing wild held item lists.
    #-------------------------------------------------------------------------
    elsif GameData::Item.exists?(cursor)
      list = []
      GameData::Species.each do |sp|
        next if !sp.display_species?(@dexlist, species)
        regional_form = sp.form > 0 && sp.is_regional_form?
        base_form = (sp.form > 0) ? GameData::Species.get_species_form(sp.species, sp.base_pokedex_form) : nil
        next if base_form && !regional_form && 
		        sp.wild_item_common   == base_form.wild_item_common   && 
                sp.wild_item_uncommon == base_form.wild_item_uncommon &&
                sp.wild_item_rare     == base_form.wild_item_rare
        if sp.wild_item_common.include?(cursor) ||
           sp.wild_item_uncommon.include?(cursor) ||
           sp.wild_item_rare.include?(cursor)
          list.push(sp.id)
        end
      end
      list = pbSortDataList(list)
    #---------------------------------------------------------------------------
    # Ensures no compatible Egg Groups if viewed species in Undiscovered group.
    #---------------------------------------------------------------------------
    elsif cursor == :egg && !list.empty?
      list.clear if species.egg_groups.include?(:Undiscovered)
    end
    if list.empty?
      pbPlayBuzzerSE
    else
      list.push(:RETURN)
    end
    return list
  end

  #-----------------------------------------------------------------------------
  # Draws sub menus that display pages of species icons.
  #-----------------------------------------------------------------------------
  def pbDrawSpeciesDataList(list, index, page, maxpage, cursor = nil)
    return if list.empty?
    overlay = @sprites["data_overlay"].bitmap
    overlay.clear
    base = Color.new(248, 248, 248)
    shadow = Color.new(72, 72, 72)
    path = Settings::POKEDEX_DATA_PAGE_GRAPHICS_PATH
    page_size = PokemonDataPageSprite::PAGE_SIZE
    idxList = (page * page_size) + index
    species_data = GameData::Species.try_get(list[idxList])
    gender = (cursor == :egg) ? [1, 0][@gender] : @gender
    @sprites["pokelist"].setPokemon(list, page, gender)
    pokesprite = @sprites["pokelist"].getPokemon(index)
    name = (species_data) ? species_data.name : _INTL("Volver")
    textpos = [
      [name, 256, 248, :center, base, shadow, :outline],
      [sprintf("%d/%d", page + 1, maxpage + 1), 51, 249, :center, base, shadow, :outline]
    ]
    imagepos = [
      [path + "submenu", 0, 88, 0, 0, 512, 196], 
      [path + "cursor", pokesprite.x - 5, pokesprite.y - 4, 402, 132, 76, 76]
    ]
    if page < maxpage
      imagepos.push([path + "page_cursor", 88, 242, 0, 70, 76, 32])
    end
    if page > 0
      imagepos.push([path + "page_cursor", 348, 242, 76, 70, 76, 32])
    end
    #---------------------------------------------------------------------------
    # Draws header and message box if viewing moves.
    #---------------------------------------------------------------------------
    if @viewingMoves
      imagepos.push(
        [path + "heading", 0, 40], 
        [path + "messagebox", 0, Graphics.height - 100],
        [path + "submenu", 468, 244, 440, 392, 28, 28]
      )
      case cursor
      when :move
        heading = _INTL("Especies que conocen el movimiento:")
        imagepos.push([_INTL("Graphics/UI/Pokedex/icon_own"), 14, 50])
      when :egg
        heading = _INTL("Especies compatibles que conocen este movimiento:")
        imagepos.push([_INTL("Graphics/Pokemon/Eggs/000_icon"), -2, 26, 0, 0, 64, 64])
      end
      textpos.push([heading, 52,  56, :left, base, Color.black, :outline])
    end
    #---------------------------------------------------------------------------
    # Draws message box text.
    #---------------------------------------------------------------------------
    if species_data
      s2 = GameData::Species.get_species_form(@species, @form)
      case cursor
      when :general then data_text = pbDataTextGeneral(path, species_data, overlay, true)
      when :family  then data_text = pbDataTextFamily(path, species_data, overlay, true)
      when :stats   then data_text = pbDataTextStats(path, species_data, overlay, s2)
      when :egg     then data_text = pbDataTextEggGroup(path, species_data, overlay, s2.egg_groups)
      when :shape   then data_text = pbDataTextShape(path, species_data, overlay, [s2.color, s2.shape])
      when :habitat then data_text = pbDataTextHabitat(path, species_data, overlay, s2.habitat)
      when :move    then data_text = pbDataTextMoveSource(path, species_data, overlay)
      end
      if !data_text
        if GameData::Ability.exists?(cursor)
          data_text = pbDataTextAbilitySource(path, species_data, overlay, cursor)
        elsif GameData::Item.exists?(cursor)
          data_text = pbDataTextItemSource(path, species_data, overlay, cursor)
        end
      end
    else
      if GameData::Ability.exists?(cursor)
        view = "Habilidades de la especie"
      elsif GameData::Item.exists?(cursor)
        view = "Objetos equipados de la especie"
      else
        view = (@viewingMoves) ? "Movimientos de la especie" : "datos de la especie"
      end
      data_text = DATA_TEXT_TAGS[0] + "Volver a #{view}."
    end
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
    drawFormattedTextEx(overlay, 34, 294, 446, _INTL("{1}", data_text))
  end
  
  #-----------------------------------------------------------------------------
  # Controls for navigating text-based sub menus. (Ability/Item)
  #-----------------------------------------------------------------------------
  def pbChooseDataList(cursor = nil)
    return if !$player.owned?(@species)
    cursor = @cursor if !cursor
    list = []
    @data_hash[cursor].each { |k, v| list.concat(v) }
    pbPlayBuzzerSE if list.empty?
    return if list.empty?
    list.uniq!
    list.push(_INTL("Volver"))
    index = 0
    maxidx = list.length - 1
    pbSEPlay("GUI storage show party panel")
    pbDrawDataList(list, index, cursor)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.repeat?(Input::UP)
        old_index = index
        index -= 1
        index = maxidx if index < 0
        if index != old_index
          pbPlayCursorSE
          pbDrawDataList(list, index, cursor)
        end
      elsif Input.repeat?(Input::DOWN)
        old_index = index
        index += 1
        index = 0 if index > maxidx
        if index != old_index
          pbPlayCursorSE
          pbDrawDataList(list, index, cursor)
        end
      elsif Input.repeat?(Input::JUMPUP)
        old_index = index
        index = 0
        if index != old_index
          pbPlayCursorSE
          pbDrawDataList(list, index, cursor)
        end
      elsif Input.repeat?(Input::JUMPDOWN)
        old_index = index
        index = maxidx
        if index != old_index
          pbPlayCursorSE
          pbDrawDataList(list, index, cursor)
        end
      elsif Input.trigger?(Input::USE)
        if index == list.length - 1
          pbSEPlay("GUI storage hide party panel")
          drawPage(@page)
          pbDrawDataNotes
          break
        else
          pbChooseSpeciesDataList(list[index])
          break if @forceRefresh
          pbDrawDataList(list, index, cursor)
        end
      elsif Input.trigger?(Input::BACK)
        pbSEPlay("GUI storage hide party panel")
        drawPage(@page)
        pbDrawDataNotes
        break
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws text-based sub menus. (Ability/item)
  #-----------------------------------------------------------------------------
  def pbDrawDataList(list, index, cursor = nil)
    cursor = @cursor if !cursor
    case cursor
    when :item    then data = GameData::Item
    when :ability then data = GameData::Ability
    end
    return if list.empty?
    overlay = @sprites["data_overlay"].bitmap
    overlay.clear
    base = Color.new(248, 248, 248)
    shadow = Color.new(72, 72, 72)
    path = Settings::POKEDEX_DATA_PAGE_GRAPHICS_PATH
    textpos = []
    imagepos = [[path + "submenu", 0, 88, 0, 196, 512, 196]]
    last_idx = list.length - 1
    case index
    when 0        then real_idx = 0
    when last_idx then real_idx = (last_idx > 2) ? 2 : index
    else               real_idx = 1
    end
    idx_start = (index > 1) ? index - 1 : 0
    if last_idx - index > 0
      idx_end = idx_start + 2
    else
      idx_start = (last_idx - 2 > 0) ? last_idx - 2 : 0
      idx_end = last_idx
    end
    list[idx_start..idx_end].each_with_index do |id, i|
      idx = 0
      note = ""
      @data_hash[cursor].keys.each do |num|
        next if !@data_hash[cursor][num].include?(id)
        case cursor
        when :item
          case num
          when 0 then note = "Común"
          when 1 then note = "Poco común"
          when 2 then note = "Raro"
          end
        when :ability
          case num
          when 0 then note = "Habil. #{list.index(id) + 1}"
          when 1 then note = "H. Oculta"
          when 2 then note = "H. Especial"
          end
        end
        idx = num
        break if !nil_or_empty?(note)
      end
      case idx
      when 1 then imagepos.push([path + "submenu", 50, 104 + 42 * i, 0, 392, 412, 40])
      when 2 then imagepos.push([path + "submenu", 50, 104 + 42 * i, 0, 432, 412, 40])
      end
      if index < list.length - 1
        textpos.push([sprintf("%d/%d", index + 1, list.length - 1), 115, 243, :center, base, shadow, :outline])
      end
      if id.is_a?(Symbol)
        textpos.push(
          [_INTL("{1}", note), 115, 114 + 42 * i, :center, base, shadow, :outline],
          [data.get(id).name, 326, 114 + 42 * i, :center, base, shadow, :outline]
        )
      else
        imagepos.push([path + "submenu", 98, 110 + 42 * i, 468, 392, 34, 28])
        textpos.push([id, 326, 114 + 42 * i, :center, base, Color.new(148, 148, 148), :outline])
      end
    end
    imagepos.push([path + "cursor", 184, 98 + 42 * real_idx, 0, 288, 284, 52])
    if index < list.length - 1
      imagepos.push([path + "page_cursor", 248, 236, 0, 70, 76, 32])
    end
    if index > 0
      imagepos.push([path + "page_cursor", 328, 236, 76, 70, 76, 32])
    end
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
    case list[index]
    when Symbol
      data_text = DATA_TEXT_TAGS[0] + data.get(list[index]).description
    else
      data_text = DATA_TEXT_TAGS[0] + "Volver a los datos de la especie."
    end
    drawFormattedTextEx(overlay, 34, 294, 446, _INTL("{1}", data_text))
  end
end