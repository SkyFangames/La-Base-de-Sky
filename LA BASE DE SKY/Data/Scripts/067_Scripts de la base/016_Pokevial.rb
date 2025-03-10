#===============================================================================
# CREDITOS
# Voltseon, DPertierra, lavinytuttini
#===============================================================================
class PokemonGlobalMetadata
    attr_accessor :vial_charges
    attr_accessor :max_vial_charges
    attr_accessor :vial_locked
end

INITIAL_CHARGES_POKEVIAL = 1 
INFINITE_POKEVIAL = false

ItemHandlers::UseFromBag.add(:VIAL, proc { |item| use_pokevial; next 1 })
ItemHandlers::UseInField.add(:VIAL, proc { |item| use_pokevial; next 1 })

def init_pokevial
  $PokemonGlobal.vial_charges ||= INITIAL_CHARGES_POKEVIAL
  $PokemonGlobal.max_vial_charges ||= INITIAL_CHARGES_POKEVIAL
  $PokemonGlobal.vial_locked ||= false
end

def lock_vial
  return unless ensure_pokevial_initialized
  $PokemonGlobal.vial_locked = true
  Kernel.pbMessage(_INTL("El Pokévial ha sido bloqueado."))
end

def unlock_vial
  return unless ensure_pokevial_initialized
  $PokemonGlobal.vial_locked = false
  Kernel.pbMessage(_INTL("El Pokévial ha sido desbloqueado."))
end

def ensure_pokevial_initialized
  return false unless has_player_pokevial
  init_pokevial
  true
end

def has_player_pokevial
  $bag.has?(:VIAL) || $bag.has?(:EMPTYVIAL)
end


def show_message_pokevial
  if $PokemonGlobal.vial_charges <= 0
    Kernel.pbMessage(_INTL("El Pokévial está vacío. Recárgalo en el Centro Pokémon."))
    return false
  end
  if !INFINITE_POKEVIAL
    Kernel.pbMessage(_INTL("Tienes {1} {2} {3} de un máximo de {4}.",
      $PokemonGlobal.vial_charges,
      $PokemonGlobal.vial_charges == 1 ? "curación" : "curaciones",
      $PokemonGlobal.vial_charges == 1 ? "disponible" : "disponibles",
      $PokemonGlobal.max_vial_charges))
  end
  true
end

def max_vial_charges
  ensure_pokevial_initialized
  $PokemonGlobal.max_vial_charges || 0
end

def vial_charges
  ensure_pokevial_initialized
  $PokemonGlobal.vial_charges || 0
end

def vial_full?
  ensure_pokevial_initialized
  $PokemonGlobal.vial_charges == $PokemonGlobal.max_vial_charges
end


def use_pokevial
  return unless ensure_pokevial_initialized
  if $PokemonGlobal.vial_locked
    Kernel.pbMessage(_INTL("El Pokévial está bloqueado."))
    return
  end
  return unless show_message_pokevial
  if Kernel.pbConfirmMessage(_INTL("¿Quieres curar a tu equipo?"))
    heal_party_with_pokevial
  end
end

def heal_party_with_pokevial
  $player.heal_party
  pbMEPlay("Pkmn healing")
  Kernel.pbMessage(_INTL("¡Tu equipo Pokémon se ha curado al completo!"))
  $PokemonGlobal.vial_charges -= 1 if !INFINITE_POKEVIAL
  $bag.replace_item(:VIAL, :EMPTYVIAL) if $PokemonGlobal.vial_charges <= 0
end

def recharge_vial
    return unless ensure_pokevial_initialized
    $PokemonGlobal.vial_charges = $PokemonGlobal.max_vial_charges
    Kernel.pbMessage(_INTL("¡Tu Pokévial ha sido recargado!")) if !INFINITE_POKEVIAL
    $bag.replace_item(:EMPTYVIAL,:VIAL) if $bag.has?(:EMPTYVIAL)
end

def add_new_vial_charge
    return unless ensure_pokevial_initialized || INFINITE_POKEVIAL
    $PokemonGlobal.max_vial_charges += 1
    # Se hace de esta forma para que recibir una nueva carga no restaure completamente el vial
    $PokemonGlobal.vial_charges += 1
    Kernel.pbMessage(_INTL("¡Ahora tu Pokévial puede almacenar {1} carga#{$PokemonGlobal.max_vial_charges > 1 ? 's' : ''}!",$PokemonGlobal.max_vial_charges))
end

def remove_vial_charge
  return unless ensure_pokevial_initialized || INFINITE_POKEVIAL
  if $PokemonGlobal.max_vial_charges > 1
    $PokemonGlobal.max_vial_charges -= 1
    # Se hace de esta forma para que al eliminar una carga no restaure completamente el vial
    $PokemonGlobal.vial_charges -= 1 if $PokemonGlobal.vial_charges > 0
    Kernel.pbMessage(_INTL("¡Ahora tu Pokévial puede almacenar {1} carga#{$PokemonGlobal.max_vial_charges > 1 ? 's' : ''}!", 
                           $PokemonGlobal.max_vial_charges))
  end
end

