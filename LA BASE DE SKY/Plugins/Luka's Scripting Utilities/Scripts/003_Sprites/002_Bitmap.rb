#===============================================================================
#  Extensions for the `Bitmap` class
#===============================================================================
module Sprites
  class Bitmap < ::Bitmap
    #-------------------------------------------------------------------------
    attr_accessor :path

    def initialize(*args)
      @path = args.first if args.first.is_a?(String)

      super(*args)
    end
    #-------------------------------------------------------------------------
    #  draws circle on bitmap
    #-------------------------------------------------------------------------
    def draw_circle(color, radius:, hollow: false)
      # basic circle formula
      # (x - center_x)**2 + (y - center_y)**2 = r**2
      width.times do |x|
        f = (radius**2 - (x - width / 2)**2)
        next if f < 0

        y1 = -Math.sqrt(f).to_i + height / 2
        y2 = Math.sqrt(f).to_i + height / 2

        if hollow
          set_pixel(x, y1, color)
          set_pixel(x, y2, color)
        else
          fill_rect(x, y1, 1, y2 - y1, color)
        end
      end
    end
    #-------------------------------------------------------------------------
    #  sets font parameters
    #-------------------------------------------------------------------------
    def set_font(name:, size:, bold: false)
      font.name = name
      font.size = size
      font.bold = bold
    end
    #-------------------------------------------------------------------------
    #  applies mask on bitmap
    #-------------------------------------------------------------------------
    def mask!(mask = nil, offset_x: 0, offset_y: 0)
      bitmap = clone
      if mask.is_a?(Bitmap)
        mbmp = mask
      elsif mask.is_a?(Sprite)
        mbmp = mask.bitmap
      elsif mask.is_a?(String)
        mbmp = Sprites.bitmap(mask)
      else
        return false
      end

      cbmp = Bitmap.new(mbmp.width, mbmp.height)
      mask = mbmp.clone
      ox = (bitmap.width - mbmp.width) / 2
      oy = (bitmap.height - mbmp.height) / 2
      width = mbmp.width + ox
      height = mbmp.height + oy

      (oy...height).each do |y|
        (ox...width).each do |x|
          pixel = mask.get_pixel(x - ox, y - oy)
          color = bitmap.get_pixel(x - offset_x, y - offset_y)
          alpha = pixel.alpha
          alpha = color.alpha if color.alpha < pixel.alpha

          cbmp.set_pixel(x - ox, y - oy, Color.new(color.red, color.green, color.blue, alpha))
        end
      end

      mask.dispose
      cbmp
    end
    #-------------------------------------------------------------------------
    #  swap out specified colors (resource intensive, best not use on large sprites)
    #-------------------------------------------------------------------------
    def swap_colors(bmp)
      map = {}.tap do |map_hash|
        bmp.width.times do |x|
          start = bmp.get_pixel(x, 0)
          final = bmp.get_pixel(x, 1)

          map_hash[[start.red, start.green, start.blue]] = [final.red, final.green, final.blue]
        end
      end
      # failsafe
      return unless map.is_a?(Hash)

      # iterate over sprite's pixels
      width.times do |x|
        height.times do |y|
          pixel = get_pixel(x, y)
          next if pixel.alpha == 0

          final = nil
          map.keys.each do |key|
            # check for key mapping
            target = Color.new(*key)
            final  = Color.new(*map[key]) if tolerance?(pixel, target)
          end
          # swap current pixel color with target
          set_pixel(x, y, final) if final && final.is_a?(Color)
        end
      end
    end

    def tolerance?(pixel, target)
      tol = 0.05

      return false unless pixel.red.between?(target.red - target.red * tol, target.red + target.red * tol)
      return false unless pixel.green.between?(target.green - target.green * tol, target.green + target.green * tol)
      return false unless pixel.blue.between?(target.blue - target.blue * tol, target.blue + target.blue * tol)

      true
    end
    #-------------------------------------------------------------------------
  end
end
