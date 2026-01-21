#===============================================================================
# Tone
#===============================================================================
class Tone
  def self.new_from_rgbg(param)
    case param.length
    when 12   # 32-bit hex with +/- for each part
      return Tone.new(
        param[0, 3].to_i(16),
        param[3, 3].to_i(16),
        param[6, 3].to_i(16),
        param[9, 3].to_i(16)
      )
    end
    return Tone.new(0, 0, 0, 0)
  end

  # @return [String] this tone in the format "+RR+GG+BB+GG"
  def to_rgb32
    this_red = ((self.red >= 0) ? "+" : "-") + sprintf("%02X", self.red.to_i.abs)
    this_green = ((self.green >= 0) ? "+" : "-") + sprintf("%02X", self.green.to_i.abs)
    this_blue = ((self.blue >= 0) ? "+" : "-") + sprintf("%02X", self.blue.to_i.abs)
    this_gray = ((self.gray >= 0) ? "+" : "-") + sprintf("%02X", self.gray.to_i.abs)
    return this_red + this_green + this_blue + this_gray
  end
end

#===============================================================================
# I know this isn't Ruby, but everything in this file will be moved elsewhere
# eventually. It's just here to help me remember that this was added because of
# the new Animation Editor.
#===============================================================================
class AnimFrame
  COLOR      = 51   # Only used to convert old animations to new format
  TONE       = 52   # Only used to convert old animations to new format
end
