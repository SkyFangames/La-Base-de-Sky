#===============================================================================
#  Extensions for the `Sprite` class
#===============================================================================
class ::Sprite
  #-----------------------------------------------------------------------------
  #  returns value if blank or present
  #-----------------------------------------------------------------------------
  def in_viewport?(large: false)
    return false unless viewport

    view_x = large ? viewport.x - viewport.width / 2 : viewport.x
    view_y = large ? viewport.y - viewport.height / 2 : viewport.y
    view_w = large ? viewport.width * 1.5 : viewport.width
    view_h = large ? viewport.height * 1.5 : viewport.height

    !(apparent_x + apparent_width  < view_x - 64 ||
      apparent_y + apparent_height < view_x - 64 ||
      apparent_x > view_x + view_w + 64 ||
      apparent_y > view_y + view_h + 64)
  end

  def apparent_x
    self.x - self.ox * self.zoom_x
  end

  def apparent_y
    self.y - self.oy * self.zoom_y
  end

  def apparent_width
    self.src_rect.width * self.zoom_x
  end

  def apparent_height
    self.src_rect.height * self.zoom_y
  end
  #-----------------------------------------------------------------------------
end
