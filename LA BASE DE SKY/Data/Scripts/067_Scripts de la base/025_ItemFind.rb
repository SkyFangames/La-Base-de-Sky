if Settings::SHOW_ITEM_DESCRIPTIONS_ON_RECEIVE
  #-------------------------------------------------------------------------------
  # Item Find
  # v2.0
  # By Boonzeet
  # Website      = https://eeveexpo.com/resources/371/
  #-------------------------------------------------------------------------------
  # A script to show a helpful message with item name, icon and description
  # when an item is found for the first time.
  #-------------------------------------------------------------------------------
  
  WINDOWSKIN_NAME = "" # set for custom windowskin
  
  #-------------------------------------------------------------------------------
  # Save data registry
  #-------------------------------------------------------------------------------
  SaveData.register(:item_log) do
    save_value { $item_log }
    load_value { |value| $item_log = value }
    new_game_value { ItemLog.new }
  end
  
  #-------------------------------------------------------------------------------
  # Base Class
  #-------------------------------------------------------------------------------
  
  class PokemonItemFind_Scene
    
    ITEM_ICON_X = 42
    ITEM_ICON_Y_OFFSET = -48
    DESC_WINDOW_X = 64
    DESC_WINDOW_Y = 0
    DESC_WINDOW_WIDTH_OFFSET = -64
    DESC_WINDOW_HEIGHT = 64
    TITLE_WINDOW_X = 0
    TITLE_WINDOW_Y = 0
    TITLE_WINDOW_WIDTH = 128
    TITLE_WINDOW_HEIGHT = 16

    def pbStartScene(item)
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999
      @sprites = {}
      skin = WINDOWSKIN_NAME == "" ? MessageConfig.pbGetSystemFrame : "Graphics/Windowskins/" + WINDOWSKIN_NAME
      
      
      @sprites["background"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, Graphics.width, 0, @viewport)
      @sprites["background"].z = @viewport.z - 1
      @sprites["background"].visible = false
  
  
      @sprites["background"].setSkin(skin)
      
      colors = getDefaultTextColors(@sprites["background"].windowskin)
  
      @sprites["itemicon"] = ItemIconSprite.new(ITEM_ICON_X, Graphics.height + ITEM_ICON_Y_OFFSET, item.id, @viewport)
      @sprites["itemicon"].visible = false
      @sprites["itemicon"].z = @viewport.z + 2
      
      
      @sprites["descwindow"] = Window_UnformattedTextPokemon.newWithSize("", DESC_WINDOW_X, DESC_WINDOW_Y, Graphics.width + DESC_WINDOW_WIDTH_OFFSET, DESC_WINDOW_HEIGHT, @viewport)
      @sprites["descwindow"].windowskin = nil
      @sprites["descwindow"].z = @viewport.z
      @sprites["descwindow"].visible = false
      @sprites["descwindow"].baseColor = colors[0]
      @sprites["descwindow"].shadowColor = colors[1]
  
      @sprites["titlewindow"] = Window_UnformattedTextPokemon.newWithSize("", TITLE_WINDOW_X, TITLE_WINDOW_Y, TITLE_WINDOW_WIDTH, TITLE_WINDOW_HEIGHT, @viewport)
      @sprites["titlewindow"].visible = false
      @sprites["titlewindow"].z = @viewport.z + 1
      @sprites["titlewindow"].windowskin = nil
      @sprites["titlewindow"].baseColor = colors[0]
      @sprites["titlewindow"].shadowColor = colors[1]
  
    end
  
    def pbShow(item)
      item_object = GameData::Item.try_get(item)
      name = item_object.name
      if item_object.is_machine?
        machine = GameData::Item.get(item_object).move
        name = _INTL("{1} {2}", name, GameData::Move.get(machine).name)
      end
      description = item_object.description
  
      descwindow = @sprites["descwindow"]
      descwindow.resizeToFit(description, Graphics.width + DESC_WINDOW_WIDTH_OFFSET)
      descwindow.text = description
      descwindow.y = Graphics.height - descwindow.height
      descwindow.visible = true
  
      titlewindow = @sprites["titlewindow"]
      titlewindow.resizeToFit(name, Graphics.height)
      titlewindow.text = name
      titlewindow.y = Graphics.height - descwindow.height - TITLE_WINDOW_HEIGHT * 2
      titlewindow.visible = true
  
      background = @sprites["background"]
      background.height = descwindow.height + DESC_WINDOW_HEIGHT / 2
      background.y = Graphics.height - background.height
      background.visible = true
  
      itemicon = @sprites["itemicon"]
      itemicon.item = item
      itemicon.y = Graphics.height - (descwindow.height / 2).floor
      itemicon.visible = true
  
      loop do
        background.update
        itemicon.update
        descwindow.update
        titlewindow.update
        Graphics.update
        Input.update
        pbUpdateSceneMap
        if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
          pbEndScene
          break
        end
      end
    end
  
    def pbEndScene
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end
  end
  
  
  #-------------------------------------------------------------------------------
  # Item Log class
  #-------------------------------------------------------------------------------
  # The store of found items
  #-------------------------------------------------------------------------------
  class ItemLog
    def initialize()
      @found_items = []
    end
  
    def register(item)
      if !@found_items.include?(item)
        @found_items.push(item)
        item_object = GameData::Item.try_get(item)
        scene = PokemonItemFind_Scene.new
        scene.pbStartScene(item_object)
        scene.pbShow(item)
      end
    end
  end
  
  #-------------------------------------------------------------------------------
  # Overrides of pbItemBall and pbReceiveItem
  #-------------------------------------------------------------------------------
  # Picking up an item found on the ground
  #-------------------------------------------------------------------------------
  
  alias pbItemBall_itemfind pbItemBall
  def pbItemBall(item, quantity = 1, outfit = nil)
    result = pbItemBall_itemfind(item, quantity, outfit)
    $item_log.register(item) if result
    return result
  end
  
  alias pbReceiveItem_itemfind pbReceiveItem
  def pbReceiveItem(item, quantity = 1, outfit_change = nil)
    result = pbReceiveItem_itemfind(item, quantity, outfit_change)
    $item_log.register(item) if result
    return result
  end
  
  alias pbPickBerry_itemfind pbPickBerry
  def pbPickBerry(berry, qty = 1)
    ret = pbPickBerry_itemfind(berry,qty)
    $item_log.register(berry) if $bag.has?(berry)
    return ret
  end
end
