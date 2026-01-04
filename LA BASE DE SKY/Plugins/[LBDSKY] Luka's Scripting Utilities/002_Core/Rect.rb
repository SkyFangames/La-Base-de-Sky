#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Rect` class
#===============================================================================
class ::Rect
  # Allows rect components to be animated easily
  include ::LUTS::Concerns::Animatable

  def update; end
end
