#===============================================================================
# CREDITOS
# Swdfm
#===============================================================================
class Swdfm_Exp_Screen
  def set_comparative_z(first_tile, second_tile, amount = 1)
    set_to = @sprites[second_tile].z
	set_to += amount
	@sprites[first_tile].z = set_to
  end
  
  def main
    loop do
      Graphics.update
      Input.update
	  pbUpdateSpriteHash(@sprites)
      update_bars if @elapsed < @total_frames
	  if Input.trigger?(Input::USE)
	    do_action_USE
	  elsif Input.trigger?(Input::BACK)
	    @do_break = true
	    do_action_BACK
	  end
	  break if @do_break
    end
  end
  
  def run
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites)
	main
	pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
  end
  
  def dispose_if_there(name)
    @sprites[name].dispose if @sprites[name]
  end
end
