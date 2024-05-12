#===============================================================================
# CREDITOS
# DiegoWT, Skyflyer, DPertierra
#===============================================================================
#===============================================================================
# Creating specific Bag and Party functionalities
#===============================================================================

# Making a minor edit to SpriteWindow_Selectable's update to avoid the
# pbPlayCursorSE to play while you scroll through the items' list
class SpriteWindow_Selectable < SpriteWindow_Base
  attr_reader :index
  attr_writer :ignore_input

  def update
    super
    if self.active && @item_max > 0 && @index >= 0 && !@ignore_input && @bag
      if Input.repeat?(Input::UP)
        if @index >= @column_max ||
           (Input.trigger?(Input::UP) && (@item_max % @column_max) == 0)
          oldindex = @index
          @index = (@index - @column_max + @item_max) % @item_max
          if @index != oldindex
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::DOWN)
        if @index < @item_max - @column_max ||
           (Input.trigger?(Input::DOWN) && (@item_max % @column_max) == 0)
          oldindex = @index
          @index = (@index + @column_max) % @item_max
          if @index != oldindex
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::JUMPUP)
        if @index > 0
          oldindex = @index
          @index = [self.index - self.page_item_max, 0].max
          if @index != oldindex
            pbPlayCursorSE
            self.top_row -= self.page_row_max
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::JUMPDOWN)
        if @index < @item_max - 1
          oldindex = @index
          @index = [self.index + self.page_item_max, @item_max - 1].min
          if @index != oldindex
            pbPlayCursorSE
            self.top_row += self.page_row_max
            update_cursor_rect
          end
        end
      end
    elsif  self.active && @item_max > 0 && @index >= 0 && !@ignore_input
      if Input.repeat?(Input::UP)
        if @index >= @column_max ||
           (Input.trigger?(Input::UP) && (@item_max % @column_max) == 0)
          oldindex = @index
          @index = (@index - @column_max + @item_max) % @item_max
          if @index != oldindex
            pbPlayCursorSE
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::DOWN)
        if @index < @item_max - @column_max ||
           (Input.trigger?(Input::DOWN) && (@item_max % @column_max) == 0)
          oldindex = @index
          @index = (@index + @column_max) % @item_max
          if @index != oldindex
            pbPlayCursorSE
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::LEFT)
        if @column_max >= 2 && @index > 0
          oldindex = @index
          @index -= 1
          if @index != oldindex
            pbPlayCursorSE
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::RIGHT)
        if @column_max >= 2 && @index < @item_max - 1
          oldindex = @index
          @index += 1
          if @index != oldindex
            pbPlayCursorSE
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::JUMPUP)
        if @index > 0
          oldindex = @index
          @index = [self.index - self.page_item_max, 0].max
          if @index != oldindex
            pbPlayCursorSE
            self.top_row -= self.page_row_max
            update_cursor_rect
          end
        end
      elsif Input.repeat?(Input::JUMPDOWN)
        if @index < @item_max - 1
          oldindex = @index
          @index = [self.index + self.page_item_max, @item_max - 1].min
          if @index != oldindex
            pbPlayCursorSE
            self.top_row += self.page_row_max
            update_cursor_rect
          end
        end
      end
    end
  end
end

class Window_PokemonBag < Window_DrawableCommand
  attr_reader :pocket
  attr_accessor :sorting
  attr_accessor :party1sel
  attr_accessor :party2sel

  def initialize(bag, filterlist, pocket, x, y, width, height)
    @bag        = bag
    @filterlist = filterlist
    @pocket     = pocket
    @sorting  = false
    @party1sel = false
    @party2sel = false
    @adapter  = PokemonMartAdapter.new
    super(x, y, width, height)
    @selarrow   = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/cursor")
    @swaparrow  = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/cursor_swap")
    @party1arrow = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/cursor_party1")
    @party2arrow = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/cursor_party2")
    self.windowskin = nil
  end

  def dispose
    @swaparrow.dispose
    @party1arrow.dispose
    @party2arrow.dispose
    super
  end

  def pocket=(value)
    @pocket = value
    @item_max = (@filterlist) ? @filterlist[@pocket].length + 1 : @bag.pockets[@pocket].length + 1
    self.index = @bag.last_viewed_index(@pocket)
  end

  def page_row_max; return PokemonBag_Scene::ITEMSVISIBLE; end
  def page_item_max; return PokemonBag_Scene::ITEMSVISIBLE; end

  def item
    return nil if @filterlist && !@filterlist[@pocket][self.index]
    thispocket = @bag.pockets[@pocket]
    item = (@filterlist) ? thispocket[@filterlist[@pocket][self.index]] : thispocket[self.index]
    return (item) ? item[0] : nil
  end

  def itemCount
    return (@filterlist) ? @filterlist[@pocket].length + 1 : @bag.pockets[@pocket].length + 1
  end

  def itemRect(item)
    if item < 0 || item >= @item_max || item < self.top_item - 1 ||
       item > self.top_item + self.page_item_max
      return Rect.new(0, 0, 0, 0)
    else
      cursor_width = (self.width - self.borderX - ((@column_max - 1) * @column_spacing)) / @column_max
      x = item % @column_max * (cursor_width + @column_spacing)
      y = (item / @column_max * @row_height) - @virtualOy
      return Rect.new(x, y, cursor_width, @row_height)
    end
  end

  def drawCursor(index, rect)
    if self.index == index
      if @party1sel
        bmp = @party1arrow.bitmap
      elsif @party2sel
        bmp = @party2arrow.bitmap
      elsif @sorting
        bmp = @swaparrow.bitmap
      else
        bmp = @selarrow.bitmap
      end
      pbCopyBitmap(self.contents, bmp, rect.x, rect.y + 2)
    end
  end

  def drawItem(index, _count, rect)
    textpos = []
    rect = Rect.new(rect.x + 16, rect.y + 16, rect.width - 16, rect.height)
    thispocket = @bag.pockets[@pocket]
    if index == self.itemCount - 1
      if @selarrow && index == self.index
        if @party2sel
          baseColor   = self.baseColor
          shadowColor = self.shadowColor
        else
          baseColor   = Color.new(78, 86, 100)
          shadowColor = Color.new(157, 171, 178)
        end
      else
        baseColor   = self.baseColor
        shadowColor = self.shadowColor
      end
      textpos.push([_INTL("CERRAR MOCHILA"), rect.x, rect.y + 4, :left, baseColor, shadowColor])
    else
      item = (@filterlist) ? thispocket[@filterlist[@pocket][index]][0] : thispocket[index][0]
      baseColor   = self.baseColor
      shadowColor = self.shadowColor
      if @sorting && index == self.index
        baseColor   = Color.new(224, 0, 0)
        shadowColor = Color.new(248, 144, 144)
      elsif @party2sel && index == self.index
        baseColor   = self.baseColor
        shadowColor = self.shadowColor
      elsif @selarrow && index == self.index
        baseColor   = Color.new(78, 86, 100)
        shadowColor = Color.new(157, 171, 178)
      end
      textpos.push(
        [@adapter.getDisplayName(item), rect.x, rect.y + 4, :left, baseColor, shadowColor]
      )
      item_data = GameData::Item.get(item)
      showing_register_icon = false
      if item_data.is_important?
        if @bag.registered?(item)
          pbDrawImagePositions(
            self.contents,
            [["Graphics/UI/Bag Screen with Party/icon_register", rect.x + rect.width - 72, rect.y + 10, 0, 0, -1, 24]]
          )
          showing_register_icon = true
        elsif pbCanRegisterItem?(item)
          pbDrawImagePositions(
            self.contents,
            [["Graphics/UI/Bag Screen with Party/icon_register", rect.x + rect.width - 72, rect.y + 10, 0, 24, -1, 24]]
          )
          showing_register_icon = true
        end
      end
      if item_data.show_quantity? && !showing_register_icon
        qty = (@filterlist) ? thispocket[@filterlist[@pocket][index]][1] : thispocket[index][1]
        qtytext = _ISPRINTF("x{1: 3d}", qty)
        xQty    = rect.x + rect.width - self.contents.text_size(qtytext).width - 16
        textpos.push([qtytext, xQty, rect.y + 2, :left, baseColor, shadowColor])
      end
    end
    pbDrawTextPositions(self.contents, textpos)
  end

  def refresh
    @item_max = itemCount
    self.update_cursor_rect
    dwidth  = self.width - self.borderX
    dheight = self.height - self.borderY
    self.contents = pbDoEnsureBitmap(self.contents, dwidth, dheight)
    self.contents.clear
    drawCursor(self.index, itemRect(self.index))
    @item_max.times do |i|
      next if i < self.top_item - 1 || i > self.top_item + self.page_item_max
      drawItem(i, @item_max, itemRect(i))
    end
  end

  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end

