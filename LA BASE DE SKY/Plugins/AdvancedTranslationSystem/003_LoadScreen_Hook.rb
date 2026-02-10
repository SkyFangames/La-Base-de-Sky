#===============================================================================
# Load Screen Hook
# Prepends into PokemonLoadScreen#pbStartLoadScreen to:
#   1. Apply the saved language from the save file before building commands
#   2. Rebuild command labels when the language is changed via Options
#===============================================================================

module LoadScreenRefreshPanels
  def pbStartLoadScreen
    # Restore saved language BEFORE building any UI text
    if !@save_data.empty? && @save_data[:pokemon_system]
      saved_language = @save_data[:pokemon_system].dialogue_language
      if saved_language
        TranslationSystem.reset_current_language
        if saved_language >= 0
          languages = TranslationSystem.available_languages
          if saved_language < languages.length
            TranslationSystem.set_language(languages[saved_language])
          end
        else
          TranslationSystem.set_language(TranslationSystem.system_default_language)
        end
      end
    end

    # Build menu commands
    check_for_updates() if defined?(check_for_updates)
    commands = []
    cmd_continue     = -1
    cmd_new_game     = -1
    cmd_options      = -1
    cmd_language     = -1
    cmd_mystery_gift = -1
    cmd_update       = -1
    cmd_debug        = -1
    cmd_quit         = -1
    show_continue = !@save_data.empty?
    if show_continue
      commands[cmd_continue = commands.length] = _INTL("Continuar")
      if @save_data[:player].mystery_gift_unlocked
        commands[cmd_mystery_gift = commands.length] = _INTL("Regalo Misterioso")
      end
    end
    commands[cmd_new_game = commands.length]  = _INTL("Nueva partida")
    commands[cmd_options = commands.length]   = _INTL("Opciones")
    commands[cmd_language = commands.length]  = _INTL("Idioma") if Settings::LANGUAGES.length >= 2
    commands[cmd_update=commands.length]      = _INTL("Buscar actualizaciones") if PluginManager.installed?("Pokemon Essentials Game Updater")
    commands[cmd_debug = commands.length]     = _INTL("Debug") if $DEBUG
    commands[cmd_quit = commands.length]      = _INTL("Cerrar Juego")
    map_id = show_continue ? @save_data[:map_factory].map.map_id : 0
    @scene.pbStartScene(commands, show_continue, @save_data[:player], @save_data[:stats], map_id)
    @scene.pbSetParty(@save_data[:player]) if show_continue
    @scene.pbStartScene2
    loop do
      command = @scene.pbChoose(commands)
      pbPlayDecisionSE if command != cmd_quit
      case command
      when cmd_continue
        @scene.pbEndScene
        Game.load(@save_data)
        return
      when cmd_new_game
        @scene.pbEndScene
        Game.start_new
        return
      when cmd_mystery_gift
        pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }
      when cmd_options
        old_language = TranslationSystem.current_language

        if defined?(Settings::USE_NEW_OPTIONS_UI) && Settings::USE_NEW_OPTIONS_UI
          UI::Options.new(true).main
        else
          pbFadeOutIn do
            scene = PokemonOption_Scene.new
            screen = PokemonOptionScreen.new(scene)
            screen.pbStartScreen(true)
          end
        end

        # If language changed, rebuild every command label and refresh panels
        new_language = TranslationSystem.current_language
        if old_language != new_language
          commands.clear
          if show_continue
            commands[cmd_continue = commands.length] = _INTL("Continuar")
            if @save_data[:player].mystery_gift_unlocked
              commands[cmd_mystery_gift = commands.length] = _INTL("Regalo Misterioso")
            end
          end
          commands[cmd_new_game = commands.length]  = _INTL("Nueva partida")
          commands[cmd_options = commands.length]   = _INTL("Opciones")
          commands[cmd_language = commands.length]  = _INTL("Idioma") if Settings::LANGUAGES.length >= 2
          commands[cmd_update = commands.length]    = _INTL("Buscar actualizaciones") if PluginManager.installed?("Pokemon Essentials Game Updater")
          commands[cmd_debug = commands.length]     = _INTL("Debug") if $DEBUG
          commands[cmd_quit = commands.length]      = _INTL("Cerrar Juego")

          commands.length.times do |i|
            panel = @scene.instance_variable_get(:@sprites)["panel#{i}"]
            if panel
              panel.instance_variable_set(:@title, commands[i])
              panel.pbRefresh
            end
          end
        end
      when cmd_language
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
        if show_continue
          @save_data[:pokemon_system] = $PokemonSystem
          File.open(SaveData::FILE_PATH, "wb") { |file| Marshal.dump(@save_data, file) }
        end
        $scene = pbCallTitle
        return
      when cmd_debug
        pbFadeOutIn { pbDebugMenu(false) }
      when cmd_update
        validate_game_version_and_update(true) if defined?(validate_game_version_and_update)
      when cmd_quit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      else
        pbPlayBuzzerSE
      end
    end
  end
end

class PokemonLoadScreen
  prepend LoadScreenRefreshPanels
end
