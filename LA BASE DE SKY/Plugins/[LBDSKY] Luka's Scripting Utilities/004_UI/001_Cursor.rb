#===============================================================================
#  UI class to generate selection cursor
#===============================================================================
module LUTS
  module UI
    class Cursor < ::Sprites::Sheet
      #-------------------------------------------------------------------------
      attr_accessor :filename, :anchor
      #-------------------------------------------------------------------------
      #  sets sheet bitmap
      #-------------------------------------------------------------------------
      def render(rect, file: nil, vertical: false)
        @filename ||= file
        @cur_frame  = 0
        @speed      = 4
        src_rect.x  = 0
        src_rect.y  = 0

        set_bitmap(sel_bitmap(@filename, rect), vertical)
        center!
      end
      #-------------------------------------------------------------------------
      #  target sprite with selector
      #-------------------------------------------------------------------------
      def target(sprite)
        return unless sprite.respond_to?(:set_bitmap)

        render(Rect.new(0, 0, sprite.width, sprite.height))
        self.anchor = sprite
      end
      #-------------------------------------------------------------------------
      #  update sprite
      #-------------------------------------------------------------------------
      def update
        super

        return unless anchor

        self.x       = anchor.x - anchor.ox + anchor.width / 2
        self.y       = anchor.y - anchor.oy + anchor.height / 2
        self.opacity = anchor.opacity
        self.visible = anchor.visible
      end

      private
      #-------------------------------------------------------------------------
      #  renders selection bitmap for cursor
      #-------------------------------------------------------------------------
      def sel_bitmap(path, rect)
        bmp   = SpriteHash.bitmap(path)
        qw    = bmp.width / 2
        qh    = bmp.height / 2
        max_w = rect.width + qw * 2 - 8
        max_h = rect.height + qh * 2 - 8
        full  = ::Bitmap.new(max_w * 4, max_h)

        # draws 4 frames where corners of selection get closer to bounding rect
        5.times do |i|
          5.times do |j|
            m = i < 3 ? i : i - 2
            x = (j.even? ? 2 : -2) * m + max_w * i + (j.even? ? 0 : max_w - qw)
            y = ((j / 2).zero? ? 2 : -2) * m + ((j / 2).zero? ? 0 : max_h - qh)
            full.blt(x, y, bmp, Rect.new(qw * (j % 2), qh * (j / 2), qw, qh))
          end
        end

        full
      end
      #-------------------------------------------------------------------------
    end
  end
end
