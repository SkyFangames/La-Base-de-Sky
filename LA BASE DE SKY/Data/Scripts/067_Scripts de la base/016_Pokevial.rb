#===============================================================================
# CREDITOS
# Voltseon, DPertierra
#===============================================================================
class PokemonGlobalMetadata
    attr_accessor :vial_charges
    attr_accessor :max_vial_charges
end

CARGAS_INICIALES_POKEVIAL = 1 

ItemHandlers::UseInField.add(:VIAL,proc{|item|
   inicializar_pokevial() if !$PokemonGlobal.vial_charges
   case $PokemonGlobal.vial_charges
   when 0
     Kernel.pbMessage(_INTL("Al Pokévial no le queda ningún uso..."))
     $bag.replace_item(:VIAL,:EMPTYVIAL) #this should never happen btw
   when 1
     Kernel.pbMessage(_INTL("El Pokévial tiene 1 curación disponible de un máximo de {1}.", $PokemonGlobal.max_vial_charges))
     if Kernel.pbConfirmMessage("¿Quieres curar a tu equipo?")
        $PokemonGlobal.vial_charges -= 1
       for i in $player.party
        i.heal
       end
       Kernel.pbMessage(_INTL("¡Tu equipo Pokémon se ha curado al completo!"))
       $bag.replace_item(:VIAL,:EMPTYVIAL)
     end
   else
     Kernel.pbMessage(_INTL("El Pokévial tiene {1} curaciones disponibles de un máximo de {2}.",$PokemonGlobal.vial_charges, $PokemonGlobal.max_vial_charges))
     if Kernel.pbConfirmMessage("¿Quieres curar a tu equipo?")
       $PokemonGlobal.vial_charges -= 1
       for i in $player.party
        i.heal
       end
       Kernel.pbMessage(_INTL("¡Tu equipo Pokémon se ha curado al completo!"))
     end
   end
   next 1
})

def recharge_vial()
    return if !($bag.has?(:EMPTYVIAL) || $bag.has?(:VIAL))
    $PokemonGlobal.vial_charges = $PokemonGlobal.max_vial_charges ? $PokemonGlobal.max_vial_charges : CARGAS_INICIALES_POKEVIAL
    Kernel.pbMessage(_INTL("¡Tu Pokévial ha sido recargado!"))
    $bag.replace_item(:EMPTYVIAL,:VIAL) if $bag.has?(:EMPTYVIAL)
end

def add_new_vial_charge()
    return if !($bag.has?(:EMPTYVIAL) || $bag.has?(:VIAL))
    $PokemonGlobal.max_vial_charges += 1
    Kernel.pbMessage(_INTL("¡Ahora tu Pokévial puede almacenar {1} cargas!",$PokemonGlobal.max_vial_charges))
end

def inicializar_pokevial()
  if !$PokemonGlobal.vial_charges
    $PokemonGlobal.vial_charges=CARGAS_INICIALES_POKEVIAL
  end
  if !$PokemonGlobal.max_vial_charges
    $PokemonGlobal.max_vial_charges=CARGAS_INICIALES_POKEVIAL 
  end
end
