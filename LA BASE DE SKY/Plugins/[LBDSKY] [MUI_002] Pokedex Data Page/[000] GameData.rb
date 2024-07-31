#===============================================================================
# Adds additional Habitat game data.
#===============================================================================
module GameData
  class Habitat
    attr_accessor :icon_position

    alias _dataplus_initialize initialize
    def initialize(hash)
      _dataplus_initialize(hash)
      @icon_position = hash[:icon_position] || 0
    end
  end
end

#-------------------------------------------------------------------------------
# Adds icon positions to each Habitat.
#-------------------------------------------------------------------------------
GameData::Habitat.each do |habitat|
  case habitat.id
  when :None         then habitat.icon_position = 0
  when :Grassland    then habitat.icon_position = 1
  when :Forest       then habitat.icon_position = 2
  when :WatersEdge   then habitat.icon_position = 3
  when :Sea          then habitat.icon_position = 4
  when :Cave         then habitat.icon_position = 5
  when :Mountain     then habitat.icon_position = 6
  when :RoughTerrain then habitat.icon_position = 7
  when :Urban        then habitat.icon_position = 8
  when :Rare         then habitat.icon_position = 9
  else                    habitat.icon_position = 0
  end
end


#===============================================================================
# Adds additional Egg Group game data.
#===============================================================================
module GameData
  class EggGroup
    attr_accessor :alt_name
    attr_accessor :icon_position

    alias _dataplus_initialize initialize
    def initialize(hash)
      _dataplus_initialize(hash)
      @alt_name      = hash[:alt_name] || @real_name
      @icon_position = hash[:icon_position] || 0
    end
    
    def alt_name
      return _INTL(@alt_name)
    end
  end
end

#-------------------------------------------------------------------------------
# Adds icon positions and alternative names to each Egg Group.
#-------------------------------------------------------------------------------
GameData::EggGroup.each do |group|
  case group.id
  when :Undiscovered
    group.alt_name = _INTL("Desconocido")
    group.icon_position = 1
  when :Monster
    group.alt_name = _INTL("Monstruo")
    group.icon_position = 2
  when :Water1
    group.alt_name = _INTL("Agua 1")
    group.icon_position = 3
  when :Bug
    group.alt_name = _INTL("Bicho")
    group.icon_position = 4
  when :Flying
    group.alt_name = _INTL("Volador")
    group.icon_position = 5
  when :Field
    group.alt_name = _INTL("Campo")
    group.icon_position = 6
  when :Fairy
    group.alt_name = _INTL("Hada")
    group.icon_position = 7
  when :Grass
    group.alt_name = _INTL("Planta")
    group.icon_position = 8
  when :Humanlike
    group.alt_name = _INTL("Humanoide")
    group.icon_position = 9
  when :Water3
    group.alt_name = _INTL("Agua 3")
    group.icon_position = 10
  when :Mineral
    group.alt_name = _INTL("Mineral")
    group.icon_position = 11
  when :Amorphous
    group.alt_name = _INTL("Amorfo")
    group.icon_position = 12
  when :Water2
    group.alt_name = _INTL("Agua 2")
    group.icon_position = 13
  when :Ditto
    group.alt_name = _INTL("Ditto")
    group.icon_position = 14
  when :Dragon
    group.alt_name = _INTL("Dragón")
    group.icon_position = 15
  else
    group.icon_position = 0
  end
end

#-------------------------------------------------------------------------------
# Adds the "None" group to display the ???? icon on genderless species.
#-------------------------------------------------------------------------------
GameData::EggGroup.register({
  :id   => :None,
  :name => _INTL("Ninguno"),
  :alt_name => _INTL("????"),
  :icon_position => 0
})


