class PokemonPokedex_Scene
  attr_reader :sprites
end

# Searches for a Pokémon in the dexlist based on the given text.
# Inherits common search functionality from BaseSearcher.
#
# @example Usage
#   searcher = PokedexSearcher.new(dexlist, dex_instance)
class PokedexSearcher < BaseSearcher
  def initialize(dexlist, dex_instance)
    @dexlist = dexlist
    @dex_instance = dex_instance
    open_search_box
  end

  # Gets the Pokémon name from a dex entry.
  # @param item [Hash] A dex entry with :name key.
  # @return [String] The Pokémon's name.
  def get_item_name(item)
    item[:name]
  end

  # Gets the dexlist to search through.
  # @return [Array<Hash>] The dex entries list.
  def get_search_list
    @dexlist
  end

  # Gets the current selected index in the Pokédex.
  # @return [Integer] The current index.
  def get_current_index
    @dex_instance.sprites['pokedex'].index
  end

  # Refreshes the Pokédex display with the found Pokémon.
  # @param index [Integer] The dex number minus 1.
  def refresh_display(index)
    @dex_instance.pbRefreshDexList(index)
  end

  # Validates if a Pokémon entry should be searchable.
  # Only seen Pokémon (excluding shift entries) are valid.
  # @param item [Hash] A dex entry with :species and :shift keys.
  # @return [Boolean] True if the Pokémon has been seen.
  def valid_item?(item)
    ($player.seen?(item[:species]) && !item[:shift]) || $player.seen?(item[:species])
  end

  # Transforms the found index to the correct dex number format.
  # @param index [Integer] The array index where the Pokémon was found.
  # @return [Integer] The dex number minus 1.
  def on_search_complete(index)
    return false unless index
    dex_number = @dexlist[index][:number] - 1
    refresh_display(dex_number)
    dex_number
  end

  # Customized search prompt for Pokédex.
  # @return [String] The localized prompt text.
  def search_prompt
    _INTL("¿Qué Pokémon desea buscar?")
  end
end
  