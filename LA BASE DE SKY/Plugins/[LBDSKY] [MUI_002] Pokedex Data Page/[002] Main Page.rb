#===============================================================================
# Main Data Page display
#===============================================================================
class PokemonPokedexInfo_Scene 
  #-----------------------------------------------------------------------------
  # Controls for navigating the Data page.
  #-----------------------------------------------------------------------------
  def pbDataPageMenu
    pbPlayDecisionSE
    pbDrawDataNotes
    species = GameData::Species.get_species_form(@species, @form).id
    loop do
      Graphics.update
      Input.update
      pbUpdate
      #-------------------------------------------------------------------------
      if Input.trigger?(Input::BACK)
        pbPlayCancelSE
        @sprites["data_overlay"].bitmap.clear
        break
      #-------------------------------------------------------------------------
      elsif Input.trigger?(Input::USE)
        case @cursor
        #-----------------------------------------------------------------------
        # Displays move lists.
        when :moves
          next if !$player.owned?(species)
          pbChooseMove
        #-----------------------------------------------------------------------
        # Displays item/ability lists.
        when :item, :ability
          next if !$player.owned?(species)
          pbChooseDataList
        #-----------------------------------------------------------------------
        # Displays compatible species lists.
        when :general, :family, :stats, :habitat, :egg, :shape
          next if !$player.owned?(species)
          pbChooseSpeciesDataList
        end
        break if @forceRefresh
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::UP)
        old_cursor = @cursor
        case @cursor
        when :general then @cursor = :ability
        when :stats   then @cursor = :general
        when :family  then @cursor = :general
        when :habitat then @cursor = :family
        when :shape   then @cursor = :family
        when :egg     then @cursor = :family
        when :item    then @cursor = :family
        when :ability then @cursor = :egg
        when :moves   then @cursor = :habitat
        end
        if @cursor != old_cursor
          pbPlayCursorSE
          pbDrawDataNotes
        end
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::DOWN)
        old_cursor = @cursor
        case @cursor
        when :general then @cursor = :family
        when :stats   then @cursor = :general
        when :family  then @cursor = :habitat
        when :habitat then @cursor = :moves
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
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::LEFT)
        old_cursor = @cursor
        case @cursor
        when :general then @cursor = :general
        when :stats   then @cursor = :habitat
        when :family  then @cursor = :stats
        when :habitat then @cursor = :shape
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
      #-------------------------------------------------------------------------
      elsif Input.repeat?(Input::RIGHT)
        old_cursor = @cursor
        case @cursor
        when :general then @cursor = :general
        when :stats   then @cursor = :item
        when :family  then @cursor = :stats
        when :habitat then @cursor = :stats
        when :shape   then @cursor = :habitat
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
    @forceRefresh = false
    drawPage(@page)
  end
  
  #-----------------------------------------------------------------------------
  # Utility for generating lists of data related to a viewed species.
  #-----------------------------------------------------------------------------
  def pbGenerateDataLists(species)
    @data_hash = {
	  :species => species.id,
      :general => [],
      :habitat => [],
      :shape   => [],
      :stats   => [],
      :egg     => [],
      :family  => []
    }
    #---------------------------------------------------------------------------
    # Determines if this species should display species in compatible Egg Groups.
    #---------------------------------------------------------------------------
    eggSpecies = species
    showCompatible = true
    if species.egg_groups.include?(:Undiscovered)
      evos = species.get_evolutions(true)
      if evos.empty?
        showCompatible = false
      else
        evo = GameData::Species.get(evos[0][0])
        if !evo.egg_groups.include?(:Undiscovered)
          eggSpecies = evo
        else
          showCompatible = false
        end
      end
    end
    #---------------------------------------------------------------------------
    # Sorts all owned species into compatibility lists.
    #---------------------------------------------------------------------------
    family = species.get_family_species
    family_evos_temp = species.get_evolutions
    family_evos = []
    for i in family_evos_temp
      family_evos << (i[0])
    end
    blacklisted = [:PICHU_2, :FLOETTE_5, :GIMMIGHOUL_1].include?(species.id) ||
                  species.species == :PIKACHU && (8..15).include?(species.form)
    GameData::Species.each do |sp|

      # Family members.
      next if blacklisted
      ## NO LO HAS VISTO
      if sp.display_species?(@dexlist, species)
        if family.include?(sp.species)
          if sp.species == species.species
            special_form, _check_form, _check_item = pbGetSpecialFormData(sp)
            next if !special_form
          end
          @data_hash[:family] << sp.id
        end
      elsif sp.display_species?(@dexlist, species, false, true)
          if family.include?(sp.species)
            if sp.species == species.species
              special_form, _check_form, _check_item = pbGetSpecialFormData(sp)
              next if !special_form
            end
            @data_hash[:family] << sp.id
          end
      end
      #-------------------------------------------------------------------------
      next if !sp.display_species?(@dexlist, species)
      regional_form = sp.form > 0 && sp.is_regional_form?
      base_form = (sp.form > 0) ? GameData::Species.get_species_form(sp.species, sp.base_pokedex_form) : nil
      #-------------------------------------------------------------------------
      # Compatible gender ratio.
      if sp.gender_ratio == species.gender_ratio
        skipForm = base_form && !regional_form && sp.gender_ratio == base_form.gender_ratio
        @data_hash[:general] << sp.id if !skipForm
      end
      #-------------------------------------------------------------------------
      # Compatible habitat.
      if sp.habitat == species.habitat
        skipForm = base_form && !regional_form && sp.habitat == base_form.habitat
        @data_hash[:habitat] << sp.id if !skipForm
      end
      #-------------------------------------------------------------------------
      # Compatible shape & color.
      if sp.color == species.color && sp.shape == species.shape
        skipForm = base_form && !regional_form && sp.color == base_form.color && sp.shape == base_form.shape
        @data_hash[:shape] << sp.id if !skipForm
      end
      #-------------------------------------------------------------------------
      # Compatible base stats.
      if !base_form || regional_form || base_form && sp.base_stats != base_form.base_stats
        GameData::Stat.each_main do |s|
          next if sp.base_stats[s.id] != species.base_stats[s.id]
          @data_hash[:stats] << sp.id
          break
        end
      end
      #-------------------------------------------------------------------------
      # Family members.
      next if blacklisted
      if family.include?(sp.species)
        if sp.species == species.species
          special_form, _check_form, _check_item = pbGetSpecialFormData(sp)
          next if !special_form
        end
        @data_hash[:family] << sp.id
      end
      #-------------------------------------------------------------------------
      # Compatible egg groups.
      if showCompatible
        if base_form && !regional_form && sp.egg_groups == base_form.egg_groups
          next if sp.moves == base_form.moves && sp.tutor_moves == base_form.tutor_moves
        end
        sp.egg_groups.each do |group|
          case group
          when :Ditto
            next if eggSpecies.egg_groups.include?(:Ditto)
            next if eggSpecies.egg_groups.include?(:Undiscovered)
            @data_hash[:egg] << sp.id
          else
            next if eggSpecies.egg_groups.include?(:Undiscovered)
            if eggSpecies.egg_groups.include?(:Ditto)
              next if sp.egg_groups.include?(:Ditto)
              next if sp.egg_groups.include?(:Undiscovered)
              @data_hash[:egg] << sp.id
            elsif eggSpecies.egg_groups.include?(group)
              next if eggSpecies.gender_ratio == :Genderless
              gender = sp.gender_ratio
              next if gender == :Genderless
              next if [:AlwaysMale, :AlwaysFemale].include?(gender) && gender == eggSpecies.gender_ratio
              @data_hash[:egg] << sp.id 
            end
          end
        end
      end
    end
    @data_hash.each_key do |key|
	  next if key == :species
      list = @data_hash[key].clone
      if key == :family
        sortlist = species.get_family_species
        @data_hash[key] = pbSortDataList(list, sortlist)
      else
        @data_hash[key] = pbSortDataList(list)
      end
    end
    #---------------------------------------------------------------------------
    # Generates list of this species' abilities.
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
    # Generates list of this species' wild held items.
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
  end
  
  #-----------------------------------------------------------------------------
  # Utility for sorting all generated species lists in Pokedex order.
  #-----------------------------------------------------------------------------
  def pbSortDataList(list, sortlist = nil)
    newSort = []
    sortlist = @dexlist if sortlist.nil?
    list.each do |id|
      sp = GameData::Species.get(id).species
      sortlist.each_with_index do |dex, i|
        species = (dex.is_a?(Hash)) ? dex[:species] : dex
        if species == sp
          newSort[i] = [] if !newSort[i]
          newSort[i].push(id)
          break
        end
      end
    end
    newSort.compact!
    newSort.flatten!
    newSort.uniq!
    return newSort
  end
  
  #-----------------------------------------------------------------------------
  # Utility for getting data related to special forms, such as Mega Evolutions.
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
  # Draws the data page.
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
    pbGenerateDataLists(species_data) if @data_hash[:species] != species_data.id
    @sprites["itemicon"].item = (owned && !@data_hash[:item].empty?) ? @data_hash[:item].values.last.last : nil
    @gender = 1 if species_data.gender_ratio == :AlwaysFemale || species_data.form_name == _INTL("Female")
    pbDrawDataNotes(:encounter)
    #---------------------------------------------------------------------------
    # Draws species name & typing.
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
    # Draws gender icons.
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
    # Draws habitat icon.
    #---------------------------------------------------------------------------
    habitat = (owned) ? GameData::Habitat.get(species_data.habitat).icon_position : 0
    imagepos.push([path + "habitats", 445, 174, 0, 48 * habitat, 64, 48])
    #---------------------------------------------------------------------------
    # Draws body shape icon.
    #---------------------------------------------------------------------------
    shape = GameData::BodyShape.get(species_data.shape).icon_position
    imagepos.push(["Graphics/UI/Pokedex/icon_shapes", 375, 170, 0, 60 * shape, 60, 60])
    #---------------------------------------------------------------------------
    # Draws egg group icons.
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
      imagepos.push([path + "egg_groups", 302, group_y, rectX, 28 * rectY, 62, 28])
    end
    #---------------------------------------------------------------------------
    # Draws the base stats text and bars.
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
    # Sets up sprites if the species is a special form.
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
      #-------------------------------------------------------------------------
      # Sets up sprites if the species is a single-stage species.
      #-------------------------------------------------------------------------
      prevo = species_data.get_previous_species
      if prevo == species_data.species || @data_hash[:family].empty?
        imagepos.push([path + "evolutions", 234, ICONS_POS_Y - 34, 0, 0, 272, 64])
        @sprites["familyicon0"].pbSetParams(@species, @gender, @form)
        @sprites["familyicon0"].x = ICONS_CENTER
        @sprites["familyicon0"].visible = true
        @sprites["familyicon1"].visible = false
        @sprites["familyicon2"].visible = false
      #-------------------------------------------------------------------------
      # Sets up sprites if the species has multiple stages.
      #-------------------------------------------------------------------------
      else
        form = (species_data.default_form >= 0) ? species_data.default_form : @form
        prevo_data = GameData::Species.get_species_form(prevo, form)
        stages = (species_data.get_baby_species == prevo) ? 1 : 2
        imagepos.push([path + "evolutions", 234, ICONS_POS_Y - 34, 0, 64 * stages, 272, 64])
        @sprites["familyicon0"].pbSetParams(@species, @gender, @form)
        @sprites["familyicon0"].x = (stages == 1) ? ICONS_RIGHT_DOUBLE : ICONS_RIGHT_TRIPLE
        @sprites["familyicon0"].visible = true
        if $player.seen?(prevo)
          @sprites["familyicon1"].pbSetParams(prevo, @gender, prevo_data.form)
          @sprites["familyicon1"].tone = Tone.new(0,0,0,0)
        else
          @sprites["familyicon1"].pbSetParams(prevo, @gender, prevo_data.form)
          @sprites["familyicon1"].tone = Tone.new(-255,-255,-255,0)
          # @sprites["familyicon1"].species = nil
        end
        @sprites["familyicon1"].x = (stages == 1) ? ICONS_LEFT_DOUBLE : ICONS_CENTER
        @sprites["familyicon1"].visible = true
        if stages == 2
          baby = species_data.get_baby_species
          baby_data = GameData::Species.get_species_form(baby, prevo_data.form)
          if $player.seen?(baby)
            @sprites["familyicon2"].pbSetParams(baby, @gender, baby_data.form)
            @sprites["familyicon2"].tone = Tone.new(0,0,0,0)
          else
            @sprites["familyicon2"].pbSetParams(baby, @gender, baby_data.form)
            @sprites["familyicon2"].tone = Tone.new(-255,-255,-255,0)
            # @sprites["familyicon2"].species = nil
          end
          @sprites["familyicon2"].x = ICONS_LEFT_TRIPLE
          @sprites["familyicon2"].visible = true
        else
          @sprites["familyicon2"].visible = false
        end
      end
    end
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
  end
end