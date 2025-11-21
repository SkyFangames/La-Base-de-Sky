#===============================================================================
# Conversions required to support backwards compatibility with old save files
# (within reason).
#===============================================================================

SaveData.register_conversion(:v19_define_versions) do
  essentials_version 19
  display_title 'Adding game version and Essentials version to save data'
  to_all do |save_data|
    unless save_data.has_key?(:essentials_version)
      save_data[:essentials_version] = Essentials::VERSION
    end
    unless save_data.has_key?(:game_version)
      save_data[:game_version] = Settings::GAME_VERSION
    end
  end
end

SaveData.register_conversion(:v19_convert_PokemonSystem) do
  essentials_version 19
  display_title 'Updating PokemonSystem class'
  to_all do |save_data|
    new_system = PokemonSystem.new
    new_system.textspeed   = save_data[:pokemon_system].textspeed || new_system.textspeed
    new_system.battlescene = save_data[:pokemon_system].battlescene || new_system.battlescene
    new_system.battlestyle = save_data[:pokemon_system].battlestyle || new_system.battlestyle
    new_system.frame       = save_data[:pokemon_system].frame || new_system.frame
    new_system.textskin    = save_data[:pokemon_system].textskin || new_system.textskin
    new_system.screensize  = save_data[:pokemon_system].screensize || new_system.screensize
    new_system.language    = save_data[:pokemon_system].language || new_system.language
    new_system.runstyle    = save_data[:pokemon_system].runstyle || new_system.runstyle
    new_system.bgmvolume   = save_data[:pokemon_system].bgmvolume || new_system.bgmvolume
    new_system.sevolume    = save_data[:pokemon_system].sevolume || new_system.sevolume
    new_system.textinput   = save_data[:pokemon_system].textinput || new_system.textinput
    save_data[:pokemon_system] = new_system
  end
end

SaveData.register_conversion(:v19_convert_player) do
  essentials_version 19
  display_title 'Converting player trainer class'
  to_all do |save_data|
    next if save_data[:player].is_a?(Player)
    # Conversion of the party is handled in PokeBattle_Trainer.convert
    save_data[:player] = PokeBattle_Trainer.convert(save_data[:player])
  end
end

SaveData.register_conversion(:v19_move_global_data_to_player) do
  essentials_version 19
  display_title 'Moving some global metadata data to player'
  to_all do |save_data|
    global = save_data[:global_metadata]
    player = save_data[:player]
    player.character_ID = global.playerID
    global.playerID = nil
    global.pokedexUnlocked.each_with_index do |value, i|
      if value
        player.pokedex.unlock(i)
      else
        player.pokedex.lock(i)
      end
    end
    player.coins = global.coins
    global.coins = nil
    player.soot = global.sootsack
    global.sootsack = nil
    player.has_running_shoes = global.runningShoes
    global.runningShoes = nil
    player.seen_storage_creator = global.seenStorageCreator
    global.seenStorageCreator = nil
    player.has_snag_machine = global.snagMachine
    global.snagMachine = nil
    player.seen_purify_chamber = global.seenPurifyChamber
    global.seenPurifyChamber = nil
  end
end

SaveData.register_conversion(:v19_convert_global_metadata) do
  essentials_version 19
  display_title 'Adding encounter version variable to global metadata'
  to_value :global_metadata do |global|
    global.bridge ||= 0
    global.encounter_version ||= 0
    if global.pcItemStorage
      global.pcItemStorage.items.each_with_index do |slot, i|
        item_data = GameData::Item.try_get(slot[0])
        if item_data
          slot[0] = item_data.id
        else
          global.pcItemStorage.items[i] = nil
        end
      end
      global.pcItemStorage.items.compact!
    end
    if global.mailbox
      global.mailbox.each_with_index do |mail, i|
        global.mailbox[i] = PokemonMail.convert(mail) if mail
      end
    end
    global.phoneNumbers.each do |contact|
      contact[1] = GameData::TrainerType.get(contact[1]).id if contact && contact.length == 8
    end
    if global.partner
      global.partner[0] = GameData::TrainerType.get(global.partner[0]).id
      global.partner[3].each_with_index do |pkmn, i|
        global.partner[3][i] = PokeBattle_Pokemon.convert(pkmn) if pkmn
      end
    end
    if global.daycare
      global.daycare.each do |slot|
        slot[0] = PokeBattle_Pokemon.convert(slot[0]) if slot && slot[0]
      end
    end
    if global.roamPokemon
      global.roamPokemon.each_with_index do |pkmn, i|
        global.roamPokemon[i] = PokeBattle_Pokemon.convert(pkmn) if pkmn && pkmn != true
      end
    end
    global.purifyChamber.sets.each do |set|
      set.shadow = PokeBattle_Pokemon.convert(set.shadow) if set.shadow
      set.list.each_with_index do |pkmn, i|
        set.list[i] = PokeBattle_Pokemon.convert(pkmn) if pkmn
      end
    end
    if global.hallOfFame
      global.hallOfFame.each do |team|
        next if !team
        team.each_with_index do |pkmn, i|
          team[i] = PokeBattle_Pokemon.convert(pkmn) if pkmn
        end
      end
    end
    if global.triads
      global.triads.items.each do |card|
        card[0] = GameData::Species.get(card[0]).id if card && card[0] && card[0] != 0
      end
    end
  end