#===============================================================================
# Adds additional Evolution game data.
#===============================================================================
module GameData
  class Evolution
    attr_accessor :description

    alias _dataplus_initialize initialize
    def initialize(hash)
      _dataplus_initialize(hash)
      @description = hash[:description] || ""
    end
    
    #---------------------------------------------------------------------------
    # Returns the description of an evolution method.
    #---------------------------------------------------------------------------
    # [species] is the species ID of the species with this evolution method.
    # [evo] is the species ID of the species that [species] is evolving into.
    # [param] is the specific parameter used for this evolution, if any.
    # [full] can be set to a boolean to display full or shortened descriptions.
    # [form] can be set to a boolean to display form names or not.
    # [c] is an array used for determining text colors for highlighting.
    #---------------------------------------------------------------------------
    def description(species, evo, param = nil, full = true, form = false, c = [])
      #-------------------------------------------------------------------------
      # Determines the species name.
      if GameData::Species.exists?(species)
        prefix = ""
        if @id.to_s.include?("female")
          prefix = " siendo hembra"
        elsif @id.to_s.include?("male")
          prefix = " siendo macho"
        end
        form = false if evo == :MOTHIM
        species_data = GameData::Species.get(species)
        form_name = species_data.form_name
        if form && form_name && !form_name.include?(species_data.name)
          full_name = _INTL("{2} {3}{1}", prefix, species_data.name, species_data.form_name)
        else
          full_name = _INTL("{2}{1}", prefix, species_data.name)
        end
      else
        full_name = _INTL("????")
      end
      full_name = c[1] + full_name + c[0] if !c.empty?
      #-------------------------------------------------------------------------
      # Determines the parameter name.
      case param
      when Symbol
        case @parameter
        when :Move    then par = GameData::Move.get(param).name
        when :Type    then par = GameData::Type.get(param).name
        when :Species then par = GameData::Species.get(param).name
        when :Item
          par  = GameData::Item.get(param).portion_name
          par2 = GameData::Item.get(param).portion_name_plural
        end
        prefix = ""
        if [:Type, :Item, :Species].include?(@parameter)
          prefix = ' ' #(par.starts_with_vowel?) ? "an " : "a "
        end
        param = c[2] + par + c[0] if !c.empty?
        param_name = _INTL("{1}{2}", prefix, param)
        param = c[2] + par2 + c[0] if !c.empty? && par2
        param_name2 = _INTL("{1}", param)
      when Integer
        case @id
        when :Region
          param_name = GameData::TownMap.get(param).name
        when :Location
          param_name = GameData::MapMetadata.get(param).name		  
        when :LevelDarkInParty
          param_name = GameData::Type.get(:DARK).name
        when :AttackGreater, :DefenseGreater, :AtkDefEqual
          param_name = GameData::Stat.get(:ATTACK).name
          param_name2 = GameData::Stat.get(:DEFENSE).name
        end
        if param_name
          param_name = c[2] + param_name + c[0] if !c.empty?
          param_name2 = c[2] + param_name2 + c[0] if param_name2 && !c.empty?
        else
          param_name = param.to_s
        end
      else
        case param
        when "  "
          location = (c.empty?) ? "Roca Musgosa" : c[2] + "Roca Musgosa" + c[0]
          param_name = _INTL("cerca de una {1}", location)
        when "IceRock"
          location = (c.empty?) ? "Roca Helada" : c[2] + "Roca Helada" + c[0]
          param_name = _INTL("cerca de una {1}", location)
        when "Magnetic"
          location = (c.empty?) ? "Área Magnética" : c[2] + "Área Magnética" + c[0]
          param_name = _INTL("en un {1}", location)
        else
          location = (c.empty?) ? "Área Especial" : c[2] + "Área Especial" + c[0]
          param_name = _INTL("En un {1}", location)
        end
      end
      #-------------------------------------------------------------------------
      # Determines the first portion of the description based on proc type.
      if @event_proc
        desc = (full) ? "Tiene #{full_name}" : "O" 
        desc = _INTL("{1} lanza un evento especial", desc)
      elsif @use_item_proc
        desc = (full) ? "Usando #{param_name} en #{full_name} " : "Usar #{param_name}"
        #desc = _INTL("{1} {2}", desc, param_name)
      elsif @on_trade_proc
        desc = (full) ? _INTL("Intercambio {1}", full_name) : _INTL("Intercambio")
      elsif @after_battle_proc
        desc = (full) ? "Tiene #{full_name}" : ""
        desc = _INTL("{1} finaliza una batalla", desc)
      elsif @level_up_proc
        if @any_level_up
          desc = (full) ? _INTL("Subir de nivel a {1}", full_name) : _INTL("Nivel")
        else
          desc = (full) ? "Subir a #{full_name}" : "O"
          desc = _INTL("{1} al nivel {2}", desc, param)
        end
      elsif @id == :Shedinja
        desc = (full) ? "#{full_name} evoluciona" : "evolución"
        desc = _INTL("Puede dejarse en una ranura vacía del equipo después de {1}", desc)
      else
        desc = (full) ? "#{full_name} evoluciona" : "O"
        desc = _INTL("{1} a través de un método desconocido", desc)
      end
      #-------------------------------------------------------------------------
      # Determines the full description by combining method-specific details.
      if !nil_or_empty?(@description)
        desc2 = _INTL("#{@description}", param_name, param_name2)
        full_desc = _INTL("{1} {2}.", desc, desc2)
      else
        full_desc = _INTL("{1}.", desc)
      end
      return full_desc
    end
  end
end

