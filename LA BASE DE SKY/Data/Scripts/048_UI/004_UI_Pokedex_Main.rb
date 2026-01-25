#===============================================================================
#
#===============================================================================
class Window_Pokedex < Window_DrawableCommand
  # Constantes para el layout y offsets dentro de la ventana del Pokédex
  # Offset horizontal aplicado al rectángulo de dibujo de cada entrada
  RECT_X_OFFSET       = 16
  # Ajuste de anchura para el rectángulo de dibujo (puede ser negativo)
  RECT_WIDTH_OFFSET   = -16
  # Offset X/Y para el icono de pokeball que indica poseído
  OWN_ICON_X_OFFSET   = -6
  OWN_ICON_Y_OFFSET   = 10
  # Offset X/Y para el icono que indica visto
  SEEN_ICON_X_OFFSET  = -6
  SEEN_ICON_Y_OFFSET  = 10
  # Offset X/Y para dibujar el número del Pokédex
  DEX_NUMBER_X_OFFSET = 36
  DEX_NUMBER_Y_OFFSET = 6
  # Offset X/Y para dibujar el nombre del Pokémon en la lista
  DEX_NAME_X_OFFSET   = 84
  DEX_NAME_Y_OFFSET   = 6
  def initialize(x, y, width, height, viewport)
    @commands = []
    super(x, y, width, height, viewport)
    @selarrow     = AnimatedBitmap.new("Graphics/UI/Pokedex/cursor_list")
    @pokeballOwn  = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_own")
    @pokeballSeen = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_seen")
    self.baseColor   = Color.new(88, 88, 80)
    self.shadowColor = Color.new(168, 184, 184)
    self.windowskin  = nil
  end

  def commands=(value)
    @commands = value
    refresh
  end

  def dispose
    @pokeballOwn.dispose
    @pokeballSeen.dispose
    super
  end

  def species
    return (@commands.length == 0) ? 0 : @commands[self.index][:species]
  end

  def itemCount
    return @commands.length
  end

  def drawItem(index, _count, rect)
    return if index >= self.top_row + self.page_item_max
    rect = Rect.new(rect.x + RECT_X_OFFSET, rect.y, rect.width + RECT_WIDTH_OFFSET, rect.height)
    species     = @commands[index][:species]
    indexNumber = @commands[index][:number]
    indexNumber -= 1 if @commands[index][:shift]
    if $player.seen?(species)
      if $player.owned?(species)
        pbCopyBitmap(self.contents, @pokeballOwn.bitmap, rect.x + OWN_ICON_X_OFFSET, rect.y + OWN_ICON_Y_OFFSET)
      else
        pbCopyBitmap(self.contents, @pokeballSeen.bitmap, rect.x + SEEN_ICON_X_OFFSET, rect.y + SEEN_ICON_Y_OFFSET)
      end
      num_text = sprintf("%03d", indexNumber)
      name_text = @commands[index][:name]
    else
      num_text = sprintf("%03d", indexNumber)
      name_text = "----------"
    end
    pbDrawShadowText(self.contents, rect.x + DEX_NUMBER_X_OFFSET, rect.y + DEX_NUMBER_Y_OFFSET, rect.width, rect.height,
                     num_text, self.baseColor, self.shadowColor)
    pbDrawShadowText(self.contents, rect.x + DEX_NAME_X_OFFSET, rect.y + DEX_NAME_Y_OFFSET, rect.width, rect.height,
                     name_text, self.baseColor, self.shadowColor)
  end

  def refresh
    @item_max = itemCount
    dwidth  = self.width - self.borderX
    dheight = self.height - self.borderY
    self.contents = pbDoEnsureBitmap(self.contents, dwidth, dheight)
    self.contents.clear
    @item_max.times do |i|
      next if i < self.top_item || i > self.top_item + self.page_item_max
      drawItem(i, @item_max, itemRect(i))
    end
    drawCursor(self.index, itemRect(self.index))
  end

  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end

#===============================================================================
#
#===============================================================================
class PokedexSearchSelectionSprite < Sprite

  MODE_COORDS = {
    0 => {:xstart=>46, :ystart=>128, :xgap=>236, :ygap=>64, :cols=>2},
    1 => {:xstart=>78, :ystart=>114, :xgap=>52,  :ygap=>52, :cols=>7},
    2 => {:xstart=>8,  :ystart=>104, :xgap=>124, :ygap=>44, :cols=>4},
    3 => {:xstart=>44, :ystart=>110, :xgap=>8,   :ygap=>112, :cols=>nil},
    4 => {:xstart=>44, :ystart=>110, :xgap=>8,   :ygap=>112, :cols=>nil},
    5 => {:xstart=>62, :ystart=>114, :xgap=>132, :ygap=>52, :cols=>3},
    6 => {:xstart=>82, :ystart=>116, :xgap=>70,  :ygap=>70, :cols=>5}
  }

  # Constantes para el cursor
  # MAIN_SRC_RECTS: coordenadas para el cuadro de búsqueda principal
  #   key: índice de la opción principal (0..6 y :default para botones)
  #   value: [src_y, src_height]
  #     - src_y: coordenada Y del rectángulo fuente dentro del bitmap del cursor
  #     - src_height: altura del rectángulo fuente en píxeles
  # PARAM_SRC_RECTS: coordenadas para el cuadro de búsqueda de parámetros
  #   key: modo de parámetro (0..6)
  #   value: [src_y, src_height]
  #     - src_y: coordenada Y del rectángulo fuente dentro del bitmap del cursor para este modo
  #     - src_height: altura del rectángulo fuente en píxeles
  # PARAM_HW_SRC_Y_MIN / PARAM_HW_SRC_Y_MAX: posiciones Y para altura/peso
  #   cuando se muestra el selector mínimo o máximo respectivamente; PARAM_HW_SRC_HEIGHT es la altura
  # OK_POS / CANCEL_POS: coordenadas en pantalla para los botones OK y Cancelar (formato [x, y])
  # MAIN_POS: posiciones y desplazamientos usados para la colocación del cursor en la pantalla principal
  MAIN_SRC_RECTS = {
    0 => [0, 44],
    1 => [44, 44],
    2 => [88, 44],
    3 => [132, 44],
    4 => [132, 44],
    5 => [44, 44],
    6 => [176, 68],
    :default => [244, 40]
  }

  PARAM_SRC_RECTS = {
    0 => [0, 44],
    1 => [284, 44],
    2 => [44, 44],
    5 => [44, 44],
    6 => [176, 68]
  }

  PARAM_HW_SRC_Y_MIN = 328
  PARAM_HW_SRC_Y_MAX = 424
  PARAM_HW_SRC_HEIGHT = 96

  # x, y
  OK_POS = [4, 334]
  # x, y
  CANCEL_POS = [356, 334]

  MAIN_POS = {
    # x, y
    :order => [252, 52],
    # 
    :name_x => 114,
    :name_y_base => 110,
    :name_y_gap => 52,
    :color => [382, 110],
    :shape => [420, 214],
    :reset_base_x => 4,
    :reset_gap => 176,
    :reset_y => 334
  }

  attr_reader :index
  attr_accessor :cmds
  attr_accessor :minmax

  def initialize(viewport = nil)
    super(viewport)
    @selbitmap = AnimatedBitmap.new("Graphics/UI/Pokedex/cursor_search")
    self.bitmap = @selbitmap.bitmap
    self.mode = -1
    @index = 0
    refresh
  end

  def dispose
    @selbitmap.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def mode=(value)
    @mode   = value
    coords  = MODE_COORDS[@mode]
    if coords
      @xstart = coords[:xstart]
      @ystart = coords[:ystart]
      @xgap   = coords[:xgap]
      @ygap   = coords[:ygap]
      @cols   = coords[:cols] if coords[:cols]
    end
  end

  def refresh
    # Size and position cursor
    if @mode == -1   # Main search screen
      y, h = MAIN_SRC_RECTS.fetch(@index, MAIN_SRC_RECTS[:default])
      self.src_rect.y = y
      self.src_rect.height = h
      case @index
      when 0         # Order
        self.x, self.y = *MAIN_POS[:order]
      when 1, 2, 3, 4   # Name, type, height, weight
        self.x = MAIN_POS[:name_x]
        self.y = MAIN_POS[:name_y_base] + ((@index - 1) * MAIN_POS[:name_y_gap])
      when 5         # Color
        self.x, self.y = *MAIN_POS[:color]
      when 6         # Shape
        self.x, self.y = *MAIN_POS[:shape]
      when 7, 8, 9     # Reset, start, cancel
        self.x = MAIN_POS[:reset_base_x] + ((@index - 7) * MAIN_POS[:reset_gap])
        self.y = MAIN_POS[:reset_y]
      end
    else   # Parameter screen
      case @index
      when -2, -3   # OK, Cancel
        self.src_rect.y, self.src_rect.height = MAIN_SRC_RECTS[:default]
      else
        if [3, 4].include?(@mode)
          self.src_rect.y = (@minmax == 1) ? PARAM_HW_SRC_Y_MIN : PARAM_HW_SRC_Y_MAX
          self.src_rect.height = PARAM_HW_SRC_HEIGHT
        else
          rect = PARAM_SRC_RECTS[@mode] || MAIN_SRC_RECTS[:default]
          self.src_rect.y, self.src_rect.height = rect
        end
      end
      case @index
      when -1   # Blank option
        if @mode == 3 || @mode == 4   # Height/weight range
          self.x = @xstart + ((@cmds + 1) * @xgap * (@minmax % 2))
          self.y = @ystart + (@ygap * ((@minmax + 1) % 2))
        else
          self.x = @xstart + ((@cols - 1) * @xgap)
          self.y = @ystart + ((@cmds / @cols).floor * @ygap)
        end
      when -2   # OK
        self.x, self.y = *OK_POS
      when -3   # Cancel
        self.x, self.y = *CANCEL_POS
      else
        case @mode
        when 0, 1, 2, 5, 6   # Order, name, type, color, shape
          if @index >= @cmds
            self.x = @xstart + ((@cols - 1) * @xgap)
            self.y = @ystart + ((@cmds / @cols).floor * @ygap)
          else
            self.x = @xstart + ((@index % @cols) * @xgap)
            self.y = @ystart + ((@index / @cols).floor * @ygap)
          end
        when 3, 4         # Height, weight
          if @index >= @cmds
            self.x = @xstart + ((@cmds + 1) * @xgap * ((@minmax + 1) % 2))
          else
            self.x = @xstart + ((@index + 1) * @xgap)
          end
          self.y = @ystart + (@ygap * ((@minmax + 1) % 2))
        end
      end
    end
  end
