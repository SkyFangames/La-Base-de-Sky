#===============================================================================
# CREDITOS
# Swdfm
#===============================================================================
class Swdfm_Exp_Screen
  def do_action_USE
    if @elapsed >= @total_frames
	  do_action_BACK
	else
      @elapsed = @total_frames
	  update_bars
	end
  end
  
  def do_action_BACK
    if @elapsed < @total_frames
	  @do_break = false
      @elapsed = @total_frames
	  update_bars
	  return
	end
	@do_break = true
  end
end
