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
  $PokemonGlobal.infRepel ||= false
  if !$PokemonGlobal.infRepel
    pbMessage("Se activó el repelente infinito.")
    $bag.replace_item(:INFREPELOFF, :INFREPEL)
    $bag.replace_registered(:INFREPELOFF, :INFREPEL)
  else
    pbMessage("Se desactivó el repelente infinito.")
    $bag.replace_item(:INFREPEL, :INFREPELOFF)
    $bag.replace_registered(:INFREPEL, :INFREPELOFF)
  end
  $PokemonGlobal.infRepel = !$PokemonGlobal.infRepel
  return 0
end

ItemHandlers::UseFromBag.add(:INFREPEL,proc{|item| pbToggleInfiniteRepel() })
ItemHandlers::UseFromBag.add(:INFREPELOFF,proc{|item| pbToggleInfiniteRepel() })
ItemHandlers::UseInField.add(:INFREPEL,proc{|item| pbToggleInfiniteRepel() })
ItemHandlers::UseInField.add(:INFREPELOFF,proc{|item| pbToggleInfiniteRepel() })
ItemHandlers::UseText.add(:INFREPEL, proc { |item| next _INTL("Desactivar")})
ItemHandlers::UseText.add(:INFREPELOFF, proc { |item| next _INTL("Activar")})

alias pbBattleOnStepTakenOverride pbBattleOnStepTaken 
def pbBattleOnStepTaken(repel_active)
  $PokemonGlobal.infRepel ||= false
  repel = ($PokemonGlobal.infRepel || $PokemonGlobal.repel > 0 || repel_active) ? true : false
  pbBattleOnStepTakenOverride(repel)
end
