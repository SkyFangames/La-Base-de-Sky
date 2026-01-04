#===============================================================================
#  Luka's Scripting Utilities
#
#  * Various object extensions
#===============================================================================
module LUTS
  module Concerns
    # Block constructor module to allow passing of blocks when instanciating
    # new objects. Alternative to the `.tap` method.
    module BlockConstructor
      alias with_block_constructor_initialize initialize
      def initialize(*args, &block)
        with_block_constructor_initialize(*args)

        block.call(self) if block_given?
      end
    end
  end
end
