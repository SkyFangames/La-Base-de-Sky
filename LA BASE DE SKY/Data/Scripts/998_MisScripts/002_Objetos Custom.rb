# Manejador de uso del objeto #BITACORA desde la bolsa
ItemHandlers::UseFromBag.add(:BITACORAPADRE, proc { |item|
  if BookScene.new.pbBook(0)
    next 2
  else
    next 0
  end
})

# Manejador de uso del objeto Lente de la Verdad desde la bolsa
ItemHandlers::UseFromBag.add(:LENSOFTRUTH, proc { |item|
  if pbLensOfTruth
    next 2
  else
    next 0
  end
})


# Manejador de uso del objeto #CUARDERNO JUICIO# desde la bolsa
ItemHandlers::UseFromBag.add(:CUARDERNOJUICIO, proc { |item|
  if MenuPanel1.new.Panel1
    next 2
  else
    next 0
  end
})





ItemHandlers::BattleUseOnPokemon.add(:DONUT, proc { |item, pokemon, battler, choices, scene|
  usado = false

  # Restaurar PS (40 puntos)
  if pokemon.hp < pokemon.totalhp
    pbBattleHPItem(pokemon, battler, 40, scene)
    usado = true
  end

  # Comprobar que tiene movimientos para restaurar PP
  if pokemon.moves.length > 0
    move = scene.pbChooseMove(pokemon, _INTL("¿Qué movimiento quieres restaurar?"), nil)
    if move.is_a?(Integer) && move >= 0 && move < pokemon.moves.length
      if pbBattleRestorePP(pokemon, battler, move, 2) > 0
        pbSEPlay("Use item in party")
        scene.pbDisplay(_INTL("Ha restaurado los PP del movimiento."))
        usado = true
      else
        scene.pbDisplay(_INTL("No tendrá ningún efecto en los PP."))
      end
    else
      scene.pbDisplay(_INTL("No se seleccionó ningún movimiento."))
    end
  else
    scene.pbDisplay(_INTL("No tiene movimientos para restaurar PP."))
  end

  unless usado
    scene.pbDisplay(_INTL("No tendrá ningún efecto."))
  end
})





# Cafe en pokemon fuera batalla
ItemHandlers::UseOnPokemon.add(:CAFE, proc { |item, qty, pkmn, scene|
  if pkmn.fainted?
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  
  healed = false
   if pkmn.status == :SLEEP
    pbSEPlay("Use item in party")
    pkmn.heal_status
    healed = true
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1} se despertó gracias al café.", pkmn.name))
  end
  
  if pkmn.hp < pkmn.totalhp
    pbSEPlay("Use item in party")
    pkmn.hp += 30
    pkmn.hp = [pkmn.hp, pkmn.totalhp].min
    healed = true
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1} recuperó energía con el café.", pkmn.name))
  end

  unless healed
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
  end

  next healed
})
# Cafe en pokemon en batalla
ItemHandlers::CanUseInBattle.add(:CAFE, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  next pbBattleItemCanCureStatus?(:SLEEP, pokemon, scene, showMessages)
})

