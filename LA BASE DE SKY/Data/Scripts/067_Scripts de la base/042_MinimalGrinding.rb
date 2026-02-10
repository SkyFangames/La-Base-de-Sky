class PokemonGlobalMetadata
	attr_accessor :minimal_grinding
	alias initialize_minimal_grinding initialize
	def initialize
		initialize_minimal_grinding
		@minimal_grinding = false
	end
end

module MinimalGrinding
	module_function

	def on?
		return $PokemonGlobal.minimal_grinding ? true : false
	end

	def on
		$PokemonGlobal.minimal_grinding = true
	end

	def off
		$PokemonGlobal.minimal_grinding = false
	end

	def toggle
		if $PokemonGlobal.minimal_grinding
			$PokemonGlobal.minimal_grinding = !$PokemonGlobal.minimal_grinding
		else
			$PokemonGlobal.minimal_grinding = false
		end
	end
end

class Pokemon
	# @return [Integer] the maximum HP of this Pokémon
  alias calcHP_minimal_grinding calcHP
	def calcHP(base, level, iv, ev)
		return calcHP_minimal_grinding(base, level, iv, ev) unless MinimalGrinding.on?
    return 1 if base == 1   # For Shedinja
    iv = ev = 0
    return (((base * 2) + iv + (ev / 4)) * level / 100).floor + level + 10
  end

  # @return [Integer] the specified stat of this Pokémon (not used for total HP)
	alias calcStat_minimal_grinding calcStat
  def calcStat(base, level, iv, ev, nat)
		return calcStat_minimal_grinding(base, level, iv, ev, nat) unless MinimalGrinding.on?
    iv = ev = 0
    return (((((base * 2) + iv + (ev / 4)) * level / 100).floor + 5) * nat / 100).floor
  end
end
