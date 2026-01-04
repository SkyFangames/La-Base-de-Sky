#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Array` data types
#===============================================================================
class ::Array
  # Swaps specific indexes
  # @param index1 [Integer]
  # @param index2 [Integer]
  def swap_at(index1, index2)
    val1 = self[index1].clone
    val2 = self[index2].clone
    self[index1] = val2
    self[index2] = val1
  end

  # Pushes value to last index
  # @param val [Object]
  def to_last(val)
    delete(val) if include?(val)
    push(val)
  end

  # @return [Boolean]
  def last?(index)
    (length - 1).eql?(index)
  end

  # @return [Boolean]
  def string_include?(val)
    return false unless val.is_a?(String)

    each do |a|
      return true if a.is_a?(String) && val.include?(a)
    end

    false
  end

  # @param index [Integer]
  # @return [Object]
  def value(index)
    self[index]
  end

  # @return [Boolean]
  def blank?
    empty?
  end

  # @return [Boolean]
  def present?
    !blank?
  end
end
