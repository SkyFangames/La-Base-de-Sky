#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Nil` class
#===============================================================================
class ::NilClass
  # @return [Boolean]
  def blank?
    true
  end

  # @return [Boolean]
  def present?
    false
  end
end
