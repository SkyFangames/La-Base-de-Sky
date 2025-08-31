#===============================================================================
# * Debug Passability Script for Pokémon Essentials by shiney570.
# * Adaptado a Essentials V21 por DPertierra
# * Optimizado para dibujar solo área visible alrededor del jugador
#
# Current Version: V2.1 - Optimized
#
#
# * If you have any questions or found a bug let me know.
# * Contact: Skype: imatrix.wt ; DeviantArt: shiney570
#===============================================================================

# SETTINGS

# When true, the event squares will be visible. (May reduce lag.)
SHOW_EVENTS = true
# When true, the passability squares will be visible.
SHOW_PASSIBILITY = true
# When true, the terrain tags will be visible.
SHOW_TERRAIN_TAGS = true

# NUEVA CONFIGURACIÓN: Distancia de renderizado (en casillas)
RENDER_DISTANCE = 10

# Size of the field square. (choose a number between 1 and 15.)
$passa_field_size = 4
# Size of the event square. (choose a number between 1 and 32.)
$passa_event_size = 16
$passa_event_size_outline = 2
# Opacity of the squares.
# (choose a number between 0 (invisible) and 255 (visible).)

$passa_opacity = 200
# Color of the field squares. (red by default.)
$passa_field_color = Color.new(255,0,0)
# Color of the event squares.
$passa_event_color = Color.new(0,0,0) # (black by default.)
$passa_event_color2 = Color.new(255,255,255)# (white by default.)
# Color of the terrain text.
$passa_terrain_color = Color.new(255,255,255) # (white by default.)
$passa_terrain_color2 = Color.new(0,0,0) # (black by default.)
#===============================================================================

