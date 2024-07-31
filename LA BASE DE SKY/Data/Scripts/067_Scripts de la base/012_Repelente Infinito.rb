#===============================================================================
# Infinite Repel by dpertierra
# https://github.com/Pokemon-Fan-Games/InifiniteRepel
# https://twitter.com/dpertierra
#===============================================================================
class PokemonGlobalMetadata
    attr_accessor :infRepel
    attr_accessor :repel
end
  
def pbToggleInfiniteRepel()
  if !$PokemonGlobal.infRepel
    Kernel.pbMessage("Se activó el repelente infinito.")
  else
    Kernel.pbMessage("Se desactivó el repelente infinito.")
  end
  $PokemonGlobal.infRepel = !$PokemonGlobal.infRepel
  return 0
end

ItemHandlers::UseFromBag.add(:INFREPEL,proc{|item| pbToggleInfiniteRepel() })
ItemHandlers::UseText.add(:INFREPEL, proc { |item| next ($PokemonGlobal.infRepel) ? _INTL("Desactivar") : _INTL("Activar")})

alias pbBattleOnStepTakenOverride pbBattleOnStepTaken 
def pbBattleOnStepTaken(repel_active)
  repel = ($PokemonGlobal.infRepel  || $PokemonGlobal.repel > 0 || repel_active)
  pbBattleOnStepTakenOverride(repel)
end
