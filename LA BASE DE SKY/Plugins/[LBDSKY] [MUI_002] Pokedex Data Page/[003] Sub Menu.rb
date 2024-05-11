#===============================================================================
# Usado para dibujar una página entera de sprites de iconos de especies a la vez.
#===============================================================================
class PokemonDataPageSprite < Sprite
  PAGE_SIZE = 12  # Numero de iconos de especies por pagina
  ROW_SIZE  = 6   # Numero de iconos de especies por fila
  ICON_GAP  = 72  # Gap de pixeles entre cada icono de especie
  PAGE_X    = 43  # Coordenada X donde se colocan los iconos
  PAGE_Y    = 26  # Coordenada Y donde se colocan los iconos

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
  
  def setPokemon(list, page)
    PAGE_SIZE.times do |i|
      index = PAGE_SIZE * page + i
      pokemon = list[index]
      if GameData::Species.exists?(pokemon)
        @pokemonsprites[i].species = pokemon
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
# Controla los diversos sub menús de la página de datos.
#===============================================================================
class PokemonPokedexInfo_Scene
  #-----------------------------------------------------------------------------
  # Controla la navegación de los sub menús que muestran páginas de iconos de especies.
  #-----------------------------------------------------------------------------
  def pbChooseSpeciesDataList(cursor = nil)
    cursor = @cursor if !cursor
    list = []
    case cursor
    when :stats, :egg     then @data_hash[cursor].each { |k, v| list += v }
    when :shape           then list = @data_hash[cursor]
    when :family          then list = @data_hash[:evos]
    end
    return if list.empty?
    list.uniq!
    row_size  = PokemonDataPageSprite::ROW_SIZE
    page_size = PokemonDataPageSprite::PAGE_SIZE
    page    = 0
    index   = 0
    maxpage = ((list.length - 1) / page_size).floor
    pbPlayDecisionSE
    pbDrawSpeciesDataList(list, index, page, maxpage, cursor)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      count = 0
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
          dorefresh = true
        end
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::JUMPDOWN)
        if page < maxpage
          page += 1
          index = 0
          dorefresh = true
        end
      #-------------------------------------------------------------------------
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        @sprites["pokelist"].visible = false
        drawPage(@page)
        pbDrawDataNotes
        break
      end
      #-------------------------------------------------------------------------
      if dorefresh
        pbPlayCursorSE
        pbDrawSpeciesDataList(list, index, page, maxpage, cursor)
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Dibuja sub menús que muestran páginas de iconos de especies.
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
    species_data = GameData::Species.get(list[idxList])
    textpos = [[species_data.name, 256, 248, :center, base, shadow, :outline]]
    @sprites["pokelist"].setPokemon(list, page)
    pokesprite = @sprites["pokelist"].getPokemon(index)
    imagepos = [
      [path + "submenu", 0, 88, 0, 0, 512, 196], 
      [path + "cursor", pokesprite.x - 5, pokesprite.y - 4, 402, 132, 76, 76]
    ]
    if page < maxpage
      imagepos.push([path + "page_cursor", 44, 242, 0, 70, 76, 32])
    end
    if page > 0
      imagepos.push([path + "page_cursor", 392, 242, 76, 70, 76, 32])
    end
    t = DATA_TEXT_TAGS
    s2 = GameData::Species.get_species_form(@species, @form)
    case cursor
    when :stats   then data_text = pbDataTextStats(path, species_data, overlay, s2)
    when :egg     then data_text = pbDataTextEggGroup(path, species_data, overlay, s2.egg_groups)
    when :shape   then data_text = pbDataTextShape(path, species_data, overlay, [s2.color, s2.shape])
    when :family  then data_text = pbDataTextFamily(path, species_data, overlay)
    end
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
    drawFormattedTextEx(overlay, 34, 294, 446, _INTL("{1}", data_text))
  end
  
  #-----------------------------------------------------------------------------
  # Controla la navegación de los sub menús de texto. (Habilidad/Objeto)
  #-----------------------------------------------------------------------------
  def pbChooseDataList(cursor = nil)
    return if !$player.owned?(@species)
    cursor = @cursor if !cursor
    list = []
    @data_hash[cursor].each { |k, v| list += v }
    return if list.empty?
    list.uniq!
    index = 0
    maxidx = list.length - 1
    pbPlayDecisionSE
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
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        drawPage(@page)
        pbDrawDataNotes
        break
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Dibuja sub menús de texto. (Habilidad/Objeto)
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
      count = (index + 1).to_s + "/" + list.length.to_s
      textpos.push(
        [_INTL("{1}", note), 115, 114 + 42 * i, :center, base, shadow, :outline],
        [_INTL("{1}", count), 115, 243, :center, base, shadow, :outline],
        [data.get(id).name, 326, 114 + 42 * i, :center, base, shadow, :outline]
      )
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
    data_text = DATA_TEXT_TAGS[0] + data.get(list[index]).description
    drawFormattedTextEx(overlay, 34, 294, 446, _INTL("{1}", data_text))
  end
end