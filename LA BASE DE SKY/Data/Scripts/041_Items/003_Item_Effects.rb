#===============================================================================
# UseText handlers
#===============================================================================
ItemHandlers::UseText.add(:BICYCLE, proc { |item|
  next ($PokemonGlobal.bicycle) ? _INTL("Caminar") : _INTL("Usar")
})

ItemHandlers::UseText.copy(:BICYCLE, :MACHBIKE, :ACROBIKE)

ItemHandlers::UseText.add(:EXPALLOFF, proc { |item|
  next _INTL("Encender")
})

ItemHandlers::UseText.add(:EXPALL, proc { |item|
  next _INTL("Apagar")
})

#===============================================================================
# UseFromBag handlers
# Return values: 0 = not used
#                1 = used
#                2 = close the Bag to use
# If there is no UseFromBag handler for an item being used from the Bag (not on
# a Pokémon), calls the UseInField handler for it instead.
#===============================================================================

ItemHandlers::UseFromBag.add(:HONEY, proc { |item|
  next 2
})

ItemHandlers::UseFromBag.add(:ESCAPEROPE, proc { |item|
  if !$game_player.can_map_transfer_with_follower?
    pbMessage(_INTL("No se puede usar cuando hay alguien contigo."))
    next 0
  end
  if ($PokemonGlobal.escapePoint rescue false) && $PokemonGlobal.escapePoint.length > 0
    next 2   # End screen and use item
  end
  pbMessage(_INTL("Aquí no se puede usar."))
  next 0
})

ItemHandlers::UseFromBag.add(:BICYCLE, proc { |item|
  next (pbBikeCheck) ? 2 : 0
})

ItemHandlers::UseFromBag.copy(:BICYCLE, :MACHBIKE, :ACROBIKE)

ItemHandlers::UseFromBag.add(:OLDROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  next 2 if $game_player.pbFacingTerrainTag.can_fish && ($PokemonGlobal.surfing || notCliff)
  pbMessage(_INTL("Aquí no se puede usar."))
  next 0
})

ItemHandlers::UseFromBag.copy(:OLDROD, :GOODROD, :SUPERROD)

ItemHandlers::UseFromBag.add(:ITEMFINDER, proc { |item|
  next 2
})

ItemHandlers::UseFromBag.copy(:ITEMFINDER, :DOWSINGMCHN, :DOWSINGMACHINE)

ItemHandlers::UseFromBag.add(:TOWNMAP, proc { |item|
  pbFadeOutIn do
    scene = PokemonRegionMap_Scene.new(-1, false)
    screen = PokemonRegionMapScreen.new(scene)
    ret = screen.pbStartScreen
    $game_temp.fly_destination = ret if ret
    next 99999 if ret   # Ugly hack to make Bag scene not reappear if flying
  end
  next ($game_temp.fly_destination) ? 2 : 0
})

ItemHandlers::UseFromBag.addIf(:move_machines,
  proc { |item| GameData::Item.get(item).is_machine? },
  proc { |item|
    if $player.pokemon_count == 0
      pbMessage(_INTL("No hay Pokémon."))
      next 0
    end
    item_data = GameData::Item.get(item)
    move = item_data.move
    next 0 if !move
    pbMessage("\\se[PC access]" + _INTL("Has encendido {1}.", item_data.name) + "\1")
    next 0 if !pbConfirmMessage(_INTL("¿Quieres enseñarle {1} a un Pokémon?",
                                      GameData::Move.get(move).name))
    next 1 if pbMoveTutorChoose(move, nil, true, item_data.is_TR?)
    next 0
  }
)

#===============================================================================
# ConfirmUseInField handlers
# Return values: true/false
# Called when an item is used from the Ready Menu.
# If an item does not have this handler, it is treated as returning true.
#===============================================================================

ItemHandlers::ConfirmUseInField.add(:ESCAPEROPE, proc { |item|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  if !escape || escape == []
    pbMessage(_INTL("Aquí no se puede usar."))
    next false
  end
  if !$game_player.can_map_transfer_with_follower?
    pbMessage(_INTL("No se puede usar cuando hay alguien contigo."))
    next false
  end
  mapname = pbGetMapNameFromId(escape[0])
  next pbConfirmMessage(_INTL("¿Quieres salir de aquí y volver a {1}?", mapname))
})

#===============================================================================
# UseInField handlers
# Return values: false = not used
#                true = used
# Called if an item is used from the Bag (not on a Pokémon and not a TM/HM) and
# there is no UseFromBag handler above.
# If an item has this handler, it can be registered to the Ready Menu.
#===============================================================================

def pbRepel(item, steps)
  if $PokemonGlobal.repel > 0
    pbMessage(_INTL("El Repelente anterior todavía no se ha terminado."))
    return false
  end
  pbSEPlay("Repel")
  $stats.repel_count += 1
  pbUseItemMessage(item)
  $PokemonGlobal.repel = steps
  return true
end

ItemHandlers::UseInField.add(:REPEL, proc { |item|
  next pbRepel(item, 100)
})

ItemHandlers::UseInField.add(:SUPERREPEL, proc { |item|
  next pbRepel(item, 200)
})

ItemHandlers::UseInField.add(:MAXREPEL, proc { |item|
  next pbRepel(item, 250)
})

EventHandlers.add(:on_player_step_taken, :repel_counter,
  proc {
    next if $PokemonGlobal.repel <= 0 || $game_player.terrain_tag.ice   # Shouldn't count down if on ice
    $PokemonGlobal.repel -= 1
    next if $PokemonGlobal.repel > 0
    repels = []
    GameData::Item.each { |itm| repels.push(itm.id) if itm.has_flag?("Repel") }
    if repels.none? { |item| $bag.has?(item) }
      pbMessage(_INTL("¡El efecto del Repelente se ha terminado!"))
      next
    end
    next if !pbConfirmMessage(_INTL("¡El efecto del Repelente se ha terminado! ¿Quieres usar otro?"))
    ret = nil
    pbFadeOutIn do
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, $bag)
      ret = screen.pbChooseItemScreen(proc { |item| repels.include?(item) })
    end
    pbUseItem($bag, ret) if ret
  }
)

