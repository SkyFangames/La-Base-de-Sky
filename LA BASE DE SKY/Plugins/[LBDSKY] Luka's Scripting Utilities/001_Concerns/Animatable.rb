#===============================================================================
#  Animation engine extensions
#===============================================================================
module LUTS
  module Concerns
    module Animatable
      #-------------------------------------------------------------------------
      #  animation automation
      #-------------------------------------------------------------------------
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

      def anim_target
        @anim_target ||= {}
      end

      def play_target_animation(duration)
        # animates each property specified for object
        anim_target.each do |property, value|
          next send(property) if respond_to?(property) && value.nil?
          next unless respond_to?("#{property}=")

          k = value.first < value.last ? 1 : -1
          next unless k * (value.last - send(property)) > 0

          diff = value.last - value.first
          anim_target[property][1] += (diff / duration.to_f).lerp
          # increment values based on delta interpolation
          send("#{property}=", anim_target[property][1])
        end
      end

      def clear_anim_target
        anim_target.clear
      end

      def animating?
        !anim_target.empty?
      end
      #-------------------------------------------------------------------------
    end
  end
end
