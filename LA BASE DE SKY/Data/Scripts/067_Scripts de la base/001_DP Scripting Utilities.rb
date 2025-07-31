# Define a mapping of accented characters to unaccented characters
ACCENTED_CHARACTERS = {
  'á' => 'a', 'Á' => 'A', 'à' => 'a', 'ä' => 'a', 'â' => 'a', 'ã' => 'a', 'å' => 'a', 
  'é' => 'e', 'É' => 'E', 'è' => 'e', 'ë' => 'e', 'ê' => 'e',
  'í' => 'i', 'Í' => 'I', 'ì' => 'i', 'ï' => 'i', 'î' => 'i',
  'ó' => 'o', 'Ó' => 'O', 'ò' => 'o', 'ö' => 'o', 'ô' => 'o', 'õ' => 'o',
  'ú' => 'u', 'Ú' => 'U', 'ù' => 'u', 'ü' => 'u', 'û' => 'u',
  'ç' => 'c'
}

$:.push File.join(Dir.pwd, "Ruby Library 3.3.0")

def json_remove_comments(json_str)
  json_str.gsub(/\/\/.*$/, '').gsub(/\/\*.*?\*\//m, '')
end

############### Workaround para el ordenamiento en JoiPlay ###############
def remove_accents_joiplay(str)
  str.chars.map { |char| ACCENTED_CHARACTERS[char] || char }.join
end

# Natural sort comparison method 
def natural_sort_key_joiplay(str)
  # Remove accents and non-alphanumeric characters, and split into chunks of numbers and non-numbers
  str = remove_accents_joiplay(str).downcase
  remove_accents_joiplay(str).gsub(/[^a-z0-9]/, '').scan(/\d+|\D+/).map { |chunk| chunk =~ /\d/ ? chunk.to_i : chunk }
end
############### Workaround para el ordenamiento en JoiPlay ###############

# Helper function to remove accents from a string using Unicode normalization
def remove_accents(str)
  str.unicode_normalize(:nfd).gsub(/[^\u0000-\u007F]/, '') # Remove non-ASCII characters after normalization
end
  
# Natural sort comparison method
def natural_sort_key(str)
  # Remove accents, non-alphanumeric characters, and split into chunks of numbers and non-numbers
  return natural_sort_key_joiplay(str) if $joiplay
  remove_accents(str.downcase).gsub(/[^a-z0-9]/, '').scan(/\d+|\D+/).map { |chunk| chunk.match?(/\d/) ? chunk.to_i : chunk }
end

module PokeAPI
	module_function
	
	def get_data(species)
		if species.is_a?(GameData::Species)
			species_name = get_species_name(species)

			if species.form > 0
				if species.mega_stone || species.mega_move
					species_name += get_mega_form_name(species)
				else
					species_name += get_form_name(species)
				end
			end
		else
			species_name = species.downcase

		end
		uri = "https://pokeapi.co/api/v2/pokemon/#{species_name}"
		begin 
			response = pbDownloadToString(uri)
		rescue MKXPError
			return nil
		end
		return nil if response.nil? || response.empty?
		data = HTTPLite::JSON.parse(response)
		return parse_data(data, species)
	end

	def get_species_name(species)
		species_name = species.id.to_s.downcase
		species_name.gsub!(/_\d+$/, '')
		case species.id
		when :NIDORANfE
			species_name = "nidoran-f"
		when :NIDORANmA
			species_name = "nidoran-m"
		when :MRMIME, :MRMIME_1
			species_name = "mr-mime"
		when :MIMEJR
			species_name = "mime-jr"
		when :WORMADAM
			species_name += '-plant'
		when :MEOWSTIC
			species_name += '-male' 
		when :PUMPKABOO, :GOURGEIST
			species_name += '-small'
		when :LYCANROC
			species_name += '-midday'
		when :TYPENULL
			species_name = 'type-null'
		when :MINIOR
			species_name += '-orange-meteor'
		when :MIMIKYU
			species_name += '-disguised'
		when :JANGMOO
			species_name = 'jangmo-o'
		when :HAKAMOO
			species_name = 'hakamo-o'
		when :KOMMOO
			species_name = 'kommo-o'
	    when :TAPUKOKO
			species_name = 'tapu-koko'
		when :TAPUBULU
			species_name = 'tapu-bulu'
		when :TAPULELE
			species_name = 'tapu-lele'
		when :TAPUFINI
			species_name = 'tapu-fini'
		when :TOXTRICITY
			species_name += '-amped'
		when :EISCUE
			species_name += '-ice'
		when :INDEEDEE, :BASCULEGION, :OINKOLOGNE
			species_name += '-male'
		when :MORPEKO
			species_name += '-full-belly'
		when :URSHIFU
			species_name += '-single-strike'
		when :MAUSHOLD
			species_name += '-family-of-four'
		when :SQUAWKABILLY
			species_name += '-green-plumage'
		when :PALAFIN
			species_name += '-zero'
		when :TATSUGIRI
			species_name += '-curly'
		when :DUDUNSPARCE
			species_name += '-two-segment'
		when :GREATTUSK
			species_name = 'great-tusk'
		when :SCREAMTAIL
			species_name = 'scream-tail'
		when :BRUTEBONNET
			species_name = 'brute-bonnet'
		when :FLUTTERMANE
			species_name = 'flutter-mane'
		when :SLITHERWING
			species_name = 'slither-wing'
		when :SANDYSHOCKS
			species_name = 'sandy-shocks'
		when :IRONTHREADS
			species_name = 'iron-threads'
		when :IRONBUNDLE
			species_name = 'iron-bundle'
		when :IRONJUGULIS
			species_name = 'iron-jugulis'
		when :IRONMOTH
			species_name = 'iron-moth'
		when :IRONTHORNS
			species_name = 'iron-thorns'
	    when :IRONHANDS
			species_name = 'iron-hands'
		end
		return species_name
	end


	def parse_data(data, species)
		return nil if !data || data.empty?
		new_stats = {}
		data["species"] = species.is_a?(GameData::Species) ? species.id : species.to_sym
		data["form"] = species.is_a?(GameData::Species) ? species.form : 0
		stat_data = data.fetch("stats", [])
		stat_data.each do |stat|
			stat_name = stat.fetch("stat", {}).fetch("name", "").upcase.tr("-", "_").to_sym
			stat_value = stat.fetch("base_stat", 0)
			next if !stat_name || !stat_value || stat_value <= 0
			new_stats[stat_name] = stat_value
		end
		data["stats"] = new_stats
		abilities_data = data.fetch("abilities", [])
		new_abs = {}
		abilities_data.each do |ability|
			ability_key = ability.fetch("ability", {}).fetch("name", "").upcase.tr("-", "").to_sym
			ability_name = GameData::Ability.try_get(ability_key)&.name
			next if ability_name.nil?
			ability_hidden = ability["is_hidden"]
			ability_index = ability["slot"].to_i
			new_abs[ability_key] = [ability_name, ability_index, ability_hidden]
		end
		data["abilities"] = new_abs

		types = data.fetch("types", []) 
		new_types = []
		types.each do |type|
			type_key = type.fetch("type", {}).fetch("name", "").upcase.tr("-", "_").to_sym
			next if !GameData::Type.exists?(type_key)
			new_types << type_key
		end
		data["types"] = new_types
		return data
	end
	
	def get_mega_form_name(species)
		case species.species
		when :CHARIZARD, :MEWTWO
			return "-mega-#{species.form_name.split(' ')[2].downcase}"
		else
			return "-mega"
		end
	end
	
	def get_form_name(species)
		form_name = species.region && !species.region.empty? ? species.region.downcase : species.form_name.downcase.gsub(/forma\s+/, '').strip
		case species.species
		when :TAUROS
			if species.form_name.downcase.include?("combatiente")
				form_name += "-combat-breed"
			elsif species.form_name.downcase.include?("ardiente")
				form_name += "-blaze-breed"
			elsif species.form_name.downcase.include?("acuática")
				form_name += "-aqua-breed"
			end
		when :CASTFORM
			if species.form_name.downcase.include?("sol")
				form_name = "sunny"
			elsif species.form_name.downcase.include?("lluvia")
				form_name = "rainy"
			elsif species.form_name.downcase.include?("nieve")
				form_name = "snowy"
			end
		when :BURMY, :WORMADAM
			if species.form_name.downcase.include?("arena")
				form_name = "sandy"
			elsif species.form_name.downcase.include?("basura")
				form_name = "trash"
			end
		when :CHERRIM
			if species.form_name.downcase.include?("soleada")
				form_name = "sunshine"
			end
		when :MEOWSTIC
			form_name = 'female'
		when :PUMPKABOO, :GOURGEIST
			if species.form_name.downcase.include?("extragrande")
				form_name = "super"
			elsif species.form_name.downcase.include?("grande")
				form_name = "large"
			elsif species.form_name.downcase.include?("normal")
				form_name = "average"
			end
		when :LYCANROC
			if species.form_name.downcase.include?('nocturna')
				form_name = 'midnight'
			elsif species.form_name.downcase.include?('crepuscular')
				form_name = 'dusk'
			end
		when :MINIOR
			if species.form_name.downcase.include?('rojo')
				form_name = 'red'
			elsif species.form_name.downcase.include?('naranja')
				form_name = 'orange'
			elsif species.form_name.downcase.include?('amarillo')
				form_name = 'yellow'
			elsif species.form_name.downcase.include?('verde')
				form_name = 'green'
			elsif species.form_name.downcase.include?('azul')
				form_name = 'blue'
			elsif species.form_name.downcase.include?('añil')
				form_name = 'indigo'
			elsif species.form_name.downcase.include?('violeta')
				form_name = 'purple'
			end
		when :MIMIKYU
			if species.form_name.downcase.include?('descubierta')
				form_name = 'busted'
			end
		when :TOXTRICITY
			if species.form_name.downcase.include?('grave')
				form_name = 'low-key'
			end
		when :EISCUE
			if species.form_name.downcase.include?('deshielo')
				form_name = 'noice'
			end
		when :INDEEDEE, :BASCULEGION, :OINKOLOGNE
			if species.form_name.downcase.include?('hembra')
				form_name = 'female'
			end
		when :MORPEKO
			if species.form_name.downcase.include?('voraz')
				form_name = 'hangry'
			end
		when :URSHIFU
			if species.form_name.downcase.include?('fluido')
				form_name = 'rapid-strike'
			end
		when :MAUSHOLD
			if species.form_name.downcase.include?('tres')
				form_name = 'family-of-three'
			end
		when :SQUAWKABILLY
			if species.form_name.downcase.include?('azul')
				form_name = 'blue-plumage'
			elsif species.form_name.downcase.include?('amarillo')
				form_name = 'yellow-plumage'
			elsif species.form_name.downcase.include?('blanco')
				form_name = 'white-plumage'
			end
		when :PALAFIN
			form_name = 'hero'
		when :TATSUGIRI
			if species.form_name.downcase.include?('lánguida')
				form_name = 'droopy'
			elsif species.form_name.downcase.include?('recta')
				form_name = 'stretchy'
			end
		when :DUDUNSPARCE
			if species.form_name.downcase.include?('trinodular')
				form_name = 'three-segment'
			end
		end
		return "-#{form_name}"
	end
end