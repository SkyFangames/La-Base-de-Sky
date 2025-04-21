#===============================================================================
# Constant checks
#===============================================================================
# Pokérus check
EventHandlers.add(:on_frame_update, :pokerus_counter,
  proc {
    next if !$player || $player.party.none? { |pkmn| pkmn.pokerusStage == 1 }
    last = $PokemonGlobal.pokerusTime
    next if !last
    now = pbGetTimeNow
    if last.year != now.year || last.month != now.month || last.day != now.day
      $player.pokemon_party.each { |pkmn| pkmn.lowerPokerusCount }
      $PokemonGlobal.pokerusTime = now
    end
  }
)

# Returns whether the Poké Center should explain Pokérus to the player, if a
# healed Pokémon has it.
def pbPokerus?
  return false if $game_switches[Settings::SEEN_POKERUS_SWITCH]
  $player.party.each do |i|
    return true if i.pokerusStage == 1
  end
  return false
end

class Game_Temp
  attr_accessor :warned_low_battery
  attr_accessor :cue_bgm
  attr_accessor :cue_bgm_timer_start
  attr_accessor :cue_bgm_delay
end

def pbBatteryLow?
  pstate = System.power_state
  # If it's not discharging, it doesn't matter if it's low
  return false if !pstate[:discharging]
  # Check for less than 10m, priority over the percentage
  # Some laptops (Chromebooks, Macbooks) have very long lifetimes
  return true if pstate[:seconds] && pstate[:seconds] <= 600
  # Check for <=15%
  return true if pstate[:percent] && pstate[:percent] <= 15
  return false
end

EventHandlers.add(:on_frame_update, :low_battery_warning,
  proc {
    next if $game_temp.warned_low_battery || !pbBatteryLow?
    next if $game_temp.in_menu || $game_temp.in_battle || $game_player.move_route_forcing ||
            $game_temp.message_window_showing || pbMapInterpreterRunning?
    $game_temp.warned_low_battery = true
    pbMessage(_INTL("El juego ha detectado que la batería está baja. Deberías guardar pronto para evitar perder el progreso."))
  }
)

EventHandlers.add(:on_frame_update, :cue_bgm_after_delay,
  proc {
    next if $game_temp.cue_bgm_delay.nil?
    next if System.uptime - $game_temp.cue_bgm_timer_start < $game_temp.cue_bgm_delay
    $game_temp.cue_bgm_delay = nil
    pbBGMPlay($game_temp.cue_bgm) if $game_system.getPlayingBGM.nil?
  }
)

#===============================================================================
# Checks per step
#===============================================================================
# Party Pokémon gain happiness from walking
EventHandlers.add(:on_player_step_taken, :gain_happiness,
  proc {
    $PokemonGlobal.happinessSteps = 0 if !$PokemonGlobal.happinessSteps
    $PokemonGlobal.happinessSteps += 1
    next if $PokemonGlobal.happinessSteps < 128
    $player.able_party.each do |pkmn|
      pkmn.changeHappiness("walking") if rand(2) == 0
    end
    $PokemonGlobal.happinessSteps = 0
  }
)

# Poison party Pokémon
EventHandlers.add(:on_player_step_taken_can_transfer, :poison_party,
  proc { |handled|
    # handled is an array: [nil]. If [true], a transfer has happened because of
    # this event, so don't do anything that might cause another one
    next if handled[0]
    next if !Settings::POISON_IN_FIELD || $PokemonGlobal.stepcount % 4 != 0
    flashed = false
    $player.able_party.each do |pkmn|
      next if pkmn.status != :POISON || pkmn.hasAbility?(:IMMUNITY)
      if !flashed
        pbSEPlay("Poison step")
        pbFlash(Color.new(255, 0, 0, 128), 8)
        flashed = true
      end
      pkmn.hp -= 1 if pkmn.hp > 1 || Settings::POISON_FAINT_IN_FIELD
      if pkmn.hp == 1 && !Settings::POISON_FAINT_IN_FIELD
        pkmn.status = :NONE
        pbMessage(_INTL("{1} sobrevivió al veneno.\\n¡El veneno ha desaparecido!", pkmn.name))
        next
      elsif pkmn.hp == 0
        pkmn.changeHappiness("faint")
        pkmn.status = :NONE
        pbMessage(_INTL("{1} se debilitó...", pkmn.name))
      end
      if $player.able_pokemon_count == 0
        handled[0] = true
        pbCheckAllFainted
      end
    end
  }
)

