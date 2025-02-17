#===============================================================================
#  Extensions for `Numeric` data types
#===============================================================================
class ::Numeric

  #-----------------------------------------------------------------------------
  #  Delta offset for frame rates
  #-----------------------------------------------------------------------------
  def delta(type = :add, round = true)
    d = Graphics.frame_rate/40.0
    a = round ? (self*d).to_i : (self*d)
    s = round ? (self/d).floor : (self/d)
    return type == :add ? a : s
  end
  
  def delta_add(round = true)
    return self.delta(:add, round)
  end
  
  def delta_sub(round = true)
    return self.delta(:sub, round)
  end
  #-----------------------------------------------------------------------------
  #  Superior way to round stuff
  #-----------------------------------------------------------------------------
	alias quick_mafs round
	def round(n = 0)
		# gets the current float to an actually roundable integer
		t = self*(10.0**n)
		# returns the rounded value
		return t.quick_mafs/(10.0**n)
	end

  #-----------------------------------------------------------------------------
  #  interpolate number based on current frame rates
  #-----------------------------------------------------------------------------
  def lerp(inverse: false)
    # time per frame, for a target of 60 FPS
    target = 60.0 / Graphics.average_frame_rate
    target = 1.0 / target if inverse

    self * target
  end
  #-----------------------------------------------------------------------------
  def blank?
    zero?
  end

  def present?
    !blank?
  end
end
