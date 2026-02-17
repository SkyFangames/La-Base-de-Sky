#===============================================================================
#
#===============================================================================
class PokemonSystem
  attr_accessor :textspeed
  attr_accessor :battlescene
  attr_accessor :battlestyle
  attr_accessor :runstyle
  attr_accessor :sendtoboxes
  attr_accessor :givenicknames
  attr_accessor :frame
  attr_accessor :textskin
  attr_accessor :language

  attr_reader :skip_texts
  attr_reader   :skip_move_learning
  attr_reader   :main_volume
  attr_reader   :bgmvolume
  attr_reader   :sevolume
  attr_reader   :pokemon_cry_volume
  
  attr_accessor :textinput
  attr_reader   :bgmvolume
  attr_reader   :sevolume
  attr_writer   :pokemon_cry_volume
  attr_reader   :textspeed
  attr_accessor :battlescene
  attr_reader   :textskin
  attr_reader   :frame
  attr_reader   :screensize
  attr_reader   :language
  attr_writer   :controls
  attr_accessor :vsync
  attr_accessor :autotile_animations

  def initialize
    @battlestyle         = 0     # Battle style (0=switch, 1=set)
    @runstyle            = 0     # Default movement speed (0=walk, 1=run)
    @sendtoboxes         = 0     # Send to Boxes (0=manual, 1=automatic)
    @givenicknames       = 0     # Give nicknames (0=give, 1=don't give)
    @skip_move_learning  = 1     # Skip move learning (0=Sí, 1=No)
    @textinput           = 0     # Text input mode (0=cursor, 1=keyboard)
    @skip_texts          = 1     # Skip text (0=Sí, 1=No)
    @language            = 0     # Language (see also Settings::LANGUAGES)
    @main_volume         = 100
    @bgmvolume           = 80    # Volume of background music and ME
    @sevolume            = 100   # Volume of sound effects (except cries)
    @pokemon_cry_volume  = 100
    @textspeed           = 1     # Text speed (0=slow, 1=medium, 2=fast, 3=instant)
    @battlescene         = 0     # Battle effects (animations) (0=on, 1=off)
    @textskin            = 0     # Speech frame
    @frame               = 0     # Default window frame (see also Settings::MENU_WINDOWSKINS)
    @screensize          = (Settings::SCREEN_SCALE * 2).floor - 1   # 0=half size, 1=full size, 2=full-and-a-half size, 3=double size
    @vsync               = vsync_initial_value?
    @autotile_animations = 0
  end

  def vsync_initial_value?
    return 1 if !File.exist?("mkxp.json") || $joiplay
    file_content = File.read("mkxp.json")
    clean_json_string = json_remove_comments(file_content)
    # Parse JSON content
    begin
      config = HTTPLite::JSON.parse(clean_json_string)

      # Check the vsync value
      vsync_value = config['vsync']
      return vsync_value == true ? 0 : 1
    rescue MKXPError => e
      echoln "Error parsing JSON: #{e.message}"
    end
  end

  def update_vsync(vsync_value)
    file_path = "mkxp.json"
    vsync_value = vsync_value == 1 ? false : true
    vsync_str = vsync_value ? 'true' : 'false'
    sync_to_refresh_str = vsync_str

    # Read the file line-by-line to preserve comments and order
    lines = File.readlines(file_path)
    
    updated_lines = lines.map do |line|
      # Update the "vsync" value
      if line.match?(/"vsync":\s*(true|false)/)
        line.sub(/"vsync":\s*(true|false)/, "\"vsync\": #{vsync_str}")
      # Update the "syncToRefreshrate" value
      elsif line.match?(/"syncToRefreshrate":\s*(true|false)/)
        if vsync_value
          # Set to true with a trailing comma
          line.sub(/"syncToRefreshrate":\s*(true|false),?/, "\"syncToRefreshrate\": #{sync_to_refresh_str}")
        else
          # Set to false without a trailing comma
          line.sub(/"syncToRefreshrate":\s*(true|false)/, "\"syncToRefreshrate\": #{sync_to_refresh_str},")
        end
      # Comment out "fixedFramerate" if vsync is true
      elsif vsync_value && line.match?(/"fixedFramerate":\s*\d+/)
        "//#{line.strip}" # Comment out the line
      # Uncomment "fixedFramerate" if vsync is false
      elsif !vsync_value && line.match?(/\/\/\s*"fixedFramerate":\s*\d+/)
        line.sub(/\/\/\s*/, '') # Uncomment the line
      else
        line # Return the line unchanged
      end
    end
    
    # Write the updated lines back to the file
    File.open(file_path, 'w') do |file|
      file.puts(updated_lines)
    end
    # Handle game restart after vsync value change
    message = $player ? _INTL("Cambiar el valor del vsync requiere reiniciar el juego.\nPodrás guardar antes de reiniciar.\n¿Deseas reiniciar ahora?") : _INTL("Cambiar el valor del vsync requiere reiniciar el juego.\n¿Deseas reiniciar ahora?")
    if Kernel.pbConfirmMessageSerious(message)
      pbSaveScreen if $player
      if System.is_really_windows?
        # Launch Game.exe and immediately exit the current process
        Thread.new do
          system('start "" "Game.exe"')
        end
        sleep(0.1) # Give the thread some time to execute
      else
        pbMessage(_INTL("Al no estar en Windows el juego no puede reiniciarse automáticamente.\nSe cerrará y deberás abrirlo manualmente"))
      end

      Kernel.exit!
    end
  end

  def language=(value)
    return if @language == value && !@force_set_options
    @language = value
    if Settings::LANGUAGES[@language]
      MessageTypes.load_message_files(Settings::LANGUAGES[@language][1])
    end
  end

  def skip_move_learning
    return @skip_move_learning || 1
  end

  def skip_move_learning=(value)
    return if @skip_move_learning == value && !@force_set_options
    @skip_move_learning = value
  end

  def main_volume
    return @main_volume || 100
  end

  def main_volume=(value)
    return if @main_volume == value && !@force_set_options
    @main_volume = value
    return if !$game_system
    if $game_system.playing_bgm
      playing_bgm = $game_system.getPlayingBGM
      $game_system.bgm_pause
      $game_system.bgm_resume(playing_bgm)
    end
    if $game_system.playing_bgs
      playing_bgs = $game_system.getPlayingBGS
      $game_system.bgs_pause
      $game_system.bgs_resume(playing_bgs)
    end
  end

  def bgmvolume
    return @bgmvolume || 80
  end

  def bgmvolume=(value)
    return if @bgmvolume == value && !@force_set_options
    @bgmvolume = value
    return if !$game_system || $game_system.playing_bgm.nil?
    playing_bgm = $game_system.getPlayingBGM
    $game_system.bgm_pause
    $game_system.bgm_resume(playing_bgm)
  end

  def sevolume
    return @sevolume || 100
  end

  def sevolume=(value)
    return if @sevolume == value && !@force_set_options
    @sevolume = value
    return if !$game_system || $game_system.playing_bgs.nil?
    playing_bgs = $game_system.getPlayingBGS
    $game_system.bgs_pause
    $game_system.bgs_resume(playing_bgs)
  end

  def pokemon_cry_volume
    return @pokemon_cry_volume || 100
  end

  def pokemon_cry_volume=(value)
    return if @pokemon_cry_volume == value && !@force_set_options
    @pokemon_cry_volume = value
  end

  def textspeed=(value)
    return if @textspeed == value && !@force_set_options
    @textspeed = value
    MessageConfig.pbSetTextSpeed(MessageConfig.pbSettingToTextSpeed(@textspeed))
  end

  def textskin=(value)
    return if @textskin == value && !@force_set_options
    @textskin = value
    MessageConfig.pbSetSpeechFrame("Graphics/Windowskins/" + Settings::SPEECH_WINDOWSKINS[@textskin])
  end

  def frame=(value)
    return if @frame == value && !@force_set_options
    @frame = value
    MessageConfig.pbSetSystemFrame("Graphics/Windowskins/" + Settings::MENU_WINDOWSKINS[@frame])
  end

  def screensize=(value)
    return if @screensize == value && !@force_set_options
    @screensize = value
    pbSetResizeFactor(@screensize)
  end

  def skip_texts
    return @skip_texts || 1
  end

  def skip_texts=(value)
    return if @skip_texts == value && !@force_set_options
    @skip_texts = value
  end

  # def controls
  #   reset_controls if !@controls
  #   return @controls
  # end

  # def reset_controls
  #   @controls ||= {}
  #   keys = Input::DEFAULT_INPUT_MAPPINGS.keys + Input::DEFAULT_INPUT_MAPPINGS_REMAPPABLE.keys
  #   keys.uniq!
  #   keys.each do |key|
  #     @controls[key] = []
  #     if Input::DEFAULT_INPUT_MAPPINGS_REMAPPABLE[key]
  #       @controls[key][0] = Input::DEFAULT_INPUT_MAPPINGS_REMAPPABLE[key][0]
  #       @controls[key][1] = Input::DEFAULT_INPUT_MAPPINGS_REMAPPABLE[key][1]
  #     end
  #   end
  # end

  #-----------------------------------------------------------------------------

  def reapply_all_options
    @force_set_options = true
    all_options = self.instance_variables.map { |val| val.to_s.gsub("@", "").to_sym }
    all_options.each do |option|
      next if option == :force_set_options
      self.send((option.to_s + "=").to_sym, self.send(option))
    end
    @force_set_options = false
  end
