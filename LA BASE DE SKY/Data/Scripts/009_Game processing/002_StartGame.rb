# The Game module contains methods for saving and loading the game.
module Game
  module_function
  # Initializes various global variables and loads the game data.
  def initialize
    $game_temp          = Game_Temp.new
    $game_system        = Game_System.new
    $data_animations    = load_data("Data/Animations.rxdata")
    $data_tilesets      = load_data("Data/Tilesets.rxdata")
    $data_common_events = load_data("Data/CommonEvents.rxdata")
    $data_system        = load_data("Data/System.rxdata")
    pbLoadBattleAnimations
    GameData.load_all
    map_file = sprintf("Data/Map%03d.rxdata", $data_system.start_map_id)
    if $data_system.start_map_id == 0 || !pbRgssExists?(map_file)
      raise _INTL("No se estableció una posición de inicio en el editor de mapas.")
    end
  end

  # Loads bootup data from save file (if it exists) or creates bootup data (if
  # it doesn't).
  def set_up_system
    SaveData.initialize_bootup_values
    # Set resize factor
    pbSetResizeFactor([$PokemonSystem.screensize, 4].min)
    # Set language (and choose language if there is no save file)
    if !Settings::LANGUAGES.empty?
      $PokemonSystem.language = pbChooseLanguage if !SaveData.exists? && Settings::LANGUAGES.length >= 2
      MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
    end
  end

  # Called when starting a new game. Initializes global variables
  # and transfers the player into the map scene.
  def start_new
    if $game_map&.events
      $game_map.events.each_value { |event| event.clear_starting }
    end
    $game_temp.common_event_id = 0 if $game_temp
    pbMapInterpreter&.clear
    pbMapInterpreter&.setup(nil, 0, 0)
    $scene = Scene_Map.new
    SaveData.load_new_game_values
    $game_temp.last_uptime_refreshed_play_time = System.uptime
    $stats.play_sessions += 1
    $map_factory = PokemonMapFactory.new($data_system.start_map_id)
    $game_player.moveto($data_system.start_x, $data_system.start_y)
    $game_player.refresh
    $PokemonEncounters = PokemonEncounters.new
    $PokemonEncounters.setup($game_map.map_id)
    $game_map.autoplay
    $game_map.update
  end

  # Loads the game from the given save data and starts the map scene.
  # @param save_data [Hash] hash containing the save data
  # @raise [SaveData::InvalidValueError] if an invalid value is being loaded
  def load(save_data)
    validate save_data => Hash
    SaveData.load_all_values(save_data)
    $game_temp.last_uptime_refreshed_play_time = System.uptime
    $stats.play_sessions += 1
    self.load_map
    pbAutoplayOnSave
    $game_map.update
    $PokemonMap.updateMap
    $scene = Scene_Map.new
  end

  # Loads and validates the map. Called when loading a saved game.
  def load_map
    $game_map = $map_factory.map
    magic_number_matches = ($game_system.magic_number == $data_system.magic_number)
    if !magic_number_matches || $PokemonGlobal.safesave
      pbMapInterpreter.setup(nil, 0) if pbMapInterpreterRunning?
      begin
        $map_factory.setup($game_map.map_id)
      rescue Errno::ENOENT
        if $DEBUG
          pbMessage(_INTL("No se ha encontrado el Mapa {1}.", $game_map.map_id))
          map = pbWarpToMap
          exit unless map
          $map_factory.setup(map[0])
          $game_player.moveto(map[1], map[2])
        else
          raise _INTL("No se ha encontrado el mapa. No se puede continuar la partida.")
        end
      end
      $game_player.center($game_player.x, $game_player.y)
    else
      $map_factory.setMapChanged($game_map.map_id)
    end
    if $game_map.events.nil?
      raise _INTL("El mapa está corrupto. No se puede continuar la partida.")
    end
    $PokemonEncounters = PokemonEncounters.new
    $PokemonEncounters.setup($game_map.map_id)
    pbUpdateVehicle
  end

  # Saves the game. Returns whether the operation was successful.
  # @param index [Integer] the number to put in the save file's name Game#.rzdata
  # @param directory [String] the folder to put the save file in
  # @param safe [Boolean] whether $PokemonGlobal.safesave should be set to true
  # @return [Boolean] whether the operation was successful
  # @raise [SaveData::InvalidValueError] if an invalid value is being saved
  def save(index, directory = SaveData::DIRECTORY, safe: false)
    validate index => Integer, directory => String, safe => [TrueClass, FalseClass]
    filename = SaveData.filename_from_index(index)
    $PokemonGlobal.safesave = safe
    $game_system.save_count += 1
    $game_system.magic_number = $data_system.magic_number
    $stats.set_time_last_saved
    $stats.save_filename_number = index
    begin
      SaveData.save_to_file(directory + filename)
      Graphics.frame_reset
    rescue IOError, SystemCallError
      $game_system.save_count -= 1
      return false
    end
    return true
  end
end