end

SaveData.register_conversion(:v19_1_fix_phone_contacts) do
  essentials_version 19.1
  display_title 'Fixing phone contacts data'
  to_value :global_metadata do |global|
    global.phoneNumbers.each do |contact|
      contact[1] = GameData::TrainerType.get(contact[1]).id if contact && contact.length == 8
    end
  end
end

SaveData.register_conversion(:v19_convert_bag) do
  essentials_version 19
  display_title 'Converting item IDs in Bag'
  to_value :bag do |bag|
    bag.instance_eval do
      for pocket in self.pockets
        pocket.each_with_index do |item, i|
          next if !item || !item[0] || item[0] == 0
          item_data = GameData::Item.try_get(item[0])
          if item_data
            item[0] = item_data.id
          else
            pocket[i] = nil
          end
        end
        pocket.compact!
      end
      self.registeredIndex   # Just to ensure this data exists
      self.registeredItems.each_with_index do |item, i|
        next if !item
        if item == 0
          self.registeredItems[i] = nil
        else
          item_data = GameData::Item.try_get(item)
          if item_data
            self.registeredItems[i] = item_data.id
          else
            self.registeredItems[i] = nil
          end
        end
      end
      self.registeredItems.compact!
    end   # bag.instance_eval
  end   # to_value
end

SaveData.register_conversion(:v19_convert_game_variables) do
  essentials_version 19
  display_title 'Converting classes of things in Game Variables'
  to_all do |save_data|
    variables = save_data[:variables]
    for i in 0..5000
      value = variables[i]
      next if value.nil?
      if value.is_a?(Array)
        value.each_with_index do |value2, j|
          if value2.is_a?(PokeBattle_Pokemon)
            value[j] = PokeBattle_Pokemon.convert(value2)
          end
        end
      elsif value.is_a?(PokeBattle_Pokemon)
        variables[i] = PokeBattle_Pokemon.convert(value)
      elsif value.is_a?(PokemonBag)
        SaveData.run_single_conversions(value, :bag, save_data)
      end
    end
  end
end

SaveData.register_conversion(:v19_convert_storage) do
  essentials_version 19
  display_title 'Converting classes of Pokémon in storage'
  to_value :storage_system do |storage|
    storage.instance_eval do
      for box in 0...self.maxBoxes
        for i in 0...self.maxPokemon(box)
          self[box, i] = PokeBattle_Pokemon.convert(self[box, i]) if self[box, i]
        end
      end
      self.unlockedWallpapers   # Just to ensure this data exists
    end   # storage.instance_eval
  end   # to_value
end

SaveData.register_conversion(:v19_convert_game_player) do
  essentials_version 19
  display_title 'Converting game player character'
  to_value :game_player do |game_player|
    game_player.width = 1
    game_player.height = 1
    game_player.sprite_size = [Game_Map::TILE_WIDTH, Game_Map::TILE_HEIGHT]
    game_player.pattern_surf ||= 0
    game_player.lock_pattern ||= false
    game_player.move_speed = game_player.move_speed
  end
end

SaveData.register_conversion(:v19_convert_game_screen) do
  essentials_version 19
  display_title 'Converting game screen'
  to_value :game_screen do |game_screen|
    game_screen.weather(game_screen.weather_type, game_screen.weather_max, 0)
  end
end

