#===============================================================================
# "v21.1 Hotfixes" plugin
# This file contains fixes for bugs in Essentials v21.1.
# These bug fixes are also in the master branch of the GitHub version of
# Essentials:
# https://github.com/Maruno17/pokemon-essentials
#===============================================================================

Essentials::ERROR_TEXT += "[v21.1 Hotfixes 1.0.9]\r\n"

#===============================================================================
# Fixed Pokédex not showing male/female options for species with gender
# differences, and showing them for species without.
#===============================================================================
class PokemonPokedexInfo_Scene
  def pbGetAvailableForms
    ret = []
    multiple_forms = false
    gender_differences = (GameData::Species.front_sprite_filename(@species, 0) != GameData::Species.front_sprite_filename(@species, 0, 1))
    # Find all genders/forms of @species that have been seen
    GameData::Species.each do |sp|
      next if sp.species != @species
      next if sp.form != 0 && (!sp.real_form_name || sp.real_form_name.empty?)
      next if sp.pokedex_form != sp.form
      multiple_forms = true if sp.form > 0
      if sp.single_gendered?
        real_gender = (sp.gender_ratio == :AlwaysFemale) ? 1 : 0
        next if !$player.pokedex.seen_form?(@species, real_gender, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
        real_gender = 2 if sp.gender_ratio == :Genderless
        ret.push([sp.form_name, real_gender, sp.form])
      elsif sp.form == 0 && !gender_differences
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          ret.push([sp.form_name || _INTL("Forma Normal"), 0, sp.form])
          break
        end
      else   # Both male and female
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          ret.push([sp.form_name, real_gndr, sp.form])
          break if sp.form_name && !sp.form_name.empty?   # Only show 1 entry for each non-0 form
        end
      end
    end
    # Sort all entries
    ret.sort! { |a, b| (a[2] == b[2]) ? a[1] <=> b[1] : a[2] <=> b[2] }
    # Create form names for entries if they don't already exist
    ret.each do |entry|
      if entry[0]   # Alternate forms, and form 0 if no gender differences
        entry[0] = "" if !multiple_forms && !gender_differences
      else   # Necessarily applies only to form 0
        case entry[1]
        when 0 then entry[0] = _INTL("Macho")
        when 1 then entry[0] = _INTL("Hembra")
        else
          entry[0] = (multiple_forms) ? _INTL("Forma Normal") : _INTL("Sin género")
        end
      end
      entry[1] = 0 if entry[1] == 2   # Genderless entries are treated as male
    end
    return ret
  end
end

#===============================================================================
# Fixed class PngAnimatedBitmap animating slowly.
#===============================================================================
class PngAnimatedBitmap
  def initialize(dir, filename, hue = 0)
    @frames       = []
    @currentFrame = 0
    @timer_start  = System.uptime
    panorama = RPG::Cache.load_bitmap(dir, filename, hue)
    if filename[/^\[(\d+)(?:,(\d+))?\]/]   # Starts with 1 or 2 numbers in brackets
      # File has a frame count
      numFrames = $1.to_i
      duration  = $2.to_i   # In 1/20ths of a second
      duration  = 5 if duration == 0
      raise "Numero de frames inválido en #{filename}" if numFrames <= 0
      raise "Duración de frames inválido en #{filename}" if duration <= 0
      if panorama.width % numFrames != 0
        raise "Ancho del Bitmap (#{panorama.width}) no es divisible por el número de frames: #{filename}"
      end
      @frame_duration = duration / 20.0
      subWidth = panorama.width / numFrames
      numFrames.times do |i|
        subBitmap = Bitmap.new(subWidth, panorama.height)
        subBitmap.blt(0, 0, panorama, Rect.new(subWidth * i, 0, subWidth, panorama.height))
        @frames.push(subBitmap)
      end
      panorama.dispose
    else
      @frames = [panorama]
    end
  end

  def totalFrames
    return (@frame_duration * @frames.length * 20).to_i
  end
end

#===============================================================================
# Fixed being unable to replace a NamedEvent.
#===============================================================================
class NamedEvent
  def add(key, proc)
    @callbacks[key] = proc
  end
end

#===============================================================================
# Fixed crash when a phone contact tries to call you while you're on a map with
# no map metadata.
#===============================================================================
class Phone
  module Call
    module_function

    def can_make?
      return false if $game_map.metadata&.has_flag?("NoPhoneSignal")
      return true
    end
  end
end

#===============================================================================
# Fixed being able to fly from the Town Map even if the CAN_FLY_FROM_TOWN_MAP
# Setting is false.
#===============================================================================
class PokemonRegionMap_Scene
  def pbMapScene
    x_offset = 0
    y_offset = 0
    new_x    = 0
    new_y    = 0
    timer_start = System.uptime
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if x_offset != 0 || y_offset != 0
        if x_offset != 0
          @sprites["cursor"].x = lerp(new_x - x_offset, new_x, 0.1, timer_start, System.uptime)
          x_offset = 0 if @sprites["cursor"].x == new_x
        end
        if y_offset != 0
          @sprites["cursor"].y = lerp(new_y - y_offset, new_y, 0.1, timer_start, System.uptime)
          y_offset = 0 if @sprites["cursor"].y == new_y
        end
        next if x_offset != 0 || y_offset != 0
      end
      ox = 0
      oy = 0
      case Input.dir8
      when 1, 2, 3
        oy = 1 if @map_y < BOTTOM
      when 7, 8, 9
        oy = -1 if @map_y > TOP
      end
      case Input.dir8
      when 1, 4, 7
        ox = -1 if @map_x > LEFT
      when 3, 6, 9
        ox = 1 if @map_x < RIGHT
      end
      if ox != 0 || oy != 0
        @map_x += ox
        @map_y += oy
        x_offset = ox * SQUARE_WIDTH
        y_offset = oy * SQUARE_HEIGHT
        new_x = @sprites["cursor"].x + x_offset
        new_y = @sprites["cursor"].y + y_offset
        timer_start = System.uptime
      end
      @sprites["mapbottom"].maplocation = pbGetMapLocation(@map_x, @map_y)
      @sprites["mapbottom"].mapdetails  = pbGetMapDetails(@map_x, @map_y)
      if Input.trigger?(Input::BACK)
        if @editor && @changed
          pbSaveMapData if pbConfirmMessage(_INTL("¿Guardar cambios?")) { pbUpdate }
          break if pbConfirmMessage(_INTL("¿Salir del mapa?")) { pbUpdate }
        else
          break
        end
      elsif Input.trigger?(Input::USE) && @mode == 1   # Choosing an area to fly to
        healspot = pbGetHealingSpot(@map_x, @map_y)
        if healspot && ($PokemonGlobal.visitedMaps[healspot[0]] ||
           ($DEBUG && Input.press?(Input::CTRL)))
          return healspot if @fly_map
          name = pbGetMapNameFromId(healspot[0])
          return healspot if pbConfirmMessage(_INTL("¿Quieres usar Vuelo para ir a {1}?", name)) { pbUpdate }
        end
      elsif Input.trigger?(Input::USE) && @editor   # Intentionally after other USE input check
        pbChangeMapLocation(@map_x, @map_y)
      elsif Input.trigger?(Input::ACTION) && Settings::CAN_FLY_FROM_TOWN_MAP &&
            !@wallmap && !@fly_map && pbCanFly?
        pbPlayDecisionSE
        @mode = (@mode == 1) ? 0 : 1
        refresh_fly_screen
      end
    end
    pbPlayCloseMenuSE
    return nil
  end
end

#===============================================================================
# Language files are now loaded properly even if the game is encrypted.
# Fixed trying to load non-existent language files not reverting the messages to
# the default messages if other language files are already loaded.
#===============================================================================
class Translation
  def load_message_files(filename)
    @core_messages = nil
    @game_messages = nil
    begin
      core_filename = sprintf("Data/messages_%s_core.dat", filename)
      if FileTest.exist?(core_filename)
        @core_messages = load_data(core_filename)
        @core_messages = nil if !@core_messages.is_a?(Array)
      end
      game_filename = sprintf("Data/messages_%s_game.dat", filename)
      if FileTest.exist?(game_filename)
        @game_messages = load_data(game_filename)
        @game_messages = nil if !@game_messages.is_a?(Array)
      end
    rescue
      @core_messages = nil
      @game_messages = nil
    end
  end
end

#===============================================================================
# Fixed standing on an event preventing you from interacting with an event
# you're facing.
#===============================================================================
class Game_Player < Game_Character
  def pbCheckEventTriggerFromDistance(triggers)
    events = pbTriggeredTrainerEvents(triggers)
    events.concat(pbTriggeredCounterEvents(triggers))
    return false if events.length == 0
    ret = false
    events.each do |event|
      event.start
      ret = true if event.starting
    end
    return ret
  end

  def check_event_trigger_here(triggers)
    result = false
    # If event is running
    return result if $game_system.map_interpreter.running?
    # All event loops
    $game_map.events.each_value do |event|
      # If event coordinates and triggers are consistent
      next if !event.at_coordinate?(@x, @y)
      next if !triggers.include?(event.trigger)
      # If starting determinant is same position event (other than jumping)
      next if event.jumping? || !event.over_trigger?
      event.start
      result = true if event.starting
    end
    return result
  end

  def check_event_trigger_there(triggers)
    result = false
    # If event is running
    return result if $game_system.map_interpreter.running?
    # Calculate front event coordinates
    new_x = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    new_y = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    return false if !$game_map.valid?(new_x, new_y)
    # All event loops
    $game_map.events.each_value do |event|
      next if !triggers.include?(event.trigger)
      # If event coordinates and triggers are consistent
      next if !event.at_coordinate?(new_x, new_y)
      # If starting determinant is front event (other than jumping)
      next if event.jumping? || event.over_trigger?
      event.start
      result = true if event.starting
    end
    # If fitting event is not found
    if result == false && $game_map.counter?(new_x, new_y)
      # Calculate coordinates of 1 tile further away
      new_x += (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
      new_y += (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
      return false if !$game_map.valid?(new_x, new_y)
      # All event loops
      $game_map.events.each_value do |event|
        next if !triggers.include?(event.trigger)
        # If event coordinates and triggers are consistent
        next if !event.at_coordinate?(new_x, new_y)
        # If starting determinant is front event (other than jumping)
        next if event.jumping? || event.over_trigger?
        event.start
        result = true if event.starting
      end
    end
    return result
  end

  def check_event_trigger_touch(dir)
    result = false
    return result if $game_system.map_interpreter.running?
    # All event loops
    x_offset = (dir == 4) ? -1 : (dir == 6) ? 1 : 0
    y_offset = (dir == 8) ? -1 : (dir == 2) ? 1 : 0
    $game_map.events.each_value do |event|
      next if ![1, 2].include?(event.trigger)   # Player touch, event touch
      # If event coordinates and triggers are consistent
      next if !event.at_coordinate?(@x + x_offset, @y + y_offset)
      if event.name[/(?:sight|trainer)\((\d+)\)/i]
        distance = $~[1].to_i
        next if !pbEventCanReachPlayer?(event, self, distance)
      elsif event.name[/counter\((\d+)\)/i]
        distance = $~[1].to_i
        next if !pbEventFacesPlayer?(event, self, distance)
      end
      # If starting determinant is front event (other than jumping)
      next if event.jumping? || event.over_trigger?
      event.start
      result = true if event.starting
    end
    return result
  end
end

#===============================================================================
# Fixed line breaks making some messages appear oddly at slow text speeds.
#===============================================================================
class Window_AdvancedTextPokemon < SpriteWindow_Base
  def updateInternal
    time_now = System.uptime
    @display_last_updated = time_now if !@display_last_updated
    delta_t = time_now - @display_last_updated
    @display_last_updated = time_now
    visiblelines = (self.height - self.borderY) / @lineHeight
    @lastchar = -1 if !@lastchar
    show_more_characters = false
    # Pauses and new lines
    if @textchars[@curchar] == "\1"   # Waiting
      show_more_characters = true if !@pausing
    elsif @textchars[@curchar] == "\n"   # Move to new line
      if @linesdrawn >= visiblelines - 1   # Need to scroll text to show new line
        if @scroll_timer_start
          old_y = @scrollstate
          new_y = lerp(0, @lineHeight, 0.1, @scroll_timer_start, time_now)
          @scrollstate = new_y
          @scrollY += new_y - old_y
          if @scrollstate >= @lineHeight
            @scrollstate = 0
            @scroll_timer_start = nil
            @linesdrawn += 1
            show_more_characters = true
          end
        else
          show_more_characters = true
        end
      else   # New line but the next line can be shown without scrolling to it
        @linesdrawn += 1 if @lastchar < @curchar
        show_more_characters = true
      end
    elsif @curchar <= @numtextchars   # Displaying more text
      show_more_characters = true
    else
      @displaying = false
      @scrollstate = 0
      @scrollY = 0
      @scroll_timer_start = nil
      @linesdrawn = 0
    end
    @lastchar = @curchar
    # Keep displaying more text
    if show_more_characters
      @display_timer += delta_t
      if curcharSkip
        if @textchars[@curchar] == "\n" && @linesdrawn >= visiblelines - 1
          @scroll_timer_start = time_now
        elsif @textchars[@curchar] == "\1"
          @pausing = true if @curchar < @numtextchars - 1
          self.startPause
          refresh
        end
      end
    end
  end
end

#===============================================================================
# Fixed Rotom Catalog not being able to change Rotom to its base form.
#===============================================================================
ItemHandlers::UseOnPokemon.add(:ROTOMCATALOG, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:ROTOM)
    scene.pbDisplay(_INTL("Pero no tuvo efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("Esto no puede ser usado en un Pokémon debilitado."))
    next false
  end
  choices = [
    _INTL("Bombilla"),
    _INTL("Microondas"),
    _INTL("Lavadora"),
    _INTL("Nevera"),
    _INTL("Ventilador"),
    _INTL("Corta césped"),
    _INTL("Cancelar")
  ]
  new_form = scene.pbShowCommands(_INTL("¿Qué electrodoméstico quieres pedir?"), choices, pkmn.form)
  if new_form == pkmn.form
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  elsif new_form >= 0 && new_form < choices.length - 1
    pkmn.setForm(new_form) do
      scene.pbRefresh
      scene.pbDisplay(_INTL("{1} se transformó!", pkmn.name))
    end
    next true
  end
  next false
})

#===============================================================================
# Fixed an event's reflection not disappearing if its page is changed to one
# without a graphic.
#===============================================================================
class Sprite_Character < RPG::Sprite
  def refresh_graphic
    return if @tile_id == @character.tile_id &&
              @character_name == @character.character_name &&
              @character_hue == @character.character_hue &&
              @oldbushdepth == @character.bush_depth
    @tile_id        = @character.tile_id
    @character_name = @character.character_name
    @character_hue  = @character.character_hue
    @oldbushdepth   = @character.bush_depth
    @charbitmap&.dispose
    @charbitmap = nil
    @bushbitmap&.dispose
    @bushbitmap = nil
    if @tile_id >= 384
      @charbitmap = pbGetTileBitmap(@character.map.tileset_name, @tile_id,
                                    @character_hue, @character.width, @character.height)
      @charbitmapAnimated = false
      @spriteoffset = false
      @cw = Game_Map::TILE_WIDTH * @character.width
      @ch = Game_Map::TILE_HEIGHT * @character.height
      self.src_rect.set(0, 0, @cw, @ch)
      self.ox = @cw / 2
      self.oy = @ch
    elsif @character_name != ""
      @charbitmap = AnimatedBitmap.new(
        "Graphics/Characters/" + @character_name, @character_hue
      )
      RPG::Cache.retain("Graphics/Characters/", @character_name, @character_hue) if @character == $game_player
      @charbitmapAnimated = true
      @spriteoffset = @character_name[/offset/i]
      @cw = @charbitmap.width / 4
      @ch = @charbitmap.height / 4
      self.ox = @cw / 2
    else
      self.bitmap = nil
      @cw = 0
      @ch = 0
      @reflection&.update   # HOTFIXES: Just added this line
    end
    @character.sprite_size = [@cw, @ch]
  end
end

#===============================================================================
# Fixed bad conversion of old phone data in an old save file.
#===============================================================================
SaveData.register_conversion(:v21_replace_phone_data) do
  essentials_version 21
  display_title "Updating Phone data format"
  to_value :global_metadata do |global|
    if !global.phone
      global.instance_eval do
        @phone = Phone.new
        @phoneTime = nil   # Don't bother using this
        if @phoneNumbers
          @phoneNumbers.each do |contact|
            if contact.length > 4
              # Trainer
              @phone.add(contact[6], contact[7], contact[1], contact[2], contact[5], 0)
              new_contact = @phone.get(contact[1], contact[2], 0)
              new_contact.visible = contact[0]
              new_contact.rematch_flag = [contact[4] - 1, 0].max
            else
              # Non-trainer
              @phone.add(contact[3], contact[2], contact[1])
            end
          end
          @phoneNumbers = nil
        end
      end
    end
  end
end
#===============================================================================
# Fixed events with an even width/height that approach the player shuffling back
# and forth endlessly in front of them.
#===============================================================================
class Game_Character
  def move_toward_player
    sx = @x + (@width / 2.0) - ($game_player.x + ($game_player.width / 2.0))
    sy = @y - (@height / 2.0) - ($game_player.y - ($game_player.height / 2.0))
    return if sx == 0 && sy == 0
    abs_sx = sx.abs
    abs_sy = sy.abs
    if abs_sx == abs_sy
      (rand(2) == 0) ? abs_sx += 1 : abs_sy += 1
    end
    if abs_sx > abs_sy
      if abs_sx >= 1
        (sx > 0) ? move_left : move_right
      end
      if !moving? && sy != 0
        if abs_sy >= 1
          (sy > 0) ? move_up : move_down
        end
      end
    else
      if abs_sy >= 1
        (sy > 0) ? move_up : move_down
      end
      if !moving? && sx != 0
        if abs_sx >= 1
          (sx > 0) ? move_left : move_right
        end
      end
    end
  end
end
#===============================================================================
# Fixed Event Touch events on a connected map triggering themselves by moving
# around.
#===============================================================================
class Game_Event < Game_Character
  alias __hotfixes__over_trigger? over_trigger? unless method_defined?(:__hotfixes__over_trigger?)
  def over_trigger?
    return false if @map_id != $game_player.map_id
    return __hotfixes__over_trigger?
  end
  alias __hotfixes__check_event_trigger_touch check_event_trigger_touch unless method_defined?(:__hotfixes__check_event_trigger_touch)
  def check_event_trigger_touch(dir)
    return if @map_id != $game_player.map_id
    __hotfixes__check_event_trigger_touch(dir)
  end
  alias __hotfixes__pbCheckEventTriggerAfterTurning pbCheckEventTriggerAfterTurning unless method_defined?(:__hotfixes__pbCheckEventTriggerAfterTurning)
  def pbCheckEventTriggerAfterTurning
    return if @map_id != $game_player.map_id
    return __hotfixes__pbCheckEventTriggerAfterTurning
  end
  def onEvent?
    return @map_id == $game_player.map_id && at_coordinate?($game_player.x, $game_player.y)
  end
  def check_event_trigger_after_moving
    return if @map_id != $game_player.map_id
    return if @trigger != 2   # Not Event Touch
    return if $game_system.map_interpreter.running? || @starting
    if self.name[/(?:sight|trainer)\((\d+)\)/i]
      distance = $~[1].to_i
      return if !pbEventCanReachPlayer?(self, $game_player, distance)
    elsif self.name[/counter\((\d+)\)/i]
      distance = $~[1].to_i
      return if !pbEventFacesPlayer?(self, $game_player, distance)
    else
      return
    end
    return if jumping? || over_trigger?
    start
  end
  def update
    @to_update = should_update?(true)
    @updated_last_frame = false
    return if !@to_update
    @updated_last_frame = true
    @moveto_happened = false
    last_moving = moving?
    super
    check_event_trigger_after_moving if !moving? && last_moving
    if @need_refresh
      @need_refresh = false
      refresh
    end
    check_event_trigger_auto
    if @interpreter
      @interpreter.setup(@list, @event.id, @map_id) if !@interpreter.running?
      @interpreter.update
    end
  end
end
class Game_Player < Game_Character
  def pbCheckEventTriggerFromDistance(triggers)
    events = pbTriggeredTrainerEvents(triggers)
    events.concat(pbTriggeredCounterEvents(triggers))
    return false if events.length == 0
    ret = false
    events.each do |event|
      event.start
      ret = true if event.starting
    end
    return ret
  end
  def check_event_trigger_here(triggers)
    result = false
    # If event is running
    return result if $game_system.map_interpreter.running?
    # All event loops
    $game_map.events.each_value do |event|
      # If event coordinates and triggers are consistent
      next if !event.at_coordinate?(@x, @y)
      next if !triggers.include?(event.trigger)
      # If starting determinant is same position event (other than jumping)
      next if event.jumping? || !event.over_trigger?
      event.start
      result = true if event.starting
    end
    return result
  end
  def check_event_trigger_there(triggers)
    result = false
    # If event is running
    return result if $game_system.map_interpreter.running?
    # Calculate front event coordinates
    new_x = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    new_y = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    return false if !$game_map.valid?(new_x, new_y)
    # All event loops
    $game_map.events.each_value do |event|
      next if !triggers.include?(event.trigger)
      # If event coordinates and triggers are consistent
      next if !event.at_coordinate?(new_x, new_y)
      # If starting determinant is front event (other than jumping)
      next if event.jumping? || event.over_trigger?
      event.start
      result = true if event.starting
    end
    # If fitting event is not found
    if result == false && $game_map.counter?(new_x, new_y)
      # Calculate coordinates of 1 tile further away
      new_x += (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
      new_y += (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
      return false if !$game_map.valid?(new_x, new_y)
      # All event loops
      $game_map.events.each_value do |event|
        next if !triggers.include?(event.trigger)
        # If event coordinates and triggers are consistent
        next if !event.at_coordinate?(new_x, new_y)
        # If starting determinant is front event (other than jumping)
        next if event.jumping? || event.over_trigger?
        event.start
        result = true if event.starting
      end
    end
    return result
  end
  def check_event_trigger_touch(dir)
    result = false
    return result if $game_system.map_interpreter.running?
    # All event loops
    x_offset = (dir == 4) ? -1 : (dir == 6) ? 1 : 0
    y_offset = (dir == 8) ? -1 : (dir == 2) ? 1 : 0
    $game_map.events.each_value do |event|
      next if ![1, 2].include?(event.trigger)   # Player touch, event touch
      # If event coordinates and triggers are consistent
      next if !event.at_coordinate?(@x + x_offset, @y + y_offset)
      if event.name[/(?:sight|trainer)\((\d+)\)/i]
        distance = $~[1].to_i
        next if !pbEventCanReachPlayer?(event, self, distance)
      elsif event.name[/counter\((\d+)\)/i]
        distance = $~[1].to_i
        next if !pbEventFacesPlayer?(event, self, distance)
      end
      # If starting determinant is front event (other than jumping)
      next if event.jumping? || event.over_trigger?
      event.start
      result = true if event.starting
    end
    return result
  end
end
def pbEventCanReachPlayer?(event, player, distance)
  return false if event.map_id != player.map_id
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
  return false if event1.map_id != event2.map_id
  return pbEventFacesPlayer?(event1, event2, 1) && pbEventFacesPlayer?(event2, event1, 1)
end