class PokemonBagPartyBlankPanel < Sprite
  attr_accessor :text
  attr_accessor :text_color

  def initialize(_pokemon,index,viewport=nil)
    super(viewport)
    self.x = (index % 2) * 112 + 4
    self.y = (index % 2) + 96 + 2
    @panelbgsprite = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/ptpanel_blank")
    self.bitmap = @panelbgsprite.bitmap
    @text = nil
  end

  def dispose
    @panelbgsprite.dispose
    super
  end

  def selected; return false; end
  def selected=(value); end
  def preselected; return false; end
  def preselected=(value); end
  def switching; return false; end
  def switching=(value); end
  def refresh; end
end

class PokemonBagPartyPanel < Sprite
  attr_reader :pokemon
  attr_reader :active
  attr_reader :selected
  attr_reader :preselected
  attr_reader :switching
  attr_reader :text
  attr_reader :text_color

  def initialize(pokemon, index, viewport=nil)
    super(viewport)
    @pokemon = pokemon
    @active = (index == 0)   # true = rounded panel, false = rectangular panel
    @refreshing = true
    self.x = (index % 2) * 112 + 4
    self.y = 96 * (index / 2) + 2
    @panelbgsprite = ChangelingSprite.new(0, 0, viewport)
    @panelbgsprite.z = self.z
    if @active   # Rounded panel
      @panelbgsprite.addBitmap("APTO", "Graphics/UI/Bag Screen with Party/ptpanel_round_desel")
      @panelbgsprite.addBitmap("APTOsel", "Graphics/UI/Bag Screen with Party/ptpanel_round_sel")
      @panelbgsprite.addBitmap("fainted", "Graphics/UI/Bag Screen with Party/ptpanel_round_faint")
      @panelbgsprite.addBitmap("faintedsel", "Graphics/UI/Bag Screen with Party/ptpanel_round_faint_sel")
      @panelbgsprite.addBitmap("swap", "Graphics/UI/Bag Screen with Party/ptpanel_round_move")
      @panelbgsprite.addBitmap("swapsel", "Graphics/UI/Bag Screen with Party/ptpanel_round_move_sel")
      @panelbgsprite.addBitmap("swapsel2", "Graphics/UI/Bag Screen with Party/ptpanel_round_move_sel")
    else   # Rectangular panel
      @panelbgsprite.addBitmap("APTO", "Graphics/UI/Bag Screen with Party/ptpanel_rect_desel")
      @panelbgsprite.addBitmap("APTOsel", "Graphics/UI/Bag Screen with Party/ptpanel_rect_sel")
      @panelbgsprite.addBitmap("fainted", "Graphics/UI/Bag Screen with Party/ptpanel_rect_faint")
      @panelbgsprite.addBitmap("faintedsel", "Graphics/UI/Bag Screen with Party/ptpanel_rect_faint_sel")
      @panelbgsprite.addBitmap("swap", "Graphics/UI/Bag Screen with Party/ptpanel_rect_move")
      @panelbgsprite.addBitmap("swapsel", "Graphics/UI/Bag Screen with Party/ptpanel_rect_move_sel")
      @panelbgsprite.addBitmap("swapsel2", "Graphics/UI/Bag Screen with Party/ptpanel_rect_move_sel")
    end
    @pkmnsprite = PokemonIconSprite.new(pokemon, viewport)
    @pkmnsprite.setOffset(PictureOrigin::CENTER)
    @pkmnsprite.active = @active
    @pkmnsprite.z      = self.z + 1
    @hpbgsprite = ChangelingSprite.new(0, 0, viewport)
    @hpbgsprite.z = self.z + 2
    @hpbgsprite.addBitmap("APTO", "Graphics/UI/Bag Screen with Party/overlay_hp_back")
    @hpbgsprite.addBitmap("cursor", "Graphics/UI/Bag Screen with Party/overlay_hp_back")
    @helditemsprite = HeldItemIconSprite.new(0, 0, @pokemon, viewport)
    @helditemsprite.z = self.z + 3
    @overlaysprite = BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    @overlaysprite.z = self.z + 4
    @hpbar    = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/overlay_hp")
    @statuses = AnimatedBitmap.new(_INTL("Graphics/UI/statuses"))
    @pokerus  = AnimatedBitmap.new("Graphics/UI/Bag Screen with Party/icon_pokerus") if BagScreenWiInParty::PKRSICON == true
    @selected      = false
    @preselected   = false
    @switching     = false
    @text          = nil
    @text_color    = nil
    @refreshBitmap = true
    @refreshing    = false
    refresh
  end

  def dispose
    @panelbgsprite.dispose
    @hpbgsprite.dispose
    @pkmnsprite.dispose
    @helditemsprite.dispose
    @overlaysprite.bitmap.dispose
    @overlaysprite.dispose
    @hpbar.dispose
    @statuses.dispose
    super
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    refresh
  end

  def text=(value)
    if @text != value
      @text = value
      @refreshBitmap = true
      refresh
    end
  end

  def text_color=(value)
    if @text_color!=value
      @text_color = value
      @refreshBitmap = true
      refresh
    end
  end

  def pokemon=(value)
    @pokemon = value
    @pkmnsprite.pokemon = value if @pkmnsprite && !@pkmnsprite.disposed?
    @helditemsprite.pokemon = value if @helditemsprite && !@helditemsprite.disposed?
    @refreshBitmap = true
    refresh
  end

  def selected=(value)
    if @selected != value
      @selected = value
      refresh
    end
  end

  def preselected=(value)
    if @preselected != value
      @preselected = value
      refresh
    end
  end

  def switching=(value)
    if @switching != value
      @switching = value
      refresh
    end
  end

  def hp; return @pokemon.hp; end

  def refresh
    return if disposed?
    return if @refreshing
    @refreshing = true
    if @panelbgsprite && !@panelbgsprite.disposed?
      if self.selected
        if self.preselected;     @panelbgsprite.changeBitmap("swapsel2")
        elsif @switching;        @panelbgsprite.changeBitmap("swapsel")
        elsif @pokemon.fainted?; @panelbgsprite.changeBitmap("faintedsel")
        else;                    @panelbgsprite.changeBitmap("APTOsel")
        end
      else
        if self.preselected;     @panelbgsprite.changeBitmap("swap")
        elsif @pokemon.fainted?; @panelbgsprite.changeBitmap("fainted")
        else;                    @panelbgsprite.changeBitmap("APTO")
        end
      end
      @panelbgsprite.x     = self.x
      @panelbgsprite.y     = self.y
      @panelbgsprite.color = self.color
    end
    if @hpbgsprite && !@hpbgsprite.disposed?
      @hpbgsprite.visible = !@pokemon.egg?
      if @hpbgsprite.visible
        if self.preselected || (self.selected); @hpbgsprite.changeBitmap("cursor")
        else;                                   @hpbgsprite.changeBitmap("APTO")
        end
        @hpbgsprite.x     = self.x + 6
        @hpbgsprite.y     = self.y + 60
        @hpbgsprite.color = self.color
      end
    end
    if @pkmnsprite && !@pkmnsprite.disposed?
      @pkmnsprite.x        = self.x + 32
      @pkmnsprite.y        = self.y + 36
      @pkmnsprite.color    = self.color
      @pkmnsprite.selected = self.selected
    end
    if @helditemsprite&.visible && !@helditemsprite.disposed?
      @helditemsprite.x     = self.x + 66
      @helditemsprite.y     = self.y + 30
      @helditemsprite.color = self.color
    end
    if @overlaysprite && !@overlaysprite.disposed?
      @overlaysprite.x     = self.x
      @overlaysprite.y     = self.y
      @overlaysprite.color = self.color
    end
    if @refreshBitmap
      @refreshBitmap = false
      @overlaysprite.bitmap.clear if @overlaysprite.bitmap
      baseColor   = Color.new(248, 248, 248)
      outlineColor = Color.new(0, 0, 0)
      pbSetSystemFont(@overlaysprite.bitmap)
      pbSetSmallFont(@overlaysprite.bitmap)
      textpos = []
      if !@pokemon.egg?
        if !@text || @text.length == 0
          # Draw HP numbers
          textpos.push([sprintf("% 3d /% 3d", @pokemon.hp, @pokemon.totalhp), 52, 76, 2, baseColor, Color.new(40, 40, 40), true, Graphics.width]) if !@text || @text.length == 0
        end
          # Draw HP bar
          if @pokemon.hp > 0
            w = @pokemon.hp * 94 / @pokemon.totalhp.to_f
            w = 1 if w < 1
            w = ((w / 2).round) * 2
            hpzone = 0
            hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
            hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
            hprect = Rect.new(0, hpzone * 8, w, 8)
            @overlaysprite.bitmap.blt(8, 62, @hpbar.bitmap, hprect)
          end
          # Draw status
          status = -1
          if @pokemon.fainted?
            status = GameData::Status.count - 1
          elsif @pokemon.status != :NONE
            status = GameData::Status.get(@pokemon.status).icon_position
          end
          if status >= 0
            statusrect = Rect.new(0, 16 * status, 44, 16)
            @overlaysprite.bitmap.blt(48, 26, @statuses.bitmap, statusrect)
          end
        # Draw Pokerus icon
          if BagScreenWiInParty::PKRSICON == true
            if @pokemon.pokerusStage == 1
              @overlaysprite.bitmap.blt(64, 44, @pokerus.bitmap, Rect.new(0, 0, 16, 16))
            elsif @pokemon.pokerusStage == 2
              @overlaysprite.bitmap.blt(64, 44, @pokerus.bitmap, Rect.new(0, 16, 16, 16))
            end
          end
        # Draw gender symbol
        if @pokemon.male?
          textpos.push([_INTL("♂"), 92, 8, 0, Color.new(116, 162, 237), outlineColor, true, Graphics.width])
        elsif @pokemon.female?
          textpos.push([_INTL("♀"), 92, 8, 0, Color.new(237, 116, 140), outlineColor, true, Graphics.width])
        end
        # Draw shiny icon
        if @pokemon.shiny? && BagScreenWiInParty::SHINYICON == true
          pbDrawImagePositions(@overlaysprite.bitmap,
                               [["Graphics/UI/Bag Screen with Party/shiny", 84, 44, 0, 0, 16, 16]])
        end
      end
      pbDrawTextPositions(@overlaysprite.bitmap, textpos)
      # Draw level text
      if !@pokemon.egg?
        pbDrawImagePositions(@overlaysprite.bitmap,
                             [["Graphics/UI/Bag Screen with Party/overlay_lv", 34, 10, 0, 0, 22, 14]])
        pbSetSmallFont(@overlaysprite.bitmap)
        pbDrawTextPositions(@overlaysprite.bitmap,
                            [[@pokemon.level.to_s, 58, 8, 0, baseColor, outlineColor, true, Graphics.width]])
      end
      # Draw annotation text
      if @text && @text.length > 0
        pbSetSystemFont(@overlaysprite.bitmap)
        pbSetSmallFont(@overlaysprite.bitmap)
        if @text_color
          pbDrawTextPositions(@overlaysprite.bitmap,
                              [[@text,56,76,2,Color.new(90,90,90),Color.new(40, 40, 40), true, Graphics.width]])
        elsif @text_color == false
          pbDrawTextPositions(@overlaysprite.bitmap,[
                              [@text,56,76,2,baseColor,Color.new(140,140,140),true,Graphics.width]])
        else
          pbDrawTextPositions(@overlaysprite.bitmap,[
                              [@text,56,76,2,baseColor,Color.new(40,40,40),true,Graphics.width]])
        end
      end
    end
    @refreshing = false
  end

  def update
    super
    @panelbgsprite.update if @panelbgsprite && !@panelbgsprite.disposed?
    @hpbgsprite.update if @hpbgsprite && !@hpbgsprite.disposed?
    @pkmnsprite.update if @pkmnsprite && !@pkmnsprite.disposed?
    @helditemsprite.update if @helditemsprite && !@helditemsprite.disposed?
  end