# Planted berries accidentally weren't converted in v19 to change their
# numerical IDs to symbolic IDs (for the berry planted and for mulch laid down).
# Since item numerical IDs no longer exist, this conversion needs to have a list
# of them in order to convert planted berry data properly.
SaveData.register_conversion(:v20_fix_planted_berry_numerical_ids) do
  essentials_version 20
  display_title "Arreglando los datos de las IDs delas plantas de bayas"
  to_value :global_metadata do |global|
    berry_conversion = {
      389 => :CHERIBERRY,
      390 => :CHESTOBERRY,
      391 => :PECHABERRY,
      392 => :RAWSTBERRY,
      393 => :ASPEARBERRY,
      394 => :LEPPABERRY,
      395 => :ORANBERRY,
      396 => :PERSIMBERRY,
      397 => :LUMBERRY,
      398 => :SITRUSBERRY,
      399 => :FIGYBERRY,
      400 => :WIKIBERRY,
      401 => :MAGOBERRY,
      402 => :AGUAVBERRY,
      403 => :IAPAPABERRY,
      404 => :RAZZBERRY,
      405 => :BLUKBERRY,
      406 => :NANABBERRY,
      407 => :WEPEARBERRY,
      408 => :PINAPBERRY,
      409 => :POMEGBERRY,
      410 => :KELPSYBERRY,
      411 => :QUALOTBERRY,
      412 => :HONDEWBERRY,
      413 => :GREPABERRY,
      414 => :TAMATOBERRY,
      415 => :CORNNBERRY,
      416 => :MAGOSTBERRY,
      417 => :RABUTABERRY,
      418 => :NOMELBERRY,
      419 => :SPELONBERRY,
      420 => :PAMTREBERRY,
      421 => :WATMELBERRY,
      422 => :DURINBERRY,
      423 => :BELUEBERRY,
      424 => :OCCABERRY,
      425 => :PASSHOBERRY,
      426 => :WACANBERRY,
      427 => :RINDOBERRY,
      428 => :YACHEBERRY,
      429 => :CHOPLEBERRY,
      430 => :KEBIABERRY,
      431 => :SHUCABERRY,
      432 => :COBABERRY,
      433 => :PAYAPABERRY,
      434 => :TANGABERRY,
      435 => :CHARTIBERRY,
      436 => :KASIBBERRY,
      437 => :HABANBERRY,
      438 => :COLBURBERRY,
      439 => :BABIRIBERRY,
      440 => :CHILANBERRY,
      441 => :LIECHIBERRY,
      442 => :GANLONBERRY,
      443 => :SALACBERRY,
      444 => :PETAYABERRY,
      445 => :APICOTBERRY,
      446 => :LANSATBERRY,
      447 => :STARFBERRY,
      448 => :ENIGMABERRY,
      449 => :MICLEBERRY,
      450 => :CUSTAPBERRY,
      451 => :JABOCABERRY,
      452 => :ROWAPBERRY
    }
    mulch_conversion = {
      59 => :GROWTHMULCH,
      60 => :DAMPMULCH,
      61 => :STABLEMULCH,
      62 => :GOOEYMULCH
    }
    global.eventvars.each_value do |var|
      next if !var || !var.is_a?(Array)
      next if var.length < 6 || var.length > 8   # Neither old nor new berry plant
      if !var[1].is_a?(Symbol)   # Planted berry item
        var[1] = berry_conversion[var[1]] || :ORANBERRY
      end
      if var[7] && !var[7].is_a?(Symbol)   # Mulch
        var[7] = mulch_conversion[var[7]]
      end
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v20_refactor_planted_berries_data) do
  essentials_version 20
  display_title "Actualizando el formato de datos de las plantas de bayas"
  to_value :global_metadata do |global|
    if global.eventvars
      global.eventvars.each_pair do |key, value|
        next if !value || !value.is_a?(Array)
        case value.length
        when 6   # Old berry plant data
          data = BerryPlantData.new
          if value[1].is_a?(Symbol)
            plant_data = GameData::BerryPlant.get(value[1])
            data.new_mechanics      = false
            data.berry_id           = value[1]
            data.time_alive         = value[0] * plant_data.hours_per_stage * 3600
            data.time_last_updated  = value[3]
            data.growth_stage       = value[0]
            data.replant_count      = value[5]
            data.watered_this_stage = value[2]
            data.watering_count     = value[4]
          end
          global.eventvars[key] = data
        when 7, 8   # New berry plant data
          data = BerryPlantData.new
          if value[1].is_a?(Symbol)
            data.new_mechanics     = true
            data.berry_id          = value[1]
            data.mulch_id          = value[7] if value[7].is_a?(Symbol)
            data.time_alive        = value[2]
            data.time_last_updated = value[3]
            data.growth_stage      = value[0]
            data.replant_count     = value[5]
            data.moisture_level    = value[4]
            data.yield_penalty     = value[6]
          end
          global.eventvars[key] = data
        end
      end
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v20_refactor_follower_data) do
  essentials_version 20
  display_title "Actualizando el formato de los dataos del acompañante"
  to_value :global_metadata do |global|
    # NOTE: dependentEvents is still defined in class PokemonGlobalMetadata just
    #       for the sake of this conversion. It is deprecated and will be
    #       removed in v22.
    if global.dependentEvents && global.dependentEvents.length > 0
      global.followers = []
      global.dependentEvents.each do |follower|
        data = FollowerData.new(follower[0], follower[1], "reflection",
                                follower[2], follower[3], follower[4],
                                follower[5], follower[6], follower[7])
        data.name            = follower[8]
        data.common_event_id = follower[9]
        global.followers.push(data)
      end
    end
    global.dependentEvents = nil
  end
