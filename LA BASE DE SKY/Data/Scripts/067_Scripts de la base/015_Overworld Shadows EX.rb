module OWShadowSettings
  # Set this to true if you want the event name and character name blacklists to be case sensitive.
  CASE_SENSITIVE_BLACKLISTS = false

  # If an event name contains one of these words, it will not have a shadow.
  SHADOWLESS_EVENT_NAME     = [
    "door", "FlechaSalida", "nurse", "Enfermera", "Healing balls", "Balls curativas", "Mart","Tendero", "SmashRock", "RocaRompible", "StrengthBoulder", "PiedraFuerza",
    "CutTree", "ArbolCorte", "HeadbuttTree", "ArbolGolpeCabeza", "BerryPlant", "Planta Bayas", ".shadowless", ".noshadow", ".sl", "Entrada Mazmorra Bosque", "Entrada Cueva", "Relic Stone",
    "Escalera"
  ]

  # If the character file and event uses contains one of these words in its filename, it will not have a shadow.
  SHADOWLESS_CHARACTER_NAME = ["nil"]

  # If an event stands on a tile with one of these terrain tags, it will not have a shadow.
  # (Names can be seen in the script section "Terrain Tag")
  SHADOWLESS_TERRAIN_NAME   = [
    :Grass, :DeepWater, :StillWater, :Water, :Waterfall, :WaterfallCrest,
    :Puddle
  ]

  # If an event doesn't have a custom shadow defined, it will use this shadow graphic
  DEFAULT_SHADOW_FILENAME   = "defaultShadow"

  # Defaul shadow graphic used by the player
  PLAYER_SHADOW_FILENAME    = "defaultShadow"
end


#-------------------------------------------------------------------------------
# New Class for Shadow object
#-------------------------------------------------------------------------------
class Sprite_OWShadow
  attr_reader :visible
  #-----------------------------------------------------------------------------
  # Initialize a shadow sprite based on the name of the event
  #-----------------------------------------------------------------------------
  def initialize(sprite, event, viewport = nil)
    @rsprite  = sprite
    @event    = event
    @viewport = viewport
    @sprite   = Sprite.new(viewport)
    @disposed = false
    @remove   = false
    name      = ""
    if !defined?(Game_FollowingPkmn) || !@event.is_a?(Game_FollowingPkmn)
      if @event != $game_player
        name = $~[1] if @event.name[/shdw\((.*?)\)/]
      else
        name = OWShadowSettings::PLAYER_SHADOW_FILENAME
      end
    end
    name = OWShadowSettings::DEFAULT_SHADOW_FILENAME if nil_or_empty?(name)
    @ow_shadow_bitmap = AnimatedBitmap.new("Graphics/Characters/Shadows/" + name)
    RPG::Cache.retain("Graphics/Characters/Shadows/" + name)
    update
  end
  #-----------------------------------------------------------------------------
  # Override the bitmap of the shadow sprite
  #-----------------------------------------------------------------------------
  def set_bitmap(name)
    if !pbResolveBitmap("Graphics/Characters/Shadows/" + name)
      echoln("The Shadow File you are trying to set it absent from /Graphics/Characters/Shadows/")
      return
    end
    @ow_shadow_bitmap = AnimatedBitmap.new("Graphics/Characters/Shadows/" + name)
    RPG::Cache.retain("Graphics/Characters/Shadows/" + name)
    @sprite.dispose if @sprite && !@sprite.disposed?
    @sprite = nil
    @sprite = Sprite.new(@viewport)
    @sprite.bitmap  = @ow_shadow_bitmap.bitmap
    update
  end
  #-----------------------------------------------------------------------------
  # Dispose the shadow bitmap
  #-----------------------------------------------------------------------------
  def dispose
    return if @disposed
    @sprite.dispose if @sprite
    @sprite = nil
    @disposed = true
  end
  #-----------------------------------------------------------------------------
  # Check whether the shadow has been disposed
  #-----------------------------------------------------------------------------
  def disposed?; return @disposed; end
  #-----------------------------------------------------------------------------
  # Calculation of shadow size when jumping
  #-----------------------------------------------------------------------------
  def jump_sprite
    return unless @sprite
    if @event.jump_distance_left && @event.jump_distance_left >= 1 && @event.jump_distance_left < @event.jump_peak
      @sprite.zoom_x += 0.1
      @sprite.zoom_y += 0.1
    elsif @event.jump_distance_left && @event.jump_distance_left >= @event.jump_peak
      @sprite.zoom_x -= 0.05
      @sprite.zoom_y -= 0.05
    end
    @sprite.zoom_x = 1 if @sprite.zoom_x > 1
    @sprite.zoom_x = 0 if @sprite.zoom_x < 0
    @sprite.zoom_y = 1 if @sprite.zoom_y > 1
    @sprite.zoom_y = 0 if @sprite.zoom_y < 0
    if @event.jump_count == 1
      @sprite.zoom_x = 1.0
      @sprite.zoom_y = 1.0
    end
    @sprite.x = @event.screen_x
    @sprite.y = @event.screen_y
    @sprite.z = @rsprite.z - 1
  end
  #-----------------------------------------------------------------------------
  # Calculation of shadow size when jumping
  #-----------------------------------------------------------------------------
  def update
    return if disposed? || !$scene.is_a?(Scene_Map)
    return jump_sprite if @event.jumping?
    @sprite = Sprite.new(@viewport) if !@sprite
    @ow_shadow_bitmap.update
    @sprite.bitmap  = @ow_shadow_bitmap.bitmap
    @sprite.x       = @rsprite.x
    @sprite.y       = @rsprite.y
    @sprite.ox      = @ow_shadow_bitmap.width / 2
    @sprite.oy      = @ow_shadow_bitmap.height - 2
    @sprite.z       = @event.screen_z(@ow_shadow_bitmap.height) - 1
    @sprite.zoom_x  = @rsprite.zoom_x
    @sprite.zoom_y  = @rsprite.zoom_y
    @sprite.opacity = @rsprite.opacity
    @sprite.visible = @rsprite.visible && @event.shows_shadow?
  end
  #-----------------------------------------------------------------------------