def pbCheckAllFainted
  if $player.able_pokemon_count == 0
    pbMessage(_INTL("¡No tienes más Pokémon que puedan pelear!") + "\1")
    pbMessage(_INTL("¡Te has desmayado!"))
    pbBGMFade(1.0)
    pbBGSFade(1.0)
    pbFadeOutIn { pbStartOver }
  end
end

# Gather soot from soot grass
EventHandlers.add(:on_step_taken, :pick_up_soot,
  proc { |event|
    thistile = $map_factory.getRealTilePos(event.map.map_id, event.x, event.y)
    map = $map_factory.getMap(thistile[0])
    [2, 1, 0].each do |i|
      tile_id = map.data[thistile[1], thistile[2], i]
      next if tile_id.nil?
      next if GameData::TerrainTag.try_get(map.terrain_tags[tile_id]).id != :SootGrass
      if event == $game_player && $bag.has?(:SOOTSACK)
        old_soot = $player.soot
        $player.soot += 1
        $stats.soot_collected += $player.soot - old_soot if $player.soot > old_soot
      end
      map.erase_tile(thistile[1], thistile[2], i)
      break
    end
  }
)

# Show grass rustle animation
EventHandlers.add(:on_step_taken, :grass_rustling,
  proc { |event|
    next if !$scene.is_a?(Scene_Map)
    event.each_occupied_tile do |x, y|
      next if !$map_factory.getTerrainTagFromCoords(event.map.map_id, x, y, true).shows_grass_rustle
      spriteset = $scene.spriteset(event.map_id)
      spriteset&.addUserAnimation(Settings::GRASS_ANIMATION_ID, x, y, true, 1)
    end
  }
)

# Auto-move the player over waterfalls and ice
EventHandlers.add(:on_step_taken, :auto_move_player,
  proc { |event|
    next if !$scene.is_a?(Scene_Map)
    next if event != $game_player
    currentTag = $game_player.pbTerrainTag
    if currentTag.waterfall_crest || currentTag.waterfall ||
       $PokemonGlobal.descending_waterfall || $PokemonGlobal.ascending_waterfall
      pbTraverseWaterfall
    elsif currentTag.ice || $PokemonGlobal.ice_sliding
      pbSlideOnIce
    end
  }
)

def pbOnStepTaken(eventTriggered)
  if $game_player.move_route_forcing || pbMapInterpreterRunning?
    EventHandlers.trigger(:on_step_taken, $game_player)
    return
  end
  $PokemonGlobal.stepcount = 0 if !$PokemonGlobal.stepcount
  $PokemonGlobal.stepcount += 1
  $PokemonGlobal.stepcount &= 0x7FFFFFFF
  repel_active = ($PokemonGlobal.repel > 0)
  EventHandlers.trigger(:on_player_step_taken)
  handled = [nil]
  EventHandlers.trigger(:on_player_step_taken_can_transfer, handled)
  return if handled[0]
  pbBattleOnStepTaken(repel_active) if !eventTriggered && !$game_temp.in_menu
  $game_temp.encounter_triggered = false   # This info isn't needed here
end

# Start wild encounters while turning on the spot
EventHandlers.add(:on_player_change_direction, :trigger_encounter,
  proc {
    repel_active = ($PokemonGlobal.repel > 0)
    pbBattleOnStepTaken(repel_active) if !$game_temp.in_menu
  }
)

def pbBattleOnStepTaken(repel_active)
  return if $player.able_pokemon_count == 0
  return if !$PokemonEncounters.encounter_possible_here?
  encounter_type = $PokemonEncounters.encounter_type
  return if !encounter_type
  return if !$PokemonEncounters.encounter_triggered?(encounter_type, repel_active)
  $game_temp.encounter_type = encounter_type
  encounter = $PokemonEncounters.choose_wild_pokemon(encounter_type)
  EventHandlers.trigger(:on_wild_species_chosen, encounter)
  if $PokemonEncounters.allow_encounter?(encounter, repel_active)
    if $PokemonEncounters.have_double_wild_battle?
      encounter2 = $PokemonEncounters.choose_wild_pokemon(encounter_type)
      EventHandlers.trigger(:on_wild_species_chosen, encounter2)
      WildBattle.start(encounter, encounter2, can_override: true)
    else
      WildBattle.start(encounter, can_override: true)
    end
    $game_temp.encounter_type = nil
    $game_temp.encounter_triggered = true
  end
  $game_temp.force_single_battle = false