end

#===============================================================================
# Pokédex main screen
#===============================================================================
class PokemonPokedex_Scene
  MODENUMERICAL = 0
  MODEATOZ      = 1   # Modo: ordenar alfabéticamente A-Z
  MODETALLEST   = 2   # Modo: ordenar por más alto a más bajo
  MODESMALLEST  = 3   # Modo: ordenar por más bajo a más alto (altura)
  MODEHEAVIEST  = 4   # Modo: ordenar por más pesado a más liviano
  MODELIGHTEST  = 5   # Modo: ordenar por más liviano a más pesado

  # Constantes de posición/size para la ventana del Pokédex
  POKEDEX_WINDOW_X = 206        # X posición de la ventana del listado
  POKEDEX_WINDOW_Y = 30         # Y posición de la ventana del listado
  POKEDEX_WINDOW_WIDTH = 276    # Anchura de la ventana del listado
  POKEDEX_WINDOW_HEIGHT = 364   # Altura de la ventana del listado
  # Posición del sprite del Pokémon mostrado a la izquierda
  POKEMON_ICON_X = 112
  POKEMON_ICON_Y = 196
  # Offsets para el título y textos informativos en la parte superior/derecha
  DEX_NAME_X_OFFSET = 40
  DEX_NAME_Y = 10
  SPECIES_NAME_X = 112
  SPECIES_NAME_Y = 58
  RESULTS_TEXT_X = 112
  RESULTS_TEXT_Y = 314
  RESULTS_NUMBER_X = 112
  RESULTS_NUMBER_Y = 346
  SEEN_TEXT_X = 26
  SEEN_TEXT_Y = 314
  SEEN_NUMBER_X = 136
  SEEN_NUMBER_Y = 314
  CAPTURED_TEXT_X = 26
  CAPTURED_TEXT_Y = 346
  CAPTURED_NUMBER_X = 152
  CAPTURED_NUMBER_Y = 346

  # Constantes para el control deslizante (slider) del listado
  SLIDER_X = 468                           # X del slider
  SLIDER_ARROW_UP_Y = 48                   # Y para la flecha de arriba
  SLIDER_ARROW_DOWN_Y = 346                # Y para la flecha de abajo
  # Formato de rectángulos fuente (arrays): [src_x, src_y, width, height]
  #  - src_x, src_y: coordenadas dentro del bitmap fuente
  #  - width, height: dimensiones del rectángulo fuente
  SLIDER_SRC_ARROW_UP = [0, 0, 40, 30]     # Rect fuente para la flecha arriba: [src_x, src_y, w, h]
  SLIDER_SRC_ARROW_DOWN = [0, 30, 40, 30]  # Rect fuente para la flecha abajo: [src_x, src_y, w, h]
  SLIDER_BOX_SRC_TOP = [40, 0, 40, 8]      # Rect fuente para la parte superior de la caja: [src_x, src_y, w, h]
  # SLIDER_BOX_SRC_MID está en formato [src_x, src_y, width]
  #  - la altura se pasa dinámicamente cuando se dibuja cada segmento medio
  SLIDER_BOX_SRC_MID = [40, 8, 40]         # Rect base para partes medias: [src_x, src_y, width]
  SLIDER_BOX_SRC_BOTTOM = [40, 24, 40, 16] # Rect fuente para la parte inferior de la caja: [src_x, src_y, w, h]
  SLIDER_HEIGHT = 268                      # Altura total del área del slider
  SLIDER_Y = 78                            # Y inicial para la caja deslizante
  SLIDER_BOX_PADDING_TOP = 8               # Padding superior interno de la caja
  SLIDER_BOX_SEGMENT = 16                  # Tamaño de cada segmento medio de la caja
  SLIDER_MIN_BOXHEIGHT = 40                # Altura mínima de la caja

  # Constantes de posición para la ventana de búsqueda del Pokédex
  DEXSEARCH_TITLE_X   = Settings::SCREEN_WIDTH / 2
  DEXSEARCH_TITLE_Y   = 10
  DEXSEARCH_ORDER_X   = 136
  DEXSEARCH_ORDER_Y   = 64
  DEXSEARCH_NAME_X    = 58
  DEXSEARCH_NAME_Y    = 122
  DEXSEARCH_TYPE_X    = 58
  DEXSEARCH_TYPE_Y    = 174
  DEXSEARCH_HEIGHT_X  = 58
  DEXSEARCH_HEIGHT_Y  = 226
  DEXSEARCH_WEIGHT_X  = 58
  DEXSEARCH_WEIGHT_Y  = 278
  DEXSEARCH_COLOR_X   = 326
  DEXSEARCH_COLOR_Y   = 122
  DEXSEARCH_SHAPE_X   = 454
  DEXSEARCH_SHAPE_Y   = 174
  DEXSEARCH_RESET_X   = 80
  DEXSEARCH_RESET_Y   = 346
  DEXSEARCH_START_X   = Settings::SCREEN_WIDTH / 2
  DEXSEARCH_START_Y   = 346
  DEXSEARCH_CANCEL_X  = Settings::SCREEN_WIDTH - 80
  DEXSEARCH_CANCEL_Y  = 346

  # Constantes para las posiciones de los parámetros en pbRefreshDexSearch
  DEXSEARCH_PARAM_ORDER_X = 344
  DEXSEARCH_PARAM_ORDER_Y = 66
  DEXSEARCH_PARAM_NAME_X  = 176
  DEXSEARCH_PARAM_NAME_Y  = 124
  DEXSEARCH_PARAM_COLOR_X = 444
  DEXSEARCH_PARAM_COLOR_Y = 124
  DEXSEARCH_TYPE1_BLT_X   = 128
  DEXSEARCH_TYPE1_BLT_Y   = 168
  DEXSEARCH_TYPE1_EMPTY_X = 176
  DEXSEARCH_TYPE1_EMPTY_Y = 176
  DEXSEARCH_TYPE2_BLT_X   = 256
  DEXSEARCH_TYPE2_BLT_Y   = 168
  DEXSEARCH_TYPE2_EMPTY_X = 304
  DEXSEARCH_TYPE2_EMPTY_Y = 176

  # Constantes para posiciones de altura/peso, iconos HW y forma en pbRefreshDexSearch
  DEXSEARCH_HT1_X        = 166
  DEXSEARCH_HT2_X        = 294
  DEXSEARCH_HT_Y         = 228
  DEXSEARCH_WT1_X        = 166
  DEXSEARCH_WT2_X        = 294
  DEXSEARCH_WT_Y         = 280
  DEXSEARCH_HWBLT_X      = 344
  DEXSEARCH_HWBLT1_Y     = 214
  DEXSEARCH_HWBLT2_Y     = 266
  DEXSEARCH_SHAPE_BLT_X  = 424
  DEXSEARCH_SHAPE_BLT_Y  = 218

  # Constantes para posiciones usadas en pbRefreshDexSearchParam (height/weight top bar)
  DEXSEARCH_PARAM_HW_TOP1_X = 286
  DEXSEARCH_PARAM_HW_TOP2_X = 414
  DEXSEARCH_PARAM_HW_TOP_Y  = 66
  DEXSEARCH_PARAM_HW_BLTX    = 462
  DEXSEARCH_PARAM_HW_BLT_Y   = 52

  # Constantes para posiciones del cuadro de parámetros (pbRefreshDexSearchParam)
  DEXSEARCH_PARAM_TITLE_X    = Settings::SCREEN_WIDTH / 2
  DEXSEARCH_PARAM_TITLE_Y    = 10
  DEXSEARCH_PARAM_OK_X       = 80
  DEXSEARCH_PARAM_OK_Y       = 346
  DEXSEARCH_PARAM_CANCEL_X   = Settings::SCREEN_WIDTH - 80
  DEXSEARCH_PARAM_CANCEL_Y   = 346

  # Constantes para la posición del texto título en pbRefreshDexSearchParam
  DEXSEARCH_PARAM_TITLE_TEXT_X     = 102
  DEXSEARCH_PARAM_TITLE_TEXT_Y_SM  = 64
  DEXSEARCH_PARAM_TITLE_TEXT_Y_LG  = 70

  # Top-bar type/spacing constants for pbRefreshDexSearchParam
  DEXSEARCH_PARAM_TYPE_TEXT_X_BASE = 298
  DEXSEARCH_PARAM_TYPE_BLT_X_BASE  = 250
  DEXSEARCH_PARAM_TYPE_SPACING     = 128
  DEXSEARCH_PARAM_TYPE_TEXT_Y      = 66
  DEXSEARCH_PARAM_TYPE_BLT_Y       = 58

  # Additional constants to remove remaining magic numbers in
  # pbRefreshDexSearchParam
  DEXSEARCH_PARAM_SLIDER_LEFT_X    = 16
  DEXSEARCH_PARAM_SLIDER_RIGHT_X   = 464
  DEXSEARCH_PARAM_SLIDER_TOP1_Y    = 120
  DEXSEARCH_PARAM_SLIDER_TOP2_Y    = 264
  DEXSEARCH_PARAM_SLIDER_SRC_LEFT  = [0, 192, 32, 44]
  DEXSEARCH_PARAM_SLIDER_SRC_RIGHT = [32, 192, 32, 44]

  DEXSEARCH_PARAM_HWRECT_W         = 120
  DEXSEARCH_PARAM_HWRECT_H         = 96
  DEXSEARCH_PARAM_HWRECT_ALT_Y     = 96
  DEXSEARCH_PARAM_HW_Y_OFFSET1     = 180
  DEXSEARCH_PARAM_HW_Y_OFFSET2     = 36

  DEXSEARCH_PARAM_TEXT_X_OFFSET    = 14
  DEXSEARCH_PARAM_TEXT_Y_OFFSET    = 14
  DEXSEARCH_PARAM_ICON_X_OFFSET    = 4
  DEXSEARCH_PARAM_ICON_Y_OFFSET    = 6
  DEXSEARCH_PARAM_SHAPE_W          = 60
  DEXSEARCH_PARAM_SHAPE_H          = 60

  # Layouts for pbRefreshDexSearchParam by mode. Keys are modes (0..6).
  # For modes 3 and 4 (height/weight) the values for :xgap and :cols are
  # computed dynamically because they depend on `cmds.length`.
  DEXSEARCH_PARAM_LAYOUTS = {
        :default => { xstart: 46,  ystart: 128, xgap: 236, ygap: 64,  halfwidth: 92, cols: 2, selbuttony: 0,   selbuttonheight: 44,
            top_text_x_base: 362, top_blt_x_base: 332, top_spacing: 128, top_text_y: 66, top_blt_y: 50 },
        0 => { xstart: 46,  ystart: 128, xgap: 236, ygap: 64,  halfwidth: 92, cols: 2, selbuttony: 0,   selbuttonheight: 44,
          top_text_x_base: 362, top_blt_x_base: 332, top_spacing: 128, top_text_y: 66, top_blt_y: 50 },
        1 => { xstart: 78,  ystart: 114, xgap: 52,  ygap: 52,  halfwidth: 22, cols: 7, selbuttony: 156, selbuttonheight: 44,
          top_text_x_base: 362, top_blt_x_base: 332, top_spacing: 128, top_text_y: 66, top_blt_y: 50 },
        2 => { xstart: 8,   ystart: 104, xgap: 124, ygap: 44,  halfwidth: 62, cols: 4, selbuttony: 44,  selbuttonheight: 44,
          top_text_x_base: 298, top_blt_x_base: 250, top_spacing: 128, top_text_y: 66, top_blt_y: 58 },
        3 => { xstart: 44,  ystart: 110, xgap: nil, ygap: 112, halfwidth: 60, cols: nil, selbuttony: nil, selbuttonheight: nil,
          top_text_x_base: 362, top_blt_x_base: 332, top_spacing: 128, top_text_y: 66, top_blt_y: 50 },
        4 => { xstart: 44,  ystart: 110, xgap: nil, ygap: 112, halfwidth: 60, cols: nil, selbuttony: nil, selbuttonheight: nil,
          top_text_x_base: 362, top_blt_x_base: 332, top_spacing: 128, top_text_y: 66, top_blt_y: 50 },
        5 => { xstart: 62,  ystart: 114, xgap: 132, ygap: 52,  halfwidth: 62, cols: 3, selbuttony: 44,  selbuttonheight: 44,
          top_text_x_base: 362, top_blt_x_base: 332, top_spacing: 0,   top_text_y: 66, top_blt_y: 50 },
        6 => { xstart: 82,  ystart: 116, xgap: 70,  ygap: 70,  halfwidth: 0,  cols: 5, selbuttony: 88,  selbuttonheight: 68,
          top_text_x_base: 362, top_blt_x_base: 332, top_spacing: 0,   top_text_y: 66, top_blt_y: 50 }
  }


  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @sliderbitmap       = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_slider")
    @typebitmap         = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_types"))
    @shapebitmap        = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_shapes")
    @hwbitmap           = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_hw"))
    @selbitmap          = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_searchsel")
    @searchsliderbitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_searchslider"))
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    addBackgroundPlane(@sprites, "background", "Pokedex/bg_list", @viewport)
    # Suggestion for changing the background depending on region. You can
    # comment out the line above and uncomment the following lines:
