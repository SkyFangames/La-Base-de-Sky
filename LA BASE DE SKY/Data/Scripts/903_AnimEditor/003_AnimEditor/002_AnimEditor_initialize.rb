#===============================================================================
#
#===============================================================================
class AnimationEditor
  attr_reader :components
  attr_reader :anim

  include AnimationEditor::SettingsMixin
  include UIControls::StyleMixin

  #-----------------------------------------------------------------------------

  def initialize(anim_id, anim)
    load_settings
    @anim_id  = anim_id
    @anim     = anim
    @pbs_path = anim[:pbs_path]
    @quit     = false
    initialize_viewports
    initialize_bitmaps
    initialize_components
    @captured = nil
    set_components_contents
    self.color_scheme = @settings[:color_scheme]
    refresh
  end

  def initialize_viewports
    @viewport = Viewport.new(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    @viewport.z = 99999
    # TODO: It'd be nice if the Canvas component made this viewport instead.
    @canvas_viewport = Viewport.new(CANVAS_X, CANVAS_Y, CANVAS_WIDTH, CANVAS_HEIGHT)
    @canvas_viewport.z = @viewport.z
    @pop_up_viewport = Viewport.new(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    @pop_up_viewport.z = @viewport.z + 200
  end

  def initialize_bitmaps
    # Background for main editor
    if !@screen_bitmap
      @screen_bitmap = BitmapSprite.new(WINDOW_WIDTH, WINDOW_HEIGHT, @viewport)
      @screen_bitmap.z = -100
    end
    # Semi-transparent black overlay to dim the screen while a pop-up window is open
    if !@pop_up_bg_bitmap
      @pop_up_bg_bitmap = BitmapSprite.new(WINDOW_WIDTH, WINDOW_HEIGHT, @pop_up_viewport)
      @pop_up_bg_bitmap.z = -100
      @pop_up_bg_bitmap.visible = false
    end
    # Draw in these bitmaps
    draw_editor_background
  end

  def initialize_components
    @components = {}
    # Menu bar
    @components[:menu_bar] = AnimationEditor::MenuBar.new(
      MENU_BAR_X, MENU_BAR_Y, MENU_BAR_WIDTH, MENU_BAR_HEIGHT, @viewport
    )
    @components[:menu_bar].anim_name = get_animation_display_name
    # Battlers layout
    @components[:battlers_layout] = AnimationEditor::BattlersLayout.new(
      BATTLERS_LAYOUT_X, BATTLERS_LAYOUT_Y, BATTLERS_LAYOUT_WIDTH, BATTLERS_LAYOUT_HEIGHT
    )
    # Play controls
    @components[:play_controls] = AnimationEditor::PlayControls.new(
      PLAY_CONTROLS_X, PLAY_CONTROLS_Y, PLAY_CONTROLS_WIDTH, PLAY_CONTROLS_HEIGHT, @viewport
    )
    # Canvas
    @components[:canvas] = AnimationEditor::Canvas.new(@canvas_viewport, @anim, @settings)
    # Timeline/particle list
    @components[:timeline] = AnimationEditor::Timeline.new(
      PARTICLE_LIST_X, PARTICLE_LIST_Y, PARTICLE_LIST_WIDTH, PARTICLE_LIST_HEIGHT,
      @viewport, @anim[:particles]
    )
    # Pop-up windows
    [:editor_settings, :animation_properties, :particle_properties].each do |pop_up|
      @components[pop_up] = UIControls::ListedContainer.new(
        ANIM_PROPERTIES_X + 4, ANIM_PROPERTIES_Y, ANIM_PROPERTIES_WIDTH - 8, ANIM_PROPERTIES_HEIGHT, @pop_up_viewport
      )
      @components[pop_up].label_offset_x = 170
    end
    # Graphic chooser pop-up window
    @components[:graphic_chooser] = UIControls::ListedContainer.new(
      GRAPHIC_CHOOSER_X, GRAPHIC_CHOOSER_Y, GRAPHIC_CHOOSER_WINDOW_WIDTH, GRAPHIC_CHOOSER_WINDOW_HEIGHT, @pop_up_viewport
    )
    # Audio chooser pop-up window
    @components[:audio_chooser] = UIControls::ListedContainer.new(
      AUDIO_CHOOSER_X, AUDIO_CHOOSER_Y, AUDIO_CHOOSER_WINDOW_WIDTH, AUDIO_CHOOSER_WINDOW_HEIGHT, @pop_up_viewport
    )
  end

  def dispose
    @screen_bitmap.dispose
    @pop_up_bg_bitmap.dispose
    @components.each_value { |c| c.dispose }
    @components.clear
    @viewport.dispose
    @canvas_viewport.dispose
    @pop_up_viewport.dispose
  end

  #-----------------------------------------------------------------------------

  def keyframe
    return @components[:timeline].selected_keyframe
  end

  def particle_index
    return @components[:timeline].particle_index
  end


  def color_scheme=(value)
    return if @color_scheme == value
    @color_scheme = value
    return if !@components
    initialize_bitmaps
    @components.each do |component|
      component[1].color_scheme = value if component[1].respond_to?("color_scheme=")
    end
    refresh
  end

  #-----------------------------------------------------------------------------

  # Returns the animation's name for display in the menu bar and elsewhere.
  def get_animation_display_name
    ret = ""
    case @anim[:type]
    when :move       then ret += _INTL("[Move]")
    when :opp_move   then ret += _INTL("[Foe Move]")
    when :common     then ret += _INTL("[Common]")
    when :opp_common then ret += _INTL("[Foe Common]")
    else
      raise _INTL("Unknown animation type.")
    end
    case @anim[:type]
    when :move, :opp_move
      move_data = GameData::Move.try_get(@anim[:move])
      move_name = (move_data) ? move_data.name : @anim[:move]
      ret += " " + move_name
    when :common, :opp_common
      ret += " " + @anim[:move]
    end
    if @anim[:version] > 0 || @anim[:name]
      ret += "\n"
      if @anim[:version] > 0
        ret += "[" + @anim[:version].to_s + "]"
        ret += " " if @anim[:name]
      end
      ret += @anim[:name] if @anim[:name]
    end
    return ret
  end

  #-----------------------------------------------------------------------------

  # TODO: The fitted buttons added in these three methods are 24 pixels tall,
  #       not 20 as I'd prefer them to be.
  def set_editor_settings_contents
    editor_settings = @components[:editor_settings]
    editor_settings.add_header_label(:header, _INTL("Editor settings"))
    editor_settings.add_labelled_dropdown_list(:color_scheme, _INTL("Color scheme"), color_scheme_options, :light)
    editor_settings.add_labelled_dropdown_list(:canvas_bg, _INTL("Background graphic"), {}, "")
    editor_settings.add_labelled_dropdown_list(:user_sprite_name, _INTL("User graphic"), {}, "")
    ctrl = editor_settings.get_control(:user_sprite_name)
    ctrl.max_rows = 20
    editor_settings.add_labelled_dropdown_list(:target_sprite_name, _INTL("Target graphic"), {}, "")
    ctrl = editor_settings.get_control(:target_sprite_name)
    ctrl.max_rows = 20
    editor_settings.add_fitted_button(:close, _INTL("Close"))
    editor_settings.visible = false
  end

  def set_animation_properties_contents
    anim_properties = @components[:animation_properties]
    anim_properties.add_header_label(:header, _INTL("Animation properties"))
    anim_properties.add_labelled_checkbox(:usable, _INTL("Can be used in battle?"), true)
    anim_properties.add_labelled_dropdown_list(:type, _INTL("Animation type"), {
      :move   => _INTL("Move"),
      :common => _INTL("Common")
    }, :move)
    anim_properties.add_labelled_checkbox(:opp_variant, _INTL("User is opposing?"), false)
    anim_properties.add_labelled_text_box_dropdown_list(:move, "", [], "")
    move_ctrl = anim_properties.get_control(:move)
    move_ctrl.max_rows = 20
    anim_properties.add_labelled_number_text_box(:version, _INTL("Version"), 0, 99, 0)
    anim_properties.add_labelled_text_box(:name, _INTL("Name"), "")
    anim_properties.add_labelled_text_box(:pbs_path, _INTL("PBS filepath"), "")
    anim_properties.add_labelled_checkbox(:has_user, _INTL("Involves a user?"), true)
    anim_properties.add_labelled_checkbox(:has_target, _INTL("Involves a target?"), true)
    anim_properties.add_fitted_button(:close, _INTL("Close"))
    anim_properties.visible = false
  end

  def set_particle_properties_contents
    part_properties = @components[:particle_properties]
    part_properties.add_header_label(:header, _INTL("Edit particle properties"))
    part_properties.add_labelled_text_box(:name, _INTL("Name"), "")
    part_properties.get_control(:name).set_blacklist("", "User", "Target", "SE")
    part_properties.add_labelled_label(:graphic_name, _INTL("Graphic"), "")
    part_properties.add_labelled_fitted_button(:graphic, "", _INTL("Change"))
    part_properties.add_labelled_dropdown_list(:focus, _INTL("Focus"), {}, :undefined)
    part_properties.add_label(:opposing_label, _INTL("> If on opposing side..."))
    part_properties.add_labelled_checkbox(:foe_invert_x, _INTL("Invert X"), false)
    part_properties.add_labelled_checkbox(:foe_invert_y, _INTL("Invert Y"), false)
    part_properties.add_labelled_checkbox(:foe_flip, _INTL("Flip sprite"), false)
    part_properties.add_label(:property_override_label, _INTL("> Override properties..."))
    part_properties.add_labelled_number_text_box(:random_frame_max, _INTL("Random frame (max)"), 0, 99, 0)
    part_properties.add_labelled_dropdown_list(:angle_override, _INTL("Smart angle"), {
      :none                   => _INTL("None"),
      :initial_angle_to_focus => _INTL("Initial angle to focus"),
      :always_point_at_focus  => _INTL("Always point at focus")
    }, :none)
    part_properties.add_label(:emitter_label, _INTL("> Emitter properties..."))
    part_properties.add_labelled_dropdown_list(:spawner, _INTL("Emitter type"), {
      :none                        => _INTL("None"),
      :random_direction            => _INTL("Random direction"),
      :random_direction_gravity    => _INTL("Random dir. with gravity"),
      :random_up_direction_gravity => _INTL("Random up dir. gravity")
    }, :none)
    part_properties.add_labelled_number_text_box(:spawn_quantity, _INTL("Emit amount"), 1, 99, 1)
    part_properties.add_fitted_button(:duplicate, _INTL("Duplicate this particle"))
    part_properties.add_fitted_button(:delete, _INTL("Delete this particle"))
    part_properties.add_fitted_button(:close, _INTL("Close"))
    part_properties.visible = false
  end

  def set_graphic_chooser_contents
    graphic_chooser = @components[:graphic_chooser]
    graphic_chooser.add_header_label(:header, _INTL("Choose a file"))
    # List of files
    list = UIControls::List.new(CHOOSER_FILE_LIST_WIDTH, CHOOSER_FILE_LIST_HEIGHT, graphic_chooser.viewport, [])
    graphic_chooser.add_control_at(:list,
                                   graphic_chooser.x + CHOOSER_FILE_LIST_X,
                                   graphic_chooser.y + CHOOSER_FILE_LIST_Y,
                                   list)
    # Buttons
    [[:ok, _INTL("OK")], [:cancel, _INTL("Cancel")]].each_with_index do |option, i|
      btn = UIControls::Button.new(CHOOSER_BUTTON_WIDTH, MESSAGE_BOX_BUTTON_HEIGHT, graphic_chooser.viewport, option[1])
      graphic_chooser.add_control_at(option[0],
                                     graphic_chooser.x + CHOOSER_FILE_LIST_X + (CHOOSER_BUTTON_WIDTH * i),
                                     graphic_chooser.y + CHOOSER_FILE_LIST_Y + CHOOSER_FILE_LIST_HEIGHT + 2,
                                     btn)
    end
    graphic_chooser.visible = false
    graphic_chooser.z = 100
  end

  def set_audio_chooser_contents
    audio_chooser = @components[:audio_chooser]
    audio_chooser.add_header_label(:header, _INTL("Choose a file"))
    # List of files
    list = UIControls::List.new(CHOOSER_FILE_LIST_WIDTH, CHOOSER_FILE_LIST_HEIGHT, audio_chooser.viewport, [])
    audio_chooser.add_control_at(:list,
                                 audio_chooser.x + CHOOSER_FILE_LIST_X,
                                 audio_chooser.y + CHOOSER_FILE_LIST_Y,
                                 list)
    # Buttons
    [[:ok, _INTL("OK")], [:cancel, _INTL("Cancel")]].each_with_index do |option, i|
      btn = UIControls::Button.new(CHOOSER_BUTTON_WIDTH, MESSAGE_BOX_BUTTON_HEIGHT, audio_chooser.viewport, option[1])
      audio_chooser.add_control_at(option[0],
                                   audio_chooser.x + CHOOSER_FILE_LIST_X + (CHOOSER_BUTTON_WIDTH * i) + 2,
                                   audio_chooser.y + CHOOSER_FILE_LIST_Y + CHOOSER_FILE_LIST_HEIGHT + 2,
                                   btn)
    end
    # Volume and pitch sliders
    [[:volume, _INTL("Volume"), 0, 100], [:pitch, _INTL("Pitch"), 0, 200]].each_with_index do |option, i|
      label = UIControls::Label.new(AUDIO_CHOOSER_LABEL_WIDTH, 28, audio_chooser.viewport, option[1])
      audio_chooser.add_control_at((option[0].to_s + "_label").to_sym,
                                   list.x + list.width + 6, list.y + (28 * i), label)
      slider = UIControls::NumberSlider.new(AUDIO_CHOOSER_SLIDER_WIDTH, 28, audio_chooser.viewport, option[2], option[3], 100)
      audio_chooser.add_control_at(option[0], label.x + label.width, label.y, slider)
    end
    # Playback buttons
    [[:play, _INTL("Play")], [:stop, _INTL("Stop")]].each_with_index do |option, i|
      btn = UIControls::Button.new(CHOOSER_BUTTON_WIDTH, MESSAGE_BOX_BUTTON_HEIGHT, audio_chooser.viewport, option[1])
      audio_chooser.add_control_at(option[0],
                                   list.x + list.width + 6 + (CHOOSER_BUTTON_WIDTH * i),
                                   list.y + (28 * 2),
                                   btn)
    end
    audio_chooser.visible = false
    audio_chooser.z = 100
  end

  def set_components_contents
    # Pop-up windows
    set_editor_settings_contents
    set_animation_properties_contents
    set_particle_properties_contents
    set_graphic_chooser_contents
    set_audio_chooser_contents
  end

  #-----------------------------------------------------------------------------

  def draw_editor_background
    bg_color = get_color_of(:background)
    contrast_color = get_color_of(:line)
    middle_color = get_color_of(:gray_background)
    # Fill the whole screen with white
    @screen_bitmap.bitmap.fill_rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, bg_color)
    # Outline around elements
    [
      [MENU_BAR_X, MENU_BAR_Y, MENU_BAR_WIDTH, MENU_BAR_HEIGHT],
      [CANVAS_X, CANVAS_Y, CANVAS_WIDTH, CANVAS_HEIGHT],
      [PLAY_CONTROLS_X, PLAY_CONTROLS_Y, PLAY_CONTROLS_WIDTH, PLAY_CONTROLS_HEIGHT],
      [BATTLERS_LAYOUT_X, BATTLERS_LAYOUT_Y, BATTLERS_LAYOUT_WIDTH, BATTLERS_LAYOUT_HEIGHT],
      [RIGHT_PANE_X, RIGHT_PANE_Y, RIGHT_PANE_WIDTH, RIGHT_PANE_HEIGHT],
      [PARTICLE_LIST_X, PARTICLE_LIST_Y, PARTICLE_LIST_WIDTH, PARTICLE_LIST_HEIGHT]
    ].each do |rect|
      @screen_bitmap.bitmap.border_rect(*rect, CONTAINER_BORDER, bg_color, contrast_color, middle_color)
    end
    # Make the pop-up background semi-transparent
    @pop_up_bg_bitmap.bitmap.fill_rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, get_color_of(:semi_transparent))
  end
end