end

#-------------------------------------------------------------------------------
# New Method for setting shadow of any event given the map id and event id
#-------------------------------------------------------------------------------
def pbSetOverworldShadow(name, event_id = nil, map_id = nil)
  return if !$scene.is_a?(Scene_Map)
  return if nil_or_empty?(name)
  if !event_id
    $scene.spritesetGlobal.playersprite.ow_shadow.set_bitmap(name)
  else
    map_id = $game_map.map_id if !map_id
    $scene.spritesets[map_id].character_sprites[(event_id - 1)].ow_shadow.set_bitmap(name)
  end
end


#-------------------------------------------------------------------------------
# Referencing and initializing Shadow Sprite in Sprite_Character
#-------------------------------------------------------------------------------
class Sprite_Character
  attr_accessor :ow_shadow
  #-----------------------------------------------------------------------------
  # Initializing Shadow with Character
  #-----------------------------------------------------------------------------
  alias __ow_shadow__initialize initialize unless private_method_defined?(:__ow_shadow__initialize)
  def initialize(*args)
    __ow_shadow__initialize(*args)
    @ow_shadow = Sprite_OWShadow.new(self, args[1], args[0])
    update
  end
  #-----------------------------------------------------------------------------
  # Disposing Shadow with Character
  #-----------------------------------------------------------------------------
  alias __ow_shadow__dispose dispose unless method_defined?(:__ow_shadow__dispose)
  def dispose(*args)
    __ow_shadow__dispose(*args)
    @ow_shadow.dispose if @ow_shadow
    @ow_shadow = nil
  end
  #-----------------------------------------------------------------------------
  # Updating Shadow with Character
  #-----------------------------------------------------------------------------
  alias __ow_shadow__update update unless method_defined?(:__ow_shadow__update)
  def update(*args)
    __ow_shadow__update(*args)
    return if !@ow_shadow
    @ow_shadow.update
  end
