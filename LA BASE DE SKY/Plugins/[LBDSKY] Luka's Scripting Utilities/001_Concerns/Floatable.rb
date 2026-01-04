#===============================================================================
#  Luka's Scripting Utilities
#
#  * Various object extensions
#===============================================================================
module LUTS
  module Concerns
    # Floatable concern that implents new float value components for smooth
    # calculations.
    module Floatable
      # @return [FloatValues]
      def float
        @float ||= FloatValues.new(self)
      end
    end
  end
end