ItemHandlers::UseInField.add(:BLACKFLUTE, proc { |item|
  pbUseItemMessage(item)
  if Settings::FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS
    pbMessage(_INTL("¡Ahora es más probable que te encuentres Pokémon de niveles altos!"))
    $PokemonMap.higher_level_wild_pokemon = true
    $PokemonMap.lower_level_wild_pokemon = false
  else
    pbMessage(_INTL("¡La probabilidad de encontrar Pokémon disminuyó!"))
    $PokemonMap.lower_encounter_rate = true
    $PokemonMap.higher_encounter_rate = false
  end
  next true
})

ItemHandlers::UseInField.add(:WHITEFLUTE, proc { |item|
  pbUseItemMessage(item)
  if Settings::FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS
    pbMessage(_INTL("¡Ahora es más probable que te encuentres Pokémon de niveles bajos!"))
    $PokemonMap.lower_level_wild_pokemon = true
    $PokemonMap.higher_level_wild_pokemon = false
  else
    pbMessage(_INTL("¡La probabilidad de encontrar Pokémon aumentó!"))
    $PokemonMap.higher_encounter_rate = true
    $PokemonMap.lower_encounter_rate = false
  end
  next true
})

ItemHandlers::UseInField.add(:HONEY, proc { |item|
  pbUseItemMessage(item)
  pbSweetScent
  next true
})

ItemHandlers::UseInField.add(:ESCAPEROPE, proc { |item|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  if !escape || escape == []
    pbMessage(_INTL("Aquí no se puede usar."))
    next false
  end
  if !$game_player.can_map_transfer_with_follower?
    pbMessage(_INTL("No se puede usar cuando hay alguien contigo."))
    next false
  end
  pbUseItemMessage(item)
  pbFadeOutIn do
    $game_temp.player_new_map_id    = escape[0]
    $game_temp.player_new_x         = escape[1]
    $game_temp.player_new_y         = escape[2]
    $game_temp.player_new_direction = escape[3]
    pbCancelVehicles
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  end
  pbEraseEscapePoint
  next true
})

ItemHandlers::UseInField.add(:SACREDASH, proc { |item|
  if $player.pokemon_count == 0
    pbMessage(_INTL("No hay Pokémon."))
    next false
  end
  canrevive = false
  $player.pokemon_party.each do |i|
    next if !i.fainted?
    canrevive = true
    break
  end
  if !canrevive
    pbMessage(_INTL("No tendría ningún efecto."))
    next false
  end
  revived = 0
  pbFadeOutIn do
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene, $player.party)
    screen.pbStartScene(_INTL("Usando objeto..."), false)
    pbSEPlay("Use item in party")
    $player.party.each_with_index do |pkmn, i|
      next if !pkmn.fainted?
      revived += 1
      pkmn.heal
      screen.pbRefreshSingle(i)
      screen.pbDisplay(_INTL("Los PS de {1} se han restaurado.", pkmn.name))
    end
    screen.pbDisplay(_INTL("No tendría ningún efecto.")) if revived == 0
    screen.pbEndScene
  end
  next (revived > 0)
})

ItemHandlers::UseInField.add(:BICYCLE, proc { |item|
  if pbBikeCheck
    if $PokemonGlobal.bicycle
      pbDismountBike
    else
      pbMountBike
    end
    next true
  end
  next false
})

ItemHandlers::UseInField.copy(:BICYCLE, :MACHBIKE, :ACROBIKE)

ItemHandlers::UseInField.add(:OLDROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Aquí no se puede usar."))
    next false
  end
  encounter = $PokemonEncounters.has_encounter_type?(:OldRod)
  if pbFishing(encounter, 1)
    $stats.fishing_battles += 1
    pbEncounter(:OldRod)
  end
  next true
})

ItemHandlers::UseInField.add(:GOODROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Aquí no se puede usar."))
    next false
  end
  encounter = $PokemonEncounters.has_encounter_type?(:GoodRod)
  if pbFishing(encounter, 2)
    $stats.fishing_battles += 1
    pbEncounter(:GoodRod)
  end
  next true
})

ItemHandlers::UseInField.add(:SUPERROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Aquí no se puede usar."))
    next false
  end
  encounter = $PokemonEncounters.has_encounter_type?(:SuperRod)
  if pbFishing(encounter, 3)
    $stats.fishing_battles += 1
    pbEncounter(:SuperRod)
  end
  next true
})

ItemHandlers::UseInField.add(:ITEMFINDER, proc { |item|
  $stats.itemfinder_count += 1
  pbSEPlay("Itemfinder")
  event = pbClosestHiddenItem
  if !event
    pbMessage(_INTL("... \\wt[10]... \\wt[10]... \\wt[10]... \\wt[10]¡No! No responde."))
    next true
  end
  offsetX = event.x - $game_player.x
  offsetY = event.y - $game_player.y
  if offsetX == 0 && offsetY == 0   # Standing on the item, spin around
    4.times do
      pbWait(0.2)
      $game_player.turn_right_90
    end
    pbWait(0.3)
    pbMessage(_INTL("¡El {1} está reaccionando a algo bajo tus pies!", GameData::Item.get(item).name))
  else   # Item is nearby, face towards it
    direction = $game_player.direction
    if offsetX.abs > offsetY.abs
      direction = (offsetX < 0) ? 4 : 6
    else
      direction = (offsetY < 0) ? 8 : 2
    end
    case direction
    when 2 then $game_player.turn_down
    when 4 then $game_player.turn_left
    when 6 then $game_player.turn_right
    when 8 then $game_player.turn_up
    end
    pbWait(0.3)
    pbMessage(_INTL("¿Eh? ¡El {1} está reaccionando!", GameData::Item.get(item).name) + "\1")
    pbMessage(_INTL("¡Hay un objeto enterrado por aquí cerca!"))
  end
  next true
})

ItemHandlers::UseInField.copy(:ITEMFINDER, :DOWSINGMCHN, :DOWSINGMACHINE)

ItemHandlers::UseInField.add(:TOWNMAP, proc { |item|
  pbShowMap(-1, false) if $game_temp.fly_destination.nil?
  pbFlyToNewLocation
  next true
})

ItemHandlers::UseInField.add(:COINCASE, proc { |item|
  pbMessage(_INTL("Monedas: {1}", $player.coins.to_s_formatted))
  next true
})

ItemHandlers::UseInField.add(:EXPALL, proc { |item|
  $bag.replace_item(:EXPALL, :EXPALLOFF)
  pbMessage(_INTL("El Rep Exp se ha apagado."))
  next true
})