#    if pbGetPokedexRegion == -1   # Using national Pokédex
#      addBackgroundPlane(@sprites, "background", "Pokedex/bg_national", @viewport)
#    elsif pbGetPokedexRegion == 0   # Using first regional Pokédex
#      addBackgroundPlane(@sprites, "background", "Pokedex/bg_regional", @viewport)
#    end
    addBackgroundPlane(@sprites, "searchbg", "Pokedex/bg_search", @viewport)
    @sprites["searchbg"].visible = false
    @sprites["pokedex"] = Window_Pokedex.new(POKEDEX_WINDOW_X, POKEDEX_WINDOW_Y, POKEDEX_WINDOW_WIDTH, POKEDEX_WINDOW_HEIGHT, @viewport)
    @sprites["icon"] = PokemonSprite.new(@viewport)
    @sprites["icon"].setOffset(PictureOrigin::CENTER)
    @sprites["icon"].x = POKEMON_ICON_X
    @sprites["icon"].y = POKEMON_ICON_Y
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["searchcursor"] = PokedexSearchSelectionSprite.new(@viewport)
    @sprites["searchcursor"].visible = false
    @searchResults = false
    @searchParams  = [$PokemonGlobal.pokedexMode, -1, -1, -1, -1, -1, -1, -1, -1, -1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @sliderbitmap.dispose
    @typebitmap.dispose
    @shapebitmap.dispose
    @hwbitmap.dispose
    @selbitmap.dispose
    @searchsliderbitmap.dispose
    @viewport.dispose
  end

  # Gets the region used for displaying Pokédex entries. Species will be listed
  # according to the given region's numbering and the returned region can have
  # any value defined in the town map data file. It is currently set to the
  # return value of pbGetCurrentRegion, and thus will change according to the
  # current map's MapPosition metadata setting.
  def pbGetPokedexRegion
    if Settings::USE_CURRENT_REGION_DEX
      region = pbGetCurrentRegion
      region = -1 if region >= $player.pokedex.dexes_count - 1
      return region
    else
      return $PokemonGlobal.pokedexDex   # National Dex -1, regional Dexes 0, 1, etc.
    end
  end

  # Determines which index of the array $PokemonGlobal.pokedexIndex to save the
  # "last viewed species" in. All regional dexes come first in order, then the
  # National Dex at the end.
  def pbGetSavePositionIndex
    index = pbGetPokedexRegion
    if index == -1   # National Dex (comes after regional Dex indices)
      index = $player.pokedex.dexes_count - 1
    end
    return index
  end

  def pbCanAddForModeList?(mode, species)
    case mode
    when MODEATOZ
      return $player.seen?(species)
    when MODEHEAVIEST, MODELIGHTEST, MODETALLEST, MODESMALLEST
      return $player.owned?(species)
    end
    return true   # For MODENUMERICAL
  end

  def pbGetDexList
    region = pbGetPokedexRegion
    regionalSpecies = pbAllRegionalSpecies(region)
    if !regionalSpecies || regionalSpecies.length == 0
      # If no Regional Dex defined for the given region, use the National Pokédex
      regionalSpecies = []
      GameData::Species.each_species { |s| regionalSpecies.push(s.id) }
    end
    shift = Settings::DEXES_WITH_OFFSETS.include?(region)
    ret = []
    regionalSpecies.each_with_index do |species, i|
      next if !species
      next if !pbCanAddForModeList?($PokemonGlobal.pokedexMode, species)
      _gender, form, _shiny = $player.pokedex.last_form_seen(species)
      species_data = GameData::Species.get_species_form(species, form)
      ret.push({
        :species => species,
        :name    => species_data.name,
        :height  => species_data.height,
        :weight  => species_data.weight,
        :number  => i + 1,
        :shift   => shift,
        :types   => species_data.types,
        :color   => species_data.color,
        :shape   => species_data.shape
      })
    end
    return ret
  end

  def pbRefreshDexList(index = 0)
    dexlist = pbGetDexList
    case $PokemonGlobal.pokedexMode
    when MODENUMERICAL
      # Hide the Dex number 0 species if unseen
      dexlist[0] = nil if dexlist[0][:shift] && !$player.seen?(dexlist[0][:species])
      # Remove unseen species from the end of the list
      i = dexlist.length - 1
      loop do
        break if i < 0 || !dexlist[i] || $player.seen?(dexlist[i][:species])
        dexlist[i] = nil
        i -= 1
      end
      dexlist.compact!
      # Sort species in ascending order by Regional Dex number
      dexlist.sort! { |a, b| a[:number] <=> b[:number] }
    when MODEATOZ
      dexlist.sort! { |a, b| (a[:name] == b[:name]) ? a[:number] <=> b[:number] : a[:name] <=> b[:name] }
    when MODEHEAVIEST
      dexlist.sort! { |a, b| (a[:weight] == b[:weight]) ? a[:number] <=> b[:number] : b[:weight] <=> a[:weight] }
    when MODELIGHTEST
      dexlist.sort! { |a, b| (a[:weight] == b[:weight]) ? a[:number] <=> b[:number] : a[:weight] <=> b[:weight] }
    when MODETALLEST
      dexlist.sort! { |a, b| (a[:height] == b[:height]) ? a[:number] <=> b[:number] : b[:height] <=> a[:height] }
    when MODESMALLEST
      dexlist.sort! { |a, b| (a[:height] == b[:height]) ? a[:number] <=> b[:number] : a[:height] <=> b[:height] }
    end
    @dexlist = dexlist
    @sprites["pokedex"].commands = @dexlist
    @sprites["pokedex"].index    = index
    @sprites["pokedex"].refresh
    if @searchResults
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_listsearch")
    else
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_list")
    end
    pbRefresh
  end

  # DP - Agrega funcion para buscar por nombre presionando la D
  def open_search_box
    PokedexSearcher.new(@dexlist, self)
  end

  def searchByName(text, char="")
    current_index = @sprites["pokedex"].index
    for i in current_index...@dexlist.length
      item = @dexlist[i]
      next if !$player.seen?(item[:species])
      next if item[:shift] && !$player.seen?(item[:species])
      return pbRefreshDexList(item[:number] - 1) if item[:name].downcase.include?(text.downcase)
    end
    if current_index > 0
      for i in 0...current_index
        item = @dexlist[i]
        next if !$player.seen?(item[:species])
        next if item[:shift] && !$player.seen?(item[:species])
        return pbRefreshDexList(item[:number] - 1) if item[:name].downcase.include?(text.downcase)
      end
    end
    return false
  end

  def pbRefresh
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(88, 88, 80)
    shadow = Color.new(168, 184, 184)
    iconspecies = @sprites["pokedex"].species 
    iconspecies = nil if !$player.seen?(iconspecies) && !Settings::SHOW_SILHOUETTES_IN_DEX
    # Write various bits of text
    dexname = _INTL("Pokédex")
    if $player.pokedex.dexes_count > 1
      thisdex = Settings.pokedex_names[pbGetSavePositionIndex]
      if thisdex
        dexname = (thisdex.is_a?(Array)) ? thisdex[0] : thisdex
      end
    end
    textpos = [
      [dexname, (Graphics.width / 2)+DEX_NAME_X_OFFSET, DEX_NAME_Y, :center, Color.new(248, 248, 248), Color.black]
    ]
    textpos.push([GameData::Species.get(iconspecies).name, SPECIES_NAME_X, SPECIES_NAME_Y, :center, base, shadow]) if (Settings::SHOW_SILHOUETTES_IN_DEX && $player.seen?(iconspecies)) || (!Settings::SHOW_SILHOUETTES_IN_DEX && iconspecies)
    if @searchResults
      textpos.push([_INTL("Resultados:"), RESULTS_TEXT_X, RESULTS_TEXT_Y, :center, base, shadow])
      textpos.push([@dexlist.length.to_s, RESULTS_NUMBER_X, RESULTS_NUMBER_Y, :center, base, shadow])
    else
      textpos.push([_INTL("Avistados:"), SEEN_TEXT_X, SEEN_TEXT_Y, :left, base, shadow])
      textpos.push([$player.pokedex.seen_count(pbGetPokedexRegion).to_s, SEEN_NUMBER_X, SEEN_NUMBER_Y, :left, base, shadow])
      textpos.push([_INTL("Capturados:"), CAPTURED_TEXT_X, CAPTURED_TEXT_Y, :left, base, shadow])
      textpos.push([$player.pokedex.owned_count(pbGetPokedexRegion).to_s, CAPTURED_NUMBER_X, CAPTURED_NUMBER_Y, :left, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Set Pokémon sprite
    setIconBitmap(iconspecies)
    # Draw slider arrows
    itemlist = @sprites["pokedex"]
    showslider = false
    if itemlist.top_row > 0
      overlay.blt(SLIDER_X, SLIDER_ARROW_UP_Y, @sliderbitmap.bitmap, Rect.new(*SLIDER_SRC_ARROW_UP))
      showslider = true
    end
    if itemlist.top_item + itemlist.page_item_max < itemlist.itemCount
      overlay.blt(SLIDER_X, SLIDER_ARROW_DOWN_Y, @sliderbitmap.bitmap, Rect.new(*SLIDER_SRC_ARROW_DOWN))
      showslider = true
    end
    # Draw slider box
    if showslider
      sliderheight = SLIDER_HEIGHT
      boxheight = (sliderheight * itemlist.page_row_max / itemlist.row_max).floor
      boxheight += [(sliderheight - boxheight) / 2, sliderheight / 6].min
      boxheight = [boxheight.floor, SLIDER_MIN_BOXHEIGHT].max
      y = SLIDER_Y
      y += ((sliderheight - boxheight) * itemlist.top_row / (itemlist.row_max - itemlist.page_row_max)).floor
      overlay.blt(SLIDER_X, y, @sliderbitmap.bitmap, Rect.new(*SLIDER_BOX_SRC_TOP))
      i = 0
      while i * SLIDER_BOX_SEGMENT < boxheight - SLIDER_BOX_PADDING_TOP - SLIDER_BOX_SEGMENT
        height = [boxheight - SLIDER_BOX_PADDING_TOP - SLIDER_BOX_SEGMENT - (i * SLIDER_BOX_SEGMENT), SLIDER_BOX_SEGMENT].min
        overlay.blt(SLIDER_X, y + SLIDER_BOX_PADDING_TOP + (i * SLIDER_BOX_SEGMENT), @sliderbitmap.bitmap, Rect.new(SLIDER_BOX_SRC_MID[0], SLIDER_BOX_SRC_MID[1], SLIDER_BOX_SRC_MID[2], height))
        i += 1
      end
      overlay.blt(SLIDER_X, y + boxheight - SLIDER_BOX_SEGMENT, @sliderbitmap.bitmap, Rect.new(*SLIDER_BOX_SRC_BOTTOM))
    end
  end

  def pbRefreshDexSearch(params, _index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(72, 72, 72)
    # Write various bits of text
    textpos = [
      [_INTL("Modo de Búsqueda"), DEXSEARCH_TITLE_X, DEXSEARCH_TITLE_Y, :center, base, shadow],
      [_INTL("Orden"), DEXSEARCH_ORDER_X, DEXSEARCH_ORDER_Y, :center, base, shadow],
      [_INTL("Nombre"), DEXSEARCH_NAME_X, DEXSEARCH_NAME_Y, :center, base, shadow],
      [_INTL("Tipo"), DEXSEARCH_TYPE_X, DEXSEARCH_TYPE_Y, :center, base, shadow],
      [_INTL("Altura"), DEXSEARCH_HEIGHT_X, DEXSEARCH_HEIGHT_Y, :center, base, shadow],
      [_INTL("Peso"), DEXSEARCH_WEIGHT_X, DEXSEARCH_WEIGHT_Y, :center, base, shadow],
      [_INTL("Color"), DEXSEARCH_COLOR_X, DEXSEARCH_COLOR_Y, :center, base, shadow],
      [_INTL("Forma"), DEXSEARCH_SHAPE_X, DEXSEARCH_SHAPE_Y, :center, base, shadow],
      [_INTL("Reiniciar"), DEXSEARCH_RESET_X, DEXSEARCH_RESET_Y, :center, base, shadow, 1],
      [_INTL("Empezar"), DEXSEARCH_START_X, DEXSEARCH_START_Y, :center, base, shadow, :outline],
      [_INTL("Cancelar"), DEXSEARCH_CANCEL_X, DEXSEARCH_CANCEL_Y, :center, base, shadow, :outline]
    ]
    # Write order, name and color parameters
    textpos.push([@orderCommands[params[0]], DEXSEARCH_PARAM_ORDER_X, DEXSEARCH_PARAM_ORDER_Y, :center, base, shadow, :outline])
    textpos.push([(params[1] < 0) ? "----" : @nameCommands[params[1]], DEXSEARCH_PARAM_NAME_X, DEXSEARCH_PARAM_NAME_Y, :center, base, shadow, :outline])
    textpos.push([(params[8] < 0) ? "----" : @colorCommands[params[8]].name, DEXSEARCH_PARAM_COLOR_X, DEXSEARCH_PARAM_COLOR_Y, :center, base, shadow, :outline])
    # Draw type icons
    if params[2] >= 0
      type_number = @typeCommands[params[2]].icon_position
      typerect = Rect.new(0, type_number * 32, 96, 32)
      overlay.blt(DEXSEARCH_TYPE1_BLT_X, DEXSEARCH_TYPE1_BLT_Y, @typebitmap.bitmap, typerect)
    else
      textpos.push(["----", DEXSEARCH_TYPE1_EMPTY_X, DEXSEARCH_TYPE1_EMPTY_Y, :center, base, shadow, :outline])
    end
    if params[3] >= 0
      type_number = @typeCommands[params[3]].icon_position
      typerect = Rect.new(0, type_number * 32, 96, 32)
      overlay.blt(DEXSEARCH_TYPE2_BLT_X, DEXSEARCH_TYPE2_BLT_Y, @typebitmap.bitmap, typerect)
    else
      textpos.push(["----", DEXSEARCH_TYPE2_EMPTY_X, DEXSEARCH_TYPE2_EMPTY_Y, :center, base, shadow, :outline])
    end
    # Write height and weight limits
    ht1 = (params[4] < 0) ? 0 : (params[4] >= @heightCommands.length) ? 999 : @heightCommands[params[4]]
    ht2 = (params[5] < 0) ? 999 : (params[5] >= @heightCommands.length) ? 0 : @heightCommands[params[5]]
    wt1 = (params[6] < 0) ? 0 : (params[6] >= @weightCommands.length) ? 9999 : @weightCommands[params[6]]
    wt2 = (params[7] < 0) ? 9999 : (params[7] >= @weightCommands.length) ? 0 : @weightCommands[params[7]]
    hwoffset = false
    if System.user_language[3..4] == "US"   # If the user is in the United States
      ht1 = (params[4] >= @heightCommands.length) ? 99 * 12 : (ht1 / 0.254).round
      ht2 = (params[5] < 0) ? 99 * 12 : (ht2 / 0.254).round
      wt1 = (params[6] >= @weightCommands.length) ? 99_990 : (wt1 / 0.254).round
      wt2 = (params[7] < 0) ? 99_990 : (wt2 / 0.254).round
      textpos.push([sprintf("%d'%02d''", ht1 / 12, ht1 % 12), DEXSEARCH_HT1_X, DEXSEARCH_HT_Y, :center, base, shadow, :outline])
      textpos.push([sprintf("%d'%02d''", ht2 / 12, ht2 % 12), DEXSEARCH_HT2_X, DEXSEARCH_HT_Y, :center, base, shadow, :outline])
      textpos.push([sprintf("%.1f", wt1 / 10.0), DEXSEARCH_WT1_X, DEXSEARCH_WT_Y, :center, base, shadow, :outline])
      textpos.push([sprintf("%.1f", wt2 / 10.0), DEXSEARCH_WT2_X, DEXSEARCH_WT_Y, :center, base, shadow, :outline])
      hwoffset = true
    else
      textpos.push([sprintf("%.1f", ht1 / 10.0), DEXSEARCH_HT1_X, DEXSEARCH_HT_Y, :center, base, shadow, :outline])
      textpos.push([sprintf("%.1f", ht2 / 10.0), DEXSEARCH_HT2_X, DEXSEARCH_HT_Y, :center, base, shadow, :outline])
      textpos.push([sprintf("%.1f", wt1 / 10.0), DEXSEARCH_WT1_X, DEXSEARCH_WT_Y, :center, base, shadow, :outline])
      textpos.push([sprintf("%.1f", wt2 / 10.0), DEXSEARCH_WT2_X, DEXSEARCH_WT_Y, :center, base, shadow, :outline])
    end
    overlay.blt(DEXSEARCH_HWBLT_X, DEXSEARCH_HWBLT1_Y, @hwbitmap.bitmap, Rect.new(0, (hwoffset) ? 44 : 0, 32, 44))
    overlay.blt(DEXSEARCH_HWBLT_X, DEXSEARCH_HWBLT2_Y, @hwbitmap.bitmap, Rect.new(32, (hwoffset) ? 44 : 0, 32, 44))
    # Draw shape icon
    if params[9] >= 0
      shape_number = @shapeCommands[params[9]].icon_position
      shaperect = Rect.new(0, shape_number * 60, 60, 60)
      overlay.blt(DEXSEARCH_SHAPE_BLT_X, DEXSEARCH_SHAPE_BLT_Y, @shapebitmap.bitmap, shaperect)
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def pbRefreshDexSearchParam(mode, cmds, sel, _index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(72, 72, 72)
    # Write various bits of text
    textpos = [
      [_INTL("Modo de Búsqueda"), DEXSEARCH_PARAM_TITLE_X, DEXSEARCH_PARAM_TITLE_Y, :center, base, shadow],
      [_INTL("OK"), DEXSEARCH_PARAM_OK_X, DEXSEARCH_PARAM_OK_Y, :center, base, shadow, :outline],
      [_INTL("Cancelar"), DEXSEARCH_PARAM_CANCEL_X, DEXSEARCH_PARAM_CANCEL_Y, :center, base, shadow, :outline]
    ]
    title = [_INTL("Orden"), _INTL("Nombre"), _INTL("Tipo"), _INTL("Altura"),
             _INTL("Peso"), _INTL("Color"), _INTL("Forma")][mode]
    textpos.push([title, DEXSEARCH_PARAM_TITLE_TEXT_X, (mode == 6) ? DEXSEARCH_PARAM_TITLE_TEXT_Y_LG : DEXSEARCH_PARAM_TITLE_TEXT_Y_SM, :left, base, shadow])
    # Load layout values from the mode->layout hash. Modes 3 and 4 need
    # dynamic computation for :xgap and :cols because they depend on
    # `cmds.length`.
    layout = DEXSEARCH_PARAM_LAYOUTS.fetch(mode, DEXSEARCH_PARAM_LAYOUTS[:default])
    xstart = layout[:xstart]
    ystart = layout[:ystart]
    if layout[:xgap].nil?
      xgap = 304 / (cmds.length + 1)
      cols = cmds.length + 1
    else
      xgap = layout[:xgap]
      cols = layout[:cols]
    end
    ygap = layout[:ygap]
    halfwidth = layout[:halfwidth]
    selbuttony = layout[:selbuttony] || 0
    selbuttonheight = layout[:selbuttonheight] || 44
    top_text_x_base = layout[:top_text_x_base]
    top_blt_x_base  = layout[:top_blt_x_base]
    top_spacing     = layout[:top_spacing]
    top_text_y      = layout[:top_text_y]
    top_blt_y       = layout[:top_blt_y]
    # Draw selected option(s) text in top bar
    case mode
    when 2   # Type icons
      2.times do |i|
        if !sel[i] || sel[i] < 0
          textpos.push(["----", top_text_x_base + (top_spacing * i), top_text_y, :center, base, shadow, :outline])
        else
          type_number = @typeCommands[sel[i]].icon_position
          typerect = Rect.new(0, type_number * 32, 96, 32)
          overlay.blt(top_blt_x_base + (top_spacing * i), top_blt_y, @typebitmap.bitmap, typerect)
        end
      end
    when 3   # Height range
      ht1 = (sel[0] < 0) ? 0 : (sel[0] >= @heightCommands.length) ? 999 : @heightCommands[sel[0]]
      ht2 = (sel[1] < 0) ? 999 : (sel[1] >= @heightCommands.length) ? 0 : @heightCommands[sel[1]]
      hwoffset = false
      if System.user_language[3..4] == "US"    # If the user is in the United States
        ht1 = (sel[0] >= @heightCommands.length) ? 99 * 12 : (ht1 / 0.254).round
        ht2 = (sel[1] < 0) ? 99 * 12 : (ht2 / 0.254).round
        txt1 = sprintf("%d'%02d''", ht1 / 12, ht1 % 12)
        txt2 = sprintf("%d'%02d''", ht2 / 12, ht2 % 12)
        hwoffset = true
      else
        txt1 = sprintf("%.1f", ht1 / 10.0)
        txt2 = sprintf("%.1f", ht2 / 10.0)
      end
      textpos.push([txt1, top_text_x_base, top_text_y, :center, base, shadow, :outline])
      textpos.push([txt2, top_text_x_base + top_spacing, top_text_y, :center, base, shadow, :outline])
      overlay.blt(top_blt_x_base, top_blt_y, @hwbitmap.bitmap, Rect.new(0, (hwoffset) ? 44 : 0, 32, 44))
    when 4   # Weight range
      wt1 = (sel[0] < 0) ? 0 : (sel[0] >= @weightCommands.length) ? 9999 : @weightCommands[sel[0]]
      wt2 = (sel[1] < 0) ? 9999 : (sel[1] >= @weightCommands.length) ? 0 : @weightCommands[sel[1]]
      hwoffset = false
      if System.user_language[3..4] == "US"   # If the user is in the United States
        wt1 = (sel[0] >= @weightCommands.length) ? 99_990 : (wt1 / 0.254).round
        wt2 = (sel[1] < 0) ? 99_990 : (wt2 / 0.254).round
        txt1 = sprintf("%.1f", wt1 / 10.0)
        txt2 = sprintf("%.1f", wt2 / 10.0)
        hwoffset = true
      else
        txt1 = sprintf("%.1f", wt1 / 10.0)
        txt2 = sprintf("%.1f", wt2 / 10.0)
      end
      textpos.push([txt1, top_text_x_base, top_text_y, :center, base, shadow, :outline])
      textpos.push([txt2, top_text_x_base + top_spacing, top_text_y, :center, base, shadow, :outline])
      overlay.blt(top_blt_x_base + 32, top_blt_y, @hwbitmap.bitmap, Rect.new(32, (hwoffset) ? 44 : 0, 32, 44))
    when 5   # Color
      if sel[0] < 0
        textpos.push(["----", top_text_x_base, top_text_y, :center, base, shadow, :outline])
      else
        textpos.push([cmds[sel[0]].name, top_text_x_base, top_text_y, :center, base, shadow, :outline])
      end
    when 6   # Shape icon
      if sel[0] >= 0
        shaperect = Rect.new(0, @shapeCommands[sel[0]].icon_position * 60, 60, 60)
        overlay.blt(top_blt_x_base, top_blt_y, @shapebitmap.bitmap, shaperect)
      end
    else
      if sel[0] < 0
        text = ["----", "-", "----", "", "", "----", ""][mode]
        textpos.push([text, top_text_x_base, top_text_y, :center, base, shadow, :outline])
      else
        textpos.push([cmds[sel[0]], top_text_x_base, top_text_y, :center, base, shadow, :outline])
      end
    end
    # Draw selected option(s) button graphic
    if [3, 4].include?(mode)   # Height, weight
      xpos1 = xstart + ((sel[0] + 1) * xgap)
      xpos1 = xstart if sel[0] < -1
      xpos2 = xstart + ((sel[1] + 1) * xgap)
      xpos2 = xstart + (cols * xgap) if sel[1] < 0
      xpos2 = xstart if sel[1] >= cols - 1
      ypos1 = ystart + DEXSEARCH_PARAM_HW_Y_OFFSET1
      ypos2 = ystart + DEXSEARCH_PARAM_HW_Y_OFFSET2
      overlay.blt(DEXSEARCH_PARAM_SLIDER_LEFT_X, DEXSEARCH_PARAM_SLIDER_TOP1_Y, @searchsliderbitmap.bitmap, Rect.new(*DEXSEARCH_PARAM_SLIDER_SRC_LEFT)) if sel[1] < cols - 1
      overlay.blt(DEXSEARCH_PARAM_SLIDER_RIGHT_X, DEXSEARCH_PARAM_SLIDER_TOP1_Y, @searchsliderbitmap.bitmap, Rect.new(*DEXSEARCH_PARAM_SLIDER_SRC_RIGHT)) if sel[1] >= 0
      overlay.blt(DEXSEARCH_PARAM_SLIDER_LEFT_X, DEXSEARCH_PARAM_SLIDER_TOP2_Y, @searchsliderbitmap.bitmap, Rect.new(*DEXSEARCH_PARAM_SLIDER_SRC_LEFT)) if sel[0] >= 0
      overlay.blt(DEXSEARCH_PARAM_SLIDER_RIGHT_X, DEXSEARCH_PARAM_SLIDER_TOP2_Y, @searchsliderbitmap.bitmap, Rect.new(*DEXSEARCH_PARAM_SLIDER_SRC_RIGHT)) if sel[0] < cols - 1
      hwrect = Rect.new(0, 0, DEXSEARCH_PARAM_HWRECT_W, DEXSEARCH_PARAM_HWRECT_H)
      overlay.blt(xpos2, ystart, @searchsliderbitmap.bitmap, hwrect)
      hwrect.y = DEXSEARCH_PARAM_HWRECT_ALT_Y
      overlay.blt(xpos1, ystart + ygap, @searchsliderbitmap.bitmap, hwrect)
      textpos.push([txt1, xpos1 + halfwidth, ypos1, :center, base])
      textpos.push([txt2, xpos2 + halfwidth, ypos2, :center, base])
    else
      sel.length.times do |i|
        selrect = Rect.new(0, selbuttony, @selbitmap.bitmap.width, selbuttonheight)
        if sel[i] >= 0
          overlay.blt(xstart + ((sel[i] % cols) * xgap),
                      ystart + ((sel[i] / cols).floor * ygap),
                      @selbitmap.bitmap, selrect)
        else
          overlay.blt(xstart + ((cols - 1) * xgap),
                      ystart + ((cmds.length / cols).floor * ygap),
                      @selbitmap.bitmap, selrect)
        end
      end
    end
    # Draw options
    case mode
    when 0, 1   # Order, name
      cmds.length.times do |i|
        x = xstart + halfwidth + ((i % cols) * xgap)
        y = ystart + DEXSEARCH_PARAM_TEXT_Y_OFFSET + ((i / cols).floor * ygap)
        textpos.push([cmds[i], x, y, :center, base, shadow, :outline])
      end
      if mode != 0
        textpos.push([(mode == 1) ? "-" : "----",
                      xstart + halfwidth + ((cols - 1) * xgap),
                      ystart + DEXSEARCH_PARAM_TEXT_Y_OFFSET + ((cmds.length / cols).floor * ygap),
                      :center, base, shadow, :outline])
      end
    when 2   # Type
      typerect = Rect.new(0, 0, 96, 32)
      cmds.length.times do |i|
        typerect.y = @typeCommands[i].icon_position * 32
        overlay.blt(xstart + DEXSEARCH_PARAM_TEXT_X_OFFSET + ((i % cols) * xgap),
                    ystart + DEXSEARCH_PARAM_ICON_Y_OFFSET + ((i / cols).floor * ygap),
                    @typebitmap.bitmap, typerect)
      end
      textpos.push(["----",
                    xstart + halfwidth + ((cols - 1) * xgap),
                    ystart + DEXSEARCH_PARAM_TEXT_Y_OFFSET + ((cmds.length / cols).floor * ygap),
                    :center, base, shadow, :outline])
    when 5   # Color
      cmds.length.times do |i|
        x = xstart + halfwidth + ((i % cols) * xgap)
        y = ystart + DEXSEARCH_PARAM_TEXT_Y_OFFSET + ((i / cols).floor * ygap)
        textpos.push([cmds[i].name, x, y, :center, base, shadow, :outline])
      end
      textpos.push(["----",
                    xstart + halfwidth + ((cols - 1) * xgap),
                    ystart + DEXSEARCH_PARAM_TEXT_Y_OFFSET + ((cmds.length / cols).floor * ygap),
                    :center, base, shadow, :outline])
    when 6   # Shape
      shaperect = Rect.new(0, 0, DEXSEARCH_PARAM_SHAPE_W, DEXSEARCH_PARAM_SHAPE_H)
      cmds.length.times do |i|
        shaperect.y = @shapeCommands[i].icon_position * DEXSEARCH_PARAM_SHAPE_H
        overlay.blt(xstart + DEXSEARCH_PARAM_ICON_X_OFFSET + ((i % cols) * xgap),
                    ystart + DEXSEARCH_PARAM_ICON_Y_OFFSET + ((i / cols).floor * ygap),
                    @shapebitmap.bitmap, shaperect)
      end
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def setIconBitmap(species)
    gender, form, shiny = $player.pokedex.last_form_seen(species)
    @sprites["icon"].setSpeciesBitmap(species, gender, form, shiny)
    if Settings::SHOW_SILHOUETTES_IN_DEX
      # species_id = (species) ? GameData::Species.get_species_form(species, form).id : nil
      # @sprites["icon"].pbSetDisplay([112, 196, 224, 216], species_id)
      if !$player.seen?(@sprites["pokedex"].species)
        @sprites["icon"].tone = Tone.new(-255,-255,-255,255)
      else
        @sprites["icon"].tone = Tone.new(0,0,0,0)
      end
    end
  end

  def pbSearchDexList(params)
    $PokemonGlobal.pokedexMode = params[0]
    dexlist = pbGetDexList
    # Filter by name
    if params[1] >= 0
      scanNameCommand = @nameCommands[params[1]].scan(/./)
      dexlist = dexlist.find_all do |item|
        next false if !$player.seen?(item[:species])
        firstChar = item[:name][0, 1]
        next scanNameCommand.any? { |v| v == firstChar }
      end
    end
    # Filter by type
    if params[2] >= 0 || params[3] >= 0
      stype1 = (params[2] >= 0) ? @typeCommands[params[2]].id : nil
      stype2 = (params[3] >= 0) ? @typeCommands[params[3]].id : nil
      dexlist = dexlist.find_all do |item|
        next false if !$player.owned?(item[:species])
        types = item[:types]
        if stype1 && stype2
          # Find species that match both types
          next types.include?(stype1) && types.include?(stype2)
        elsif stype1
          # Find species that match first type entered
          next types.include?(stype1)
        elsif stype2
          # Find species that match second type entered
          next types.include?(stype2)
        else
          next false
        end
      end
    end
    # Filter by height range
    if params[4] >= 0 || params[5] >= 0
      minh = (params[4] < 0) ? 0 : (params[4] >= @heightCommands.length) ? 999 : @heightCommands[params[4]]
      maxh = (params[5] < 0) ? 999 : (params[5] >= @heightCommands.length) ? 0 : @heightCommands[params[5]]
      dexlist = dexlist.find_all do |item|
        next false if !$player.owned?(item[:species])
        height = item[:height]
        next height >= minh && height <= maxh
      end
    end
    # Filter by weight range
    if params[6] >= 0 || params[7] >= 0
      minw = (params[6] < 0) ? 0 : (params[6] >= @weightCommands.length) ? 9999 : @weightCommands[params[6]]
      maxw = (params[7] < 0) ? 9999 : (params[7] >= @weightCommands.length) ? 0 : @weightCommands[params[7]]
      dexlist = dexlist.find_all do |item|
        next false if !$player.owned?(item[:species])
        weight = item[:weight]
        next weight >= minw && weight <= maxw
      end
    end
    # Filter by color
    if params[8] >= 0
      scolor = @colorCommands[params[8]].id
      dexlist = dexlist.find_all do |item|
        next $player.seen?(item[:species]) && item[:color] == scolor
      end
    end
    # Filter by shape
    if params[9] >= 0
      sshape = @shapeCommands[params[9]].id
      dexlist = dexlist.find_all do |item|
        next $player.seen?(item[:species]) && item[:shape] == sshape
      end
    end
    # Remove all unseen species from the results
    dexlist = dexlist.find_all { |item| next $player.seen?(item[:species]) }
    case $PokemonGlobal.pokedexMode
    when MODENUMERICAL then dexlist.sort! { |a, b| a[:number] <=> b[:number] }
    when MODEATOZ      then dexlist.sort! { |a, b| a[:name] <=> b[:name] }
    when MODEHEAVIEST  then dexlist.sort! { |a, b| b[:weight] <=> a[:weight] }
    when MODELIGHTEST  then dexlist.sort! { |a, b| a[:weight] <=> b[:weight] }
    when MODETALLEST   then dexlist.sort! { |a, b| b[:height] <=> a[:height] }
    when MODESMALLEST  then dexlist.sort! { |a, b| a[:height] <=> b[:height] }
    end
    return dexlist
  end

  def pbCloseSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    oldspecies = @sprites["pokedex"].species
    @searchResults = false
    $PokemonGlobal.pokedexMode = MODENUMERICAL
    @searchParams = [$PokemonGlobal.pokedexMode, -1, -1, -1, -1, -1, -1, -1, -1, -1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    @dexlist.length.times do |i|
      next if @dexlist[i][:species] != oldspecies
      @sprites["pokedex"].index = i
      pbRefresh
      break
    end
    $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index
    pbFadeInAndShow(@sprites, oldsprites)
  end

  def pbDexEntry(index)
    oldsprites = pbFadeOutAndHide(@sprites)
    region = -1
    if !Settings::USE_CURRENT_REGION_DEX
      dexnames = Settings.pokedex_names
      if dexnames[pbGetSavePositionIndex].is_a?(Array)
        region = dexnames[pbGetSavePositionIndex][1]
      end
    end
    scene = PokemonPokedexInfo_Scene.new
    screen = PokemonPokedexInfoScreen.new(scene)
    ret = screen.pbStartScreen(@dexlist, index, region)
    if @searchResults
      dexlist = pbSearchDexList(@searchParams)
      @dexlist = dexlist
      @sprites["pokedex"].commands = @dexlist
      ret = @dexlist.length - 1 if ret >= @dexlist.length
      ret = 0 if ret < 0
    else
      pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
      $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = ret
    end
    @sprites["pokedex"].index = ret
    @sprites["pokedex"].refresh
    pbRefresh
    pbFadeInAndShow(@sprites, oldsprites)
  end

  def pbDexSearchCommands(mode, selitems, mainindex)
    cmds = [@orderCommands, @nameCommands, @typeCommands, @heightCommands,
            @weightCommands, @colorCommands, @shapeCommands][mode]
    cols = [2, 7, 4, 1, 1, 3, 5][mode]
    ret = nil
    # Set background
    case mode
    when 0    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_order")
    when 1    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_name")
    when 2
      count = 0
      GameData::Type.each { |t| count += 1 if !t.pseudo_type && t.id != :SHADOW }
      if count == 18
        @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_type_18")
      else
        @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_type")
      end
    when 3, 4 then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_size")
    when 5    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_color")
    when 6    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search_shape")
    end
    selindex = selitems.clone
    index     = selindex[0]
    oldindex  = index
    minmax    = 1
    oldminmax = minmax
    index = oldindex = selindex[minmax] if [3, 4].include?(mode)
    @sprites["searchcursor"].mode   = mode
    @sprites["searchcursor"].cmds   = cmds.length
    @sprites["searchcursor"].minmax = minmax
    @sprites["searchcursor"].index  = index
    nextparam = cmds.length % 2
    pbRefreshDexSearchParam(mode, cmds, selindex, index)
    loop do
      pbUpdate
      if index != oldindex || minmax != oldminmax
        @sprites["searchcursor"].minmax = minmax
        @sprites["searchcursor"].index  = index
        oldindex  = index
        oldminmax = minmax
      end
      Graphics.update
      Input.update
      if [3, 4].include?(mode)
        if Input.trigger?(Input::UP)
          if index < -1   # From OK/Cancel
            minmax = 0
            index = selindex[minmax]
          elsif minmax == 0
            minmax = 1
            index = selindex[minmax]
          end
          if index != oldindex || minmax != oldminmax
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        elsif Input.trigger?(Input::DOWN)
          case minmax
          when 1
            minmax = 0
            index = selindex[minmax]
          when 0
            minmax = -1
            index = -2
          end
          if index != oldindex || minmax != oldminmax
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        elsif Input.repeat?(Input::LEFT)
          if index == -3
            index = -2
          elsif index >= -1
            if minmax == 1 && index == -1
              index = cmds.length - 1 if selindex[0] < cmds.length - 1
            elsif minmax == 1 && index == 0
              index = cmds.length if selindex[0] < 0
            elsif index > -1 && !(minmax == 1 && index >= cmds.length)
              index -= 1 if minmax == 0 || selindex[0] <= index - 1
            end
          end
          if index != oldindex
            selindex[minmax] = index if minmax >= 0
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        elsif Input.repeat?(Input::RIGHT)
          if index == -2
            index = -3
          elsif index >= -1
            if minmax == 1 && index >= cmds.length
              index = 0
            elsif minmax == 1 && index == cmds.length - 1
              index = -1
            elsif index < cmds.length && !(minmax == 1 && index < 0)
              index += 1 if minmax == 1 || selindex[1] == -1 ||
                            (selindex[1] < cmds.length && selindex[1] >= index + 1)
            end
          end
          if index != oldindex
            selindex[minmax] = index if minmax >= 0
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        end
      else
        if Input.trigger?(Input::UP)
          if index == -1   # From blank
            index = cmds.length - 1 - ((cmds.length - 1) % cols) - 1
          elsif index == -2   # From OK
            index = ((cmds.length - 1) / cols).floor * cols
          elsif index == -3 && mode == 0   # From Cancel
            index = cmds.length - 1
          elsif index == -3   # From Cancel
            index = -1
          elsif index >= cols
            index -= cols
          end
          pbPlayCursorSE if index != oldindex
        elsif Input.trigger?(Input::DOWN)
          if index == -1   # From blank
            index = -3
          elsif index >= 0
            if index + cols < cmds.length
              index += cols
            elsif (index / cols).floor < ((cmds.length - 1) / cols).floor
              index = (index % cols < cols / 2.0) ? cmds.length - 1 : -1
            else
              index = (index % cols < cols / 2.0) ? -2 : -3
            end
          end
          pbPlayCursorSE if index != oldindex
        elsif Input.trigger?(Input::LEFT)
          if index == -3
            index = -2
          elsif index == -1
            index = cmds.length - 1
          elsif index > 0 && index % cols != 0
            index -= 1
          end
          pbPlayCursorSE if index != oldindex
        elsif Input.trigger?(Input::RIGHT)
          if index == -2
            index = -3
          elsif index == cmds.length - 1 && mode != 0
            index = -1
          elsif index >= 0 && index % cols != cols - 1
            index += 1
          end
          pbPlayCursorSE if index != oldindex
        end
      end
      if Input.trigger?(Input::ACTION)
        index = -2
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        ret = nil
        break
      elsif Input.trigger?(Input::USE)
        if index == -2      # OK
          pbSEPlay("GUI pokedex open")
          ret = selindex
          break
        elsif index == -3   # Cancel
          pbPlayCloseMenuSE
          ret = nil
          break
        elsif selindex != index && mode != 3 && mode != 4
          if mode == 2
            if index == -1
              nextparam = (selindex[1] >= 0) ? 1 : 0
            elsif index >= 0
              nextparam = (selindex[0] < 0) ? 0 : (selindex[1] < 0) ? 1 : nextparam
            end
            if index < 0 || selindex[(nextparam + 1) % 2] != index
              pbPlayDecisionSE
              selindex[nextparam] = index
              nextparam = (nextparam + 1) % 2
            end
          else
            pbPlayDecisionSE
            selindex[0] = index
          end
          pbRefreshDexSearchParam(mode, cmds, selindex, index)
        end
      end
    end
    Input.update
    # Set background image
    @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search")
    @sprites["searchcursor"].mode = -1
    @sprites["searchcursor"].index = mainindex
    return ret
  end

  def pbDexSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    params = @searchParams.clone
    @orderCommands = []
    @orderCommands[MODENUMERICAL] = _INTL("Numérico")
    @orderCommands[MODEATOZ]      = _INTL("A a Z")
    @orderCommands[MODEHEAVIEST]  = _INTL("Más pesado")
    @orderCommands[MODELIGHTEST]  = _INTL("Más ligero")
    @orderCommands[MODETALLEST]   = _INTL("Más alto")
    @orderCommands[MODESMALLEST]  = _INTL("Más bajo")
    @nameCommands = [_INTL("A"), _INTL("B"), _INTL("C"), _INTL("D"), _INTL("E"),
                     _INTL("F"), _INTL("G"), _INTL("H"), _INTL("I"), _INTL("J"),
                     _INTL("K"), _INTL("L"), _INTL("M"), _INTL("N"), _INTL("O"),
                     _INTL("P"), _INTL("Q"), _INTL("R"), _INTL("S"), _INTL("T"),
                     _INTL("U"), _INTL("V"), _INTL("W"), _INTL("X"), _INTL("Y"),
                     _INTL("Z")]
    @typeCommands = []
    GameData::Type.each { |t| @typeCommands.push(t) if !t.pseudo_type }
    @heightCommands = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                       11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                       21, 22, 23, 24, 25, 30, 35, 40, 45, 50,
                       55, 60, 65, 70, 80, 90, 100]
    @weightCommands = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50,
                       55, 60, 70, 80, 90, 100, 110, 120, 140, 160,
                       180, 200, 250, 300, 350, 400, 500, 600, 700, 800,
                       900, 1000, 1250, 1500, 2000, 3000, 5000]
    @colorCommands = []
    GameData::BodyColor.each { |c| @colorCommands.push(c) if c.id != :None }
    @shapeCommands = []
    GameData::BodyShape.each { |s| @shapeCommands.push(s) if s.id != :None }
    @sprites["searchbg"].visible     = true
    @sprites["overlay"].visible      = true
    @sprites["searchcursor"].visible = true
    index = 0
    oldindex = index
    @sprites["searchcursor"].mode    = -1
    @sprites["searchcursor"].index   = index
    pbRefreshDexSearch(params, index)
    pbFadeInAndShow(@sprites)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if index != oldindex
        @sprites["searchcursor"].index = index
        oldindex = index
      end
      if Input.trigger?(Input::UP)
        if index >= 7
          index = 4
        elsif index == 5
          index = 0
        elsif index > 0
          index -= 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::DOWN)
        if [4, 6].include?(index)
          index = 8
        elsif index < 7
          index += 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::LEFT)
        if index == 5
          index = 1
        elsif index == 6
          index = 3
        elsif index > 7
          index -= 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::RIGHT)
        if index == 1
          index = 5
        elsif index >= 2 && index <= 4
          index = 6
        elsif [7, 8].include?(index)
          index += 1
        end
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::ACTION)
        index = 8
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbSEPlay("GUI pokedex open") if index != 9
        case index
        when 0   # Choose sort order
          newparam = pbDexSearchCommands(0, [params[0]], index)
          params[0] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 1   # Filter by name
          newparam = pbDexSearchCommands(1, [params[1]], index)
          params[1] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 2   # Filter by type
          newparam = pbDexSearchCommands(2, [params[2], params[3]], index)
          if newparam
            params[2] = newparam[0]
            params[3] = newparam[1]
          end
          pbRefreshDexSearch(params, index)
        when 3   # Filter by height range
          newparam = pbDexSearchCommands(3, [params[4], params[5]], index)
          if newparam
            params[4] = newparam[0]
            params[5] = newparam[1]
          end
          pbRefreshDexSearch(params, index)
        when 4   # Filter by weight range
          newparam = pbDexSearchCommands(4, [params[6], params[7]], index)
          if newparam
            params[6] = newparam[0]
            params[7] = newparam[1]
          end
          pbRefreshDexSearch(params, index)
        when 5   # Filter by color filter
          newparam = pbDexSearchCommands(5, [params[8]], index)
          params[8] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 6   # Filter by shape
          newparam = pbDexSearchCommands(6, [params[9]], index)
          params[9] = newparam[0] if newparam
          pbRefreshDexSearch(params, index)
        when 7   # Clear filters
          10.times do |i|
            params[i] = (i == 0) ? MODENUMERICAL : -1
          end
          pbRefreshDexSearch(params, index)
        when 8   # Start search (filter)
          dexlist = pbSearchDexList(params)
          if dexlist.length == 0
            pbMessage(_INTL("No se han encontrado Pokémon con estos criterios."))
          else
            @dexlist = dexlist
            @sprites["pokedex"].commands = @dexlist
            @sprites["pokedex"].index    = 0
            @sprites["pokedex"].refresh
            @searchResults = true
            @searchParams = params
            break
          end
        when 9   # Cancel
          pbPlayCloseMenuSE
          break
        end
      end
    end
    pbFadeOutAndHide(@sprites)
    if @searchResults
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_listsearch")
    else
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_list")
    end
    pbRefresh
    pbFadeInAndShow(@sprites, oldsprites)
    Input.update
    return 0
  end

  def pbPokedex
    pbActivateWindow(@sprites, "pokedex") do
      loop do
        Graphics.update
        Input.update
        oldindex = @sprites["pokedex"].index
        pbUpdate
        if oldindex != @sprites["pokedex"].index
          $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index if !@searchResults
          pbRefresh
        end
        if Input.trigger?(Input::ACTION)
          pbSEPlay("GUI pokedex open")
          @sprites["pokedex"].active = false
          pbDexSearch
          @sprites["pokedex"].active = true
        elsif Input.trigger?(Input::BACK)
          pbPlayCloseMenuSE
          if @searchResults
            pbCloseSearch
          else
            break
          end
        elsif Input.trigger?(Input::USE)
          if $player.seen?(@sprites["pokedex"].species)
            pbSEPlay("GUI pokedex open")
            pbDexEntry(@sprites["pokedex"].index)
          end
        elsif Input.trigger?(Input::SPECIAL)
          open_search_box
        end
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokedexScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbPokedex
    @scene.pbEndScene
  end
end