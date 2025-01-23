module GameData
  class Species
    def regional_forms
      forms = []
      has_dinamax = PluginManager.installed?("[DBK] Dynamax")
      DATA.each_value { |species|
        if self.species == species.species && !(species.mega_stone || species.mega_move) && 
          (!FORMS_BLACKLIST[species.species] || !FORMS_BLACKLIST[species.species].include?(species.form)) &&
          (!has_dinamax || (has_dinamax && !species.dynamax_form?))
          forms << species
        end
      }
      forms
    end
  end
end

def change_pokemon_form
  pbChoosePokemon(1, 2, proc { |pkmn|
    !pkmn.egg? && !pkmn.shadowPokemon? && REGIONAL_SPECIES.include?(GameData::Species.get(pkmn.species).species)
  })
  return false if $game_variables[1] == -1
  pokemon = pbGetPokemon(1)
  species = GameData::Species.get(pokemon.species)
  forms = species.regional_forms.reject {|form| form.form == pokemon.form}
  form_names = forms.map { |form| 
    !form.form_name || form.form_name.empty? ? _INTL("Forma Normal") : form.form_name 
  }
  form_names << _INTL("Cancelar")
  form_index = pbMessage(_INTL("¿Qué forma quieres que tenga {1}?", pokemon.name), form_names, -1)
  if form_index != -1 && form_index < forms.length
    pokemon.form = forms[form_index].form
    pokemon.form_simple = pokemon.form
    pokemon.calc_stats
    pokemon.reset_moves
    pbMessage(_INTL("¡Listo! ¡He cambiado la forma de {1} a {2}!", pokemon.name, form_names[form_index]))
    return true 
  end
  pbMessage(_INTL("Lo dejamos como está entonces."))
  false
end