end

#===============================================================================
# Bag visuals
#===============================================================================
class PokemonBag_Scene
  ITEMLISTBASECOLOR      = Color.new(240, 240, 250)
  ITEMLISTSHADOWCOLOR    = Color.new(107, 107, 117)
  ITEMTEXTBASECOLOR      = Color.new(239, 239, 239)
  ITEMTEXTSHADOWCOLOR    = ITEMLISTSHADOWCOLOR
  POCKETNAMEBASECOLOR    = Color.new(255, 255, 255)
  POCKETNAMEOUTLINECOLOR = Color.new(78, 83, 100)
  ITEMSVISIBLE           = 6

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    @sprites["panorama"].x  = 0 if @sprites["panorama"].x == - 56
    @sprites["panorama"].x -= 2 if BagScreenWiInParty::PANORAMA == true
  end

  def pbStartScene(bag, party = $player.party, choosing = false, filterproc = nil, resetpocket = true)
    @viewport   = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @bag        = bag
    @choosing   = choosing
    @filterproc = filterproc
    @party      = party
    
    pbRefreshFilter
    lastpocket = @bag.last_viewed_pocket
    numfilledpockets = @bag.pockets.length - 1
    if @choosing
      numfilledpockets = 0
      if @filterlist.nil?
        (1...@bag.pockets.length).each do |i|
          numfilledpockets += 1 if @bag.pockets[i].length > 0
        end
      else
        (1...@bag.pockets.length).each do |i|
          numfilledpockets += 1 if @filterlist[i].length > 0
        end
      end
      lastpocket = (resetpocket) ? 1 : @bag.last_viewed_pocket
      if (@filterlist && @filterlist[lastpocket].length == 0) ||
         (!@filterlist && @bag.pockets[lastpocket].length == 0)
        (1...@bag.pockets.length).each do |i|
          if @filterlist && @filterlist[i].length > 0
            lastpocket = i
            break
          elsif !@filterlist && @bag.pockets[i].length > 0
            lastpocket = i
            break
          end
        end
      end
    end
    @bag.last_viewed_pocket = lastpocket
    
    @sliderbitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Bag Screen with Party/icon_slider"))
    @pocketbitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Bag Screen with Party/icon_pocket"))
    
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap("Graphics/UI/Bag Screen with Party/bg")
    @sprites["gradient"] = IconSprite.new(0, 0, @viewport)
    @sprites["gradient"].setBitmap("Graphics/UI/Bag Screen with Party/grad")
    @sprites["panorama"] = IconSprite.new(0, 0, @viewport)
    @sprites["panorama"].setBitmap("Graphics/UI/Bag Screen with Party/panorama")
    
    if BagScreenWiInParty::BGSTYLE == 1 # BW Style
      if $player.female?
        @sprites["background"].color = Color.new(231, 101, 137)
        @sprites["gradient"].color = Color.new(243, 133, 169)
        @sprites["panorama"].color = Color.new(232, 62, 113)
      else
        @sprites["background"].color = Color.new(101, 230, 255)
        @sprites["gradient"].color = Color.new(37, 129, 255)
        @sprites["panorama"].color = Color.new(37, 136, 255)
      end
    elsif BagScreenWiInParty::BGSTYLE == 2 # HGSS Style
      pbPocketColor
    end
    @sprites["ui1"] = IconSprite.new(0, 0, @viewport)
    @sprites["ui1"].setBitmap("Graphics/UI/Bag Screen with Party/ui1")
    @sprites["ui2"] = IconSprite.new(0, 0, @viewport)
    @sprites["ui2"].setBitmap("Graphics/UI/Bag Screen with Party/ui2")
    
    for i in 0...Settings::MAX_PARTY_SIZE
      if @party[i]
        @sprites["pokemon#{i}"] = PokemonBagPartyPanel.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = PokemonBagPartyBlankPanel.new(@party[i], i, @viewport)
      end
    end
    
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    rbvar = 0
    
    @sprites["pocketicon"] = BitmapSprite.new(130, 52, @viewport)
    @sprites["pocketicon"].x = 372
    @sprites["pocketicon"].y = 0
    @sprites["currentpocket"] = IconSprite.new(0, 0, @viewport)
    @sprites["currentpocket"].setBitmap("Graphics/UI/Bag Screen with Party/icon_pocket")
    @sprites["currentpocket"].x = 372
    @sprites["currentpocket"].y = 26
    @sprites["currentpocket"].src_rect = Rect.new(0, 0, 28, 28)
    
    @sprites["itemlist"] = Window_PokemonBag.new(@bag, @filterlist, lastpocket, 204, 40, 314, 72 + ITEMSVISIBLE * 32)
    @sprites["itemlist"].viewport    = @viewport
    @sprites["itemlist"].pocket      = lastpocket
    @sprites["itemlist"].index       = @bag.last_viewed_index(lastpocket)
    @sprites["itemlist"].baseColor   = ITEMLISTBASECOLOR
    @sprites["itemlist"].shadowColor = ITEMLISTSHADOWCOLOR
    @sprites["itemicon"] = ItemIconSprite.new(48, Graphics.height - 46, nil, @viewport)
    @sprites["itemtext"] = Window_UnformattedTextPokemon.newWithSize(
      "", 72, 274, Graphics.width - 72 - 24, 128, @viewport
    )
    @sprites["itemtext"].baseColor   = ITEMTEXTBASECOLOR
    @sprites["itemtext"].shadowColor = ITEMTEXTSHADOWCOLOR
    @sprites["itemtext"].visible     = true
    @sprites["itemtext"].windowskin  = nil
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.new("")
    @sprites["helpwindow"].visible  = false
    @sprites["helpwindow"].viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"], 1)
    @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible  = false
    @sprites["msgwindow"].viewport = @viewport
    @sprites["msgwindow"].letterbyletter = true
    pbBottomLeftLines(@sprites["msgwindow"], 2)
    
    pbUpdateAnnotation
    
    pbDeactivateWindows(@sprites)
    pbRefresh
    pbFadeInAndShow(@sprites)
    $game_temp.bag_scene = self if $bag.has?(:EGGHATCHER)
  end

  def pbPocketColor
    case @bag.last_viewed_pocket
    when 1
      @sprites["background"].color = Color.new(233, 152, 189)
      @sprites["gradient"].color = Color.new(255, 37, 187)
      @sprites["panorama"].color = Color.new(213, 89, 141)
    when 2
      @sprites["background"].color = Color.new(233, 161, 152)
      @sprites["gradient"].color = Color.new(255, 134, 37)
      @sprites["panorama"].color = Color.new(224, 112, 56)
    when 3
      @sprites["background"].color = Color.new(233, 197, 152)
      @sprites["gradient"].color = Color.new(255, 177, 37)
      @sprites["panorama"].color = Color.new(200, 136, 32)
    when 4
      @sprites["background"].color = Color.new(216, 233, 152)
      @sprites["gradient"].color = Color.new(194, 255, 37)
      @sprites["panorama"].color = Color.new(128, 168, 32)
    when 5
      @sprites["background"].color = Color.new(175, 233, 152)
      @sprites["gradient"].color = Color.new(78, 255, 37)
      @sprites["panorama"].color = Color.new(32, 160, 72)
    when 6
      @sprites["background"].color = Color.new(152, 220, 233)
      @sprites["gradient"].color = Color.new(37, 212, 255)
      @sprites["panorama"].color = Color.new(24, 144, 176)
    when 7
      @sprites["background"].color = Color.new(152, 187, 233)
      @sprites["gradient"].color = Color.new(37, 125, 255)
      @sprites["panorama"].color = Color.new(48, 112, 224)
    when 8
      @sprites["background"].color = Color.new(178, 152, 233)
      @sprites["gradient"].color = Color.new(145, 37, 255)
      @sprites["panorama"].color = Color.new(144, 72, 216)
    end
  end
  
  def pbFadeOutScene
    @oldsprites = pbFadeOutAndHide(@sprites)
    @oldtext = []
    for i in 0...Settings::MAX_PARTY_SIZE
      @oldtext.push(@sprites["pokemon#{i}"].text)
      @sprites["pokemon#{i}"].dispose
    end
  end
  
  def pbFadeInScene
    for i in 0...Settings::MAX_PARTY_SIZE
      if @party[i]
        @sprites["pokemon#{i}"] = PokemonBagPartyPanel.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = PokemonBagPartyBlankPanel.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = @oldtext[i]
    end
    @oldtext = nil
    pbFadeInAndShow(@sprites, @oldsprites)
    @oldsprites = nil
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) if !@oldsprites
    @oldsprites = nil
    dispose
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @sliderbitmap.dispose
    @pocketbitmap.dispose
    @viewport.dispose
  end

  def pbDisplay(text, brief = false)
    @sprites["msgwindow"].text    = text
    @sprites["msgwindow"].visible = true
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["msgwindow"].busy?
        if Input.trigger?(Input::USE)
          pbPlayDecisionSE if @sprites["msgwindow"].pausing?
          @sprites["msgwindow"].resume
        end
      elsif Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
        break
      end
    end
    @sprites["msgwindow"].visible = false
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end
  
  def pbConfirm(msg)
    UIHelper.pbConfirm(@sprites["msgwindow"], msg) { pbUpdate }
  end

  def pbChooseNumber(helptext, maximum, initnum = 1)
    return UIHelper.pbChooseNumber(@sprites["helpwindow"], helptext, maximum, initnum) { pbUpdate }
  end

  def pbShowCommands(helptext, commands, index = 0)
    return UIHelper.pbShowCommands(@sprites["helpwindow"], helptext, commands, index) { pbUpdate }
  end

  def pbRefresh
    # Draw the pocket icons
    pocketX  = []; incrementX = 0 # Fixes pockets' X coordinates
    @bag.pockets.length.times do |i|
      break if pocketX.length == @bag.pockets.length
      pocketX.push(incrementX)
      incrementX += 2 if i.odd?
    end
    pocketAcc = @sprites["itemlist"].pocket - 1 # Current pocket
    @sprites["pocketicon"].bitmap.clear
    (1...@bag.pockets.length).each do |i|
      pocketValue = i - 1
      @sprites["pocketicon"].bitmap.blt(
        (i - 1) * 14 + pocketX[pocketValue], (i % 2) * 26, @pocketbitmap.bitmap,
        Rect.new((i - 1) * 28, 0, 28, 28)) if pocketValue != pocketAcc # Unblocked icons
    end
    if @choosing && @filterlist
      (1...@bag.pockets.length).each do |i|
        next if @filterlist[i].length > 0
        pocketValue = i - 1
        @sprites["pocketicon"].bitmap.blt(
          (i - 1) * 14 + pocketX[pocketValue], (i % 2) * 26, @pocketbitmap.bitmap,
          Rect.new((i - 1) * 28, 56, 28, 28)) # Blocked icons
      end
    end
    @sprites["currentpocket"].x = 372 + ((pocketAcc) * 14) + pocketX[pocketAcc]
    @sprites["currentpocket"].y = 26 - (((pocketAcc) % 2) * 26)
    @sprites["currentpocket"].src_rect = Rect.new((pocketAcc) * 28, 28, 28, 28) # Current pocket icon
    # Refresh stuff
    @sprites["itemlist"].refresh
    pbRefreshIndexChanged
    pbRefreshParty
    pbPocketColor if BagScreenWiInParty::BGSTYLE == 2
  end
  
  def pbRefreshParty
    for i in 0...Settings::MAX_PARTY_SIZE
      if @party[i]
        @sprites["pokemon#{i}"].pokemon = @party[i]
      else
      end
    end
  end
  
  def pbRefreshIndexChanged
    itemlist = @sprites["itemlist"]
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Draw the pocket name
    pbDrawTextPositions(
      overlay,
      [[PokemonBag.pocket_names[@bag.last_viewed_pocket - 1], 297, 18, :center, POCKETNAMEBASECOLOR, POCKETNAMEOUTLINECOLOR, true, Graphics.width]]
    )
    # Draw slider arrows
    showslider = false
    if itemlist.top_row > 0
      overlay.blt(356, 16, @sliderbitmap.bitmap, Rect.new(0, 0, 36, 38))
      showslider = true
    end
    if itemlist.top_item + itemlist.page_item_max < itemlist.itemCount
      overlay.blt(356, 228, @sliderbitmap.bitmap, Rect.new(0, 38, 36, 38))
      showslider = true
    end
    # Draw slider box
    if showslider
      sliderheight = 174
      boxheight = (sliderheight * itemlist.page_row_max / itemlist.row_max).floor
      boxheight += [(sliderheight - boxheight) / 2, sliderheight / 6].min
      boxheight = [boxheight.floor, 38].max
      y = 80
      y += ((sliderheight - boxheight) * itemlist.top_row / (itemlist.row_max - itemlist.page_row_max)).floor
      overlay.blt(484, y, @sliderbitmap.bitmap, Rect.new(36, 0, 36, 4))
      i = 0
      while i * 16 < boxheight - 4 - 18
        height = [boxheight - 4 - 18 - (i * 16), 16].min
        overlay.blt(484, y + 4 + (i * 16), @sliderbitmap.bitmap, Rect.new(36, 4, 36, height))
        i += 1
      end
      overlay.blt(484, y + boxheight - 18, @sliderbitmap.bitmap, Rect.new(36, 20, 36, 18))
    end
    # Set the selected item's icon
    @sprites["itemicon"].item = itemlist.item
    # Set the selected item's description
    @sprites["itemtext"].text =
      (itemlist.item) ? GameData::Item.get(itemlist.item).description : _INTL("Cerrar Mochila.")
  end

  def pbRefreshFilter
    @filterlist = nil
    return if !@choosing
    return if @filterproc.nil?
    @filterlist = []
    (1...@bag.pockets.length).each do |i|
      @filterlist[i] = []
      @bag.pockets[i].length.times do |j|
        @filterlist[i].push(j) if @filterproc.call(@bag.pockets[i][j][0])
      end
    end
  end

  def pbHardRefresh
    oldtext      = []
    lastselected = -1
    for i in 0...Settings::MAX_PARTY_SIZE
      if @sprites["pokemon#{i}"].respond_to?(:text)
        oldtext.push(@sprites["pokemon#{i}"].text)
      end
      lastselected = i if @sprites["pokemon#{i}"].selected
      @sprites["pokemon#{i}"].dispose
    end
    lastselected = @party.length - 1 if lastselected >= @party.length
    lastselected = 0 if lastselected < 0
    for i in 0...Settings::MAX_PARTY_SIZE
      if @party[i]
        @sprites["pokemon#{i}"] = PokemonBagPartyPanel.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = PokemonBagPartyBlankPanel.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = oldtext[i] if oldtext[i]
    end
    pbSelect(lastselected)
  end

  def pbRefreshSingle(i)
    sprite = @sprites["pokemon#{i}"]
    if sprite
      if sprite.is_a?(PokemonBagPartyPanel)
        sprite.pokemon = sprite.pokemon
      else
        sprite.refresh
      end
    end
  end
  
  def pbUpdateAnnotation
    itemwindow = @sprites["itemlist"]
    item       = itemwindow.item
    itm        = GameData::Item.get(item) if item
    if @bag.last_viewed_pocket == 1 && item #Items Pocket
      annotations = nil
      annotations = []
      color_annotations=[]
      if itm.is_evolution_stone?
        for i in $player.party
          elig = i.check_evolution_on_use_item(itm)
          annotations.push((elig) ? _INTL("APTO") : _INTL("NO APTO"))
          color_annotations.push((elig) ? nil : true)
        end
      else
        for i in 0...Settings::MAX_PARTY_SIZE
          @sprites["pokemon#{i}"].text = annotations[i] if  annotations
        end
      end
      for i in 0...Settings::MAX_PARTY_SIZE
        @sprites["pokemon#{i}"].text = annotations[i] if  annotations
      end
    elsif @bag.last_viewed_pocket == 4 && item #TMs Pocket
      annotations = nil
      annotations = []
      color_annotations=[]
      if itm.is_machine?
        machine = itm.move
        move = GameData::Move.get(machine).id
        movelist = nil
        if movelist!=nil && movelist.is_a?(Array)
          for i in 0...movelist.length
            movelist[i] = GameData::Move.get(movelist[i]).id
          end
        end
        $player.party.each_with_index do |pkmn, i|
          if pkmn.egg?
            annotations[i] = _INTL("NO APTO")
            color_annotations[i] = nil
          elsif pkmn.hasMove?(move)
            annotations[i] = _INTL("APRENDIDO")
            color_annotations[i] = false
          else
            species = pkmn.species
            if movelist && movelist.any? { |j| j == species }
              # Checked data from movelist given in parameter
              annotations[i] = _INTL("APTO")
              color_annotations[i] = nil
            elsif pkmn.compatible_with_move?(move)
              # Checked data from Pokémon's tutor moves in pokemon.txt
              annotations[i] = _INTL("APTO")
              color_annotations[i] = nil
            else
              annotations[i] = _INTL("NO APTO")
              color_annotations[i] = true
            end
          end
        end
      else
        for i in @party
          annotations.push((elig) ? _INTL("APTO") : _INTL("NO APTO"))
          color_annotations.push((elig) ? nil : true)
        end
      end
      for i in 0...Settings::MAX_PARTY_SIZE
        @sprites["pokemon#{i}"].text = annotations[i] if annotations
        @sprites["pokemon#{i}"].text_color = color_annotations[i] if annotations
      end
    else #Others, only show HP
      for i in 0...Settings::MAX_PARTY_SIZE
        @sprites["pokemon#{i}"].text = nil if @sprites["pokemon#{i}"].text 
        @sprites["pokemon#{i}"].text_color = color_annotations[i] if @sprites["pokemon#{i}"].text 
      end
    end
  end
      
  # Called when the item screen wants an item to be chosen from the screen
  def pbChooseItem
    @sprites["helpwindow"].visible = false
    itemwindow = @sprites["itemlist"]
    thispocket = @bag.pockets[itemwindow.pocket]
    swapinitialpos = -1
    pbActivateWindow(@sprites, "itemlist") {
      loop do
        oldindex = itemwindow.index
        Graphics.update
        Input.update
        pbUpdate
        pbUpdateAnnotation
        if itemwindow.sorting && itemwindow.index >= thispocket.length
          itemwindow.index = (oldindex == thispocket.length - 1) ? 0 : thispocket.length - 1
        end
        if itemwindow.index != oldindex
          # Move the item being switched
          if itemwindow.sorting
            thispocket.insert(itemwindow.index, thispocket.delete_at(oldindex))
          end
          # Update selected item for current pocket
          @bag.set_last_viewed_index(itemwindow.pocket, itemwindow.index)
          pbRefresh
        end
        if itemwindow.sorting
          if Input.trigger?(Input::ACTION) ||
             Input.trigger?(Input::USE)
            itemwindow.sorting = false
            pbPlayDecisionSE
            pbRefresh
          elsif Input.trigger?(Input::BACK)
            thispocket.insert(swapinitialpos, thispocket.delete_at(itemwindow.index))
            itemwindow.index = swapinitialpos
            itemwindow.sorting = false
            pbPlayCancelSE
            pbRefresh
          end
        else
          # Plays SE when scrolling the item list
          if Input.repeat?(Input::UP) && thispocket.length   > 0 || 
             Input.repeat?(Input::DOWN) && thispocket.length > 0
            pbSEPlay("GUI bag cursor") if itemwindow.index != oldindex
          end
          # Change pockets
          if Input.trigger?(Input::LEFT)
            newpocket = itemwindow.pocket
            loop do
              newpocket = (newpocket == 1) ? PokemonBag.pocket_count : newpocket - 1
              break if !@choosing || newpocket == itemwindow.pocket
              if @filterlist
                break if @filterlist[newpocket].length > 0
              elsif @bag.pockets[newpocket].length > 0
                break
              end
            end
            if itemwindow.pocket != newpocket
              itemwindow.pocket = newpocket
              @bag.last_viewed_pocket = itemwindow.pocket
              thispocket = @bag.pockets[itemwindow.pocket]
              pbRefresh
              pbSEPlay("GUI bag pocket")
              @sprites["currentpocket"].x -= 2
              pbWait(0.1) {pbUpdate}
              @sprites["currentpocket"].x += 2
            end
          elsif Input.trigger?(Input::RIGHT)
            newpocket = itemwindow.pocket
            loop do
              newpocket = (newpocket == PokemonBag.pocket_count) ? 1 : newpocket + 1
              break if !@choosing || newpocket == itemwindow.pocket
              if @filterlist
                break if @filterlist[newpocket].length > 0
              elsif @bag.pockets[newpocket].length > 0
                break
              end
            end
            if itemwindow.pocket != newpocket
              itemwindow.pocket = newpocket
              @bag.last_viewed_pocket = itemwindow.pocket
              thispocket = @bag.pockets[itemwindow.pocket]
              pbRefresh
              pbSEPlay("GUI bag pocket")
              @sprites["currentpocket"].x += 2
              pbWait(0.1) {pbUpdate}
              @sprites["currentpocket"].x -= 2
            end
          elsif Input.trigger?(Input::SPECIAL)   # Checking party
            if $player.pokemon_count == 0
              pbMessage(_INTL("No hay Pokémon."))
            else
              pbSEPlay("GUI storage show party panel")
              itemwindow.party2sel = true
              pbRefresh
              pbDeactivateWindows(@sprites){pbChoosePoke(3, false)}
              pbRefresh
            end
          elsif Input.trigger?(Input::ACTION)   # Start switching the selected item
            if !@choosing && thispocket.length > 1 && itemwindow.index < thispocket.length &&
               !Settings::BAG_POCKET_AUTO_SORT[itemwindow.pocket - 1]
              itemwindow.sorting = true
              swapinitialpos = itemwindow.index
              pbPlayDecisionSE
              pbRefresh
            end
          elsif Input.trigger?(Input::BACK)   # Cancel the item screen
            pbPlayCloseMenuSE
            return nil
          elsif Input.trigger?(Input::USE)   # Choose selected item
            (itemwindow.item) ? pbPlayDecisionSE : pbPlayCloseMenuSE
            return itemwindow.item
          end
        end
      end
    }
  end

  def pbSetHelpText(helptext)
    helpwindow = @sprites["helpwindow"]
    pbBottomLeftLines(helpwindow, 1)
    helpwindow.text = helptext
    helpwindow.width = 398
    helpwindow.visible = true
  end

  def pbChangeSelection(key,currentsel)
    numsprites = @party.length - 1
    case key
    when Input::LEFT
      begin
        currentsel -= 1
      end while currentsel >= 0 && currentsel < @party.length && !@party[currentsel]
      if currentsel >= @party.length && currentsel < Settings::MAX_PARTY_SIZE
        currentsel = @party.length - 1
      end
      currentsel = numsprites if currentsel < 0 || currentsel > numsprites
    when Input::RIGHT
      begin
        currentsel += 1
      end while currentsel < @party.length && !@party[currentsel]
      currentsel = 0 if currentsel == @party.length
    when Input::UP
      if currentsel > numsprites
        currentsel -= 1
        while currentsel > 0 && currentsel < numsprites && !@party[currentsel]
          currentsel -= 1
        end 
      else
        begin
          currentsel -= 2
        end while currentsel > 0 && !@party[currentsel]
      end
      if currentsel > numsprites && currentsel < numsprites
        currentsel = numsprites
      end
      currentsel = numsprites if currentsel < 0
    when Input::DOWN
      if currentsel >= Settings::MAX_PARTY_SIZE - 1
        currentsel += 1
      else
        currentsel += 2
        currentsel = Settings::MAX_PARTY_SIZE if currentsel < Settings::MAX_PARTY_SIZE && !@party[currentsel]
      end
      if currentsel >= @party.length && currentsel < Settings::MAX_PARTY_SIZE
        currentsel = Settings::MAX_PARTY_SIZE
      elsif currentsel > numsprites
        currentsel = 0
      end
    end
    return currentsel
  end
  
  def pbChangeCursor(number)
    # 1 for using/giving an item to a Pokémon; 2 for exiting; 3 for interacting
    itemwindow = @sprites["itemlist"]
    if number == 1
      itemwindow.party1sel = true
    elsif number == 2
      itemwindow.party1sel = false
      itemwindow.party2sel = false
    elsif number == 3
      itemwindow.party2sel = true
    end
    pbRefresh
  end
  
  def pbChoosePoke(option, switching = false)
    # 0 to choose a Pokémon; 1 to hold an item; 2 to use an item; 3 to interact; 4 to switch party items
    for i in 0...Settings::MAX_PARTY_SIZE
      @sprites["pokemon#{i}"].preselected = (switching && i == @activecmd)
      @sprites["pokemon#{i}"].switching   = switching
    end
    @sprites["pokemon#{@activecmd}"].selected = false if switching
    @activecmd = 0
    for i in 0...Settings::MAX_PARTY_SIZE
      @sprites["pokemon#{i}"].selected = (i == @activecmd)
    end
    itemwindow = @sprites["itemlist"]
    item = itemwindow.item
    if option == 3 || option == 4
      pbChangeCursor(3)
    else
      pbChangeCursor(1)
    end
    loop do
      Graphics.update
      Input.update
      pbUpdate
      oldsel = @activecmd
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN) && @party.length > 2
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP) && @party.length > 2
      if key >= 0 && @party.length > 1
        @activecmd = pbChangeSelection(key, @activecmd)
      end
      if @activecmd != oldsel   # Changing selection
        pbPlayCursorSE
        numsprites = Settings::MAX_PARTY_SIZE
        for i in 0...numsprites
          @sprites["pokemon#{i}"].selected = (i == @activecmd)
        end
      end
      if Input.trigger?(Input::USE)
        pkmn = @party[@activecmd]
        if option == 0 # Choose
          return @activecmd
        elsif option == 1 # Hold
          if @activecmd >= 0
            ret = pbGiveItemToPokemon(item, @party[@activecmd], self, @activecmd)
            pbChangeCursor(2)
            @sprites["pokemon#{@activecmd}"].selected = false
            break
          end
        elsif option == 2 # Use
          ret = pbBagUseItem(@bag, item, PokemonBagScreen, self, @activecmd)
          pbRefresh; pbUpdateAnnotation
          if !$bag.has?(item)
            @sprites["pokemon#{@activecmd}"].selected = false
            pbChangeCursor(2)
            break
          end
        elsif option == 3 # Interaction
          pbPlayDecisionSE
          loop do
            cmdSummary     = -1
            cmdTake        = -1 
            cmdMove        = -1
            commands = []
            # Generate command list
            commands[cmdSummary = commands.length]       = _INTL("Datos")
            commands[cmdTake = commands.length]          = _INTL("Coger Objeto") if pkmn.hasItem?
            commands[cmdMove = commands.length]          = _INTL("Mover Objeto") if pkmn.hasItem? && !GameData::Item.get(pkmn.item).is_mail?
            commands[commands.length]                    = _INTL("Cancelar")
            # Show commands generated above
            if pkmn.hasItem?
              item = pkmn.item
              itemname = item.name
              # = (itemname.starts_with_vowel?) ? "an" : "a"
              command = pbShowCommands(_INTL("{1} tiene equipado {2}.", pkmn.name, itemname), commands)
            else
              command = pbShowCommands(_INTL("Has elegido a {1}.", pkmn.name), commands)
            end
            if cmdSummary >= 0 && command == cmdSummary   # Summary
              pbSummary(@activecmd)
            elsif cmdTake >= 0 && command == cmdTake && pkmn.hasItem?  # Take item
              if pbTakeItemFromPokemon(pkmn, self)
                pbRefresh
              end
              break
            elsif cmdMove >= 0 && command == cmdMove && pkmn.hasItem? && !GameData::Item.get(pkmn.item).is_mail?  # Move item
              oldpkmn = pkmn
              loop do
                pbPreSelect(oldpkmn)
                newpkmn = pbChoosePoke(4, true)
                if newpkmn < 0
                  pbClearSwitching
                  break 
                end
                newpkmn = @party[newpkmn]
                if newpkmn == oldpkmn
                  pbClearSwitching
                  break 
                end
                if newpkmn.egg?
                  pbDisplay(_INTL("Los Huevos no pueden llevar objetos."))
                elsif !newpkmn.hasItem?
                  newpkmn.item = item
                  oldpkmn.item = nil
                  pbClearSwitching; pbRefresh
                  pbDisplay(_INTL("Has equipado {1} a {2}.", newpkmn.name, itemname))
                  break
                elsif GameData::Item.get(newpkmn.item).is_mail?
                  pbDisplay(_INTL("Debes quitarle la carta a {1} para equiparle un objeto.", newpkmn.name))
                else
                  newitem = newpkmn.item
                  newitemname = newitem.name
                  if newitem == :LEFTOVERS
                    pbDisplay(_INTL("{1} ya tiene equipado unos {2}.\1", newpkmn.name, newitemname))
                  elsif newitemname.starts_with_vowel?
                    pbDisplay(_INTL("{1} ya tiene equipado {2}.\1", newpkmn.name, newitemname))
                  else
                    pbDisplay(_INTL("{1} ya tiene equipado {2}.\1", newpkmn.name, newitemname))
                  end
                  if pbConfirm(_INTL("¿Quieres intercambiar los dos objetos?"))
                    newpkmn.item = item
                    oldpkmn.item = newitem
                    pbClearSwitching; pbRefresh
                    pbDisplay(_INTL("Has equipado {2} a {1}.", newpkmn.name, itemname))
                    pbDisplay(_INTL("Has equipado {2} a {1}.", oldpkmn.name, newitemname))
                  else
                    pbClearSwitching; pbRefresh
                  end
                  break
                end
              end
              break
            else
              break
            end
          end
        elsif option == 4 # Interaction for switching item
          return @activecmd
        end
      elsif Input.trigger?(Input::BACK)
        if option != 4
          pbSEPlay("GUI storage hide party panel")
          pbChangeCursor(2)
        else
          pbPlayCancelSE
        end
        if switching
          return -1
        elsif option == 0
          @sprites["pokemon#{@activecmd}"].selected = false
          return -1
        else
          @sprites["pokemon#{@activecmd}"].selected = false
          return
        end
      end
      break if ret == 2 && option == 2  # End screen
    end
  end
  
  def pbChoosePokemon(text = nil)
    # For fusing/unfusing Pokemon
    fusioncmd  = @activecmd
    @activecmd = 0
    for i in 0...Settings::MAX_PARTY_SIZE
      @sprites["pokemon#{i}"].selected = (i == @activecmd)
    end
    @sprites["pokemon#{fusioncmd}"].selected = true
    loop do
      Graphics.update
      Input.update
      pbUpdate
      oldsel = @activecmd
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN) && @party.length > 2
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP) && @party.length > 2
      if key >= 0 && @party.length > 1
        @activecmd = pbChangeSelection(key,@activecmd)
      end
      if @activecmd != oldsel   # Changing selection
        pbPlayCursorSE
        numsprites = Settings::MAX_PARTY_SIZE
        for i in 0...numsprites
          @sprites["pokemon#{i}"].selected = (i == @activecmd)
        end
        @sprites["pokemon#{fusioncmd}"].selected = true
      end
      if Input.trigger?(Input::USE)
        @sprites["pokemon#{fusioncmd}"].selected = false if fusioncmd != @activecmd
        return @activecmd
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        @sprites["pokemon#{fusioncmd}"].selected = false if fusioncmd != @activecmd
        return -1
      end
    end
  end
  
  def pbSummary(pkmnid, inbattle=false)
    oldsprites = pbFadeOutAndHide(@sprites)
    scene = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene,inbattle)
    screen.pbStartScreen(@party,pkmnid)
    yield if block_given?
    pbFadeInAndShow(@sprites,oldsprites)
  end

  def pbSelect(item)
    @activecmd = item
    numsprites = Settings::MAX_PARTY_SIZE
    for i in 0...numsprites
      @sprites["pokemon#{i}"].selected = (i == @activecmd)
    end
  end
  
  def pbPreSelect(item)
    @othercmd = item
  end

  def pbClearSwitching
    for i in 0...Settings::MAX_PARTY_SIZE
      @sprites["pokemon#{i}"].preselected = false
      @sprites["pokemon#{i}"].switching   = false
    end
  end
  
  def pbChooseMove(pokemon, helptext, index = 0)
    movenames = []
    pokemon.moves.each do |i|
      next if !i || !i.id
      if i.total_pp <= 0
        movenames.push(_INTL("{1} (PP: ---)", i.name))
      else
        movenames.push(_INTL("{1} (PP: {2}/{3})", i.name, i.pp, i.total_pp))
      end
    end
    return pbShowCommands(helptext,movenames,index)
  end
