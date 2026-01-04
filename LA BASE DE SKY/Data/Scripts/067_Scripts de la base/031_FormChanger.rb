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

    def has_alternative_form?
      forms = regional_forms
      forms = forms.delete_if { |form| !form.form_name || form.form_name.empty? }
      return !forms.empty?
    end
  end
end

def change_pokemon_form(force_species = nil, message_var = nil, show_messages = true)
  return false if force_species && !GameData::Species.exists?(force_species)
  
  pbChoosePokemon(1, 2, proc { |pkmn| 
    (force_species && pkmn.species == force_species && GameData::Species.get(force_species).has_alternative_form?) || 
    (!force_species && !CURRENT_SPECIES_BLACKLIST.include?(pkmn.species_data.id) &&
    !pkmn.egg? && !pkmn.shadowPokemon? && REGIONAL_SPECIES.include?(GameData::Species.get(pkmn.species).species)
    )
  })

  if $game_variables[1] == -1
    text = _INTL("¿No? ¿De verdad no quieres probar una versión distinta de alguno de tus Pokémon?")
    pbMessage(text) if show_messages
    pbSet(message_var, _INTL("¿No? ¿De verdad no quieres probar una versión distinta de alguno de tus Pokémon?")) if message_var
    return false 
  end

  pokemon = pbGetPokemon(1)
  species = GameData::Species.get(pokemon.species)
  forms = species.regional_forms.reject {|form| form.form == pokemon.form}
  
  if forms.empty?
    text = _INTL("{1} no tiene formas alternativas disponibles.", pokemon.name)
    pbMessage(text) if show_messages
    pbSet(message_var, _INTL("No hay formas alternativas disponibles para {1}.", pokemon.name)) if message_var
    return false if forms.empty?
  end

  if SHOW_SPRITES_IN_FORM_CHANGER
    form_names = forms.map { |form|
      name = !form.form_name || form.form_name.empty? ? _INTL("Forma Normal") : form.form_name
      bitmap = GameData::Species.sprite_bitmap(form.species, form.form)
      [name, bitmap]
    }
    form_names << [_INTL("Cancelar"), nil]
  else
    form_names = forms.map { |form| 
      !form.form_name || form.form_name.empty? ? _INTL("Forma Normal") : form.form_name 
    }
    form_names << _INTL("Cancelar")
  end
  
  form_index = pbMessage(_INTL("¿Qué forma quieres que tenga {1}?", pokemon.name), form_names, -1)
  if form_index != -1 && form_index < forms.length
    pokemon.form = forms[form_index].form
    pokemon.form_simple = pokemon.form
    pokemon.calc_stats
    pokemon.reset_moves
    form_name = form_names[form_index].is_a?(Array) ? form_names[form_index][0] : form_names[form_index]
    text = _INTL("¡Listo! ¡He cambiado la forma de {1} a {2}!", pokemon.name, form_name)
    pbSet(message_var, text) if message_var
    pbMessage(text) if show_messages
    return true 
  end
  text = _INTL("¿No? ¿De verdad no quieres probar una versión distinta de alguno de tus Pokémon?")
  pbSet(message_var, text) if message_var
  pbMessage(text) if show_messages
  false
end

def pokemon_that_can_change_form
  text = REGIONAL_SPECIES.map { |species| GameData::Species.get(species).name }.join(", ")
  return text
end