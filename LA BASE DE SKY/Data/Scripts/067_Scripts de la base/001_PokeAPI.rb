# Add pokeapi_cache attribute to PokemonGlobalMetadata
class PokemonGlobalMetadata
	attr_accessor :pokeapi_cache
end

module PokeAPI
	module_function
	
	CACHE_DURATION = 60 * 24 * 60 * 60 # 60 days in seconds
	
	# Initialize cache in PokemonGlobalMetadata if it doesn't exist
	def initialize_cache
		$PokemonGlobal.pokeapi_cache = {} if $PokemonGlobal.pokeapi_cache.nil?
	end
	
	# Get cache from PokemonGlobalMetadata
	def get_cache
		initialize_cache
		return $PokemonGlobal.pokeapi_cache
	end
	
	# Get cached data if it exists and is not expired
	def get_cached_data(cache_key)
		cache = get_cache
		cached_entry = cache[cache_key]
		return nil unless cached_entry
		
		# Check if cache entry has expired
		if Time.now - cached_entry[:timestamp] > CACHE_DURATION
			# Remove expired entry
			cache.delete(cache_key)
			return nil
		end
		
		return cached_entry[:data]
	end
	
	# Store data in cache
	def cache_data(cache_key, data)
		cache = get_cache
		cache[cache_key] = {
			data: data,
			timestamp: Time.now
		}
	end
	
	# Generate cache key for a species
	def generate_cache_key(species)
		if species.is_a?(GameData::Species)
			return "#{species.id}_#{species.form}"
		else
			return species.to_s.downcase
		end
	end
	
	# Clean up expired cache entries
	def cleanup_expired_cache
		cache = get_cache
		expired_keys = []
		
		cache.each do |key, entry|
			if Time.now - entry[:timestamp] > CACHE_DURATION
				expired_keys << key
			end
		end
		
		expired_keys.each { |key| cache.delete(key) }
		
		if expired_keys.length > 0
			puts "Cleaned up #{expired_keys.length} expired cache entries"
		end
	end
	
	# Clear entire cache (useful for debugging or forcing refresh)
	def clear_cache
		initialize_cache
		$PokemonGlobal.pokeapi_cache.clear
		puts "Pokemon API cache cleared"
	end
	
	def get_data(species)
		# Generate cache key for this species
		cache_key = generate_cache_key(species)
		
		# Try to get cached data first
		cached_data = get_cached_data(cache_key)
		if cached_data
			puts "Using cached data for #{cache_key}"
			return cached_data
		end
		
		# Check network connectivity before attempting API call
		unless network_available?
			puts "No internet connection available. Cannot fetch Pokemon data from API."
			return nil
		end
		
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
		parsed_data = parse_data(data, species)
		
		# Cache the successful result
		if parsed_data
			cache_data(cache_key, parsed_data)
			puts "Cached new data for #{cache_key}"
		end
		
		return parsed_data
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