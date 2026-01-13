#===============================================================================
# Storage UI edits.
#===============================================================================
class PokemonStorageScene

  SHINY_LEAF_X = 158
  SHINY_LEAF_Y = 50
  IV_RATING_X = 8
  IV_RATING_Y = 198
   
  def pbUpdateOverlay(selection, party = nil)
    if !@sprites["plugin_overlay"]
      @sprites["plugin_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @boxsidesviewport)
      pbSetSystemFont(@sprites["plugin_overlay"].bitmap)
    end
    plugin_overlay = @sprites["plugin_overlay"].bitmap
    plugin_overlay.clear
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    buttonbase = Color.new(248, 248, 248)
    buttonshadow = Color.new(80, 80, 80)
    pbDrawTextPositions(
      overlay,
      [[_INTL("Equipo: {1}", (@storage.party.length rescue 0)), TEAM_TEXT_X, TEAM_TEXT_Y, :center, buttonbase, buttonshadow, :outline],
       [_INTL("Salir"), EXIT_TEXT_X, EXIT_TEXT_Y, :center, buttonbase, buttonshadow, :outline]]
    )
    pokemon = nil
    if @screen.pbHeldPokemon
      pokemon = @screen.pbHeldPokemon
    elsif selection >= 0
      pokemon = (party) ? party[selection] : @storage[@storage.currentBox, selection]
    end
    if !pokemon
      @sprites["pokemon"].visible = false
      return
    end
    @sprites["pokemon"].visible = true
    base   = Color.new(88, 88, 80)
    shadow = Color.new(168, 184, 184)
    nonbase   = Color.new(208, 208, 208)
    nonshadow = Color.new(224, 224, 224)
    pokename = pokemon.name
    textstrings = [
      [pokename, POKENAME_TEXT_X, POKENAME_TEXT_Y, :left, base, shadow]
    ]
    if !pokemon.egg?
      imagepos = []
      if pokemon.male?
        textstrings.push([_INTL("♂"), GENDER_ICON_TEXT_X, GENDER_ICON_TEXT_Y, :left, Color.new(24, 112, 216), Color.new(136, 168, 208)])
      elsif pokemon.female?
        textstrings.push([_INTL("♀"), GENDER_ICON_TEXT_X, GENDER_ICON_TEXT_Y, :left, Color.new(248, 56, 32), Color.new(224, 152, 144)])
      end
      imagepos.push([_INTL("Graphics/UI/Storage/overlay_lv"), LEVEL_ICON_X, LEVEL_ICON_Y])
      textstrings.push([pokemon.level.to_s, LEVEL_NUMBER_X, LEVEL_NUMBER_Y, :left, base, shadow])
      if pokemon.ability
        textstrings.push([pokemon.ability.name, ABILITY_NAME_X, ABILITY_NAME_Y, :center, base, shadow])
      else
        textstrings.push([_INTL("Sin habilidad"), ABILITY_NAME_X, ABILITY_NAME_Y, :center, nonbase, nonshadow])
      end
      if pokemon.item
        textstrings.push([pokemon.item.name, ITEM_NAME_X, ITEM_NAME_Y, :center, base, shadow])
      else
        textstrings.push([_INTL("Sin objeto"), ITEM_NAME_X, ITEM_NAME_Y, :center, nonbase, nonshadow])
      end
      if pokemon.shiny?
        pbDrawImagePositions(plugin_overlay, [["Graphics/Pictures/shiny", SHINY_ICON_X, SHINY_ICON_Y]])
      end
      pbDisplayShinyLeaf(pokemon, plugin_overlay, SHINY_LEAF_X, SHINY_LEAF_Y)      if Settings::STORAGE_SHINY_LEAF
      pbDisplayIVRatings(pokemon, plugin_overlay, IV_RATING_X, IV_RATING_Y, true) if Settings::STORAGE_IV_RATINGS
      typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
      pokemon.types.each_with_index do |type, i|
        type_number = GameData::Type.get(type).icon_position
        type_rect = Rect.new(0, type_number * TYPE_ICON_HEIGHT, TYPE_ICON_RECT_WIDTH, TYPE_ICON_HEIGHT)
        type_x = (pokemon.types.length == 1) ? TYPE_ICON_X_1 : TYPE_ICON_X_2 + (TYPE_ICON_X_SPACING * i)
        overlay.blt(type_x, TYPE_ICON_Y, typebitmap.bitmap, type_rect)
      end
      drawMarkings(overlay, MARKINGS_X, MARKINGS_Y, MARKING_RECT_WIDTH, MARKING_RECT_HEIGHT, pokemon.markings)
      pbDrawImagePositions(overlay, imagepos)
    end
    pbDrawTextPositions(overlay, textstrings)
    @sprites["pokemon"].setPokemonBitmap(pokemon)
    @sprites["pokemon"].make_grey_if_fainted = pokemon.fainted? if pokemon
  end
end	