class Debug_Passability
  def initialize
    # The next four lines were made for idiots.
    $passa_field_size=4 if ($passa_field_size>15 || $passa_field_size<1)
    $passa_event_size=16 if ($passa_event_size>32 || $passa_field_size<1)
    $passa_event_size_outline=2 if ($passa_event_size_outline>32 || $passa_event_size_outline<1)
    $passa_opacity=200 if ($passa_opacity>255 || $passa_opacity<1)
    
    # Calcular área visible alrededor del jugador
    player_x = $game_player.x
    player_y = $game_player.y
    
    # Límites del área a dibujar
    min_x = [0, player_x - RENDER_DISTANCE].max
    max_x = [$game_map.width - 1, player_x + RENDER_DISTANCE].min
    min_y = [0, player_y - RENDER_DISTANCE].max  
    max_y = [$game_map.height - 1, player_y + RENDER_DISTANCE].min
    
    # Creating bitmap and sprite con tamaño completo del mapa
    if $passa_bitmap
      $passa_bitmap.clear
      $passa_sprite.dispose
      $passa_terrain_bitmap.dispose if $passa_terrain_bitmap
    end
    $passa_bitmap=Bitmap.new($game_map.width*32,$game_map.height*32)
    $passa_sprite=Sprite.new
    $passa_sprite.bitmap=$passa_bitmap
    $passa_sprite.z=100
    $passa_sprite.opacity=$passa_opacity
    $passa_bitmap.clear
    
    $passa_terrain_bitmap=BitmapSprite.new($game_map.width*32,$game_map.height*32)
    $passa_terrain_bitmap.z=$passa_sprite.z
    $passa_terrain_bitmap.bitmap.font.name="Sword"
    $passa_terrain_bitmap.bitmap.font.size=20
    $passa_terrain=[]
    $passa_data = nil
    $map_id = nil
    
    # Filling the fields SOLO EN EL ÁREA VISIBLE
    for xval in min_x..max_x
      for yval in min_y..max_y
        x=16+xval*32
        y=16+yval*32
        
        if isEvent?(xval,yval)
          $passa_bitmap.fill_rect(x+16-($passa_event_size/2),
          y+16-($passa_event_size/2),$passa_event_size,
          $passa_event_size,$passa_event_color)
          $passa_bitmap.fill_rect(x+16-($passa_event_size/2),
          y+16-($passa_event_size/2),$passa_event_size,
          $passa_event_size_outline,$passa_event_color2)
          $passa_bitmap.fill_rect(x+16-($passa_event_size/2),
          y+16-($passa_event_size/2)+$passa_event_size-$passa_event_size_outline,
          $passa_event_size,$passa_event_size_outline,$passa_event_color2)
          $passa_bitmap.fill_rect(x+16-($passa_event_size/2),
          y+16-($passa_event_size/2),$passa_event_size_outline,
          $passa_event_size,$passa_event_color2)
          $passa_bitmap.fill_rect(x+16-($passa_event_size/2)+$passa_event_size-$passa_event_size_outline,
          y+16-($passa_event_size/2),$passa_event_size_outline,$passa_event_size,
          $passa_event_color2)
        end
        
        if !playerPassable?(xval,yval,2) # DOWN
          $passa_bitmap.fill_rect(x,y+32-$passa_field_size,32,
          $passa_field_size,$passa_field_color)
        end
        if !playerPassable?(xval,yval,4) # LEFT
          $passa_bitmap.fill_rect(x,y,$passa_field_size,32,
          $passa_field_color)
        end
        if !playerPassable?(xval,yval,6) # RIGHT
          $passa_bitmap.fill_rect(x+32-$passa_field_size,y,
          $passa_field_size,32,$passa_field_color)
        end
        if !playerPassable?(xval,yval,8) # UP
          $passa_bitmap.fill_rect(x,y,32,$passa_field_size,
          $passa_field_color)
        end
        tileHasTerrainTag?(xval,yval) if SHOW_TERRAIN_TAGS
      end
    end
    pbDrawTextPositions($passa_terrain_bitmap.bitmap,$passa_terrain)
    
    # Guardar última posición del jugador para detectar movimiento
    $passa_last_player_x = player_x
    $passa_last_player_y = player_y
  end

  # Method which returns the passability of a field.
  def playerPassable?(x, y, d, self_event = nil)
    bit = (1 << ((d / 2) - 1)) & 0x0f
    [2, 1, 0].each do |i|
      tile_id = $game_map.data[x, y, i]
      next if tile_id == 0 || tile_id == nil || !$passa_terrain_tags
      terrain = GameData::TerrainTag.try_get($passa_terrain_tags[tile_id])
      passage = $passa_passages[tile_id]
      if terrain
        # Ignore bridge tiles if not on a bridge
        next if terrain.bridge && $PokemonGlobal.bridge == 0
        # Make water tiles passable if player is surfing
        return true if $PokemonGlobal.surfing && terrain.can_surf && !terrain.waterfall
        # Prevent cycling in really tall grass/on ice
        return false if $PokemonGlobal.bicycle && (terrain.must_walk || terrain.must_walk_or_run)
        # Depend on passability of bridge tile if on bridge
        if terrain.bridge && $PokemonGlobal.bridge > 0
          return (passage & bit == 0 && passage & 0x0f != 0x0f)
        end
      end
      next if terrain&.ignore_passability
      # Regular passability checks
      return false if passage & bit != 0 || passage & 0x0f == 0x0f
      return true if !$passa_priorities[tile_id] || $passa_priorities[tile_id] == 0
    end
    return true
  end

  def valid?(x, y); return (x >= 0 and x < $game_map.width and y >= 0 and y < $game_map.height); end
  
  # Method which returns whether a square is an event or not.
  def isEvent?(x,y)
    return false if !SHOW_EVENTS
    for event in $game_map.events.values
      if ( (x==event.x) && (y==event.y) )
        return true
      end
    end
    return false
  end
  
  # Method which checks whether a tile has a terrain tag.
  def tileHasTerrainTag?(x,y)
    terrain_tag = $game_map.terrain_tag(x,y)
    if terrain_tag.id_number>0
      # p "#{$game_map.terrain_tag(x,y)} #{x} #{y}"
      $passa_terrain.push([_INTL("{1}",terrain_tag.id_number),
      32+32*x,22+32*y,2,$passa_terrain_color,$passa_terrain_color2])
    end
  end
end

# Updating Game_Map so the passable method won't have undefined methods.
class Game_Map
  alias old_setup_kodsn setup
  def setup(map_id)
    old_setup_kodsn(map_id)
    passability_setup(map_id)
  end
  # def data; return @map.data; end

  def passability_setup(map_id)
    $map_id=map_id
    $passa_passages=@passages
    $passa_priorities=@priorities
    $passa_terrain_tags=@terrain_tags
    $passa_data = @data
  end

end