end

#===============================================================================
# Bag mechanics
#===============================================================================
class PokemonBagScreen
  def initialize(scene, bag)
    @bag   = bag
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene(@bag, $player.party)
    item = nil
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      cmdRead     = -1
      cmdUse      = -1
      cmdRegister = -1
      cmdGive     = -1
      cmdToss     = -1
      cmdDebug    = -1
      commands = []
      # Generate command list
      commands[cmdRead = commands.length]       = _INTL("Leer") if itm.is_mail?
      if ItemHandlers.hasOutHandler(item) || (itm.is_machine? && $player.party.length > 0)
        if ItemHandlers.hasUseText(item)
          commands[cmdUse = commands.length]    = ItemHandlers.getUseText(item)
        else
          commands[cmdUse = commands.length]    = _INTL("Usar")
        end
      end
      commands[cmdGive = commands.length]       = _INTL("Dar") if $player.pokemon_party.length > 0 && itm.can_hold?
      commands[cmdToss = commands.length]       = _INTL("Tirar") if !itm.is_important? || $DEBUG
      if @bag.registered?(item)
        commands[cmdRegister = commands.length] = _INTL("No regis.")
      elsif pbCanRegisterItem?(item)
        commands[cmdRegister = commands.length] = _INTL("Registrar")
      end
      commands[cmdDebug = commands.length]      = _INTL("Debug") if $DEBUG
      commands[commands.length]                 = _INTL("Cancelar")
      # Show commands generated above
      itemname = itm.name
      command = @scene.pbShowCommands(_INTL("Has seleccionado {1}.", itemname), commands)
      if cmdRead >= 0 && command == cmdRead   # Read mail
        pbFadeOutIn {
          pbDisplayMail(Mail.new(item, "", ""))
        }
      elsif cmdUse >= 0 && command == cmdUse   # Use item
        useType = itm.field_use
        # ret: 0 = Item wasn't used; 1 = Item used; 2 = Close Bag to use in field
        if useType == 1 # Consumables
          pbSEPlay("GUI storage show party panel")
          ret = @scene.pbChoosePoke(2, false)
        elsif useType == 3 || useType == 4 || useType == 5 # TM, HM and TR
          machine = itm.move
          movename = GameData::Move.get(machine).name
          pbMessage(_INTL("\\se[PC access]Has seleccionado {1}.\1", itm.name)) {@scene.pbUpdate}
          if pbConfirmMessage(_INTL("¿Quieres enseñarle {1} a un Pokémon?", movename)) {@scene.pbUpdate}
            pbSEPlay("GUI storage show party panel")
            ret = @scene.pbChoosePoke(2, false)
          end
        else
          ret = pbUseItem(@bag, item, @scene)
        end
        break if ret == 2   # End screen
        @scene.pbRefresh
        next
      elsif cmdGive >= 0 && command == cmdGive   # Give item to Pokémon
        if $player.pokemon_count == 0
          @scene.pbDisplay(_INTL("No hay Pokémon."))
        elsif itm.is_important?
          @scene.pbDisplay(_INTL("No se puede equipar {1}.", itm.portion_name))
        else
          @scene.pbChoosePoke(1, false)
        end
      elsif cmdToss >= 0 && command == cmdToss   # Toss item
        qty = @bag.quantity(item)
        if qty > 1
          helptext = _INTL("¿Qué cantidad de {1} tirar?", itm.portion_name_plural)
          qty = @scene.pbChooseNumber(helptext, qty)
        end
        if qty > 0
          itemname = (qty > 1) ? itm.portion_name_plural : itm.portion_name
          if pbConfirm(_INTL("¿Seguro que quieres tirar {1} {2}?", qty, itemname))
            pbDisplay(_INTL("Has tirado {1} {2}.", qty, itemname))
            qty.times { @bag.remove(item) }
            @scene.pbRefresh
          end
        end
      elsif cmdRegister >= 0 && command == cmdRegister   # Register item
        if @bag.registered?(item)
          @bag.unregister(item)
        else
          @bag.register(item)
        end
        @scene.pbRefresh
      elsif cmdDebug >= 0 && command == cmdDebug   # Debug
        command = 0
        loop do
          command = @scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", itemname),
                                          [_INTL("Cambiar cantidad"),
                                           _INTL("Hacer Regalo Mist."),
                                           _INTL("Cancelar")], command)
          case command
          ### Cancel ###
          when -1, 2
            break
          ### Change quantity ###
          when 0
            qty = @bag.quantity(item)
            itemplural = itm.name_plural
            params = ChooseNumberParams.new
            params.setRange(0, Settings::BAG_MAX_PER_SLOT)
            params.setDefaultValue(qty)
            newqty = pbMessageChooseNumber(
              _INTL("Elige nueva cantidad de {1} (max. {2}).", itemplural, Settings::BAG_MAX_PER_SLOT), params
            ) { @scene.pbUpdate }
            if newqty > qty
              @bag.add(item, newqty - qty)
            elsif newqty < qty
              @bag.remove(item, qty - newqty)
            end
            @scene.pbRefresh
            break if newqty == 0
          ### Make Mystery Gift ###
          when 1
            pbCreateMysteryGift(1, item)
          end
        end
      end
    end
    ($game_temp.fly_destination) ? @scene.dispose : @scene.pbEndScene
    return item
  end

  def pbDisplay(text)
    @scene.pbDisplay(text)
  end

  def pbConfirm(text)
    return @scene.pbConfirm(text)
  end

  # UI logic for the item screen for choosing an item.
  def pbChooseItemScreen(proc = nil)
    oldlastpocket = @bag.last_viewed_pocket
    oldchoices = @bag.last_pocket_selections.clone
    $bag.reset_last_selections if proc
    @scene.pbStartScene(@bag, $player.party, true, proc)
    item = @scene.pbChooseItem
    @scene.pbEndScene
    @bag.last_viewed_pocket = oldlastpocket
    @bag.last_pocket_selections = oldchoices
    return item
  end

  # UI logic for withdrawing an item in the item storage screen.
  def pbWithdrawItemScreen
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    @scene.pbStartScene(storage)
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      qty = storage.quantity(item)
      if qty > 1 && !itm.is_important?
        qty = @scene.pbChooseNumber(_INTL("¿Cuántos quieres tirar?"), qty)
      end
      next if qty <= 0
      if @bag.can_add?(item, qty)
        if !storage.remove(item, qty)
          raise "No se pueden tirar objetos del almacenamiento"
        end
        if !@bag.add(item, qty)
          raise "No se pueden sacar objetos del almacenamiento"
        end
        @scene.pbRefresh
        dispqty = (itm.is_important?) ? 1 : qty
        itemname = (dispqty > 1) ? itm.portion_name_plural : itm.portion_name
        pbDisplay(_INTL("Has sacado {1} {2}.", dispqty, itemname))
      else
        pbDisplay(_INTL("No tienes más hueco en la Mochila."))
      end
    end
    @scene.pbEndScene
  end

  # UI logic for depositing an item in the item storage screen.
  def pbDepositItemScreen
    @scene.pbStartScene(@bag,$player.party)
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      qty = @bag.quantity(item)
      if qty > 1 && !itm.is_important?
        qty = @scene.pbChooseNumber(_INTL("¿Cuántos quieres dejar?"), qty)
      end
      if qty > 0
        if storage.can_add?(item, qty)
          if !@bag.remove(item, qty)
            raise "No se pueden eliminar objetos de la Mochila"
          end
          if !storage.add(item, qty)
            raise "No se pueden dejar obejtos en el almacenamiento"
          end
          @scene.pbRefresh
          dispqty  = (itm.is_important?) ? 1 : qty
          itemname = (dispqty > 1) ? itm.portion_name_plural : itm.portion_name
          pbDisplay(_INTL("Ha sdejado {1} {2}.", dispqty, itemname))
        else
          pbDisplay(_INTL("No hay espacio para almacenar objetos."))
        end
      end
    end
    @scene.pbEndScene
  end

  # UI logic for tossing an item in the item storage screen.
  def pbTossItemScreen
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    @scene.pbStartScene(storage)
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      if itm.is_important?
        @scene.pbDisplay(_INTL("¡Eso es muy importante para ser tirado!"))
        next
      end
      qty = storage.quantity(item)
      itemname       = itm.portion_name
      itemnameplural = itm.portion_name_plural
      if qty > 1
        qty = @scene.pbChooseNumber(_INTL("Cuántos {1} tirar?", itemnameplural), qty)
      end
      next if qty <= 0
      itemname = itemnameplural if qty > 1
      next if !pbConfirm(_INTL("¿Seguro que quieres tirar {1} {2}?", qty, itemname))
      if !storage.remove(item, qty)
        raise "No se pueden borrar objetos del almacenamiento"
      end
      @scene.pbRefresh
      pbDisplay(_INTL("Has tirado {1} {2}.", qty, itemname))
    end
    @scene.pbEndScene
  end