end

#===============================================================================

SaveData.register_conversion(:v20_refactor_day_care_variables) do
  essentials_version 20
  display_title "Refactorizando variables de la Guardería Pokémon"
  to_value :global_metadata do |global|
    global.instance_eval do
      @day_care = DayCare.new if @day_care.nil?
      if !@daycare.nil?
        @daycare.each do |old_slot|
          if !old_slot[0]
            old_slot[0] = Pokemon.new(:MANAPHY, 50)
            old_slot[1] = 4
          end
          next if !old_slot[0]
          @day_care.slots.each do |slot|
            next if slot.filled?
            slot.instance_eval do
              @pokemon = old_slot[0]
              @initial_level = old_slot[1]
              if @pokemon && @pokemon.markings.is_a?(Integer)
                markings = []
                6.times { |i| markings[i] = ((@pokemon.markings & (1 << i)) == 0) ? 0 : 1 }
                @pokemon.markings = markings
              end
            end
          end
        end
        @day_care.egg_generated = ((@daycareEgg.is_a?(Numeric) && @daycareEgg > 0) || @daycareEgg == true)
        @day_care.step_counter = @daycareEggSteps
        @daycare = nil
        @daycareEgg = nil
        @daycareEggSteps = nil
      end
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v20_rename_bag_variables) do
  essentials_version 20
  display_title "Renombrando Variables de la Mochila"
  to_value :bag do |bag|
    bag.instance_eval do
      if !@lastpocket.nil?
        @last_viewed_pocket = @lastpocket
        @lastPocket = nil
      end
      if !@choices.nil?
        @last_pocket_selections = @choices.clone
        @choices = nil
      end
      if !@registeredItems.nil?
        @registered_items = @registeredItems || []
        @registeredItems = nil
      end
      if !@registeredIndex.nil?
        @ready_menu_selection = @registeredIndex || [0, 0, 1]
        @registeredIndex = nil
      end
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v20_increment_player_character_id) do
  essentials_version 20
  display_title "Incrementando el ID del personaje del jugador"
  to_value :player do |player|
    player.character_ID += 1
  end
end

#===============================================================================

SaveData.register_conversion(:v20_add_pokedex_records) do
  essentials_version 20
  display_title "Añadiendo más registros a la Pokédex"
  to_value :player do |player|
    player.pokedex.instance_eval do
      @caught_counts = {} if @caught_counts.nil?
      @defeated_counts = {} if @defeated_counts.nil?
      @seen_eggs = {} if @seen_eggs.nil?
      @seen_forms.each_value do |sp|
        next if !sp || sp[0][0].is_a?(Array)   # Already converted to include shininess
        sp[0] = [sp[0], []]
        sp[1] = [sp[1], []]
      end
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v20_add_new_default_options) do
  essentials_version 20
  display_title "Actualizando las opciones para incluir nuevas configuraciones"
  to_value :pokemon_system do |option|
    option.givenicknames = 0 if option.givenicknames.nil?
    option.sendtoboxes = 0 if option.sendtoboxes.nil?
  end
end

#===============================================================================

