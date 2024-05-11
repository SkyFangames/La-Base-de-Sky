#===============================================================================
# * Pokegear - by LinKazamine and CynderHydra (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It adds a themes the Pokégear.
#===============================================================================

if !PluginManager.installed?("Arcky's Region Map")
  class PokemonRegionMap_Scene
    def pbStartScene(as_editor = false, fly_map = false)
      @editor   = as_editor
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999
      @sprites = {}
      @fly_map = fly_map
      @mode    = fly_map ? 1 : 0
      map_metadata = $game_map.metadata
      playerpos = (map_metadata) ? map_metadata.town_map_position : nil
      if !playerpos
        mapindex = 0
        @map     = GameData::TownMap.get(0)
        @map_x   = LEFT
        @map_y   = TOP
      elsif @region >= 0 && @region != playerpos[0] && GameData::TownMap.exists?(@region)
        mapindex = @region
        @map     = GameData::TownMap.get(@region)
        @map_x   = LEFT
        @map_y   = TOP
      else
        mapindex = playerpos[0]
        @map     = GameData::TownMap.get(playerpos[0])
        @map_x   = playerpos[1]
        @map_y   = playerpos[2]
        mapsize  = map_metadata.town_map_size
        if mapsize && mapsize[0] && mapsize[0] > 0
          sqwidth  = mapsize[0]
          sqheight = (mapsize[1].length.to_f / mapsize[0]).ceil
          @map_x += ($game_player.x * sqwidth / $game_map.width).floor if sqwidth > 1
          @map_y += ($game_player.y * sqheight / $game_map.height).floor if sqheight > 1
        end
      end
      if !@map
        pbMessage(_INTL("No se encontró la información del mapa."))
        return false
      end
      addBackgroundOrColoredPlane(@sprites, "background", "Town Map/bg", Color.black, @viewport)
      @sprites["background"] = IconSprite.new(0, 0, @viewport)
      @sprites["background"].setBitmap("Graphics/UI/Pokegear/#{$PokemonSystem.pokegear}/mapbg")
      @sprites["map"] = IconSprite.new(0, 0, @viewport)
      @sprites["map"].setBitmap("Graphics/UI/Town Map/#{@map.filename}")
      @sprites["map"].x += (Graphics.width - @sprites["map"].bitmap.width) / 2
      @sprites["map"].y += (Graphics.height - @sprites["map"].bitmap.height) / 2
      Settings::REGION_MAP_EXTRAS.each do |graphic|
        next if graphic[0] != mapindex || !location_shown?(graphic)
        if !@sprites["map2"]
          @sprites["map2"] = BitmapSprite.new(480, 320, @viewport)
          @sprites["map2"].x = @sprites["map"].x
          @sprites["map2"].y = @sprites["map"].y
        end
        pbDrawImagePositions(
          @sprites["map2"].bitmap,
          [["Graphics/UI/Town Map/#{graphic[4]}", graphic[2] * SQUARE_WIDTH, graphic[3] * SQUARE_HEIGHT]]
        )
      end
      @sprites["bgover"] = IconSprite.new(0, 0, @viewport)
      @sprites["bgover"].setBitmap("Graphics/UI/Pokegear/#{$PokemonSystem.pokegear}/mapbg_over")
      @sprites["mapbottom"] = MapBottomSprite.new(@viewport)
      @sprites["mapbottom"].mapname     = @map.name
      @sprites["mapbottom"].maplocation = pbGetMapLocation(@map_x, @map_y)
      @sprites["mapbottom"].mapdetails  = pbGetMapDetails(@map_x, @map_y)
      if playerpos && mapindex == playerpos[0]
        @sprites["player"] = IconSprite.new(0, 0, @viewport)
        @sprites["player"].setBitmap(GameData::TrainerType.player_map_icon_filename($player.trainer_type))
        @sprites["player"].x = point_x_to_screen_x(@map_x)
        @sprites["player"].y = point_y_to_screen_y(@map_y)
      end
      k = 0
      (LEFT..RIGHT).each do |i|
        (TOP..BOTTOM).each do |j|
          healspot = pbGetHealingSpot(i, j)
          next if !healspot || !$PokemonGlobal.visitedMaps[healspot[0]]
          @sprites["point#{k}"] = AnimatedSprite.create("Graphics/UI/Town Map/icon_fly", 2, 16)
          @sprites["point#{k}"].viewport = @viewport
          @sprites["point#{k}"].x        = point_x_to_screen_x(i)
          @sprites["point#{k}"].y        = point_y_to_screen_y(j)
          @sprites["point#{k}"].visible  = @mode == 1
          @sprites["point#{k}"].play
          k += 1
        end
      end
      @sprites["cursor"] = AnimatedSprite.create("Graphics/UI/Town Map/cursor", 2, 5)
      @sprites["cursor"].viewport = @viewport
      @sprites["cursor"].x        = point_x_to_screen_x(@map_x)
      @sprites["cursor"].y        = point_y_to_screen_y(@map_y)
      @sprites["cursor"].play
      @sprites["help"] = BitmapSprite.new(Graphics.width, 32, @viewport)
      pbSetSystemFont(@sprites["help"].bitmap)
      refresh_fly_screen
      @changed = false
      pbFadeInAndShow(@sprites) { pbUpdate }
    end
  end
end
