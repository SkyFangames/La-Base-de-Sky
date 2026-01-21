class Bitmap
  def outline_rect(x, y, width, height, color, thickness = 1)
    fill_rect(x, y, width, thickness, color)
    fill_rect(x, y, thickness, height, color)
    fill_rect(x, y + height - thickness, width, thickness, color)
    fill_rect(x + width - thickness, y, thickness, height, color)
  end

  # Draws a series of concentric outline_rects around the defined area. From
  # inside to outside, the color of each ring alternates.
  def border_rect(x, y, width, height, thickness, *colors)
    thickness.times do |i|
      col = colors[i % colors.length]
      outline_rect(x - i - 1, y - i - 1, width + (i * 2) + 2, height + (i * 2) + 2, col)
    end
  end

  def fill_diamond(x, y, radius, color)
    ((radius * 2) + 1).times do |i|
      height = (i <= radius) ? (i * 2) + 1 : (((radius * 2) - i) * 2) + 1
      fill_rect(x - radius + i, y - ((height - 1) / 2), 1, height, color)
    end
  end

  def draw_interpolation_line(x, y, width, height, gradient, type, color)
    start_x = x
    end_x = x + width - 1
    start_y = (gradient) ? y + height - 1 : y
    end_y = (gradient) ? y : y + height - 1
    case type
    when :linear
      # NOTE: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
      dx = end_x - start_x
      dy = -((end_y - start_y).abs)
      error = dx + dy
      draw_x = start_x
      draw_y = start_y
      loop do
        fill_rect(draw_x, draw_y, 1, 1, color)
        break if draw_x == end_x && draw_y == end_y
        e2 = 2 * error
        if e2 >= dy
          break if draw_x == end_x
          error += dy
          draw_x += 1
        end
        if e2 <= dx
          break if draw_y == end_y
          error += dx
          draw_y += (gradient) ? -1 : 1
        end
      end
    when :ease_in, :ease_out, :ease_both   # Quadratic
      # TODO: Is there a nicer way to draw these lines?
      start_y = y + height - 1
      end_y = y
      points = []
      (width + 1).times do |frame|
        x = frame / width.to_f
        case type
        when :ease_in
          points[frame] = (end_y - start_y) * x * x
        when :ease_out
          points[frame] = (end_y - start_y) * (1 - ((1 - x) * (1 - x)))
        when :ease_both
          if x < 0.5
            points[frame] = (end_y - start_y) * x * x * 2
          else
            points[frame] = (end_y - start_y) * (1 - (((-2 * x) + 2) * ((-2 * x) + 2) / 2))
          end
        end
        points[frame] = points[frame].round
      end
      width.times do |frame|
        line_y = points[frame]
        if frame == 0
          line_height = 1
        else
          line_height = [(points[frame] - points[frame - 1]).abs, 1].max
        end
        if !gradient   # Going down
          line_y = -(height - 1) - line_y - line_height + 1
        end
        fill_rect(start_x + frame, start_y + line_y, 1, line_height, color)
      end
    else
      raise _INTL("Unknown interpolation type {1}.", type)
    end
  end
end

#===============================================================================
#
#===============================================================================
class AnimationEditor
  # Generates a list of all files in the given folder and its subfolders which
  # have a file extension that matches one in exts. Removes any files from the
  # list whose filename is the same as one in blacklist (case insensitive).
  def get_all_files_in_folder(folder, exts, blacklist = [])
    ret = []
    Dir.all(folder).each do |f|
      next if !exts.include?(File.extname(f))
      file = f.sub(folder + "/", "")
      ret.push([file.sub(File.extname(file), ""), file])
    end
    ret.delete_if { |f| blacklist.any? { |add| add.upcase == f[0].upcase } }
    ret.sort! { |a, b| a[0].downcase <=> b[0].downcase }
    return ret
  end
end