end

#===============================================================================
# Main list of options.
#===============================================================================
class UI::OptionsVisualsList < Window_DrawableCommand
  attr_writer   :baseColor, :shadowColor
  attr_accessor :optionColor, :optionShadowColor
  attr_accessor :selectedColor, :selectedShadowColor
  attr_accessor :unsetColor, :unsetShadowColor
  attr_reader   :value_changed

  ARRAY_SPACING = 32

  # Offset vertical al dibujar el icono de entrada (input) dentro del rect
  OPTION_ICON_BLT_Y_OFFSET = 2
  # Espacio adicional entre icono de entrada y el texto del nombre de la opción
  OPTION_ICON_TEXT_GAP = 6
  # Separación entre los valores cuando hay exactamente 2 elementos en un array
  ARRAY_SPACING = 32
  # Espacio entre el slider y el número mostrado a su derecha
  SLIDER_NUMBER_GAP = 6
  # Alto de la barra del slider (en píxeles)
  SLIDER_BAR_HEIGHT = 4
  # Ancho del indicador (notch) del slider
  SLIDER_NOTCH_WIDTH = 8
  # Alto del indicador (notch) del slider
  SLIDER_NOTCH_HEIGHT = 16
  # Padding en pbDrawShadowText para texto del número del slider
  SLIDER_NUMBER_TEXT_PADDING = 2
  # Espaciado al dibujar corchetes de selección (izquierda)
  SELECTION_BRACKET_LEFT_PADDING = 2
  # Espaciado al dibujar corchetes de selección (derecha)
  SELECTION_BRACKET_RIGHT_PADDING = 0

  def initialize(x, y, width, height, viewport)
    @input_icons_bitmap = AnimatedBitmap.new(UI::OptionsVisuals::UI_FOLDER + "input_icons")
    super(x, y, width, height, viewport)
    @index = -1
  end

  def dispose
    super
    @input_icons_bitmap.dispose
  end

  #-----------------------------------------------------------------------------

  def drawCursor(index, rect)
    # Hide cursor arrow when selecting tabs (self.index < 0)
    return Rect.new(rect.x + 16, rect.y, rect.width - 16, rect.height) if self.index < 0
    return super(index, rect)
  end

  def itemCount
    return @options&.length || 0
  end

  def options=(new_options)
    @options = new_options
    self.top_row = 0
    get_values
    @array_second_value_x = 0
    @options.each do |option|
      next if option[:type] != :array || option[:parameters].length != 2
      text_width = self.contents.text_size(option[:parameters][0]).width
      @array_second_value_x = text_width if @array_second_value_x < text_width
    end
    @array_second_value_x += ARRAY_SPACING
    refresh
  end

  def get_values
    @values = @options.map { |option| option[:get_proc]&.call }
  end

  def lowest_value(option)
    case option[:type]
    when :number_type
      case option[:parameters]
      when Range
        return option[:parameters].begin
      when Array
        return option[:parameters][0] if option[:parameters][0]   # Parameter is [lowest, highest, interval]
      end
      raise _INTL("Opción {1} tiene parámetros inválidos.", option[:name])
    when :number_slider
      if option[:parameters].is_a?(Array) && option[:parameters][1]
        return option[:parameters][0]   # Parameter is [lowest, highest, interval]
      end
      raise _INTL("Opción {1} tiene parámetros inválidos.", option[:name])
    end
    raise _INTL("Opción {1} tiene un valor más bajo indefinido.", option[:name])
  end

  def highest_value(option)
    case option[:type]
    when :number_type
      case option[:parameters]
      when Range
        return option[:parameters].end
      when Array
        return option[:parameters][1] if option[:parameters][1]   # Parameter is [lowest, highest, interval]
      end
      raise _INTL("Opción {1} tiene parámetros inválidos.", option[:name])
    when :number_slider
      if option[:parameters].is_a?(Array) && option[:parameters][1]
        return option[:parameters][1]   # Parameter is [lowest, highest, interval]
      end
      raise _INTL("Opción {1} tiene parámetros inválidos.", option[:name])
    end
    raise _INTL("Opción {1} tiene un valor más alto indefinido.", option[:name])
  end

  def previous_value(this_index)
    return @values[this_index] if @values[this_index] == 0
    option = @options[this_index]
    case option[:type]
    when :array, :array_one
      return @values[this_index] - 1
    when :number_type
      case option[:parameters]
      when Range
        ret = @values[this_index] - 1
        ret = highest_value(option) - lowest_value(option) if ret < 0   # Wrap around
        return ret
      when Array
        highest = highest_value(option)
        lowest = lowest_value(option)
        interval = option[:parameters][2]
        if @values[this_index] > 0
          ret = @values[this_index] - interval
          ret = 0 if ret < 0
        else
          ret = highest - lowest   # Wrap around
        end
        return ret
      end
    when :number_slider
      highest = highest_value(option)
      lowest = lowest_value(option)
      interval = option[:parameters][2]
      if @values[this_index] > 0
        ret = @values[this_index] - interval
        ret = 0 if ret < 0
        return ret
      end
    end
    return @values[this_index]
  end

  def next_value(this_index)
    option = @options[this_index]
    case option[:type]
    when :array, :array_one
      return @values[this_index] + 1 if @values[this_index] < option[:parameters].length - 1
    when :number_type
      case option[:parameters]
      when Range
        ret = @values[this_index] + 1
        ret = 0 if ret > highest_value(option) - lowest_value(option)   # Wrap around
        return ret
      when Array
        highest = highest_value(option)
        lowest = lowest_value(option)
        interval = option[:parameters][2]
        if @values[this_index] < highest - lowest
          ret = @values[this_index] + interval
          ret = highest - lowest if ret > highest - lowest
        else
          ret = 0   # Wrap around
        end
        return ret
      end
    when :number_slider
      highest = highest_value(option)
      lowest = lowest_value(option)
      interval = option[:parameters][2]
      if @values[this_index] < highest - lowest
        ret = @values[this_index] + interval
        ret = highest - lowest if ret > highest - lowest
        return ret
      end
    end
    return @values[this_index]
  end

  def value(this_index = nil)
    return @values[this_index || self.index]
  end

  def selected_option
    return @options[self.index]
  end

  #-----------------------------------------------------------------------------

  def drawItem(this_index, _count, rect)
    rect = drawCursor(this_index, rect)
    option_start_x = (rect.x + rect.width) / 2
    draw_option_name(this_index, rect, option_start_x)
    draw_option_values(this_index, rect, option_start_x) if this_index < @options.length
  end

  def draw_option_name(this_index, rect, option_start_x)
    if this_index >= @options.length
      pbDrawShadowText(self.contents, rect.x, rect.y, option_start_x, rect.height,
                       _INTL("Atrás"), self.baseColor, self.shadowColor)
      return
    end
    option = @options[this_index]
    option_name = option[:name]
    option_name_x = rect.x
    option_colors = [self.optionColor, self.optionShadowColor]
    case option[:type]
    when :control
      # Draw icon
      input_index = UI::BaseVisuals::INPUT_ICONS_ORDER.index(option[:parameters]) || 0
      src_rect = Rect.new(input_index * @input_icons_bitmap.height, 0,
                          @input_icons_bitmap.height, @input_icons_bitmap.height)
      self.contents.blt(rect.x, rect.y + OPTION_ICON_BLT_Y_OFFSET, @input_icons_bitmap.bitmap, src_rect)
      # Adjust text position
      option_name_x += @input_icons_bitmap.height + OPTION_ICON_TEXT_GAP
    when :use
      option_colors = [self.baseColor, self.shadowColor]
    end
    pbDrawShadowText(self.contents, option_name_x, rect.y, option_start_x, rect.height,
                     option_name, *option_colors)
  end

  def draw_option_values(this_index, rect, option_start_x)
    option_width = rect.x + rect.width - option_start_x
    option = @options[this_index]
    case option[:type]
    when :array
      total_width = 0
      option[:parameters].each { |value| total_width += self.contents.text_size(value).width }
      spacing = (rect.width - option_start_x - total_width) / (option[:parameters].length - 1)
      spacing = 0 if spacing < 0
      x_pos = option_start_x
      option[:parameters].each_with_index do |value, i|
        pbDrawShadowText(self.contents, x_pos, rect.y, option_width, rect.height,
                         value,
                         (i == @values[this_index]) ? self.selectedColor : self.baseColor,
                         (i == @values[this_index]) ? self.selectedShadowColor : self.shadowColor)
        # draw_selection_brackets(x_pos, rect.y, value, rect, option_width) if i == @values[this_index]
        if option[:parameters].length == 2
          x_pos += @array_second_value_x
        else
          x_pos += self.contents.text_size(value).width + spacing
        end
      end
    when :number_type
      lowest = lowest_value(option)
      highest = highest_value(option)
      value = _INTL("Tipo {1}/{2}", lowest + @values[this_index], highest - lowest + 1)
      pbDrawShadowText(self.contents, option_start_x, rect.y, option_width, rect.height,
                       value, self.baseColor, self.shadowColor)
    when :number_slider
      lowest = lowest_value(option)
      highest = highest_value(option)
      spacing = SLIDER_NUMBER_GAP   # Gap between slider and number
      # Draw slider bar
      slider_length = option_width - rect.x - self.contents.text_size(highest.to_s).width - spacing
      x_pos = option_start_x
      self.contents.fill_rect(x_pos, rect.y + (rect.height / 2) - (SLIDER_BAR_HEIGHT / 2), slider_length, SLIDER_BAR_HEIGHT, self.baseColor)
      # Draw slider notch
      self.contents.fill_rect(
        x_pos + ((slider_length - SLIDER_NOTCH_WIDTH) * (@values[this_index] - lowest) / (highest - lowest)),
        rect.y + (rect.height / 2) - (SLIDER_NOTCH_HEIGHT / 2),
        SLIDER_NOTCH_WIDTH, SLIDER_NOTCH_HEIGHT, self.selectedColor
      )
      # Draw text
      value = (lowest + @values[this_index]).to_s
      pbDrawShadowText(self.contents, x_pos - rect.x, rect.y, option_width, rect.height,
                       value, self.selectedColor, self.selectedShadowColor, SLIDER_NUMBER_TEXT_PADDING)
    when :control
      x_pos = option_start_x
      spacing = option_width / 2
      @values[this_index].each_with_index do |value, i|
        if value
          text = Input.input_name(value, (i == 0) ? :keyboard : :gamepad)
          text_colors = [self.baseColor, self.shadowColor]
        else
          text = "---"
          text_colors = [self.unsetColor, self.unsetShadowColor]
        end
        pbDrawShadowText(self.contents, x_pos, rect.y, option_width, rect.height,
                         text, *text_colors)
        x_pos += spacing
      end
    when :use
      # Draw nothing
    else
      value = option[:parameters][@values[this_index]]
      pbDrawShadowText(self.contents, option_start_x, rect.y, option_width, rect.height,
                       value, self.baseColor, self.shadowColor)
    end
  end

  def draw_selection_brackets(text_x, text_y, text, rect, option_width)
    pbDrawShadowText(self.contents, text_x - option_width, text_y, option_width, rect.height,
                     "[", self.selectedColor, self.selectedShadowColor, SELECTION_BRACKET_LEFT_PADDING)
    pbDrawShadowText(self.contents, text_x + self.contents.text_size(text).width, text_y, option_width, rect.height,
                     "]", self.selectedColor, self.selectedShadowColor, SELECTION_BRACKET_RIGHT_PADDING)
  end

  #-----------------------------------------------------------------------------

  def update
    if @index < 0
      # Hide up/down arrows when in tab selection mode
      @uparrow.visible = false if @uparrow
      @downarrow.visible = false if @downarrow
      return
    end
    old_index = self.index
    @value_changed = false
    super
    # Hide up/down arrows when in tab selection mode (also after super call)
    if self.index < 0
      @uparrow.visible = false if @uparrow
      @downarrow.visible = false if @downarrow
    end
    need_refresh = (self.index != old_index)
    if self.index < @options.length &&
       [:array, :array_one, :number_type, :number_slider].include?(@options[self.index][:type])
      old_value = @values[self.index]
      if Input.repeat?(Input::LEFT)
        @values[self.index] = previous_value(self.index)
      elsif Input.repeat?(Input::RIGHT)
        @values[self.index] = next_value(self.index)
      end
      if self.value != old_value
        pbPlayCursorSE if selected_option[:type] != :number_slider
        need_refresh = true
        @value_changed = true
      end
    end
    refresh if need_refresh
  end
