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
  window = Window_TextEntry_Keyboard_Terminal.new(currenttext, 0, 0, width, 64)
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
      ret = window.text
      break
    end
    window.update
    yield if block_given?
  end
  Input.text_input = false
  window.dispose
  Input.update
  return ret
end

class Window_TextEntry_Keyboard_Terminal < Window_TextEntry
  def update
    cursor_to_show = ((System.uptime - @cursor_timer_start) / 0.35).to_i % 2 == 0
    if cursor_to_show != @cursor_shown
      @cursor_shown = cursor_to_show
      refresh
    end
    return if !self.active
    # Moving cursor
    if Input.triggerex?(:LEFT) || Input.repeatex?(:LEFT)
      if @helper.cursor > 0
        if Input.pressex?(:LCTRL) || Input.pressex?(:RCTRL)
          @helper.cursor -= 1
          word = self.text[0..@helper.cursor].split(/\s+/).last
          @helper.cursor -= word.length
        else
          @helper.cursor -= 1
        end
        @cursor_timer_start = System.uptime
        @cursor_shown = true
        self.refresh
      end
      return
    elsif Input.triggerex?(:RIGHT) || Input.repeatex?(:RIGHT)
      if @helper.cursor < self.text.scan(/./m).length
        if Input.pressex?(:LCTRL) || Input.pressex?(:RCTRL)
          @helper.cursor += 1
          # Calculate distance to next word
          word = self.text[@helper.cursor..-1].split(/\s+/).first
          @helper.cursor += word.length
        else
          @helper.cursor += 1
        end
        @cursor_timer_start = System.uptime
        @cursor_shown = true
        self.refresh
      end
      return
    elsif Input.triggerex?(:BACKSPACE) || Input.repeatex?(:BACKSPACE)
      return unless @helper.cursor > 0
      if Input.pressex?(:LCTRL) || Input.pressex?(:RCTRL)
        word = self.text[0..@helper.cursor].split(/\s+/).last
        word += " " if word != self.text
        word.length.times { self.delete }
      else
        self.delete if @helper.cursor > 0
      end
      return
    elsif Input.triggerex?(:UP) && $InCommandLine && !$game_temp.lastcommand.empty?
      self.text = $game_temp.lastcommand.shift.to_s
      $game_temp.lastcommand.push(self.text)
      @helper.cursor = self.text.scan(/./m).length
      return
    elsif Input.triggerex?(:DOWN) && $InCommandLine && !$game_temp.lastcommand.empty?
      $game_temp.lastcommand.insert(0, $game_temp.lastcommand.pop)
      self.text = $game_temp.lastcommand.pop.to_s
      $game_temp.lastcommand.push(self.text)
      @helper.cursor = self.text.scan(/./m).length
      return
    elsif Input.triggerex?(:RETURN) || Input.triggerex?(:ESCAPE)
      return
    elsif Input.pressex?(:LCTRL) || Input.pressex?(:RCTRL)
      Input.clipboard = self.text if Input.triggerex?(:C)
      Console.echoln "Saved \"#{self.text}\" to clipboard." if Input.triggerex?(:C)
      if Input.triggerex?(:V)
        self.text << Input.clipboard
        @helper.cursor = self.text.scan(/./m).length
      elsif Input.triggerex?(:X)
        Input.clipboard = self.text
        Console.echoln "Saved \"#{self.text}\" to clipboard."
        self.text = ""
        @helper.cursor = 0
      end
    end
    Input.gets.each_char { |c| insert(c) }
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
