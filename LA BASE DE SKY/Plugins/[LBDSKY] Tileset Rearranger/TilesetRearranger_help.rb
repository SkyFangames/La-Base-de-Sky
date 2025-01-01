#===============================================================================
#
#===============================================================================
class TilesetRearranger
  # Sets the text in the top window (informational)
  def draw_title_text
    text = _INTL("Organizar Tileset")
    text += "\r\n"
    case @mode
    when :swap       then text += _INTL("Modo: Intercambiar tiles")
    when :cut_insert then text += _INTL("Modo: Cortar/insertar tiles")
    when :move_row   then text += _INTL("Modo: Mover filas")
    when :add_row    then text += _INTL("Modo: Insertar nueva fila")
    when :erase      then text += _INTL("Modo: Eliminar tiles no usados")
    when :delete_row then text += _INTL("Modo: Eliminar fila")
    end
    if @height > 0
      text += "\r\n"
      if @height > MAX_TILESET_ROWS
        text += _INTL("Altura: {1}/{2} filas [!]", @height, MAX_TILESET_ROWS)
      else
        text += _INTL("Altura: {1}/{2} filas", @height, MAX_TILESET_ROWS)
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
            text.push(_INTL("C: Intercambiar tiles")) if can_swap_areas?
            text.push(_INTL("X: Cancelar intercmabio"))
          elsif @mode == :cut_insert
            text.push(_INTL("C: Insertar tiles aquí")) if can_insert_cut_tiles?
            text.push(_INTL("X: Cancelar inserción de tiles"))
          end
        else
          text.push(_INTL("FLECHAS: Seleccionar múltiples tiles"))
          text.push(_INTL("SOLTAR C: Terminar selección"))
        end
      else
        text.push(_INTL("C: Seleccionar tile"))
        text.push(_INTL("MANTENER C: Seleccionar múltiples tiles"))
      end
    when :move_row
      if @selected_y >= 0
        if @selected_height > 0
          text.push(_INTL("C: Mover fila aquí"))
          text.push(_INTL("X: Cancelar mover fila"))
        else
          text.push(_INTL("FLECHAS: Select multiple rows"))
          text.push(_INTL("SOLTAR C: Terminar selección"))
        end
      else
        text.push(_INTL("C: Seleccionar fila"))
        text.push(_INTL("MANTENER C: Seleccionar múltiples filas"))
      end
    when :add_row
      text.push(_INTL("C: Insertar fila de tiles"))
    when :erase
      if @selected_x >= 0
        text.push(_INTL("FLECHAS: Seleccionar múltiples tiles"))
        text.push(_INTL("SOLTAR C: Eliminar tiles"))
      else
        text.push(_INTL("C: Eliminar tile"))
        text.push(_INTL("MANTENER C: Eliminar múltiples tiles"))
      end
    when :delete_row
      text.push(_INTL("C: Eliminar fila de tiles")) if @height > 1
    end
    text.push(_INTL("A/S: Saltar arriba/abajo del tileset"))
    if [:swap, :cut_insert].include?(@mode) && @selected_width > 0
      case @mode
      when :swap       then text.push(_INTL("Z: Cambiar modo a cortar/insertar"))
      when :cut_insert then text.push(_INTL("Z: Cambiar modo a intercambiar"))
      end
    elsif [:add_row, :delete_row].include?(@mode) || (@selected_x < 0 && @selected_y < 0)
      text.push(_INTL("Z: Cambiar modo"))
      text.push(_INTL("D: Abrir menú"))
    end
    if @history.length > 0
      if @future_history.length > 0
        text.push(_INTL("Q: Deshacer ({1}) - W: Rehacer ({2})", @history.length, @future_history.length))
      else
        text.push(_INTL("Q: Deshacer ({1})", @history.length))
      end
    elsif @future_history.length > 0
      text.push(_INTL("W: Rehacer ({1})", @future_history.length))
    end
    text_string = (text.length == 0) ? "" : text.join("\r\n")
    @sprites["help_text"].height = (text.length + 1) * 32
    @sprites["help_text"].text = text_string
    pbBottomRight(@sprites["help_text"])
  end
end