end

#===============================================================================
#
#===============================================================================
class UI::OptionsVisuals < UI::BaseVisuals
  attr_reader :page
  attr_reader :in_load_screen

  GRAPHICS_FOLDER   = "Options/"   # Subfolder in Graphics/UI
  TEXT_COLOR_THEMES = {   # Themes not in DEFAULT_TEXT_COLOR_THEMES
    :page_name        => [Color.new(248, 248, 248), Color.new(168, 184, 184)],
    :option_name      => [Color.new(192, 120, 0), Color.new(248, 176, 80)],
    :unselected_value => [Color.new(80, 80, 88), Color.new(160, 160, 168)],
    :selected_value   => [Color.new(248, 48, 24), Color.new(248, 136, 128)],
    :unset_control    => [Color.new(160, 160, 168), Color.new(224, 224, 232)]
  }
  OPTIONS_VISIBLE  = 6
  PAGE_TAB_SPACING = 4
  MAX_VISIBLE_TABS = 4   # Maximum number of tabs visible per page
  START_Y = 64
  OPTION_SPACING = 32
  PAGE_DOTS_X = 57
  PAGE_DOTS_Y = 4
  PAGE_NAME_Y = 14

  #-----------------------------------------------------------------------------

  def initialize(options, in_load_screen = false, menu = :options_menu)
    @options        = options
    @in_load_screen = in_load_screen
    @menu           = menu
    @page           = all_pages.first
    @tab_scroll     = 0   # Track which tab is the leftmost visible
    super()
  end

  def initialize_bitmaps
    super
    @bitmaps[:page_icons] = AnimatedBitmap.new(graphics_folder + "page_icons")
  end

  def initialize_message_box
    super
    @sprites[:speech_box].letterbyletter = false
    @sprites[:speech_box].visible        = true
  end

  def initialize_sprites
    initialize_page_tabs
    initialize_page_cursor
    initialize_options_list
  end

  def initialize_page_tabs
    # Use max visible tabs or actual tab count, whichever is smaller
    visible_tabs = [all_pages.length, MAX_VISIBLE_TABS].min
    add_overlay(:page_icons,
                visible_tabs * ((@bitmaps[:page_icons].width / 2) + PAGE_TAB_SPACING),
                @bitmaps[:page_icons].height + 16)  # Extra height for page dots
    # @sprites[:page_icons].x = Graphics.width - @sprites[:page_icons].width
    @sprites[:page_icons].x = PAGE_DOTS_X
    @sprites[:page_icons].y = PAGE_DOTS_Y
  end

  def initialize_page_cursor
    add_icon_sprite(:page_cursor, @sprites[:page_icons].x - 2, @sprites[:page_icons].y - 2,
                    graphics_folder + "page_cursor")
    @sprites[:page_cursor].z = 1100
  end

  def initialize_options_list
    @sprites[:options_list] = UI::OptionsVisualsList.new(0, START_Y, Graphics.width, (OPTIONS_VISIBLE * OPTION_SPACING) + OPTION_SPACING, @viewport)
    @sprites[:options_list].optionColor         = get_text_color_theme(:option_name)[0]
    @sprites[:options_list].optionShadowColor   = get_text_color_theme(:option_name)[1]
    @sprites[:options_list].baseColor           = get_text_color_theme(:unselected_value)[0]
    @sprites[:options_list].shadowColor         = get_text_color_theme(:unselected_value)[1]
    @sprites[:options_list].selectedColor       = get_text_color_theme(:selected_value)[0]
    @sprites[:options_list].selectedShadowColor = get_text_color_theme(:selected_value)[1]
    @sprites[:options_list].unsetColor          = get_text_color_theme(:unset_control)[0]
    @sprites[:options_list].unsetShadowColor    = get_text_color_theme(:unset_control)[1]
    @sprites[:options_list].options             = options_for_page(@page)
  end

  #-----------------------------------------------------------------------------

  def all_pages
    ret = []
    PageHandlers.each_available(@menu) do |page, hash, name|
      ret.push([page, hash[:order] || 0])
    end
    ret.sort_by! { |val| val[1] }
    ret.map! { |val| val[0] }
    return ret
  end

  def set_page(value)
    return if @page == value
    @page = value
    update_tab_page
    @sprites[:options_list].options = options_for_page(@page)
    refresh
  end

  def update_tab_page
    page_index = all_pages.index(@page)
    return if !page_index
    
    pages_length = all_pages.length
    return if pages_length <= MAX_VISIBLE_TABS
    
    # Calculate which "page" of tabs this belongs to
    # If we're navigating to a tab outside the current page, switch pages
    current_page_start = @tab_scroll
    current_page_end = @tab_scroll + MAX_VISIBLE_TABS
    
    if page_index < current_page_start || page_index >= current_page_end
      # Calculate which page this tab is on
      tab_page_number = page_index / MAX_VISIBLE_TABS
      @tab_scroll = tab_page_number * MAX_VISIBLE_TABS
      
      # Make sure we don't scroll past the last complete page
      max_scroll = ((pages_length - 1) / MAX_VISIBLE_TABS) * MAX_VISIBLE_TABS
      @tab_scroll = [@tab_scroll, max_scroll].min
    end
  end

  def go_to_next_page
    pages = all_pages
    page_number = pages.index(@page)
    new_page = pages[(page_number + 1) % pages.length]
    return if new_page == @page
    pbPlayCursorSE
    set_page(new_page)
  end

  def go_to_previous_page
    pages = all_pages
    page_number = pages.index(@page)
    new_page = pages[(page_number - 1) % pages.length]
    return if new_page == @page
    pbPlayCursorSE
    set_page(new_page)
  end

  def index
    return @sprites[:options_list].index
  end

  def set_index(value)
    old_index = index
    @sprites[:options_list].index = value
    refresh_on_index_changed(old_index)
  end

  def options_for_page(this_page)
    return @options.filter { |option| option[:page] == this_page }
  end

  def selected_option
    return @sprites[:options_list].selected_option
  end

  #-----------------------------------------------------------------------------

  def refresh
    super
    refresh_page_tabs
    refresh_page_cursor
    refresh_options_list
    refresh_selected_option
  end

  def refresh_on_index_changed(old_index)
    refresh_selected_option
    if (old_index < 0) != (index < 0)
      refresh_page_cursor
      refresh_options_list
    elsif index < 0
      # Also refresh when staying in tab selection to hide cursor arrows
      refresh_options_list
    end
  end

  def refresh_page_tabs
    @sprites[:page_icons].bitmap.clear
    pages = all_pages
    visible_start = @tab_scroll
    visible_end = [@tab_scroll + MAX_VISIBLE_TABS, pages.length].min
    
    # Draw only visible tabs
    (visible_start...visible_end).each do |i|
      this_page = pages[i]
      tab_x = (i - @tab_scroll) * ((@bitmaps[:page_icons].width / 2) + PAGE_TAB_SPACING)
      draw_image(@bitmaps[:page_icons], tab_x, 0,
                 (this_page == @page) ? @bitmaps[:page_icons].width / 2 : 0, 0,
                 @bitmaps[:page_icons].width / 2, @bitmaps[:page_icons].height, overlay: :page_icons)
      page_handler = PageHandlers.call(@menu, this_page)
      page_name = page_handler[:name].call
      draw_text(page_name, tab_x + (@bitmaps[:page_icons].width / 4), PAGE_NAME_Y,
                align: :center, theme: :page_name, overlay: :page_icons)
    end
    
    # Draw page indicators if there are multiple pages of tabs
    total_pages = (pages.length.to_f / MAX_VISIBLE_TABS).ceil
    if total_pages > 1
      current_page = (@tab_scroll / MAX_VISIBLE_TABS) + 1
      # Draw page dots at the bottom of the tab area
      dots_text = ""
      (1..total_pages).each do |page_num|
        dots_text += (page_num == current_page) ? "●" : "○"
        dots_text += " " if page_num < total_pages
      end
      # Center the dots below the tabs
      dots_x = @sprites[:page_icons].bitmap.width - 50
      draw_text(dots_text, dots_x, @bitmaps[:page_icons].height + 2,
                align: :center, theme: :page_name, overlay: :page_icons)
    end
  end

  def refresh_page_cursor
    @sprites[:page_cursor].visible = (index < 0)
    @sprites[:page_cursor].x = @sprites[:page_icons].x - 2
    page_index = all_pages.index(@page)
    # Calculate position relative to scroll
    visible_position = page_index - @tab_scroll
    @sprites[:page_cursor].x += visible_position * ((@bitmaps[:page_icons].width / 2) + PAGE_TAB_SPACING)
  end

  def refresh_options_list
    @sprites[:options_list].refresh
  end

  def refresh_selected_option
    # Call selected option's "on_select" proc (if defined)
    @sprites[:speech_box].letterbyletter = false
    # Set descriptive text
    description = ""
    option = selected_option
    if index < 0   # Selecting a tab
      page_handler = PageHandlers.call(@menu, @page)
      if page_handler && page_handler[:description].is_a?(Proc)
        # If the description proc expects arguments, pass the page and visuals
        desc_proc = page_handler[:description]
        description = if desc_proc.arity == 0
                        desc_proc.call
                      elsif desc_proc.arity == 1
                        desc_proc.call(@page)
                      else
                        desc_proc.call(@page, self)
                      end
      elsif page_handler && !page_handler[:description].nil?
        description = _INTL(page_handler[:description])
      end
    elsif option
      option[:on_select]&.call(self)   # Can change speech box's letterbyletter
      if option[:description].is_a?(Proc)
        description = option[:description].call
      elsif !option[:description].nil?
        description = _INTL(option[:description])
      end
    else   # Back
      description = _INTL("Atrás.")
    end
    @sprites[:speech_box].text = description
  end

  def description=(value)
    @sprites[:speech_box].text = value
  end

  #-----------------------------------------------------------------------------

  def update_input_tabs
    if Input.repeat?(Input::DOWN)
      pbPlayCursorSE
      set_index(0)
    elsif Input.repeat?(Input::LEFT)
      go_to_previous_page
    elsif Input.repeat?(Input::RIGHT)
      go_to_next_page
    end
    # Check for interaction
    if Input.trigger?(Input::USE)
      pbPlayCursorSE
      set_index(0)
    elsif Input.trigger?(Input::BACK)
      pbPlayCloseMenuSE
      return :quit
    end
    return nil
  end

  def update_input
    # Update value change
    if @sprites[:options_list].value_changed
      selected_option[:set_proc].call(@sprites[:options_list].value, self)
    end
    # Do page selection
    return update_input_tabs if @sprites[:options_list].index < 0
    # Check for interaction
    if Input.trigger?(Input::USE)
      if selected_option && selected_option[:use_proc]
        pbPlayDecisionSE
        return :use_option
      end
    elsif Input.trigger?(Input::BACK)
      pbPlayCancelSE
      set_index(-1)
    end
    return nil
  end

  # def change_key_or_button
  #   this_input = selected_option[:parameters]
  #   @sprites[:speech_box].text = _INTL("Presiona una tecla o botón para asignarlo,\no presiona Esc para salir.")
  #   pressed_key = nil
  #   pressed_button = nil
  #   # Detect key/button press
  #   loop do
  #     Graphics.update
  #     Input.update
  #     # Cancel
  #     if Input::DEFAULT_INPUT_MAPPINGS[Input::BACK].flatten.any? { |key| Input.pressex?(key) }
  #       pbPlayCancelSE
  #       break
  #     end
  #     # Check for key/button press
  #     Input::REMAP_KEYBOARD_KEYS.keys.each do |key|
  #       pressed_key = key if Input.triggerex?(key)
  #       break if pressed_key
  #     end
  #     break if pressed_key
  #     Input::REMAP_GAMEPAD_BUTTONS.keys.each do |key|
  #       pressed_button = key if Input::Controller.triggerex?(key)
  #       break if pressed_button
  #     end
  #     break if pressed_button
  #     Input::REMAP_GAMEPAD_AXIS.keys.each do |key|
  #       pressed_button = key if Input.axis_triggerex?(key)
  #       break if pressed_button
  #     end
  #     break if pressed_button
  #   end
  #   # Change input binding if key/button was pressed
  #   if pressed_key || pressed_button
  #     pbPlayDecisionSE
  #     control_index = (pressed_key ? 0 : 1)
  #     if $PokemonSystem.controls[this_input][control_index] == (pressed_key || pressed_button)
  #       $PokemonSystem.controls[this_input][control_index] = nil
  #     else
  #       $PokemonSystem.controls[this_input][control_index] = pressed_key || pressed_button
  #       $PokemonSystem.controls.each_pair do |ctrl_input, keys|
  #         keys[0] = nil if ctrl_input != this_input && pressed_key && keys[0] == pressed_key
  #         keys[1] = nil if ctrl_input != this_input && pressed_button && keys[1] == pressed_button
  #       end
  #     end
  #   end
  #   # Clean up
  #   @sprites[:options_list].get_values
  #   refresh
  #   Input.update
  # end
