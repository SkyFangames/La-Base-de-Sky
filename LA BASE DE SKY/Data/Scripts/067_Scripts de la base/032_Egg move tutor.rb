# Tutor de Movimientos Huevo
# por Skyflyer
# Para ver su uso, mira el NPC de ejemplo del mapa 12 (Condiminio Lugano).


class Pokemon
  def get_egg_moves_full
    especie = self.species_data
    return especie.egg_moves if !especie.egg_moves.empty?
    prevo = especie.get_previous_species
    return GameData::Species.get_species_form(prevo, especie.form).get_egg_moves if prevo != especie.species
    return especie.egg_moves
  end

  def can_learn_egg_move?
    return false if egg? || shadowPokemon?
    return !get_egg_moves_full.empty?
  end
end

#===============================================================================
# Custom visuals for Egg Move Tutor (extends Move Reminder visuals)
#===============================================================================
class UI::EggMoveTutorVisuals < UI::MoveReminderVisuals
  # Override header text for egg move tutor
  def draw_header
    draw_text(_INTL("¿Enseñar qué movimiento huevo?"), HEADER_X, HEADER_Y, theme: :header)
  end

  # Override to not show level/TM/HM labels for egg moves
  def draw_move_in_list(move, x, y)
    move_data = GameData::Move.get(move[0])

    # Draw move type icon
    type_number = GameData::Type.get(move_data.display_type(@pokemon)).icon_position
    draw_image(@bitmaps[:types], x + TYPE_ICON_X_OFFSET, y + TYPE_ICON_Y_OFFSET,
                0, type_number * GameData::Type::ICON_SIZE[1], *GameData::Type::ICON_SIZE)

    # Draw move name
    move_name = move_data.name
    move_name = crop_text(move_name, MOVE_NAME_WIDTH)
    draw_text(move_name, x + MOVE_NAME_X_OFFSET, y + MOVE_NAME_Y_OFFSET)

    # Don't draw level or TM/HM text for egg moves (unlike parent class)

    # Draw PP text
    if move_data.total_pp > 0
      draw_text(_INTL("PP"), x + PP_LABEL_X_OFFSET, y + PP_LABEL_Y_OFFSET, theme: :black)
      draw_text(sprintf("%d/%d", move_data.total_pp, move_data.total_pp), x + PP_VALUE_X_OFFSET, y + PP_VALUE_Y_OFFSET, align: :right, theme: :black)
    end
  end
end

#===============================================================================
# Egg Move Tutor screen (extends Move Reminder screen)
#===============================================================================
class UI::EggMoveTutor < UI::MoveReminder
  attr_reader :required_item
  
  SCREEN_ID = :egg_move_tutor_screen

  def initialize(pokemon, mode: :normal, required_item: nil)
    @required_item = required_item
    super(pokemon, mode: mode)
  end

  def initialize_visuals
    @visuals = UI::EggMoveTutorVisuals.new(@pokemon, @moves)
  end

  # Override to generate egg moves instead of level-up moves
  def generate_move_list
    @moves = []
    return if !@pokemon || @pokemon.egg? || @pokemon.shadowPokemon?
    
    egg_moves = @pokemon.get_egg_moves_full
    egg_moves.each do |move|
      next if @pokemon.hasMove?(move)
      @moves << [move, nil]  # nil for the second element since egg moves don't have level/TM labels
    end
    
    @moves = @moves.uniq { |move| move[0] }  # Remove duplicates based on move ID
  end

  # Override the quit message to be specific to egg moves
  def main
    return if @disposed
    start_screen
    @visuals.refresh if @visuals
    Graphics.update
    loop do
      on_start_main_loop
      command = @visuals.navigate
      break if command == :quit && (@mode == :normal ||
               show_confirm_message(_INTL("¿Dejar de enseñarle un movimiento a {1}?", @pokemon.name)))
      perform_action(command)
      if @moves.empty?
        show_message(_INTL("No hay más movimientos huevo para que {1} aprenda.", @pokemon.name))
        break
      end
      if @disposed
        @result = true
        break
      end
    end
    end_screen
    return @result
  end
end

#===============================================================================
# Main function to open the Egg Move Tutor screen
#===============================================================================
def pbLearnEggMoveScreen(pkmn, required_item = nil)
  ret = true
  pbFadeOutIn do
    mode = Settings::CLOSE_MOVE_RELEARNER_AFTER_TEACHING_MOVE ? :single : :normal
    egg_move_tutor = UI::EggMoveTutor.new(pkmn, mode: mode, required_item: required_item)
    ret = egg_move_tutor.main
    egg_move_tutor.show_consumed_items_message
  end
  return ret
end
  