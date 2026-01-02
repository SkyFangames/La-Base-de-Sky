#===============================================================================
#  Luka's Scripting Utilities
#
#  * Various object extensions
#===============================================================================
module LUTS
  module Concerns
    #  Animation automation module.
    #  Registers attribute values that will be used when calculating
    #  the animation progress
    module Animatable
      #  @param options [Hash{Symbol => Numeric}]
      def animate(options)
        return if animating?

        @anim_target = {}.tap do |hash|
          next hash[options] = nil if options.is_a?(Symbol)

          options.each do |property, value|
            next unless respond_to?(property)

            hash[property] = [send(property), send(property), value]
          end
        end
        Graphics.target_object_cache << self
      end

      # @return [Hash{Symbol => Numeric}]
      def anim_target
        @anim_target ||= {}
      end

      # @param duration [Integer] duration in frames (with a target FPS of 60)
      def play_target_animation(duration)
        # animates each property specified for object
        anim_target.each do |property, value|
          next send(property) if respond_to?(property) && value.nil?
          next unless respond_to?("#{property}=")

          k = value.first < value.last ? 1 : -1
          next unless k * (value.last - send(property)) > 0

          diff = value.last - value.first
          if duration.positive?
            anim_target[property][1] += (diff / duration.to_f).lerp
          else
            anim_target[property][1] = value.last
          end
          # increment values based on delta interpolation
          send("#{property}=", anim_target[property][1])
        end
      end

      # Clear currently animating values
      def clear_anim_target
        anim_target.clear
      end

      # @return [Boolean]
      def animating?
        !anim_target.empty?
      end
    end
  end
end
