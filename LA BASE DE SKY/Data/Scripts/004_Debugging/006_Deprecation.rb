# El módulo Deprecation se utiliza para advertir a los creadores de juegos y 
# plugins sobre métodos obsoletos.
module Deprecation
  module_function

  # Envía una advertencia sobre un método obsoleto a la consola de depuración.
  # @param method_name [String] nombre del método obsoleto
  # @param removal_version [String] versión en la que se elimina el método
  # @param alternative [String] método alternativo preferido
  def warn_method(method_name, removal_version = nil, alternative = nil)
    text = _INTL('Uso de un método obsoleto "{1}" o su alias.', method_name)
    unless removal_version.nil?
      text += "\n" + _INTL("El método está programado para eliminarse en Essentials {1}.", removal_version)
    end
    unless alternative.nil?
      text += "\n" + _INTL("Usa \"{1}\" en su lugar.", alternative)
    end
    Console.echo_warn text
  end
end

# La clase Module se extiende para permitir la fácil obsolescencia de métodos de instancia y de clase.
class Module
  private

  # Crea un alias obsoleto para un método.
  # Usar esto envía una advertencia a la consola de depuración.
  # @param name [Symbol] nombre del nuevo alias
  # @param aliased_method [Symbol] nombre del método aliado
  # @param removal_in [String] versión en la que se elimina el alias
  # @param class_method [Boolean] si el método es un método de clase
  def deprecated_method_alias(name, aliased_method, removal_in: nil, class_method: false)
    validate name => Symbol, aliased_method => Symbol, removal_in => [NilClass, String],
             class_method => [TrueClass, FalseClass]

    target = class_method ? self.class : self
    class_name = self.name

    unless target.method_defined?(aliased_method)
      raise ArgumentError, "#{class_name} no tiene el método #{aliased_method} definido"
    end

    delimiter = class_method ? "." : "#"

    target.define_method(name) do |*args, **kvargs|
      alias_name = sprintf("%s%s%s", class_name, delimiter, name)
      aliased_method_name = sprintf("%s%s%s", class_name, delimiter, aliased_method)
      Deprecation.warn_method(alias_name, removal_in, aliased_method_name)
      method(aliased_method).call(*args, **kvargs)
    end
  end
end