end

#===============================================================================
#
#===============================================================================
class UI::Options < UI::BaseScreen
  ACTIONS = HandlerHash.new

  def initialize(in_load_screen = false, menu = :options_menu)
    @in_load_screen = in_load_screen
    @menu = menu
    @options = get_all_options(menu)
    super()
  end

  def initialize_visuals
    @visuals = UI::OptionsVisuals.new(@options, @in_load_screen, @menu)
  end

  def get_all_options(menu = :options_menu)
    ret = []
    seen_options = {}
    
    # First pass: collect all options and track which format they use
    MenuHandlers.each_available(menu) do |option, hash, name|
      has_explicit_page = !hash["page"].nil?
      
      # If this option was already seen with an explicit page, skip old format versions
      next if seen_options[option] && !has_explicit_page
      
      if hash["description"].is_a?(Proc)
        description = hash["description"].call
      elsif !hash["description"].nil?
        description = _INTL(hash["description"])
      end
      
      # Auto-assign page for options without one (backward compatibility)
      page = hash["page"] || auto_detect_page(hash["type"], hash["name"] || name)
      # Convert old option types to new format
      type = convert_option_type(hash["type"])

      raw_params = hash["parameters"]
      final_params = raw_params.is_a?(Proc) ? raw_params.call : raw_params
      option_data = {
        :option      => option,
        :page        => page,
        :name        => name,
        :description => description,
        :type        => type,
        :parameters  => final_params,
        :on_select   => hash["on_select"],
        :get_proc    => hash["get_proc"],
        :set_proc    => hash["set_proc"],
        :use_proc    => hash["use_proc"]
      }
      option_data[:parameters].map! { |val| _INTL(val) } if option_data[:type] == :array
      
      # Remove old version if it exists and this is a new format version
      if has_explicit_page && seen_options[option]
        ret.delete_if { |opt| opt[:option] == option }
      end
      
      ret.push(option_data)
      seen_options[option] = has_explicit_page
    end
    
    return ret
  end

  # Auto-detect appropriate page based on option type and name
  def auto_detect_page(type, name)
    name_lower = name.to_s.downcase
    # Check by name keywords
    return :audio if name_lower.include?("volumen") || name_lower.include?("volume") || 
                     name_lower.include?("bgm") || name_lower.include?("sound") || 
                     name_lower.include?("música") || name_lower.include?("music")
    return :graphics if name_lower.include?("frame") || name_lower.include?("marco") ||
                        name_lower.include?("screen") || name_lower.include?("pantalla") ||
                        name_lower.include?("text") || name_lower.include?("texto") ||
                        name_lower.include?("animation") || name_lower.include?("animación") ||
                        name_lower.include?("vsync") || name_lower.include?("autotile")
    # Default to gameplay for everything else
    return :gameplay
  end

  # Convert old option type classes to new format symbols
  def convert_option_type(type)
    return type if type.is_a?(Symbol)
    case type.to_s
    when "SliderOption"
      return :number_slider
    when "EnumOption"
      return :array
    when "NumberOption"
      return :number_type
    when "ButtonOption"
      return :use
    else
      return :array  # default fallback
    end
  end

  ACTIONS.add(:use_option, {
    :effect => proc { |screen|
      option = screen.visuals.selected_option
      option[:use_proc].call(screen)
    }
  })
