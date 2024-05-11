if Settings::SHOW_ITEM_DESCRIPTIONS_ON_RECEIVE
  #-------------------------------------------------------------------------------
  # Item Find
  # v2.0
  # By Boonzeet
  # Website      = https://reliccastle.com/resources/371/
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
  
      @sprites["itemicon"] = ItemIconSprite.new(42, Graphics.height - 48, item.id, @viewport)
      @sprites["itemicon"].visible = false
      @sprites["itemicon"].z = @viewport.z + 2
      
      
      @sprites["descwindow"] = Window_UnformattedTextPokemon.newWithSize("", 64, 0, Graphics.width - 64, 64, @viewport)
      @sprites["descwindow"].windowskin = nil
      @sprites["descwindow"].z = @viewport.z
      @sprites["descwindow"].visible = false
      @sprites["descwindow"].baseColor = colors[0]
      @sprites["descwindow"].shadowColor = colors[1]
  
      @sprites["titlewindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 128, 16, @viewport)
      @sprites["titlewindow"].visible = false
      @sprites["titlewindow"].z = @viewport.z + 1
      @sprites["titlewindow"].windowskin = nil
      @sprites["titlewindow"].baseColor = colors[0]
      @sprites["titlewindow"].shadowColor = colors[1]
  
    end
  
    def pbShow(item)
      item_object = GameData::Item.try_get(item)
      name = item_object.name
      description = item_object.description
  
      descwindow = @sprites["descwindow"]
      descwindow.resizeToFit(description, Graphics.width - 64)
      descwindow.text = description
      descwindow.y = Graphics.height - descwindow.height
      descwindow.visible = true
  
      titlewindow = @sprites["titlewindow"]
      titlewindow.resizeToFit(name, Graphics.height)
      titlewindow.text = name
      titlewindow.y = Graphics.height - descwindow.height - 32
      titlewindow.visible = true
  
      background = @sprites["background"]
      background.height = descwindow.height + 32
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
        if Input.trigger?(Input::B) || Input.trigger?(Input::C)
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
  def pbItemBall(item,quantity=1)
    result = pbItemBall_itemfind(item,quantity)
    $item_log.register(item) if result
    return result
  end
  
  alias pbReceiveItem_itemfind pbReceiveItem
  def pbReceiveItem(item,quantity=1)
    result = pbReceiveItem_itemfind(item,quantity)
    $item_log.register(item) if result
    return result
  end
  
  alias pbPickBerry_itemfind pbPickBerry
  def pbPickBerry(berry, qty = 1)
    pbPickBerry_itemfind(berry,qty)
    $item_log.register(berry) if $bag.has?(berry)
  end
end
