#===============================================================================
# Abstraction layer for Pokemon Essentials
#===============================================================================
class BattlePointShopAdapter
  def getBP
    return $player.battle_points
  end

  def getBPString
    return _INTL("{1} PB", $player.battle_points.to_s_formatted)
  end

  def setBP(value)
    $player.battle_points = value
  end

  def getInventory
    return $bag
  end

  def getName(item)
    return GameData::Item.get(item).portion_name
  end

  def getNamePlural(item)
    return GameData::Item.get(item).portion_name_plural
  end

  def getDisplayName(item)
    item_name = GameData::Item.get(item).name
    if GameData::Item.get(item).is_machine?
      machine = GameData::Item.get(item).move
      item_name = _INTL("{1} {2}", item_name, GameData::Move.get(machine).name)
    end
    return item_name
  end

  def getDisplayNamePlural(item)
    item_name_plural = GameData::Item.get(item).name_plural
    if GameData::Item.get(item).is_machine?
      machine = GameData::Item.get(item).move
      item_name_plural = _INTL("{1} {2}", item_name_plural, GameData::Move.get(machine).name)
    end
    return item_name_plural
  end

  def getDescription(item)
    return GameData::Item.get(item).description
  end

  def getItemIcon(item)
    return (item) ? GameData::Item.icon_filename(item) : nil
  end

  # Unused
  def getItemIconRect(_item)
    return Rect.new(0, 0, 48, 48)
  end

  def getQuantity(item)
    return $bag.quantity(item)
  end

  def showQuantity?(item)
    return !GameData::Item.get(item).is_important?
  end

  def getPrice(item)
    if $game_temp.mart_prices && $game_temp.mart_prices[item]
      if $game_temp.mart_prices[item][0] > 0
        return $game_temp.mart_prices[item][0]
      end
    end
    return GameData::Item.get(item).bp_price
  end

  def getDisplayPrice(item, selling = false)
    price = getPrice(item).to_s_formatted
    return _INTL("{1} PB", price)
  end

  def addItem(item)
    return $bag.add(item)
  end

  def removeItem(item)
    return $bag.remove(item)
  end
end

#===============================================================================
# Battle Point Shop
#===============================================================================
class Window_BattlePointShop < Window_DrawableCommand

  CANCEL_TEXT_X_OFFSET = 0
  CANCEL_TEXT_Y_OFFSET = 2
  ITEM_QTY_X_OFFSET    = -18
  ITEM_QTY_Y_OFFSET    = 2
  ITEM_NAME_X_OFFSET   = 0
  ITEM_NAME_Y_OFFSET   = 2

  def initialize(stock, adapter, x, y, width, height, viewport = nil)
    @stock       = stock
    @adapter     = adapter
    super(x, y, width, height, viewport)
    @selarrow    = AnimatedBitmap.new("Graphics/UI/Mart/cursor")
    @baseColor   = Color.new(88, 88, 80)
    @shadowColor = Color.new(168, 184, 184)
    self.windowskin = nil
  end

  def itemCount
    return @stock.length + 1
  end

  def item
    return (self.index >= @stock.length) ? nil : @stock[self.index]
  end

  def drawItem(index, count, rect)
    textpos = []
    rect = drawCursor(index, rect)
    ypos = rect.y
    if index == count - 1
      textpos.push([_INTL("CANCELAR"), rect.x + CANCEL_TEXT_X_OFFSET, ypos + CANCEL_TEXT_Y_OFFSET, :left, self.baseColor, self.shadowColor])
    else
      item = @stock[index]
      itemname = @adapter.getDisplayName(item)
      qty = @adapter.getDisplayPrice(item)
      sizeQty = self.contents.text_size(qty).width
      xQty = rect.x + rect.width - sizeQty + ITEM_QTY_X_OFFSET
      textpos.push([itemname, rect.x + ITEM_NAME_X_OFFSET, ypos + ITEM_NAME_Y_OFFSET, :left, self.baseColor, self.shadowColor])
      textpos.push([qty, xQty, ypos + ITEM_QTY_Y_OFFSET, :left, self.baseColor, self.shadowColor])
    end
    pbDrawTextPositions(self.contents, textpos)
  end
