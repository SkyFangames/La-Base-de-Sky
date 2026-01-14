# Base class for creating searchable interfaces with text input.
# Provides common functionality for searching through collections of items.
#
# To create a new searcher:
# 1. Inherit from BaseSearcher
# 2. Implement required methods: #get_item_name, #get_search_list, #get_current_index, #refresh_display
# 3. Optionally override: #valid_item?, #search_prompt, #on_search_complete
#
# @example Creating a custom searcher
#   class MyCustomSearcher < BaseSearcher
#     def get_item_name(item)
#       item.name
#     end
#
#     def get_search_list
#       @my_list
#     end
#
#     def get_current_index
#       @current_index
#     end
#
#     def refresh_display(index)
#       @display.update(index)
#     end
#   end
class BaseSearcher
  SEARCH_BOX_MAX_LENGTH = 32
  SEARCH_BOX_WIDTH = 240

  # Opens the search box and initiates the search process.
  # @return [Boolean, Integer] Returns false if search is cancelled, otherwise returns search result.
  def open_search_box
    on_input = ->(text, char = '') { search_by_name(text, char) }
    term = pb_message_free_text_with_on_input(search_prompt, "", false, SEARCH_BOX_MAX_LENGTH, width = SEARCH_BOX_WIDTH, on_input = on_input)

    return false if ['', nil].include?(term)

    search_by_name(term)
  end

  # Searches for items by name, wrapping around the list if necessary.
  # @param text [String] The search term.
  # @param _char [String] Optional character parameter (for compatibility with on_input callback).
  # @return [Boolean, Integer] Returns the index if found, false otherwise.
  def search_by_name(text, _char = '')
    current_index = get_current_index
    search_list = get_search_list
    
    # Search from current position to end
    index = search(text, current_index, search_list.length)
    return on_search_complete(index) if index

    # Wrap around: search from beginning to current position
    if current_index.positive?
      index = search(text, 0, current_index)
      return on_search_complete(index) if index
    end
    
    false
  end

  # Searches through a range of items in the list.
  # @param text [String] The search term.
  # @param start_index [Integer] Starting index for the search.
  # @param end_index [Integer] Ending index for the search.
  # @return [Integer, Boolean] Returns the index if found, false otherwise.
  def search(text, start_index, end_index)
    get_search_list[start_index...end_index].each_with_index do |item, offset|
      next unless valid_item?(item)
      
      item_name = get_item_name(item)
      return start_index + offset if matches_name?(item_name, text)
    end
    false
  end

  # Checks if an item name matches the search text (case-insensitive).
  # @param item_name [String] The item name to check.
  # @param text [String] The search text.
  # @return [Boolean] True if the name contains the search text.
  def matches_name?(item_name, text)
    item_name.downcase.include?(text.downcase)
  end

  # Validates whether an item should be included in the search.
  # Override this method to implement custom validation logic.
  # @param item [Object] The item to validate.
  # @return [Boolean] True if the item is valid for searching.
  def valid_item?(item)
    true
  end

  # Called when a search successfully finds an item.
  # Override this to customize behavior after finding an item.
  # @param index [Integer] The index of the found item.
  # @return [Integer] The index (or transformed value).
  def on_search_complete(index)
    refresh_display(index)
    index
  end

  # ========== ABSTRACT METHODS - Must be implemented by subclasses ==========

  # Gets the display name for an item.
  # @abstract
  # @param item [Object] The item to get the name from.
  # @return [String] The item's name.
  def get_item_name(item)
    raise NotImplementedError, "#{self.class} must implement #get_item_name"
  end

  # Gets the list to search through.
  # @abstract
  # @return [Array] The searchable list.
  def get_search_list
    raise NotImplementedError, "#{self.class} must implement #get_search_list"
  end

  # Gets the current index in the list.
  # @abstract
  # @return [Integer] The current index.
  def get_current_index
    raise NotImplementedError, "#{self.class} must implement #get_current_index"
  end

  # Refreshes the display with the new index.
  # @abstract
  # @param index [Integer] The index to display.
  def refresh_display(index)
    raise NotImplementedError, "#{self.class} must implement #refresh_display"
  end

  # Gets the prompt text for the search box.
  # Override this to customize the search prompt.
  # @return [String] The prompt text.
  def search_prompt
    _INTL("¿Qué deseas buscar?")
  end
end
