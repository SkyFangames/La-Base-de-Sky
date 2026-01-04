#===============================================================================
#  Luka's Scripting Utilities
#
#  Window sprite to render windowskin as bitmap
#===============================================================================
module LUTS
  module UI
    class Window < ::Sprites::Base
      # Renders a windowskip to bitmap
      # @param width [Integer]
      # @param height [Integer]
      # @param path [String]
      # @param slice [Rect]
      def set_bitmap(width:, height:, path:, slice:)
        window = SpriteHash.bitmap(path)
        output = ::Bitmap.new(width, height)

        # coordinates for the 9-slice sprite (slice)
        x1 = [0, slice.x, slice.x + slice.width]
        y1 = [0, slice.y, slice.y + slice.height]
        w1 = [slice.x, slice.width, window.width - slice.x - slice.width]
        h1 = [slice.y, slice.height, window.height - slice.y - slice.height]

        # coordinates for the 9-slice sprite (rect)
        x2 = [0, x1[1], width - w1[2]]
        y2 = [0, y1[1], height - h1[2]]
        w2 = [x1[1], width - x1[1] - w1[2], w1[2]]
        h2 = [y1[1], height - y1[1] - h1[2], h1[2]]

        # creates a 9-point matrix to slice up the window skin
        slice_matrix = []
        rect_matrix = []
        4.times do |y|
          4.times do |x|
            # matrix that handles cutting of the original window skin
            slice_matrix << Rect.new(x1[x], y1[y], w1[x], h1[y])
            # matrix that handles generating of the entire window
            rect_matrix << Rect.new(x2[x], y2[y], w2[x], h2[y])
          end
        end
        # fills window skin
        10.times do |i|
          output.stretch_blt(rect_matrix[i], window, slice_matrix[i])
        end
        window.dispose

        # returns the newly formed window
        self.bitmap = output
      end
    end
  end
end
