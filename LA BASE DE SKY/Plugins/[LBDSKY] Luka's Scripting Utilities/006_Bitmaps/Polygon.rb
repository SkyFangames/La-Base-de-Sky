#===============================================================================
#  Luka's Scripting Utilities
#
#  Additional bitmap components
#===============================================================================
module Bitmaps
  # Class used to draw polygons onto bitmaps
  class Polygon < ::Bitmap
    # @param width [Integer]
    # @param height [Integer]
    def initialize(width, height)
      super(width, height)
      @vertices = []
    end

    # Statically adds vertex to polygon
    # @param x [Integer]
    # @param y [Integer]
    def add_vertex(x:, y:)
      @vertices << [x, y]
    end

    # Calculates vertex point
    # @param percent [Numeric]
    # @param angle [Integer]
    def calc_vertex(percent:, angle:)
      center_x = width / 2.0
      center_y = height / 2.0
      angle_radians = (angle % 360) * Math::PI / 180.0
      distance = percent * width / 2.0
      x = center_x + distance * Math.cos(angle_radians)
      y = center_y - distance * Math.sin(angle_radians)
      @vertices << [x.round, y.round]
    end

    # Renders polygon with specified color - optimized scanline algorithm
    # @param color [Color]
    def render(color = Color.black)
      return LUTS::ErrorMessages::VertexError.new(3).raise if @vertices.length < 3

      # Sort vertices by angle from center
      @vertices.sort! do |a, b|
        angle_a = Math.atan2(height / 2.0 - a[1], a[0] - width / 2.0)
        angle_b = Math.atan2(height / 2.0 - b[1], b[0] - width / 2.0)
        angle_a <=> angle_b
      end

      # Calculate bounding box
      min_x = @vertices.map { |v| v[0] }.min.clamp(0, width - 1)
      max_x = @vertices.map { |v| v[0] }.max.clamp(0, width - 1)
      min_y = @vertices.map { |v| v[1] }.min.clamp(0, height - 1)
      max_y = @vertices.map { |v| v[1] }.max.clamp(0, height - 1)

      # Build edge table for scanline algorithm
      edges = []
      n = @vertices.length
      n.times do |i|
        j = (i + 1) % n
        x1, y1 = @vertices[i]
        x2, y2 = @vertices[j]

        # Skip horizontal edges
        next if y1 == y2

        # Ensure y1 < y2
        x1, y1, x2, y2 = x2, y2, x1, y1 if y1 > y2

        # Calculate inverse slope
        dx_dy = (x2 - x1).to_f / (y2 - y1)
        edges << [y1, y2, x1.to_f, dx_dy]
      end

      # Get raw pixel data once
      pixels = raw_data.unpack('C*')

      # Pre-calculate color values
      r, g, b, a = color.red, color.green, color.blue, color.alpha

      # Scanline fill
      (min_y..max_y).each do |y|
        # Find active edges at this scanline
        intersections = []
        edges.each do |y_min, y_max, x_start, dx_dy|
          if y >= y_min && y < y_max
            x = x_start + (y - y_min) * dx_dy
            intersections << x.round
          end
        end

        # Sort intersections and fill between pairs
        intersections.sort!
        i = 0
        while i < intersections.length - 1
          x_start = intersections[i].clamp(min_x, max_x)
          x_end = intersections[i + 1].clamp(min_x, max_x)

          (x_start..x_end).each do |x|
            idx = (y * width + x) * 4
            pixels[idx]     = r
            pixels[idx + 1] = g
            pixels[idx + 2] = b
            pixels[idx + 3] = a
          end

          i += 2
        end
      end

      # Write back once
      self.raw_data = pixels.pack('C*')
      @vertices.clear
    end

    private

    # Optimized point-in-polygon test with integer arithmetic where possible
    # @param x [Integer]
    # @param y [Integer]
    # @return [Boolean]
    def point_in_polygon_fast?(x, y)
      inside = false
      j = @vertices.length - 1

      @vertices.length.times do |i|
        xi, yi = @vertices[i]
        xj, yj = @vertices[j]

        if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
          inside = !inside
        end
        j = i
      end

      inside
    end
  end
end
