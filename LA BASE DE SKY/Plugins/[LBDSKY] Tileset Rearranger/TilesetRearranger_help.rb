#===============================================================================
#
#===============================================================================
class TilesetRearranger
  # Sets the text in the top window (informational)
  def draw_title_text
    text = _INTL("Tileset Rearranger")
    text += "\r\n"
    case @mode
    when :swap       then text += _INTL("Mode: Swap tiles")
    when :cut_insert then text += _INTL("Mode: Cut/insert tiles")
    when :move_row   then text += _INTL("Mode: Move rows")
    when :add_row    then text += _INTL("Mode: Insert new row")
    when :erase      then text += _INTL("Mode: Erase unused tiles")
    when :delete_row then text += _INTL("Mode: Delete row")
    end
    if @height > 0
      text += "\r\n"
      if @height > MAX_TILESET_ROWS
        text += _INTL("Height: {1}/{2} rows [!]", @height, MAX_TILESET_ROWS)
      else
        text += _INTL("Height: {1}/{2} rows", @height, MAX_TILESET_ROWS)
      end
    end
    @sprites["title"].text = text
  end

  # Sets the text in the bottom window (controls)
  def draw_help_text
    text = []
    case @mode
    when :swap, :cut_insert
      if @selected_x >= 0
        if @selected_width > 0
          if @mode == :swap
            text.push(_INTL("C: Swap tiles")) if can_swap_areas?
            text.push(_INTL("X: Cancel tile swap"))
          elsif @mode == :cut_insert
            text.push(_INTL("C: Insert tiles here")) if can_insert_cut_tiles?
            text.push(_INTL("X: Cancel tile(s) insert"))
          end
        else
          text.push(_INTL("ARROWS: Select multiple tiles"))
          text.push(_INTL("RELEASE C: Finish selection"))
        end
      else
        text.push(_INTL("C: Select tile"))
        text.push(_INTL("HOLD C: Select multiple tiles"))
      end
    when :move_row
      if @selected_y >= 0
        if @selected_height > 0
          text.push(_INTL("C: Move rows here"))
          text.push(_INTL("X: Cancel row moving"))
        else
          text.push(_INTL("ARROWS: Select multiple rows"))
          text.push(_INTL("RELEASE C: Finish selection"))
        end
      else
        text.push(_INTL("C: Select row"))
        text.push(_INTL("HOLD C: Select multiple rows"))
      end
    when :add_row
      text.push(_INTL("C: Insert row of tiles"))
    when :erase
      if @selected_x >= 0
        text.push(_INTL("ARROWS: Select multiple tiles"))
        text.push(_INTL("RELEASE C: Erase tiles"))
      else
        text.push(_INTL("C: Erase tile"))
        text.push(_INTL("HOLD C: Erase multiple tiles"))
      end
    when :delete_row
      text.push(_INTL("C: Delete row of tiles")) if @height > 1
    end
    text.push(_INTL("A/S: Jump up/down tileset"))
    if [:swap, :cut_insert].include?(@mode) && @selected_width > 0
      case @mode
      when :swap       then text.push(_INTL("Z: Change mode to cut/insert"))
      when :cut_insert then text.push(_INTL("Z: Change mode to swap"))
      end
    elsif [:add_row, :delete_row].include?(@mode) || (@selected_x < 0 && @selected_y < 0)
      text.push(_INTL("Z: Change mode"))
      text.push(_INTL("D: Open menu"))
    end
    if @history.length > 0
      if @future_history.length > 0
        text.push(_INTL("Q: Undo ({1}) - W: Redo ({2})", @history.length, @future_history.length))
      else
        text.push(_INTL("Q: Undo ({1})", @history.length))
      end
    elsif @future_history.length > 0
      text.push(_INTL("W: Redo ({1})", @future_history.length))
    end
    text_string = (text.length == 0) ? "" : text.join("\r\n")
    @sprites["help_text"].height = (text.length + 1) * 32
    @sprites["help_text"].text = text_string
    pbBottomRight(@sprites["help_text"])
  end
end