end

#=============================================================================
# New function for using an item
#=============================================================================
# @return [Integer] 0 = item wasn't used; 1 = item used; 2 = close Bag to use in field
def pbBagUseItem(bag, item, scene, screen, chosen, bagscene=nil)
  itm     = GameData::Item.get(item)
  useType = itm.field_use
  found   = false
  pkmn    = $player.party[chosen]
  if itm.is_machine?    # TM, HM or TR
    if $player.pokemon_count == 0
      pbMessage(_INTL("No hay Pokémon.")) { screen.pbUpdate }
      return 0
    end
    machine = itm.move
    return 0 if !machine
    movename = GameData::Move.get(machine).name
    move     = GameData::Move.get(machine).id
    movelist = nil; bymachine = false; oneusemachine = false
    if movelist != nil && movelist.is_a?(Array)
      for i in 0...movelist.length
        movelist[i] = GameData::Move.get(movelist[i]).id
      end
    end
    if pkmn.egg?
      pbMessage(_INTL("Los Huevos no pueden aprender movimientos.")) { screen.pbUpdate }
    elsif pkmn.shadowPokemon?
      pbMessage(_INTL("Los Pokémon Oscuros no pueden aprender movimientos.")) { screen.pbUpdate }
    elsif movelist && !movelist.any? { |j| j == pkmn.species }
      pbMessage(_INTL("{1} no puede aprender {2}.", pkmn.name, movename)) { screen.pbUpdate }
    elsif !pkmn.compatible_with_move?(move)
      pbMessage(_INTL("{1} no puede aprender {2}.", pkmn.name, movename)) { screen.pbUpdate }
    else
      if pbLearnMove(pkmn, move, false, bymachine) { screen.pbUpdate }
        pkmn.add_first_move(move) if oneusemachine
        bag.remove(itm) if itm.consumed_after_use?
      end
    end
    screen.pbRefresh; screen.pbUpdate
    return 1
  elsif useType == 1 # Item is usable on a Pokémon
    if $player.pokemon_count == 0
      pbMessage(_INTL("No hay Pokémon.")) { screen.pbUpdate }
      return 0
    end
    qty = 1
    ret = false
    screen.pbRefresh
    if pbCheckUseOnPokemon(item, pkmn, screen)
      #ret = ItemHandlers.triggerUseOnPokemon(item, qty, pkmn, screen)
      max_at_once = ItemHandlers.triggerUseOnPokemonMaximum(item, pkmn)
      max_at_once = [max_at_once, $bag.quantity(itm)].min	
      if max_at_once > 1
        qty = screen.pbChooseNumber(
          _INTL("¿Qué cantidad {1} quieres usar?", GameData::Item.get(item).name), max_at_once
        )
        scene.pbSetHelpText("") if screen.is_a?(PokemonPartyScreen)
      end
      if qty > 0
        ret = ItemHandlers.triggerUseOnPokemon(item, qty, pkmn, screen)
        if ret && useType == 1 # Usable on Pokémon, consumed
          $bag.remove(item, qty)  if itm.consumed_after_use? { screen.pbRefresh }
        end 
        if !$bag.has?(item) && itm.num_pocket != 8
          screen.pbDisplay(_INTL("No te quedan más {1}.", itm.portion_name)) { screen.pbUpdate }
          screen.pbChangeCursor(2)
        end
      end
      screen.pbRefresh
    end
    bagscene.pbRefresh if bagscene
    return 1
  else
    pbMessage(_INTL("Aquí no se puede usar.")) { screen.pbUpdate }
    return 0
  end
