#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Sprite` class
#===============================================================================
class ::Sprite
  # Allows sprite components to be animated easily
  include LUTS::Concerns::Animatable
  # Allows sprite components to use float values for smooth calculations
  include LUTS::Concerns::Floatable

  # @return [Boolean] if blank or present
  def in_viewport?
    return false unless viewport

    !(apparent_x + apparent_width  < viewport.x - 64 ||
      apparent_y + apparent_height < viewport.x - 64 ||
      apparent_x > viewport.x + viewport.width + 64 ||
      apparent_y > viewport.x + viewport.width + 64)
  end

  # @return [Numeric]
  def apparent_x
    x - ox * zoom_x
  end

  # @return [Numeric]
  def apparent_y
    y - oy * zoom_y
  end

  # @return [Numeric]
  def apparent_width
    src_rect.width * zoom_x
  end

  # @return [Numeric]
  def apparent_height
    src_rect.height * zoom_y
  end
end