end

#===============================================================================
# Checks when moving between maps
#===============================================================================
# Set up various data related to the new map.
EventHandlers.add(:on_enter_map, :setup_new_map,
  proc { |old_map_id|   # previous map ID, is 0 if no map ID
    # Record new Teleport destination
    new_map_metadata = $game_map.metadata
    if new_map_metadata&.teleport_destination
      $PokemonGlobal.healingSpot = new_map_metadata.teleport_destination
    end
    # End effects that apply only while on the map they were used
    $PokemonMap&.clear
    # Setup new wild encounter tables
    $PokemonEncounters&.setup($game_map.map_id)
    # Record the new map as having been visited
    $PokemonGlobal.visitedMaps[$game_map.map_id] = true
  }
)

# Changes the overworld weather.
EventHandlers.add(:on_enter_map, :set_weather,
  proc { |old_map_id|   # previous map ID, is 0 if no map ID
    next if old_map_id == 0 || old_map_id == $game_map.map_id
    old_weather = $game_screen.weather_type
    new_weather = :None
    new_map_metadata = $game_map.metadata
    if new_map_metadata&.weather
      new_weather = new_map_metadata.weather[0] if rand(100) < new_map_metadata.weather[1]
    end
    next if old_weather == new_weather
    $game_screen.weather(new_weather, 9, 0)
  }
)

# Update trail of which maps the player has most recently visited.
EventHandlers.add(:on_enter_map, :add_to_trail,
  proc { |_old_map_id|
    next if !$game_map
    $PokemonGlobal.mapTrail = [] if !$PokemonGlobal.mapTrail
    if $PokemonGlobal.mapTrail[0] != $game_map.map_id && $PokemonGlobal.mapTrail.length >= 4
      $PokemonGlobal.mapTrail.pop
    end
    $PokemonGlobal.mapTrail = [$game_map.map_id] + $PokemonGlobal.mapTrail
  }
)

# Force cycling/walking.
EventHandlers.add(:on_enter_map, :force_cycling,
  proc { |_old_map_id|
    if $game_map.metadata&.always_bicycle
      pbMountBike
    elsif !pbCanUseBike?($game_map.map_id)
      pbDismountBike
    end
  }
)

# Display darkness circle on dark maps.
EventHandlers.add(:on_map_or_spriteset_change, :show_darkness,
  proc { |scene, _map_changed|
    next if !scene || !scene.spriteset
    map_metadata = $game_map.metadata
    if map_metadata&.dark_map
      $game_temp.darkness_sprite = DarknessSprite.new
      scene.spriteset.addUserSprite($game_temp.darkness_sprite)
      if $PokemonGlobal.flashUsed
        $game_temp.darkness_sprite.radius = $game_temp.darkness_sprite.radiusMax
      end
    else
      $PokemonGlobal.flashUsed = false
      $game_temp.darkness_sprite&.dispose
      $game_temp.darkness_sprite = nil
    end
  }
)

# Show location signpost.
EventHandlers.add(:on_map_or_spriteset_change, :show_location_window,
  proc { |scene, map_changed|
    next if !scene || !scene.spriteset
    next if !map_changed || !$game_map.metadata&.announce_location
    nosignpost = false
    if $PokemonGlobal.mapTrail[1]
      (Settings::NO_SIGNPOSTS.length / 2).times do |i|
        nosignpost = true if Settings::NO_SIGNPOSTS[2 * i] == $PokemonGlobal.mapTrail[1] &&
                             Settings::NO_SIGNPOSTS[(2 * i) + 1] == $game_map.map_id
        nosignpost = true if Settings::NO_SIGNPOSTS[(2 * i) + 1] == $PokemonGlobal.mapTrail[1] &&
                             Settings::NO_SIGNPOSTS[2 * i] == $game_map.map_id
        break if nosignpost
      end
      nosignpost = true if $game_map.name == pbGetMapNameFromId($PokemonGlobal.mapTrail[1])
    end
    scene.spriteset.addUserSprite(LocationWindow.new($game_map.name)) if !nosignpost
  }
)

