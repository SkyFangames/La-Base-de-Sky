#===============================================================================
# * Pokegear Theme Button
#===============================================================================
MenuHandlers.add(:pokegear_theme, :theme_1, {
  "name"      => _INTL("Azul"),
  "icon_name" => "blue",
  "order"     => 10,
  "effect"    => proc { |menu|
    $PokemonSystem.pokegear = "Theme 1"
    scene = PokemonPokegearTheme_Scene.new
    screen = PokemonPokegearThemeScreen.new(scene)
    screen.pbStartScreen
    menu.dispose
    next 99999
  }
})

MenuHandlers.add(:pokegear_theme, :theme_2, {
  "name"      => _INTL("Magenta"),
  "icon_name" => "magenta",
  "order"     => 11,
  "effect"    => proc { |menu|
    $PokemonSystem.pokegear = "Theme 2"
    scene = PokemonPokegearTheme_Scene.new
    screen = PokemonPokegearThemeScreen.new(scene)
    screen.pbStartScreen
    menu.dispose
    next 99999
  }
})

MenuHandlers.add(:pokegear_theme, :theme_3, {
  "name"      => _INTL("Amarillo"),
  "icon_name" => "yellow",
  "order"     => 12,
  "effect"    => proc { |menu|
    $PokemonSystem.pokegear = "Theme 3"
    scene = PokemonPokegearTheme_Scene.new
    screen = PokemonPokegearThemeScreen.new(scene)
    screen.pbStartScreen
    menu.dispose
    next 99999
  }
})

MenuHandlers.add(:pokegear_theme, :theme_4, {
  "name"      => _INTL("Rocket"),
  "icon_name" => "rocket",
  "order"     => 13,
  "effect"    => proc { |menu|
    $PokemonSystem.pokegear = "Theme 4"
    scene = PokemonPokegearTheme_Scene.new
    screen = PokemonPokegearThemeScreen.new(scene)
    screen.pbStartScreen
    menu.dispose
    next 99999
  }
})

MenuHandlers.add(:pokegear_theme, :theme_5, {
  "name"      => _INTL("Dojo"),
  "icon_name" => "dojo",
  "order"     => 14,
  "effect"    => proc { |menu|
    $PokemonSystem.pokegear = "Theme 5"
    scene = PokemonPokegearTheme_Scene.new
    screen = PokemonPokegearThemeScreen.new(scene)
    screen.pbStartScreen
    menu.dispose
    next 99999
  }
})

MenuHandlers.add(:pokegear_theme, :theme_6, {
  "name"      => _INTL("Liga"),
  "icon_name" => "league",
  "order"     => 15,
  "effect"    => proc { |menu|
    $PokemonSystem.pokegear = "Theme 6"
    scene = PokemonPokegearTheme_Scene.new
    screen = PokemonPokegearThemeScreen.new(scene)
    screen.pbStartScreen
    menu.dispose
    next 99999
  }
})

MenuHandlers.add(:pokegear_theme, :open_mail, {
  "name"      => _INTL("Silph"),
  "icon_name" => "silph",
  "order"     => 16,
  "effect"    => proc { |menu|
    $PokemonSystem.pokegear = "Theme 7"
    scene = PokemonPokegearTheme_Scene.new
    screen = PokemonPokegearThemeScreen.new(scene)
    screen.pbStartScreen
    menu.dispose
    next 99999
  }
})
