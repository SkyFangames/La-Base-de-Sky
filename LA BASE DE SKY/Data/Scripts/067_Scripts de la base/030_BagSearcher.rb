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
		on_input = ->(text, char = '') { search_by_name(text, itemwindow, char) }
		term = pb_message_free_text_with_on_input(_INTL("¿Qué objeto deseas buscar?"), "", false, 32, width = 240, on_input = on_input)

		return false if ['', nil].include?(term)

		search_by_name(term, itemwindow)
	end

	def search_by_name(text, itemwindow, _char = '')
		index = search(text, @current_index, @pocket.length)
		if index >= 0
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
			item_aux = GameData::Item.get(item[0])
			item_name = item_aux.is_machine? ? "#{item_aux.name} #{GameData::Move.get(item_aux.move).name}" : item_aux.name
			return start_index + index if matches_name?(item_name, text)
		end
		0
	end

	def matches_name?(item, text)
		item.downcase.include?(text.downcase) ? true : false
	end
end