end

#-------------------------------------------------------------------------------
# Adding shadow checking method to Game_Event
#-------------------------------------------------------------------------------
class Game_Character
  attr_reader :jump_count
  attr_reader :jump_distance
  attr_reader :jump_distance_left
  attr_reader :jump_peak
  #-----------------------------------------------------------------------------
  # Initializing Shadow with event
  #-----------------------------------------------------------------------------
  alias __ow_shadow__initialize initialize unless private_method_defined?(:__ow_shadow__initialize)
  def initialize(*args)
    __ow_shadow__initialize(*args)
    @shows_shadow = false
  end
  #-----------------------------------------------------------------------------
  # Updating Shadow with Character
  #-----------------------------------------------------------------------------
  alias __ow_shadow__calculate_bush_depth calculate_bush_depth unless method_defined?(:__ow_shadow__calculate_bush_depth)
  def calculate_bush_depth(*args)
    __ow_shadow__calculate_bush_depth(*args)
    @shows_shadow = shows_shadow?(true)
  end
  #-----------------------------------------------------------------------------
  # Check whether the character should have a shadow
  #-----------------------------------------------------------------------------
  def shows_shadow?(recalc = false)
    return @shows_shadow if !recalc
    return false if nil_or_empty?(self.character_name) || self.transparent
    if OWShadowSettings::CASE_SENSITIVE_BLACKLISTS
      return false if OWShadowSettings::SHADOWLESS_CHARACTER_NAME.any?{ |e| self.character_name[/#{e}/] }
      return false if self.respond_to?(:name) && OWShadowSettings::SHADOWLESS_EVENT_NAME.any? { |e| self.name[/#{e}/]}
    else
      return false if OWShadowSettings::SHADOWLESS_CHARACTER_NAME.any?{ |e| self.character_name[/#{e}/i] }
      return false if self.respond_to?(:name) && OWShadowSettings::SHADOWLESS_EVENT_NAME.any? { |e| self.name[/#{e}/]}
    end
    terrain = $game_map.terrain_tag(self.x, self.y)
    return false if OWShadowSettings::SHADOWLESS_TERRAIN_NAME.any? { |e| terrain == e } if terrain
    return true
  end
  #-----------------------------------------------------------------------------
  # Updating Shadows when transparency is changed
  #-----------------------------------------------------------------------------
  alias __ow_shadow__transparent_set transparent= unless method_defined?(:__ow_shadow__transparent_set)
  def transparent=(*args)
    __ow_shadow__transparent_set(*args)
    @shows_shadow = shows_shadow?(true)
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
# CREDITOS
# Golisopod User, Wolf PP, Marin
# Website    = https://www.youtube.com/watch?v=dQw4w9WgXcQ
#===============================================================================
#-------------------------------------------------------------------------------
# Updating Shadow with Character
#-------------------------------------------------------------------------------
class Game_Event
  alias __ow_shadow__refresh refresh unless method_defined?(:__ow_shadow__refresh)
  def refresh(*args)
    ret = __ow_shadow__refresh(*args)
    @shows_shadow = shows_shadow?(true)
    return ret
  end
end

class Game_Player
  #-----------------------------------------------------------------------------
  # Updating Shadow with Player's Movement
  #-----------------------------------------------------------------------------
  alias __ow_shadow__set_movement_type set_movement_type unless method_defined?(:__ow_shadow__set_movement_type)
  def set_movement_type(*args)
    ret = __ow_shadow__set_movement_type(*args)
    @shows_shadow = shows_shadow?(true)
    return ret
  end
  #-----------------------------------------------------------------------------
end

#-------------------------------------------------------------------------------
# Adding accessors to the Scene_Map class
#-------------------------------------------------------------------------------
class Scene_Map
  attr_accessor :spritesets
end

#-------------------------------------------------------------------------------
# Adding accessors to the Game_Character class
#-------------------------------------------------------------------------------
class Spriteset_Map
  attr_accessor :character_sprites
end

