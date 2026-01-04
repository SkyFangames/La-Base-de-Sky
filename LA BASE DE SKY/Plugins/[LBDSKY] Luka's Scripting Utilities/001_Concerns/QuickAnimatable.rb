#===============================================================================
#  Luka's Scripting Utilities
#
#  * Various object extensions
#===============================================================================
module LUTS
  #  Animation engine extensions.
  #    Adds helper functions to quickly define and play a set of animations.
  #    Requires the use of a sprite hash.
  #    Animation sets are added in the format: [duration, {}]
  #      <Hash> contains key-value pairs of symbolic sprite name and attributes
  #      @example:
  #        [10, { base: { x: 120, y: 120 } }]
  module QuickAnimatable
    # Plays animation from defined array.
    # Validates initially if required functions exist
    def play_quick_animation
      return unless validate_animation_class

      quick_animation_array.each do |value|
        duration, anim = value
        Graphics.animate(duration) do
          anim.each do |key, args|
            (key.eql?(:viewport) ? viewport : sprites[key]).animate(**args)
          end

          update
        end
      end
    end

    private

    # Method containing the animation array
    def quick_animation_array
      raise NotImplementedError
    end

    # Validates the class module is included in to respond to
    # all required functions.
    def validate_animation_class
      [:sprites, :viewport, :update].each do |func|
        unless respond_to?(func, true)
          LUTS::ErrorMessages::MissingFunctionError.new(self.class.name, func).raise
          return false
        end
      end

      true
    end
  end
end