#===============================================================================
# Event locations, terrain tags
#===============================================================================
# NOTE: Assumes the event is 1x1 tile in size. Only returns one tile.
def pbFacingTile(direction = nil, event = nil)
  return $map_factory.getFacingTile(direction, event) if $map_factory
  return pbFacingTileRegular(direction, event)
end

# NOTE: Assumes the event is 1x1 tile in size. Only returns one tile.
def pbFacingTileRegular(direction = nil, event = nil)
  event = $game_player if !event
  return [0, 0, 0] if !event
  x = event.x
  y = event.y
  direction = event.direction if !direction
  x_offset = [0, -1, 0, 1, -1, 0, 1, -1, 0, 1][direction]
  y_offset = [0, 1, 1, 1, 0, 0, 0, -1, -1, -1][direction]
  return [$game_map.map_id, x + x_offset, y + y_offset]
end

# Returns whether event is in line with the player, is facing the player and is
# within distance tiles of the player.
def pbEventFacesPlayer?(event, player, distance)
  return false if !event || !player || distance <= 0
  x_min = x_max = y_min = y_max = -1
  case event.direction
  when 2   # Down
    x_min = event.x
    x_max = event.x + event.width - 1
    y_min = event.y + 1
    y_max = event.y + distance
  when 4   # Left
    x_min = event.x - distance
    x_max = event.x - 1
    y_min = event.y - event.height + 1
    y_max = event.y
  when 6   # Right
    x_min = event.x + event.width
    x_max = event.x + event.width - 1 + distance
    y_min = event.y - event.height + 1
    y_max = event.y
  when 8   # Up
    x_min = event.x
    x_max = event.x + event.width - 1
    y_min = event.y - event.height + 1 - distance
    y_max = event.y - event.height
  else
    return false
  end
  return player.x >= x_min && player.x <= x_max &&
         player.y >= y_min && player.y <= y_max
end

# Returns whether event is able to walk up to the player.
def pbEventCanReachPlayer?(event, player, distance)
  return false if !pbEventFacesPlayer?(event, player, distance)
  delta_x = (event.direction == 6) ? 1 : (event.direction == 4) ? -1 : 0
  delta_y = (event.direction == 2) ? 1 : (event.direction == 8) ? -1 : 0
  case event.direction
  when 2   # Down
    real_distance = player.y - event.y - 1
  when 4   # Left
    real_distance = event.x - player.x - 1
  when 6   # Right
    real_distance = player.x - event.x - event.width
  when 8   # Up
    real_distance = event.y - event.height - player.y
  end
  if real_distance > 0
    real_distance.times do |i|
      return false if !event.can_move_from_coordinate?(event.x + (i * delta_x), event.y + (i * delta_y), event.direction)
    end
  end
  return true
end

# Returns whether the two events are standing next to each other and facing each
# other.
def pbFacingEachOther(event1, event2)
  return pbEventFacesPlayer?(event1, event2, 1) && pbEventFacesPlayer?(event2, event1, 1)
end

#===============================================================================
# Audio playing
#===============================================================================
def pbCueBGM(bgm, seconds, volume = nil, pitch = nil)
  return if !bgm
  bgm = pbResolveAudioFile(bgm, volume, pitch)
  playingBGM = $game_system.playing_bgm
  if !playingBGM || playingBGM.name != bgm.name || playingBGM.pitch != bgm.pitch
    pbBGMFade(seconds)
    $game_temp.cue_bgm = bgm
    if !$game_temp.cue_bgm_delay
      $game_temp.cue_bgm_delay = seconds * 0.6
      $game_temp.cue_bgm_timer_start = System.uptime
    end
  elsif playingBGM
    pbBGMPlay(bgm)
  end
end

def pbAutoplayOnTransition
  surfbgm = GameData::Metadata.get.surf_BGM
  if $PokemonGlobal.surfing && surfbgm
    pbBGMPlay(surfbgm)
  else
    $game_map.autoplayAsCue
  end
end

def pbAutoplayOnSave
  surfbgm = GameData::Metadata.get.surf_BGM
  if $PokemonGlobal.surfing && surfbgm
    pbBGMPlay(surfbgm)
  else
    $game_map.autoplay
  end
end