end

#===============================================================================
# Options Menu commands.
#===============================================================================

# Default page handlers for options menu
PageHandlers.add(:options_menu, :gameplay, {
  :name  => proc { next _INTL("Juego") },
  :order => 10,
  :description => proc { next _INTL("Cambia cómo se comporta el juego.") }
})

PageHandlers.add(:options_menu, :audio, {
  :name  => proc { next _INTL("Audio") },
  :order => 20,
  :description => proc { next _INTL("Cambia el volumen del juego.") }
})

PageHandlers.add(:options_menu, :graphics, {
  :name  => proc { next _INTL("Gráficos") },
  :order => 30,
  :description => proc { next _INTL("Cambia cómo se ve el juego.") }
})

# PageHandlers.add(:options_menu, :controls, {
#   :name  => proc { next _INTL("Controles") },
#   :order => 40,
#   :description => proc { next _INTL("Edita los controles del juego.") }
# })

PageHandlers.add(:options_menu, :plugins, {
  :name  => proc { next _INTL("Plugins") },
  :order => 50,
  :condition => proc { next PageHandlers.has_any?(:options_menu, :plugins) },
  :description => proc { next _INTL("Configuraciones de Plugins.") }
})

MenuHandlers.add(:options_menu, :text_speed, {
  "page"        => :gameplay,
  "name"        => _INTL("Velocidad de texto"),
  "order"       => 10,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Len"), _INTL("Med"), _INTL("Ráp"), _INTL("Inst")] },
  "description" => _INTL("Elige la velocidad a la que aparece el texto."),
  "on_select"   => proc { |screen| screen.sprites[:speech_box].letterbyletter = true },
  "get_proc"    => proc { next $PokemonSystem.textspeed },
  "set_proc"    => proc { |value, screen|
    next if value == $PokemonSystem.textspeed
    $PokemonSystem.textspeed = value
    # Display the message with the selected text speed to gauge it better.
    screen.sprites[:speech_box].textspeed      = MessageConfig.pbGetTextSpeed
    screen.sprites[:speech_box].letterbyletter = true
    screen.sprites[:speech_box].text           = screen.sprites[:speech_box].text
  }
})


