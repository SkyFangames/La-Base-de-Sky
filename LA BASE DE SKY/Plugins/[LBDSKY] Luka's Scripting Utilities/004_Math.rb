#===============================================================================
#  Luka's Scripting Utilities
#
#  Mathematical utilities
#===============================================================================
module LUTS
  module Math
    class << self
      # Calculates XY coordinates for all points of a polygon
      # @param n [Integer]
      # @param radius [Integer]
      # @param width [Integer]
      # @param height [Integer]
      # @param angle [Integer]
      def polygon_points(n, radius:, width:, height:, angle: 0)
        step = 360 / n

        [].tap do |points|
          n.times do
            x = width + radius * Math.cos(angle * (Math::PI / 180))
            y = height - radius * Math.sin(angle * (Math::PI / 180))
            points << [x, y]
            angle += step
          end
        end
      end

      # Calculates random XY coodrinate on the circumference of a circle
      # @param radius [Integer]
      # @param x [Integer]
      def rand_circle_coord(radius, x:)
        x ||= rand(radius * 2)

        y1 = -Math.sqrt(radius**2 - (x - radius)**2)
        y2 = Math.sqrt(radius**2 - (x - radius)**2)

        [x, (rand(2).zero? ? y1.to_i : y2.to_i) + r]
      end
    end
  end
end