#===============================================================================
# Event movement
#===============================================================================
module PBMoveRoute
  DOWN                  = 1
  LEFT                  = 2
  RIGHT                 = 3
  UP                    = 4
  LOWER_LEFT            = 5
  LOWER_RIGHT           = 6
  UPPER_LEFT            = 7
  UPPER_RIGHT           = 8
  RANDOM                = 9
  TOWARD_PLAYER         = 10
  AWAY_FROM_PLAYER      = 11
  FORWARD               = 12
  BACKWARD              = 13
  JUMP                  = 14   # xoffset, yoffset
  WAIT                  = 15   # frames
  TURN_DOWN             = 16
  TURN_LEFT             = 17
  TURN_RIGHT            = 18
  TURN_UP               = 19
  TURN_RIGHT90          = 20
  TURN_LEFT90           = 21
  TURN180               = 22
  TURN_RIGHT_OR_LEFT90  = 23
  TURN_RANDOM           = 24
  TURN_TOWARD_PLAYER    = 25
  TURN_AWAY_FROM_PLAYER = 26
  SWITCH_ON             = 27   # 1 param
  SWITCH_OFF            = 28   # 1 param
  CHANGE_SPEED          = 29   # 1 param
  CHANGE_FREQUENCY      = 30   # 1 param
  WALK_ANIME_ON         = 31
  WALK_ANIME_OFF        = 32
  STEP_ANIME_ON         = 33
  STEP_ANIME_OFF        = 34
  DIRECTION_FIX_ON      = 35
  DIRECTION_FIX_OFF     = 36
  THROUGH_ON            = 37
  THROUGH_OFF           = 38
  ALWAYS_ON_TOP_ON      = 39
  ALWAYS_ON_TOP_OFF     = 40
  GRAPHIC               = 41   # Name, hue, direction, pattern
  OPACITY               = 42   # 1 param
  BLENDING              = 43   # 1 param
  PLAY_SE               = 44   # 1 param
  SCRIPT                = 45   # 1 param
  SCRIPT_ASYNC          = 101   # 1 param
end

def pbMoveRoute(event, commands, waitComplete = false)
  route = RPG::MoveRoute.new
  route.repeat    = false
  route.skippable = true
  route.list.clear
  route.list.push(RPG::MoveCommand.new(PBMoveRoute::THROUGH_ON))
  i = 0
  while i < commands.length
    case commands[i]
    when PBMoveRoute::WAIT, PBMoveRoute::SWITCH_ON, PBMoveRoute::SWITCH_OFF,
       PBMoveRoute::CHANGE_SPEED, PBMoveRoute::CHANGE_FREQUENCY, PBMoveRoute::OPACITY,
       PBMoveRoute::BLENDING, PBMoveRoute::PLAY_SE, PBMoveRoute::SCRIPT
      route.list.push(RPG::MoveCommand.new(commands[i], [commands[i + 1]]))
      i += 1
    when PBMoveRoute::SCRIPT_ASYNC
      route.list.push(RPG::MoveCommand.new(PBMoveRoute::SCRIPT, [commands[i + 1]]))
      route.list.push(RPG::MoveCommand.new(PBMoveRoute::WAIT, [0]))
      i += 1
    when PBMoveRoute::JUMP
      route.list.push(RPG::MoveCommand.new(commands[i], [commands[i + 1], commands[i + 2]]))
      i += 2
    when PBMoveRoute::GRAPHIC
      route.list.push(RPG::MoveCommand.new(commands[i],
                                           [commands[i + 1], commands[i + 2],
                                            commands[i + 3], commands[i + 4]]))
      i += 4
    else
      route.list.push(RPG::MoveCommand.new(commands[i]))
    end
    i += 1
  end
  route.list.push(RPG::MoveCommand.new(PBMoveRoute::THROUGH_OFF))
  route.list.push(RPG::MoveCommand.new(0))
  event&.force_move_route(route)
  return route
end

# duration is in seconds
def pbWait(duration)
  timer_start = System.uptime
  until System.uptime - timer_start >= duration
    yield System.uptime - timer_start if block_given?
    Graphics.update
    Input.update
    pbUpdateSceneMap
  end
end

#===============================================================================
# Player/event movement in the field
#===============================================================================
def pbSlideOnIce
  if !$DEBUG || !Input.press?(Input::CTRL)
    if $game_player.pbTerrainTag.ice && $game_player.can_move_in_direction?($game_player.direction)
      $PokemonGlobal.ice_sliding = true
      $game_player.straighten
      $game_player.walk_anime = false
      return
    end
  end
  $PokemonGlobal.ice_sliding = false
  $game_player.walk_anime = true
