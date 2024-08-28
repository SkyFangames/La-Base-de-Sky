class PokemonPokedex_Scene
  attr_reader :sprites
end

# Searches for a Pokémon in the dexlist based on the given text.
#
# @param text [String] The name of the Pokémon to search for.
# @param _char [String] (optional) The character to search for. Defaults to an empty string.
# @return [Boolean, nil] Returns `true` if the Pokémon is found and refreshes the dexlist. Returns `false` if no Pokémon is found.
class PokedexSearcher
    def initialize(dexlist, dex_instance)
      @dexlist = dexlist
      @dex_instance = dex_instance
      open_search_box
    end
  
    def open_search_box
      on_input = ->(text, char = '') { search_by_name(text, char) }
      term = pb_message_free_text_with_on_input(_INTL("¿Qué Pokémon desea buscar?"), "", false, 32, width = 240, on_input = on_input)
  
      return false if ['', nil].include?(term)
  
      search_by_name(term)
    end
  
    def search_by_name(text, _char = '')
      current_index = @dex_instance.sprites['pokedex'].index
      index = search(text, current_index, @dexlist.length)
      return @dex_instance.pbRefreshDexList(index) if index
  
      if current_index.positive?
        index = search(text, 0, current_index)
        return @dex_instance.pbRefreshDexList(index) if index
      end
      false
    end
  
    def search(text, start_index, end_index)
      @dexlist[start_index...end_index].each do |item|
        next unless valid_item?(item)
        return item[:number] - 1 if matches_name?(item, text)
      end
      false
    end
  
    def valid_item?(item)
      ($player.seen?(item[:species]) && !item[:shift]) || $player.seen?(item[:species])
    end
  
    def matches_name?(item, text)
      item[:name].downcase.include?(text.downcase)
    end
end
  