ItemHandlers::UseInField.add(:EXPALLOFF, proc { |item|
  $bag.replace_item(:EXPALLOFF, :EXPALL)
  pbMessage(_INTL("El Rep Exp se ha encendido."))
  next true
})

#===============================================================================
# UseOnPokemon handlers
#===============================================================================

# Applies to all items defined as an evolution stone.
# No need to add more code for new ones.
ItemHandlers::UseOnPokemon.addIf(:evolution_stones,
  proc { |item| GameData::Item.get(item).is_evolution_stone? },
  proc { |item, qty, pkmn, scene|
    if pkmn.shadowPokemon?
      scene.pbDisplay(_INTL("No tendría ningún efecto."))
      next false
    end
    newspecies = pkmn.check_evolution_on_use_item(item)
    if newspecies
      pbFadeOutInWithMusic do
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(pkmn, newspecies)
        evo.pbEvolution(false)
        evo.pbEndScreen
        if scene.is_a?(PokemonPartyScreen)
          scene.pbRefreshAnnotations(proc { |p| !p.check_evolution_on_use_item(item).nil? })
          scene.pbRefresh
        end
      end
      next true
    end
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  }
)

ItemHandlers::UseOnPokemon.add(:POTION, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, 20, scene)
})

ItemHandlers::UseOnPokemon.copy(:POTION, :BERRYJUICE, :SWEETHEART)
ItemHandlers::UseOnPokemon.copy(:POTION, :RAGECANDYBAR) if !Settings::RAGE_CANDY_BAR_CURES_STATUS_PROBLEMS

ItemHandlers::UseOnPokemon.add(:SUPERPOTION, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, (Settings::REBALANCED_HEALING_ITEM_AMOUNTS) ? 60 : 50, scene)
})

ItemHandlers::UseOnPokemon.add(:HYPERPOTION, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, (Settings::REBALANCED_HEALING_ITEM_AMOUNTS) ? 120 : 200, scene)
})

ItemHandlers::UseOnPokemon.add(:MAXPOTION, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, pkmn.totalhp - pkmn.hp, scene)
})

ItemHandlers::UseOnPokemon.add(:FRESHWATER, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, (Settings::REBALANCED_HEALING_ITEM_AMOUNTS) ? 30 : 50, scene)
})

ItemHandlers::UseOnPokemon.add(:SODAPOP, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, (Settings::REBALANCED_HEALING_ITEM_AMOUNTS) ? 50 : 60, scene)
})

ItemHandlers::UseOnPokemon.add(:LEMONADE, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, (Settings::REBALANCED_HEALING_ITEM_AMOUNTS) ? 70 : 80, scene)
})

ItemHandlers::UseOnPokemon.add(:MOOMOOMILK, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, 100, scene)
})

ItemHandlers::UseOnPokemon.add(:ORANBERRY, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, 10, scene)
})

ItemHandlers::UseOnPokemon.add(:SITRUSBERRY, proc { |item, qty, pkmn, scene|
  next pbHPItem(pkmn, pkmn.totalhp / 4, scene)
})

ItemHandlers::UseOnPokemon.add(:AWAKENING, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || pkmn.status != :SLEEP
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} se despertó.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.copy(:AWAKENING, :CHESTOBERRY, :BLUEFLUTE, :POKEFLUTE)

ItemHandlers::UseOnPokemon.add(:ANTIDOTE, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || pkmn.status != :POISON
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} se curó del envenenamiento.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.copy(:ANTIDOTE, :PECHABERRY)

ItemHandlers::UseOnPokemon.add(:BURNHEAL, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || pkmn.status != :BURN
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} se curó de la quemadura.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.copy(:BURNHEAL, :RAWSTBERRY)

ItemHandlers::UseOnPokemon.add(:PARALYZEHEAL, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || pkmn.status != :PARALYSIS
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} se ha curado de la parálisis.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.copy(:PARALYZEHEAL, :PARLYZHEAL, :CHERIBERRY)

ItemHandlers::UseOnPokemon.add(:ICEHEAL, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || ![:FROZEN, :FROSTBITE].include?(pkmn.status)
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} se ha curado de la congelación.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.copy(:ICEHEAL, :ASPEARBERRY)

ItemHandlers::UseOnPokemon.add(:FULLHEAL, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || pkmn.status == :NONE
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} se curó.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.copy(:FULLHEAL,
                                :LAVACOOKIE, :OLDGATEAU, :CASTELIACONE,
                                :LUMIOSEGALETTE, :SHALOURSABLE, :BIGMALASADA,
                                :PEWTERCRUNCHIES, :LUMBERRY)
ItemHandlers::UseOnPokemon.copy(:FULLHEAL, :RAGECANDYBAR) if Settings::RAGE_CANDY_BAR_CURES_STATUS_PROBLEMS

ItemHandlers::UseOnPokemon.add(:FULLRESTORE, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || (pkmn.hp == pkmn.totalhp && pkmn.status == :NONE)
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  hpgain = pbItemRestoreHP(pkmn, pkmn.totalhp - pkmn.hp)
  pkmn.heal_status
  scene.pbRefresh
  if hpgain > 0
    scene.pbDisplay(_INTL("{1} ha recuperado {2} PS.", pkmn.name, hpgain))
  else
    scene.pbDisplay(_INTL("{1} se ha curado.", pkmn.name))
  end
  next true
})

ItemHandlers::UseOnPokemon.add(:REVIVE, proc { |item, qty, pkmn, scene|
  if !pkmn.fainted?
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.hp = (pkmn.totalhp / 2).floor
  pkmn.hp = 1 if pkmn.hp <= 0
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} ha recuperado PS.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:MAXREVIVE, proc { |item, qty, pkmn, scene|
  if !pkmn.fainted?
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_HP
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} ha recuperado PS.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.copy(:MAXREVIVE, :MAXHONEY)

ItemHandlers::UseOnPokemon.add(:ENERGYPOWDER, proc { |item, qty, pkmn, scene|
  if pbHPItem(pkmn, (Settings::REBALANCED_HEALING_ITEM_AMOUNTS) ? 60 : 50, scene)
    pkmn.changeHappiness("powder")
    next true
  end
  next false
})

ItemHandlers::UseOnPokemon.add(:ENERGYROOT, proc { |item, qty, pkmn, scene|
  if pbHPItem(pkmn, (Settings::REBALANCED_HEALING_ITEM_AMOUNTS) ? 120 : 200, scene)
    pkmn.changeHappiness("energyroot")
    next true
  end
  next false
})

ItemHandlers::UseOnPokemon.add(:HEALPOWDER, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || pkmn.status == :NONE
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_status
  pkmn.changeHappiness("powder")
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} se ha recuperado.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:REVIVALHERB, proc { |item, qty, pkmn, scene|
  if !pkmn.fainted?
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_HP
  pkmn.heal_status
  pkmn.changeHappiness("revivalherb")
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} ya no está debilitado.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:ETHER, proc { |item, qty, pkmn, scene|
  move = scene.pbChooseMove(pkmn, _INTL("Restore which move?"))
  next false if move < 0
  if pbRestorePP(pkmn, move, 10) == 0
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  scene.pbDisplay(_INTL("Ha restaurado sus PP."))
  next true
})

