#===============================================================================
#  Luka's Scripting Utilities
#
#  New callback wrapper with variable passing
#===============================================================================
class CallbackWrapper
  # Instanciates a CallbackWrapper with the specified params
  # @param block [Proc]
  # @return [CallbackWrapper]
  def self.with_params(**kwargs, &block)
    new(&block).set_params(**kwargs)
  end

  # Callback constructor
  # @param block [Proc]
  # @return [CallbackWrapper]
  def initialize(&block)
    @block = block
    @wrapper = Object.new
  end

  # Execute callback
  def execute
    return unless block

    wrapper.instance_exec(&block)
  end

  # Set params as instance variables
  # @return [CallbackWrapper]
  def set_params(**kwargs)
    kwargs.each do |key, value|
      wrapper.instance_variable_set("@#{key}", value)
    end

    self
  end

  private

  # @return [Proc]
  attr_reader :block
  # @return [Object]
  attr_reader :wrapper
end
