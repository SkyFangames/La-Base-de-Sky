#===============================================================================
#  Plugin function bulk aliaser
#===============================================================================
module PluginManager
  module Aliaser
    #---------------------------------------------------------------------------
    #  extend the base class with new class methods
    #---------------------------------------------------------------------------
    def self.included(base)
      base.extend ClassMethods
    end
    #---------------------------------------------------------------------------
    #  class methods to include
    #---------------------------------------------------------------------------
    module ClassMethods
      # include a module in base class and alias any overlapping functions
      def alias_with_module(alias_module, extension = 'old')
        module_functions = alias_module.instance_methods(false).private_methods(false)
        module_functions.concat(private_instance_methods(false))
        name_pattern = /[a-zA-Z0-9_]+/
        misc_pattern = /[^a-zA-Z0-9_]+/
        map_methods_for_alias(alias_module).sort.each do |method_name|
          aliased_name = "#{method_name[name_pattern]}_#{extension}#{method_name[misc_pattern]}"
          next if method_defined?(aliased_name) || private_method_defined?(aliased_name)

          alias_method(aliased_name, method_name)
        end

        map_class_methods_for_alias(alias_module).sort.each do |method_name|
          aliased_name = "#{method_name[name_pattern]}_#{extension}#{method_name[misc_pattern]}"
          next if singleton_class.method_defined?(aliased_name)

          singleton_class.alias_method(aliased_name, method_name)
        end

        prepend(alias_module)
        singleton_class.prepend(alias_module::ClassMethods)
      end

      # get list of all defined instance and private methods
      def map_methods_for_alias(alias_module)
        module_methods = alias_module.instance_methods(false).concat(alias_module.private_instance_methods(false))
        all_methods = instance_methods(false).concat(private_methods(false))
        all_methods.concat(private_instance_methods(false))
        method_collection = all_methods.select { |method_name| module_methods.include?(method_name) }

        method_collection
      end

      # get list of all class methods (doesn't include private class methods)
      def map_class_methods_for_alias(alias_module)
        module_methods = alias_module::ClassMethods.instance_methods(false)
        all_methods = singleton_class.instance_methods(false)
        method_collection = all_methods.select { |method_name| module_methods.include?(method_name) }

        method_collection
      end
    end
    #---------------------------------------------------------------------------
  end
end