# Disposes the Passability stuff.
def dispose_Debug_Passability
  $passa_sprite.dispose
  $passa_bitmap.clear
  $passa_terrain_bitmap.dispose
  $passa_sprite=nil
  $passa_bitmap=nil
  $passa_terrain_bitmap=nil
  $passa_last_player_x=nil
  $passa_last_player_y=nil
end

# Método optimizado que detecta si el jugador se movió lo suficiente para requerir actualización
def passability_needs_update?
  $passa_event_array="" if !$passa_event_array
  $passa_event_array2=""
  
  # Verificar si el jugador se movió fuera del área renderizada
  if $passa_last_player_x && $passa_last_player_y
    player_moved_distance = [($game_player.x - $passa_last_player_x).abs, 
                            ($game_player.y - $passa_last_player_y).abs].max
    if player_moved_distance > 3 # Re-renderizar cuando se mueva 3+ casillas
      return true
    end
  end
  
  # Solo verificar eventos en el área visible alrededor del jugador
  player_x = $game_player.x
  player_y = $game_player.y
  min_x = [0, player_x - RENDER_DISTANCE].max
  max_x = [$game_map.width - 1, player_x + RENDER_DISTANCE].min
  min_y = [0, player_y - RENDER_DISTANCE].max  
  max_y = [$game_map.height - 1, player_y + RENDER_DISTANCE].min
  
  for event in $game_map.events.values
    # Solo verificar eventos dentro del área visible
    if event.x >= min_x && event.x <= max_x && event.y >= min_y && event.y <= max_y
      $passa_event_array2.insert($passa_event_array2.length,"#{event.x}") if SHOW_EVENTS
      $passa_event_array2.insert($passa_event_array2.length,"#{event.y}") if SHOW_EVENTS
    end
  end
  
  if $PokemonMap
    $passa_event_array2.insert($passa_event_array2.length,"#{$PokemonGlobal.bridge}") if SHOW_PASSIBILITY
    $passa_event_array2.insert($passa_event_array2.length,"#{$PokemonMap.movedEvents}") if SHOW_PASSIBILITY
    $passa_event_array2.insert($passa_event_array2.length,"#{$PokemonMap.erasedEvents}") if SHOW_PASSIBILITY
  end
  $passa_event_array2.insert($passa_event_array2.length,"#{$PokemonGlobal.bicycle}") if SHOW_PASSIBILITY
  $passa_event_array2.insert($passa_event_array2.length,"#{$PokemonGlobal.surfing}") if SHOW_PASSIBILITY
  $passa_event_array2.insert($passa_event_array2.length,"#{$PokemonGlobal.ice_sliding}") if SHOW_PASSIBILITY
  $passa_event_array2.insert($passa_event_array2.length,"#{$game_map}") if SHOW_PASSIBILITY
  
  if $passa_event_array == $passa_event_array2
    return false
  else
    $passa_event_array=$passa_event_array2
    return true
  end
end

# Fixes Bug with jumping.
class Game_Player < Game_Character
  alias old_update_shiney :update
  def update
    if $passa_sprite
      Debug_Passability.new if passability_needs_update?
      $passa_sprite.x= -($game_map.display_x/4)-16
      $passa_sprite.y= -($game_map.display_y/4)-16
      if $passa_terrain_bitmap
        $passa_terrain_bitmap.x=$passa_sprite.x
        $passa_terrain_bitmap.y=$passa_sprite.y
      end
    end
    old_update_shiney
  end
end

# Updating Scene_Map
class Scene_Map
  def main
    createSpritesets
    Graphics.transition
    loop do
      if $passa_sprite
        Debug_Passability.new if passability_needs_update?
        $passa_sprite.x= -($game_map.display_x/4)-16
        $passa_sprite.y= -($game_map.display_y/4)-16
        if $passa_terrain_bitmap
          $passa_terrain_bitmap.x=$passa_sprite.x
          $passa_terrain_bitmap.y=$passa_sprite.y
        end
      end
      Graphics.update
      Input.update
      update
      if Input.trigger?(Input::AUX2) && $DEBUG
        if $passa_sprite
          dispose_Debug_Passability
        else
          Debug_Passability.new
        end
      end
      if $scene != self
        break
      end
    end
    Graphics.freeze
    disposeSpritesets
    if defined?($game_temp.to_title) && $game_temp.to_title
      Graphics.transition
      Graphics.freeze
    end
  end
end