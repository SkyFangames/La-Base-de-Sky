#===============================================================================
# CREDITOS
# Swdfm
#===============================================================================
class Swdfm_Bitmap
  def self.empty(w, h)
    ret = BitmapWrapper.new(w, h)
    return ret
  end
  
  def self.text(text, hash, bmp = nil, size = nil)
    w     = hash[:W]       || 32
    h     = hash[:H]       || w
    bmp   = self.empty(w, h) if !bmp
    align = hash[:Align]   || 0
    t     = hash[:Outline] || false
    gap   = hash[:Gap]     || 0
    anch  = hash[:Anchor]  || :C
    y_gap = hash[:Y_Gap]   || 16
    x     = align == 2 ? bmp.width / 2 : gap
    y     = 0
    y     = bmp.height / 2 - y_gap / 2 if anch == :C
    x     = hash[:X] if hash[:X]
    y     = hash[:Y] if hash[:Y]
    base  = hash[:Base]   || PANEL_BASE_COLOUR
    shad  = hash[:Shadow] || PANEL_SHADOW_COLOUR
    t_pos = [[text, x, y, align, base, shad, t]]
    pbSetSystemFont(bmp)
    bmp.font.size = size if size
    pbDrawTextPositions(bmp, t_pos)
    return bmp
  end
  
  def self.colour(bmp, col, x, y, w, h)
    bmp = self.empty(bmp[0], bmp[1]) if bmp.is_a?(Array)
    bmp.fill_rect(x, y, w, h, col)
    return bmp
  end
end
