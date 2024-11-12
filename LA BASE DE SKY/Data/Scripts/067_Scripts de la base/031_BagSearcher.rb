	class Window_PokemonBag < Window_DrawableCommand
		attr_reader :sprites
	end

	# Searches for a Item in the bag pocket based on the given text.
	#
	# @param text [String] The name of the Pokémon to search for.
	# @param _char [String] (optional) The character to search for. Defaults to an empty string.
	# @return [Boolean, nil] Returns `true` if the Pokémon is found and refreshes the dexlist. Returns `false` if no Pokémon is found.
class BagSearcher
	def initialize(pocket, itemwindow, bag)
		@pocket = pocket
		@bag_instance = bag
		@current_index = itemwindow.index
		@itemwindow = itemwindow
		open_search_box(itemwindow)
	end

	def open_search_box(itemwindow)
		on_input = ->(text, char = '') { search_by_name(text, char, itemwindow) }
		term = pb_message_free_text_with_on_input(_INTL("¿Qué objeto desea buscar?"), "", false, 32, width = 240, on_input = on_input)

		return false if ['', nil].include?(term)

		search_by_name(term)
	end

	def search_by_name(text, _char = '', itemwindow)
		index = search(text, @current_index, @pocket.length)
		if index
			@current_index = index
			itemwindow.index = index
			@bag_instance.pbRefresh
			return index
		end

		if @current_index.positive?
				index = search(text, 0, @current_index)
				if index
					@current_index = index
					itemwindow.index = index
					@bag_instance.pbRefresh
					return index
				end
		end
		false
	end

	def search(text, start_index, end_index)
		@pocket[start_index...end_index].each_with_index do |item, index|
				# next unless valid_item?(item[0])
			return start_index + index if matches_name?(GameData::Item.get(item[0]).name, text)
		end
		false
	end

	def valid_item?(item)
		($player.seen?(item[:species]) && !item[:shift]) || $player.seen?(item[:species])
	end

	def matches_name?(item, text)
		item.downcase.include?(text.downcase) ? true : false
	end
end