MenuHandlers.add(:options_menu, :battle_style, {
  "page"        => :gameplay,
  "name"        => _INTL("Estilo de combate"),
  "order"       => 20,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Cambio"), _INTL("Fijo")] }, 
  "description" => _INTL("Elige si quieres que se te ofrezca la opción de cambiar de Pokémon cuando se debilita el del rival."),
  "get_proc"    => proc { next $PokemonSystem.battlestyle },
  "set_proc"    => proc { |value, _screen| $PokemonSystem.battlestyle = value }
})

MenuHandlers.add(:options_menu, :movement_style, {
  "page"        => :gameplay,
  "name"        => _INTL("Mov. por defecto"),
  "order"       => 30,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Andar"), _INTL("Correr")] },
  "description" => _INTL("Elige tu velocidad de movimiento. Mantén Presionar hacia atrás mientras te mueves para moverte a la otra velocidad."),
  "condition"   => proc { next $player&.has_running_shoes },
  "get_proc"    => proc { next $PokemonSystem.runstyle },
  "set_proc"    => proc { |value, _sceme| $PokemonSystem.runstyle = value }
})

MenuHandlers.add(:options_menu, :send_to_boxes, {
  "page"        => :gameplay,
  "name"        => _INTL("Enviar a las Cajas"),
  "order"       => 40,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Manual"), _INTL("Automático")] },
  "description" => _INTL("Elige si los Pokémon capturados se envían a tus Cajas cuando tu equipo está lleno."),
  "condition"   => proc { next Settings::NEW_CAPTURE_CAN_REPLACE_PARTY_MEMBER },
  "get_proc"    => proc { next $PokemonSystem.sendtoboxes },
  "set_proc"    => proc { |value, _screen| $PokemonSystem.sendtoboxes = value }
})

