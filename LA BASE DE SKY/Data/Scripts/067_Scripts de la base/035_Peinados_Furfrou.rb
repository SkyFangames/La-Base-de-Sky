# NPC Peluquero de Furfrou
# Constants for better maintainability
POKEMON_VARIABLE_INDEX = 1
POKEMON_STORAGE_INDEX = 2
CANCEL_OPTION_INDEX = -1
DAYS_UNTIL_HAIRCUT_EXPIRES = 7

HAIRCUTS = [
	_INTL("Corte Corazón (Normal/Hada)"),
	_INTL("Corte Estrella (Normal/Volador)"),
	_INTL("Corte Rombo (Normal/Roca)"),
	_INTL("Corte Señorita (Normal/Eléctrico)"),
	_INTL("Corte Dama (Normal/Psíquico)"),
	_INTL("Corte Caballero (Normal/Planta)"),
	_INTL("Corte Aristocrático (Normal/Hielo)"),
	_INTL("Corte Kabuki (Normal/Fuego)"),
	_INTL("Corte Faraónico (Normal/Agua)"),
	_INTL("Cancelar")
]

HAIRCUTS_TEXTS = [
	"¡{1} ahora tiene un adorable corte en forma de corazón!",
	"¡{1} brilla con su nuevo corte estrella!",
	"¡{1} luce elegante con su corte rombo!",
	"¡{1} se ve encantadora con su corte señorita!",
	"¡{1} irradia elegancia con su corte dama!",
	"¡{1} se ve distinguido con su corte caballero!",
	"¡{1} luce majestuoso con su corte aristocrático!",
	"¡{1} se ve espectacular con su corte kabuki!",
	"¡{1} luce majestuoso con su corte faraónico!"
]
# Helper methods for better code organization

def select_furfrou_from_party
	pbChoosePokemon(POKEMON_VARIABLE_INDEX, POKEMON_STORAGE_INDEX, proc { |pkmn|
		next pkmn.isSpecies?(:FURFROU) && pkmn.able?
	})

	return nil if $game_variables[POKEMON_VARIABLE_INDEX] < 0
	pbGetPokemon(POKEMON_VARIABLE_INDEX)
end

def get_haircut_choice(furfrou)
	pbMessage(_INTL("¿Qué estilo de corte te gustaría para {1}?", furfrou.name), HAIRCUTS, CANCEL_OPTION_INDEX, nil, furfrou.form)
end

def is_cancel_choice?(choice)
	choice == CANCEL_OPTION_INDEX || choice == HAIRCUTS.length - 1
end

def has_same_haircut?(furfrou, new_form)
	new_form + 1 == furfrou.form
end

def apply_haircut(furfrou, new_form)
	FollowingPkmn.toggle_off if defined?(FollowingPkmn)
	
	# old_form = furfrou.form
	furfrou.form = new_form + 1
	furfrou.time_form_set = pbGetTimeNow.to_i
	furfrou.calc_stats
	
	pbMessage(_INTL("¡Perfecto! {1} ha cambiado de peinado.", furfrou.name))
	
	# Validate array bounds before accessing
	if new_form < HAIRCUTS_TEXTS.length
		pbMessage(_INTL(HAIRCUTS_TEXTS[new_form], furfrou.name))
	end
	
	pbMessage(_INTL("¡Espero que te guste el nuevo look de {1}!", furfrou.name))
	pbMessage(_INTL("Recuerda que tras {1} días perderá el peinado. ¡Ven a verme de nuevo cuando eso ocurra!", DAYS_UNTIL_HAIRCUT_EXPIRES))
	
	FollowingPkmn.toggle_on if defined?(FollowingPkmn)
end

# Coloca este código en un evento en el mapa donde quieras al NPC
def peluquero_furfrou
	# Código para el evento del NPC (usar en "Comando de Script"):
	pbMessage(_INTL("¡Hola! Soy un peluquero especializado en Furfrou."))

	unless pbConfirmMessage(_INTL("¿Quieres cambiar el peinado de tu Furfrou?"))
		pbMessage(_INTL("De acuerdo. ¡Vuelve cuando quieras un cambio de look!"))
		return
	end

	# Verificar si tiene un Furfrou en el equipo
	unless $player.has_species?(:FURFROU)
		pbMessage(_INTL("No tienes ningún Furfrou en tu equipo."))
		pbMessage(_INTL("Trae uno la próxima vez y le haré un corte espectacular."))
		return
	end

	# Abrir la pantalla de selección de Pokémon
	pbMessage(_INTL("¡Perfecto! Selecciona el Furfrou al que quieres cambiar el peinado."))
	
	chosen_furfrou = select_furfrou_from_party
	unless chosen_furfrou
		pbMessage(_INTL("Vuelve cuando quieras cambiar el peinado."))
		return
	end
	
	if chosen_furfrou.fainted?
		pbMessage(_INTL("No puedo peinar a un Pokémon debilitado."))
		pbMessage(_INTL("Cúralo primero y vuelve."))
		return
	end

	# Mostrar opciones de peinados
	new_form = get_haircut_choice(chosen_furfrou)

	if is_cancel_choice?(new_form)
			pbMessage(_INTL("De acuerdo, será en otra ocasión."))
	elsif has_same_haircut?(chosen_furfrou, new_form)
			pbMessage(_INTL("{1} ya tiene ese peinado.", chosen_furfrou.name))
	else
			apply_haircut(chosen_furfrou, new_form)
	end
end