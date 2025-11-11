class MenuCustomScene
  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99_999
    @finished = false
    @select = 0
    @procToExecute = {}
    @procToExecutesubButtons = {}

    #======================== Config rejilla (puedes ajustar) ===================
    @max_rows   = 3     # Nº de iconos por columna (filas)
    @col_width  = 96    # Separación horizontal entre columnas
    @row_height = 80    # Separación vertical entre filas
    @base_x     = 314   # Posición inicial X de la rejilla
    @base_y     = 91    # Posición inicial Y de la rejilla
    #============================================================================

    #=====================================================================
    # Sprites
    #=====================================================================
    if BACKGROUND_IMAGE
      @sprites["background"] = Sprite.new(@viewport)
      @sprites["background"].bitmap = Bitmap.new(BACKGROUND_IMAGE)
    end

    @sprites["background2"] = Sprite.new(@viewport)
    @sprites["background2"].bitmap = Bitmap.new("#{PATH}/menubg")
    pbSetSystemFont(@sprites["background2"].bitmap)

    # Iconos principales (colocación en rejilla vertical→nueva columna a la dcha)
    idx = 0
    MenuHandlers.each_available(:custom_menu) do |option, hash, name|
      next if !hash["condition"].call
      @procToExecute[idx] = hash["effect"]
      @sprites["opt#{idx}"] = Sprite.new(@viewport)
      @sprites["opt#{idx}"].bitmap = Bitmap.new("#{PATH}/#{hash["iconName"]}")
      col = idx / @max_rows
      row = idx % @max_rows
      @sprites["opt#{idx}"].x = @base_x + col * @col_width
      @sprites["opt#{idx}"].y = @base_y + row * @row_height
      idx += 1
    end
    @options_count = idx   # total de iconos dibujados

    @sprites["subButtons"] = Sprite.new(@viewport)
    @sprites["subButtons"].bitmap = Bitmap.new(300, 60)
    @sprites["subButtons"].y = Graphics.height - 60

    idx = 0
    space = SUB_BUTTONS_SPACE
    MenuHandlers.each_available(:custom_menu_subButtons) do |option, hash, name|
      next if !hash["condition"].call
      @procToExecutesubButtons[hash["button"]] = hash["effect"]
      bitmapToSet = Bitmap.new("#{PATH}/#{hash["iconName"]}")
      @sprites["subButtons"].bitmap.blt(
        space,
        0,
        bitmapToSet,
        Rect.new(0, 0, 56, 56)
      )
      space += bitmapToSet.width + SUB_BUTTONS_SPACE
      idx += 1
    end

    @sprites["menu_selection"] = Sprite.new(@viewport)
    @sprites["menu_selection"].bitmap = Bitmap.new("#{PATH}/menu_selection")
    # Posición inicial del selector
    @sprites["menu_selection"].x = @base_x
    @sprites["menu_selection"].y = @base_y

    @selectPosTimeStart = System.uptime
    self.pbDrawText
    self.pbDrawPokemonTeam
  end

  # =================================================================== #
  # Drawers
  # =================================================================== #
  def pbDrawPokemonTeam
    return if !SHOW_POKEMON_TEAM
    Settings::MAX_PARTY_SIZE.times do |idx|
      break if @sprites["pkmn_#{idx}"].nil?
      @sprites["pkmn_#{idx}"].dispose
      @sprites["pkmn_#{idx}"] = nil
    end

    $player.party.each_with_index do |pkmn, idx|
      @sprites["pkmn_#{idx}"] = PokemonIconSprite.new(pkmn, @viewport)
      @sprites["pkmn_#{idx}"].x = (idx * 64)
      if idx <= 2
        @sprites["pkmn_#{idx}"].mirror = true
      else
        @sprites["pkmn_#{idx}"].x += 128
      end
    end
  end

  def pbDrawText
    # Map name Section
    map_name = $game_map.name || "???"
    map_name_array = map_name.split(/(Ciudad|Pueblo)/).reject(&:empty?).map(&:strip)

    map_name_array.each_with_index do |part, idx|
      posY = 10 + (idx * 25)
      posY += 15 if map_name_array.length == 1
      pbDrawOutlineText(
        @sprites["background2"].bitmap, 0, posY, Graphics.width, 100,
        part, Color.white, Color.black, 1
      )
    end

    # Badges Section
    pbDrawOutlineText(
      @sprites["background2"].bitmap, 300, 355, 200, 100,
      "Medallas: #{$player.badge_count}", Color.white, Color.black, 0
    )
    # Money Section
    pbDrawOutlineText(
      @sprites["background2"].bitmap, 300, 355, 200, 100,
      "$#{$player.money}", Color.white, Color.black, 2
    )
  end

  # =========================== Utilidades rejilla ============================ #
  def grid_cols
    return (@options_count + @max_rows - 1) / @max_rows
  end

  def rows_in_col(col)
    return 0 if col < 0
    remaining = @options_count - col * @max_rows
    return 0 if remaining <= 0
    return [@max_rows, remaining].min
  end

  def pos_for_index(index)
    col = index / @max_rows
    row = index % @max_rows
    x = @base_x + col * @col_width
    y = @base_y + row * @row_height
    return x, y
  end
  # ========================================================================== #

  # =================================================================== #
  # Update selector (interpolado)
  # =================================================================== #
  def pbUpdateSelected
    return if @selectPosTimeStart.nil?
    posX, posY = pos_for_index(@select)

    oldX = @sprites["menu_selection"].x
    oldY = @sprites["menu_selection"].y

    @sprites["menu_selection"].x =
      lerp(oldX, posX, TRANSITION_DURATION, @selectPosTimeStart, System.uptime)
    @sprites["menu_selection"].y =
      lerp(oldY, posY, TRANSITION_DURATION, @selectPosTimeStart, System.uptime)

    if @sprites["menu_selection"].x == posX && @sprites["menu_selection"].y == posY
      @selectPosTimeStart = nil
    end
  end

  def pbExecuteMainMethod
    @procToExecute[@select].call(self) if @procToExecute[@select]
  end

  # =================================================================== #
  # Update (input y navegación por rejilla)
  # =================================================================== #
  def pbUpdate
    loop do
      Graphics.update
      Input.update

      pbUpdateSpriteHash(@sprites)
      oldSelect = @select

      # Ejecutar opción
      self.pbExecuteMainMethod if Input.trigger?(Input::USE)

      # Navegación por rejilla (sin “wrap”; se ignora si no hay celda)
      if @options_count > 0
        col = @select / @max_rows
        row = @select % @max_rows
        cols = grid_cols

        if Input.trigger?(Input::LEFT)
          new_col = col - 1
          if new_col >= 0
            max_row_new_col = rows_in_col(new_col) - 1
            new_row = [row, max_row_new_col].min
            @select = new_col * @max_rows + new_row
          end
        elsif Input.trigger?(Input::RIGHT)
          new_col = col + 1
          if new_col < cols
            max_row_new_col = rows_in_col(new_col) - 1
            next if max_row_new_col < 0
            new_row = [row, max_row_new_col].min
            @select = new_col * @max_rows + new_row
          end
        elsif Input.trigger?(Input::UP)
          new_row = row - 1
          if new_row >= 0
            @select = col * @max_rows + new_row
          end
        elsif Input.trigger?(Input::DOWN)
          max_row_this_col = rows_in_col(col) - 1
          new_row = row + 1
          if new_row <= max_row_this_col
            @select = col * @max_rows + new_row
          end
        end
      end

      # Sub-botones
      @procToExecutesubButtons.each do |key, value|
        if Input.triggerex?(key)
          value.call(self)
          next
        end
      end

      # Interpolación del selector
      self.pbUpdateSelected
      @selectPosTimeStart = System.uptime if oldSelect != @select

      @finished = true if Input.trigger?(Input::BACK)
      break if @finished
    end
  end

  # =================================================================== #
  # Menu Transitions
  # =================================================================== #
  def pbRefresh
    self.pbDrawPokemonTeam
  end

  def pbHideMenu; end
  def pbShowMenu; end

  def pbEndScene
    @finished = true
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class MenuCustom
  def initialize(scene)
    @scene = scene
  end

  def pbStartPokemonMenu
    @scene.pbStartScene
    @scene.pbUpdate
    @scene.pbEndScene
  end
end
