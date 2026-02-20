#===============================================================================
#  Luka's Scripting Utilities
#
#  New class to handle float values for smooth calculations.
#===============================================================================
class FloatValues
  # Methods to define as possible float values
  # @return [Array<Symbol>]
  METHODS = [
    :x, :y, :ox, :oy, :width, :height, :opacity, :angle
  ].freeze

  # A bit of metaprogramming to define setters and getters for above method names
  METHODS.each do |name|
    # Defines the getter function
    attr_reader name

    # Defines the setter function
    define_method(:"#{name}=") do |value|
      instance_variable_set(:"@#{name}", value)
      object.send(:"#{name}=", value) if object.respond_to?(:"#{name}=")
    end
  end

  # @param object [Object]
  def initialize(object)
    @object = object

    # Initializes beginning values
    METHODS.each do |name|
      instance_variable_set(:"@#{name}", (@object.respond_to?(name) ? @object.send(name) : 0))
    end
  end

  private

  # @return [Object]
  attr_reader :object
end
