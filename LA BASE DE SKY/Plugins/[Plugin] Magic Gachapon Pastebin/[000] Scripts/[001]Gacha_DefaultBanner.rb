def defaultBannerConfig
  config  = {
      "banner" => {
              "name" => "Test",
              "bg" => "Graphics/Battlebacks/champion1_bg",
              "rewards" => ["Graphics/Pokemon/Front/JIRACHI","Graphics/Pokemon/Front/CHARIZARD","Graphics/Pokemon/Front/MEW"],
              "stars" => [5, 5, 5],
              "url" => nil,
              "descr" =>  "<ac><b>¡Increible Banner de prueba!</b></ac>\n¡Mira cuantos Pokémon! ¿No te parece super guay? ¡Puedes hacerte con todos dejándote el dinero en este banner!\n<ac>Disponible hasta el <c2=043c3aff>25-12-1995</c2>\n\n<u><b>Premios obtenibles:</b></u> \n*Bidoof 11.5%*\n*Goldeen 11.5%*\n*Ralts 11.5%*\n*Abra Especial 12%*\n*Pichu 28%*\n*Drowzee 28%*\n*Ekans 28%*\n*Eevee 6%*\n*Sandshrew 6%*\n*Dratini 4.5%*\n*Jolteon Especial 1.4%*\n*Max Éter 4.9%*\n*Kangskhan Especial 1.2%*\n*Gyarados Especial 0.9%*\n*Venusaur Especial 0.9%*\n*Master Ball 1.2%*</ac>\n\nNo nos hacemos responsables de los problemas que puedan surgir a partir de este juego del demonio. Úsese con responsabilidad."
              }
      }
  return config
end

def defaultBanner
  prob = rand(100)
  case prob
  when (0...35) #Tier 1 con un 35%
    pokes = [:PIPLUP, :TURTWIG, :CHIMCHAR]
    result = pokes[rand(pokes.length)]
    pokeReward(Pokemon.new(result,20,$player),1)
  when (35...75) #Tier 2 con un 40%
    result = rand(10)
    if (5..7).include?(result)
      pkmn = Pokemon.new(:ABRA,20,$player)
      pkmn.ev[:SPATK]=236
      pkmn.ev[:SPDEF]=76
      pkmn.ev[:SPEED]=196
      pkmn.learn_move(:PSYCHIC)
      pkmn.learn_move(:DAZZLINGGLEAM)
      pkmn.learn_move(:PROTECT)
      pkmn.learn_move(:COUNTER)
      pkmn.calc_stats
      pokeReward(pkmn,2)
    else
      pokes = [:PICHU, :DROWZEE, :EKANS] 
      result = pokes[rand(pokes.length)]
      pokeReward(Pokemon.new(result,20,$player),2)
    end
  when (75...90) #Tier 3 con un 15%
    result = rand(10)
    if (0..3).include?(result)
      pkmn = Pokemon.new(:EEVEE,20,$player)
      pokeReward(pkmn,3)
    elsif (4..7).include?(result)
      pkmn = Pokemon.new(:SANDSHREW,20,$player)
      pokeReward(pkmn,3)
    else
      pkmn = Pokemon.new(:DRATINI,20,$player)
      pokeReward(pkmn,3)
    end
  when (90...97) #Tier 4 con un 7%
    result = rand(10)
    if result > 7
      pkmn = Pokemon.new(:JOLTEON,20,$player)
      pkmn.iv[:HP]=31
      pkmn.iv[:ATK]=31
      pkmn.iv[:DEF]=31
      pkmn.iv[:SPEED]=31
      pkmn.learn_move(:BITE)
      pkmn.learn_move(:HIDDENPOWER)
      pkmn.learn_move(:THUNDERSHOCK)
      pkmn.calc_stats
      pokeReward(pkmn,4)
    else
      pkmn = Pokemon.new(:JOLTEON,20,$player)
	  pkmn.calc_stats
      pokeReward(pkmn,4)
    end
  when (97...100) #Tier 5 con un 3%
    result = rand(10)
    if (0..3).include?(result)
      pkmn = Pokemon.new(:KANGASKHAN,20,$player)
      pkmn.ev[:HP]=212
      pkmn.ev[:ATTACK]=252
      pkmn.ev[:SPEED]=44
      pkmn.item = :SMOKEBALL
      pkmn.nature = :ADAMANT
      pkmn.ability_index = 0
      pkmn.calc_stats
      pokeReward(pkmn,5)
    elsif (4..5).include?(result)
      pkmn = Pokemon.new(:GYARADOS,20,$player)
      pkmn.ev[:HP]=68
      pkmn.ev[:ATTACK]=252
      pkmn.ev[:SPEED]=188
      pkmn.item = :SMOKEBALL
      pkmn.nature = :ADAMANT
      pkmn.learn_move(:DRAGONDANCE)
      pkmn.calc_stats
      pokeReward(pkmn,5)
    elsif (6..7)
      pkmn = Pokemon.new(:VENUSAUR,20,$player)
      pkmn.ev[:HP]=252
      pkmn.ev[:DEFENSE]=84
      pkmn.ev[:SPDEF]=148
      pkmn.ev[:SPEED]=24
      pkmn.ability_index = 0
      pkmn.calc_stats
      pokeReward(pkmn,5)
    else
      pkmn = Pokemon.new(:JOLTEON,20,$player)
	  pkmn.calc_stats
      pokeReward(pkmn,4)
    end
  end
end