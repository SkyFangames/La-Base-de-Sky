#===============================================================================
# Box Auto-Sort - Event Handler Integration
# Extends existing pbBoxCommands methods of all Storage plugins
#===============================================================================

# Override the pbBoxCommands method for all Storage plugins
EventHandlers.add(:on_game_map_setup, :box_auto_sort_integration,
  proc {
    next if !defined?(PokemonStorageScreen)
    
    # Save the original pbBoxCommands method
    PokemonStorageScreen.class_eval do
      alias_method :original_pbBoxCommands, :pbBoxCommands unless method_defined?(:original_pbBoxCommands)
      
      def pbBoxCommands
        # Create extended commands array
        if defined?(CAN_SWAP_BOXES) && CAN_SWAP_BOXES
          # Storage System Utilities is active - extend its commands
          c_consts = [:JUMP]
          c_consts.push(:SWAP) if defined?(CAN_SWAP_BOXES) && CAN_SWAP_BOXES
          c_consts.push(:SORT, :RELEASE, :WALL, :NAME, :CANCEL)  # Add Sort
          
          commands = [_INTL("Saltar")]
          commands.push(_INTL("Intercambiar")) if defined?(CAN_SWAP_BOXES) && CAN_SWAP_BOXES
          commands.push(
            _INTL("Ordenar Caja"),
            _INTL("Liberar Caja"),
            _INTL("Fondo"),
            _INTL("Nombre"),
            _INTL("Cancelar")
          )
          
          command = pbShowCommands(_INTL("¿Qué quieres hacer?"), commands)
          case c_consts[command]
          when :JUMP
            destbox = @scene.pbChooseBox(_INTL("¿Saltar a qué Caja?"))
            @scene.pbJumpToBox(destbox) if destbox >= 0
          when :SWAP
            if @scene.respond_to?(:pbSwapBoxes)
              destbox = @scene.pbChooseBox(_INTL("¿Intercambiar con qué Caja?"))
              @scene.pbSwapBoxes(destbox) if destbox >= 0
            else
              pbMessage(_INTL("Intercambio no disponible en este sistema de almacenamiento."))
            end
          when :SORT
            # Our Sort feature
            BoxAutoSort.show_sort_menu(@storage, @storage.currentBox)
          when :RELEASE
            pbReleaseBox(@storage.currentBox)
          when :WALL
            papers = @storage.availableWallpapers
            index = 0
            papers[1].length.times do |i|
              if papers[1][i] == @storage[@storage.currentBox].background
                index = i
                break
              end
            end
            wpaper = pbShowCommands(_INTL("Elige el fondo."), papers[0], index)
            @scene.pbChangeBackground(papers[1][wpaper]) if wpaper >= 0
          when :NAME
            @scene.pbBoxName(_INTL("¿Nombre de la Caja?"), 0, 12)
          end
        else
          # Standard Essentials or BW Storage - extend their commands
          commands = [
            _INTL("Saltar"),
            _INTL("Ordenar Caja"),    # Our new command
            _INTL("Fondo"),
            _INTL("Nombre"),
            _INTL("Liberar Caja"),
            _INTL("Cancelar")
          ]
          
          command = pbShowCommands(_INTL("¿Qué quieres hacer?"), commands)
          case command
          when 0  # Jump
            destbox = @scene.pbChooseBox(_INTL("¿Saltar a qué Caja?"))
            @scene.pbJumpToBox(destbox) if destbox >= 0
          when 1  # Sort
            AutoSort.show_sort_dialog(@scene, @storage)
          when 2  # Wallpaper
            papers = @storage.availableWallpapers
            index = 0
            papers[1].length.times do |i|
              if papers[1][i] == @storage[@storage.currentBox].background
                index = i
                break
              end
            end
            wpaper = pbShowCommands(_INTL("¿Qué fondo quieres usar?"), papers[0], index)
            @scene.pbChangeBackground(papers[1][wpaper]) if wpaper >= 0
          when 3  # Name
            @scene.pbBoxName(_INTL("¿Nombre de la Caja?"), 0, 12)
          when 4  # Release
            pbReleaseBox(@storage.currentBox)
          end
        end
      end
    end
  }
) 