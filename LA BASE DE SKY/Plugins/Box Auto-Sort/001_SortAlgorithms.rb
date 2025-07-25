#===============================================================================
# Box Auto-Sort - Sorting Algorithms
#===============================================================================

module BoxAutoSort
  #=============================================================================
  # Main sorting class
  #=============================================================================
  class BoxSorter
    def initialize(storage, box_index)
      @storage = storage
      @box_index = box_index
      @box = @storage[@box_index]
    end
    
    # Get all Pokemon in the current box (excluding empty slots)
    def get_pokemon_list
      pokemon_list = []
      (0...PokemonBox::BOX_SIZE).each do |i|
        pokemon = @storage[@box_index, i]
        pokemon_list << [pokemon, i] if pokemon
      end
      return pokemon_list
    end
    
    # Sort Pokemon based on the selected method
    def sort_pokemon(sort_method)
      pokemon_list = get_pokemon_list
      return false if pokemon_list.empty?
      
      # Create sorted list
      sorted_list = case sort_method
      when :LEVEL_ASC
        pokemon_list.sort { |a, b| a[0].level <=> b[0].level }
      when :LEVEL_DESC
        pokemon_list.sort { |a, b| b[0].level <=> a[0].level }
      when :ALPHABET
        pokemon_list.sort { |a, b| a[0].name <=> b[0].name }
      when :ALPHABET_REV
        pokemon_list.sort { |a, b| b[0].name <=> a[0].name }
      when :TYPE_PRIMARY
        pokemon_list.sort { |a, b| compare_types(a[0], b[0]) }
      when :TYPE_DUAL
        pokemon_list.sort { |a, b| compare_types_dual(a[0], b[0]) }
      when :CATCH_DATE
        pokemon_list.sort { |a, b| compare_catch_date(a[0], b[0]) }
      when :SHINY_FIRST
        pokemon_list.sort { |a, b| compare_shiny_first(a[0], b[0]) }
      when :SPECIES_ID
        pokemon_list.sort { |a, b| compare_species_id(a[0], b[0]) }
      when :FORM_ID
        pokemon_list.sort { |a, b| compare_form_id(a[0], b[0]) }
      when :FRIENDSHIP
        pokemon_list.sort { |a, b| b[0].happiness <=> a[0].happiness }
      when :NATURE
        pokemon_list.sort { |a, b| a[0].nature.name <=> b[0].nature.name }
      else
        return false
      end
      
      # Apply the sorted order to the box
      apply_sorted_order(sorted_list)
      return true
    end
    
    # Preview what the sort would look like without applying it
    def preview_sort(sort_method)
      pokemon_list = get_pokemon_list
      return [] if pokemon_list.empty?
      
      case sort_method
      when :LEVEL_ASC
        return pokemon_list.sort { |a, b| a[0].level <=> b[0].level }
      when :LEVEL_DESC
        return pokemon_list.sort { |a, b| b[0].level <=> a[0].level }
      when :ALPHABET
        return pokemon_list.sort { |a, b| a[0].name <=> b[0].name }
      when :ALPHABET_REV
        return pokemon_list.sort { |a, b| b[0].name <=> a[0].name }
      when :TYPE_PRIMARY
        return pokemon_list.sort { |a, b| compare_types(a[0], b[0]) }
      when :TYPE_DUAL
        return pokemon_list.sort { |a, b| compare_types_dual(a[0], b[0]) }
      when :CATCH_DATE
        return pokemon_list.sort { |a, b| compare_catch_date(a[0], b[0]) }
      when :SHINY_FIRST
        return pokemon_list.sort { |a, b| compare_shiny_first(a[0], b[0]) }
      when :SPECIES_ID
        return pokemon_list.sort { |a, b| compare_species_id(a[0], b[0]) }
      when :FORM_ID
        return pokemon_list.sort { |a, b| compare_form_id(a[0], b[0]) }
      when :FRIENDSHIP
        return pokemon_list.sort { |a, b| b[0].happiness <=> a[0].happiness }
      when :NATURE
        return pokemon_list.sort { |a, b| a[0].nature.name <=> b[0].nature.name }
      else
        return pokemon_list
      end
    end
    
    private
    
    # Apply the sorted order to the actual box
    def apply_sorted_order(sorted_list)
      # Clear the box first
      (0...PokemonBox::BOX_SIZE).each do |i|
        @storage[@box_index, i] = nil
      end
      
      # Place Pokemon in new order
      sorted_list.each_with_index do |pokemon_data, new_index|
        @storage[@box_index, new_index] = pokemon_data[0]
      end
    end
    
    # Type comparison (primary type only)
    def compare_types(pokemon_a, pokemon_b)
      type_a = pokemon_a.types[0].to_s
      type_b = pokemon_b.types[0].to_s
      comparison = type_a <=> type_b
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end
    
    # Type comparison (dual types)
    def compare_types_dual(pokemon_a, pokemon_b)
      types_a = pokemon_a.types.map(&:to_s).join("/")
      types_b = pokemon_b.types.map(&:to_s).join("/")
      comparison = types_a <=> types_b
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end
    
    # Catch date comparison (newer first, fallback to name)
    def compare_catch_date(pokemon_a, pokemon_b)
      date_a = pokemon_a.timeReceived || Time.new(2000, 1, 1)
      date_b = pokemon_b.timeReceived || Time.new(2000, 1, 1)
      comparison = date_b <=> date_a  # Newer first
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end
    
    # Shiny first, then by name
    def compare_shiny_first(pokemon_a, pokemon_b)
      shiny_a = pokemon_a.shiny? ? 0 : 1
      shiny_b = pokemon_b.shiny? ? 0 : 1
      comparison = shiny_a <=> shiny_b
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end
    
    # Species ID comparison (National Dex order)
    def compare_species_id(pokemon_a, pokemon_b)
      species_data_a = GameData::Species.get(pokemon_a.species)
      species_data_b = GameData::Species.get(pokemon_b.species)
      
      # Verwende id_number falls verfügbar, sonst die interne ID
      id_a = species_data_a.respond_to?(:id_number) ? species_data_a.id_number : species_data_a.id
      id_b = species_data_b.respond_to?(:id_number) ? species_data_b.id_number : species_data_b.id
      
      # Falls ID ein Symbol ist, konvertiere zu String und dann zu Hash für Vergleich
      if id_a.is_a?(Symbol)
        id_a = GameData::Species.keys.index(id_a) || 0
      end
      if id_b.is_a?(Symbol)
        id_b = GameData::Species.keys.index(id_b) || 0
      end
      
      comparison = id_a <=> id_b
      return comparison != 0 ? comparison : pokemon_a.name <=> pokemon_b.name
    end
    
    # Form ID comparison (species first, then form)
    def compare_form_id(pokemon_a, pokemon_b)
      species_comparison = compare_species_id(pokemon_a, pokemon_b)
      return species_comparison if species_comparison != 0
      
      form_a = pokemon_a.form || 0
      form_b = pokemon_b.form || 0
      form_comparison = form_a <=> form_b
      return form_comparison != 0 ? form_comparison : pokemon_a.name <=> pokemon_b.name
    end
  end
  
  #=============================================================================
  # Helper methods for sort descriptions
  #=============================================================================
  def self.get_sort_name(sort_method)
    case sort_method
    when :LEVEL_ASC then return _INTL("Nivel (Menor a Mayor)")
    when :LEVEL_DESC then return _INTL("Nivel (Mayor a Menor)")
    when :ALPHABET then return _INTL("Alfabetico (A-Z)")
    when :ALPHABET_REV then return _INTL("Alfabetico (Z-A)")
    when :TYPE_PRIMARY then return _INTL("Tipo Primario")
    when :TYPE_DUAL then return _INTL("Combinación de Tipos")
    when :CATCH_DATE then return _INTL("Fecha de Captura")
    when :SHINY_FIRST then return _INTL("Shiny Primero")
    when :SPECIES_ID then return _INTL("Dex Nacional")
    when :FORM_ID then return _INTL("Formas")
    when :FRIENDSHIP then return _INTL("Amistad")
    when :NATURE then return _INTL("Naturaleza")
    else return _INTL("Desconocido")
    end
  end
  
  def self.get_sort_description(sort_method)
    case sort_method
    when :LEVEL_ASC then return _INTL("Ordena por nivel de menor a mayor (1 a 100)")
    when :LEVEL_DESC then return _INTL("Ordena por nivel de mayor a menor (100 a 1)")
    when :ALPHABET then return _INTL("Ordena alfabeticamente de A a Z")
    when :ALPHABET_REV then return _INTL("Ordena alfabeticamente de Z a A")
    when :TYPE_PRIMARY then return _INTL("Ordena por tipo primario")
    when :TYPE_DUAL then return _INTL("Ordena por combinación de tipos")
    when :CATCH_DATE then return _INTL("Ordena por fecha de captura (nuevo a viejo)")
    when :SHINY_FIRST then return _INTL("Ordena por Shiny (primero los Shiny)")
    when :SPECIES_ID then return _INTL("Ordena por número de Dex Nacional")
    when :FORM_ID then return _INTL("Ordena por forma")
    when :FRIENDSHIP then return _INTL("Ordena por amistad")
    when :NATURE then return _INTL("Ordena por naturaleza")
    else return _INTL("Método de ordenamiento desconocido")
    end
  end
end 