SaveData.register_conversion(:v20_fix_default_weather_type) do
  essentials_version 20
  display_title "Corrigiendo el efecto del clima 0"
  to_value :game_screen do |game_screen|
    game_screen.instance_eval do
      @weather_type = :None if @weather_type == 0
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v20_add_stats) do
  essentials_version 20
  display_title "Añadiendo estadísticas a los datos guardados"
  to_all do |save_data|
    unless save_data.has_key?(:stats)
      save_data[:stats] = GameStats.new
      save_data[:stats].play_time = (save_data[:frame_count] || 0).to_f / Graphics.frame_rate
      save_data[:stats].play_sessions = 1
      save_data[:stats].time_last_saved = save_data[:stats].play_time
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v20_convert_pokemon_markings) do
  essentials_version 20
  display_title "Actualizando el formato de las marcas de los Pokémon"
  to_all do |save_data|
    # Create a lambda function that updates a Pokémon's markings
    update_markings = lambda do |pkmn|
      return if !pkmn || !pkmn.markings.is_a?(Integer)
      markings = []
      6.times { |i| markings[i] = ((pkmn.markings & (1 << i)) == 0) ? 0 : 1 }
      pkmn.markings = markings
    end
    # Party Pokémon
    save_data[:player].party.each { |pkmn| update_markings.call(pkmn) }
    # Pokémon storage
    save_data[:storage_system].boxes.each do |box|
      box.pokemon.each { |pkmn| update_markings.call(pkmn) if pkmn }
    end
    # NOTE: Pokémon in the Day Care have their markings converted above.
    # Partner trainer
    if save_data[:global_metadata].partner
      save_data[:global_metadata].partner[3].each { |pkmn| update_markings.call(pkmn) }
    end
    # Roaming Pokémon
    if save_data[:global_metadata].roamPokemon
      save_data[:global_metadata].roamPokemon.each { |pkmn| update_markings.call(pkmn) }
    end
    # Purify Chamber
    save_data[:global_metadata].purifyChamber.sets.each do |set|
      set.list.each { |pkmn| update_markings.call(pkmn) }
      update_markings.call(set.shadow) if set.shadow
    end
    # Hall of Fame records
    if save_data[:global_metadata].hallOfFame
      save_data[:global_metadata].hallOfFame.each do |team|
        next if !team
        team.each { |pkmn| update_markings.call(pkmn) }
      end
    end
    # Pokémon stored in Game Variables for some reason
    variables = save_data[:variables]
    (0..5000).each do |i|
      value = variables[i]
      case value
      when Array
        value.each { |value2| update_markings.call(value2) if value2.is_a?(Pokemon) }
      when Pokemon
        update_markings.call(value)
      end
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v21_replace_phone_data) do
  essentials_version 21
  display_title "Actualizando el formato de los datos del Teléfono"
  to_value :global_metadata do |global|
    if !global.phone
      global.instance_eval do
        @phone = Phone.new
        @phoneTime = nil   # Don't bother using this
        if @phoneNumbers
          @phoneNumbers.each do |contact|
            if contact.length > 4
              # Trainer
              Phone.add_silent(contact[6], contact[7], contact[1], contact[2], contact[5], 0)
              new_contact = Phone.get(contact[1], contact[2], 0)
              new_contact.visible = contact[0]
              new_contact.rematch_flag = [contact[4] - 1, 0].max
            else
              # Non-trainer
              Phone.add_silent(contact[3], contact[2], contact[1])
            end
          end
          @phoneNumbers = nil
        end
      end
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v21_replace_flute_booleans) do
  essentials_version 21
  display_title "Actualizando las variables de la Flauta Negra/Blanca"
  to_value :map_metadata do |metadata|
    metadata.instance_eval do
      if !@blackFluteUsed.nil?
        if Settings::FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS
          @higher_level_wild_pokemon = @blackFluteUsed
        else
          @lower_encounter_rate = @blackFluteUsed
        end
        @blackFluteUsed = nil
      end
      if !@whiteFluteUsed.nil?
        if Settings::FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS
          @lower_level_wild_pokemon = @whiteFluteUsed
        else
          @higher_encounter_rate = @whiteFluteUsed
        end
        @whiteFluteUsed = nil
      end
    end
  end
end

#===============================================================================

SaveData.register_conversion(:v21_add_bump_stat) do
  essentials_version 21
  display_title "Añadiendo una estadística de golpeo"
  to_value :stats do |stats|
    stats.instance_eval do
      @bump_count = 0 if !@bump_count
    end
  end
end