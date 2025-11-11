#===============================================================================
# Fixes to allow for Spinda's spots to appear on an animated sprite.
#===============================================================================

#-------------------------------------------------------------------------------
# Rewritten form handler.
#-------------------------------------------------------------------------------
MultipleForms.register(:SPINDA, {
  "alterBitmap" => proc { |pkmn, bitmap, scale, index|
    pbSpindaSpots(pkmn, bitmap, scale, index)
  }
})

#-------------------------------------------------------------------------------
# Rewritten code related to drawing Spinda's spots.
#-------------------------------------------------------------------------------
def pbSpindaSpots(pkmn, bitmap, scale, index)
  return if !pkmn.spot_hash
  spot_data = pkmn.spot_hash[index]
  colors = (pkmn.shiny?) ? [-75, -10, -150] : [0, -115, -75]
  spot_data.length.times { |i| drawSpot(bitmap, scale, *spot_data[i], *colors) }
end

def drawSpot(bitmap, scale, spotpattern, x, y, ox, oy, red, green, blue)
  height = spotpattern.length
  width  = spotpattern[0].length
  height.times do |yy|
    spot = spotpattern[yy]
    width.times do |xx|
      next if spot[xx] != 1
      xOrg = (x * scale + xx) * 2 + ox
      yOrg = (y * scale + yy) * 2 + oy
      color = bitmap.get_pixel(xOrg, yOrg)
      r = color.red + red
      g = color.green + green
      b = color.blue + blue
      color.red   = [[r, 0].max, 255].min
      color.green = [[g, 0].max, 255].min
      color.blue  = [[b, 0].max, 255].min
      bitmap.set_pixel(xOrg, yOrg, color)
      bitmap.set_pixel(xOrg + 1, yOrg, color)
      bitmap.set_pixel(xOrg, yOrg + 1, color)
      bitmap.set_pixel(xOrg + 1, yOrg + 1, color)
    end
  end
end

#-------------------------------------------------------------------------------
# Custom utilities for tracking Spinda's head movements while animating.
#-------------------------------------------------------------------------------
class Game_Temp
  attr_accessor :spinda_spots
end

# Determines how much Spinda's spots should move by tracking its mouth while it animates.
# Spinda's mouth uses a unique color that is the same for both normal and shiny sprites,
# so it's the ideal portion of its body to track to determine spot placements.
def findSpotMovement(bitmap, scale)
  pixel_x = 1
  base_y = (bitmap.height / 2).floor
  until bitmap.get_pixel(pixel_x, base_y).alpha > 0
    pixel_x += 1
    next if pixel_x < bitmap.width
    pixel_x = 0
    break
  end
  pixel_y = 0
  rect = [29, 19, 35, 29]              # Rectangle containing Spinda's mouth
  find_color = Color.new(230, 99, 115) # Spinda's mouth color
  4.times { |i| rect[i] *= scale }
  (rect[0]..rect[2]).each do |i|
    (rect[1]..rect[3]).each do |j|
      next if bitmap.get_pixel(j, i) != find_color
      pixel_y = i
      break
    end
  end
  return [pixel_x, pixel_y]
end

#-------------------------------------------------------------------------------
# Rewritten for applying Spinda's spot patterns during DBK animations.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation
  def dxSetSpotPatterns(pkmn, sprite)
    return if !MultipleForms.hasFunction?(pkmn, "alterBitmap")
    sprite.iconBitmap.compile_strip(pkmn)
    sprite.iconBitmap.hue_change(pkmn.super_shiny_hue)
  end
end

#-------------------------------------------------------------------------------
# Spinda spot patterns now saved to the individual Pokemon for faster loading.
#-------------------------------------------------------------------------------
class Pokemon
  attr_accessor :spot_hash
  
  # Changing the personalID value also clears any previously saved spot patterns.
  def personalID=(value)
    @personalID = value
    @spot_hash = nil
  end
  
  def set_spot_pattern(bitmap, scale, index)
    return if @spot_hash && @spot_hash.has_key?(index)
    return if !MultipleForms.getFunction(@species, "alterBitmap")
    spot1 = [
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 1, 1, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0]
    ]
    spot2 = [
      [0, 0, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 1, 1, 0],
      [0, 0, 1, 1, 1, 0, 0]
    ]
    id = @personalID
    a = ((id)       & 5) + 1
    b = ((id >> 4)  & 5) + 7
    c = ((id >> 8)  & 5) + 9
    d = ((id >> 12) & 5) + 6
    e = ((id >> 16) & 5) + 15
    f = ((id >> 20) & 5) + 9
    if index > 0
      old_spot = $game_temp.spinda_spots
      $game_temp.spinda_spots = findSpotMovement(bitmap, scale)
      new_spot = $game_temp.spinda_spots
      offsetX = (old_spot[0] - new_spot[0]).abs
      offsetY = (old_spot[1] - new_spot[1]).abs
      ox = @spot_hash[index - 1][0][3]
      oy = @spot_hash[index - 1][0][4]
      (old_spot[0] < new_spot[0]) ? ox += offsetX : ox -= offsetX
      (old_spot[1] < new_spot[1]) ? oy += offsetY : oy -= offsetY
    else
      $game_temp.spinda_spots = findSpotMovement(bitmap, scale)
      ox, oy = 0, 0
    end
    @spot_hash = {} if !@spot_hash
    @spot_hash[index] = [
      [spot1, a, b, ox, oy],
      [spot2, c, d, ox, oy],
      [spot1, e, f, ox, oy]
    ]
  end
end