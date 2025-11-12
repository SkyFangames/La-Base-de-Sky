#===============================================================================
# Settings.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # Stores the path name for the graphics utilized by this plugin.
  #-----------------------------------------------------------------------------
  DELUXE_GRAPHICS_PATH = "Graphics/Plugins/Deluxe Battle Kit/"
  
  #-----------------------------------------------------------------------------
  # Shortens long move names in the fight menu so they can fit the default battle UI.
  #-----------------------------------------------------------------------------
  SHORTEN_MOVES = true
  
  #-----------------------------------------------------------------------------
  # When true, Pokemon databoxes will be hidden in battle during move animations.
  #-----------------------------------------------------------------------------
  HIDE_DATABOXES_DURING_MOVES = true
  
  #-----------------------------------------------------------------------------
  # Allows for different battle music to play when the player's Pokemon is at low HP.
  #-----------------------------------------------------------------------------
  PLAY_LOW_HP_MUSIC = false
  
  #-----------------------------------------------------------------------------
  # Toggles the appearance of the Mega Evolution animation used by this plugin.
  #-----------------------------------------------------------------------------
  SHOW_MEGA_ANIM = true
  
  #-----------------------------------------------------------------------------
  # Toggles the appearance of the Primal Reversion animation used by this plugin.
  #-----------------------------------------------------------------------------
  SHOW_PRIMAL_ANIM = true
  
  #-----------------------------------------------------------------------------
  # Sets how the overlay pattern on Shadow Pokemon animates.
  # The first entry in the array corresponds to X-axis movement.
  # The second entry in the array corresponds to Y-axis movement.
  #-----------------------------------------------------------------------------
  # X-Axis    Y-Axis
  # :none     :none 
  # :left     :up
  # :right    :down
  # :erratic  :erratic
  #-----------------------------------------------------------------------------
  SHADOW_PATTERN_MOVEMENT = [:none, :up]
  
  #-----------------------------------------------------------------------------
  # When true, existing sprites you have for Shadow Pokemon species won't
  # be given the shadow overlay pattern added by this plugin.
  # Set this to false to give Shadow Pokemon sprites this overlay too.
  #-----------------------------------------------------------------------------
  DONT_OVERLAY_EXISTING_SHADOW_SPRITES = true
end