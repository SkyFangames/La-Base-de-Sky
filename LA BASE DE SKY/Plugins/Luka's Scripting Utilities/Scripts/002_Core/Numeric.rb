#===============================================================================
#  Extensions for `Numeric` data types
#===============================================================================
class ::Numeric
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