MenuHandlers.add(:options_menu, :give_nicknames, {
  "page"        => :gameplay,
  "name"        => _INTL("Motes al capturar"),
  "order"       => 50,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Dar"), _INTL("No dar")] },
  "description" => _INTL("Elige si poner mote a un Pokémon cuando lo obtienes."),
  "get_proc"    => proc { next $PokemonSystem.givenicknames },
  "set_proc"    => proc { |value, _screen| $PokemonSystem.givenicknames = value }
})

MenuHandlers.add(:options_menu, :text_input_style, {
  "page"        => :gameplay,
  "name"        => _INTL("Escritura"),
  "order"       => 60,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Cursor"), _INTL("Teclado")] },
  "description" => _INTL("Elige el método de escritura."),
  "get_proc"    => proc { next $PokemonSystem.textinput },
  "set_proc"    => proc { |value, _screen| $PokemonSystem.textinput = value }
})

MenuHandlers.add(:options_menu, :jump_texts, {
  "page"        => :gameplay,
  "name"        => _INTL("Saltar textos"),
  "order"       => 70,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Sí"), _INTL("No")] },
  "description" => _INTL("Elige si quieres saltar rápido los textos pulsando la Z."),
  "condition"   => proc { next Settings::ENABLE_SKIP_TEXT },
  "get_proc"    => proc { next $PokemonSystem.skip_texts },
  "set_proc"    => proc { |value, _screen| $PokemonSystem.skip_texts = value }
})

MenuHandlers.add(:options_menu, :language, {
  "page"        => :gameplay,
  "name"        => _INTL("Idioma"),
  "order"       => 80,
  "type"        => (Settings::LANGUAGES.length == 2) ? :array : :array_one,
  "parameters"  => proc { Settings::LANGUAGES.map { |lang| lang[0] } },
  "description" => _INTL("Elige el idioma del juego."),
  "condition"   => proc { next Settings::LANGUAGES.length >= 2 },
  "get_proc"    => proc { next $PokemonSystem.language },
  "set_proc"    => proc { |value, _screen| $PokemonSystem.language = value }
})

#-------------------------------------------------------------------------------

MenuHandlers.add(:options_menu, :main_volume, {
  "page"        => :audio,
  "name"        => _INTL("Volumen general"),
  "order"       => 10,
  "type"        => :number_slider,
  "parameters"  => [0, 100, 5],   # [minimum_value, maximum_value, interval]
  "description" => _INTL("Ajusta el volumen de todos los audio en el juego."),
  "get_proc"    => proc { next $PokemonSystem.main_volume },
  "set_proc"    => proc { |value, screen| $PokemonSystem.main_volume = value }
})

MenuHandlers.add(:options_menu, :bgm_volume, {
  "page"        => :audio,
  "name"        => _INTL("Música de fondo"),
  "order"       => 20,
  "type"        => :number_slider,
  "parameters"  => [0, 100, 5],   # [minimum_value, maximum_value, interval]
  "description" => _INTL("Ajusta el volumen de la música de fondo."),
  "get_proc"    => proc { next $PokemonSystem.bgmvolume },
  "set_proc"    => proc { |value, screen| $PokemonSystem.bgmvolume = value }
})

MenuHandlers.add(:options_menu, :se_volume, {
  "page"        => :audio,
  "name"        => _INTL("Efectos de sonido"),
  "order"       => 30,
  "type"        => :number_slider,
  "parameters"  => [0, 100, 5],   # [minimum_value, maximum_value, interval]
  "description" => _INTL("Ajusta el volumen de los efectos de sonido."),
  "get_proc"    => proc { next $PokemonSystem.sevolume },
  "set_proc"    => proc { |value, _screen|
    next if $PokemonSystem.sevolume == value
    $PokemonSystem.sevolume = value
    pbPlayCursorSE
  }
})

MenuHandlers.add(:options_menu, :pokemon_cry_volume, {
  "page"        => :audio,
  "name"        => _INTL("Volumen gritos Pkmn."),
  "order"       => 40,
  "type"        => :number_slider,
  "parameters"  => [0, 100, 5],   # [minimum_value, maximum_value, interval]
  "description" => _INTL("Ajusta el volumen de los gritos de los Pokémon."),
  "get_proc"    => proc { next $PokemonSystem.pokemon_cry_volume },
  "set_proc"    => proc { |value, _screen|
    next if $PokemonSystem.pokemon_cry_volume == value
    $PokemonSystem.pokemon_cry_volume = value
    pbPlayCursorSE
  }
})

#-------------------------------------------------------------------------------

MenuHandlers.add(:options_menu, :battle_animations, {
  "page"        => :graphics,
  "name"        => _INTL("Efectos de combate"),
  "order"       => 20,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Sí"), _INTL("No")] },
  "description" => _INTL("Elige si deseas ver las animaciones de movimiento en batalla."),
  "get_proc"    => proc { next $PokemonSystem.battlescene },
  "set_proc"    => proc { |value, _screen| $PokemonSystem.battlescene = value }
})

MenuHandlers.add(:options_menu, :speech_frame, {
  "page"        => :graphics,
  "name"        => _INTL("Marco de diálogo"),
  "order"       => 30,
  "type"        => :number_type,
  "parameters"  => 1..Settings::SPEECH_WINDOWSKINS.length,
  "description" => _INTL("Elige la apariencia de los cuadros de diálogo."),
  "condition"   => proc { next Settings::SPEECH_WINDOWSKINS.length > 1 },
  "get_proc"    => proc { next $PokemonSystem.textskin },
  "set_proc"    => proc { |value, screen|
    $PokemonSystem.textskin = value
    # Change the windowskin of the options text box to selected one
    screen.sprites[:speech_box].setSkin(MessageConfig.pbGetSpeechFrame)
  }
})

MenuHandlers.add(:options_menu, :menu_frame, {
  "page"        => :graphics,
  "name"        => _INTL("Marco de menú"),
  "order"       => 40,
  "type"        => :number_type,
  "parameters"  => 1..Settings::MENU_WINDOWSKINS.length,
  "description" => _INTL("Elige la apariencia de los menús del juego."),
  "condition"   => proc { next Settings::MENU_WINDOWSKINS.length > 1 },
  "get_proc"    => proc { next $PokemonSystem.frame },
  "set_proc"    => proc { |value, screen|
    $PokemonSystem.frame = value
    # Change the windowskin of the options text box to selected one
    screen.sprites[:options_list].setSkin(MessageConfig.pbGetSystemFrame)
  }
})

MenuHandlers.add(:options_menu, :screen_size, {
  "page"        => :graphics,
  "name"        => _INTL("Tamaño de ventana"),
  "order"       => 50,
  "type"        => :array,
  "parameters"  => proc { [_INTL("S"), _INTL("M"), _INTL("L"), _INTL("XL"), _INTL("Completa")] },
  "description" => _INTL("Elije el tamaño de la ventana del juego."),
  "get_proc"    => proc { next [$PokemonSystem.screensize, 4].min },
  "set_proc"    => proc { |value, _screen| $PokemonSystem.screensize = value }
})

