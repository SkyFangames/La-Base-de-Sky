#===============================================================================
#  Luka's Scripting Utilities
#
#  Adds easy to use mouse functionality for your Essentials code
#===============================================================================
module Mouse
  # @return [Numeric]
  CLICK_TIMEOUT = 0.5

  # Mouse button input map
  # @return [Hash{Symbol => Const}]
  INPUTS = {
    left: Input::MOUSELEFT,
    right: Input::MOUSERIGHT,
    middle: Input::MOUSEMIDDLE
  }.freeze

  class << self
    # @return [Boolean] mouse is in game window
    def active?
      Input.mouse_in_window?
    end

    # Shows mouse cursor in game window
    def show
      Graphics.show_cursor = true
    end

    # Hides mouse cursor in game window
    def hide
      Graphics.show_cursor = false
    end

    # @param button [Symbol]
    # @return [Boolean] mouse button clicked
    def click?(button = :left)
      return false if @drag
      return @hold = 0 || true if !press?(button) && @hold&.between?(1, CLICK_TIMEOUT * Graphics.frame_rate)

      @hold ||= 0
      if press?(button)
        @hold += 1
      else
        @hold = 0
      end

      false
    end

    # @param button [Symbol]
    # @return [Boolean] mouse button pressed
    def press?(button = :left)
      Input.press?(INPUTS[button])
    end

    # @param button [Symbol]
    # @return [Boolean] mouse button released
    def release?(button = :left)
      Input.release?(INPUTS[button])
    end

    # @param button [Symbol]
    # @return [Boolean] mouse button repeated
    def repeat?(button = :left)
      Input.repeat?(INPUTS[button])
    end

    # @param button [Symbol]
    # @return [Boolean] mouse button held
    def hold?(button)
      press?(button) && Input.time?(INPUTS[button]) > CLICK_TIMEOUT * 1_000_000
    end

    # @param rect [Rect]
    # @return [Boolean] mouse scroll up
    def scroll_up?(rect = nil)
      return false if rect && !over?(rect)

      Input.scroll_v.positive?
    end

    # @param rect [Rect]
    # @return [Boolean] mouse scroll down
    def scroll_down?(rect = nil)
      return false if rect && !over?(rect)

      Input.scroll_v.negative?
    end

    # @param object [Object]
    # @return [Boolean] mouse is over supported object
    def over?(object)
      return false unless object.respond_to?(:mouse_params)

      ox, oy, ow, oh = object.mouse_params

      Input.mouse_x.between?(ox, ox + ow) && Input.mouse_y.between?(oy, oy + oh)
    end

    # @param arx [Integer] X coordinate
    # @param ary [Integer] Y coordinate
    # @param arw [Integer] width
    # @param arh [Integer] height
    # @return [Boolean] mouse is in specified area
    def over_area?(arx, ary, arw, arh)
      Rect.new(arx, ary, arw, arh).over?
    end

    # Creates rectangle from mouse drag selection
    # @param button [Symbol]
    # @return [Rect]
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

    # @param object [Object]
    # @param button [Symbol]
    # @return [Boolean] object is being dragged with mouse
    def dragging?(object, button = :left)
      unless (over?(object) || @drag.eql?(object)) && press?(button)
        @drag = nil    unless press?(button)
        @object_ox = 0 unless press?(button)
        @object_oy = 0 unless press?(button)
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

    # Method to drag object using mouse
    # @param object [Object]
    # @param button [Symbol]
    # @param rect [Rect] creates a maximum dragging area
    # @param lock [Symbol] drag lock direction
    # @return [Boolean]
    def drag_object(object, button = :left, rect = nil, lock = nil)
      return false unless dragging?(object, button) && @drag.eql?(object)

      object.x = Input.mouse_x - (@object_ox || 0) unless lock.eql?(:vertical)
      object.y = Input.mouse_y - (@object_oy || 0) unless lock.eql?(:horizontal)
      return true unless rect.is_a?(Rect)

      rx, ry, rw, rh = rect.mouse_params
      _ox, _oy, ow, oh = object.mouse_params
      object.x = rx if object.x < rx && !lock.eql?(:vertical)
      object.y = ry if object.y < ry && !lock.eql?(:horizontal)
      object.x = rx + rw - ow if object.x > rx + rw - ow && !lock.eql?(:vertical)
      object.y = ry + rh - oh if object.y > ry + rh - oh && !lock.eql?(:horizontal)

      true
    end

    # Method to drag object only on the X axis
    # @param object [Object]
    # @param button [Symbol]
    # @param rect [Rect] creates a maximum dragging area
    def drag_object_x(object, button = :left, rect = nil)
      drag_object(object, button, rect, :horizontal)
    end

    # Method to drag object only on the Y axis
    # @param object [Object]
    # @param button [Symbol]
    # @param rect [Rect] creates a maximum dragging area
    def drag_object_y(object, button = :left, rect = nil)
      drag_object(object, button, rect, :vertical)
    end
  end

  # Sprite class extensions
  module Sprite
    # @param pure [Boolean] only actual values (non-transformative)
    # @return [Array<Integer>]
    def mouse_params(pure: false)
      return [x, y, width, height] if pure

      sox = x - ox + (viewport ? viewport.rect.x : 0)
      soy = y - oy + (viewport ? viewport.rect.y : 0)
      sow = bitmap ? bitmap.width * zoom_x : 0
      soh = bitmap ? bitmap.height * zoom_y : 0

      if src_rect
        sow = src_rect.width * zoom_x unless src_rect.width.eql?(sow)
        soh = src_rect.height * zoom_y unless src_rect.height.eql?(soh)
      end

      [sox, soy, sow, soh]
    end

    # @return [Boolean] if alpha of pixel is greater than 0
    def over_pixel?
      return false unless over? && bitmap

      ox, oy = mouse_params

      bitmap.get_pixel(x - ox, y - oy).alpha.positive?
    end
  end

  # Viewport class extensions
  module Viewport
    # @return [Array<Integer>]
    def mouse_params
      [rect.x, rect.y, rect.width, rect.height]
    end
  end

  # Rect class extensions
  module Rect
    # @return [Array<Integer>]
    def mouse_params
      [x, y, width, height]
    end
  end

  # Shared extensions
  module Extensions
    # @return [Boolean]
    def click?
      over? && Mouse.click?
    end

    # @return [Boolean]
    def press?
      over? && Mouse.press?
    end

    # @return [Boolean]
    def over?
      Mouse.over?(self)
    end

    # Drags object
    # @param rect [Rect]
    def mouse_drag(rect = nil)
      Mouse.drag_object(self, :left, rect)
    end

    # Drags object on X axis
    # @param rect [Rect]
    def mouse_drag_x(rect = nil)
      Mouse.drag_object_x(self, :left, rect)
    end

    # Drags object on Y axis
    # @param rect [Rect]
    def mouse_drag_y(rect = nil)
      Mouse.drag_object_y(self, :left, rect)
    end

    # @param target [Object]
    # @return [Boolean]
    def overlap?(target)
      obj_x, obj_y, obj_w, obj_h = mouse_params
      tar_x, tar_y, tar_w, tar_h = target.mouse_params

      !(obj_x + obj_w < tar_x || obj_y + obj_h < tar_y || obj_x > tar_x + tar_w || obj_y > tar_y + tar_h)
    end

    # @param target [Object]
    # @return [Boolean]
    def released_in?(target)
      overlap?(target) && Mouse.release?
    end

    # @param target [Rect]
    # @return [Boolean]
    def released_in_rect?(target)
      x.between?(target.x, target.x + target.width) && y.between?(target.y, target.y + target.height) && Mouse.release?
    end
  end
end

#-------------------------------------------------------------------------------
# Add mouse functionality to various classes
#-------------------------------------------------------------------------------
class ::FloatSprite
  include Mouse::Extensions
  include Mouse::Sprite
end

class Sprite
  include Mouse::Extensions
  include Mouse::Sprite
end

class ::Rect
  include Mouse::Extensions
  include Mouse::Rect
end

class ::Viewport
  include Mouse::Extensions
  include Mouse::Viewport
end
