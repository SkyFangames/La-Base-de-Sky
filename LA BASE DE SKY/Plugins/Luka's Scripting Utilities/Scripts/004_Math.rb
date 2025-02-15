#===============================================================================
#  Mathematical utilities
#===============================================================================
module LUTS
  module Math
    class << self
      #-------------------------------------------------------------------------
      #  calculate XY coordinates for all points of a polygon
      #-------------------------------------------------------------------------
      def polygon_points(n, radius:, angle: 0, width:, height:)
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
      #-------------------------------------------------------------------------
      #  calculate random XY coodrinate on the circumference of a circle
      #-------------------------------------------------------------------------
      def rand_circle_coord(radius, x:)
        x ||= rand(radius * 2)

        y1 = -Math.sqrt(radius**2 - (x - radius)**2)
        y2 = Math.sqrt(radius**2 - (x - radius)**2)

        [x, (rand(2).zero? ? y1.to_i : y2.to_i) + r]
      end
      #-------------------------------------------------------------------------
    end
  end
end