end

def pbTurnTowardEvent(event, otherEvent)
  sx = 0
  sy = 0
  if $map_factory
    relativePos = $map_factory.getThisAndOtherEventRelativePos(otherEvent, event)
    sx = relativePos[0]
    sy = relativePos[1]
  else
    sx = event.x - otherEvent.x
    sy = event.y - otherEvent.y
  end
  sx += (event.width - otherEvent.width) / 2.0
  sy -= (event.height - otherEvent.height) / 2.0
  return if sx == 0 && sy == 0
  if sx.abs > sy.abs
    (sx > 0) ? event.turn_left : event.turn_right
  else
    (sy > 0) ? event.turn_up : event.turn_down
  end
end

def pbMoveTowardPlayer(event)
  maxsize = [$game_map.width, $game_map.height].max
  return if !pbEventCanReachPlayer?(event, $game_player, maxsize)
  loop do
    x = event.x
    y = event.y
    event.move_toward_player
    break if event.x == x && event.y == y
    while event.moving?
      Graphics.update
      Input.update
      pbUpdateSceneMap
    end
  end
  $PokemonMap&.addMovedEvent(event.id)
end

#===============================================================================
# Bridges, cave escape points, and setting the heal point
#===============================================================================
def pbBridgeOn(height = 2)
  $PokemonGlobal.bridge = height
end

def pbBridgeOff
  $PokemonGlobal.bridge = 0
end

def pbSetEscapePoint
  $PokemonGlobal.escapePoint = [] if !$PokemonGlobal.escapePoint
  xco = $game_player.x
  yco = $game_player.y
  case $game_player.direction
  when 2   # Down
    yco -= 1
    dir = 8
  when 4   # Left
    xco += 1
    dir = 6
  when 6   # Right
    xco -= 1
    dir = 4
  when 8   # Up
    yco += 1
    dir = 2
  end
  $PokemonGlobal.escapePoint = [$game_map.map_id, xco, yco, dir]
end

def pbEraseEscapePoint
  $PokemonGlobal.escapePoint = []
end

def pbSetPokemonCenter
  $PokemonGlobal.pokecenterMapId     = $game_map.map_id
  $PokemonGlobal.pokecenterX         = $game_player.x
  $PokemonGlobal.pokecenterY         = $game_player.y
  $PokemonGlobal.pokecenterDirection = $game_player.direction
end

#===============================================================================
# Partner trainer
#===============================================================================
def pbRegisterPartner(tr_type, tr_name, tr_id = 0)
  tr_type = GameData::TrainerType.get(tr_type).id
  pbCancelVehicles
  trainer = pbLoadTrainer(tr_type, tr_name, tr_id)
  EventHandlers.trigger(:on_trainer_load, trainer)
  trainer.party.each do |i|
    i.owner = Pokemon::Owner.new_from_trainer(trainer)
    i.calc_stats
  end
  $PokemonGlobal.partner = [tr_type, tr_name, trainer.id, trainer.party]
end

def pbDeregisterPartner
  $PokemonGlobal.partner = nil
end

