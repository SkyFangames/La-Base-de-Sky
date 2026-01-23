#===============================================================================
#
#===============================================================================
class PokemonPokedexInfo_Scene
  INFO_SPRITE_X     = 104
  INFO_SPRITE_Y     = 136
  AREA_MAP_Y_OFFSET = 32
  FORM_FRONT_X      = 130
  FORM_FRONT_Y      = 158
  FORM_BACK_X       = 382
  FORM_BACK_Y       = 256
  FORM_ICON_X       = 82
  FORM_ICON_Y       = 328
  UP_ARROW_X        = 242
  UP_ARROW_Y        = 268
  DOWN_ARROW_X      = 242
  DOWN_ARROW_Y      = 348


  PAGE_INFO_COORDS   = {
    :species_name   => [246, 48],
    :battled_text   => [314, 164],
    :battled_num    => [314, 196],
    :height_text    => [314, 164],
    :weight_text    => [314, 196],
    :category       => [246, 80],
    :height_num_us  => [460, 164],
    :weight_num_us  => [494, 196],
    :height_num     => [470, 164],
    :weight_num     => [482, 196],
    # x, y, width, lines
    :dex_entry_text => [40, 246, Settings::SCREEN_WIDTH - 80, 4],
    :footprint      => [226, 138],
    :owned_icon     => [212, 44],
    # base_x, offset_x, y
    :type_icon    => [296, 100, 120],
  }

  PAGE_AREA_COORDS   = {
    :area_none              => [108, 188],
    :unknown_area_y_offset  => 6,
    :map_name               => [414, 50],
    :species_name_y         => 358,
   }

  PAGE_FORMS_COORDS  = {
    :species_name_y_offset  => -82,
    :form_name_y_offset     => -50,
  }

  def pbStartScene(dexlist, index, region, page = 1)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @dexlist = dexlist
    @index   = index
    @region  = region
    @page = page
    @show_battled_count = false
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_types"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["infosprite"] = PokemonSprite.new(@viewport)
    @sprites["infosprite"].setOffset(PictureOrigin::CENTER)
    @sprites["infosprite"].x = INFO_SPRITE_X
    @sprites["infosprite"].y = INFO_SPRITE_Y
    mappos = $game_map.metadata&.town_map_position
    if @region < 0                                 # Use player's current region
      @region = (mappos) ? mappos[0] : 0                      # Region 0 default
    end
    @mapdata = GameData::TownMap.try_get(@region)
    if @mapdata
      @sprites["areamap"] = IconSprite.new(0, 0, @viewport)
      @sprites["areamap"].setBitmap("Graphics/UI/Town Map/#{@mapdata.filename}")
      @sprites["areamap"].x += (Graphics.width - @sprites["areamap"].bitmap.width) / 2
      @sprites["areamap"].y += (Graphics.height + AREA_MAP_Y_OFFSET - @sprites["areamap"].bitmap.height) / 2
      Settings::REGION_MAP_EXTRAS.each do |hidden|
        next if hidden[0] != @region || hidden[1] <= 0 || !$game_switches[hidden[1]]
        pbDrawImagePositions(
          @sprites["areamap"].bitmap,
          [["Graphics/UI/Town Map/#{hidden[4]}",
            hidden[2] * PokemonRegionMap_Scene::SQUARE_WIDTH,
            hidden[3] * PokemonRegionMap_Scene::SQUARE_HEIGHT]]
        )
      end
    end
    @sprites["areahighlight"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["areaoverlay"] = IconSprite.new(0, 0, @viewport)
    @sprites["areaoverlay"].setBitmap("Graphics/UI/Pokedex/overlay_area")
    @sprites["formfront"] = PokemonSprite.new(@viewport)
    @sprites["formfront"].setOffset(PictureOrigin::CENTER)
    @sprites["formfront"].x = FORM_FRONT_X
    @sprites["formfront"].y = FORM_FRONT_Y
    @sprites["formback"] = PokemonSprite.new(@viewport)
    @sprites["formback"].setOffset(PictureOrigin::BOTTOM)
    @sprites["formback"].x = FORM_BACK_X   # y is set below as it depends on metrics
    @sprites["formicon"] = PokemonSpeciesIconSprite.new(nil, @viewport)
    @sprites["formicon"].setOffset(PictureOrigin::CENTER)
    @sprites["formicon"].x = FORM_ICON_X
    @sprites["formicon"].y = FORM_ICON_Y
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/UI/up_arrow", 8, 28, 40, 2, @viewport)
    @sprites["uparrow"].x = UP_ARROW_X
    @sprites["uparrow"].y = UP_ARROW_Y
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/UI/down_arrow", 8, 28, 40, 2, @viewport)
    @sprites["downarrow"].x = DOWN_ARROW_X
    @sprites["downarrow"].y = DOWN_ARROW_Y
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbUpdateDummyPokemon
    @available = pbGetAvailableForms
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  # For standalone access, shows first page only.
  def pbStartSceneBrief(species)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    dexnum = 0
    dexnumshift = false
    if $player.pokedex.unlocked?(-1)   # National Dex is unlocked
      species_data = GameData::Species.try_get(species)
      if species_data
        nationalDexList = [:NONE]
        GameData::Species.each_species { |s| nationalDexList.push(s.species) }
        dexnum = nationalDexList.index(species_data.species) || 0
        dexnumshift = true if dexnum > 0 && Settings::DEXES_WITH_OFFSETS.include?(-1)
      end
    else
      ($player.pokedex.dexes_count - 1).times do |i|   # Regional Dexes
        next if !$player.pokedex.unlocked?(i)
        num = pbGetRegionalNumber(i, species)
        next if num <= 0
        dexnum = num
        dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(i)
        break
      end
    end
    @dexlist = [{
      :species => species,
      :name    => "",
      :height  => 0,
      :weight  => 0,
      :number  => dexnum,
      :shift   => dexnumshift
    }]
    @index = 0
    @page = 1
    @brief = true
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_types"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["infosprite"] = PokemonSprite.new(@viewport)
    @sprites["infosprite"].setOffset(PictureOrigin::CENTER)
    @sprites["infosprite"].x = INFO_SPRITE_X
    @sprites["infosprite"].y = INFO_SPRITE_Y
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbUpdateDummyPokemon
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @viewport.dispose
  end

  def pbUpdate
    if @page == 2
      intensity_time = System.uptime % 1.0   # 1 second per glow
      if intensity_time >= 0.5
        intensity = lerp(64, 256 + 64, 0.5, intensity_time - 0.5)
      else
        intensity = lerp(256 + 64, 64, 0.5, intensity_time)
      end
      @sprites["areahighlight"].opacity = intensity
    end
    pbUpdateSpriteHash(@sprites)
  end

  def pbUpdateDummyPokemon
    @species = @dexlist[@index][:species]
    @gender, @form, _shiny = $player.pokedex.last_form_seen(@species)
    @shiny = false
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    @sprites["infosprite"].setSpeciesBitmap(@species, @gender, @form, @shiny)
    @sprites["formfront"]&.setSpeciesBitmap(@species, @gender, @form, @shiny)
    if @sprites["formback"]
      @sprites["formback"].setSpeciesBitmap(@species, @gender, @form, @shiny, false, true)
      @sprites["formback"].y = FORM_BACK_Y
      @sprites["formback"].y += metrics_data.back_sprite[1] * 2
    end
    @sprites["formicon"]&.pbSetParams(@species, @gender, @form, @shiny)
  end

  def pbGetAvailableForms
    ret = []
    multiple_forms = false
    gender_differences = (GameData::Species.front_sprite_filename(@species, 0) == GameData::Species.front_sprite_filename(@species, 0, 1))
    # Find all genders/forms of @species that have been seen
    GameData::Species.each do |sp|
      next if sp.species != @species
      next if sp.form != 0 && (!sp.real_form_name || sp.real_form_name.empty?)
      next if sp.pokedex_form != sp.form
      multiple_forms = true if sp.form > 0
      if sp.single_gendered?
        real_gender = (sp.gender_ratio == :AlwaysFemale) ? 1 : 0
        next if !$player.pokedex.seen_form?(@species, real_gender, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
        real_gender = 2 if sp.gender_ratio == :Genderless
        ret.push([sp.form_name, real_gender, sp.form])
      elsif sp.form == 0 && !gender_differences
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          ret.push([sp.form_name || _INTL("Forma Normal"), 0, sp.form])
          break
        end
      else   # Both male and female
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          ret.push([sp.form_name, real_gndr, sp.form])
          break if sp.form_name && !sp.form_name.empty?   # Only show 1 entry for each non-0 form
        end
      end
    end
    # Sort all entries
    ret.sort! { |a, b| (a[2] == b[2]) ? a[1] <=> b[1] : a[2] <=> b[2] }
    # Create form names for entries if they don't already exist
    ret.each do |entry|
      if entry[0]   # Alternate forms, and form 0 if no gender differences
        entry[0] = "" if !multiple_forms && !gender_differences
      else   # Necessarily applies only to form 0
        case entry[1]
        when 0 then entry[0] = _INTL("Macho")
        when 1 then entry[0] = _INTL("Hembra")
        else
          entry[0] = (multiple_forms) ? _INTL("Forma Normal") : _INTL("Sin género")
        end
      end
      entry[1] = 0 if entry[1] == 2   # Genderless entries are treated as male
    end
    return ret
  end

  def drawPage(page)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Make certain sprites visible
    @sprites["infosprite"].visible    = (@page == 1)
    @sprites["areamap"].visible       = (@page == 2) if @sprites["areamap"]
    @sprites["areahighlight"].visible = (@page == 2) if @sprites["areahighlight"]
    @sprites["areaoverlay"].visible   = (@page == 2) if @sprites["areaoverlay"]
    @sprites["formfront"].visible     = (@page == 3) if @sprites["formfront"]
    @sprites["formback"].visible      = (@page == 3) if @sprites["formback"]
    @sprites["formicon"].visible      = (@page == 3) if @sprites["formicon"]
    @sprites["formicon"].visible      = (@page == 4) if @sprites["formicon"]
    # Draw page-specific information
    case page
    when 1 then drawPageInfo
    when 2 then drawPageArea
    when 3 then drawPageForms
    end
  end

  def drawPageInfo
    coords = PAGE_INFO_COORDS
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_info"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(88, 88, 80)
    shadow = Color.new(168, 184, 184)
    imagepos = []
    imagepos.push([_INTL("Graphics/UI/Pokedex/overlay_info"), 0, 0]) if @brief
    species_data = GameData::Species.get_species_form(@species, @form)
    # Write various bits of text
    indexText = "???"
    if @dexlist[@index][:number] > 0
      indexNumber = @dexlist[@index][:number]
      indexNumber -= 1 if @dexlist[@index][:shift]
      indexText = sprintf("%03d", indexNumber)
    end
    textpos = [
      [_INTL("{1}{2} {3}", indexText, " ", species_data.name),
       coords[:species_name][0], coords[:species_name][1], :left, Color.new(248, 248, 248), Color.black]
    ]
    if @show_battled_count
      textpos.push([_INTL("Enfrentados:"), coords[:battled_text][0], coords[:battled_text][1], :left, base, shadow])
      textpos.push([$player.pokedex.battled_count(@species).to_s, coords[:battled_num][0], coords[:battled_num][1], :left, base, shadow])
    else
      textpos.push([_INTL("Altura"), coords[:height_text][0], coords[:height_text][1], :left, base, shadow])
      textpos.push([_INTL("Peso"), coords[:weight_text][0], coords[:weight_text][1], :left, base, shadow])
    end
    if $player.owned?(@species)
      # Write the category
      textpos.push([_INTL("Pokémon {1}", species_data.category), coords[:category][0], coords[:category][1], :left, base, shadow])
      # Write the height and weight
      if !@show_battled_count
        height = species_data.height
        weight = species_data.weight
        if System.user_language[3..4] == "US"   # If the user is in the United States
          inches = (height / 0.254).round
          pounds = (weight / 0.45359).round
          textpos.push([_ISPRINTF("{1:d}'{2:02d}\"", inches / 12, inches % 12), coords[:height_num_us][0], coords[:height_num_us][1], :right, base, shadow])
          textpos.push([_ISPRINTF("{1:4.1f} lbs.", pounds / 10.0), coords[:weight_num_us][0], coords[:weight_num_us][1], :right, base, shadow])
        else
          textpos.push([_ISPRINTF("{1:.1f} m", height / 10.0), coords[:height_num][0], coords[:height_num][1], :right, base, shadow])
          textpos.push([_ISPRINTF("{1:.1f} kg", weight / 10.0), coords[:weight_num][0], coords[:weight_num][1], :right, base, shadow])
        end
      end
      # Draw the Pokédex entry text
      drawTextEx(overlay, coords[:dex_entry_text][0], coords[:dex_entry_text][1], coords[:dex_entry_text][2], coords[:dex_entry_text][3],   # overlay, x, y, width, num lines
                 species_data.pokedex_entry, base, shadow)
      # Draw the footprint
      footprintfile = GameData::Species.footprint_filename(@species, @form)
      if footprintfile
        footprint = RPG::Cache.load_bitmap("", footprintfile)
        overlay.blt(coords[:footprint][0], coords[:footprint][1], footprint, footprint.rect)
        footprint.dispose
      end
      # Show the owned icon
      imagepos.push(["Graphics/UI/Pokedex/icon_own", coords[:owned_icon][0], coords[:owned_icon][1]])
      # Draw the type icon(s)
      species_data.types.each_with_index do |type, i|
        type_number = GameData::Type.get(type).icon_position
        type_rect = Rect.new(0, type_number * 32, 96, 32)
        overlay.blt(coords[:type_icon][0] + (coords[:type_icon][1] * i), coords[:type_icon][2], @typebitmap.bitmap, type_rect)
      end
    else
      # Write the category
      textpos.push([_INTL("Pokémon ?????"), coords[:category][0], coords[:category][1], :left, base, shadow])
      # Write the height and weight
      if !@show_battled_count
        if System.user_language[3..4] == "US"   # If the user is in the United States
          textpos.push([_INTL("???'??\""), coords[:height_num_us][0], coords[:height_num_us][1], :right, base, shadow])
          textpos.push([_INTL("????.? lbs."), coords[:weight_num_us][0], coords[:weight_num_us][1], :right, base, shadow])
        else
          textpos.push([_INTL("????.? m"), coords[:height_num][0], coords[:height_num][1], :right, base, shadow])
          textpos.push([_INTL("????.? kg"), coords[:weight_num][0], coords[:weight_num][1], :right, base, shadow])
        end
      end
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
  end

  def pbFindEncounter(enc_types, species)
    return false if !enc_types
    enc_types.each_value do |slots|
      next if !slots
      slots.each { |slot| return true if GameData::Species.get(slot[1]).species == species }
    end
    return false
  end

  # Returns a 1D array of values corresponding to points on the Town Map. Each
  # value is true or false.
  def pbGetEncounterPoints
    # Determine all visible points on the Town Map (i.e. only ones with a
    # defined point in town_map.txt, and which either have no Self Switch
    # controlling their visibility or whose Self Switch is ON)
    visible_points = []
    @mapdata&.point&.each do |loc|
      next if loc[7] && !$game_switches[loc[7]]   # Point is not visible
      visible_points.push([loc[0], loc[1]])
    end
    # Find all points with a visible area for @species
    town_map_width = 1 + PokemonRegionMap_Scene::RIGHT - PokemonRegionMap_Scene::LEFT
    ret = []
    GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
      next if !pbFindEncounter(enc_data.types, @species)   # Species isn't in encounter table
      # Get the map belonging to the encounter table
      map_metadata = GameData::MapMetadata.try_get(enc_data.map)
      next if !map_metadata || map_metadata.has_flag?("HideEncountersInPokedex")
      mappos = map_metadata.town_map_position
      next if mappos[0] != @region   # Map isn't in the region being shown
      # Get the size and shape of the map in the Town Map
      map_size = map_metadata.town_map_size
      map_width = 1
      map_height = 1
      map_shape = "1"
      if map_size && map_size[0] && map_size[0] > 0   # Map occupies multiple points
        map_width = map_size[0]
        map_shape = map_size[1]
        map_height = (map_shape.length.to_f / map_width).ceil
      end
      # Mark each visible point covered by the map as containing the area
      map_width.times do |i|
        map_height.times do |j|
          next if map_shape[i + (j * map_width), 1].to_i == 0   # Point isn't part of map
          next if !visible_points.include?([mappos[1] + i, mappos[2] + j])   # Point isn't visible
          ret[mappos[1] + i + ((mappos[2] + j) * town_map_width)] = true
        end
      end
    end
    return ret
  end

  def drawPageArea
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_area"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(88, 88, 80)
    shadow = Color.new(168, 184, 184)
    @sprites["areahighlight"].bitmap.clear
    # Get all points to be shown as places where @species can be encountered
    points = pbGetEncounterPoints
    # Draw coloured squares on each point of the Town Map with a nest
    pointcolor   = Color.new(0, 248, 248)
    pointcolorhl = Color.new(192, 248, 248)
    town_map_width = 1 + PokemonRegionMap_Scene::RIGHT - PokemonRegionMap_Scene::LEFT
    sqwidth = PokemonRegionMap_Scene::SQUARE_WIDTH
    sqheight = PokemonRegionMap_Scene::SQUARE_HEIGHT
    points.length.times do |j|
      next if !points[j]
      x = (j % town_map_width) * sqwidth
      x += (Graphics.width - @sprites["areamap"].bitmap.width) / 2
      y = (j / town_map_width) * sqheight
      y += (Graphics.height + 32 - @sprites["areamap"].bitmap.height) / 2
      @sprites["areahighlight"].bitmap.fill_rect(x, y, sqwidth, sqheight, pointcolor)
      if j - town_map_width < 0 || !points[j - town_map_width]
        @sprites["areahighlight"].bitmap.fill_rect(x, y - 2, sqwidth, 2, pointcolorhl)
      end
      if j + town_map_width >= points.length || !points[j + town_map_width]
        @sprites["areahighlight"].bitmap.fill_rect(x, y + sqheight, sqwidth, 2, pointcolorhl)
      end
      if j % town_map_width == 0 || !points[j - 1]
        @sprites["areahighlight"].bitmap.fill_rect(x - 2, y, 2, sqheight, pointcolorhl)
      end
      if (j + 1) % town_map_width == 0 || !points[j + 1]
        @sprites["areahighlight"].bitmap.fill_rect(x + sqwidth, y, 2, sqheight, pointcolorhl)
      end
    end
    # Set the text
    coords = PAGE_AREA_COORDS
    textpos = []
    if points.length == 0
      pbDrawImagePositions(
        overlay,
        [["Graphics/UI/Pokedex/overlay_areanone", coords[:area_none][0], coords[:area_none][1]]]
      )
      textpos.push([_INTL("Área desconocida"), Graphics.width / 2, Graphics.height / 2 + coords[:unknown_area_y_offset], :center, base, shadow])
    end
    if @mapdata
      textpos.push([@mapdata&.name, coords[:map_name][0], coords[:map_name][1], :center, base, shadow])
    end
    textpos.push([_INTL("Área de {1}", GameData::Species.get(@species).name),
                  Graphics.width / 2, coords[:species_name_y], :center, base, shadow])
    pbDrawTextPositions(overlay, textpos)
  end

  def drawPageForms
    coords = PAGE_FORMS_COORDS
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_forms"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(88, 88, 80)
    shadow = Color.new(168, 184, 184)
    # Write species and form name
    formname = ""
    @available.each do |i|
      if i[1] == @gender && i[2] == @form
        formname = i[0]
        break
      end
    end
    textpos = [
      [GameData::Species.get(@species).name, Graphics.width / 2, Graphics.height + coords[:species_name_y_offset], :center, base, shadow],
      [formname, Graphics.width / 2, Graphics.height + coords[:form_name_y_offset], :center, base, shadow]
    ]
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def pbGoToPrevious
    newindex = @index
    while newindex > 0
      newindex -= 1
      if $player.seen?(@dexlist[newindex][:species])
        @index = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @index
    while newindex < @dexlist.length - 1
      newindex += 1
      if $player.seen?(@dexlist[newindex][:species])
        @index = newindex
        break
      end
    end
  end

  def pbChooseForm
    index = 0
    @available.length.times do |i|
      if @available[i][1] == @gender && @available[i][2] == @form
        index = i
        break
      end
    end
    oldindex = -1
    loop do
      if oldindex != index
        $player.pokedex.set_last_form_seen(@species, @available[index][1], @available[index][2])
        pbUpdateDummyPokemon
        drawPage(@page)
        @sprites["uparrow"].visible   = (index > 0)
        @sprites["downarrow"].visible = (index < @available.length - 1)
        oldindex = index
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::UP)
        pbPlayCursorSE
        index = (index + @available.length - 1) % @available.length
      elsif Input.trigger?(Input::DOWN)
        pbPlayCursorSE
        index = (index + 1) % @available.length
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      end
    end
    @sprites["uparrow"].visible   = false
    @sprites["downarrow"].visible = false
  end

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
        case @page
        when 1   # Info
          pbPlayDecisionSE
          @show_battled_count = !@show_battled_count
          dorefresh = true
        when 2   # Area
#          dorefresh = true
        when 3   # Forms
          if @available.length > 1
            pbPlayDecisionSE
            pbChooseForm
            dorefresh = true
          end
        end
      elsif Input.trigger?(Input::UP)
        oldindex = @index
        pbGoToPrevious
        if @index != oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page == 1) ? Pokemon.play_cry(@species, @form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN)
        oldindex = @index
        pbGoToNext
        if @index != oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page == 1) ? Pokemon.play_cry(@species, @form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT)
        oldpage = @page
        @page -= 1
        @page = 1 if @page < 1
        @page=@maxPage if @page>@maxPage
        if @page != oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT)
        oldpage = @page
        @page += 1
        @page = 1 if @page < 1
        @page=@maxPage if @page>@maxPage
        if @page != oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      end
      drawPage(@page) if dorefresh
    end
    return @index
  end

  def pbSceneBrief
    Pokemon.play_cry(@species, @form)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::ACTION)
        pbSEStop
        Pokemon.play_cry(@species, @form)
      elsif Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
        pbPlayCloseMenuSE
        break
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokedexInfoScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(dexlist, index, region, page = 1)
    @scene.pbStartScene(dexlist, index, region, page)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret   # Index of last species viewed in dexlist
  end

  # For use from a Pokémon's summary screen.
  def pbStartSceneSingle(species, full_dexlist = false)
    region = -1
    if Settings::USE_CURRENT_REGION_DEX
      region = pbGetCurrentRegion
      region = -1 if region >= $player.pokedex.dexes_count - 1
    else
      region = $PokemonGlobal.pokedexDex  # National Dex -1, regional Dexes 0, 1, etc.
    end
    dexnum = pbGetRegionalNumber(region, species)
    dexnumshift = Settings::DEXES_WITH_OFFSETS.include?(region)
    if full_dexlist
      region = -1
      dexlist, index = pbGetDexList(species, region)
    else
      dexlist = [{
        :species => species,
        :name    => GameData::Species.get(species).name,
        :height  => 0,
        :weight  => 0,
        :number  => dexnum,
        :shift   => dexnumshift
      }]
      index = 0
    end
    @scene.pbStartScene(dexlist, index, region)
    @scene.pbScene
    @scene.pbEndScene
  end

  # For use when capturing or otherwise obtaining a new species.
  def pbDexEntry(species)
    @scene.pbStartSceneBrief(species)
    @scene.pbSceneBrief
    @scene.pbEndScene
  end
end