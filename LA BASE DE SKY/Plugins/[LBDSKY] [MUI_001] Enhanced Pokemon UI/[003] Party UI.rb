#===============================================================================
# Party Menu UI edits.
#===============================================================================
if Settings::SHOW_PARTY_BALL
  class PokemonPartyPanel < Sprite
    alias enhanced_initialize initialize
    def initialize(*args)
      enhanced_initialize(*args)
      GameData::Item.each do |ball|
        next if !ball.is_poke_ball?
        sprite = Settings::POKEMON_UI_GRAPHICS_PATH + "Party Ball/#{ball.id}"
        next if !pbResolveBitmap(sprite)
        @ballsprite.addBitmap("#{ball.id}_desel", sprite)
        @ballsprite.addBitmap("#{ball.id}_sel", sprite + "_sel")
      end
      refresh
    end
	
    alias enhanced_refresh_ball_graphic refresh_ball_graphic
    def refresh_ball_graphic
      enhanced_refresh_ball_graphic
      if @ballsprite && !@ballsprite.disposed?
        ball = @pokemon.poke_ball
        path = Settings::POKEMON_UI_GRAPHICS_PATH + "Party Ball/#{ball}"
        ball_sel   = pbResolveBitmap(path + "_sel") ? "#{ball}_sel"   : "sel"
        ball_desel = pbResolveBitmap(path)          ? "#{ball}_desel" : "desel"
        @ballsprite.changeBitmap((self.selected) ? ball_sel : ball_desel)
      end
    end
  end
end