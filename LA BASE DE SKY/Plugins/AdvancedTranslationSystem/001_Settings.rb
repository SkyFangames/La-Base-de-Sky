#===============================================================================
# Settings Menu Integration
# Adds a language selector to the options menu and hooks into PokemonSystem
# so the chosen language persists across saves.
#
# dialogue_language values:
#   -1        = Auto (detect from OS)
#    0, 1, …  = index into TranslationSystem.available_languages
#===============================================================================

# Persist the selected language index in save data
class PokemonSystem
  attr_accessor :dialogue_language

  alias_method :initialize_without_dialogue_language, :initialize
  def initialize
    initialize_without_dialogue_language
    @dialogue_language = -1 if @dialogue_language.nil?
  end
end

#===============================================================================
# UI Refresh Hooks
# These patches let the options/pause/load screens update their labels
# immediately when the language changes, without reopening the menu.
#===============================================================================

# Old options UI (PokemonOption_Scene)
class PokemonOption_Scene
  def pbRefresh
    return if !@sprites || !@sprites["option"]

    current_index = @sprites["option"].index
    current_values = []
    @options.length.times { |i| current_values[i] = @sprites["option"][i] }

    @options.clear
    @hashes.clear
    MenuHandlers.each_available(:options_menu) do |option, hash, name|
      @options.push(
        hash["type"].new(name, hash["parameters"], hash["get_proc"], hash["set_proc"])
      )
      @hashes.push(hash)
    end

    @sprites["option"].instance_variable_set(:@options, @options)
    @options.length.times { |i| @sprites["option"].setValueNoRefresh(i, current_values[i]) }
    @sprites["title"].text = pbTranslate("Opciones")
    @sprites["option"].index = current_index
    @sprites["option"].refresh
    pbChangeSelection
  end
end

# New options UI (UI::OptionsVisuals)
class UI::OptionsVisuals
  def rebuild_for_translation
    return if !@options || @options.empty?

    MenuHandlers.each_available(:options_menu) do |option_id, hash, name|
      @options.each do |opt|
        next if opt[:option] != option_id
        opt[:name] = name
        if hash["description"].is_a?(Proc)
          opt[:description] = hash["description"].call
        elsif !hash["description"].nil?
          opt[:description] = _INTL(hash["description"])
        end
        # Translate Option Choices when language changes
        if opt[:type] == :array && hash["parameters"].is_a?(Array)
          opt[:parameters] = hash["parameters"].map { |val| _INTL(val) }
        end
      end
    end

    refresh if respond_to?(:refresh)
  end
end

# Pause menu — commands are rebuilt in the main loop, nothing extra needed
class PokemonPauseMenu_Scene
  def pbRefresh; end

  # Replaces the command list in-place without recreating the window
  def pbUpdateCommands(command_list)
    return if !@sprites || !@sprites["cmdwindow"]
    cmdwindow = @sprites["cmdwindow"]
    current_index = cmdwindow.index rescue 0
    was_visible = cmdwindow.visible
    cmdwindow.commands = command_list
    cmdwindow.index = current_index
    cmdwindow.resizeToFit(command_list)
    cmdwindow.x = Graphics.width - cmdwindow.width
    cmdwindow.y = 0
    cmdwindow.visible = was_visible
  end
end

# Rebuild pause menu commands after returning from a submenu (e.g. options)
class PokemonPauseMenu
  def pbStartPokemonMenu
    if !$player
      if $DEBUG
        pbMessage(pbTranslate("El entrenador del jugador no está definido, por lo que el menú de pausa no se puede mostrar."))
        pbMessage(pbTranslate("Por favor mira la documentación para aprender cómo definir el entrenador del jugador."))
      end
      return
    end
    @scene.pbStartScene
    pbShowInfo
    @command_list = []
    @commands = []
    MenuHandlers.each_available(:pause_menu) do |option, hash, name|
      @command_list.push(name)
      @commands.push(hash)
    end
    end_scene = false
    loop do
      choice = @scene.pbShowCommands(@command_list)
      if choice < 0
        pbPlayCloseMenuSE
        end_scene = true
        break
      end
      if @commands[choice]["effect"].call(@scene)
        break
      else
        # Refresh commands (language may have changed in options)
        @command_list.clear
        @commands.clear
        MenuHandlers.each_available(:pause_menu) do |option, hash, name|
          @command_list.push(name)
          @commands.push(hash)
        end
        @scene.pbUpdateCommands(@command_list)
      end
    end
    @scene.pbEndScene if end_scene
  end
