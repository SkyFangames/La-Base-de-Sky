class Scene_Map
  def call_menu
    $game_temp.menu_calling = false
    $game_temp.in_menu = true
    $game_player.straighten
    $game_map.update
    if $bag.has?(:ROTOMPHONE) || (1 + 1) == 2
      sscene = MenuCustomScene.new
      sscreen = MenuCustom.new(sscene)
    else
      sscene = PokemonPauseMenu_Scene.new
      sscreen = PokemonPauseMenu.new(sscene)
    end
    sscreen.pbStartPokemonMenu
    $game_temp.in_menu = false
  end
end