#-------------------------------------------------------------------------------
# Adds description details to each Evolution method.
#-------------------------------------------------------------------------------
GameData::Evolution.each do |evo|
  case evo.id
  when :LevelDay, :ItemDay, :TradeDay          then evo.description = _INTL("de día")
  when :LevelNight, :ItemNight, :TradeNight    then evo.description = _INTL("de noche")
  when :LevelMorning                           then evo.description = _INTL("por la mañana")
  when :LevelAfternoon                         then evo.description = _INTL("por la tarde")
  when :LevelEvening                           then evo.description = _INTL("purante la noche")
  when :LevelNoWeather                         then evo.description = _INTL("con clima despejado")
  when :LevelSun                               then evo.description = _INTL("con sol fuerte")
  when :LevelRain                              then evo.description = _INTL("mientras llueve")
  when :LevelSnow                              then evo.description = _INTL("mientras nieva")
  when :LevelSandstorm                         then evo.description = _INTL("durante una tormenta de arena")
  when :LevelCycling                           then evo.description = _INTL("andando en bici")
  when :LevelSurfing                           then evo.description = _INTL("mientras andas por el agua")
  when :LevelDiving                            then evo.description = _INTL("mientras buceas")
  when :LevelDarkness                          then evo.description = _INTL("mientras andas en la oscuridad")
  when :LevelDarkInParty                       then evo.description = _INTL("cuando hay un pokémon tipo {1} en el equipo")
  when :AttackGreater                          then evo.description = _INTL("cuando su {1} es mayor que su {2}")
  when :DefenseGreater                         then evo.description = _INTL("cuando su {2} es mayor que su {1}")
  when :AtkDefEqual                            then evo.description = _INTL("cuando su {1} y {2} son iguales")
  when :Silcoon, :Cascoon                      then evo.description = _INTL("- los resultados pueden variar")
  when :Ninjask                                then evo.description = _INTL("- esto puede dejar atrás una cáscara después")
  when :Happiness, :ItemHappiness              then evo.description = _INTL("con felicidad alta")
  when :HappinessMale, :HappinessFemale        then evo.description = _INTL("con felicidad alta")
  when :MaxHappiness                           then evo.description = _INTL("con felicidad máxima")
  when :HappinessDay                           then evo.description = _INTL("de día con felicidad alta")
  when :HappinessNight                         then evo.description = _INTL("de noche con felicidad alta")
  when :HappinessMove                          then evo.description = _INTL("con felicidad alta y sabiendo el movimiento {1}")
  when :HappinessMoveType                      then evo.description = _INTL("con felicidad alta y sabiendo un ataque de tipo {1}")
  when :HappinessHoldItem, :HoldItemHappiness  then evo.description = _INTL("con felicidad alta mientras lleva equipado {1}")
  when :Beauty                                 then evo.description = _INTL("con belleza alta")
  when :HoldItem, :TradeItem                   then evo.description = _INTL("sosteniendo {1}")
  when :HoldItemMale, :HoldItemFemale          then evo.description = _INTL("sosteniendo {1}")
  when :DayHoldItem                            then evo.description = _INTL("de día sosteniendo {1}")
  when :NightHoldItem                          then evo.description = _INTL("de noche sosteniendo {1}")
  when :HasMove                                then evo.description = _INTL("sabiendo el movimiento {1}")
  when :HasMoveType                            then evo.description = _INTL("sabiendo un movimiento tipo {1}")
  when :HasInParty                             then evo.description = _INTL("teniendo a {1} en el equipo")
  when :Location                               then evo.description = _INTL("estando en {1}")
  when :LocationFlag                           then evo.description = _INTL("mientras {1}")
  when :Region                                 then evo.description = _INTL("estando el la región {1}")
  when :TradeSpecies                           then evo.description = _INTL("por {1}")
  when :BattleDealCriticalHit                  then evo.description = _INTL("causando {1} or mas golpes críticos")
  when :EventAfterDamageTaken                  then evo.description = _INTL("tras perder al menos 49 PS")
  when :LevelWalk                              then evo.description = _INTL("tras dar {1} pasos estando como primer pokémon del equipo")
  when :LevelWithPartner                       then evo.description = _INTL("subiendo de nivel junto a un aliado")
  when :LevelUseMoveCount                      then evo.description = _INTL("tras usar el movimiento {1} 20 veces")
  when :LevelRecoilDamage                      then evo.description = _INTL("tras perder al menos {1} PS por daño de retroceso")
  when :LevelDefeatItsKindWithItem             then evo.description = _INTL("tras vencer a 3 de su misma especie que tengan el objeto {1}")
  when :CollectItems                           then evo.description = _INTL("teniendo al menos 999x {2} en la mochila")
  end
