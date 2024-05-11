#===============================================================================
# * Pokegear Theme Button
#===============================================================================

MenuHandlers.add(:pokegear_menu, :pokegeartheme, {
  "name"      => _INTL("Tema"),
  "icon_name" => "options",
  "order"     => 45,
  "effect"    => proc { |menu|
    scene = PokemonPokegearTheme_Scene.new
    screen = PokemonPokegearThemeScreen.new(scene)
    screen.pbStartScreen
    menu.dispose
    next 99999
  }
})
