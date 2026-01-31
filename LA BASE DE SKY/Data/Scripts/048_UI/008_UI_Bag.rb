#===============================================================================
#
#===============================================================================
class Window_PokemonBag < Window_DrawableCommand
  attr_reader :pocket
  attr_accessor :sorting

  RECT_X_OFFSET = 16
  RECT_Y_OFFSET = 16
  CLOSE_BAG_TEXT_X_OFFSET = 0
  CLOSE_BAG_TEXT_Y_OFFSET = 2
  ITEM_NAME_Y_OFFSET = 2
  ITEM_NAME_X_OFFSET = 0
  ICON_REGISTER_X_OFFSET = -72
  ICON_REGISTER_Y_OFFSET = 8
  ITEM_QUANTITY_X_OFFSET = -16
  ITEM_QUANTITY_Y_OFFSET = 2

  def initialize(bag, filterlist, pocket, x, y, width, height)
    @bag        = bag
    @filterlist = filterlist
    @pocket     = pocket
    @sorting = false
    @adapter = PokemonMartAdapter.new
    super(x, y, width, height)
    @selarrow  = AnimatedBitmap.new("Graphics/UI/Bag/cursor")
    @swaparrow = AnimatedBitmap.new("Graphics/UI/Bag/cursor_swap")
    self.windowskin = nil
  end

  def dispose
    @swaparrow.dispose
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
      bmp = (@sorting) ? @swaparrow.bitmap : @selarrow.bitmap
      pbCopyBitmap(self.contents, bmp, rect.x, rect.y + 2)
    end
  end

  def drawItem(index, _count, rect)
    textpos = []
    rect = Rect.new(rect.x + RECT_X_OFFSET, rect.y + RECT_Y_OFFSET, rect.width - RECT_X_OFFSET, rect.height)
    thispocket = @bag.pockets[@pocket]
    if index == self.itemCount - 1
      textpos.push([_INTL("CERRAR MOCHILA"), rect.x + CLOSE_BAG_TEXT_X_OFFSET, rect.y + CLOSE_BAG_TEXT_Y_OFFSET, :left, self.baseColor, self.shadowColor])
    else
      item = (@filterlist) ? thispocket[@filterlist[@pocket][index]][0] : thispocket[index][0]
      baseColor   = self.baseColor
      shadowColor = self.shadowColor
      if @sorting && index == self.index
        baseColor   = Color.new(224, 0, 0)
        shadowColor = Color.new(248, 144, 144)
      end
      textpos.push(
        [@adapter.getDisplayName(item), rect.x + ITEM_NAME_X_OFFSET, rect.y + ITEM_NAME_Y_OFFSET, :left, baseColor, shadowColor]
      )
      item_data = GameData::Item.get(item)
      showing_register_icon = false
      if item_data.is_important?
        if @bag.registered?(item)
          pbDrawImagePositions(
            self.contents,
            [[_INTL("Graphics/UI/Bag/icon_register"), rect.x + rect.width + ICON_REGISTER_X_OFFSET, rect.y + ICON_REGISTER_Y_OFFSET, 0, 0, -1, 24]]
          )
          showing_register_icon = true
        elsif pbCanRegisterItem?(item)
          pbDrawImagePositions(
            self.contents,
            [[_INTL("Graphics/UI/Bag/icon_register"), rect.x + rect.width + ICON_REGISTER_X_OFFSET, rect.y + ICON_REGISTER_Y_OFFSET, 0, 24, -1, 24]]
          )
          showing_register_icon = true
        end
      end
      if item_data.show_quantity? && !showing_register_icon
        qty = (@filterlist) ? thispocket[@filterlist[@pocket][index]][1] : thispocket[index][1]
        qtytext = _ISPRINTF("x{1: 3d}", qty)
        xQty    = rect.x + rect.width - self.contents.text_size(qtytext).width + ITEM_QUANTITY_X_OFFSET
        textpos.push([qtytext, xQty, rect.y + ITEM_QUANTITY_Y_OFFSET, :left, baseColor, shadowColor])
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
    @item_max.times do |i|
      next if i < self.top_item - 1 || i > self.top_item + self.page_item_max
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
# Bag visuals
#===============================================================================
class PokemonBag_Scene
  ITEMLISTBASECOLOR                = Color.new(88, 88, 80)
  ITEMLISTSHADOWCOLOR              = Color.new(168, 184, 184)
  ITEMTEXTBASECOLOR                = Color.new(248, 248, 248)
  ITEMTEXTSHADOWCOLOR              = Color.new(0, 0, 0)
  POCKETNAMEBASECOLOR              = Color.new(88, 88, 80)
  POCKETNAMESHADOWCOLOR            = Color.new(168, 184, 184)
  ITEMSVISIBLE                     = 7
  BAG_SPRITE_WIDTH                 = 30
  BAG_SPRITE_HEIGHT                = 20
  POCKET_ICON_WIDTH                = 186
  POCKET_ICON_HEIGHT               = 32
  POCKET_ICON_X                    = 0
  POCKET_ICON_Y                    = 224
  POCKET_ICON_OFFSET_X             = 6
  POCKET_ICON_OFFSET_Y             = 6
  POCKET_ICON_ACTIVE_OFFSET_X      = 2
  POCKET_ICON_ACTIVE_OFFSET_Y      = 2
  POCKET_ICON_SPACING_X            = 22
  POCKET_ICON_SRC_WIDTH            = 20
  POCKET_ICON_SRC_HEIGHT           = 20
  POCKET_ICON_SRC_Y                = 28
  POCKET_ACTIVE_SRC_WIDTH          = 28
  POCKET_ACTIVE_SRC_HEIGHT         = 28
  POCKET_ACTIVE_SRC_Y              = 0
  POCKET_NAME_X                    = 94
  POCKET_NAME_Y                    = 186

  SLIDER_X                         = 470
  SLIDER_ARROW_TOP_Y               = 16
  SLIDER_ARROW_BOTTOM_Y            = 228
  SLIDER_ARROW_SRC_TOP_Y           = 0
  SLIDER_ARROW_SRC_BOTTOM_Y        = 38
  SLIDER_ARROW_SRC_WIDTH           = 36
  SLIDER_ARROW_SRC_HEIGHT          = 38

  SLIDER_BAR_SRC_X                 = 36
  SLIDER_BAR_TOP_SRC_Y             = 0
  SLIDER_BAR_TOP_SRC_HEIGHT        = 4
  SLIDER_BAR_FILL_SRC_Y            = 4
  SLIDER_BAR_FILL_CHUNK_HEIGHT     = 16
  SLIDER_BAR_BOTTOM_SRC_Y          = 20
  SLIDER_BAR_BOTTOM_SRC_HEIGHT     = 18

  SLIDER_HEIGHT                    = 174
  SLIDER_BOX_MIN_HEIGHT            = 38
  SLIDER_BOX_START_Y               = 54
  SLIDER_MIN_DIV                   = 6
  LEFT_ARROW_X                     = -4
  LEFT_ARROW_Y                     = 76
  RIGHT_ARROW_X                    = 150
  RIGHT_ARROW_Y                    = 76
  ITEM_ICON_X                      = 48
  ITEM_ICON_Y                      = Graphics.height - 48
  TEXT_BOX_X                       = 72
  TEXT_BOX_Y                       = 272
  TEXT_BOX_WIDTH                   = Graphics.width - 72 - 24
  TEXT_BOX_HEIGHT                  = 128

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(bag, choosing = false, filterproc = nil, resetpocket = true)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @bag        = bag
    @choosing   = choosing
    @filterproc = filterproc
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
    @sliderbitmap = AnimatedBitmap.new("Graphics/UI/Bag/icon_slider")
    @pocketbitmap = AnimatedBitmap.new("Graphics/UI/Bag/icon_pocket")
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["bagsprite"] = IconSprite.new(BAG_SPRITE_WIDTH, BAG_SPRITE_HEIGHT, @viewport)
    @sprites["pocketicon"] = BitmapSprite.new(POCKET_ICON_WIDTH, POCKET_ICON_HEIGHT, @viewport)
    @sprites["pocketicon"].x = POCKET_ICON_X
    @sprites["pocketicon"].y = POCKET_ICON_Y
    @sprites["leftarrow"] = AnimatedSprite.new("Graphics/UI/left_arrow", 8, 40, 28, 2, @viewport)
    @sprites["leftarrow"].x       = LEFT_ARROW_X
    @sprites["leftarrow"].y       = LEFT_ARROW_Y
    @sprites["leftarrow"].visible = (!@choosing || numfilledpockets > 1)
    @sprites["leftarrow"].play
    @sprites["rightarrow"] = AnimatedSprite.new("Graphics/UI/right_arrow", 8, 40, 28, 2, @viewport)
    @sprites["rightarrow"].x       = RIGHT_ARROW_X
    @sprites["rightarrow"].y       = RIGHT_ARROW_Y
    @sprites["rightarrow"].visible = (!@choosing || numfilledpockets > 1)
    @sprites["rightarrow"].play
    @sprites["itemlist"] = Window_PokemonBag.new(@bag, @filterlist, lastpocket, 168, -8, 314, 40 + 32 + (ITEMSVISIBLE * 32))
    @sprites["itemlist"].viewport    = @viewport
    @sprites["itemlist"].pocket      = lastpocket
    @sprites["itemlist"].index       = @bag.last_viewed_index(lastpocket)
    @sprites["itemlist"].baseColor   = ITEMLISTBASECOLOR
    @sprites["itemlist"].shadowColor = ITEMLISTSHADOWCOLOR
    @sprites["itemicon"] = ItemIconSprite.new(ITEM_ICON_X, ITEM_ICON_Y, nil, @viewport)
    @sprites["itemtext"] = Window_UnformattedTextPokemon.newWithSize(
      "", TEXT_BOX_X, TEXT_BOX_Y, TEXT_BOX_WIDTH, TEXT_BOX_HEIGHT, @viewport
    )
    @sprites["itemtext"].baseColor   = ITEMTEXTBASECOLOR
    @sprites["itemtext"].shadowColor = ITEMTEXTSHADOWCOLOR
    @sprites["itemtext"].visible     = true
    @sprites["itemtext"].windowskin  = nil
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.new("")
    @sprites["helpwindow"].visible  = false
    @sprites["helpwindow"].viewport = @viewport
    @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible  = false
    @sprites["msgwindow"].viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"], 1)
    pbDeactivateWindows(@sprites)
    pbRefresh
    pbFadeInAndShow(@sprites)
  end

  def pbFadeOutScene
    @oldsprites = pbFadeOutAndHide(@sprites)
  end

  def pbFadeInScene
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

  def pbDisplay(msg, brief = false)
    UIHelper.pbDisplay(@sprites["msgwindow"], msg, brief) { pbUpdate }
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
    # Set the background image
    @sprites["background"].setBitmap(sprintf("Graphics/UI/Bag/bg_%d", @bag.last_viewed_pocket))
    # Set the bag sprite
    fbagexists = pbResolveBitmap(sprintf("Graphics/UI/Bag/bag_%d_f", @bag.last_viewed_pocket))
    if $player.female? && fbagexists
      @sprites["bagsprite"].setBitmap(sprintf("Graphics/UI/Bag/bag_%d_f", @bag.last_viewed_pocket))
    else
      @sprites["bagsprite"].setBitmap(sprintf("Graphics/UI/Bag/bag_%d", @bag.last_viewed_pocket))
    end
    # Draw the pocket icons
    @sprites["pocketicon"].bitmap.clear
    if @choosing && @filterlist
      (1...@bag.pockets.length).each do |i|
        next if @filterlist[i].length > 0
        @sprites["pocketicon"].bitmap.blt(
          POCKET_ICON_OFFSET_X + ((i - 1) * POCKET_ICON_SPACING_X), POCKET_ICON_OFFSET_Y,
          @pocketbitmap.bitmap,
          Rect.new((i - 1) * POCKET_ICON_SRC_WIDTH, POCKET_ICON_SRC_Y, POCKET_ICON_SRC_WIDTH, POCKET_ICON_SRC_HEIGHT)
        )
      end
    end
    @sprites["pocketicon"].bitmap.blt(
      POCKET_ICON_ACTIVE_OFFSET_X + ((@sprites["itemlist"].pocket - 1) * POCKET_ICON_SPACING_X),
      POCKET_ICON_ACTIVE_OFFSET_Y,
      @pocketbitmap.bitmap,
      Rect.new((@sprites["itemlist"].pocket - 1) * POCKET_ACTIVE_SRC_WIDTH, POCKET_ACTIVE_SRC_Y,
               POCKET_ACTIVE_SRC_WIDTH, POCKET_ACTIVE_SRC_HEIGHT)
    )
    # Refresh the item window
    @sprites["itemlist"].refresh
    # Refresh more things
    pbRefreshIndexChanged
  end

  def pbRefreshIndexChanged
    itemlist = @sprites["itemlist"]
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Draw the pocket name
    pbDrawTextPositions(
      overlay,
      [[PokemonBag.pocket_names[@bag.last_viewed_pocket - 1], POCKET_NAME_X, POCKET_NAME_Y, :center, POCKETNAMEBASECOLOR, POCKETNAMESHADOWCOLOR]]
    )
    # Draw slider arrows
    showslider = false
    if itemlist.top_row > 0
      overlay.blt(SLIDER_X, SLIDER_ARROW_TOP_Y, @sliderbitmap.bitmap, Rect.new(0, SLIDER_ARROW_SRC_TOP_Y, SLIDER_ARROW_SRC_WIDTH, SLIDER_ARROW_SRC_HEIGHT))
      showslider = true
    end
    if itemlist.top_item + itemlist.page_item_max < itemlist.itemCount
      overlay.blt(SLIDER_X, SLIDER_ARROW_BOTTOM_Y, @sliderbitmap.bitmap, Rect.new(0, SLIDER_ARROW_SRC_BOTTOM_Y, SLIDER_ARROW_SRC_WIDTH, SLIDER_ARROW_SRC_HEIGHT))
      showslider = true
    end
    # Draw slider box
    if showslider
      sliderheight = SLIDER_HEIGHT
      boxheight = (sliderheight * itemlist.page_row_max / itemlist.row_max).floor
      boxheight += [(sliderheight - boxheight) / 2, sliderheight / SLIDER_MIN_DIV].min
      boxheight = [boxheight.floor, SLIDER_BOX_MIN_HEIGHT].max
      y = SLIDER_BOX_START_Y
      y += ((sliderheight - boxheight) * itemlist.top_row / (itemlist.row_max - itemlist.page_row_max)).floor
      overlay.blt(SLIDER_X, y, @sliderbitmap.bitmap, Rect.new(SLIDER_BAR_SRC_X, SLIDER_BAR_TOP_SRC_Y, SLIDER_ARROW_SRC_WIDTH, SLIDER_BAR_TOP_SRC_HEIGHT))
      i = 0
      while i * SLIDER_BAR_FILL_CHUNK_HEIGHT < boxheight - SLIDER_BAR_TOP_SRC_HEIGHT - SLIDER_BAR_BOTTOM_SRC_HEIGHT
        height = [boxheight - SLIDER_BAR_TOP_SRC_HEIGHT - SLIDER_BAR_BOTTOM_SRC_HEIGHT - (i * SLIDER_BAR_FILL_CHUNK_HEIGHT), SLIDER_BAR_FILL_CHUNK_HEIGHT].min
        overlay.blt(SLIDER_X, y + SLIDER_BAR_TOP_SRC_HEIGHT + (i * SLIDER_BAR_FILL_CHUNK_HEIGHT), @sliderbitmap.bitmap, Rect.new(SLIDER_BAR_SRC_X, SLIDER_BAR_FILL_SRC_Y, SLIDER_ARROW_SRC_WIDTH, height))
        i += 1
      end
      overlay.blt(SLIDER_X, y + boxheight - SLIDER_BAR_BOTTOM_SRC_HEIGHT, @sliderbitmap.bitmap, Rect.new(SLIDER_BAR_SRC_X, SLIDER_BAR_BOTTOM_SRC_Y, SLIDER_ARROW_SRC_WIDTH, SLIDER_BAR_BOTTOM_SRC_HEIGHT))
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

  # Called when the item screen wants an item to be chosen from the screen
  def pbChooseItem
    @sprites["helpwindow"].visible = false
    itemwindow = @sprites["itemlist"]
    thispocket = @bag.pockets[itemwindow.pocket]
    swapinitialpos = -1
    pbActivateWindow(@sprites, "itemlist") do
      loop do
        oldindex = itemwindow.index
        Graphics.update
        Input.update
        pbUpdate
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
        else   # Change pockets
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
              pbPlayCursorSE
              pbRefresh
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
              pbPlayCursorSE
              pbRefresh
            end
