#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Tone` class
#===============================================================================
class ::Tone
  # Creates a lookup table for tones to blend shading with regular colors.
  class LookupTable
    # Luminance coefficients used in shader (same as YUV standard)
    LUMA_R = 0.299
    LUMA_G = 0.587
    LUMA_B = 0.114

    # @param tone [Tone]
    def initialize(tone)
      @tone      = tone
      @red_lut   = build_channel_lut(tone.red)
      @green_lut = build_channel_lut(tone.green)
      @blue_lut  = build_channel_lut(tone.blue)
      @gray_norm = (tone.gray / 255.0).clamp(0.0, 1.0)
    end

    # Transform RGB using separate channel lookups + grayscale mixing
    # @param r [Integer] Red (0-255)
    # @param g [Integer] Green (0-255)
    # @param b [Integer] Blue (0-255)
    # @return [Array<Integer>] Transformed [r, g, b]
    def transform(r, g, b)
      if @gray_norm > 0.0
        # Need to calculate grayscale mixing
        r_norm = r / 255.0
        g_norm = g / 255.0
        b_norm = b / 255.0

        luma = r_norm * LUMA_R + g_norm * LUMA_G + b_norm * LUMA_B

        mixed_r = mix(r_norm, luma, @gray_norm)
        mixed_g = mix(g_norm, luma, @gray_norm)
        mixed_b = mix(b_norm, luma, @gray_norm)

        # Apply tone and convert back
        final_r = (mixed_r + @tone.red / 255.0).clamp(0.0, 1.0)
        final_g = (mixed_g + @tone.green / 255.0).clamp(0.0, 1.0)
        final_b = (mixed_b + @tone.blue / 255.0).clamp(0.0, 1.0)

        [(final_r * 255).round, (final_g * 255).round, (final_b * 255).round]
      else
        # No grayscale, use simple channel lookup
        [@red_lut[r], @green_lut[g], @blue_lut[b]]
      end
    end

    private

    # Build lookup table for a single channel
    # @param tone_adjustment [Integer]
    def build_channel_lut(tone_adjustment)
      lut = Array.new(256)
      tone_norm = tone_adjustment / 255.0

      (0..255).each do |i|
        original = i / 255.0
        adjusted = (original + tone_norm).clamp(0.0, 1.0)
        lut[i] = (adjusted * 255).round
      end

      lut
    end

    # Helper method that mimics GLSL mix function
    # @param x [Float] first value
    # @param y [Float] second value
    # @param a [Float] mix factor (0.0 = all x, 1.0 = all y)
    # @return [Float] interpolated value
    def mix(x, y, a)
      x * (1.0 - a) + y * a
    end
  end

  # Allows tone components to be animated easily
  include ::LUTS::Concerns::Animatable

  # @return [Tone::LookupTable]
  def lookup_table
    @lookup_table ||= LookupTable.new(self)
  end

  def update; end

  # @return [Numeric] average value of all colors
  def all
    (red + green + blue) / 3
  end

  # Applies value to all channels
  # @param val [Numeric]
  def all=(val)
    self.red   = val
    self.green = val
    self.blue  = val
  end
end