ItemHandlers::UseOnPokemon.copy(:ETHER, :LEPPABERRY, :HOPOBERRY)

ItemHandlers::UseOnPokemon.add(:MAXETHER, proc { |item, qty, pkmn, scene|
  move = scene.pbChooseMove(pkmn, _INTL("¿Restaurar qué movimiento?"))
  next false if move < 0
  if pbRestorePP(pkmn, move, pkmn.moves[move].total_pp - pkmn.moves[move].pp) == 0
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  scene.pbDisplay(_INTL("Ha restaurado sus PP."))
  next true
})

ItemHandlers::UseOnPokemon.add(:ELIXIR, proc { |item, qty, pkmn, scene|
  pprestored = 0
  pkmn.moves.length.times do |i|
    pprestored += pbRestorePP(pkmn, i, 10)
  end
  if pprestored == 0
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  scene.pbDisplay(_INTL("Ha restaurado sus PP."))
  next true
})

ItemHandlers::UseOnPokemon.add(:MAXELIXIR, proc { |item, qty, pkmn, scene|
  pprestored = 0
  pkmn.moves.length.times do |i|
    pprestored += pbRestorePP(pkmn, i, pkmn.moves[i].total_pp - pkmn.moves[i].pp)
  end
  if pprestored == 0
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  scene.pbDisplay(_INTL("Ha restaurado sus PP."))
  next true
})

ItemHandlers::UseOnPokemon.add(:PPUP, proc { |item, qty, pkmn, scene|
  move = scene.pbChooseMove(pkmn, _INTL("¿Aumentar los PP de qué movimiento?"))
  next false if move < 0
  if pkmn.moves[move].total_pp <= 1 || pkmn.moves[move].ppup >= 3
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.moves[move].ppup += 1
  movename = pkmn.moves[move].name
  scene.pbDisplay(_INTL("Los PP de {1} han aumentado.", movename))
  next true
})

ItemHandlers::UseOnPokemon.add(:PPMAX, proc { |item, qty, pkmn, scene|
  move = scene.pbChooseMove(pkmn, _INTL("Boost PP of which move?"))
  next false if move < 0
  if pkmn.moves[move].total_pp <= 1 || pkmn.moves[move].ppup >= 3
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.moves[move].ppup = 3
  movename = pkmn.moves[move].name
  scene.pbDisplay(_INTL("Los PP de {1} han aumentado.", movename))
  next true
})

ItemHandlers::UseOnPokemonMaximum.add(:HPUP, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:HP, 10, pkmn, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemonMaximum.copy(:HPUP, :HEALTHMOCHI)

ItemHandlers::UseOnPokemon.add(:HPUP, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:HP, 10, qty, pkmn, "vitamin", scene, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemon.copy(:HPUP, :HEALTHMOCHI)

ItemHandlers::UseOnPokemonMaximum.add(:PROTEIN, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:ATTACK, 10, pkmn, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemonMaximum.copy(:PROTEIN, :MUSCLEMOCHI)

ItemHandlers::UseOnPokemon.add(:PROTEIN, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:ATTACK, 10, qty, pkmn, "vitamin", scene, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemon.copy(:PROTEIN, :MUSCLEMOCHI)

ItemHandlers::UseOnPokemonMaximum.add(:IRON, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:DEFENSE, 10, pkmn, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemonMaximum.copy(:IRON, :RESISTMOCHI)

ItemHandlers::UseOnPokemon.add(:IRON, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:DEFENSE, 10, qty, pkmn, "vitamin", scene, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemon.copy(:IRON, :RESISTMOCHI)

ItemHandlers::UseOnPokemonMaximum.add(:CALCIUM, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:SPECIAL_ATTACK, 10, pkmn, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemonMaximum.copy(:CALCIUM, :GENIUSMOCHI)

ItemHandlers::UseOnPokemon.add(:CALCIUM, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:SPECIAL_ATTACK, 10, qty, pkmn, "vitamin", scene, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemon.copy(:CALCIUM, :GENIUSMOCHI)

ItemHandlers::UseOnPokemonMaximum.add(:ZINC, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:SPECIAL_DEFENSE, 10, pkmn, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemonMaximum.copy(:ZINC, :CLEVERMOCHI)

ItemHandlers::UseOnPokemon.add(:ZINC, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:SPECIAL_DEFENSE, 10, qty, pkmn, "vitamin", scene, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemon.copy(:ZINC, :CLEVERMOCHI)

ItemHandlers::UseOnPokemonMaximum.add(:CARBOS, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:SPEED, 10, pkmn, Settings::NO_VITAMIN_EV_CAP)
})

ItemHandlers::UseOnPokemon.add(:CARBOS, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:SPEED, 10, qty, pkmn, "vitamin", scene, Settings::NO_VITAMIN_EV_CAP)
})
ItemHandlers::UseOnPokemonMaximum.copy(:CARBOS, :SWIFTMOCHI)

ItemHandlers::UseOnPokemonMaximum.add(:HEALTHFEATHER, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:HP, 1, pkmn, true)
})
ItemHandlers::UseOnPokemon.copy(:CARBOS, :SWIFTMOCHI)

ItemHandlers::UseOnPokemonMaximum.copy(:HEALTHFEATHER, :HEALTHWING)

ItemHandlers::UseOnPokemon.add(:HEALTHFEATHER, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:HP, 1, qty, pkmn, "wing", scene, true)
})

ItemHandlers::UseOnPokemon.copy(:HEALTHFEATHER, :HEALTHWING)

ItemHandlers::UseOnPokemonMaximum.add(:MUSCLEFEATHER, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:ATTACK, 1, pkmn, true)
})

