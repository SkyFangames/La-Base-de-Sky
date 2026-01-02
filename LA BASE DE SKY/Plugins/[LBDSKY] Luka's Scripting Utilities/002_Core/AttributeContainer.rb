#===============================================================================
#  Luka's Scripting Utilities
#
#  New `AttributeContainer` class for defining quick getter/setter with
#  default values
#===============================================================================
class AttributeContainer
  class << self
    # Defines setter and getter functions
    # @param key [Symbol]
    # @param default [Any]
    def with_attribute(key, default: nil)
      attribute_list[key] = default

      if default.is_a?(TrueClass) || default.is_a?(FalseClass)
        attr_accessor(key)

        define_method(:"#{key}?") do
          instance_variable_get("@#{key}")
        end
      else
        attr_accessor(key)
      end
    end

    # @return [Hash{Symbol => Any}]
    def attribute_list
      @attribute_list ||= {}
    end

    # @param subclass [Class]
    def inherited(subclass)
      subclass.instance_variable_set(:@attribute_list, attribute_list.dup)
    end
  end

  def initialize
    self.class.attribute_list.each do |key, value|
      instance_variable_set("@#{key}", value.dup)
    end
  end
end
