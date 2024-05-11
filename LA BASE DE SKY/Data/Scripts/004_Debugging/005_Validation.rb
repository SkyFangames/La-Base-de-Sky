# El módulo Kernel se amplía para incluir el método de validación.
module Kernel
  private

  # Utilizado para comprobar si los argumentos de un método son de una clase dada o responden a un método.
  # @param value_pairs [Hash{Object => Class, Array<Class>, Symbol}] pares de valores a validar
  # @example Validar una clase o método
  #   validate foo => Integer, baz => :to_s # lanza un error si foo no es un Integer o si baz no implementa #to_s
  # @example Validar una clase desde un array
  #   validate foo => [Sprite, Bitmap, Viewport] # lanza un error si foo no es un Sprite, Bitmap o Viewport
  # @raise [ArgumentError] si la validación falla
  def validate(value_pairs)
    unless value_pairs.is_a?(Hash)
      raise ArgumentError, "El argumento sin hash #{value_pairs.inspect} se pasó a validar."
    end
    errors = value_pairs.map do |value, condition|
      if condition.is_a?(Array)
        unless condition.any? { |klass| value.is_a?(klass) }
          next "Se esperaba que #{value.inspect} fuera uno de #{condition.inspect}, pero se obtuvo #{value.class.name}."
        end
      elsif condition.is_a?(Symbol)
        next "Se esperaba que #{value.inspect} respondiera a #{condition}." unless value.respond_to?(condition)
      elsif !value.is_a?(condition)
        next "Se esperaba que #{value.inspect} fuera #{condition.name}, pero se obtuvo #{value.class.name}."
      end
    end
    errors.compact!
    return if errors.empty?
    raise ArgumentError, "Argumento no válido pasado al método.\r\n" + errors.join("\r\n")
  end
end