MenuHandlers.add(:options_menu, :vsync, {
  "page"        => :graphics,
  "name"        => _INTL("VSync"),
  "order"       => 60,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Sí"), _INTL("No")] },
  "condition"   => proc { next !$joiplay },
  "description" => _INTL("Si el juego va muy rápido desactiva el VSync.\nRequiere reiniciar el juego"),
  "get_proc"    => proc { next $PokemonSystem.vsync },
  "set_proc"    => proc { |value, _scene|
    next if $PokemonSystem.vsync == value
    $PokemonSystem.vsync = value
    $PokemonSystem.update_vsync($PokemonSystem.vsync)
  }
})

MenuHandlers.add(:options_menu, :autotile_animations, {
  "page"        => :graphics,
  "name"        => _INTL("Anim. de mapas"),
  "order"       => 70,
  "type"        => :array,
  "parameters"  => proc { [_INTL("Sí"), _INTL("No")] },
  "description" => _INTL("Activa o desactiva las animaciones de los mapas."),
  "get_proc"    => proc { next $PokemonSystem.autotile_animations || 0 },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.autotile_animations = value }
})

#-------------------------------------------------------------------------------

# MenuHandlers.add(:options_menu, :control_up, {
#   "page"        => :controls,
#   "name"        => _INTL("Arriba"),
#   "order"       => 10,
#   "type"        => :control,
#   "parameters"  => Input::UP,
#   "description" => _INTL("Movimiento hacia arriba del personaje o en menús. [Also: Arriba]"),
#   "get_proc"    => proc { next $PokemonSystem.controls[Input::UP] },
#   "set_proc"    => proc { |value, _screen| $PokemonSystem.controls[Input::UP] = value },
#   "use_proc"    => proc { |screen| screen.visuals.change_key_or_button }
# })

# MenuHandlers.add(:options_menu, :control_left, {
#   "page"        => :controls,
#   "name"        => _INTL("Izquierda"),
#   "order"       => 20,
#   "type"        => :control,
#   "parameters"  => Input::LEFT,
#   "description" => _INTL("Movimiento hacia la izquierda del personaje o en menús. [Also: Izquierda]"),
#   "get_proc"    => proc { next $PokemonSystem.controls[Input::LEFT] },
#   "set_proc"    => proc { |value, _screen| $PokemonSystem.controls[Input::LEFT] = value },
#   "use_proc"    => proc { |screen| screen.visuals.change_key_or_button }
# })

# MenuHandlers.add(:options_menu, :control_down, {
#   "page"        => :controls,
#   "name"        => _INTL("Abajo"),
#   "order"       => 30,
#   "type"        => :control,
#   "parameters"  => Input::DOWN,
#   "description" => _INTL("Movimiento hacia abajo del personaje o en menús. [Also: Abajo]"),
#   "get_proc"    => proc { next $PokemonSystem.controls[Input::DOWN] },
#   "set_proc"    => proc { |value, _screen| $PokemonSystem.controls[Input::DOWN] = value },
#   "use_proc"    => proc { |screen| screen.visuals.change_key_or_button }
# })

# MenuHandlers.add(:options_menu, :control_right, {
#   "page"        => :controls,
#   "name"        => _INTL("Derecha"),
#   "order"       => 40,
#   "type"        => :control,
#   "parameters"  => Input::RIGHT,
#   "description" => _INTL("Movimiento hacia la derecha del personaje o en menús. [También: Derecha]"),
#   "get_proc"    => proc { next $PokemonSystem.controls[Input::RIGHT] },
#   "set_proc"    => proc { |value, _screen| $PokemonSystem.controls[Input::RIGHT] = value },
#   "use_proc"    => proc { |screen| screen.visuals.change_key_or_button }
# })

# MenuHandlers.add(:options_menu, :control_use, {
#   "page"        => :controls,
#   "name"        => _INTL("Usar/Seleccionar"),
#   "order"       => 50,
#   "type"        => :control,
#   "parameters"  => Input::USE,
#   "description" => _INTL("Interactuar o Confirmar. [También: Enter, Espacio]"),
#   "get_proc"    => proc { next $PokemonSystem.controls[Input::USE] },
#   "set_proc"    => proc { |value, _screen| $PokemonSystem.controls[Input::USE] = value },
#   "use_proc"    => proc { |screen| screen.visuals.change_key_or_button }
# })

# MenuHandlers.add(:options_menu, :control_back, {
#   "page"        => :controls,
#   "name"        => _INTL("Atrás"),
#   "order"       => 60,
#   "type"        => :control,
#   "parameters"  => Input::BACK,
#   "description" => _INTL("Sale del menú y cancela interacciones. [También: X/Esc]"),
#   "get_proc"    => proc { next $PokemonSystem.controls[Input::BACK] },
#   "set_proc"    => proc { |value, _screen| $PokemonSystem.controls[Input::BACK] = value },
#   "use_proc"    => proc { |screen| screen.visuals.change_key_or_button }
# })

# MenuHandlers.add(:options_menu, :control_action, {
#   "page"        => :controls,
#   "name"        => _INTL("Acción"),
#   "order"       => 70,
#   "type"        => :control,
#   "parameters"  => Input::ACTION,
#   "description" => _INTL("Cambia el comportamiento de ciertas interacciones en el juego. (Default: Z)"),
#   "get_proc"    => proc { next $PokemonSystem.controls[Input::ACTION] },
#   "set_proc"    => proc { |value, _screen| $PokemonSystem.controls[Input::ACTION] = value },
#   "use_proc"    => proc { |screen| screen.visuals.change_key_or_button }
# })

# MenuHandlers.add(:options_menu, :control_jump_up, {
#   "page"        => :controls,
#   "name"        => _INTL("Subir Rápido"),
#   "order"       => 80,
#   "type"        => :control,
#   "parameters"  => Input::QUICK_UP,
#   "description" => _INTL("Permite avanzar más rápidamente hacia arriba en los menús."),
#   "get_proc"    => proc { next $PokemonSystem.controls[Input::QUICK_UP] },
#   "set_proc"    => proc { |value, _screen| $PokemonSystem.controls[Input::QUICK_UP] = value },
#   "use_proc"    => proc { |screen| screen.visuals.change_key_or_button }
# })

# MenuHandlers.add(:options_menu, :control_jump_down, {
#   "page"        => :controls,
#   "name"        => _INTL("Av. Página"),
#   "order"       => 90,
#   "type"        => :control,
#   "parameters"  => Input::QUICK_DOWN,
#   "description" => _INTL("Permite avanzar más rápidamente hacia abajo en los menús."),
#   "get_proc"    => proc { next $PokemonSystem.controls[Input::QUICK_DOWN] },
#   "set_proc"    => proc { |value, _screen| $PokemonSystem.controls[Input::QUICK_DOWN] = value },
#   "use_proc"    => proc { |screen| screen.visuals.change_key_or_button }
# })

# MenuHandlers.add(:options_menu, :reset_controls, {
#   "page"        => :controls,
#   "name"        => _INTL("Resetear Controles"),
#   "order"       => 900,
#   "type"        => :use,
#   "description" => _INTL("Restablece los controles a sus valores predeterminados."),
#   "use_proc"    => proc { |screen|
#     $PokemonSystem.reset_controls
#     screen.sprites[:options_list].get_values
#     screen.refresh
#     Input.update
#   }
# })