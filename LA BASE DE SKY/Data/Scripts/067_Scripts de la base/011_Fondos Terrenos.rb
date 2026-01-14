HAZARD_OPACITY = 180
class Battle::Scene
  
  def sceneWait(numframes)
    numframes.times do
      pbGraphicsUpdate
      pbFrameUpdate
      Input.update
    end
  end
  
  def pbDeleteField(bg = 'terrain_bg', base1 = 'base_terrain_0', base2 = 'base_terrain_1')
    if @sprites[bg]&.visible
      20.times do
        @sprites[bg].opacity -= 8
        @sprites[base1].opacity -= 8
        @sprites[base2].opacity -= 8
        sceneWait(2)
      end
    end
  end

  def pbDeleteTrickRoomBackground
    if @sprites["trick_room_bg"]&.visible
      25.times do
        @sprites["trick_room_bg"].opacity -= 8
        sceneWait(2)
      end
    end
  end

  def pbSetTrickRoomBackground
    if @battle.field.effects[PBEffects::TrickRoom] <= 0
      pbDeleteTrickRoomBackground
    else
      bg = pbAddSprite("trick_room_bg", 0, 0, "Graphics/Animations/PRAS- Trick Room BG", @viewport)
      bg.z = 1
      bg.opacity = 0
      bg.visible = true

      pbSEPlay("PRSFX- Trick Room", 80)
      25.times do
        @sprites["trick_room_bg"].opacity += 8
        sceneWait(2)
      end
    end
  end
  
  def pbSetFieldBackground
    if @battle.field.terrain == :None 
      pbCreateBackdropSprites
      pbDeleteField
    else
      pbDeleteField
      
      if @battle.field.terrain == :Grassy
        field = "Grassy Terrain"
        sound = "PRSFX- Grassy Terrain"
      elsif @battle.field.terrain == :Misty
        field = "Misty Terrain"
        sound = "PRSFX- Misty Terrain"
      elsif @battle.field.terrain == :Psychic
        field = "Psychic Terrain"
        sound = "PRSFX- Psychic Terrain"
      elsif @battle.field.terrain == :Electric
        field = "Electric Terrain"
        sound = "PRSFX- Electric Terrain"
      end
      
      bg = pbAddSprite("terrain_bg", 0, 0, "Graphics/Animations/PRAS- #{field} BG", @viewport)
      bg.z = 2
      bg.opacity = 0
      bg.visible = true

      playerBase = "Graphics/Animations/#{field}playerbase"
      enemyBase  = "Graphics/Animations/#{field}enemybase"

      2.times do |side|
        baseX, baseY = Battle::Scene.pbBattlerPosition(side)
        base = pbAddSprite("base_terrain_#{side}", baseX, baseY,
                           (side == 0) ? playerBase : enemyBase, @viewport)
        base.z = 3
        base.opacity = 0
        base.visible = true
        if base.bitmap
          base.ox = base.bitmap.width / 2
          base.oy = (side == 0) ? base.bitmap.height : base.bitmap.height / 2
        end
      end

      pbSEPlay(sound, 80)
      20.times do
        @sprites["terrain_bg"].opacity += 8
        @sprites["base_terrain_0"].opacity += 8
        @sprites["base_terrain_1"].opacity += 8
        sceneWait(2)
      end
    end
    
    # Update hazard visuals after setting terrain
    pbUpdateHazardSprites
  end

  # Clear all hazard sprites
  def pbDeleteHazardSprites
    return if !Settings::SHOW_HAZARDS_IN_BATTLE
    # Clear all possible hazard sprites for both sides
    ["stealthrock_0", "stealthrock_1", "stickyweb_0", "stickyweb_1"].each do |sprite_id|
      if @sprites[sprite_id]
        @sprites[sprite_id].visible = false
        @sprites[sprite_id].dispose
        @sprites.delete(sprite_id)
      end
    end
    
    # Clear spikes (up to 3 layers per side)
    2.times do |side|
      3.times do |layer|
        sprite_id = "spikes_#{side}_#{layer}"
        if @sprites[sprite_id]
          @sprites[sprite_id].visible = false
          @sprites[sprite_id].dispose
          @sprites.delete(sprite_id)
        end
      end
    end
    
    # Clear toxic spikes (up to 2 layers per side)
    2.times do |side|
      2.times do |layer|
        sprite_id = "toxicspikes_#{side}_#{layer}"
        if @sprites[sprite_id]
          @sprites[sprite_id].visible = false
          @sprites[sprite_id].dispose
          @sprites.delete(sprite_id)
        end
      end
    end
  end

  # Update all hazard sprites based on current battle state
  def pbUpdateHazardSprites
    return if !@battle
    return if !Settings::SHOW_HAZARDS_IN_BATTLE

    hazards_folder = File.join("Graphics", "UI", "Battle", "hazards")
    
    begin
      pbDeleteHazardSprites
    rescue
      # Silently handle any errors in deleting sprites
    end
    
    2.times do |side|
      sideData = @battle.sides[side]
      baseX, baseY = Battle::Scene.pbBattlerPosition(side)
      

      
      # Stealth Rock - appears floating around the field
      if sideData.effects[PBEffects::StealthRock]
        offset_x = [10, 10][side]           # Spread horizontally
        offset_y = [20, -10][side]         # Keep near the base level
        stealth = pbAddSprite("stealthrock_#{side}", baseX + offset_x, baseY + offset_y,
                             File.join(hazards_folder, "stealth_rock"), @viewport)
        stealth.z = 4
        stealth.opacity = HAZARD_OPACITY
        stealth.visible = true
        if stealth.bitmap
          stealth.ox = stealth.bitmap.width / 2
          stealth.oy = stealth.bitmap.height / 2
        end
      end
      
      # Spikes - appears on the ground (up to 3 layers)
      spikes_count = sideData.effects[PBEffects::Spikes]
      spikes_count.times do |layer|
          # Position spikes in different locations for each layer
          offset_x = [[0, -25, 25], [0, -25, 25]][side][layer]        # Spread horizontally
          offset_y = [[0, 5, -5], [0, 5, -5]][side][layer]          # Keep near the base level
          
          final_x = baseX + offset_x
          final_y = baseY + offset_y
        
        # Try the custom hazards folder first, fallback to original graphics
        spikes_graphic = File.join(hazards_folder, "spikes")
        
        spikes = pbAddSprite("spikes_#{side}_#{layer}", final_x, final_y, spikes_graphic, @viewport)
        spikes.z = 4 + layer * 0.1  # Slight z-ordering for layers
        spikes.opacity = HAZARD_OPACITY  # Each layer more visible: 150, 175, 200
        spikes.visible = true
        
        if spikes.bitmap
          spikes.ox = spikes.bitmap.width / 2
          spikes.oy = (side == 0) ? spikes.bitmap.height : spikes.bitmap.height / 2
        end
      end
      
      # Toxic Spikes - appears on the ground (up to 2 layers)
      toxic_count = sideData.effects[PBEffects::ToxicSpikes]
      toxic_count.times do |layer|
        # Position toxic spikes in different locations for each layer  
        offset_x = [[25, -25], [25, -25]][side][layer]           # Spread horizontally
        offset_y = [[30, 30], [-20, -20]][side][layer]            # Keep near the base level
        
        toxic = pbAddSprite("toxicspikes_#{side}_#{layer}", baseX + offset_x, baseY + offset_y,
                           File.join(hazards_folder, "toxic_spikes"), @viewport)
        toxic.z = 4 + layer * 0.1  # Slight z-ordering for layers
        # toxic.z = 100 + layer * 0.1 if side == 0 # Slight z-ordering for layers 
        toxic.opacity = HAZARD_OPACITY  # Each layer more visible: 140, 180
        toxic.visible = true

        if toxic.bitmap
          toxic.ox = toxic.bitmap.width / 2
          toxic.oy = (side == 0) ? toxic.bitmap.height : toxic.bitmap.height / 2
        end
      end
      
      # Sticky Web - appears as webbing on the ground
      if sideData.effects[PBEffects::StickyWeb]
        offset_x = [10, 0][side]           # Spread horizontally
        offset_y = [20, -20][side]            # Keep near the base level
        web = pbAddSprite("stickyweb_#{side}", baseX + offset_x, baseY + offset_y,
                         File.join(hazards_folder, "sticky_web"), @viewport)
        web.z = 4
        web.opacity = HAZARD_OPACITY
        web.visible = true
        if web.bitmap
          web.ox = web.bitmap.width / 2
          web.oy = (side == 0) ? web.bitmap.height : web.bitmap.height / 2
        end
      end
    end
  end
end

class Battle
  def on_terrain_start
    @scene.pbSetFieldBackground
  end

  alias pbEndTerrain_bg pbEndTerrain
  def pbEndTerrain
    pbEndTerrain_bg
    @scene.pbSetFieldBackground
  end
end
