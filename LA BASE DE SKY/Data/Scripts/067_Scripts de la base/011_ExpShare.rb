#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#                         Script : Repartir Exp 5.5                             #
#                             Selfish - Público                                 #
#                         Rescrito para Essentials 21 por DPertierra            #
#                         Remember to give Credits!				                #
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#                  Creado para RPG Maker XP con base Essentials                 #
#                          Compatible : versión 21.1                            #
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#

def expshare_enabled?
	return false unless $PokemonGlobal
	$PokemonGlobal.expshare_enabled ||= Settings::EXPSHARE_ENABLED || $player&.has_exp_all || $bag.has?(:EXPSHARE2)
	$PokemonGlobal.expshare_enabled ? true : false
end

class PokemonGlobalMetadata
	attr_accessor :expshare_enabled
	alias initialize_expshare initialize
	def initialize
		initialize_expshare
		@expshare_enabled = Settings::EXPSHARE_ENABLED
	end
end

if Settings::USE_NEW_EXP_SHARE
	class PokemonSystem
		attr_accessor :expshareon
	end

	MenuHandlers.add(:options_menu, :expshareon, {
		"name"        => _INTL("Rep. Exp. al capturar"),
		"order"       => 40,
		"type"        => Settings::USE_NEW_OPTIONS_UI ? :array : EnumOption,
		"condition"   => proc { next expshare_enabled? },
		"parameters"  => proc { [_INTL("Sí"), _INTL("No")] },
		"description" => _INTL("Si quieres que los Pokémon capturados tengan el repartir experiencia activado."),
		"get_proc"    => proc { next $PokemonSystem.expshareon },
		"set_proc"    => proc { |value, _scene| $PokemonSystem.expshareon = value }
	})

    MenuHandlers.add(:party_menu, :expshare, {
		"name"      => _INTL("Repartir Exp."),
		"order"     => 70,
		"condition" => proc { next expshare_enabled? },
		"effect"    => proc { |screen, party, party_idx|
			pokemon = party[party_idx]
			
			txt_individual = pokemon.expshare ? _INTL("Desactivar a {1}", pokemon.name) : _INTL("Activar a {1}", pokemon.name)
			txt_individual_msg = pokemon.expshare ? _INTL("desactivado") : _INTL("activado")
			txt_all_on     = _INTL("Activar a todos")
			txt_all_off    = _INTL("Desactivar a todos")
			txt_cancel     = _INTL("Cancelar")
			commands = []
			cmd_individual = -1
			cmd_all_on     = -1
			cmd_all_off    = -1
			cmd_cancel     = -1

			if !pokemon.egg?
				commands.push(txt_individual)
				cmd_individual = commands.length - 1
			end

			commands.push(txt_all_on)
			cmd_all_on = commands.length - 1
			commands.push(txt_all_off)
			cmd_all_off = commands.length - 1
			commands.push(txt_cancel)
			cmd_cancel = commands.length - 1
			cmd = screen.pbShowCommands(_INTL("¿Qué hacer?"), commands, 0)
			

			if cmd >= 0
				if cmd == cmd_individual
					pokemon.expshare = !pokemon.expshare
					screen.scene.pbRefresh
					screen.pbDisplay( _INTL("Se ha {1} el Repartir Exp. en {2}.", txt_individual_msg, pokemon.name))						
				elsif cmd == cmd_all_on
					party.each do |pkmn| 
						pkmn.expshare = true if !pkmn.egg? 
					end
					screen.scene.pbRefresh
					screen.pbDisplay(_INTL("Se ha activado el Repartir Exp. para todo el equipo."))					
				elsif cmd == cmd_all_off
					party.each { |pkmn| pkmn.expshare = false }
					screen.scene.pbRefresh
					screen.pbDisplay(_INTL("Se ha desactivado el Repartir Exp. para todo el equipo."))
				elsif cmd == cmd_cancel
					# No hace nada (Inserte meme del gato)
				end
			end
			
			next true
		}   
	})

	def toggle_expshare
		$PokemonGlobal.expshare_enabled ||= Settings::EXPSHARE_ENABLED || $player&.has_exp_all || $bag.has?(:EXPSHARE2)
		$PokemonGlobal.expshare_enabled = !$PokemonGlobal.expshare_enabled
		$player.party.each { |pokemon| pokemon.expshare = $PokemonGlobal.expshare_enabled }
	end
	
	class Pokemon
		attr_accessor(:expshare)    # Repartir experiencia
		alias initialize_old initialize
		def initialize(species, level, player = $player, withMoves = true, recheck_form = true)
			initialize_old(species, level, player, withMoves)
			$PokemonSystem.expshareon ||= 0
			@expshare = expshare_enabled? && $PokemonSystem.expshareon == 0
		end 
	end
	
	class PokemonPartyPanel < Sprite
		alias initialize_old initialize
		def initialize(pokemon,index,viewport=nil)
			initialize_old(pokemon,index,viewport)
			if @pokemon.expshare && !@pokemon.egg?
				@expicon = ChangelingSprite.new(0, 0, viewport)
				@expicon.add_bitmap(:expicon,"Graphics/Pictures/expicon")
				@expicon.z=self.z+3 # For compatibility with RGSS2
			end
		end


		alias refresh_overlay_information_old refresh_overlay_information
		def refresh_overlay_information
			refresh_overlay_information_old
			draw_exp_icon
		end

		def draw_exp_icon
			return if !@pokemon.expshare || @pokemon.egg?
			pbDrawImagePositions(@overlaysprite.bitmap, 
			[["Graphics/Pictures/expicon", 226, 70, 0, 0]])
		end

		def refresh_exp_icon
			return if !@expicon || @expicon.disposed?
			@expicon.x=self.x+226
			@expicon.y=self.y+68
			@expicon.color=self.color
		end

		def dispose
			@panelbgsprite.dispose
			@hpbgsprite.dispose
			@ballsprite.dispose
			@pkmnsprite.dispose
			@helditemsprite.dispose
			@overlaysprite.bitmap.dispose
			@overlaysprite.dispose
			@hpbar.dispose
			@statuses.dispose
			@expicon.dispose if @expicon
			super
		end
		
		def refresh
			return if disposed?
			return if @refreshing
			@refreshing = true
			refresh_panel_graphic
			refresh_hp_bar_graphic
			refresh_ball_graphic
			refresh_pokemon_icon
			refresh_held_item_icon
			refresh_exp_icon
			if @overlaysprite && !@overlaysprite.disposed?
			@overlaysprite.x     = self.x
			@overlaysprite.y     = self.y
			@overlaysprite.color = self.color
			end
			refresh_overlay_information
			@refreshBitmap = false
			@refreshing = false
		end

		alias update_old update
		def update
			update_old
			@expicon.update if @expicon 
		end
	end
	
	class Battle 
	################################################################################
	# Experiencia en captura reducida
	################################################################################
		def pbGainExp
			# Play wild victory music if it's the end of the battle (has to be here)
			@scene.pbWildBattleSuccess if wildBattle? && pbAllFainted?(1) && !pbAllFainted?(0)
			return if !@internalBattle || @rules[:no_exp_gain]
			# Go through each battler in turn to find the Pokémon that participated in
			# battle against it, and award those Pokémon Exp/EVs
			expAll = $player.has_exp_all || $bag.has?(:EXPALL)
			p1 = pbParty(0)
			@battlers.each do |b|
				next unless b&.opposes?   # Can only gain Exp from fainted foes
				next if b.participants.length == 0
				next unless b.fainted? || b.captured
				# Count the number of participants
				numPartic = 0
				b.participants.each do |partic|
					next unless p1[partic]&.able? && pbIsOwner?(0, partic)
					numPartic += 1
				end
				# Find which Pokémon have an Exp Share
				expShare = []
				if !expAll
					eachInTeam(0, 0) do |pkmn, i|
						next if !pkmn.able?
						next if !pkmn.hasItem?(:EXPSHARE) && initialItem(0, i) != :EXPSHARE && !pkmn.expshare
						expShare.push(i)
					end
				end
				# Calculate EV and Exp gains for the participants
				if numPartic > 0 || expShare.length > 0 || expAll
				unGroupMessage = !Settings::GROUP_EXP_SHARE_MESSAGE && expShare.length > 0 && expShare.length > b.participants.length ? true : false
				# Gain EVs and Exp for participants
				eachInTeam(0, 0) do |pkmn, i|
					next if !pkmn.able?
					next unless b.participants.include?(i) || expShare.include?(i)
					showMessage = b.participants.include?(i) || unGroupMessage ? true : false
					pbGainEVsOne(i, b)
					pbGainExpOne(i, b, numPartic, expShare, expAll, showMessage)
				end
				if !unGroupMessage && (expShare.length > numPartic && pbParty(0).length > 1)
					pbDisplayPaused(_INTL("¡Tus otros Pokémon también ganaron puntos de experiencia!"))
				end
				# Gain EVs and Exp for all other Pokémon because of Exp All
				if expAll
					showMessage = true
					eachInTeam(0, 0) do |pkmn, i|
						next if !pkmn.able?
						next if b.participants.include?(i) || expShare.include?(i)
						pbDisplayPaused(_INTL("¡Tus otros Pokémon también ganaron puntos de experiencia!")) if showMessage && (expShare.length > numPartic && pbParty(0).length > 1)
						showMessage = false
						pbGainEVsOne(i, b)
						pbGainExpOne(i, b, numPartic, expShare, expAll, false)
					end
				end
			end
			# Clear the participants array
			b.participants = []
			end
		end
	end
end