#===============================================================================
# Picking up an item found on the ground
#===============================================================================
def pbItemBall(item, quantity = 1, outfit_change = nil)
  item = GameData::Item.get(item)
  return false if !item || quantity < 1
  itemname = (quantity > 1) ? item.portion_name_plural : item.portion_name
  pocket = item.pocket
  move = item.move
  if $bag.add(item, quantity)   # If item can be picked up
    if outfit_change && outfit_change != $player.outfit
      old_outfit = $player.outfit
      $player.outfit = outfit_change
    end
    meName = (item.is_key_item?) ? "Key item get" : "Item get"
    if item == :DNASPLICERS
      pbMessage("\\me[#{meName}]" + _INTL("¡Has encontrado \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
    elsif item.is_machine?   # TM or HM
      if quantity > 1
        pbMessage("\\me[Machine get]" + _INTL("¡Has encontrado {1} \\c[1]{2} {3}\\c[0]!",
                                              quantity, itemname, GameData::Move.get(move).name) + "\\wtnp[70]")
      else
        pbMessage("\\me[Machine get]" + _INTL("¡Has encontrado \\c[1]{1} {2}\\c[0]!",
                                              itemname, GameData::Move.get(move).name) + "\\wtnp[70]")
      end
    elsif quantity > 1
      pbMessage("\\me[#{meName}]" + _INTL("¡Has encontrado {1} \\c[1]{2}\\c[0]!", quantity, itemname) + "\\wtnp[40]")
    elsif itemname.starts_with_vowel?
      pbMessage("\\me[#{meName}]" + _INTL("¡Has encontrado \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
    else
      pbMessage("\\me[#{meName}]" + _INTL("¡Has encontrado \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
    end
    pbMessage(_INTL("Has guardado {1} en\\nel bolsillo <icon=bagPocket{2}>\\c[1]{3}\\c[0].",
                    itemname, pocket, PokemonBag.pocket_names[pocket - 1]))
    $player.outfit = old_outfit if outfit_change
    return true
  end
  # Can't add the item
  # if item.is_machine?   # TM or HM
  #   if quantity > 1
  #     pbMessage(_INTL("¡Has encontrado {1} \\c[1]{2} {3}\\c[0]!", quantity, itemname, GameData::Move.get(move).name))
  #   else
  #     pbMessage(_INTL("¡Has encontrado \\c[1]{1} {2}\\c[0]!", itemname, GameData::Move.get(move).name))
  #   end
  # elsif quantity > 1
  #   pbMessage(_INTL("¡Has encontrado {1} \\c[1]{2}\\c[0]!", quantity, itemname))
  # elsif itemname.starts_with_vowel?
  #   pbMessage(_INTL("¡Has encontrado \\c[1]{1}\\c[0]!", itemname))
  # else
  #   pbMessage(_INTL("¡Has encontrado \\c[1]{1}\\c[0]!", itemname))
  # end
  pbMessage(_INTL("Pero tu Mochila está llena..."))
  return false
end

#===============================================================================
# Being given an item
#===============================================================================
def pbReceiveItem(item, quantity = 1)
  item = GameData::Item.get(item)
  return false if !item || quantity < 1
  itemname = (quantity > 1) ? item.portion_name_plural : item.portion_name
  pocket = item.pocket
  move = item.move
  meName = (item.is_key_item?) ? "Key item get" : "Item get"
  if item == :DNASPLICERS
    pbMessage("\\me[#{meName}]" + _INTL("¡Has obtenido \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
  elsif item.is_machine?   # TM or HM
    if quantity > 1
      pbMessage("\\me[Machine get]" + _INTL("¡Has obtenido {1} \\c[1]{2} {3}\\c[0]!",
                                            quantity, itemname, GameData::Move.get(move).name) + "\\wtnp[70]")
    else
      pbMessage("\\me[Machine get]" + _INTL("¡Has obtenido \\c[1]{1} {2}\\c[0]!",
                                            itemname, GameData::Move.get(move).name) + "\\wtnp[70]")
    end
  elsif quantity > 1
    pbMessage("\\me[#{meName}]" + _INTL("¡Has obtenido {1} \\c[1]{2}\\c[0]!", quantity, itemname) + "\\wtnp[40]")
  elsif itemname.starts_with_vowel?
    pbMessage("\\me[#{meName}]" + _INTL("¡Has obtenido \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
  else
    pbMessage("\\me[#{meName}]" + _INTL("¡Has obtenido \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
  end
  if $bag.add(item, quantity)   # If item can be added
    pbMessage(_INTL("Has guardado {1} en\\nel bolsillo <icon=bagPocket{2}>\\c[1]{3}\\c[0].",
                    itemname, pocket, PokemonBag.pocket_names[pocket - 1]))
    return true
  end
  return false   # Can't add the item
end

#===============================================================================
# Buying a prize item from the Game Corner
#===============================================================================
def pbBuyPrize(item, quantity = 1)
  item = GameData::Item.get(item)
  return false if !item || quantity < 1
  item_name = (quantity > 1) ? item.portion_name_plural : item.portion_name
  pocket = item.pocket
  return false if !$bag.add(item, quantity)
  pbMessage("\\CN" + _INTL("Has puesto {1} en\\nel bolsillo <icon=bagPocket{2}>\\c[1]{3}\\c[0].",
                           item_name, pocket, PokemonBag.pocket_names[pocket - 1]))
  return true
end

