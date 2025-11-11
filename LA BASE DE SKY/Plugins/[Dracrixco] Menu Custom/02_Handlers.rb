#===============================================================================
# Pause menu commands.
#===============================================================================
MenuHandlers.add(
  :custom_menu,
  :pokedex,
  {
    "name" => _INTL("Pokédex"),
    "iconName" => "pokedex",
    "condition" =>
      proc do
        next $player.has_pokedex && $player.pokedex.accessible_dexes.length > 0
      end,
    "effect" =>
      proc do |menu|
        pbPlayDecisionSE
        if Settings::USE_CURRENT_REGION_DEX
          pbFadeOutIn do
            scene = PokemonPokedex_Scene.new
            screen = PokemonPokedexScreen.new(scene)
            screen.pbStartScreen
            menu.pbRefresh
          end
        elsif $player.pokedex.accessible_dexes.length == 1
          $PokemonGlobal.pokedexDex = $player.pokedex.accessible_dexes[0]
          pbFadeOutIn do
            scene = PokemonPokedex_Scene.new
            screen = PokemonPokedexScreen.new(scene)
            screen.pbStartScreen
            menu.pbRefresh
          end
        else
          pbFadeOutIn do
            scene = PokemonPokedexMenu_Scene.new
            screen = PokemonPokedexMenuScreen.new(scene)
            screen.pbStartScreen
            menu.pbRefresh
          end
        end
        next false
      end
  }
)

MenuHandlers.add(
  :custom_menu,
  :party,
  {
    "name" => _INTL("Pokémon"),
    "iconName" => "pokeball",
    "condition" => proc { next $player.party_count > 0 },
    "effect" =>
      proc do |menu|
        pbPlayDecisionSE
        hidden_move = nil
        pbFadeOutIn do
          sscene = PokemonParty_Scene.new
          sscreen = PokemonPartyScreen.new(sscene, $player.party)
          hidden_move = sscreen.pbPokemonScreen
          (hidden_move) ? menu.pbEndScene : menu.pbRefresh
        end
        next false if !hidden_move
        $game_temp.in_menu = false
        pbUseHiddenMove(hidden_move[0], hidden_move[1])
        next true
      end
  }
)

MenuHandlers.add(
  :custom_menu,
  :bag,
  {
    "name" => _INTL("Mochila"),
    "iconName" => "bag",
    "condition" => proc { next !pbInBugContest? },
    "effect" =>
      proc do |menu|
        pbPlayDecisionSE
        item = nil
        pbFadeOutIn do
          scene = PokemonBag_Scene.new
          screen = PokemonBagScreen.new(scene, $bag)
          item = screen.pbStartScreen
          (item) ? menu.pbEndScene : menu.pbRefresh
        end
        next false if !item
        $game_temp.in_menu = false
        pbUseKeyItemInField(item)
        next true
      end
  }
)

MenuHandlers.add(
  :custom_menu,
  :trainer_card,
  {
    "name" => proc { next $player.name },
    "iconName" => "trainer",
    "condition" => proc { next true },
    "effect" =>
      proc do |menu|
        pbPlayDecisionSE
        pbFadeOutIn do
          scene = PokemonTrainerCard_Scene.new
          screen = PokemonTrainerCardScreen.new(scene)
          screen.pbStartScreen
          menu.pbRefresh
        end
        next false
      end
  }
)

MenuHandlers.add(
  :custom_menu,
  :options,
  {
    "name" => _INTL("Opciones"),
    "iconName" => "options",
    "condition" => proc { next true },
    "effect" =>
      proc do |menu|
        pbPlayDecisionSE
        pbFadeOutIn do
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen
          pbUpdateSceneMap
          menu.pbRefresh
        end
        next false
      end
  }
)

MenuHandlers.add(
  :custom_menu,
  :debug,
  {
    "name" => _INTL("Debug"),
    "iconName" => "debug",
    "condition" => proc { next $DEBUG },
    "effect" =>
      proc do |menu|
        pbPlayDecisionSE
        pbFadeOutIn do
          pbDebugMenu
          menu.pbRefresh
        end
        next false
      end
  }
)

MenuHandlers.add(:custom_menu, :quests, {
    "name"      => _INTL("Misiones"),
    "order"     => 81,
    "condition" => proc { next hasAnyQuests? },
    "iconName" => "quest",
    "effect"    => proc { |menu|
      menu.pbHideMenu
      pbViewQuests
      menu.pbRefresh
      menu.pbShowMenu
      next false
    }
  })


#===============================================================================
# Pause menu sub Buttons.
#===============================================================================
MenuHandlers.add(
  :custom_menu_subButtons,
  :searchPokemon,
  {
    "iconName" => "searchPokemon",
    "condition" => proc { next true },
    "button" => :W,
    "effect" =>
      proc do |menu|
        scene = EncounterList_Scene.new
        screen = EncounterList_Screen.new(scene)
        screen.pbStartScreen
      end
  }
)

MenuHandlers.add(
  :custom_menu_subButtons,
  :save,
  {
    "iconName" => "save",
    "condition" => proc { next true },
    "button" => :A,
    "effect" =>
      proc { |menu| MenuHandlers.call(:pause_menu, :save, "effect", menu) }
  }
)

MenuHandlers.add(
  :custom_menu_subButtons,
  :pokeVial,
  {
    "iconName" => "pokeVial",
    "condition" => proc { next true },
    "button" => :E,
    "effect" => proc { |menu| use_pokevial }
  }
)

MenuHandlers.add(
  :custom_menu_subButtons,
  :towMap,
  {
    "iconName" => "towMap",
    "condition" => proc { next true },
    "button" => :F,
    "effect" =>
      proc { |menu| MenuHandlers.call(:pause_menu, :town_map, "effect", menu) }
  }
)
