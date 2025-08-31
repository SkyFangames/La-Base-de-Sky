#===============================================================================
# CREDITOS
# DPertierra
#===============================================================================
MenuHandlers.add(:party_menu, :pokedex, {
    "name"      => _INTL("Pokédex"),
    "order"     => 60,
    "condition" => proc { next $player.has_pokedex && $player.pokedex.unlocked?(-1) },
    "effect"    => proc { |screen, party, party_idx|
      openPokedexOnPokemon(party[party_idx].species, party[party_idx].gender, party[party_idx].form)
    }
})

def openPokedexOnPokemon(species, gender, form = 0)
    region = -1
    pokedexScene = PokemonPokedexInfo_Scene.new
    pokedexScreen = PokemonPokedexInfoScreen.new(pokedexScene)
    dexlist, index = pbGetDexList(species, region)
    $player.pokedex.set_last_form_seen(species, gender, form)
    pokedexScreen.pbStartScreen(dexlist, index, region)
end

def pbGetDexList(species_to_find = nil, region = -1)
  regionalSpecies = pbAllRegionalSpecies(region)
  if !regionalSpecies || regionalSpecies.length == 0
    # If no Regional Dex defined for the given region, use the National Pokédex
    regionalSpecies = []
    GameData::Species.each_species { |s| regionalSpecies.push(s.id) }
  end
  shift = Settings::DEXES_WITH_OFFSETS.include?(region)
  dexlist = []
  index = 1
  regionalSpecies.each_with_index do |species, i|
    next if !species
    # next if !pbCanAddForModeList?($PokemonGlobal.pokedexMode, species)
    _gender, form, _shiny = $player.pokedex.last_form_seen(species)
    species_data = GameData::Species.get_species_form(species, form)
    index = i if species_to_find == species
    dexlist.push({
      :species => species,
      :name    => species_data.name,
      :height  => species_data.height,
      :weight  => species_data.weight,
      :number  => i + 1,
      :shift   => shift,
      :types   => species_data.types,
      :color   => species_data.color,
      :shape   => species_data.shape
    })
  end
  return dexlist, index
end