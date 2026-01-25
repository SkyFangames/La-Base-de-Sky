if !$joiplay
  #########################################
  #                                       #
  # Easy Debug Terminal                   #
  # by ENLS                               #
  # no clue what to write here honestly   #
  #                                       #
  #########################################

  ###########################
  #      Configuration      #
  ###########################

  # Enable or disable the debug terminal
  TERMINAL_ENABLED = true

  # Always print returned value from script
  TERMINAL_ECHO = true

  # Button used to open the terminal
  TERMINAL_KEYBIND = :F3
  # Uses SDL scancodes, without the SDL_SCANCODE_ prefix.
  # https://github.com/mkxp-z/mkxp-z/wiki/Extensions-(RGSS,-Modules)#detecting-key-states

  ###########################
  #       Code Stuff        #
  ###########################

  module Input
    unless defined?(update_Debug_Terminal)
      class << Input
        alias update_Debug_Terminal update
      end
    end

    def self.update
      update_Debug_Terminal
      if triggerex?(TERMINAL_KEYBIND) && $DEBUG && !$InCommandLine && TERMINAL_ENABLED
        $InCommandLine = true
        backup_array = $game_temp.lastcommand.clone
        script = pbFreeTextNoWindow("",false,256,Graphics.width)
        $game_temp.lastcommand = backup_array
        $game_temp.lastcommand.insert(0, script) unless nil_or_empty?(script)
        begin
          if TERMINAL_ECHO && !script.include?("echoln")
            echoln(pbMapInterpreter.execute_script(script)) unless nil_or_empty?(script)
          else
            pbMapInterpreter.execute_script(script) unless nil_or_empty?(script)
          end
        rescue Exception
        end
        $InCommandLine = false
      end
    end
  end

  $InCommandLine = false

  # Custom Message Input Box Stuff
  def pbFreeTextNoWindow(currenttext, passwordbox, maxlength, width = 240)
    window = Window_TextEntry_Keyboard_Terminal.new(currenttext, 0, 0, Graphics.width, 64)
    ret = ""
    window.maxlength = maxlength
    window.visible = true
    window.z = 99999
    window.text = currenttext
    window.passwordChar = "*" if passwordbox
    Input.text_input = true
    loop do
      Graphics.update
      Input.update
      if Input.triggerex?(:ESCAPE)
        break
      elsif Input.triggerex?(:RETURN)
        if Input.pressex?(:LSHIFT) || Input.pressex?(:RSHIFT)
          window.insert("\n")
        else
          ret = window.text
          break
        end
      end
      window.update
      yield if block_given?
    end
    Input.text_input = false
    window.dispose
    Input.update
    return ret
  end

  class Window_TextEntry_Keyboard_Terminal < Window_TextEntry_Keyboard
    def initialize(text, x, y, width, height)
      super(text, x, y, width, height)
      self.opacity = 0
      self.contents = Bitmap.new(width - 32, height - 32)
      if self.contents.font.respond_to?(:name)
        self.contents.font.name = ["Power Green", "Arial"]
      end
      self.contents.font.size = 20
      self.contents.font.bold = true
      
      refresh
    end

    def resize_height
      lines = self.text.split("\n", -1)
      line_count = lines.empty? ? 1 : lines.length
      new_height = 64 + ((line_count - 1) * 32)
      
      if self.height != new_height
        self.height = new_height
        self.contents = Bitmap.new(self.width - 32, self.height - 32)
        if self.contents.font.respond_to?(:name)
          self.contents.font.name = ["Power Green", "Arial"]
        end
        self.contents.font.size = 20
        self.contents.font.bold = true
        refresh
      end
    end

    def insert(ch)
      if super(ch)
        resize_height
        return true
      end
      return false
    end

    def delete
      if super
        resize_height
        return true
      end
      return false
    end

    def refresh
      self.contents.clear
      bg_color = Color.new(0, 0, 0, 160)
      self.contents.fill_rect(0, 0, self.contents.width, self.contents.height, bg_color)
      prompt = "> "
      self.contents.font.color = Color.new(0, 255, 0)
      self.contents.draw_text(1, 4, 30, 32, prompt)
      self.contents.font.color = Color.new(255, 255, 255)
      text_x = 20 
      
      lines = self.text.split("\n", -1)
      lines.each_with_index do |line, i|
        self.contents.draw_text(text_x, 32 * i, self.contents.width - text_x, 32, line)
      end

      if @cursor_shown
        subtext = self.text[0...@helper.cursor]
        line_index = subtext.count("\n")
        current_line_start = subtext.rindex("\n")
        current_line_start = (current_line_start ? current_line_start + 1 : 0)
        subtext_on_line = subtext[current_line_start..-1]
        
        current_full_line = lines[line_index] || ""
        full_line_width = self.contents.text_size(current_full_line).width
        cursor_text_width = self.contents.text_size(subtext_on_line).width
        max_width = self.contents.width - text_x
        
        if full_line_width > 0 && full_line_width > max_width
          scale = max_width.to_f / full_line_width
          cursor_text_width = (cursor_text_width * scale).to_i
        end

        cursor_x = text_x + cursor_text_width
        cursor_y = 4 + (line_index * 32)
        self.contents.fill_rect(cursor_x, cursor_y, 2, 24, Color.new(255, 255, 255))
      end
   end

   def handle_input
    super
    if Input.triggerex?(:UP) && $InCommandLine && !$game_temp.lastcommand.empty?
        self.text = $game_temp.lastcommand.shift.to_s
        $game_temp.lastcommand.push(self.text)
        @helper.cursor = self.text.scan(/./m).length
        refresh
        resize_height
        return
      elsif Input.triggerex?(:DOWN) && $InCommandLine && !$game_temp.lastcommand.empty?
        $game_temp.lastcommand.insert(0, $game_temp.lastcommand.pop)
        self.text = $game_temp.lastcommand.pop.to_s
        $game_temp.lastcommand.push(self.text)
        @helper.cursor = self.text.scan(/./m).length
        refresh
        resize_height
        return
      elsif Input.triggerex?(:RETURN) || Input.triggerex?(:ESCAPE)
        return
      elsif Input.pressex?(:LCTRL) || Input.pressex?(:RCTRL)
        Input.clipboard = self.text if Input.triggerex?(:C)
        Console.echoln "\"#{self.text}\" copiado al portapapeles." if Input.triggerex?(:C)
        if Input.triggerex?(:V)
          Input.clipboard.each_char { |c| insert(c) } 
        elsif Input.triggerex?(:X)
          Input.clipboard = self.text
          Console.echoln "\"#{self.text}\" copiado al portapapeles."
          self.text = ""
          @helper.cursor = 0
          refresh
          resize_height
        end
      end
    end
  end

  # Saving the last executed command
  class Game_Temp
    attr_accessor :lastcommand

    def lastcommand
      if !@lastcommand
        if File.exist?(System.data_directory + "/lastcommand.dat")
          File.open(System.data_directory + "/lastcommand.dat", "rb") { |f| @lastcommand = Marshal.load(f) }
        else
          @lastcommand = []
        end
      end
      return @lastcommand
    end

    def lastcommand=(value)
      @lastcommand = value
      File.open(System.data_directory + "/lastcommand.dat", "wb") { |f| Marshal.dump(@lastcommand, f) }
    end
  end
end