#===============================================================================
# Página de datos de la Pokédex
#===============================================================================
class PokemonPokedexInfo_Scene 
  #-----------------------------------------------------------------------------
  # Controla la navegación por la página de datos.
  #-----------------------------------------------------------------------------
  def pbDataPageMenu
    pbPlayDecisionSE
    pbDrawDataNotes
    species = GameData::Species.get_species_form(@species, @form).id
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCancelSE
        @sprites["data_overlay"].bitmap.clear
        break
      elsif Input.trigger?(Input::USE)
        case @cursor
        when :moves
          next if !$player.owned?(species)
          pbChooseMove
        when :item, :ability
          next if !$player.owned?(species)
          pbChooseDataList
        when :stats, :egg
          next if !$player.owned?(species)
          pbChooseSpeciesDataList
        when :shape
          pbChooseSpeciesDataList
        when :family
          pbChooseSpeciesDataList if  GameData::Species.get_species_form(@species, @form).get_evolutions.length > 0
        end
      elsif Input.repeat?(Input::UP)
        old_cursor = @cursor
        case @cursor
        when :general then @cursor = :ability
        when :stats   then @cursor = :general
        when :family  then @cursor = :general
        when :shape   then @cursor = :family
        when :egg     then @cursor = :family
        when :item    then @cursor = :family
        when :ability then @cursor = :egg
        when :moves   then @cursor = :item
        end
        if @cursor != old_cursor
          pbPlayCursorSE
          pbDrawDataNotes
        end
      elsif Input.repeat?(Input::DOWN)
        old_cursor = @cursor
        case @cursor
        when :general then @cursor = :family
        when :stats   then @cursor = :general
        when :family  then @cursor = :item
        when :shape   then @cursor = :moves
        when :egg     then @cursor = :ability
        when :item    then @cursor = :ability
        when :ability then @cursor = :general
        when :moves   then @cursor = :general
        end
        if @cursor != old_cursor
          pbPlayCursorSE
          pbDrawDataNotes
        end
      elsif Input.repeat?(Input::LEFT)
        old_cursor = @cursor
        case @cursor
        when :general then @cursor = :general
        when :stats   then @cursor = :shape
        when :family  then @cursor = :stats
        when :shape   then @cursor = :egg
        when :egg     then @cursor = :item
        when :item    then @cursor = :stats
        when :ability then @cursor = :stats
        when :moves   then @cursor = :ability
        end
        if @cursor != old_cursor
          pbPlayCursorSE
          pbDrawDataNotes
        end
      elsif Input.repeat?(Input::RIGHT)
        old_cursor = @cursor
        case @cursor
        when :general then @cursor = :general
        when :stats   then @cursor = :item
        when :family  then @cursor = :stats
        when :shape   then @cursor = :stats
        when :egg     then @cursor = :shape
        when :item    then @cursor = :egg
        when :ability then @cursor = :moves
        when :moves   then @cursor = :stats
        end
        if @cursor != old_cursor
          pbPlayCursorSE
          pbDrawDataNotes
        end
      end
    end
    drawPage(@page)
  end
  
  #-----------------------------------------------------------------------------
  # Utilidad para generar listas de datos relacionados con una especie vista.
  #-----------------------------------------------------------------------------
  def pbGenerateDataLists(species)
    @data_hash.clear
    #---------------------------------------------------------------------------
    # Genera una lista de especies que comparten el mismo color y forma.
    #---------------------------------------------------------------------------
    @data_hash[:shape] = Array.new
    @dexlist.each do |dex|
      next if @species == dex[:species]
      next if !$player.seen?(dex[:species])
      next if species.color != GameData::Species.get(dex[:species]).color
      next if species.shape != GameData::Species.get(dex[:species]).shape
      @data_hash[:shape].push(dex[:species])
    end
    #---------------------------------------------------------------------------
    # Genera una lista de especies que comparten las misma suma de estadísticas base.
    #---------------------------------------------------------------------------
    @data_hash[:stats] = Hash.new { |key, value| key[value] = [] }
    GameData::Stat.each_main do |s|
      @dexlist.each do |dex|
        next if species.species == dex[:species]
        next if !$player.owned?(dex[:species])
        if species.base_stats[s.id] == GameData::Species.get(dex[:species]).base_stats[s.id]
          @data_hash[:stats][s.pbs_order] << dex[:species]
        end
      end
    end
    #---------------------------------------------------------------------------
    # Genera una lista de especies que comparten los mismos grupos huevos.
    #---------------------------------------------------------------------------
    @data_hash[:egg] = Hash.new { |key, value| key[value] = [] }
    if !species.egg_groups.include?(:Undiscovered)
      maleOnly = species.gender_ratio == :AlwaysMale
      femaleOnly = species.gender_ratio == :AlwaysFemale
      genderless = species.gender_ratio == :Genderless
      2.times do |i|
        group = species.egg_groups[i]
        next if !group
        case group
        when :Ditto
          @dexlist.each do |dex|
            next if !$player.owned?(dex[:species])
            egg_groups = GameData::Species.get(dex[:species]).egg_groups
            next if egg_groups.include?(:Undiscovered)
            next if egg_groups.include?(:Ditto)
            @data_hash[:egg][0] << dex[:species]
          end
          break
        else
          @dexlist.each do |dex|
            next if @species == dex[:species]
            next if !$player.owned?(dex[:species])
            egg_groups = GameData::Species.get(dex[:species]).egg_groups
            next if genderless && !egg_groups.include?(:Ditto)
            @data_hash[:egg][2] << dex[:species] if egg_groups.include?(:Ditto)
            case GameData::Species.get(dex[:species]).gender_ratio
            when :Genderless   then next
            when :AlwaysMale   then next if maleOnly
            when :AlwaysFemale then next if femaleOnly
            end
            @data_hash[:egg][i] << dex[:species] if egg_groups.include?(group)
          end
          break if genderless
        end
      end
    end
    @data_hash[:egg] = @data_hash[:egg].sort.to_h
    #---------------------------------------------------------------------------
    # Genera una lista de pokémon con esta habilidad.
    #---------------------------------------------------------------------------
    @data_hash[:ability] = Hash.new { |key, value| key[value] = [] }
    species.abilities.each do |a|
      next if @data_hash[:ability][0].include?(a)	
      @data_hash[:ability][0] << a
    end
    species.hidden_abilities.each do |a|
      next if @data_hash[:ability][0].include?(a)	
      next if @data_hash[:ability][1].include?(a)	
      @data_hash[:ability][1] << a
    end
    case species.id
    when :GRENINJA
      if GameData::Species.exists?(:GRENINJA_1) &&
         GameData::Species.get(:GRENINJA_1).abilities.include?(:BATTLEBOND)
        @data_hash[:ability][2] << :BATTLEBOND
      end
    when :ROCKRUFF
      if GameData::Species.exists?(:ROCKRUFF_2) &&
         GameData::Species.get(:ROCKRUFF_2).abilities.include?(:OWNTEMPO)
        @data_hash[:ability][2] << :OWNTEMPO
      end
    end
    #---------------------------------------------------------------------------
    # Genera una lista de objetos que se pueden encontrar en estado salvaje.
    #---------------------------------------------------------------------------
    @data_hash[:item] = Hash.new { |key, value| key[value] = [] }
    special_form, _check_form, check_item = pbGetSpecialFormData(species)
    if special_form && check_item
      @data_hash[:item][0] = [check_item]
    else
      species.wild_item_common.each do |i|
        next if @data_hash[:item][0].include?(i)
        @data_hash[:item][0] << i
      end
      species.wild_item_uncommon.each do |i|
        next if @data_hash[:item][0].include?(i)
        next if @data_hash[:item][1].include?(i)
        @data_hash[:item][1] << i
      end
      species.wild_item_rare.each do |i|
        next if @data_hash[:item][0].include?(i)
        next if @data_hash[:item][1].include?(i)
        next if @data_hash[:item][2].include?(i)
        @data_hash[:item][2] << i
      end
    end

    @data_hash[:evos] = Array.new
    species.evolutions.each do |evo|
      next if !evo[0]
      next if !GameData::Species.exists?(evo[0])
      next if species.get_previous_species == evo[0]
      @data_hash[:evos].push(evo[0])
    end
  end
  
  #-----------------------------------------------------------------------------
  # Trae datos para formas especiales, como Megaevoluciones.
  #-----------------------------------------------------------------------------
  def pbGetSpecialFormData(species)
    check_form = 0
    check_item = nil
    special_form = nil
    if species.form > 0
      [:mega, :primal, :ultra, :gmax, :emax, :tera].each do |sym|
        function = nil
        special_form = nil
        case sym
        when :mega
          if species.mega_stone || species.mega_move
            special_form, check_form, check_item = sym, species.unmega_form, species.mega_stone
            break
          end
        when :gmax
          if defined?(species.gmax_move) && species.gmax_move
            special_form, check_form, check_item = sym, species.ungmax_form, nil
            break
          end
        when :primal then function = "getPrimalForm"
        when :ultra  then function = "getUltraForm"
        when :emax   then function = "getEternamaxForm"
        when :tera   then function = "getTerastalForm"
        end
        next if function.nil?
        if MultipleForms.hasFunction?(species.species, function)
          dex_data = MultipleForms.call("getDataPageInfo", species)
          next if !dex_data || species.form != dex_data[0]
          special_form, check_form, check_item = sym, dex_data[1], dex_data[2]
          break
        end
      end
    end
    return special_form, check_form, check_item
  end
  
  #-----------------------------------------------------------------------------
  # Dibuja la página de datos.
  #-----------------------------------------------------------------------------
  def drawPageData
    base    = Color.new(248, 248, 248)
    shadow  = Color.new(72, 72, 72)
    path = Settings::POKEDEX_DATA_PAGE_GRAPHICS_PATH
    overlay = @sprites["overlay"].bitmap
    imagepos = []
    textpos = []
    owned = $player.owned?(@species)
    species_data = GameData::Species.get_species_form(@species, @form)
    pbGenerateDataLists(species_data)
    @sprites["itemicon"].item = (owned && !@data_hash[:item].empty?) ? @data_hash[:item].values.last.last : nil
    pbDrawDataNotes(:encounter)
    #---------------------------------------------------------------------------
    # Dibuja el nombre y el tipo de especie.
    #---------------------------------------------------------------------------
    textpos.push([species_data.name, 84,  56, :left, base, Color.black, :outline])
    if owned
      species_data.types.each_with_index do |type, i|
        type_number = GameData::Type.get(type).icon_position
        type_rect = Rect.new(0, type_number * 32, 96, 32)
        type_x = (species_data.types.length == 1) ? 347 : 298 + (100 * i)
        overlay.blt(type_x, 48, @typebitmap.bitmap, type_rect)
      end
    end
    #---------------------------------------------------------------------------
    # Dibuja los iconos de género.
    #---------------------------------------------------------------------------
    case species_data.gender_ratio
    when :AlwaysMale   then gender = [1, 0]
    when :AlwaysFemale then gender = [0, 1]
    when :Genderless   then gender = [0, 0]
    else
      if owned && !gender_difference?(@form)
        gender = [1, 1]
      else
        gender = (@gender == 0) ? [1, 0] : [0, 1]
      end
    end
    imagepos.push([path + "gender", 10, 48, 32 * gender[0],  0, 32, 32],
                  [path + "gender", 44, 48, 32 * gender[1], 32, 32, 32])
    #---------------------------------------------------------------------------
    # Dibuja el icono de la forma del cuerpo del pokemon
    #---------------------------------------------------------------------------
    shape = GameData::BodyShape.get(species_data.shape).icon_position
    imagepos.push(["Graphics/UI/Pokedex/icon_shapes", 420, 170, 0, 60 * shape, 60, 60])
    #---------------------------------------------------------------------------
    # Dibuja los iconos de los grupos de huevos.
    #---------------------------------------------------------------------------
    if owned
      egg_groups = species_data.egg_groups
      egg_groups = [:None] if species_data.gender_ratio == :Genderless && 
                              !(egg_groups.include?(:Ditto) || egg_groups.include?(:Undiscovered))
    else
      egg_groups = [:None]
    end
    rectX = (Settings::ALT_EGG_GROUP_NAMES) ? 62 : 0
    egg_groups.each_with_index do |group, i|
      rectY = GameData::EggGroup.get(group).icon_position
      group_y = (egg_groups.length == 1) ? 188 : 172 + 30 * i
      imagepos.push([path + "egg_groups", 338, group_y, rectX, 28 * rectY, 62, 28])
    end
    #---------------------------------------------------------------------------
    # Dibuja el texto y las barras de estadísticas base.
    #---------------------------------------------------------------------------
    textpos.push(
      [_INTL("PS"),        12, 104, :left, base, shadow, :outline],
      [_INTL("Ataque"),    12, 132, :left, base, shadow, :outline],
      [_INTL("Defensa"),   12, 160, :left, base, shadow, :outline],
      [_INTL("At. Esp."),  12, 188, :left, base, shadow, :outline],
      [_INTL("Df. Esp."),  12, 216, :left, base, shadow, :outline],
      [_INTL("Velocid."),  12, 244, :left, base, shadow, :outline]
    )
    stats_order = [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED]
    if owned
      stats_order.each_with_index do |s, i|
        stat = species_data.base_stats[s]
        w = stat * 100 / 254.0
        w = 1 if w < 1
        w = ((w / 2).round) * 2
        imagepos.push([path + "overlay_stats", 106, 105 + i * 28, 0, i * 18, w, 18])
      end
    end
    #---------------------------------------------------------------------------
    # Draws Ability/Move button text.
    #---------------------------------------------------------------------------
    textpos.push([_INTL("Habilid."), 306, 253, :center, base, shadow, :outline],
                 [_INTL("Movimien."),434, 253, :center, base, shadow, :outline])			  
    #---------------------------------------------------------------------------
    # Sets up sprites for family data.
    #---------------------------------------------------------------------------
    special_form, check_form, _check_item = pbGetSpecialFormData(species_data)
    if special_form
      imagepos.push([path + "evolutions", 234, ICONS_POS_Y - 34, 0, 64, 272, 64])
      case special_form
      when :mega        then imagepos.push(["Graphics/UI/Battle/icon_mega", 259, 49])
      when :primal      then imagepos.push(["Graphics/UI/Battle/icon_primal_#{species_data.name}", 256, 47])
      when :ultra       then imagepos.push([Settings::ZMOVE_GRAPHICS_PATH + "icon_ultra", 257, 47])
      when :gmax, :emax then imagepos.push([Settings::DYNAMAX_GRAPHICS_PATH + "icon_dynamax", 256, 47])
      when :tera
        species_data.flags.each do |flag|
          next if !flag[/^TeraType_(\w+)/i]
          pos = GameData::Type.get($~[1].to_sym).icon_position
          imagepos.push([Settings::TERASTAL_GRAPHICS_PATH + "tera_types", 257, 47, 0, pos * 32, 32, 32])
          break
        end
      end
      @sprites["familyicon0"].pbSetParams(@species, @gender, @form)
      @sprites["familyicon0"].x = ICONS_RIGHT_DOUBLE
      @sprites["familyicon0"].visible = true
      @sprites["familyicon1"].pbSetParams(@species, @gender, check_form)
      @sprites["familyicon1"].x = ICONS_LEFT_DOUBLE
      @sprites["familyicon1"].visible = true
      @sprites["familyicon2"].visible = false
    else
      prevo = species_data.get_previous_species
      prevo = species_data.species if species_data.id == :FLOETTE_5
      if prevo != species_data.species
        form = (species_data.default_form >= 0) ? species_data.default_form : @form
        prevo_data = GameData::Species.get_species_form(prevo, form)
        stages = (species_data.get_baby_species == prevo) ? 1 : 2
        imagepos.push([path + "evolutions", 234, ICONS_POS_Y - 34, 0, 64 * stages, 272, 64])
        @sprites["familyicon0"].pbSetParams(@species, @gender, @form)
        @sprites["familyicon0"].x = (stages == 1) ? ICONS_RIGHT_DOUBLE : ICONS_RIGHT_TRIPLE
        @sprites["familyicon0"].visible = true
        if $player.seen?(prevo)
          @sprites["familyicon1"].pbSetParams(prevo, @gender, prevo_data.form)
        else
          @sprites["familyicon1"].species = nil
        end
        @sprites["familyicon1"].x = (stages == 1) ? ICONS_LEFT_DOUBLE : ICONS_CENTER
        @sprites["familyicon1"].visible = true
        if stages == 2
          baby = species_data.get_baby_species
          baby_data = GameData::Species.get_species_form(baby, prevo_data.form)
          if $player.seen?(baby)
            @sprites["familyicon2"].pbSetParams(baby, @gender, baby_data.form)
          else
            @sprites["familyicon2"].species = nil
          end
          @sprites["familyicon2"].x = ICONS_LEFT_TRIPLE
          @sprites["familyicon2"].visible = true
        else
          @sprites["familyicon2"].visible = false
        end
      else
        imagepos.push([path + "evolutions", 234, ICONS_POS_Y - 34, 0, 0, 272, 64])
        @sprites["familyicon0"].pbSetParams(@species, @gender, @form)
        @sprites["familyicon0"].x = ICONS_CENTER
        @sprites["familyicon0"].visible = true
        @sprites["familyicon1"].visible = false
        @sprites["familyicon2"].visible = false
      end
    end
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
  end
end