end

#=============================================================================
# Reprogamming Sacred Ash to work with the party from the bag
#=============================================================================
ItemHandlers::UseInField.add(:SACREDASH, proc { |item|
  if $player.pokemon_count == 0
    pbMessage(_INTL("No hay Pokémon."))
    next false
  end
  canrevive = false
  $player.pokemon_party.each do |i|
    next if !i.fainted?
    canrevive = true
    break
  end
  if !canrevive
    pbMessage(_INTL("No tendría ningún efecto."))
    next false
  end
  revived = 0
  $player.party.each_with_index do |pkmn, i|
    next if !pkmn.fainted?
    revived += 1
    pkmn.heal
  end
  if revived > 1
    pbMessage(_INTL("Has restaurado los PS de tu Pokémon."))
  elsif revived == 1
    pbMessage(_INTL("Has restaurado los PS de tu Pokémon."))
  end
  next (revived > 0)
})

#=============================================================================
# Battle scene for openning the Bag screen and choosing an item to use
#=============================================================================
class Battle::Scene
  def pbItemMenu(idxBattler, _firstAction)
    # Fade out and hide all sprites
    visibleSprites = pbFadeOutAndHide(@sprites)
    # Set Bag starting positions
    oldLastPocket = $bag.last_viewed_pocket
    oldChoices    = $bag.last_pocket_selections.clone
    if @bagLastPocket
      $bag.last_viewed_pocket     = @bagLastPocket
      $bag.last_pocket_selections = @bagChoices
    else
      $bag.reset_last_selections
    end
    # Setting up the party and starting the Bag screen
    partyPos = @battle.pbPartyOrder(idxBattler)
    partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
    modParty = @battle.pbPlayerDisplayParty(idxBattler)
    itemScene = PokemonBag_Scene.new
    itemScene.pbStartScene($bag, modParty, true,
                           proc { |item|
                             useType = GameData::Item.get(item).battle_use
                             next useType && useType > 0
                           }, false)
    # Loop while in Bag screen
    wasTargeting = false
    loop do
      # Select an item
      item = itemScene.pbChooseItem
      break if !item
      # Choose a command for the selected item
      item = GameData::Item.get(item)
      itemName = item.name
      useType = item.battle_use
      cmdUse = -1
      commands = []
      commands[cmdUse = commands.length] = _INTL("Usar") if useType && useType != 0
      commands[commands.length]          = _INTL("Cancelar")
      command = itemScene.pbShowCommands(_INTL("Has seleccionado a {1}.", itemName), commands)
      next unless cmdUse >= 0 && command == cmdUse   # Use
      # Use types:
      # 0 = not usable in battle
      # 1 = use on Pokémon (lots of items, Blue Flute)
      # 2 = use on Pokémon's move (Ethers)
      # 3 = use on battler (X items, Persim Berry, Red/Yellow Flutes)
      # 4 = use on opposing battler (Poké Balls)
      # 5 = use no target (Poké Doll, Guard Spec., Poké Flute, Launcher items)
      case useType
      when 1, 2, 3   # Use on Pokémon/Pokémon's move/battler
        # Auto-choose the Pokémon/battler whose action is being decided if they
        # are the only available Pokémon/battler to use the item on
        case useType
        when 1   # Use on Pokémon
          if @battle.pbTeamLengthFromBattlerIndex(idxBattler) == 1
            break if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, itemScene
          end
        when 3   # Use on battler
          if @battle.pbPlayerBattlerCount == 1
            break if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, itemScene
          end
        end
        # Get player's party
        party    = @battle.pbParty(idxBattler)
        partyPos = @battle.pbPartyOrder(idxBattler)
        partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
        modParty = @battle.pbPlayerDisplayParty(idxBattler)
        # Start Pokémon selection
        idxParty = -1
        # Loop while in party screen
        loop do
          # Select a Pokémon
          pbPlayDecisionSE
          idxParty = itemScene.pbChoosePoke(0,false)
          break if idxParty < 0
          idxPartyRet = -1
          partyPos.each_with_index do |pos, i|
            next if pos != idxParty + partyStart
            idxPartyRet = i
            break
          end
          next if idxPartyRet < 0
          pkmn = party[idxPartyRet]
          next if !pkmn || pkmn.egg?
          idxMove = -1
          if useType == 2   # Use on Pokémon's move
            idxMove = itemScene.pbChooseMove(pkmn,_INTL("¿Qué movimiento restaurar?"))
            next if idxMove < 0
          end
          break if yield item.id, useType, idxPartyRet, idxMove, itemScene
        end
        # Cancelled choosing a Pokémon; show the Bag screen again
        break if idxParty >= 0
      when 4   # Use on opposing battler (Poké Balls)
        idxTarget = -1
        if @battle.pbOpposingBattlerCount(idxBattler) == 1
          @battle.allOtherSideBattlers(idxBattler).each { |b| idxTarget = b.index }
          break if yield item.id, useType, idxTarget, -1, itemScene
        else
          wasTargeting = true
          # Fade out and hide Bag screen
          itemScene.pbFadeOutScene
          # Fade in and show the battle screen, choosing a target
          tempVisibleSprites = visibleSprites.clone
          tempVisibleSprites["commandWindow"] = false
          tempVisibleSprites["targetWindow"]  = true
          idxTarget = pbChooseTarget(idxBattler, GameData::Target.get(:Foe), tempVisibleSprites)
          if idxTarget >= 0
            break if yield item.id, useType, idxTarget, -1, self
          end
          # Target invalid/cancelled choosing a target; show the Bag screen again
          wasTargeting = false
          pbFadeOutAndHide(@sprites)
          itemScene.pbFadeInScene
        end
      when 5   # Use with no target
        break if yield item.id, useType, idxBattler, -1, itemScene
      end
    end
    @bagLastPocket = $bag.last_viewed_pocket
    @bagChoices    = $bag.last_pocket_selections.clone
    $bag.last_viewed_pocket     = oldLastPocket
    $bag.last_pocket_selections = oldChoices
    # Close Bag screen
    itemScene.pbEndScene
    # Fade back into battle screen (if not already showing it)
    pbFadeInAndShow(@sprites, visibleSprites) if !wasTargeting
  end
end
