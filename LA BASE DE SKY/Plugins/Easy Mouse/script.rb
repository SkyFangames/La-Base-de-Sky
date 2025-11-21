#===============================================================================
#  Easy Mouse System
#   by Luka S.J
#
#  Adds easy to use mouse functionality for your Essentials code
#===============================================================================
module Mouse
  CLICK_TIMEOUT = 0.25
  #-----------------------------------------------------------------------------
  #  mouse button input map
  #-----------------------------------------------------------------------------
  INPUTS = {
    left: Input::MOUSELEFT,
    right: Input::MOUSERIGHT,
    middle: Input::MOUSEMIDDLE
  }
  #-----------------------------------------------------------------------------
  class << self
    #---------------------------------------------------------------------------
    #  checks if mouse is in game window
    #---------------------------------------------------------------------------
    def active?
      Input.mouse_in_window?
    end
    #---------------------------------------------------------------------------
    #  show mouse cursor in game window
    #---------------------------------------------------------------------------
    def show
      Graphics.show_cursor = true
    end
    #---------------------------------------------------------------------------
    #  hide mouse cursor in game window
    #---------------------------------------------------------------------------
    def hide
      Graphics.show_cursor = false
    end
    #---------------------------------------------------------------------------
    #  standard mouse input checks
    #---------------------------------------------------------------------------
    def click?(button = :left)
      return @hold = 0 || true if !press?(button) && @hold&.between?(1, CLICK_TIMEOUT * 1_000_000)

      @hold = Input.time?(INPUTS[button])
      false
    end

    def press?(button = :left)
      Input.press?(INPUTS[button])
    end

    def release?(button = :left)
      Input.release?(INPUTS[button])
    end

    def repeat?(button = :left)
      Input.repeat?(INPUTS[button])
    end

    def hold?(button)
      press?(button) && Input.time?(INPUTS[button]) > CLICK_TIMEOUT * 1_000_000
    end
    #---------------------------------------------------------------------------
    #  mouse scroll checks
    #---------------------------------------------------------------------------
    def scroll_up?
      Input.scroll_v > 0
    end

    def scroll_down?
      Input.scroll_v < 0
    end
    #---------------------------------------------------------------------------
    #  check if mouse is over supported object
    #---------------------------------------------------------------------------
    def over?(object)
      return false unless object.respond_to?(:mouse_params)

      ox, oy, ow, oh = object.mouse_params

      Input.mouse_x.between?(ox, ox + ow) && Input.mouse_y.between?(oy, oy + oh)
    end
    #---------------------------------------------------------------------------
    #  check if mouse is in specified area
    #---------------------------------------------------------------------------
    def over_area?(arx, ary, arw, arh)
      Rect.new(arx, ary, arw, arh).over?
    end
    #---------------------------------------------------------------------------
    #  create rectangle from mouse drag selection
    #---------------------------------------------------------------------------
    def create_rect(button = :left)
      if press?(button)
        @rect_x ||= x
        @rect_y ||= y

        rx = x < @rect_x ? x : @rect_x
        ry = y < @rect_y ? y : @rect_y
        rw = x < @rect_x ? @rect_x - x : x - @rect_x
        rh = y < @rect_y ? @rect_y - y : y - @rect_y

        return Rect.new(rx, ry, rw, rh)
      end

      @rect_x = nil
      @rect_y = nil
      Rect.new(0, 0, 0, 0)
    end
    #---------------------------------------------------------------------------
    #  checks if object is being dragged with mouse
    #---------------------------------------------------------------------------
    def dragging?(object, button = :left)
      unless (over?(object) && press?(button)) || (press?(button) && @drag.eql?(object))
        @drag = nil
        @object_ox = 0
        @object_oy = 0
        return false
      end

      @drag = [Input.mouse_x, Input.mouse_y] if @drag.nil?
      if @drag.is_a?(Array) && !(@drag[0].eql?(Input.mouse_x) && @drag[1].eql?(Input.mouse_y))
        @drag = object
        @object_ox = Input.mouse_x - object.x
        @object_oy = Input.mouse_y - object.y
      end

      true
    end
    #---------------------------------------------------------------------------
    #  method to drag object using mouse
    #    - `lock` argument decides which axis to lock the dragging on
    #    - `rect` parameter creates a maximum dragging area
    #---------------------------------------------------------------------------
    def drag_object(object, button = :left, rect = nil, lock = nil)
      return false unless dragging?(object, button) && @drag.eql?(object)

      object.x = Input.mouse_x - (@object_ox || 0) unless lock.eql?(:vertical)
      object.y = Input.mouse_y - (@object_oy || 0) unless lock.eql?(:horizontal)
      return unless rect.is_a?(Rect)

      rx, ry, rw, rh = object_params(rect)
      _ox, _oy, ow, oh = object_params(object)
      object.x = rx if object.x < rx && !lock.eql?(:vertical)
      object.y = ry if object.y < ry && !lock.eql?(:horizontal)
      object.x = rx + rw - ow if object.x > rx + rw - ow && !lock.eql?(:vertical)
      object.y = ry + rh - oh if object.y > ry + rh - oh && !lock.eql?(:horizontal)
    end
    #---------------------------------------------------------------------------
    #  method to drag object only on the X axis
    #---------------------------------------------------------------------------
    def drag_object_x(object, button = :left, rect = nil)
      drag_object(object, button, rect, :horizontal)
    end
    #---------------------------------------------------------------------------
    #  method to drag object only on the Y axis
    #---------------------------------------------------------------------------
    def drag_object_y(object, button = :left, rect = nil)
      drag_object(object, button, rect, :vertical)
    end
    #---------------------------------------------------------------------------
  end
  #-----------------------------------------------------------------------------
  #  sprite extensions
  #-----------------------------------------------------------------------------
  module Sprite
    def mouse_params
      ox = x - self.ox + (viewport ? viewport.rect.x : 0)
      oy = y - self.oy + (viewport ? viewport.rect.y : 0)
      ow = bitmap ? bitmap.width * zoom_x : 0
      oh = bitmap ? bitmap.height * zoom_y : 0

      if src_rect
        ow = src_rect.width * zoom_x unless src_rect.width.eql?(ow)
        oh = src_rect.height * zoom_y unless src_rect.height.eql?(oh)
      end

      [ox, oy, ow, oh]
    end

    def over_pixel?
      return false unless over? && bitmap

      ox, oy = mouse_params

      bitmap.get_pixel(x - ox, y - oy).alpha.positive?
    end
  end
  #-----------------------------------------------------------------------------
  #  viewport extensions
  #-----------------------------------------------------------------------------
  module Viewport
    def mouse_params
      [rect.x, rect.y, rect.width, rect.height]
    end
  end
  #-----------------------------------------------------------------------------
  #  rect extensions
  #-----------------------------------------------------------------------------
  module Rect
    def mouse_params
      [x, y, width, height]
    end
  end
  #-----------------------------------------------------------------------------
  #  shared extensions
  #-----------------------------------------------------------------------------
  module Extensions
    def click?
      over? && Mouse.click?
    end

    def over?
      Mouse.over?(self)
    end

    def mouse_drag
      Mouse.drag_object(self)
    end
  end
end
#-------------------------------------------------------------------------------
#  add mouse functionality to sprite class
#-------------------------------------------------------------------------------
class ::Sprite
  include Mouse::Extensions
  include Mouse::Sprite
end
#-------------------------------------------------------------------------------
#  add mouse functionality to rect class
#-------------------------------------------------------------------------------
class ::Rect
  include Mouse::Extensions
  include Mouse::Rect
end
#-------------------------------------------------------------------------------
#  add mouse functionality to viewport class
#-------------------------------------------------------------------------------
class ::Viewport
  include Mouse::Extensions
  include Mouse::Viewport
end