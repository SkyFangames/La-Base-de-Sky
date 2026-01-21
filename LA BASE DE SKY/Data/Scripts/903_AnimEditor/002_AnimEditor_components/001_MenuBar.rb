#===============================================================================
#
#===============================================================================
class AnimationEditor::MenuBar < UIControls::BaseContainer
  # NOTE: The innermost ring of pixels outside this container are the same color
  #       as it, making it look 1 pixel wider in each direction than it actually
  #       is. EDGE_BUFFER compensates for this.
  EDGE_BUFFER    = 1
  BUTTON_WIDTH   = 74
  BUTTON_HEIGHT  = 26
  BUTTON_SPACING = 2

  QUIT_BUTTON_X          = BUTTON_SPACING - EDGE_BUFFER   # 1
  QUIT_BUTTON_Y          = BUTTON_SPACING - EDGE_BUFFER   # 1
  SAVE_BUTTON_X          = QUIT_BUTTON_X + BUTTON_WIDTH + BUTTON_SPACING   # 77
  SAVE_BUTTON_Y          = QUIT_BUTTON_Y   # 1
  HELP_BUTTON_X          = SAVE_BUTTON_X + BUTTON_WIDTH + BUTTON_SPACING   # 153
  HELP_BUTTON_Y          = SAVE_BUTTON_Y   # 1
  SETTINGS_BUTTON_X      = HELP_BUTTON_X + BUTTON_WIDTH + BUTTON_SPACING   # 229
  SETTINGS_BUTTON_Y      = HELP_BUTTON_Y   # 1
  SETTINGS_BUTTON_WIDTH  = BUTTON_HEIGHT   # 26, button's bitmap width is 18
  SETTINGS_BUTTON_HEIGHT = BUTTON_HEIGHT   # 26, button's bitmap height is 18
  NAME_BUTTON_X          = QUIT_BUTTON_X   # 1
  NAME_BUTTON_Y          = QUIT_BUTTON_Y + BUTTON_HEIGHT + BUTTON_SPACING   # 29
  NAME_BUTTON_WIDTH      = SETTINGS_BUTTON_X + SETTINGS_BUTTON_WIDTH - NAME_BUTTON_X   # 254
  NAME_BUTTON_HEIGHT     = (BUTTON_HEIGHT - UIControls::Button::BUTTON_FRAME_THICKNESS) * 2   # 44

  TOTAL_WIDTH  = NAME_BUTTON_X + NAME_BUTTON_WIDTH + BUTTON_SPACING - EDGE_BUFFER   # 256
  TOTAL_HEIGHT = NAME_BUTTON_Y + NAME_BUTTON_HEIGHT + BUTTON_SPACING - EDGE_BUFFER   # 74

  def initialize(x, y, width, height, viewport)
    super(x, y, width, height)
    @viewport.z = viewport.z + 10   # So that it appears over the canvas
  end

  def initialize_bitmaps
    # Editor settings button bitmap
    btmp_width = (SETTINGS_BUTTON_WIDTH / 2) - UIControls::BitmapButton::BUTTON_FRAME_THICKNESS   # 9
    btmp_height = (SETTINGS_BUTTON_HEIGHT / 2) - UIControls::BitmapButton::BUTTON_FRAME_THICKNESS   # 9
    # The top left quarter of a cog
    btmp_graphic = %w(
      . . . . . . . . X
      . . . . . . . X X
      . . X X X . . X X
      . . X X X X . X X
      . . X X X X X X X
      . . . X X X X X X
      . . . . X X X X .
      . X X X X X X . .
      X X X X X X . . .
    )
    @bitmaps[:settings] = Bitmap.new(btmp_width * 2, btmp_height * 2) if !@bitmaps[:settings]
    btmp = @bitmaps[:settings]
    icon_color = get_color_of(:text)
    btmp_graphic.length.times do |i|
      next if btmp_graphic[i] == "."
      pixel_x = i % btmp_width
      pixel_y = i / btmp_width
      btmp.fill_rect(pixel_x, pixel_y, 1, 1, icon_color)
      btmp.fill_rect(btmp.width - 1 - pixel_x, pixel_y, 1, 1, icon_color)
      btmp.fill_rect(pixel_x, btmp.height - 1 - pixel_y, 1, 1, icon_color)
      btmp.fill_rect(btmp.width - 1 - pixel_x, btmp.height - 1 - pixel_y, 1, 1, icon_color)
    end
  end

  def initialize_controls
    add_control_at(:quit, QUIT_BUTTON_X, QUIT_BUTTON_Y,
                   UIControls::Button.new(BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, _INTL("Quit")))
    add_control_at(:save, SAVE_BUTTON_X, SAVE_BUTTON_Y,
                   UIControls::Button.new(BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, _INTL("Save")))
    add_control_at(:help, HELP_BUTTON_X, HELP_BUTTON_Y,
                   UIControls::Button.new(BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, _INTL("Help")))
    add_control_at(:settings, SETTINGS_BUTTON_X, SETTINGS_BUTTON_Y,
                   UIControls::BitmapButton.new(@viewport, @bitmaps[:settings]))
    add_control_at(:name, NAME_BUTTON_X, NAME_BUTTON_Y,
                   UIControls::Button.new(NAME_BUTTON_WIDTH, NAME_BUTTON_HEIGHT, @viewport, ""))
  end

  #-----------------------------------------------------------------------------

  def anim_name=(val)
    ctrl = get_control(:name)
    ctrl.set_text(val) if ctrl
  end

  def color_scheme=(value)
    return if @color_scheme == value
    @color_scheme = value
    initialize_bitmaps
    if @controls
      @controls.each_value { |c| c.color_scheme = value }
      repaint
    end
  end
end
