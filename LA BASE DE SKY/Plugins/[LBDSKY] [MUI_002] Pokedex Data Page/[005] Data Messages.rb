#===============================================================================
# Relacionado con la visualización de varios textos en el cuadro de mensajes de la página de datos.
#===============================================================================
class PokemonPokedexInfo_Scene
  #-----------------------------------------------------------------------------
  # Dibuja los textos relevantes en función de la posición del cursor.
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
    when :family    then text = pbDataTextShowEvolutions(path, species, overlay)
    when :shape     then text = pbDataTextShape(path, species, overlay)
    when :egg       then text = pbDataTextEggGroup(path, species, overlay)
    when :item      then text = pbDataTextItems(path, species, overlay)
    when :ability
      pbDrawImagePositions(overlay, [[path, 248, 240, 0, 244, 116, 44]])
      text = t[0] + "Habilidades\n"
      if $player.owned?(@species)
        text += "Ver todas las habilidades de esta especie."
      else
        text += "Desconocido."
      end
    when :moves
      pbDrawImagePositions(overlay, [[path, 376, 240, 0, 244, 116, 44]])
      text = t[0] + "Movimientos\n"
      if $player.owned?(@species)
        text += "Ver todos los movimientos que esta especie puede aprender."
      else
        text += "Desconocido."
      end
    end
    drawFormattedTextEx(overlay, 34, 294, 446, _INTL("{1}", text))
  end
  
  #-----------------------------------------------------------------------------
  # Determina el texto de encuentro a mostrar. (Cursor ==: encuentro)
  #-----------------------------------------------------------------------------
  def pbDataTextEncounters(path, species, overlay)
    t = DATA_TEXT_TAGS
    text = t[0] + "Encuentros:\n"
    text += "Derrotados: " + "#{$player.pokedex.defeated_count(species.id)}\n"
    text += "Capturados: " + "#{$player.pokedex.caught_count(species.id)}\n"
    return text
  end
  
  #-----------------------------------------------------------------------------
  # Determina el texto general a mostrar. (Cursor ==: general)
  #-----------------------------------------------------------------------------
  def pbDataTextGeneral(path, species, overlay)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 0, 36, 0, 0, 512, 56]])
    owned = $player.owned?(@species)
    text = t[0] + "Estadísticas Generales:\n"
    if owned
      chance = species.catch_rate
      c = ((chance / 256.0) * 100).floor
      c = 1 if c < 1
      text += "Prob. de captura: #{c}%\n"
      text += "Prob. de género: "
      if owned
        case species.gender_ratio
        when :AlwaysMale   then text += t[2] + "Macho 100%"
        when :AlwaysFemale then text += t[1] + "Hembra 100%"
        when :Genderless   then text += "---"
        else
          chance = GameData::GenderRatio.get(species.gender_ratio).female_chance
          if chance
            f = ((chance / 256.0) * 100).round
            m = (100 - f)
            text += t[2] + "Macho #{m.to_s}% " + t[1] + "Hembra #{f.to_s}%"
          else
            text += "????"
          end
        end
      else
        text += "????"
      end
    else
      text += "Desconocido."
    end
    return text
  end
  
  #-----------------------------------------------------------------------------
  # Determina el texto de estadísticas base a mostrar. (Cursor ==: estadísticas) 
  #-----------------------------------------------------------------------------
  def pbDataTextStats(path, species, overlay, s2 = nil)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 0, 90, 0, 56, 222, 188]])
    owned = $player.owned?(@species)
    text = t[0] + "Estadísticas:" 
    if owned
      nt = (s2 && s2.base_stat_total == species.base_stat_total) ? t[2] : t[1]
      text += " - " + nt + _ISPRINTF("Total {1:3d}", species.base_stat_total)
      s1 = species.base_stats
      s2 = s2.base_stats if s2
      stats_order = [[:HP, :SPECIAL_ATTACK], [:ATTACK, :SPECIAL_DEFENSE], [:DEFENSE, :SPEED]]
      stats_order.each_with_index do |st, i|
        names = values = ""
        st.each_with_index do |s, j|
          stat = (s == :SPECIAL_ATTACK) ? "At. Esp." : (s == :SPECIAL_DEFENSE) ? "Def. Esp." : GameData::Stat.get(s).name
          nt = (s2 && s2[s] == s1[s]) ? t[2] : t[0]
          names  += nt + _INTL("{1}", stat)
          values += nt + _ISPRINTF("{1:3d}", s1[s])
          names  += "\n" if j == 0
          values += "\n" if j == 0
        end
        nameX = 34 + 152 * i
        valueX = nameX + 100
        drawFormattedTextEx(overlay, nameX, 324, 76+16, _INTL("{1}", names))
        drawFormattedTextEx(overlay, valueX, 324, 52, _INTL("{1}", values))
      end
      pbDrawTextPositions(overlay, [
        [_INTL("Ver similares"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
      ]) if !s2 && !@data_hash[:stats].empty?
    else
      text += "\nDesconocido."
    end
    return text
  end
  
  #-----------------------------------------------------------------------------
  # Determines the body color & shape text to display. (Cursor == :shape)
  #-----------------------------------------------------------------------------
  def pbDataTextShape(path, species, overlay, s2 = nil)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 412, 166, 432, 208, 74, 72]])
    text = t[0] + "Morfología:\n"
    color = GameData::BodyColor.get(species.color)
    nt = (s2 && s2[0] == color.id) ? t[2] : t[1]
    name = color.name.downcase
    text += "El color principal de la especie es el " + nt + _INTL("{1}", name) + t[0] + "."
    shape = GameData::BodyShape.get(species.shape)
    nt = (s2 && s2[1] == shape.id) ? t[2] : t[1]
    name = shape.name.downcase
    case shape.id
    when :Head, :HeadArms, :HeadBase, :HeadLegs
      text += " Tiene forma " + nt + _INTL("{1}", name) + t[0] + "."
    when :Bipedal, :BipedalTail, :Quadruped, :Multiped, :MultiBody, :MultiWinged, :Winged, :Serpentine
      text += " Tiene forma " + nt + _INTL("{1}", name) + t[0] + "."
    when :Insectoid
      text += " Tiene forma " + nt + _INTL("{1}", name) + t[0] + "."
    when :Finned
      text += " Tiene forma " + nt + _INTL("{1}", name) + t[0] + "."
    else
      text += " La forma no puede ser clasificada."
    end
    pbDrawTextPositions(overlay, [
      [_INTL("Ver Pokémon similares"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
    ]) if !s2 && !@data_hash[:shape].empty?
    return text
  end
  
  #-----------------------------------------------------------------------------
  # Determina el grupo huevo a mostrar. (Cursor ==: huevo)
  #-----------------------------------------------------------------------------
  def pbDataTextEggGroup(path, species, overlay, s2 = nil)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 332, 166, 432, 208, 74, 72]])
    owned = $player.owned?(@species)
    text = t[0] + "Crianza:\n"
    if owned
      text += "Especie "
      groups = species.egg_groups
      groups = [:None] if species.gender_ratio == :Genderless && 
                          !(groups.include?(:Ditto) || groups.include?(:Undiscovered))
      if groups.include?(:None)
        data = GameData::EggGroup.get(:Ditto)
        name = (Settings::ALT_EGG_GROUP_NAMES) ? data.alt_name : data.name
        text += "sin género, solo compatible con el grupo " + t[1] + "#{name}" + t[0] + "."
      elsif groups.include?(:Ditto)
        data = GameData::EggGroup.get(:Ditto)
        name = (Settings::ALT_EGG_GROUP_NAMES) ? data.alt_name : data.name
        text += "en el grupo " + t[1] + "#{name}" + t[0] + ", compatible con todos salvo Desconocido."
      elsif groups.include?(:Undiscovered) || groups.empty?
        data = GameData::EggGroup.get(:Undiscovered)
        name = (Settings::ALT_EGG_GROUP_NAMES) ? data.alt_name : data.name
        text += "en el grupo " + t[1] + "#{name}" + t[0] + ", no puede ser criado."
      else
        size_groups_sky = 0
        groups.each_with_index do |group, i|
          size_groups_sky+=1
        end
        if size_groups_sky == 2
          text += "compatible con los grupos "
        else
          text += "compatible con el grupo "
        end
        groups.each_with_index do |group, i|
          data = GameData::EggGroup.get(group)
          name = (Settings::ALT_EGG_GROUP_NAMES) ? data.alt_name : data.name
          nt = (s2 && s2.include?(group)) ? t[2] : t[1]
          text += nt + "#{name}" + t[0]
          if i < groups.length - 1
            text += " y "
          else
            text += "."
          end
        end
      end
      pbDrawTextPositions(overlay, [
        [_INTL("Ver Pokémon compatibles"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
      ]) if !s2 && !@data_hash[:egg].empty?
    else
      text += "Desconocido."
    end
    return text
  end
  
  #-----------------------------------------------------------------------------
  # Determina el texto del objeto sostenido salvaje a mostrar. (Cursor ==: item)
  #-----------------------------------------------------------------------------
  def pbDataTextItems(path, species, overlay)
    t = DATA_TEXT_TAGS
    pbDrawImagePositions(overlay, [[path, 254, 166, 432, 208, 74, 72]])
    owned = $player.owned?(@species)
    text = ""
    if owned
      @data_hash[:item].keys.each_with_index do |r, a|
        next if @data_hash[:item][r].empty?
        text += ", " if !nil_or_empty?(text)
        @data_hash[:item][r].each_with_index do |item, i|
          text += t[1] + GameData::Item.get(item).name + t[0]
          text += ", " if i < @data_hash[:item][r].length - 1
        end
      end
      if nil_or_empty?(text)
        text += "---" 
      else
        pbDrawTextPositions(overlay, [
          [_INTL("Más información"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
        ])
      end
    else
      text += "Desconocido."
    end
    text = t[0] + "Objetos\n" + text
    return text
  end
  
  #-----------------------------------------------------------------------------
  # Determines the family & evolution method text to display. (Cursor == :family)
  #-----------------------------------------------------------------------------

  def pbDataTextShowEvolutions(path, species, overlay)
    t = DATA_TEXT_TAGS
    if @sprites["familyicon1"].visible && @sprites["familyicon2"].visible
      pbDrawImagePositions(overlay, [[path, 228, 90, 222, 56, 284, 76]])
    elsif @sprites["familyicon1"].visible
      pbDrawImagePositions(overlay, [[path, 280, 90, 222, 132, 180, 76]])
    else
      pbDrawImagePositions(overlay, [[path, 332, 90, 402, 132, 76, 76]])
    end
    text = t[0] + "Evoluciones:\n"
    evos = species.get_evolutions
    if evos.empty?
      text += "Esta especie no evoluciona."
    else
      evo_count = 0
      previous_evo = nil
      evos.each do |evo|
        if previous_evo != evo[1]
          evo_count += 1
          previous_evo = evo[1]
        end
      end
      text += "Tiene " + t[1] + "#{evo_count}" + t[0] 
      text+= evo_count > 1 ? " evoluciones posibles." : " evolución posible."
      pbDrawTextPositions(overlay, [
        [_INTL("Ver las evoluciones"), Graphics.width - 34, 292, :right, Color.new(0, 112, 248), Color.new(120, 184, 232)]
      ]) 
    end
    return text
  end

  def pbDataTextFamily(path, species, overlay)
    t = DATA_TEXT_TAGS
    if @sprites["familyicon1"].visible && @sprites["familyicon2"].visible
      pbDrawImagePositions(overlay, [[path, 228, 90, 222, 56, 284, 76]])
    elsif @sprites["familyicon1"].visible
      pbDrawImagePositions(overlay, [[path, 280, 90, 222, 132, 180, 76]])
    else
      pbDrawImagePositions(overlay, [[path, 332, 90, 402, 132, 76, 76]])
    end
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
      when :mega
        text = t[0] + "Método de Mega Evolución\n"
        text += t[0] + "Available when " + t[1] + "#{spname}" + t[0]
        if species.mega_stone
          param = GameData::Item.get(check_item).name
          text += " lanza su " + t[2] + "#{param}" + t[0] + "."
        else
          param = GameData::Move.get(species.mega_move).name
          text += " tiene el movimiento " + t[2] + "#{param}" + t[0] + "."
        end
      when :primal
        text = t[0] + "Método de Reversión Primigenia\n"
        text += t[0] + "Ocurre cuando " + t[1] + "#{spname}"
        item = GameData::Item.try_get(check_item)
        param = (item) ? t[2] + item.name + t[0] : "Orbe Primigenio"
        text += t[0] + " entrando en batalla con su " + "#{param}" + "."
      when :ultra
        spname = "una forma fusionada de #{base_data.name}" if species.species == :NECROZMA
        text = t[0] + "Método Ultra Ráfaga\n"
        text += t[0] + "Disponible cuando " + t[1] + "#{spname}" + t[0]
        item = GameData::Item.try_get(check_item)
        param = (item) ? t[2] + item.name + t[0] : "Ultra item"
        text += " lanza su " + "#{param}" + "."
      when :gmax
        spname = "cualquier forma de #{base_data.name}" if species.has_flag?("AllFormsShareGmax") || species.species == :TOXTRICITY
        text = t[0] + "Método Gigantamax\n"
        text += t[0] + "Disponible cuando " + t[1] + "#{spname}" + t[0]
        text += " has " + t[2] + " Factor G-Max " + t[0] + "."
      when :emax
        text = t[0] + "Método Eternamax \n"
        text += "Desconocido."
      when :tera
        text = t[0] + "Método forma Terastal\n"
        text += t[0] + "Disponible cuando " + t[1] + "#{spname}" + t[0] + " lanza la Teracristalización."
      end
    else
      prevo = species.get_previous_species
      prevo = species.species if species.id == :FLOETTE_5
      if prevo != species.species
        form = (species.default_form >= 0) ? species.default_form : @form
        prevo_data = GameData::Species.get_species_form(prevo, form)
        evos = prevo_data.get_evolutions
        if species.species == :ALCREMIE
          name = t[1] + "#{prevo_data.name}" + t[0]
          text = t[0] + "Usa varios " + t[2] + "Dulces" + t[0] + " en #{name}."
        else
          text = ""
          index = 0
          evos.each do |evo|
            next if evo[0] != species.species
            if species.species == :URSHIFU && evo[1] == :Item
              next if evo[2] != [:SCROLLOFDARKNESS, :SCROLLOFWATERS][species.form]
            end
            spec = prevo_data.id
            data = GameData::Evolution.get(evo[1])
            text += " " if index > 0
            text += data.description(spec, evo[0], evo[2], nil_or_empty?(text), true, t)
            break if index > 0
            index += 1
          end
          case species.species
          when :LYCANROC
            case @form
            when 0 then text += " Tiene que ser de día para esta forma."
            when 1 then text += " Tiene que ser de noche para esta forma."
            when 2 then text += " Requiere " + t[2] + GameData::Ability.get(:OWNTEMPO).name + t[0] + "."
            end
          when :TOXTRICITY
            text += " Forma depende de su " + t[2] + "Naturaleza" + t[0] + "."
          end
        end
        text = t[0] + "Método de Evolución:\n" + text
      else
        text = t[0] + "Especies Relacionadas:\n"
        family = species.get_family_evolutions
        if !family.empty?
          ids = []
          family.each { |f| ids.push(f[1]) if !ids.include?(f[1]) }
          ids.each_with_index do |fam, i|  
            name = ($player.seen?(fam)) ? GameData::Species.get(fam).name : "????"
            text += t[1] + name
            text += t[0] + ", " if i < ids.length - 1
          end
        else
          text += "---"
        end
      end
    end
    return text
  end
end