end

# Load screen panel — allow title updates for live language switching
class PokemonLoadPanel
  def update_title(new_title)
    @title = new_title
    pbRefresh
  end
end

class PokemonLoad_Scene
  def pbRefresh(new_commands = nil)
    return if !@sprites
    @commands = new_commands if new_commands
    return if !@commands
    @commands.length.times do |i|
      @sprites["panel#{i}"]&.update_title(@commands[i])
    end
  end
end

#===============================================================================
# Language Application
# Restores the saved language on game load / new game / map entry.
#===============================================================================

EventHandlers.add(:on_new_game, :init_dialogue_language,
  proc {
    if $PokemonSystem.dialogue_language.nil? || $PokemonSystem.dialogue_language == 0
      $PokemonSystem.dialogue_language = -1
    end
  }
)

$language_applied_this_session = false

def apply_saved_language(force = false)
  return if $language_applied_this_session && !force

  $PokemonSystem.dialogue_language = -1 if $PokemonSystem.dialogue_language.nil?

  # Reset so current_language re-evaluates from the saved setting
  TranslationSystem.reset_current_language

  if $PokemonSystem.dialogue_language >= 0
    languages = TranslationSystem.available_languages
    if $PokemonSystem.dialogue_language < languages.length
      TranslationSystem.set_language(languages[$PokemonSystem.dialogue_language])
    end
  else
    TranslationSystem.set_language(TranslationSystem.system_default_language)
  end

  $language_applied_this_session = true
end

EventHandlers.add(:on_game_start, :init_dialogue_language, proc { apply_saved_language })
EventHandlers.add(:on_player_change, :init_dialogue_language, proc { apply_saved_language })
EventHandlers.add(:on_enter_map, :init_dialogue_language, proc { apply_saved_language })

#===============================================================================
# Language Option Helpers
#===============================================================================

module TranslationSystem
  # Returns ["Auto", "ES", "EN", ...] for the options menu
  def self.build_language_options
    options = ["Auto"]
    available_languages.each { |code| options.push(code) }
    return options
  end

  # Total option count including Auto
  def self.language_count
    return available_languages.length + 1
  end
end

#===============================================================================
# Options Menu Entry
# Displayed as an :array selector: Auto / LANG1 / LANG2 / ...
#===============================================================================

MenuHandlers.add(:options_menu, :dialogue_language, {
  "name"        => lambda { |*args| pbTranslate("Idioma") },
  "type"        => EnumOption,
  "parameters"  => TranslationSystem.build_language_options,
  "description" => lambda { pbTranslate("Selecciona el idioma.") },
  "get_proc"    => proc {
    $PokemonSystem.dialogue_language = -1 if $PokemonSystem.dialogue_language.nil?
    # -1 (auto) → index 0, language 0 → index 1, etc.
    next $PokemonSystem.dialogue_language + 1
  },
  "set_proc"    => proc { |value, scene|
    begin
      $PokemonSystem.dialogue_language = value - 1
      $language_applied_this_session = false

      if $PokemonSystem.dialogue_language >= 0
        languages = TranslationSystem.available_languages
        if $PokemonSystem.dialogue_language < languages.length
          TranslationSystem.set_language(languages[$PokemonSystem.dialogue_language])
        end
      else
        TranslationSystem.set_language(TranslationSystem.system_default_language)
      end

      # Live-refresh the options screen
      if scene
        if defined?(UI::OptionsVisuals) && scene.is_a?(UI::OptionsVisuals)
          scene.rebuild_for_translation
        elsif scene.is_a?(PokemonOption_Scene)
          scene.pbRefresh
        end
      end
    rescue => e
      Console.echo_error("Error changing language: #{e.message}") if defined?(Console)
    end
  }
})
