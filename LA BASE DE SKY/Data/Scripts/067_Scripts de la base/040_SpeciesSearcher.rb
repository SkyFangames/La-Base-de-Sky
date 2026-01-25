# Searches for a Pokémon in the dexlist based on the given text.
# Inherits common search functionality from BaseSearcher.
#
# @example Usage
#   searcher = SpeciesSearcher.new(species_list)
class SpeciesSearcher < BaseSearcher
  def initialize(species_list, window, class_instance = nil)
    @species_list = species_list
    @window = window
    @class_instance = class_instance
    open_search_box(:left)
  end

  # Gets the Pokémon name from a dex entry.
  # @param item [Hash] A dex entry with :name key.
  # @return [String] The Pokémon's name.
  def get_item_name(item)
    item[3]
  end

  # Gets the dexlist to search through.
  # @return [Array<Hash>] The dex entries list.
  def get_search_list
    @species_list
  end

  # Gets the current selected index in the Pokédex.
  # @return [Integer] The current index.
  def get_current_index
    @window.index
  end

  # Refreshes the Pokédex display with the found Pokémon.
  # @param index [Integer] The dex number minus 1.
  def refresh_display(index)
    @window.index = index
    @class_instance.refresh if @class_instance
  end

  # Customized search prompt for Pokédex.
  # @return [String] The localized prompt text.
  def search_prompt
    _INTL("¿Qué Pokémon desea buscar?")
  end
end
  