ItemHandlers::UseOnPokemonMaximum.copy(:MUSCLEFEATHER, :MUSCLEWING)

ItemHandlers::UseOnPokemon.add(:MUSCLEFEATHER, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:ATTACK, 1, qty, pkmn, "wing", scene, true)
})

ItemHandlers::UseOnPokemon.copy(:MUSCLEFEATHER, :MUSCLEWING)

ItemHandlers::UseOnPokemonMaximum.add(:RESISTFEATHER, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:DEFENSE, 1, pkmn, true)
})

ItemHandlers::UseOnPokemonMaximum.copy(:RESISTFEATHER, :RESISTWING)

ItemHandlers::UseOnPokemon.add(:RESISTFEATHER, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:DEFENSE, 1, qty, pkmn, "wing", scene, true)
})

ItemHandlers::UseOnPokemon.copy(:RESISTFEATHER, :RESISTWING)

ItemHandlers::UseOnPokemonMaximum.add(:GENIUSFEATHER, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:SPECIAL_ATTACK, 1, pkmn, true)
})

ItemHandlers::UseOnPokemonMaximum.copy(:GENIUSFEATHER, :GENIUSWING)

ItemHandlers::UseOnPokemon.add(:GENIUSFEATHER, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:SPECIAL_ATTACK, 1, qty, pkmn, "wing", scene, true)
})

ItemHandlers::UseOnPokemon.copy(:GENIUSFEATHER, :GENIUSWING)

ItemHandlers::UseOnPokemonMaximum.add(:CLEVERFEATHER, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:SPECIAL_DEFENSE, 1, pkmn, true)
})

ItemHandlers::UseOnPokemonMaximum.copy(:CLEVERFEATHER, :CLEVERWING)

ItemHandlers::UseOnPokemon.add(:CLEVERFEATHER, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:SPECIAL_DEFENSE, 1, qty, pkmn, "wing", scene, true)
})

ItemHandlers::UseOnPokemon.copy(:CLEVERFEATHER, :CLEVERWING)

ItemHandlers::UseOnPokemonMaximum.add(:SWIFTFEATHER, proc { |item, pkmn|
  next pbMaxUsesOfEVRaisingItem(:SPEED, 1, pkmn, true)
})

ItemHandlers::UseOnPokemonMaximum.copy(:SWIFTFEATHER, :SWIFTWING)

ItemHandlers::UseOnPokemon.add(:SWIFTFEATHER, proc { |item, qty, pkmn, scene|
  next pbUseEVRaisingItem(:SPEED, 1, qty, pkmn, "wing", scene, true)
})

ItemHandlers::UseOnPokemon.copy(:SWIFTFEATHER, :SWIFTWING)

ItemHandlers::UseOnPokemon.add(:LONELYMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:LONELY, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:ADAMANTMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:ADAMANT, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:NAUGHTYMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:NAUGHTY, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:BRAVEMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:BRAVE, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:BOLDMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:BOLD, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:IMPISHMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:IMPISH, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:LAXMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:LAX, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:RELAXEDMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:RELAXED, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:MODESTMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:MODEST, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:MILDMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:MILD, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:RASHMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:RASH, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:QUIETMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:QUIET, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:CALMMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:CALM, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:GENTLEMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:GENTLE, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:CAREFULMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:CAREFUL, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:SASSYMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:SASSY, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:TIMIDMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:TIMID, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:HASTYMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:HASTY, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:JOLLYMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:JOLLY, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:NAIVEMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:NAIVE, item, pkmn, scene)
})

