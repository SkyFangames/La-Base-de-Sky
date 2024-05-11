#===============================================================================
# * Pokegear Settings
#===============================================================================

module PokegearConfig
  # Change the space between icons
  COLUMN_WIDTH = 148    #Default: 138
  COLUMN_SPACING = 0
  # Increase the number to reduce the height between buttons.
  BUTTON_HEIGHT_SPACING = 1.4    #Default: 1.4

  THEME_COLUMN_WIDTH = 148    #Default: 138
  THEME_COLUMN_SPACING = 0
  # Increase the number to reduce the height between buttons.
  THEME_BUTTON_HEIGHT_SPACING = 1.4    #Default: 1.4

  # Change the number of columns the icon use. Default: 1
  # If column_count is used instead of a number, the number of columns will change based on the amount
  # of icons in display
  NUM_COLUMNS = 3

  THEME_NUM_COLUMNS = 3

  # The name of the themes that need a diferent button position
  SPECIAL_THEME = [
    "Theme 5", "EXAMPLE"
  ]

  # Used to change the position of the icons in the pokegear depending of the theme
  # Has to be defined for every theme added in SPECIAL_THEME
  # Default: 10
  BUTTON_HEIGHT = [
    30, 10
  ]

  # Used to change the position of the icons in the pokegear theme selection depending of the theme
  # Has to be defined for every theme added in SPECIAL_THEME
  # Default: 30
  THEME_BUTTON_HEIGHT = [
    30, 30
  ]

  # The path for the background to use for Arcky's Region Map.
  BACKGROUND_PATH = _INTL("Graphics/UI/Town Map/UI/")
end
