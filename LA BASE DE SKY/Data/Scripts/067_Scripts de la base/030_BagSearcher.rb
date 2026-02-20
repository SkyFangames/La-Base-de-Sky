# Searches for an item in the bag pocket based on the given text.
# Inherits common search functionality from BaseSearcher.
#
# @example Usage
#   searcher = BagSearcher.new(pocket, itemwindow, bag)
class BagSearcher < BaseSearcher
	def initialize(pocket, itemwindow, bag)
		@pocket = pocket
		@bag_instance = bag
		@current_index = itemwindow.index
		@itemwindow = itemwindow
		open_search_box
	end

	# Gets the item name, including TM/HM move names for machines.
	# @param item [Array] An item entry [item_id, quantity].
	# @return [String] The item's display name.
	def get_item_name(item)
		item_data = GameData::Item.get(item[0])
		if item_data.is_machine?
			"#{item_data.name} #{GameData::Move.get(item_data.move).name}"
		else
			item_data.name
		end
	end

	# Gets the pocket list to search through.
	# @return [Array] The bag pocket items.
	def get_search_list
		@pocket
	end

	# Gets the current selected index in the bag.
	# @return [Integer] The current index.
	def get_current_index
		@current_index
	end

	# Refreshes the bag display and updates the current index.
	# @param index [Integer] The index of the found item.
	def refresh_display(index)
		@current_index = index
		@itemwindow.index = index
		@bag_instance.pbRefresh
	end

	# Customized search prompt for bag items.
	# @return [String] The localized prompt text.
	def search_prompt
		_INTL("¿Qué objeto deseas buscar?")
	end
end
