#===============================================================================
# Abstraction layer for Pokemon Essentials
#===============================================================================
class PokemonMartAdapter 
  def getMoney
    return $player.money
  end

  def getMoneyString
    return pbGetGoldString
  end

  def setMoney(value)
    $player.money = value
  end

  def getItemIconRect(_item)
    return Rect.new(0, 0, 48, 48)
  end

  def getDisplayPrice(item, selling = false)
    price = getPrice(item, selling).to_s_formatted
    return _INTL("$ {1}", price)
  end

  # ========== ABSTRACT METHODS - Must be implemented by subclasses ==========

  def getItemIcon(item)
    raise NotImplementedError, "#{self.class} debe implementar #getItemIcon"
  end

  def getInventory
    raise NotImplementedError, "#{self.class} debe implementar #getInventory"
  end

  def getName(item)
    raise NotImplementedError, "#{self.class} debe implementar #getName"
  end

  def getNamePlural(item)
    raise NotImplementedError, "#{self.class} debe implementar #getNamePlural"
  end

  def getDisplayName(item)
    raise NotImplementedError, "#{self.class} debe implementar #getDisplayName"
  end

  def getDescription(item)
    raise NotImplementedError, "#{self.class} debe implementar #getDescription"
  end

  def getQuantity(item)
    raise NotImplementedError, "#{self.class} debe implementar #getQuantity"
  end

  def getPrice(item, selling = false)
    raise NotImplementedError, "#{self.class} debe implementar #getPrice"
  end

  def getDisplayPrice(item, selling = false)
    raise NotImplementedError, "#{self.class} debe implementar #getDisplayPrice"
  end

  def canSell?(item)
    raise NotImplementedError, "#{self.class} debe implementar #canSell?"
  end

  def addItem(item)
    raise NotImplementedError, "#{self.class} debe implementar #addItem"
  end

  def removeItem(item)
    raise NotImplementedError, "#{self.class} debe implementar #removeItem"
  end
end

class PokemonItemMartAdapter < PokemonMartAdapter
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
    item_data = GameData::Item.get(item)
    item_name = item_data.name
    if item_data.is_machine?
      machine = item_data.move
      item_name = _INTL("{1} {2}", item_name.ljust(4), GameData::Move.get(machine).name)
    end
    return item_name
  end

  def getDisplayNamePlural(item)
    item_data = GameData::Item.get(item)
    item_name_plural = item_data.name_plural
    if item_data.is_machine?
      machine = item_data.move
      item_name_plural = _INTL("{1} {2}", item_name_plural.ljust(5), GameData::Move.get(machine).name)
    end
    return item_name_plural
  end

  def getDisplayNameMachineNumber(item)
    item_data = GameData::Item.get(item)
    item_name = item_data.name
    if item_data.is_machine?
      machine = item_data.move
      item_name = _INTL("{1}", item_name)
    end
    return item_name
  end

  def getDisplayNameMachineName(item)
    item_data = GameData::Item.get(item)
    item_name = item_data.name
    if item_data.is_machine?
      machine = item_data.move
      item_name = _INTL("{1}", GameData::Move.get(machine).name)
    end
    return item_name
  end

  def getDescription(item)
    return GameData::Item.get(item).description
  end

  def getItemIcon(item)
    return (item) ? GameData::Item.icon_filename(item) : nil
  end

  def getQuantity(item)
    return $bag.quantity(item)
  end

  def showQuantity?(item)
    return !GameData::Item.get(item).is_important?
  end

  def getPrice(item, selling = false)
    if $game_temp.mart_prices && $game_temp.mart_prices[item]
      if selling
        return $game_temp.mart_prices[item][1] if $game_temp.mart_prices[item][1] >= 0
      elsif $game_temp.mart_prices[item][0] > 0
        return $game_temp.mart_prices[item][0]
      end
    end
    return GameData::Item.get(item).sell_price if selling
    return GameData::Item.get(item).price
  end

  def canSell?(item)
    return getPrice(item, true) > 0 && !GameData::Item.get(item).is_important?
  end

  def addItem(item)
    return $bag.add(item)
  end

  def removeItem(item)
    return $bag.remove(item)
  end
end

#===============================================================================
# Buy and Sell adapters
#===============================================================================
class BuyAdapter
  def initialize(adapter)
    @adapter = adapter
  end

  # For showing in messages
  def getName(item)
    @adapter.getName(item)
  end

  # For showing in messages
  def getNamePlural(item)
    @adapter.getNamePlural(item)
  end

  # For showing in the list of items
  def getDisplayName(item)
    @adapter.getDisplayName(item)
  end

  # For showing in the list of items
  def getDisplayNamePlural(item)
    @adapter.getDisplayNamePlural(item)
  end

  def getDisplayPrice(item)
    @adapter.getDisplayPrice(item, false)
  end

  def isSelling?
    return false
  end