ItemHandlers::UseOnPokemon.add(:SERIOUSMINT, proc { |item, qty, pkmn, scene|
  pbNatureChangingMint(:SERIOUS, item, pkmn, scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:RARECANDY, proc { |item, pkmn|
  next GameData::GrowthRate.max_level - pkmn.level
})

ItemHandlers::UseOnPokemon.add(:RARECANDY, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  if pkmn.level >= GameData::GrowthRate.max_level
    new_species = pkmn.check_evolution_on_level_up
    if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
      scene.pbDisplay(_INTL("No tendría ningún efecto."))
      next false
    end
    # Check for evolution
    pbFadeOutInWithMusic do
      evo = PokemonEvolutionScene.new
      evo.pbStartScreen(pkmn, new_species)
      evo.pbEvolution
      evo.pbEndScreen
      scene.pbRefresh if scene.is_a?(PokemonPartyScreen)
    end
    next true
  end
  # Level up
  pbSEPlay("Pkmn level up")
  pbChangeLevel(pkmn, pkmn.level + qty, scene)
  scene.pbHardRefresh
  next true
})

ItemHandlers::UseOnPokemonMaximum.add(:UNRARECANDY, proc { |item, pkmn|
  next pkmn.level - 1
})

ItemHandlers::UseOnPokemon.add(:UNRARECANDY, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon? || qty >= pkmn.level
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  # if pkmn.level >= GameData::GrowthRate.max_level
  # new_species = pkmn.check_evolution_on_level_up
  # if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
  #   scene.pbDisplay(_INTL("No tendría ningún efecto."))
  #   next false
  # end
  # # Check for evolution
  # pbFadeOutInWithMusic do
  #   evo = PokemonEvolutionScene.new
  #   evo.pbStartScreen(pkmn, new_species)
  #   evo.pbEvolution
  #   evo.pbEndScreen
  #   scene.pbRefresh if scene.is_a?(PokemonPartyScreen)
  # end
  # next true
  # end
  # Level down
  pbSEPlay("Pkmn level up")
  pbChangeLevel(pkmn, pkmn.level - qty, scene)
  scene.pbHardRefresh
  next true
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYXS, proc { |item, pkmn|
  gain_amount = 100
  next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXS, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 100, qty, scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYS, proc { |item, pkmn|
  gain_amount = 800
  next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYS, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 800, qty, scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYM, proc { |item, pkmn|
  gain_amount = 3_000
  next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYM, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 3_000, qty, scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYL, proc { |item, pkmn|
  gain_amount = 10_000
  next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYL, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 10_000, qty, scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYXL, proc { |item, pkmn|
  gain_amount = 30_000
  next ((pkmn.growth_rate.maximum_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXL, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 30_000, qty, scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:POMEGBERRY, proc { |item, pkmn|
  next pbMaxUsesOfEVLoweringBerry(:HP, pkmn)
})

ItemHandlers::UseOnPokemon.add(:POMEGBERRY, proc { |item, qty, pkmn, scene|
  next pbRaiseHappinessAndLowerEV(
    pkmn, scene, :HP, qty, [
      _INTL("¡{1} te adora! ¡Sus PS base bajaron!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Sus PS de base ya no pueden bajar más!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos PS de base!", pkmn.name)
    ]
  )
})

ItemHandlers::UseOnPokemonMaximum.add(:KELPSYBERRY, proc { |item, pkmn|
  next pbMaxUsesOfEVLoweringBerry(:ATTACK, pkmn)
})

ItemHandlers::UseOnPokemon.add(:KELPSYBERRY, proc { |item, qty, pkmn, scene|
  next pbRaiseHappinessAndLowerEV(
    pkmn, scene, :ATTACK, qty, [
      _INTL("¡{1} te adora! Its base Attack fell!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Ataque de base ya no puede bajar más!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Ataque de base!", pkmn.name)
    ]
  )
})

ItemHandlers::UseOnPokemonMaximum.add(:QUALOTBERRY, proc { |item, pkmn|
  next pbMaxUsesOfEVLoweringBerry(:DEFENSE, pkmn)
})

ItemHandlers::UseOnPokemon.add(:QUALOTBERRY, proc { |item, qty, pkmn, scene|
  next pbRaiseHappinessAndLowerEV(
    pkmn, scene, :DEFENSE, qty, [
      _INTL("¡{1} te adora! Its base Defense fell!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Defensa de base ya no puede bajar más!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Defensa de base!", pkmn.name)
    ]
  )
})

ItemHandlers::UseOnPokemonMaximum.add(:HONDEWBERRY, proc { |item, pkmn|
  next pbMaxUsesOfEVLoweringBerry(:SPECIAL_ATTACK, pkmn)
})

ItemHandlers::UseOnPokemon.add(:HONDEWBERRY, proc { |item, qty, pkmn, scene|
  next pbRaiseHappinessAndLowerEV(
    pkmn, scene, :SPECIAL_ATTACK, qty, [
      _INTL("¡{1} te adora! Its base Special Attack fell!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Ataque Especial de base ya no puede bajar más!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Ataque Especial de base!", pkmn.name)
    ]
  )
})

ItemHandlers::UseOnPokemonMaximum.add(:GREPABERRY, proc { |item, pkmn|
  next pbMaxUsesOfEVLoweringBerry(:SPECIAL_DEFENSE, pkmn)
})

ItemHandlers::UseOnPokemon.add(:GREPABERRY, proc { |item, qty, pkmn, scene|
  next pbRaiseHappinessAndLowerEV(
    pkmn, scene, :SPECIAL_DEFENSE, qty, [
      _INTL("¡{1} te adora! Its base Special Defense fell!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Defensa Especial de base ya no puede bajar más!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Defensa Especial de base!", pkmn.name)
    ]
  )
})

ItemHandlers::UseOnPokemonMaximum.add(:TAMATOBERRY, proc { |item, pkmn|
  next pbMaxUsesOfEVLoweringBerry(:SPEED, pkmn)
})

ItemHandlers::UseOnPokemon.add(:TAMATOBERRY, proc { |item, qty, pkmn, scene|
  next pbRaiseHappinessAndLowerEV(
    pkmn, scene, :SPEED, qty, [
      _INTL("¡{1} te adora! Its base Speed fell!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Velocidad de base ya no puede bajar más!", pkmn.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Veloc de base!", pkmn.name)
    ]
  )
})

ItemHandlers::UseOnPokemon.add(:ABILITYCAPSULE, proc { |item, qty, pkmn, scene|
  if scene.pbConfirm(_INTL("¿Quieres cambiar la Habilidad de {1}?", pkmn.name))
    abils = pkmn.getAbilityList
    abil1 = nil
    abil2 = nil
    abils.each do |i|
      abil1 = i[0] if i[1] == 0
      abil2 = i[0] if i[1] == 1
    end
    if abil1.nil? || abil2.nil? || pkmn.hasHiddenAbility? || pkmn.isSpecies?(:ZYGARDE)
      scene.pbDisplay(_INTL("No tendría ningún efecto."))
      next false
    end
    newabil = (pkmn.ability_index + 1) % 2
    newabilname = GameData::Ability.get((newabil == 0) ? abil1 : abil2).name
    pkmn.ability_index = newabil
    pkmn.ability = nil
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡La Habilidad de {1} cambió! ¡Su Habilidad ahora es {2}!", pkmn.name, newabilname))
    next true
  end
  next false
})

ItemHandlers::UseOnPokemon.add(:ABILITYPATCH, proc { |item, qty, pkmn, scene|
  if scene.pbConfirm(_INTL("¿Quieres cambiar la Habilidad de {1}?", pkmn.name))
    current_abi = pkmn.ability_index
    abils = pkmn.getAbilityList
    new_ability_id = nil
    abils.each { |a| new_ability_id = a[0] if (current_abi < 2 && a[1] == 2) || (current_abi == 2 && a[1] == 0) }
    if !new_ability_id || pkmn.hasHiddenAbility? || pkmn.isSpecies?(:ZYGARDE)
      scene.pbDisplay(_INTL("No tendría ningún efecto."))
      next false
    end
    new_ability_name = GameData::Ability.get(new_ability_id).name
    pkmn.ability_index = current_abi < 2 ? 2 : 0
    pkmn.ability = nil
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡La Habilidad de {1} cambió! ¡Su Habilidad ahora es {2}!", pkmn.name, new_ability_name))
    next true
  end
  next false
})

ItemHandlers::UseOnPokemon.add(:SUPERCAPSULE, proc { |item, qty, pkmn, scene|
  if scene.pbConfirm(_INTL("¿Quieres cambiar la Habilidad de {1}?", pkmn.name))
    oldabil=pkmn.ability_index
    abils = pkmn.getAbilityList
    ability_commands = []
    abil_cmd = 0
    for i in abils
      ability_commands.push(GameData::Ability.get(i[0]).name + ((i[1] < 2) ? "" : " (H)"))
    end
    cmd= pbMessage("¿Qué habilidad quieres para tu Pokémon?",ability_commands,-1,nil,0)
    next false if cmd == -1
    if oldabil == abils[cmd][1]
      scene.pbDisplay("Tu Pokémon ya posee esa habilidad.") 
      next false
    end
    pkmn.ability_index = abils[cmd][1]
    pkmn.ability = nil
    newabilname = GameData::Ability.get(abils[cmd][0]).name
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡La Habilidad de {1} cambió! ¡Su Habilidad ahora es {2}!", pkmn.name, newabilname))
    next true
  end
})

ItemHandlers::UseOnPokemon.add(:GRACIDEA, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:SHAYMIN) || pkmn.form != 0 ||
     [:FROZEN, :FROSTBITE].include?(pkmn.status)|| PBDayNight.isNight?
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  pkmn.setForm(1) do
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  next true
})

ItemHandlers::UseOnPokemon.add(:REDNECTAR, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:ORICORIO) || pkmn.form == 0
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  pkmn.setForm(0) do
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  next true
})

ItemHandlers::UseOnPokemon.add(:YELLOWNECTAR, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:ORICORIO) || pkmn.form == 1
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  pkmn.setForm(1) do
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  next true
})

ItemHandlers::UseOnPokemon.add(:PINKNECTAR, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:ORICORIO) || pkmn.form == 2
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  pkmn.setForm(2) do
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  next true
})

ItemHandlers::UseOnPokemon.add(:PURPLENECTAR, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:ORICORIO) || pkmn.form == 3
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  pkmn.setForm(3) do
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  next true
})

