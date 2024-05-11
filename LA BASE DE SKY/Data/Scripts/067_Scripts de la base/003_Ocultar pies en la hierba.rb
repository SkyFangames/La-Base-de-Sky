#===============================================================================
# ■ Always on bush by DPertierra
# https://github.com/dpertierra
# https://twitter.com/dpertierra
#===============================================================================
class Game_Character
  def calculate_bush_depth
    if @tile_id > 0 || @always_on_top || jumping?
      @bush_depth = 0
      return
    end
    this_map = (self.map.valid?(@x, @y)) ? [self.map, @x, @y] : $map_factory&.getNewMap(@x, @y, self.map.map_id)
    if this_map && ( this_map[0].deepBush?(this_map[1], this_map[2]) || this_map[0].bush?(this_map[1], this_map[2]))
      xbehind = @x + (@direction == 4 ? 1 : @direction == 6 ? -1 : 0)
      ybehind = @y + (@direction == 8 ? 1 : @direction == 2 ? -1 : 0)
      if moving?
        behind_map = (self.map.valid?(xbehind, ybehind)) ? [self.map, xbehind, ybehind] : $map_factory&.getNewMap(xbehind, ybehind, self.map.map_id)
        @bush_depth = 12 if (behind_map[0].bush?(behind_map[1], behind_map[2]) || behind_map[0].deepBush?(behind_map[1], behind_map[2]))
      else
        @bush_depth = 12
      end
    else
      @bush_depth = 0
    end
  end
end