end

#===============================================================================
#
#===============================================================================
class SellAdapter
  def initialize(adapter)
    @adapter = adapter
  end

  # For showing in messages
  def getName(item)
    @adapter.getName(item)
  end

  # For showing in messages
  def getNamePlural(item)
    @adapter.getNamePlural(item)
  end

  # For showing in the list of items
  def getDisplayName(item)
    @adapter.getDisplayName(item)
  end

  # For showing in the list of items
  def getDisplayNamePlural(item)
    @adapter.getDisplayNamePlural(item)
  end

  def getDisplayPrice(item)
    if @adapter.showQuantity?(item)
      return sprintf("x%d", @adapter.getQuantity(item))
    else
      return ""
    end
  end

  def isSelling?
    return true
  end
end

#===============================================================================
# Pokémon Mart
#===============================================================================
class Window_PokemonMart < Window_DrawableCommand

  CANCEL_TEXT_X_OFFSET    = 0
  CANCEL_TEXT_Y_OFFSET    = 2
  ITEM_NAME_X_OFFSET      = 0
  ITEM_NAME_Y_OFFSET      = 2
  ITEM_QUANTITY_X_OFFSET  = -18
  ITEM_QUANTITY_Y_OFFSET  = 2
  BASE_COLOR              = Color.new(88, 88, 80)
  SHADOW_COLOR            = Color.new(168, 184, 184)


  def initialize(stock, adapter, x, y, width, height, viewport = nil)
    @stock       = stock
    @adapter     = adapter
    super(x, y, width, height, viewport)
    @selarrow    = AnimatedBitmap.new("Graphics/UI/Mart/cursor")
    @baseColor   = BASE_COLOR
    @shadowColor = SHADOW_COLOR
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
      xQty = rect.x + rect.width - sizeQty + ITEM_QUANTITY_X_OFFSET
      textpos.push([itemname, rect.x + ITEM_NAME_X_OFFSET, ypos + ITEM_NAME_Y_OFFSET, :left, self.baseColor, self.shadowColor])
      textpos.push([qty, xQty, ypos + ITEM_QUANTITY_Y_OFFSET, :left, self.baseColor, self.shadowColor])
    end
    pbDrawTextPositions(self.contents, textpos)
  end
end

