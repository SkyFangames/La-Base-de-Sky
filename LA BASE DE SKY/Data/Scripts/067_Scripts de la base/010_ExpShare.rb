#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#                         Script : Repartir Exp 5.5                             #
#                             Selfish - Público                                 #
#                         Remember to give Credits!				                #
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#                  Creado para RPG Maker XP con base Essentials                 #
#                          Compatible : versión 16.2                            #
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
if Settings::USE_NEW_EXP_SHARE
    class PokemonSystem
        attr_accessor :expshareon
    end

    MenuHandlers.add(:options_menu, :expshareon, {
    "name"        => _INTL("Rep Exp al capturar"),
    "order"       => 40,
    "type"        => EnumOption,
    "parameters"  => [_INTL("Sí"), _INTL("No")],
    "description" => _INTL("Si quieres que los Pokémon capturados tengan el repartir experiencia activado."),
    "get_proc"    => proc { next $PokemonSystem.expshareon },
    "set_proc"    => proc { |value, _scene| $PokemonSystem.expshareon = value }
    })



    MenuHandlers.add(:party_menu, :expshare, {
    "name"      => _INTL("Repartir Exp."),
    "order"     => 70,
    "effect"    => proc { |screen, party, party_idx|
        pokemon = party[party_idx]
        if pokemon.expshare
            if pbConfirmMessage(_INTL("¿Quieres desactivar el Repartir Experiencia en este Pokémon?"))
                pokemon.expshare=false
            end
        else
            if pbConfirmMessage(_INTL("¿Quieres activar el Repartir Experiencia en este Pokémon?"))
                pokemon.expshare=true
            end
        end
    }
    })

    # class Trainer
    #     attr_accessor(:expall)        # Mejora el Repartir experiencia
    # end
    
    class Pokemon
        attr_accessor(:expshare)    # Repartir experiencia
        alias initialize_old initialize
        def initialize(species,level,player=$player,withMoves=true, recheck_form = true)
            initialize_old(species, level, player, withMoves)
            @expshare = true if $PokemonSystem.expshareon == 0 || !$PokemonSystem.expshareon
        end 
    end
    
    
    class PokemonPartyPanel < Sprite

        alias initialize_old initialize
        def initialize(pokemon,index,viewport=nil)
            initialize_old(pokemon,index,viewport)
            # @expicon = Sprite.new(viewport)
            if @pokemon.expshare
                @expicon = ChangelingSprite.new(0, 0, viewport)
                @expicon.addBitmap("expicon","Graphics/Pictures/expicon")
                @expicon.z=self.z+3 # For compatibility with RGSS2
            end
        end


        alias refresh_overlay_information_old refresh_overlay_information
        def refresh_overlay_information
            refresh_overlay_information_old
            draw_exp_icon
        end

        def draw_exp_icon
            return if !@pokemon.expshare
            pbDrawImagePositions(@overlaysprite.bitmap, 
            [["Graphics/Pictures/expicon", 226, 70, 0, 0]])
        end

        def refresh_exp_icon
            return if !@expicon || @expicon.disposed? #|| !@expicon.visible
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

    if !MOSTRAR_PANEL_REP_EXP
        class Battle 
        ################################################################################
        # Experiencia en captura reducida
        ################################################################################
            def pbGainExp
                # Play wild victory music if it's the end of the battle (has to be here)
                @scene.pbWildBattleSuccess if wildBattle? && pbAllFainted?(1) && !pbAllFainted?(0)
                return if !@internalBattle || !@expGain
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
                    next if (!pkmn.hasItem?(:EXPSHARE) && GameData::Item.try_get(@initialItems[0][i]) != :EXPSHARE) && !pkmn.expshare
                    expShare.push(i)
                    end
                end
                # Calculate EV and Exp gains for the participants
                if numPartic > 0 || expShare.length > 0 || expAll
                    # Gain EVs and Exp for participants
                    eachInTeam(0, 0) do |pkmn, i|
                    next if !pkmn.able?
                    next unless b.participants.include?(i) || expShare.include?(i) 
                    pbGainEVsOne(i, b)
                    pbGainExpOne(i, b, numPartic, expShare, expAll, !pkmn.shadowPokemon?)
                    end
                    # Gain EVs and Exp for all other Pokémon because of Exp All
                    if expAll
                    showMessage = true
                    eachInTeam(0, 0) do |pkmn, i|
                        next if !pkmn.able?
                        next if b.participants.include?(i) || expShare.include?(i) 
                        pbDisplayPaused(_INTL("¡Tus otros Pokémon también ganaron puntos de experiencia!")) if showMessage
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
end