ItemHandlers::UseOnPokemon.add(:REVEALGLASS, proc { |item, qty, pkmn, scene|
  if !pkmn.species_data.has_flag?("ForcesOfNature")
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  newForm = (pkmn.form == 0) ? 1 : 0
  pkmn.setForm(newForm) do
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  next true
})

ItemHandlers::UseOnPokemon.add(:PRISONBOTTLE, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:HOOPA)
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  newForm = (pkmn.form == 0) ? 1 : 0
  pkmn.setForm(newForm) do
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  next true
})

ItemHandlers::UseOnPokemon.add(:ROTOMCATALOG, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:ROTOM)
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  choices = [
    _INTL("Bombilla"),
    _INTL("Microondas"),
    _INTL("Lavadora"),
    _INTL("Frigorífico"),
    _INTL("Ventilador"),
    _INTL("Cortacésped"),
    _INTL("Cancelar")
  ]
  new_form = scene.pbShowCommands(_INTL("¿Qué electrodoméstico te gustaría pedir?"), choices, pkmn.form)
  if new_form == pkmn.form
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  elsif new_form > 0 && new_form < choices.length - 1
    pkmn.setForm(new_form) do
      scene.pbRefresh
      scene.pbDisplay(_INTL("¡{1} se tranformó!", pkmn.name))
    end
    next true
  end
  next false
})

ItemHandlers::UseOnPokemon.add(:ZYGARDECUBE, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:ZYGARDE)
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  case scene.pbShowCommands(_INTL("¿Qué quieres hacer con {1}?", pkmn.name),
                            [_INTL("Cambiar forma"), _INTL("Cambiar habilidad"), _INTL("Cancelar")])
  when 0   # Change form
    newForm = (pkmn.form == 0) ? 1 : 0
    pkmn.setForm(newForm) do
      scene.pbRefresh
      scene.pbDisplay(_INTL("¡{1} se tranformó!", pkmn.name))
    end
    next true
  when 1   # Change ability
    new_abil = (pkmn.ability_index + 1) % 2
    pkmn.ability_index = new_abil
    pkmn.ability = nil
    scene.pbRefresh
    scene.pbDisplay(_INTL("¡La habilidad de {1} cambió! ¡Su habilidad ahora es {2}!", pkmn.name, pkmn.ability.name))
    next true
  end
  next false
})

ItemHandlers::UseOnPokemon.add(:DNASPLICERS, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:KYUREM) || !pkmn.fused.nil?
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  # Fusing
  chosen = scene.pbChoosePokemon(_INTL("¿Fusionar con qué Pokémon?"))
  next false if chosen < 0
  other_pkmn = $player.party[chosen]
  if pkmn == other_pkmn
    scene.pbDisplay(_INTL("No se puede fusionar consigo mismo."))
    next false
  elsif other_pkmn.egg?
    scene.pbDisplay(_INTL("No se puede fusionar con un Huevo."))
    next false
  elsif other_pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede fusionar con un Pokémon debilitado."))
    next false
  elsif !other_pkmn.isSpecies?(:RESHIRAM) && !other_pkmn.isSpecies?(:ZEKROM)
    scene.pbDisplay(_INTL("No se puede fusionar con este Pokémon."))
    next false
  end
  newForm = 0
  newForm = 1 if other_pkmn.isSpecies?(:RESHIRAM)
  newForm = 2 if other_pkmn.isSpecies?(:ZEKROM)
  pkmn.setForm(newForm) do
    pkmn.fused = other_pkmn
    $player.remove_pokemon_at_index(chosen)
    scene.pbHardRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  $bag.replace_item(:DNASPLICERS, :DNASPLICERSUSED)
  next true
})

ItemHandlers::UseOnPokemon.add(:DNASPLICERSUSED, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:KYUREM) || pkmn.fused.nil?
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  elsif $player.party_full?
    scene.pbDisplay(_INTL("No tienes espacio para separar a los Pokémon."))
    next false
  end
  # Unfusing
  pkmn.setForm(0) do
    $player.party[$player.party.length] = pkmn.fused
    pkmn.fused = nil
    scene.pbHardRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  $bag.replace_item(:DNASPLICERSUSED, :DNASPLICERS)
  next true
})

ItemHandlers::UseOnPokemon.add(:NSOLARIZER, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:NECROZMA) || !pkmn.fused.nil?
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  # Fusing
  chosen = scene.pbChoosePokemon(_INTL("¿Fusionar con qué Pokémon?"))
  next false if chosen < 0
  other_pkmn = $player.party[chosen]
  if pkmn == other_pkmn
    scene.pbDisplay(_INTL("No se puede fusionar consigo mismo."))
    next false
  elsif other_pkmn.egg?
    scene.pbDisplay(_INTL("No se puede fusionar con un Huevo."))
    next false
  elsif other_pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede fusionar con un Pokémon debilitado."))
    next false
  elsif !other_pkmn.isSpecies?(:SOLGALEO)
    scene.pbDisplay(_INTL("No se puede fusionar con este Pokémon."))
    next false
  end
  pkmn.setForm(1) do
    pkmn.fused = other_pkmn
    $player.remove_pokemon_at_index(chosen)
    scene.pbHardRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  $bag.replace_item(:NSOLARIZER, :NSOLARIZERUSED)
  next true
})

