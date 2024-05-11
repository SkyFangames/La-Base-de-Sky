#===============================================================================
# Pokedex settings.
#===============================================================================
class PokemonPokedexInfo_Scene
  #-----------------------------------------------------------------------------
  # Sets the maximum number of page icons that can be displayed on screen at once.
  # Pages that exceed this maximum will shift over all previous icons when you
  # scroll to that page. (Default: 5)
  #-----------------------------------------------------------------------------
  MAX_PAGE_ICONS = 5
  
  #-----------------------------------------------------------------------------
  # Toggles whether arrows should appear beside the row of page icons. 
  # (Default: true)
  #-----------------------------------------------------------------------------
  PAGE_ICONS_SHOW_ARROWS = true
  
  #-----------------------------------------------------------------------------
  # Sets the X and Y coordinates for the page icons. (Default: [30, 2])
  #-----------------------------------------------------------------------------
  PAGE_ICONS_POSITION = [30, 2]
  
  #-----------------------------------------------------------------------------
  # Sets the alignment for page icons relative to their coordinates above.
  # Can be set to :left, :right, or :center. (Default: :center)
  #-----------------------------------------------------------------------------
  PAGE_ICONS_ALIGNMENT = :center
  
  #-----------------------------------------------------------------------------
  # Sets the width and height (in pixels) of each individual icon sprite.
  # Remember that the height of the icon set here should be half of the size of
  # the actual height of the graphic, since both the highlighted and unhighlighted
  # versions of the icon are contained in the same graphic. (Default: [86, 28])
  #-----------------------------------------------------------------------------
  PAGE_ICON_SIZE = [86, 28]
  
  
  ##############################################################################
  
  #-----------------------------------------------------------------------------
  # This method exists simply so that it may be edited to add a special mechanic
  # when the USE button is pressed on a specific page.
  #-----------------------------------------------------------------------------
  # "page_id" refers to the symbol ID of the particular page (ex. :page_info).
  #-----------------------------------------------------------------------------
  # This method must return true if your custom code properly runs.
  #-----------------------------------------------------------------------------
  def pbPageCustomUse(page_id)
    #---------------------------------------------------------------------------
    # Example
    #---------------------------------------------------------------------------
    if page_id == :page_mining
      pbMessage(_INTL("Begin mining mini-game."))
      pbMiningGame
      return true
    end
    #---------------------------------------------------------------------------
    return false
  end
end