#===============================================================================
#
#===============================================================================
class PokemonMart_Scene

  QUANTITY_WINDOW_Y_OFFSET      = -102
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
  MONEY_WINDOW_X                = 0
  MONEY_WINDOW_Y                = 0
  MONEY_WINDOW_WIDTH            = 190
  MONEY_WINDOW_HEIGHT           = 96
  QTY_WINDOW_X                  = 0
  QTY_WINDOW_Y_OFFSET           = -102
  QTY_WINDOW_WIDTH              = 190
  QTY_WINDOW_HEIGHT             = 96
  MONEY_WINDOW_SELL_WIDTH       = 190
  MONEY_WINDOW_SELL_HEIGHT      = 96
  SCROLL_MAP_END_DIRECTION      = 4   # Scroll right when opening mart, left when closing
  SCROLL_MAP_END_DISTANCE       = 5
  SCROLL_MAP_END_SPEED          = 5
  DISPLAY_TEXT_LINES            = 2
  CHOOSE_NUMBER_WINDOW_WIDTH    = 224
  CHOOSE_NUMBER_WINDOW_HEIGHT   = 64
  TEXT_BASE_COLOR               = Color.new(248, 248, 248)
  MONEY_BASE_COLOR              = Color.new(88, 88, 80)
  MONEY_SHADOW_COLOR            = Color.new(168, 184, 184)
  QUANTITY_BASE_COLOR           = Color.new(88, 88, 80)
  QUANTITY_SHADOW_COLOR         = Color.new(168, 184, 184)
  
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
      @sprites["qtywindow"].y       = Graphics.height + QUANTITY_WINDOW_Y_OFFSET - @sprites["qtywindow"].height
      itemwindow.refresh
    end
    @sprites["moneywindow"].text = _INTL("Dinero:\n<r>{1}", @adapter.getMoneyString)
  end

  def pbStartBuyOrSellScene(buying, stock, adapter)
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
    winAdapter = buying ? BuyAdapter.new(adapter) : SellAdapter.new(adapter)
    @sprites["itemwindow"] = Window_PokemonMart.new(
      stock, winAdapter, Graphics.width + ITEM_WINDOW_X_OFFSET, ITEM_WINDOW_Y, ITEM_WINDOW_WIDTH, Graphics.height + ITEM_WINDOW_HEIGHT_OFFSET
    )
    @sprites["itemwindow"].viewport = @viewport
    @sprites["itemwindow"].index = 0
    @sprites["itemwindow"].refresh
    @sprites["itemtextwindow"] = Window_UnformattedTextPokemon.newWithSize(
      "", ITEM_TEXT_WINDOW_X, Graphics.height + ITEM_TEXT_WINDOW_Y_OFFSET, Graphics.width + ITEM_TEXT_WINDOW_WIDTH_OFFSET, ITEM_TEXT_WINDOW_HEIGHT, @viewport
    )
    pbPrepareWindow(@sprites["itemtextwindow"])
    @sprites["itemtextwindow"].baseColor = TEXT_BASE_COLOR
    @sprites["itemtextwindow"].shadowColor = Color.black
    @sprites["itemtextwindow"].windowskin = nil
    @sprites["helpwindow"] = Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["helpwindow"])
    @sprites["helpwindow"].visible = false
    @sprites["helpwindow"].viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"], HELP_WINDOW_TEXT_LINES)
    @sprites["moneywindow"] = Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["moneywindow"])
    @sprites["moneywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["moneywindow"].visible = true
    @sprites["moneywindow"].viewport = @viewport
    @sprites["moneywindow"].x = MONEY_WINDOW_X
    @sprites["moneywindow"].y = MONEY_WINDOW_Y
    @sprites["moneywindow"].width = MONEY_WINDOW_WIDTH
    @sprites["moneywindow"].height = MONEY_WINDOW_HEIGHT
    @sprites["moneywindow"].baseColor = MONEY_BASE_COLOR
    @sprites["moneywindow"].shadowColor = MONEY_SHADOW_COLOR
    @sprites["qtywindow"] = Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["qtywindow"])
    @sprites["qtywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["qtywindow"].viewport = @viewport
    @sprites["qtywindow"].width = QTY_WINDOW_WIDTH
    @sprites["qtywindow"].height = QTY_WINDOW_HEIGHT
    @sprites["qtywindow"].baseColor = QUANTITY_BASE_COLOR
    @sprites["qtywindow"].shadowColor = QUANTITY_SHADOW_COLOR
    @sprites["qtywindow"].text = _INTL("En Mochila:<r>{1}", @adapter.getQuantity(@sprites["itemwindow"].item))
    @sprites["qtywindow"].y    = Graphics.height + QTY_WINDOW_Y_OFFSET - @sprites["qtywindow"].height
    pbDeactivateWindows(@sprites)
    @buying = buying
    pbRefresh
    Graphics.frame_reset
  end

  def pbStartBuyScene(stock, adapter)
    pbStartBuyOrSellScene(true, stock, adapter)
  end

  def pbStartSellScene(bag, adapter)
    if $bag
      pbStartSellScene2(bag, adapter)
    else
      pbStartBuyOrSellScene(false, bag, adapter)
    end
  end

  def pbStartSellScene2(bag, adapter)
    @subscene = PokemonBag_Scene.new
    @adapter = adapter
    @viewport2 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport2.z = 99999
    pbWait(0.4) do |delta_t|
      @viewport2.color.alpha = lerp(0, 255, 0.4, delta_t)
    end
    @viewport2.color.alpha = 255
    @subscene.pbStartScene(bag)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["helpwindow"] = Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["helpwindow"])
    @sprites["helpwindow"].visible = false
    @sprites["helpwindow"].viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"], HELP_WINDOW_TEXT_LINES)
    @sprites["moneywindow"] = Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["moneywindow"])
    @sprites["moneywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["moneywindow"].visible = false
    @sprites["moneywindow"].viewport = @viewport
    @sprites["moneywindow"].x = MONEY_WINDOW_X
    @sprites["moneywindow"].y = MONEY_WINDOW_Y
    @sprites["moneywindow"].width = MONEY_WINDOW_SELL_WIDTH
    @sprites["moneywindow"].height = MONEY_WINDOW_SELL_HEIGHT
    @sprites["moneywindow"].baseColor = MONEY_BASE_COLOR
    @sprites["moneywindow"].shadowColor = MONEY_SHADOW_COLOR
    pbDeactivateWindows(@sprites)
    @buying = false
    pbRefresh
  end

  def pbEndBuyScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    # Scroll left after showing screen
    pbScrollMap(SCROLL_MAP_END_DIRECTION, SCROLL_MAP_END_DISTANCE, SCROLL_MAP_END_SPEED)
  end

  def pbEndSellScene
    @subscene&.pbEndScene
    pbDisposeSpriteHash(@sprites)
    if @viewport2
      pbWait(0.4) do |delta_t|
        @viewport2.color.alpha = lerp(255, 0, 0.4, delta_t)
      end
      @viewport2.dispose
    end
    @viewport.dispose
    pbScrollMap(SCROLL_MAP_END_DIRECTION, SCROLL_MAP_END_DISTANCE, SCROLL_MAP_END_SPEED) if !@subscene
  end

  def pbPrepareWindow(window)
    window.visible = true
    window.letterbyletter = false
  end

  def pbShowMoney
    pbRefresh
    @sprites["moneywindow"].visible = true
  end

  def pbHideMoney
    pbRefresh
    @sprites["moneywindow"].visible = false
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
    itemprice = @adapter.getPrice(item, !@buying)
    pbDisplay(helptext, true)
    using(numwindow = Window_AdvancedTextPokemon.new("")) do   # Showing number of items
      pbPrepareWindow(numwindow)
      numwindow.viewport = @viewport
      numwindow.width = CHOOSE_NUMBER_WINDOW_WIDTH
      numwindow.height = CHOOSE_NUMBER_WINDOW_HEIGHT
      numwindow.baseColor = MONEY_BASE_COLOR
      numwindow.shadowColor = MONEY_SHADOW_COLOR
      numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
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
            numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
            pbPlayCursorSE
          end
        elsif Input.repeat?(Input::RIGHT)
          curnumber += 10
          curnumber = maximum if curnumber > maximum
          if curnumber != oldnumber
            numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
            pbPlayCursorSE
          end
        elsif Input.repeat?(Input::UP)
          curnumber += 1
          curnumber = 1 if curnumber > maximum
          if curnumber != oldnumber
            numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
            pbPlayCursorSE
          end
        elsif Input.repeat?(Input::DOWN)
          curnumber -= 1
          curnumber = maximum if curnumber < 1
          if curnumber != oldnumber
            numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
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

  def pbChooseBuyItem
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

  def pbChooseSellItem
    if @subscene
      return @subscene.pbChooseItem
    else
      return pbChooseBuyItem
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonMartScreen
  def initialize(scene, stock)
    @scene = scene
    @stock = stock
    @adapter = PokemonItemMartAdapter.new
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
    @scene.pbStartBuyScene(@stock, @adapter)
    item = nil
    loop do
      item = @scene.pbChooseBuyItem
      break if !item
      quantity       = 0
      itemname       = @adapter.getName(item)
      itemnameplural = @adapter.getNamePlural(item)
      price = @adapter.getPrice(item)
      if @adapter.getMoney < price
        pbDisplayPaused(_INTL("No tienes suficiente dinero."))
        next
      end
      if GameData::Item.get(item).is_important?
        next if !pbConfirm(_INTL("¿Así que quieres {1}?\nSerán ${2}. ¿Te parece bien?",
                                 itemname, price.to_s_formatted))
        quantity = 1
      else
        maxafford = (price <= 0) ? Settings::BAG_MAX_PER_SLOT : @adapter.getMoney / price
        maxafford = Settings::BAG_MAX_PER_SLOT if maxafford > Settings::BAG_MAX_PER_SLOT
        quantity = @scene.pbChooseNumber(
          _INTL("¿Cuántos {1} quieres?", itemnameplural), item, maxafford
        )
        next if quantity == 0
        price *= quantity
        if quantity > 1
          next if !pbConfirm(_INTL("¿Así que quieres {1} {2}?\nSerán ${3}. ¿Te parece bien?",
                                   quantity, itemnameplural, price.to_s_formatted))
        elsif quantity > 0
          next if !pbConfirm(_INTL("¿Así que quieres {1} {2}?\nSerán ${3}. ¿Te parece bien?",
                                   quantity, itemname, price.to_s_formatted))
        end
      end
      if @adapter.getMoney < price
        pbDisplayPaused(_INTL("No tienes suficiente dinero."))
        next
      end
      added = 0
      quantity.times do
        break if !@adapter.addItem(item)
        added += 1
      end
      if added == quantity
        $stats.money_spent_at_marts += price
        $stats.mart_items_bought += quantity
        @adapter.setMoney(@adapter.getMoney - price)
        @stock.delete_if { |itm| GameData::Item.get(itm).is_important? && $bag.has?(itm) }
        pbDisplayPaused(_INTL("¡Aquí tienes! ¡Muchas gracias!")) { pbSEPlay("Mart buy item") }
        if quantity >= 10 && GameData::Item.exists?(:PREMIERBALL)
          if Settings::MORE_BONUS_PREMIER_BALLS && GameData::Item.get(item).is_poke_ball?
            premier_balls_added = 0
            (quantity / 10).times do
              break if !@adapter.addItem(:PREMIERBALL)
              premier_balls_added += 1
            end
            ball_name = GameData::Item.get(:PREMIERBALL).portion_name
            ball_name = GameData::Item.get(:PREMIERBALL).portion_name_plural if premier_balls_added > 1
            $stats.premier_balls_earned += premier_balls_added
            pbDisplayPaused(_INTL("Recibes {1} {2} extra.", premier_balls_added, ball_name))
          elsif !Settings::MORE_BONUS_PREMIER_BALLS && GameData::Item.get(item) == :POKEBALL
            if @adapter.addItem(:PREMIERBALL)
              ball_name = GameData::Item.get(:PREMIERBALL).name
              $stats.premier_balls_earned += 1
              pbDisplayPaused(_INTL("Recibes 1 {1} extra.", ball_name))
            end
          end
        end
      else
        added.times do
          if !@adapter.removeItem(item)
            raise _INTL("Fallo al eliminar los objetos guardados")
          end
        end
        pbDisplayPaused(_INTL("No tienes hueco en tu Mochila."))
      end
    end
    @scene.pbEndBuyScene
  end

  def pbSellScreen
    item = @scene.pbStartSellScene(@adapter.getInventory, @adapter)
    loop do
      item = @scene.pbChooseSellItem
      break if !item
      itemname       = @adapter.getName(item)
      itemnameplural = @adapter.getNamePlural(item)
      if !@adapter.canSell?(item)
        pbDisplayPaused(_INTL("Oh, no. No puedo comprar {1}.", itemnameplural))
        next
      end
      price = @adapter.getPrice(item, true)
      qty = @adapter.getQuantity(item)
      next if qty == 0
      @scene.pbShowMoney
      if qty > 1
        qty = @scene.pbChooseNumber(
          _INTL("¿Cuántos {1} quieres vender?", itemnameplural), item, qty
        )
      end
      if qty == 0
        @scene.pbHideMoney
        next
      end
      price *= qty
      if pbConfirm(_INTL("Puedo pagarte ${1}.\n¿Te parece bien?", price.to_s_formatted))
        old_money = @adapter.getMoney
        @adapter.setMoney(@adapter.getMoney + price)
        $stats.money_earned_at_marts += @adapter.getMoney - old_money
        qty.times { @adapter.removeItem(item) }
        sold_item_name = (qty > 1) ? itemnameplural : itemname
        pbDisplayPaused(_INTL("Has entregado {1} y has recibido ${2}.",
                              sold_item_name, price.to_s_formatted)) { pbSEPlay("Mart buy item") }
        @scene.pbRefresh
      end
      @scene.pbHideMoney
    end
    @scene.pbEndSellScene
  end
end

#===============================================================================
#
#===============================================================================
def pbPokemonMart(stock, speech = nil, cantsell = false)
  stock.delete_if { |item| GameData::Item.get(item).is_important? && $bag.has?(item) }
  commands = []
  cmdBuy  = -1
  cmdSell = -1
  cmdQuit = -1
  commands[cmdBuy = commands.length]  = _INTL("Quiero comprar")
  commands[cmdSell = commands.length] = _INTL("Quiero vender") if !cantsell
  commands[cmdQuit = commands.length] = _INTL("No, gracias")
  cmd = pbMessage(speech || _INTL("¡Bienvenido! ¿En qué te puedo ayudar?"), commands, cmdQuit + 1)
  loop do
    if cmdBuy >= 0 && cmd == cmdBuy
      scene = PokemonMart_Scene.new
      screen = PokemonMartScreen.new(scene, stock)
      screen.pbBuyScreen
    elsif cmdSell >= 0 && cmd == cmdSell
      scene = PokemonMart_Scene.new
      screen = PokemonMartScreen.new(scene, stock)
      screen.pbSellScreen
    else
      pbMessage(_INTL("¡Vuelve pronto!"))
      break
    end
    cmd = pbMessage(_INTL("¿Puedo ayudarte en algo más?"), commands, cmdQuit + 1)
  end
  $game_temp.clear_mart_prices
end