ItemHandlers::UseOnPokemon.add(:NSOLARIZERUSED, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:NECROZMA) || pkmn.form != 1 || pkmn.fused.nil?
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  elsif $player.party_full?
    scene.pbDisplay(_INTL("No tienes espacio para separar a los Pokémon."))
    next false
  end
  # Unfusing
  pkmn.setForm(0) do
    $player.party[$player.party.length] = pkmn.fused
    pkmn.fused = nil
    scene.pbHardRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  $bag.replace_item(:NSOLARIZERUSED, :NSOLARIZER)
  next true
})

ItemHandlers::UseOnPokemon.add(:NLUNARIZER, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:NECROZMA) || !pkmn.fused.nil?
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  # Fusing
  chosen = scene.pbChoosePokemon(_INTL("¿Fusionar con qué Pokémon?"))
  next false if chosen < 0
  other_pkmn = $player.party[chosen]
  if pkmn == other_pkmn
    scene.pbDisplay(_INTL("No se puede fusionar consigo mismo."))
    next false
  elsif other_pkmn.egg?
    scene.pbDisplay(_INTL("No se puede fusionar con un Huevo."))
    next false
  elsif other_pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede fusionar con este Pokémon debilitado."))
    next false
  elsif !other_pkmn.isSpecies?(:LUNALA)
    scene.pbDisplay(_INTL("No se puede fusionar con este Pokémon."))
    next false
  end
  pkmn.setForm(2) do
    pkmn.fused = other_pkmn
    $player.remove_pokemon_at_index(chosen)
    scene.pbHardRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  $bag.replace_item(:NLUNARIZER, :NLUNARIZERUSED)
  next true
})

ItemHandlers::UseOnPokemon.add(:NLUNARIZERUSED, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:NECROZMA) || pkmn.form != 2 || pkmn.fused.nil?
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  elsif $player.party_full?
    scene.pbDisplay(_INTL("You have no room to separate the Pokémon."))
    next false
  end
  # Unfusing
  pkmn.setForm(0) do
    $player.party[$player.party.length] = pkmn.fused
    pkmn.fused = nil
    scene.pbHardRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  $bag.replace_item(:NLUNARIZERUSED, :NLUNARIZER)
  next true
})

ItemHandlers::UseOnPokemon.add(:REINSOFUNITY, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:CALYREX) || !pkmn.fused.nil?
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  # Fusing
  chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
  next false if chosen < 0
  other_pkmn = $player.party[chosen]
  if pkmn == other_pkmn
    scene.pbDisplay(_INTL("No se puede fusionar consigo mismo."))
    next false
  elsif other_pkmn.egg?
    scene.pbDisplay(_INTL("No se puede fusionar con un Huevo."))
    next false
  elsif other_pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede fusionar con este Pokémon debilitado."))
    next false
  elsif !other_pkmn.isSpecies?(:GLASTRIER) &&
        !other_pkmn.isSpecies?(:SPECTRIER)
    scene.pbDisplay(_INTL("No se puede fusionar con este Pokémon."))
    next false
  end
  newForm = 0
  newForm = 1 if other_pkmn.isSpecies?(:GLASTRIER)
  newForm = 2 if other_pkmn.isSpecies?(:SPECTRIER)
  pkmn.setForm(newForm) do
    pkmn.fused = other_pkmn
    $player.remove_pokemon_at_index(chosen)
    scene.pbHardRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  $bag.replace_item(:REINSOFUNITY, :REINSOFUNITYUSED)
  next true
})

ItemHandlers::UseOnPokemon.add(:REINSOFUNITYUSED, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:CALYREX) || pkmn.fused.nil?
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  elsif $player.party_full?
    scene.pbDisplay(_INTL("No tienes espacio para separar a los Pokémon."))
    next false
  end
  # Unfusing
  pkmn.setForm(0) do
    $player.party[$player.party.length] = pkmn.fused
    pkmn.fused = nil
    scene.pbHardRefresh
    scene.pbDisplay(_INTL("¡{1} cambió de forma!", pkmn.name))
  end
  $bag.replace_item(:REINSOFUNITYUSED, :REINSOFUNITY)
  next true
})

#===============================================================================
# Scroll of Waters
#===============================================================================
ItemHandlers::UseOnPokemon.add(:SCROLLOFWATERS,
  proc { |item, qty, pkmn, scene|
    if pkmn.shadowPokemon?
      scene.pbDisplay(_INTL("No tendría efecto."))
      next false
    end
    newspecies = pkmn.check_evolution_on_use_item(item)
    if newspecies
      pkmn.form = 1 if pkmn.species == :KUBFU
      pbFadeOutInWithMusic {
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(pkmn, newspecies)
        evo.pbEvolution(false)
        evo.pbEndScreen
        if scene.is_a?(PokemonPartyScreen)
          scene.pbRefreshAnnotations(proc { |p| !p.check_evolution_on_use_item(item).nil? })
          scene.pbRefresh
        end
      }
      next true
    end
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  }
)

ItemHandlers::UseOnPokemon.add(:FRESHSTARTMOCHI, proc { |item, qty, pkmn, scene|
  next false if pkmn.ev.values.none? { |ev| ev > 0 }
  GameData::Stat.each_main { |s| pkmn.ev[s.id] = 0 }
  pkmn.changeHappiness("vitamin")
  pkmn.calc_stats
  pbSEPlay("Use item in party")
  scene.pbRefresh
  scene.pbDisplay(_INTL("¡Los puntos base {1} de volvieron a 0!", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:METEORITE, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:DEOXYS)
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
    next false
  end
  choices = [
    _INTL("Forma Normal"),
    _INTL("Forma Ataque"),
    _INTL("Forma Defensa"),
    _INTL("Forma Velocidad"),
    _INTL("Cancelar")
  ]
  new_form = scene.pbShowCommands(_INTL("¿En que forma debería convertise {1}?", pkmn.name), choices, pkmn.form)
  if new_form == pkmn.form
    scene.pbDisplay(_INTL("No tendría efecto."))
    next false
  elsif new_form > -1 && new_form < choices.length - 1
    pkmn.setForm(new_form) do
      scene.pbRefresh
      scene.pbDisplay(_INTL("¡{1} se transformó!", pkmn.name))
    end
    next true
  end
  next false
})
