#===============================================================================
# Related to displaying various text in the message box of the Data page.
#===============================================================================
class PokemonPokedexInfo_Scene
  #-----------------------------------------------------------------------------
  # Draws the relevant text relative to the cursor position.
  #-----------------------------------------------------------------------------
  def pbDrawDataNotes(cursor = nil)
    t = DATA_TEXT_TAGS
    cursor = @cursor if !cursor
    path = Settings::POKEDEX_DATA_PAGE_GRAPHICS_PATH + "cursor"
    species = GameData::Species.get_species_form(@species, @form)
    overlay = @sprites["data_overlay"].bitmap
    overlay.clear
    case cursor
    when :encounter then text = pbDataTextEncounters(path, species, overlay)
    when :general   then text = pbDataTextGeneral(path, species, overlay)
    when :stats     then text = pbDataTextStats(path, species, overlay)
    when :family    then text = pbDataTextFamily(path, species, overlay)
    when :habitat   then text = pbDataTextHabitat(path, species, overlay)
    when :shape     then text = pbDataTextShape(path, species, overlay)
    when :egg       then text = pbDataTextEggGroup(path, species, overlay)
    when :item      then text = pbDataTextItems(path, species, overlay)
    when :ability
      pbDrawImagePositions(overlay, [[path, 248, 240, 0, 244, 116, 44]])
      text = t[0] + _INTL("Habilidades\n")
      if $player.owned?(@species)
        text << _INTL("Ver todas las habilidades de esta especie.")
      else
        text << _INTL("Desconocido.")
      end
    when :moves
      pbDrawImagePositions(overlay, [[path, 376, 240, 0, 244, 116, 44]])
      text = t[0] + _INTL("Movimientos\n")
      if $player.owned?(@species)
        text << _INTL("Ver todos los movimientos que esta especie puede aprender.")
      else
        text << _INTL("Desconocido.")
      end
    end
    drawFormattedTextEx(overlay, 34, 294, 446, _INTL("{1}", text))
  end
  
  
  ##############################################################################
  #
  # These methods draw text when the cursor is highlighting a selection.
  #
  ##############################################################################
  
  
  #=============================================================================
  # Determines the encounter text to display. (Cursor == :encounter)
  #=============================================================================
  def pbDataTextEncounters(path, species, overlay)
    t = DATA_TEXT_TAGS
    text = t[0] + _INTL("Encuentros:\n")
    text << _INTL("Derrotados: ") + "#{$player.pokedex.defeated_count(species.id)}\n"
    text << _INTL("Capturados: ") + "#{$player.pokedex.caught_count(species.id)}\n"
    return text
  end
  
  #=============================================================================
  # Determines the general text to display. (Cursor == :general)
  #=============================================================================
  def pbDataTextGeneral(path, species, overlay, inMenu = false)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 0, 36, 0, 0, 512, 56]])
    owned = $player.owned?(@species)
    text = t[0] + _INTL("Estadísticas Generales:\n")
    if owned
      chance = species.catch_rate
      c = ((chance / 256.0) * 100).floor
      c = 1 if c < 1
      text << _INTL("Ratio de Captura: {1}%\n", c)
      gender = _INTL("Prob. de género: ")
      case species.gender_ratio
      when :AlwaysMale   then gender << t[2] + _INTL("100% Macho")
      when :AlwaysFemale then gender << t[1] + _INTL("100% Hembra")
      when :Genderless   then gender << _INTL("sin género")
      else
        chance = GameData::GenderRatio.get(species.gender_ratio).female_chance
        if chance
          f = ((chance / 256.0) * 100).round
          m = (100 - f)
          #if m > f      # Male odds are higher than female.
          #  gender << t[2] + "#{m.to_s}% Macho"
          #elsif f > m   # Female odds are higher than male.
          #  gender << + t[1] + "#{f.to_s}% Hembra"
          #else          # Gender odds are equal.
          #  gender << "has an equal gender ratio"
          #end
          gender << _INTL("{1}{2}% Macho{3}, {4}{5}% Hembra", t[2], m, t[0], t[1], f)
        else
          gender = ""
        end
      end
      text << gender + t[0] + "." if gender != ""
      pbDrawTextPositions(overlay, [
        [_INTL("Ver relacionados"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
      ]) if !inMenu && !@data_hash[:general].empty?
    else
      text << _INTL("Desconocido.")
    end
    return text
  end
  
  #=============================================================================
  # Determines the wild held item text to display. (Cursor == :item)
  #=============================================================================
  def pbDataTextItems(path, species, overlay)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 224, 166, 432, 208, 74, 72]])
    owned = $player.owned?(@species)
    text = ""
    if owned
      @data_hash[:item].keys.each_with_index do |r, a|
        next if @data_hash[:item][r].empty?
        text << ", " if !nil_or_empty?(text)
        @data_hash[:item][r].each_with_index do |item, i|
          text << t[1] + GameData::Item.get(item).name + t[0]
          text << ", " if i < @data_hash[:item][r].length - 1
        end
      end
      if nil_or_empty?(text)
        text << "---" 
      else
        pbDrawTextPositions(overlay, [
          [_INTL("Más información"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
        ])
      end
    else
      text << _INTL("Desconocido.")
    end
    text = t[0] + _INTL("Objetos\n") + text
    return text
  end
  
  #=============================================================================
  # Determines the base stat text to display. (Cursor == :stats)
  #=============================================================================
  def pbDataTextStats(path, species, overlay, s2 = nil)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 0, 90, 0, 56, 222, 188]])
    owned = $player.owned?(@species)
    text = t[0] + _INTL("Estadísticas") 
    if owned
      nt = (s2 && s2.base_stat_total == species.base_stat_total) ? t[2] : t[1]
      text << " - " + nt + _ISPRINTF("Total: {1:3d}", species.base_stat_total)
      s1 = species.base_stats
      @api_data = PokeAPI.get_data(species) if !s2 && !@api_data && Settings::SHOW_STAT_CHANGES_WITH_POKEAPI
      s2 = s2.base_stats if s2
      stats_order = [[:HP, :SPECIAL_ATTACK], [:ATTACK, :SPECIAL_DEFENSE], [:DEFENSE, :SPEED]]
      stats_order.each_with_index do |st, i|
        names = values = ""
        st.each_with_index do |s, j|
          stat = (s == :SPECIAL_ATTACK) ? _INTL("At. Esp.") : (s == :SPECIAL_DEFENSE) ? _INTL("Def. Esp.") : GameData::Stat.get(s).name
          nt = (s2 && s2[s] == s1[s]) ? t[2] : t[0]
          names  += nt + _INTL("{1}", stat)
          if !s2 && @api_data
            case
            when s1[s] > @api_data["stats"][s]
              color = t[3]
            when s1[s] < @api_data["stats"][s]
              color = t[1]
            else
              color = t[0]
            end
            values += color + _ISPRINTF("{1:3d}", s1[s])
          else
            values += nt + _ISPRINTF("{1:3d}", s1[s])
          end
          names  += "\n" if j == 0
          values += "\n" if j == 0
        end
        nameX = 34 + 152 * i
        valueX = nameX + 100
        drawFormattedTextEx(overlay, nameX, 324, 76+16, _INTL("{1}", names))
        drawFormattedTextEx(overlay, valueX, 324, 52, _INTL("{1}", values))
      end
      pbDrawTextPositions(overlay, [
        [_INTL("[D]: Cambios"), Graphics.width/2-13, 292, :center, Color.new(0, 112, 248), Color.new(120, 184, 232)]
      ]) if Settings::SHOW_STAT_CHANGES_WITH_POKEAPI
      pbDrawTextPositions(overlay, [
        [_INTL("[C]: Similares"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
      ]) if !s2 && !@data_hash[:stats].empty?
    else
      text << _INTL("\nDesconocido.")
    end
    return text
  end
  
  #=============================================================================
  # Determines the habitat text to display. (Cursor == :habitat)
  #=============================================================================
  def pbDataTextHabitat(path, species, overlay, s2 = nil)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 440, 166, 432, 208, 74, 72]])
    owned = $player.owned?(@species)
    text = t[0] + _INTL("Hábitat\n")
    if owned
      habitat = GameData::Habitat.get(species.habitat)
      nt = (s2 && s2 == habitat.id) ? t[2] : t[1]
      name = habitat.name.downcase
      case habitat.id
      when :Grassland
        text << _INTL("Esta especie se puede encontrar correteando por zonas de {1}{2}{3}.", nt, name, t[0])
      when :Forest
        text << _INTL("Esta especie se puede encontrar en zonas densas de {1}{2}{3}.", nt, name, t[0])
      when :WatersEdge
        text << _INTL("Esta especie se puede encontrar cerca de zonas de {1}{2}{3}.", nt, name, t[0])
      when :Sea
        text << _INTL("Esta especie se puede encontrar en zonas de {1}{2}{3}.", nt, name, t[0])
      when :Cave
        text << _INTL("Esta especie se puede encontrar en zonas de {1}{2}{3}.", nt, name, t[0])
      when :Mountain
        text << _INTL("Esta especie se puede encontrar en zonas escarpadas de {1}{2}{3}.", nt, name, t[0])
      when :RoughTerrain
        text << _INTL("Esta especie se puede encontrar en zonas de {1}{2}{3}.", nt, name, t[0])
      when :Urban
        text << _INTL("Esta especie se puede encontrar cerca de estructuras creadas por humanos o de {1}{2}{3}.", nt, name, t[0])
      when :Rare
        text << _INTL("Esta especie se puede encontrar en lugares bastante {1}{2}{3}.", nt, name, t[0])
      else
        text << _INTL("Esta especie se puede encontrar en sitios desconocidos.")
      end     
      pbDrawTextPositions(overlay, [
        [_INTL("Ver relacionados"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
      ]) if !s2 && !@data_hash[:habitat].empty?
    else
      text << _INTL("Desconocido.")
    end
    return text
  end
  
  #=============================================================================
  # Determines the body color & shape text to display. (Cursor == :shape)
  #=============================================================================
  def pbDataTextShape(path, species, overlay, s2 = nil)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 368, 166, 432, 208, 74, 72]])
    text = t[0] + _INTL("Morfología\n")
    color = GameData::BodyColor.get(species.color)
    nt = (s2 && s2[0] == color.id) ? t[2] : t[1]
    name = color.name.downcase
    text << _INTL("El color principal de la especie es el {1}{2}{3}. ", nt, name, t[0])
    shape = GameData::BodyShape.get(species.shape)
    nt = (s2 && s2[1] == shape.id) ? t[2] : t[1]
    name = shape.name.downcase
    case shape.id
    when :Head, :Serpentine, :Finned, :HeadArms, :HeadBase, :Winged, :Multiped, :MultiBody, :MultiWinged
      text << _INTL("Tiene forma de {1}{2}{3}.", nt, name, t[0])
    when :Bipedal, :BipedalTail, :HeadLegs,  :Quadruped, :Insectoid
      text << _INTL("Tiene forma {1}{2}{3}.", nt, name, t[0])
    else
      text << _INTL("La forma no puede ser clasificada.")
    end
    if !s2 && $player.owned?(@species) && !@data_hash[:shape].empty?
      pbDrawTextPositions(overlay, [
        [_INTL("Ver Pokémon similares"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
      ])
    end
    return text
  end
  
  #=============================================================================
  # Determines the egg group text to display. (Cursor == :egg)
  #=============================================================================
  def pbDataTextEggGroup(path, species, overlay, s2 = nil)
    return pbDataTextMoveSource(path, species, overlay) if @viewingMoves
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 296, 166, 432, 208, 74, 72]])
    owned = $player.owned?(@species)
    text = t[0] + _INTL("Crianza\n")
    if owned
      text << _INTL("Especie ")
      groups = species.egg_groups
      groups = [:None] if species.gender_ratio == :Genderless && 
                          !(groups.include?(:Ditto) || groups.include?(:Undiscovered))
      if groups.include?(:None)
        data = GameData::EggGroup.get(:Ditto)
        name = (Settings::ALT_EGG_GROUP_NAMES) ? data.alt_name : data.name
        text << _INTL("sin género, solo compatible con el grupo {1}{2}{3}.", t[1], name, t[0])
      elsif groups.include?(:Ditto)
        data = GameData::EggGroup.get(:Ditto)
        name = (Settings::ALT_EGG_GROUP_NAMES) ? data.alt_name : data.name
        text << _INTL("en el grupo {1}{2}{3}, compatible con todos salvo Desconocido.", t[1], name, t[0])
      elsif groups.include?(:Undiscovered) || groups.empty?
        data = GameData::EggGroup.get(:Undiscovered)
        name = (Settings::ALT_EGG_GROUP_NAMES) ? data.alt_name : data.name
        text << _INTL("en el grupo {1}{2}{3}, no puede ser criado.", t[1], name, t[0])
      else
        size_groups_sky = 0
        groups.each_with_index do |group, i|
          size_groups_sky+=1
        end
        if size_groups_sky == 2
          text << _INTL("compatible con los grupos ")
        else
          text << _INTL("compatible con el grupo ")
        end
        groups.each_with_index do |group, i|
          data = GameData::EggGroup.get(group)
          name = (Settings::ALT_EGG_GROUP_NAMES) ? data.alt_name : data.name
          nt = (s2 && s2.include?(group)) ? t[2] : t[1]
          text << nt + "#{name}" + t[0]
          if i < groups.length - 1
            text << _INTL(" y ")
          else
            text << "."
          end
        end
      end
      pbDrawTextPositions(overlay, [
        [_INTL("Ver Pokémon compatibles"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
      ]) if !s2 && !@data_hash[:egg].empty?
    else
      text << _INTL("Desconocido.")
    end
    return text
  end
  
  #=============================================================================
  # Determines the family & evolution method text to display. (Cursor == :family)
  #=============================================================================
  def pbDataTextFamily(path, species, overlay, inMenu = false)
    t = DATA_TEXT_TAGS
    #---------------------------------------------------------------------------
    # Determines how many species icons to draw.
    #---------------------------------------------------------------------------
    if @sprites["familyicon1"].visible && @sprites["familyicon2"].visible
      pbDrawImagePositions(overlay, [[path, 228, 90, 222, 56, 284, 76]])
    elsif @sprites["familyicon1"].visible
      pbDrawImagePositions(overlay, [[path, 280, 90, 222, 132, 180, 76]])
    else
      pbDrawImagePositions(overlay, [[path, 332, 90, 402, 132, 76, 76]])
    end
    text = pbDrawSpecialFormText(species) # If this species is a special form.
    if nil_or_empty?(text)
      prevo = species.get_previous_species
      #-------------------------------------------------------------------------
      # These unique forms are treated as if they have no family trees.
      #-------------------------------------------------------------------------
      if [:PICHU_2, :FLOETTE_5, :GIMMIGHOUL_1].include?(species.id) ||
         species.species == :PIKACHU && (8..15).include?(species.form)
        prevo = species.species
      end
      #-------------------------------------------------------------------------
      # When the species is the base species in a family tree.
      #-------------------------------------------------------------------------
      if prevo == species.species
        text = t[0] + _INTL("Ramas evolutivas\n")
        # Updated
        family_ids = []
        evos = species.get_evolutions
        evos.each do |evo|
          next if family_ids.include?(evo[0]) || evo[1] == :None
          family_ids.push(evo[0])
          species.branch_evolution_forms.each do |form|
            try_species = GameData::Species.get_species_form(evo[0], form)
            try_evos = try_species.get_evolutions
            next if try_evos.empty?
            try_evos.each do |try_evo|
              next if family_ids.include?(try_evo[0]) || try_evo[1] == :None
              family_ids.push(try_evo[0])
            end
          end
        end
        if family_ids.empty?          # Species doesn't evolve.
          text << _INTL("No evoluciona.")
        else                          # Species does evolve.
          family_ids.each_with_index do |fam, i|  
            name = GameData::Species.get(fam).name
            text << t[1] + name
            if i < family_ids.length - 1
              if fam == GameData::Species.get(family_ids[i + 1]).get_previous_species
                text << t[0] + "=> "  # Shows evolution pathway.
              else
                text << t[0] + ", "   # Shows a new pathway.
              end				
            end
          end
        end
      #-------------------------------------------------------------------------
      # When the species is an evolved species.
      #-------------------------------------------------------------------------
      else
        #-----------------------------------------------------------------------
        # Compiles the actual description for this species' evolution method.
        # Some species require special treatment due to unique evolution traits.
        #-----------------------------------------------------------------------
        form = (species.default_form >= 0) ? species.default_form : species.form
        prevo_data = GameData::Species.get_species_form(prevo, form)
        if species.species == :ALCREMIE
          name = t[1] + "#{prevo_data.name}" + t[0]
          text = _INTL("{1}Usar varios {2}Confites{3} en {4}.", t[0], t[2], t[0], name)
        else
          text = ""
          index = 0
          
          evolutions = prevo_data.get_evolutions(true)
          # First, check if there are any form-specific evolution methods for this species
          has_form_evos = evolutions.any? do |evo|
            evo[0] == species.species && evo[1].to_s.include?("Form") && evo[1].to_s =~ /Form(\d+)$/
          end
          
          evolutions = evolutions.select do |evo|
            next false if evo[0] != species.species || evo[1] == :None
            # Check if evolution method has a Form number
            if evo[1].to_s.include?("Form") && evo[1].to_s =~ /Form(\d+)$/
              form_number = $1.to_i
              next form_number == species.form
            end
            # If there are form-specific evolutions and this is not form 0, exclude non-form evolutions
            next false if has_form_evos && species.form > 0
            true
          end

          count = evolutions.length
          evolutions.each do |evo|
            next if evo[0] != species.species
            next if evo[1] == :None
            if species.species == :URSHIFU && evo[1] == :Item
              next if evo[2] != [:SCROLLOFDARKNESS, :SCROLLOFWATERS][species.form]
            end
            spec = prevo_data.id #($player.seen?(prevo_data.id)) ? prevo_data.id : nil
            data = GameData::Evolution.get(evo[1])
            # Add appropriate separator based on number of evolution methods
            if !nil_or_empty?(text)
              if count == 2
                text << _INTL(" o ")
              elsif count > 2
                if index == count - 1
                  text << _INTL(" o ")
                else
                  text << ", "
                end
              end
            end
            text << data.description(spec, evo[0], evo[2], nil_or_empty?(text), true, t)
            break if index > 0
            index += 1
          end
          case species.species
          when :LYCANROC
            case species.form
            when 0 then text += _INTL(" Tiene que ser de día para esta forma.")
            when 1 then text += _INTL(" Tiene que ser de noche para esta forma.")
            when 2 then text += _INTL(" Requiere {1}{2}{3}.", t[2], GameData::Ability.get(:OWNTEMPO).name, t[0])
            end
          when :TOXTRICITY
            text += _INTL(" Forma depende de su {1}Naturaleza{2}.", t[2], t[0])
          end
        end
        #-----------------------------------------------------------------------
        # Determines what should be displayed as the "heading" in the message box.
        #-----------------------------------------------------------------------
        heading = ""
        if species.form_name
          Settings::REGIONAL_NAMES.each do |region|
            next if !species.form_name.include?(region)
            heading = _INTL("{1}{2} Evolución\n", t[0], region)
          end
        end
        if nil_or_empty?(heading)
          evos = species.evolutions
          if inMenu && evos[-1][0] == prevo && evos.any? { |evo| evo[0] != prevo && evo[1] == :None }
            heading = t[0] + _INTL("Método evolutivo (etapa final)\n")
          else
            heading = t[0] + _INTL("Método evolutivo\n")
          end
        end
        text = heading + text
      end
      if !inMenu && !@data_hash[:family].empty? #&& $player.owned?(@species)
        pbDrawTextPositions(overlay, [
          [_INTL("Ver evoluciones"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
        ])
      end
    end
    return text
  end
  
  #=============================================================================
  # Draws text related to special forms such as Mega Evolutions.
  #=============================================================================
  def pbDrawSpecialFormText(species)
    text = ""
    t = DATA_TEXT_TAGS
    special_form, check_form, check_item = pbGetSpecialFormData(species)
    if special_form
      base_data = GameData::Species.get_species_form(species.species, check_form)
      form_name = base_data.form_name
      if nil_or_empty?(form_name)
        spname = base_data.name
      elsif form_name.include?(base_data.name)
        spname = form_name
      else
        spname = form_name + " " + base_data.name
      end
      case special_form
      #-------------------------------------------------------------------------
      # Mega forms
      #-------------------------------------------------------------------------
      when :mega
        text = t[0] + _INTL("Mega Evolución\n")
        text << _INTL("{1}Obtenible cuando {2}{3}{4}", t[0], t[1], spname, t[0])
        if species.mega_stone
          param = GameData::Item.get(check_item).name
          text << _INTL(" activa la {1}{2}{3} equipada.", t[2], param, t[0])
        else
          param = GameData::Move.get(species.mega_move).name
          text << _INTL(" tiene el movimiento {1}{2}{3}.", t[2], param, t[0])
        end
      #-------------------------------------------------------------------------
      # Primal forms
      #-------------------------------------------------------------------------
      when :primal
        text = t[0] + _INTL("Regresión Primigenia\n")
        text << _INTL("{1}Ocurre cuando {2}{3}", t[0], t[1], spname)
        item = GameData::Item.try_get(check_item)
        param = (item) ? t[2] + item.name + t[0] : _INTL("Orbe Primigenio")
        text << _INTL("{1} entra en combate con el {2} equipado.", t[0], param)
      #-------------------------------------------------------------------------
      # Ultra Burst forms
      #-------------------------------------------------------------------------
      when :ultra
        spname = _INTL("una forma fusionada de {1}", base_data.name) if species.species == :NECROZMA
        text = t[0] + _INTL("Método Ultraexplosión\n")
        text << _INTL("{1}Obtenible cuando {2}{3}{4}", t[0], t[1], spname, t[0])
        item = GameData::Item.try_get(check_item)
        param = (item) ? t[2] + item.name + t[0] : _INTL("Ultranecrostal Z")
        text << _INTL(" activa su {1} equipado.", param)
      #-------------------------------------------------------------------------
      # Gigantamax forms
      #-------------------------------------------------------------------------
      when :gmax
        spname = _INTL("cualquier forma de {1}", base_data.name) if species.has_flag?("AllFormsShareGmax") || species.species == :TOXTRICITY
        text = t[0] + _INTL("Método Gigamax\n")
        text << _INTL("{1}Obtenible cuando {2}{3}{4}", t[0], t[1], spname, t[0])
        text << _INTL(" tiene el {1}factor Gigamax{2}.", t[2], t[0])
      #-------------------------------------------------------------------------
      # Eternamax forms
      #-------------------------------------------------------------------------
      when :emax
        text = t[0] + _INTL("Método Eternamax\n")
        text << _INTL("Desconocido.")
      #-------------------------------------------------------------------------
      # Terastal forms
      #-------------------------------------------------------------------------
      when :tera
        text = t[0] + _INTL("Método forma Teracristal\n")
        text << _INTL("{1}Obtenible cuando {2}{3}{4} activa la Teracristalización.", t[0], t[1], spname, t[0])
      end
    end
    return text
  end
  
  
  ##############################################################################
  #
  # These methods draw text only when a selection has been opened to view.
  #
  ##############################################################################

  
  #=============================================================================
  # Determines item rarity text to display. (Viewing item compatibility)
  #=============================================================================
  def pbDataTextItemSource(path, species, overlay, item)
    t = DATA_TEXT_TAGS
    itemName = GameData::Item.get(item).name
    text = _INTL("{1}{2}\n", t[2], itemName)
    if species.wild_item_common.include?(item)
      text << _INTL("{1}Objeto que {2}de forma común{3} puede llevar equipado esta especie.", t[0], t[1], t[0])     # Common items.
    elsif species.wild_item_uncommon.include?(item)
      text << _INTL("{1}Objeto que {2}de forma poco común{3} puede llevar equipado esta especie.", t[0], t[1], t[0])  # Uncommon items.
    elsif species.wild_item_rare.include?(item)
      text << _INTL("{1}Objeto que {2}rara vez{3} puede llevar equipado esta especie.", t[0], t[1], t[0])       # Rare items.
    end
    return text
  end
  
  #=============================================================================
  # Determines ability availability text to display. (Viewing ability compatibility)
  #=============================================================================
  def pbDataTextAbilitySource(path, species, overlay, ability)
    t = DATA_TEXT_TAGS
    abilityName = GameData::Ability.get(ability).name
    text = _INTL("{1}{2}\n", t[2], abilityName)
    text << t[0] + _INTL("Obtenible como ")
    #---------------------------------------------------------------------------
    # Natural abilities.
    #---------------------------------------------------------------------------
    if species.abilities.include?(ability)
      case species.abilities.length
      when 1 # Species only has one base ability.
        if species.hidden_abilities.empty? || 
           species.mega_stone || species.mega_move
          text << _INTL("la {1}única{2} habilidad de esta especie.", t[1], t[0])
        else
          text << _INTL("la habilidad {1}base{2} de esta especie.", t[1], t[0])
        end
      when 2 # Species has two base abilities.
        if species.abilities[0] == ability
          text << _INTL("la habilidad {1}primaria{2} de esta especie.", t[1], t[0])
        else
          text << _INTL("la habilidad {1}secundaria{2} de esta especie.", t[1], t[0])
        end
      end
    #---------------------------------------------------------------------------
    # Hidden abilities.
    #---------------------------------------------------------------------------
    elsif species.hidden_abilities.include?(ability)
      text << _INTL("habilidad {1}oculta{2} de esta especie.", t[1], t[0])
    else
      text << _INTL("habilidad {1}especial{2} de esta especie.", t[1], t[0])
    end
    return text
  end
  
  #=============================================================================
  # Determines move learning text to display. (Viewing move compatibility)
  #=============================================================================
  def pbDataTextMoveSource(path, species, overlay)
    t = DATA_TEXT_TAGS
    moveID = pbCurrentMoveID
    moveName = GameData::Move.get(moveID).name
    text = _INTL("{1}{2}\n", t[2], moveName)
    text << t[0] + _INTL("Aprendido por esta especie ")
    methods = []
    #---------------------------------------------------------------------------
    # Move appears in the species' learnset.
    #---------------------------------------------------------------------------
    species.moves.each do |m|
      next if m[1] != moveID
      case m[0]
      when -1 then method = _INTL("en el {1}recuerda movimientos{2}", t[1], t[0])  # Gen 9 move relearning.
      when 0  then method = _INTL("al {1}evolucionar{2}", t[1], t[0])           # Evolution move.
      else         method = _INTL("a {1}nivel {2}{3}", t[1], m[0], t[0])         # Level-up move.
      end
      methods.push(method)
      break	  
    end
    #text << "a través de " if methods.empty?
    #---------------------------------------------------------------------------
    # Move is learned as an Egg Move.
    #---------------------------------------------------------------------------
    if species.get_inherited_moves.include?(moveID)
      method = t[1] + _INTL("crianza") + t[0]
      methods.push(method)
    end
    #---------------------------------------------------------------------------
    # Move is learned via TM or move tutor.
    #---------------------------------------------------------------------------
    if species.tutor_moves.include?(moveID)
      method = _INTL("visitando un {1}tutor de movimientos{2}", t[1], t[0])
      # If none of the below applies, assume this is a move tutor move.
      GameData::Item.each do |item|
        next if !item.is_machine?
        next if item.move != moveID
        if $bag.has?(item.id)  # Player owns required machine.
          method = _INTL("usando {1}{2}{3}", t[1], item.name, t[0])
        elsif item.is_HM?      # Move is taught via HM.
          method = _INTL("usando una {1}MO{2}", t[1], t[0])
        elsif item.is_TM?      # Move is taught via TM.
          method = _INTL("usando una {1}MT{2}", t[1], t[0])
        elsif item.is_TR?      # Move is taught via TR.
          method = _INTL("usando una {1}DT{2}", t[1], t[0])
        end
        break
      end
      methods.push(method)
    end
    #---------------------------------------------------------------------------
    # Fixes up grammar and phrasing of learning methods.
    #---------------------------------------------------------------------------
    methods.push(_INTL("método desconocido")) if methods.empty?
    methods.each_with_index do |m, i|
      if i > 0 && i == methods.length - 1
        if m.include?("crianza")
          text << _INTL(" o a través de ")
        else
          text << _INTL(" o ")
        end
      end
      text << m
      text << ", " if i == 0 && methods.length > 2
    end
    text << "."
    return text
  end
end