end

#===============================================================================
#
#===============================================================================
class BattlePointShop_Scene

  QTY_WINDOW_Y_OFFSET= -102
  SCROLL_MAP_START_DIRECTION    = 6   # Scroll right when opening mart
  SCROLL_MAP_START_DISTANCE     = 5
  SCROLL_MAP_START_SPEED        = 5
  ICON_X                        = 36
  ICON_Y_OFFSET                 = -50
  ITEM_WINDOW_X_OFFSET          = -332
  ITEM_WINDOW_Y                 = 10
  ITEM_WINDOW_WIDTH             = 346
  ITEM_WINDOW_HEIGHT_OFFSET     = -124
  ITEM_TEXT_WINDOW_X            = 64
  ITEM_TEXT_WINDOW_Y_OFFSET     = -112
  ITEM_TEXT_WINDOW_WIDTH_OFFSET = -64
  ITEM_TEXT_WINDOW_HEIGHT       = 128
  HELP_WINDOW_TEXT_LINES        = 1
  BATTLE_POINT_WINDOW_X         = 0
  BATTLE_POINT_WINDOW_Y         = 0
  BATTLE_POINT_WINDOW_WIDTH     = 190
  BATTLE_POINT_WINDOW_HEIGHT    = 96
  QTY_WINDOW_WIDTH              = 190
  QTY_WINDOW_HEIGHT             = 64
  QTY_WINDOW_Y_OFFSET           = -102
  SCROLL_MAP_END_DIRECTION      = 4   # Scroll left when closing mart
  SCROLL_MAP_END_DISTANCE       = 5
  SCROLL_MAP_END_SPEED          = 5
  DISPLAY_TEXT_LINES            = 2
  CHOOSE_NUMBER_WINDOW_WIDTH    = 224
  CHOOSE_NUMBER_WINDOW_HEIGHT   = 64

  def update
    pbUpdateSpriteHash(@sprites)
    @subscene&.pbUpdate
  end

  def pbRefresh
    if @subscene
      @subscene.pbRefresh
    else
      itemwindow = @sprites["itemwindow"]
      @sprites["icon"].item = itemwindow.item
      @sprites["itemtextwindow"].text =
        (itemwindow.item) ? @adapter.getDescription(itemwindow.item) : _INTL("Dejar de comprar.")
      @sprites["qtywindow"].visible = !itemwindow.item.nil?
      @sprites["qtywindow"].text    = _INTL("En Mochila:<r>{1}", @adapter.getQuantity(itemwindow.item))
      @sprites["qtywindow"].y       = Graphics.height + QTY_WINDOW_Y_OFFSET - @sprites["qtywindow"].height
      itemwindow.refresh
    end
    @sprites["battlepointwindow"].text = _INTL("Puntos de\nBatalla: {1}", $player.battle_points.to_s_formatted)
  end

  def pbStartScene(stock, adapter)
    # Scroll right before showing screen
    pbScrollMap(SCROLL_MAP_START_DIRECTION, SCROLL_MAP_START_DISTANCE, SCROLL_MAP_START_SPEED)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @stock = stock
    @adapter = adapter
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap("Graphics/UI/Mart/bg")
    @sprites["icon"] = ItemIconSprite.new(ICON_X, Graphics.height + ICON_Y_OFFSET, nil, @viewport)
    winAdapter = BattlePointShopAdapter.new
    @sprites["itemwindow"] = Window_BattlePointShop.new(
      stock, winAdapter, Graphics.width + ITEM_WINDOW_X_OFFSET, ITEM_WINDOW_Y, ITEM_WINDOW_WIDTH, Graphics.height + ITEM_WINDOW_HEIGHT_OFFSET
    )
    @sprites["itemwindow"].viewport = @viewport
    @sprites["itemwindow"].index = 0
    @sprites["itemwindow"].refresh
    @sprites["itemtextwindow"] = Window_UnformattedTextPokemon.newWithSize(
      "", ITEM_TEXT_WINDOW_X, Graphics.height + ITEM_TEXT_WINDOW_Y_OFFSET, Graphics.width + ITEM_TEXT_WINDOW_WIDTH_OFFSET, ITEM_TEXT_WINDOW_HEIGHT, @viewport
    )
    pbPrepareWindow(@sprites["itemtextwindow"])
    @sprites["itemtextwindow"].baseColor = Color.new(248, 248, 248)
    @sprites["itemtextwindow"].shadowColor = Color.new(0, 0, 0)
    @sprites["itemtextwindow"].windowskin = nil
    @sprites["helpwindow"] = Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["helpwindow"])
    @sprites["helpwindow"].visible = false
    @sprites["helpwindow"].viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"], HELP_WINDOW_TEXT_LINES)
    @sprites["battlepointwindow"] = Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["battlepointwindow"])
    @sprites["battlepointwindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["battlepointwindow"].visible = true
    @sprites["battlepointwindow"].viewport = @viewport
    @sprites["battlepointwindow"].x = BATTLE_POINT_WINDOW_X
    @sprites["battlepointwindow"].y = BATTLE_POINT_WINDOW_Y
    @sprites["battlepointwindow"].width = BATTLE_POINT_WINDOW_WIDTH
    @sprites["battlepointwindow"].height = BATTLE_POINT_WINDOW_HEIGHT
    @sprites["battlepointwindow"].baseColor = Color.new(88, 88, 80)
    @sprites["battlepointwindow"].shadowColor = Color.new(168, 184, 184)
    @sprites["qtywindow"] = Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["qtywindow"])
    @sprites["qtywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["qtywindow"].viewport = @viewport
    @sprites["qtywindow"].width = QTY_WINDOW_WIDTH
    @sprites["qtywindow"].height = QTY_WINDOW_HEIGHT
    @sprites["qtywindow"].baseColor = Color.new(88, 88, 80)
    @sprites["qtywindow"].shadowColor = Color.new(168, 184, 184)
    @sprites["qtywindow"].text = _INTL("En Mochila:<r>{1}", @adapter.getQuantity(@sprites["itemwindow"].item))
    @sprites["qtywindow"].y = Graphics.height + QTY_WINDOW_Y_OFFSET - @sprites["qtywindow"].height
    pbDeactivateWindows(@sprites)
    pbRefresh
    Graphics.frame_reset
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    # Scroll left after showing screen
    pbScrollMap(SCROLL_MAP_END_DIRECTION, SCROLL_MAP_END_DISTANCE, SCROLL_MAP_END_SPEED)
  end

  def pbPrepareWindow(window)
    window.visible = true
    window.letterbyletter = false
  end

  def pbShowBattlePoints
    pbRefresh
    @sprites["battlepointwindow"].visible = true
  end

  def pbHideBattlePoints
    pbRefresh
    @sprites["battlepointwindow"].visible = false
  end

  def pbShowQuantity
    pbRefresh
    @sprites["qtywindow"].visible = true
  end

  def pbHideQuantity
    pbRefresh
    @sprites["qtywindow"].visible = false
  end

  def pbDisplay(msg, brief = false)
    cw = @sprites["helpwindow"]
    cw.letterbyletter = true
    cw.text = msg
    pbBottomLeftLines(cw, DISPLAY_TEXT_LINES)
    cw.visible = true
    pbPlayDecisionSE
    refreshed_after_busy = false
    timer_start = System.uptime
    loop do
      Graphics.update
      Input.update
      self.update
      if !cw.busy?
        return if brief
        if !refreshed_after_busy
          pbRefresh
          timer_start = System.uptime
          refreshed_after_busy = true
        end
      end
      if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        cw.resume if cw.busy?
      end
      return if refreshed_after_busy && System.uptime - timer_start >= 1.5
    end
  end

  def pbDisplayPaused(msg)
    cw = @sprites["helpwindow"]
    cw.letterbyletter = true
    cw.text = msg
    pbBottomLeftLines(cw, DISPLAY_TEXT_LINES)
    cw.visible = true
    yielded = false
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      wasbusy = cw.busy?
      self.update
      if !cw.busy? && !yielded
        yield if block_given?   # For playing SE as soon as the message is all shown
        yielded = true
      end
      pbRefresh if !cw.busy? && wasbusy
      if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        if cw.resume && !cw.busy?
          @sprites["helpwindow"].visible = false
          break
        end
      end
    end
  end

  def pbConfirm(msg)
    dw = @sprites["helpwindow"]
    dw.letterbyletter = true
    dw.text = msg
    dw.visible = true
    pbBottomLeftLines(dw, DISPLAY_TEXT_LINES)
    commands = [_INTL("Sí"), _INTL("No")]
    cw = Window_CommandPokemon.new(commands)
    cw.viewport = @viewport
    pbBottomRight(cw)
    cw.y -= dw.height
    cw.index = 0
    pbPlayDecisionSE
    loop do
      cw.visible = !dw.busy?
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::BACK) && dw.resume && !dw.busy?
        cw.dispose
        @sprites["helpwindow"].visible = false
        return false
      end
      if Input.trigger?(Input::USE) && dw.resume && !dw.busy?
        cw.dispose
        @sprites["helpwindow"].visible = false
        return (cw.index == 0)
      end
    end
  end

  def pbChooseNumber(helptext, item, maximum)
    curnumber = 1
    ret = 0
    helpwindow = @sprites["helpwindow"]
    itemprice = @adapter.getPrice(item)
    # itemprice /= 2 if !@buying
    pbDisplay(helptext, true)
    using(numwindow = Window_AdvancedTextPokemon.new("")) do   # Showing number of items
      pbPrepareWindow(numwindow)
      numwindow.viewport = @viewport
      numwindow.width = CHOOSE_NUMBER_WINDOW_WIDTH
      numwindow.height = CHOOSE_NUMBER_WINDOW_HEIGHT
      numwindow.baseColor = Color.new(88, 88, 80)
      numwindow.shadowColor = Color.new(168, 184, 184)
      numwindow.text = _INTL("x{1}<r>{2} PB", curnumber, (curnumber * itemprice).to_s_formatted)
      pbBottomRight(numwindow)
      numwindow.y -= helpwindow.height
      loop do
        Graphics.update
        Input.update
        numwindow.update
        update
        oldnumber = curnumber
        if Input.repeat?(Input::LEFT)
          curnumber -= 10
          curnumber = 1 if curnumber < 1
          if curnumber != oldnumber
            numwindow.text = _INTL("x{1}<r>{2} PB", curnumber, (curnumber * itemprice).to_s_formatted)
            pbPlayCursorSE
          end
        elsif Input.repeat?(Input::RIGHT)
          curnumber += 10
          curnumber = maximum if curnumber > maximum
          if curnumber != oldnumber
            numwindow.text = _INTL("x{1}<r>{2} PB", curnumber, (curnumber * itemprice).to_s_formatted)
            pbPlayCursorSE
          end
        elsif Input.repeat?(Input::UP)
          curnumber += 1
          curnumber = 1 if curnumber > maximum
          if curnumber != oldnumber
            numwindow.text = _INTL("x{1}<r>{2} PB", curnumber, (curnumber * itemprice).to_s_formatted)
            pbPlayCursorSE
          end
        elsif Input.repeat?(Input::DOWN)
          curnumber -= 1
          curnumber = maximum if curnumber < 1
          if curnumber != oldnumber
            numwindow.text = _INTL("x{1}<r>{2} PB", curnumber, (curnumber * itemprice).to_s_formatted)
            pbPlayCursorSE
          end
        elsif Input.trigger?(Input::USE)
          ret = curnumber
          break
        elsif Input.trigger?(Input::BACK)
          pbPlayCancelSE
          ret = 0
          break
        end
      end
    end
    helpwindow.visible = false
    return ret
  end

  def pbChooseItem
    itemwindow = @sprites["itemwindow"]
    @sprites["helpwindow"].visible = false
    pbActivateWindow(@sprites, "itemwindow") do
      pbRefresh
      loop do
        Graphics.update
        Input.update
        olditem = itemwindow.item
        self.update
        pbRefresh if itemwindow.item != olditem
        if Input.trigger?(Input::BACK)
          pbPlayCloseMenuSE
          return nil
        elsif Input.trigger?(Input::USE)
          if itemwindow.index < @stock.length
            pbRefresh
            return @stock[itemwindow.index]
          else
            return nil
          end
        end
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
class BattlePointShopScreen
  def initialize(scene, stock)
    @scene = scene
    @stock = stock
    @adapter = BattlePointShopAdapter.new
  end

  def pbConfirm(msg)
    return @scene.pbConfirm(msg)
  end

  def pbDisplay(msg)
    return @scene.pbDisplay(msg)
  end

  def pbDisplayPaused(msg, &block)
    return @scene.pbDisplayPaused(msg, &block)
  end

  def pbBuyScreen
    @scene.pbStartScene(@stock, @adapter)
    item = nil
    loop do
      item = @scene.pbChooseItem
      break if !item
      quantity       = 0
      itemname       = @adapter.getName(item)
      itemnameplural = @adapter.getNamePlural(item)
      price = @adapter.getPrice(item)
      if @adapter.getBP < price
        pbDisplayPaused(_INTL("No tienes suficientes PB."))
        next
      end
      if GameData::Item.get(item).is_important?
        next if !pbConfirm(_INTL("¿Te interesa comprar {1}?\nEl precio son {2} PB.",
                                 itemname, price.to_s_formatted))
        quantity = 1
      else
        maxafford = (price <= 0) ? Settings::BAG_MAX_PER_SLOT : @adapter.getBP / price
        maxafford = Settings::BAG_MAX_PER_SLOT if maxafford > Settings::BAG_MAX_PER_SLOT
        quantity = @scene.pbChooseNumber(
          _INTL("¿Cuántos {1} quieres?", itemnameplural), item, maxafford
        )
        next if quantity == 0
        price *= quantity
        if quantity > 1
          next if !pbConfirm(_INTL("¿Así que quieres {1} {2}?\nSerían {3} PB.",
                                   quantity, itemnameplural, price.to_s_formatted))
        elsif quantity > 0
          next if !pbConfirm(_INTL("¿Así que quieres {1} {2}?\nSerían {3} PB.",
                                   quantity, itemname, price.to_s_formatted))
        end
      end
      if @adapter.getBP < price
        pbDisplayPaused(_INTL("Lo siento, no tienes suficientes PB."))
        next
      end
      added = 0
      quantity.times do
        break if !@adapter.addItem(item)
        added += 1
      end
      if added == quantity
        $stats.battle_points_spent += price
        $stats.mart_items_bought += quantity
        @adapter.setBP(@adapter.getBP - price)
        @stock.delete_if { |itm| GameData::Item.get(itm).is_important? && $bag.has?(itm) }
        pbDisplayPaused(_INTL("¡Aquí tienes! ¡Muchas gracias!")) { pbSEPlay("Mart buy item") }
      else
        added.times do
          if !@adapter.removeItem(item)
            raise _INTL("Fallo al eliminar los objetos guardados")
          end
        end
        pbDisplayPaused(_INTL("No tienes espacio en tu Mochila."))
      end
    end
    @scene.pbEndScene
  end
end

#===============================================================================
#
#===============================================================================
def pbBattlePointShop(stock, speech = nil)
  stock.delete_if { |item| GameData::Item.get(item).is_important? && $bag.has?(item) }
  if speech.nil?
    pbMessage(_INTL("¡Bienvenido al Servicio de Intercambio!"))
    pbMessage(_INTL("Podemos cambiar tus Puntos de Batalla por fabulosos premios."))
  else
    pbMessage(speech)
  end
  scene = BattlePointShop_Scene.new
  screen = BattlePointShopScreen.new(scene, stock)
  screen.pbBuyScreen
  pbMessage(_INTL("Gracias por tu visita."))
  pbMessage(_INTL("Por favor, visítenos de nuevo cuando hayas conseguido más PB."))
  $game_temp.clear_mart_prices
end