#          elsif Input.trigger?(Input::SPECIAL)   # Register/unregister selected item
#            if !@choosing && itemwindow.index<thispocket.length
#              if @bag.registered?(itemwindow.item)
#                @bag.unregister(itemwindow.item)
#              elsif pbCanRegisterItem?(itemwindow.item)
#                @bag.register(itemwindow.item)
#              end
#              pbPlayDecisionSE
#              pbRefresh
#            end
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
    end
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
    @scene.pbStartScene(@bag)
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
      commands[cmdRead = commands.length] = _INTL("Leer") if itm.is_mail?
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
        commands[cmdRegister = commands.length] = _INTL("No registrar")
      elsif pbCanRegisterItem?(item)
        commands[cmdRegister = commands.length] = _INTL("Registrar")
      end
      commands[cmdDebug = commands.length]      = _INTL("Debug") if $DEBUG
      commands[commands.length]                 = _INTL("Cancelar")
      # Show commands generated above
      itemname = itm.name
      command = @scene.pbShowCommands(_INTL("Has seleccionado {1}.", itemname), commands)
      if cmdRead >= 0 && command == cmdRead   # Read mail
        pbFadeOutIn do
          pbDisplayMail(Mail.new(item, "", ""))
        end
      elsif cmdUse >= 0 && command == cmdUse   # Use item
        ret = pbUseItem(@bag, item, @scene)
        # ret: 0=Item wasn't used; 1=Item used; 2=Close Bag to use in field
        break if ret == 2   # End screen
        @scene.pbRefresh
        next
      elsif cmdGive >= 0 && command == cmdGive   # Give item to Pokémon
        if $player.pokemon_count == 0
          @scene.pbDisplay(_INTL("No hay Pokémon."))
        elsif itm.is_important?
          @scene.pbDisplay(_INTL("No se puede equipar {1}.", itm.portion_name))
        else
          pbFadeOutIn do
            sscene = PokemonParty_Scene.new
            sscreen = PokemonPartyScreen.new(sscene, $player.party)
            sscreen.pbPokemonGiveScreen(item)
            @scene.pbRefresh
          end
        end
      elsif cmdToss >= 0 && command == cmdToss   # Toss item
        qty = @bag.quantity(item)
        if qty > 1
          helptext = _INTL("¿Cuántos {1} tirar?", itm.portion_name_plural)
          qty = @scene.pbChooseNumber(helptext, qty)
        end
        if qty > 0
          itemname = (qty > 1) ? itm.portion_name_plural : itm.portion_name
          if pbConfirm(_INTL("¿Quieres tirar {1} {2}?", qty, itemname))
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
                                           _INTL("Hacer Regalo Misterioso"),
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
              _INTL("Elige la nueva cantidad de {1} (máx. {2}).", itemplural, Settings::BAG_MAX_PER_SLOT), params
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
    @bag.reset_last_selections if proc
    @scene.pbStartScene(@bag, true, proc)
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
          raise "No se pueden eliminar objetos del almacenamiento"
        end
        if !@bag.add(item, qty)
          raise "No se pueden tirar objetos del almacenamiento"
        end
        @scene.pbRefresh
        dispqty = (itm.is_important?) ? 1 : qty
        itemname = (dispqty > 1) ? itm.portion_name_plural : itm.portion_name
        pbDisplay(_INTL("Has tirado {1} {2}.", dispqty, itemname))
      else
        pbDisplay(_INTL("No hay más espacio en la Mochila."))
      end
    end
    @scene.pbEndScene
  end

  # UI logic for depositing an item in the item storage screen.
  def pbDepositItemScreen
    @scene.pbStartScene(@bag)
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
            raise "No se pueden dejar objetos en el almacenamiento"
          end
          @scene.pbRefresh
          dispqty  = (itm.is_important?) ? 1 : qty
          itemname = (dispqty > 1) ? itm.portion_name_plural : itm.portion_name
          pbDisplay(_INTL("Has dejado {1} {2}.", dispqty, itemname))
        else
          pbDisplay(_INTL("No hay espacio para guardar objetos."))
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
        @scene.pbDisplay(_INTL("¡Eso es muy importante para tirarlo!"))
        next
      end
      qty = storage.quantity(item)
      itemname       = itm.portion_name
      itemnameplural = itm.portion_name_plural
      if qty > 1
        qty = @scene.pbChooseNumber(_INTL("¿Cuántos {1} tirar?", itemnameplural), qty)
      end
      next if qty <= 0
      itemname = itemnameplural if qty > 1
      next if !pbConfirm(_INTL("¿Quieres tirar {1} {2}?", qty, itemname))
      if !storage.remove(item, qty)
        raise "No se pueden eliminar objetos del almacenamiento"
      end
      @scene.pbRefresh
      pbDisplay(_INTL("Has tirado {1} {2}.", qty, itemname))
    end
    @scene.pbEndScene
  end
end

