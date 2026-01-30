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
    @undo_history = []
    @redo_history = []
    set_components_contents
    self.color_scheme = @settings[:color_scheme]
    add_to_change_history
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
      PLAY_CONTROLS_X, PLAY_CONTROLS_Y, PLAY_CONTROLS_WIDTH, PLAY_CONTROLS_HEIGHT, @viewport, @anim
    )
    # Canvas
    @components[:canvas] = AnimationEditor::Canvas.new(@canvas_viewport, @anim, @settings)
    # Timeline/particle list
    @components[:timeline] = AnimationEditor::Timeline.new(
      PARTICLE_LIST_X, PARTICLE_LIST_Y, PARTICLE_LIST_WIDTH, PARTICLE_LIST_HEIGHT,
      @viewport, @anim[:particles]
    )
    # Batch edits
    @components[:batch_edits] = AnimationEditor::BatchEdits.new(
      BATCH_EDITS_X, BATCH_EDITS_Y, BATCH_EDITS_WIDTH, BATCH_EDITS_HEIGHT
    )
    # Pop-up windows
    @components[:help] = UIControls::ListedContainer.new(
      HELP_X, HELP_Y, HELP_WIDTH, HELP_HEIGHT, @pop_up_viewport
    )
    [:editor_settings, :animation_properties, :particle_properties].each do |pop_up|
      @components[pop_up] = UIControls::ListedContainer.new(
        ANIM_PROPERTIES_X + 4, ANIM_PROPERTIES_Y, ANIM_PROPERTIES_WIDTH - 8, ANIM_PROPERTIES_HEIGHT, @pop_up_viewport
      )
      @components[pop_up].label_offset_x = 170
    end
    # Command batch editor
    @components[:command_batch_editor] = UIControls::BaseContainer.new(
      BATCH_EDITOR_X, BATCH_EDITOR_Y, BATCH_EDITOR_WINDOW_WIDTH, BATCH_EDITOR_WINDOW_HEIGHT, @pop_up_viewport
    )
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

  # TODO: The fitted buttons added in these four methods are 24 pixels tall,
  #       not 20 as I'd prefer them to be.
  def set_help_window_contents
    help_window = @components[:help]
    help_window.add_header_label(:header, _INTL("Ayuda"))
    help_window.add_underlined_label(:section_keyboard, _INTL("Controles de teclado"))
    help_window.add_label(:text_esc, _INTL("Esc - Cierra cualquier ventana emergente (como esta)."))
    help_window.add_label(:text_space, _INTL("Espacio - Reproduce la animación, o la detiene si se está reproduciendo."))
    help_window.add_label(:text_arrows, _INTL("Flechas arriba/abajo/izquierda/derecha - Mueve la partícula seleccionada en el lienzo."))
    help_window.add_label(:text_shift_arrows, _INTL("Shift + Flechas arriba/abajo/izquierda/derecha - Mueve la partícula seleccionada en el lienzo más rápido."))
    help_window.add_label(:text_delete, _INTL("Delete - Elimina el comando seleccionado en la línea de tiempo."))
    help_window.add_label(:text_insert, _INTL("Insert - Añade un comando en el punto seleccionado en la línea de tiempo."))
    help_window.add_label(:text_undo, _INTL("Ctrl + Z - Deshacer."))
    help_window.add_label(:text_redo, _INTL("Ctrl + Y - Rehacer."))
    help_window.add_underlined_label(:section_mouse, _INTL("Controles del ratón"))
    help_window.add_label(:text_left_click, _INTL("Clic izquierdo - Seleccionar/cambiar algo."))
    help_window.add_label(:text_left_drag, _INTL("Clic izquierdo y arrastrar - Mover un comando en la línea de tiempo, mover una partícula en el lienzo, moverse a través de los fotogramas clave en la barra de tiempo."))
    help_window.add_label(:text_right_click, _INTL("Clic derecho - Cambiar el tipo de interpolación entre dos comandos."))
    help_window.add_label(:text_scroll_wheel, _INTL("Rueda de desplazamiento - Desplazarse hacia arriba/abajo en la lista de partículas."))
    help_window.add_label(:close_gap, "")
    help_window.add_fitted_button(:close, _INTL("Cerrar"))
    help_window.visible = false
  end

  def set_editor_settings_contents
    editor_settings = @components[:editor_settings]
    editor_settings.add_header_label(:header, _INTL("Configuración del editor"))

    interps = {}
    GameData::Animation::INTERPOLATION_TYPES.each_pair { |name, id| interps[id] = name }
    editor_settings.add_labelled_dropdown_list(:default_interpolation, _INTL("Interpolación predeterminada"), interps, :linear)
    editor_settings.add_labelled_dropdown_list(:color_scheme, _INTL("Esquema de color"), color_scheme_options, :light)

    editor_settings.add_underlined_label(:canvas_header, _INTL("Gráficos del lienzo"))
    editor_settings.add_labelled_dropdown_list(:canvas_bg, _INTL("Gráfico de fondo"), {}, "")
    editor_settings.add_labelled_dropdown_list(:user_sprite_name, _INTL("Gráfico del usuario"), {}, "")
    ctrl = editor_settings.get_control(:user_sprite_name)
    ctrl.max_rows = 20
    editor_settings.add_labelled_dropdown_list(:target_sprite_name, _INTL("Gráfico del objetivo"), {}, "")
    ctrl = editor_settings.get_control(:target_sprite_name)
    ctrl.max_rows = 20

    editor_settings.add_fitted_button(:close, _INTL("Cerrar"))
    editor_settings.visible = false
  end

  def set_animation_properties_contents
    anim_properties = @components[:animation_properties]
    anim_properties.add_header_label(:header, _INTL("Propiedades de la animación"))

    anim_properties.add_underlined_label(:identity_label, _INTL("Identidad"))
    anim_properties.add_labelled_dropdown_list(:type, _INTL("Tipo de animación"), {
      :move   => _INTL("Movimiento"),
      :common => _INTL("Común")
    }, :move)
    anim_properties.add_labelled_text_box_dropdown_list(:move, "", [], "")
    move_ctrl = anim_properties.get_control(:move)
    move_ctrl.max_rows = 20
    anim_properties.add_labelled_number_text_box(:version, _INTL("Versión"), 0, 99, 0)
    anim_properties.add_labelled_text_box(:name, _INTL("Nombre"), "")
    anim_properties.add_labelled_text_box(:pbs_path, _INTL("Ruta de archivo PBS"), "")

    anim_properties.add_underlined_label(:user_and_target_label, _INTL("Usuario y objetivo"))
    anim_properties.add_labelled_checkbox(:has_user, _INTL("¿Involucra un usuario?"), true)
    anim_properties.add_labelled_checkbox(:opp_variant, _INTL("¿El usuario está en el lado opuesto?"), false)
    anim_properties.add_labelled_checkbox(:has_target, _INTL("¿Involucra un objetivo?"), true)

    anim_properties.add_underlined_label(:completion_label, _INTL("Finalización"))
    anim_properties.add_labelled_checkbox(:usable, _INTL("¿Se puede usar en batalla?"), true)

    anim_properties.add_underlined_label(:other_label, _INTL("Otro"))
    anim_properties.add_labelled_number_text_box(:fps, _INTL("FPS"), 1, 100, 20)

    anim_properties.add_fitted_button(:close, _INTL("Cerrar"))
    anim_properties.visible = false
  end

  def set_particle_properties_contents
    part_properties = @components[:particle_properties]
    part_properties.add_header_label(:header, _INTL("Propiedades de la partícula"))

    part_properties.add_labelled_text_box(:name, _INTL("Nombre"), "")
    part_properties.get_control(:name).set_blacklist("", "User", "Target", "SE")
    part_properties.add_labelled_label(:graphic_name, _INTL("Gráfico"), "")
    part_properties.add_labelled_fitted_button(:graphic, "", _INTL("Cambiar"))
    part_properties.add_labelled_dropdown_list(:focus, _INTL("Enfoque"), {}, :undefined)

    part_properties.add_underlined_label(:opposing_label, _INTL("Si está en el lado opuesto..."))
    part_properties.add_labelled_checkbox(:foe_invert_x, _INTL("Invertir X"), false)
    part_properties.add_labelled_checkbox(:foe_invert_y, _INTL("Invertir Y"), false)
    part_properties.add_labelled_checkbox(:foe_flip, _INTL("Voltear sprite"), false)

    part_properties.add_underlined_label(:property_override_label, _INTL("Sobrescribir propiedades"))
    part_properties.add_labelled_number_text_box(:random_frame_max, _INTL("Fotograma aleatorio (máx)"), 0, 99, 0)
    part_properties.add_labelled_dropdown_list(:angle_override, _INTL("Ángulo inteligente"), {
      :none                   => _INTL("Ninguno"),
      :initial_angle_to_focus => _INTL("Ángulo inicial al enfoque"),
      :always_point_at_focus  => _INTL("Apuntar siempre al enfoque")
    }, :none)

    part_properties.add_underlined_label(:emitter_label, _INTL("Propiedades del emisor"))
    part_properties.add_labelled_dropdown_list(:spawner, _INTL("Tipo de emisor"), {
      :none                        => _INTL("Ninguno"),
      :random_direction            => _INTL("Dirección aleatoria"),
      :random_direction_gravity    => _INTL("Dirección aleatoria con gravedad"),
      :random_up_direction_gravity => _INTL("Dirección aleatoria hacia arriba con gravedad")
    }, :none)
    part_properties.add_labelled_number_text_box(:spawn_quantity, _INTL("Cantidad emitida"), 1, 99, 1)

    part_properties.add_fitted_button(:duplicate, _INTL("Duplicar esta partícula"))
    part_properties.add_fitted_button(:delete, _INTL("Eliminar esta partícula"))
    part_properties.add_fitted_button(:close, _INTL("Cerrar"))
    part_properties.visible = false
  end

  def set_command_batch_editor_contents
    editor = @components[:command_batch_editor]
    # Title
    editor.add_control_at(:title,
      editor.x + BATCH_EDITOR_PARTICLE_LIST_X,
      editor.y,
      UIControls::Label.new(editor.width, BATCH_EDITOR_ROW_HEIGHT, editor.viewport, _INTL("Apply offset to particle commands"))
    )
    editor.get_control(:title).header = true
    # Particle list
    editor.add_control_at(:particles_label,
      editor.x + BATCH_EDITOR_PARTICLE_LIST_X,
      editor.y + BATCH_EDITOR_PARTICLE_LIST_Y,
      UIControls::Label.new(BATCH_EDITOR_PARTICLE_LIST_WIDTH, BATCH_EDITOR_ROW_HEIGHT, editor.viewport, _INTL("Particles:"))
    )
    editor.add_control_at(:particles,
      editor.x + BATCH_EDITOR_PARTICLE_LIST_X,
      editor.y + BATCH_EDITOR_PARTICLE_LIST_Y + BATCH_EDITOR_ROW_HEIGHT,
      UIControls::CheckboxList.new(
        BATCH_EDITOR_PARTICLE_LIST_WIDTH, BATCH_EDITOR_PARTICLE_LIST_HEIGHT,
        editor.viewport, [], BATCH_EDITOR_PARTICLE_LIST_ROW_HEIGHT
      )
    )
    # Buttons beneath particle list
    list = editor.get_control(:particles)
    button_width = (list.width - BATCH_EDITOR_SPACING) / 2
    [[:select_all_particles, _INTL("Select all")],
     [:select_no_particles, _INTL("Select none")]].each_with_index do |btn, i|
      editor.add_control_at(btn[0],
        list.x + i * (button_width + BATCH_EDITOR_SPACING),
        list.y + list.height + BATCH_EDITOR_SPACING,
        UIControls::Button.new(button_width, BATCH_EDITOR_BUTTON_HEIGHT, editor.viewport, btn[1])
      )
    end
    # Keyframe range
    label_x = list.x + list.width + (BATCH_EDITOR_SPACING * 2)
    label_y = editor.y + BATCH_EDITOR_PARTICLE_LIST_Y
    keyframe_boxes_spacing = 32
    to_label_x_offset = 8   # Distance after the first NumberTextBox to draw the "~"
    editor.add_control_at(:keyframes_label,
      label_x,
      label_y,
      UIControls::Label.new(BATCH_EDITOR_LABEL_WIDTH, BATCH_EDITOR_ROW_HEIGHT, editor.viewport, _INTL("Keyframes:"))
    )
    editor.add_control_at(:keyframes_to_label,
      label_x + BATCH_EDITOR_LABEL_WIDTH + BATCH_EDITOR_NUMBER_BOX_WIDTH + to_label_x_offset,
      label_y,
      UIControls::Label.new(BATCH_EDITOR_LABEL_WIDTH, BATCH_EDITOR_ROW_HEIGHT, editor.viewport, "~")
    )
    [:start_keyframe, :end_keyframe].each_with_index do |ctrl, i|
      editor.add_control_at(ctrl,
        label_x + BATCH_EDITOR_LABEL_WIDTH + (i * (BATCH_EDITOR_NUMBER_BOX_WIDTH + keyframe_boxes_spacing)),
        label_y,
        UIControls::NumberTextBox.new(BATCH_EDITOR_NUMBER_BOX_WIDTH, BATCH_EDITOR_ROW_HEIGHT, editor.viewport, 0, 999, 0)
      )
    end
    # Each interpolable value
    label_y += BATCH_EDITOR_ROW_HEIGHT * 2
    plus_label_x_offset = 15   # Distance before a NumberTextBox to draw the "+"
    properties = []
    AnimationEditor::ListedParticle::PROPERTY_GROUPS.each_value do |props|
      props.each do |prop|
        next if [:color, :tone].include?(prop)
        properties.push(prop) if GameData::Animation.property_can_interpolate?(prop)
      end
    end
    properties.each do |property|
      editor.add_control_at((property.to_s + "_label").to_sym,
        label_x,
        label_y,
        UIControls::Label.new(
          BATCH_EDITOR_LABEL_WIDTH, BATCH_EDITOR_ROW_HEIGHT,
          editor.viewport, GameData::Animation.property_display_name(property) + ":"
        )
      )
      editor.add_control_at((property.to_s + "_plus_label").to_sym,
        label_x + BATCH_EDITOR_LABEL_WIDTH - plus_label_x_offset,
        label_y,
        UIControls::Label.new(BATCH_EDITOR_LABEL_WIDTH, BATCH_EDITOR_ROW_HEIGHT, editor.viewport, "+")
      )
      editor.add_control_at(property,
        label_x + BATCH_EDITOR_LABEL_WIDTH,
        label_y,
        UIControls::NumberTextBox.new(BATCH_EDITOR_NUMBER_BOX_WIDTH, BATCH_EDITOR_ROW_HEIGHT, editor.viewport, -9999, 9999, 0)
      )
      label_y += BATCH_EDITOR_ROW_HEIGHT
    end
    # Close button
    editor.add_control_at(:close,
      editor.x + editor.width - BATCH_EDITOR_PARTICLE_LIST_X - BATCH_EDITOR_APPLY_BUTTON_WIDTH,
      editor.y + editor.height - (BATCH_EDITOR_SPACING - 1) - BATCH_EDITOR_BUTTON_HEIGHT,
      UIControls::Button.new(BATCH_EDITOR_APPLY_BUTTON_WIDTH, BATCH_EDITOR_BUTTON_HEIGHT, editor.viewport, _INTL("Close"))
    )
    # Apply button
    editor.add_control_at(:apply,
      editor.get_control(:close).x - BATCH_EDITOR_SPACING - BATCH_EDITOR_APPLY_BUTTON_WIDTH,
      editor.get_control(:close).y,
      UIControls::Button.new(BATCH_EDITOR_APPLY_BUTTON_WIDTH, BATCH_EDITOR_BUTTON_HEIGHT, editor.viewport, _INTL("Apply"))
    )
    editor.visible = false
  end

  def set_graphic_chooser_contents
    graphic_chooser = @components[:graphic_chooser]
    graphic_chooser.add_header_label(:header, _INTL("Elegir archivo"))
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
    audio_chooser.add_header_label(:header, _INTL("Elegir archivo"))
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
    [[:volume, _INTL("Volumen"), 0, 100], [:pitch, _INTL("Tono"), 0, 200]].each_with_index do |option, i|
      label = UIControls::Label.new(AUDIO_CHOOSER_LABEL_WIDTH, 28, audio_chooser.viewport, option[1])
      audio_chooser.add_control_at((option[0].to_s + "_label").to_sym,
                                   list.x + list.width + 6, list.y + (28 * i), label)
      slider = UIControls::NumberSlider.new(AUDIO_CHOOSER_SLIDER_WIDTH, 28, audio_chooser.viewport, option[2], option[3], 100)
      audio_chooser.add_control_at(option[0], label.x + label.width, label.y, slider)
    end
    # Playback buttons
    [[:play, _INTL("Reproducir")], [:stop, _INTL("Detener")]].each_with_index do |option, i|
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
    set_help_window_contents
    set_editor_settings_contents
    set_animation_properties_contents
    set_particle_properties_contents
    set_command_batch_editor_contents
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
      [BATCH_EDITS_X, BATCH_EDITS_Y, BATCH_EDITS_WIDTH, BATCH_EDITS_HEIGHT],
      [PARTICLE_LIST_X, PARTICLE_LIST_Y, PARTICLE_LIST_WIDTH, PARTICLE_LIST_HEIGHT]
    ].each do |rect|
      @screen_bitmap.bitmap.border_rect(*rect, CONTAINER_BORDER, bg_color, contrast_color, middle_color)
    end
    # Make the pop-up background semi-transparent
    @pop_up_bg_bitmap.bitmap.fill_rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, get_color_of(:semi_transparent))
  end
end
