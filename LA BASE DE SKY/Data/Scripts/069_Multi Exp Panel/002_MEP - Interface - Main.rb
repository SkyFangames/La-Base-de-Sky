#===============================================================================
# CREDITOS
# Swdfm
#===============================================================================
class Swdfm_Exp_Screen
  def initialize(values)
    @v21 = Essentials::VERSION.include?("21")
	@elapsed       = 0
	@values        = values
	speed          = 200 - BAR_SPEED
	speed          = speed.clamp(1, 200)
	@total_frames  = (@values.max / speed).floor
	@total_frames  = @total_frames.clamp(40 * FASTEST_TIME, 40 * SLOWEST_TIME)
    @sprites    = {}
    @width      = Graphics.width
    @height     = Graphics.height
    @viewport   = Viewport.new(0, 0, @width, @height)
	@viewport.z = 120_000
	@do_break   = false
	before_run
	run
  end
  
  def before_run
    @s_width  = @width - BORDER_WIDTH * 2
    @s_height = @height - BORDER_HEIGHT * 2
	@s_x      = (@width - @s_width) / 2
	@s_y      = (@height - @s_height) / 2
	compile_bars
	draw
  end
  
  def draw
    draw_backing
	draw_party
  end
  
  def draw_backing
	@e_col     = PANEL_EDGE_COLOUR
	@f_col     = PANEL_FILL_COLOUR
	bmp = Swdfm_Bitmap.colour([@s_width, @s_height], @e_col, 0, 0, @s_width, @s_height)
	e   = PANEL_EDGE_SIZE
	bmp = Swdfm_Bitmap.colour(bmp, @f_col, e, e, @s_width - 2 * e, @s_height - 2 * e)
	@sprites["bg"] = IconSprite.new(@s_x, @s_y, @viewport)
	@sprites["bg"].setBitmap_Swdfm(pbPackageBitmap(bmp))
	@sprites["bg"].x = @s_x
	@sprites["bg"].y = @s_y
  end
  
  def compile_bars
	@levels = []
    for i in $player.party
	  @levels.push(i.level)
	end
  end
  
  def update_bars
    for i in 0...$player.party.size
      next if $player.party[i].level == Settings::MAXIMUM_LEVEL
      next if !@values[i]
      mock_exp  = $player.party[i].exp + (@values[i] * @elapsed / @total_frames).floor
      lvl, perc = $player.party[i].exp_fraction_for_panel(mock_exp)
      if lvl > @levels[i]
        @levels[i] = lvl
        redraw_level(i)
        @sprites["bar_1_#{i}"].bitmap.clear
      end
      if @elapsed == (ANNOUCE_TIME * 40) || @elapsed == @total_frames
        dispose_if_there("exp_#{i}")
      end
      bmp = @sprites["bar_1_#{i}"].bitmap
      bmp = Swdfm_Bitmap.colour(bmp, EXP_EXP_COLOUR, 0, 0, (bmp.width * perc / 100).floor, bmp.height)
      @sprites["bar_1_#{i}"].bitmap = bmp
    end
    @elapsed += 1
    f = @v21 ? (1 / 40) : 1
    pbWait(f)
  end
  
  def draw_party
	b_w = (@s_width / 3).floor - EXP_WIDTH_GAP * 2
	b_h = EXP_BAR_HEIGHT
	c_o = CO_ORDINATES[$player.party.size - 1]
	e   = EXP_BAR_EDGE_SIZE
	@places = []
    for i in 0...$player.party.length
	  x_c, y_c = c_o[i]
	  x        = x_c * @s_width
	  y        = y_c * @s_height
	  x       -= (b_w / 2)
	  y       -= (b_h / 2)
	  x       += @s_x
	  y       += @s_y
	  y       += MOVE_DOWN_PIXELS
	  bmp = Swdfm_Bitmap.colour([b_w, b_h], EXP_EDGE_COLOUR, 0, 0, b_w, b_h)
	  bmp = Swdfm_Bitmap.colour(bmp, EXP_FILL_COLOUR, e, e, b_w - 2 * e, b_h - 2 * e)
	  # Pokemon
	  s = PokemonIconSprite.new($player.party[i], @viewport)
	  @sprites["poke_#{i}"] = s
	  set_comparative_z("poke_#{i}", "bg", 5)
	  # Bar
	  @sprites["bar_#{i}"] = IconSprite.new(0, 0, @viewport)
	  @sprites["bar_#{i}"].setBitmap_Swdfm(pbPackageBitmap(bmp))
	  @sprites["bar_#{i}"].x = x
	  @sprites["bar_#{i}"].y = y
	  set_comparative_z("bar_#{i}", "bg", 10)
	  # Bar Filler
	  @sprites["bar_1_#{i}"] = BitmapSprite.new(b_w - 2 * e, b_h - 2 * e, @viewport)
	  @sprites["bar_1_#{i}"].x = x + e
	  @sprites["bar_1_#{i}"].y = y + e
	  set_comparative_z("bar_1_#{i}", "bg", 15)
	  # Poke Again
	  @sprites["poke_#{i}"].x = x + POKE_X
	  @sprites["poke_#{i}"].y = y - @sprites["poke_#{i}"].height + POKE_Y
	  # Levels
	  @sprites["level_#{i}"] = BitmapSprite.new(96, 64, @viewport)
	  @sprites["level_#{i}"].x = ( x + b_w - e - LEVEL_X ) - 6
	  @sprites["level_#{i}"].y = y - LEVEL_Y
	  set_comparative_z("level_#{i}", "bg", 20)
	  hash = {
	    :X       => 48,
	    :Align   => 2,
	    :Outline => true
	  }
	  bmp = Swdfm_Bitmap.text("Nv. #{$player.party[i].level.to_s}", hash, @sprites["level_#{i}"].bitmap)
	  next if @values[i] == 0 || !@values[i]
	  # Exp
	  @sprites["exp_#{i}"] = BitmapSprite.new(b_w, 64, @viewport)
	  @sprites["exp_#{i}"].x = x + EXP_X
	  @sprites["exp_#{i}"].y = y + EXP_Y
	  set_comparative_z("exp_#{i}", "bg", 25)
	  hash = {
	    :X       => b_w / 2,
	    :Align   => 2
	  }
	  bmp = Swdfm_Bitmap.text("+" + @values[i].to_s_formatted, hash, @sprites["exp_#{i}"].bitmap)
	end
  end
  
  def redraw_level(i)
    @sprites["level_#{i}"].bitmap.clear
    pbSEPlay("Pkmn exp full")
	hash = {
	  :X       => 48,
	  :Align   => 2,
	  :Outline => true
	}
	bmp = Swdfm_Bitmap.text("Nv. #{@levels[i].to_s}", hash, @sprites["level_#{i}"].bitmap)
  end
end