end


#===============================================================================
# Adds new utilities to the species class.
#===============================================================================
module GameData
  class Species
    #---------------------------------------------------------------------------
    # Determines if this species should be viewable in the data page menus.
    #---------------------------------------------------------------------------
    def display_species?(dexlist, species, special = false, skip_owned_check = false)
      return false if !dexlist.any? { |dex| dex[:species] == @species }
      return false if (!$player.owned?(@species) && !skip_owned_check)
      return false if @species == species.species && @form == species.form
      if @form > 0 && !Settings::DEX_SHOWS_ALL_FORMS
        return false if !($player.pokedex.seen_form?(@species, 0, @form) ||
                        $player.pokedex.seen_form?(@species, 1, @form))
      end
      return false if @form != 0 && (!@real_form_name || @real_form_name.empty?)
      return false if @pokedex_form != @form
      return false if [:PICHU_2, :FLOETTE_5, :GIMMIGHOUL_1].include?(@id)
      return false if @species == :PIKACHU && (8..15).include?(@form)
      if special
        return false if @mega_stone || @mega_move
        return false if defined?(@gmax_move) && @gmax_move
      end
      return true
    end
    
    #---------------------------------------------------------------------------
    # Determines the base form of a species.
    #---------------------------------------------------------------------------
    def base_pokedex_form
      return @ungmax_form if defined?(@ungmax_form) && @ungmax_form > 0
      return @unmega_form if @unmega_form > 0
      return default_form if default_form >= 0
      return 0
    end
		
	  #---------------------------------------------------------------------------
    # Checks a species for all forms that branch off into different evolutions.
    #---------------------------------------------------------------------------
    def branch_evolution_forms
      forms = [@form]
      @flags.each do |flag|
        forms.push($~[1].to_i) if flag[/^EvoBranchForm_(\d+)$/i]
      end
      return forms
    end
	
    #---------------------------------------------------------------------------
    # Determines if the species is a regional form.
    #---------------------------------------------------------------------------
    def is_regional_form?
      if @form > 0 && self.form_name
        return false if self.form_name.include?(_INTL("Forma Daruma"))
        Settings::REGIONAL_NAMES.each do |region|
          return true if self.form_name.include?(region)
        end
      end
      return false
    end
	
    #---------------------------------------------------------------------------
    # Includes special form moves in tutor move lists.
    #---------------------------------------------------------------------------
    def get_tutor_moves
      case @id
      when :PIKACHU     then moves = [:VOLTTACKLE]
      when :ROTOM_1     then moves = [:OVERHEAT]
      when :ROTOM_2     then moves = [:HYDROPUMP]
      when :ROTOM_3     then moves = [:BLIZZARD]
      when :ROTOM_4     then moves = [:AIRSLASH]
      when :ROTOM_5     then moves = [:LEAFSTORM]
      when :KYUREM_1    then moves = [:ICEBURN, :FUSIONFLARE]
      when :KYUREM_2    then moves = [:FREEZESHOCK, :FUSIONBOLT]
      when :NECROZMA_1  then moves = [:SUNSTEELSTRIKE]
      when :NECROZMA_2  then moves = [:MOONGEISTBEAM]
      when :ZACIAN_1    then moves = [:BEHEMOTHBLADE]
      when :ZAMAZENTA_1 then moves = [:BEHEMOTHBASH]
      when :CALYREX_1   then moves = [:GLACIALLANCE]
      when :CALYREX_2   then moves = [:ASTRALBARRAGE]
      end
      return @tutor_moves if !moves
      return moves.concat(@tutor_moves.clone)
    end
	
    #---------------------------------------------------------------------------
    # Alias for displaying the "return" icon in species lists.
    #---------------------------------------------------------------------------
    Species.singleton_class.alias_method :pokedex_icon_filename, :icon_filename
    def self.icon_filename(*params)
      return pbResolveBitmap("Graphics/Pokemon/Icons/_RETURN_") if params[0] == :RETURN
      return self.pokedex_icon_filename(*params)
    end
  end
end


#===============================================================================
# Allows Primal Reversion methods to be displayed in the Data page.
#===============================================================================
MultipleForms.register(:GROUDON, {
  "getPrimalForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:REDORB)
    next
  },
  "getDataPageInfo" => proc { |pkmn|
    next [1, 0, :REDORB]
  }
})

MultipleForms.register(:KYOGRE, {
  "getPrimalForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:BLUEORB)
    next
  },
  "getDataPageInfo" => proc { |pkmn|
    next [1, 0, :BLUEORB]
  }
})