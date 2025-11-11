def storage_gain_exp(battler)
    for x in 0...$PokemonStorage.maxBoxes
        for y in 0...$PokemonStorage.maxPokemon(x)
            next if !$PokemonStorage[x,y]
            next if $PokemonStorage[x,y].egg?
            current_pokemon=$PokemonStorage[x,y]
            maxexp=current_pokemon.growth_rate.maximum_exp
            if current_pokemon.exp<maxexp
                oldlevel=current_pokemon.level
                baseexp=battler.pokemon.base_exp
                exp=(battler.level*baseexp).floor
                leveladjust=(2*battler.level+10.0)/(battler.level+current_pokemon.level+10.0)
                leveladjust=leveladjust**5
                leveladjust=Math.sqrt(leveladjust)
                exp=(exp*leveladjust).floor
                current_pokemon.exp+=(exp*0.11).floor #cambiar número para modificar
                if current_pokemon.level!=oldlevel
                    current_pokemon.calc_stats
                    movelist= current_pokemon.getMoveList
                    for move in movelist
                        current_pokemon.pbLearnMove(move[1]) if move[0]==current_pokemon.level # Learned a new move
                    end
                end
            end
        end
    end
end