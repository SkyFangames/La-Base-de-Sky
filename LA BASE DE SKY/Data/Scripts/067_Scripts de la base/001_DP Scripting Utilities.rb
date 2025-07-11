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


def get_pokeapi_data(species)
	if species.is_a?(GameData::Species)
		species_name = species.id.to_s.downcase
		case species.id
		when :NIDORANfE
				species_name = "nidoran-f"
		when :NIDORANmA
				species_name = "nidoran-m"
		when :MRMIME
				species_name = "mr-mime"
		when :MIMEJR
				species_name = "mime-jr"
		end

		if species.form > 0
				species_name += "-#{species.form_name.downcase}"
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
	new_stats = {}
	if data
		stat_data = data["stats"]
		stat_data.each do |stat|
			stat_name = stat["stat"]["name"]
			stat_value = stat["base_stat"]
			stat_key = stat_name.upcase.tr("-", "_").to_sym
			new_stats[stat_key] = stat_value
		end
		data["stats"] = new_stats
		abilities_data = data["abilities"]
		new_abs = {}
		abilities_data.each do |ability|
			ability_key = ability["ability"]["name"].upcase.tr("-", "").to_sym
			ability_name = GameData::Ability.try_get(ability_key)&.name
			next if ability_name.nil?
			ability_hidden = ability["is_hidden"]
			ability_index = ability["slot"].to_i
			new_abs[ability_key] = [ability_name, ability_index, ability_hidden]
		end
		data["abilities"] = new_abs
	end
	return data
end