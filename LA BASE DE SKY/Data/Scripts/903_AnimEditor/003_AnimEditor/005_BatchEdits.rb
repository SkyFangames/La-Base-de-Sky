#===============================================================================
#
#===============================================================================
class AnimationEditor::BatchEdits < UIControls::BaseContainer
  LABEL_X      = 4
  CONTROL_X    = 143
  FIRST_LINE_Y = 0
  LINE_SPACING = 24

  LEFT_RIGHT_BUTTON_WIDTH = 20
  UNDO_BUTTON_WIDTH = 74
  BUTTON_HEIGHT = 20
  BUTTON_SPACING = 4
  BUTTON_Y_OFFSET = (LINE_SPACING - BUTTON_HEIGHT) / 2

  def initialize_controls
    label_width = CONTROL_X - LABEL_X
    ctrl_y = FIRST_LINE_Y
    ctrl_width = @width - CONTROL_X
    # Header
    add_control_at(:header, 0, ctrl_y,
                   UIControls::Label.new(@width, LINE_SPACING, @viewport, _INTL("Ediciones por lote")))
    @controls[:header].header = true
    ctrl_y += LINE_SPACING
    # Undo/redo buttons
    add_control_at(:undo, ((@width - BUTTON_SPACING) / 2) - UNDO_BUTTON_WIDTH, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(UNDO_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "Deshacer"))
    add_control_at(:redo, ((@width + BUTTON_SPACING) / 2), ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(UNDO_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "Rehacer"))
    ctrl_y += LINE_SPACING
    # Time shifts header
    add_control_at(:time_shifts_label, LABEL_X, ctrl_y,
                   UIControls::Label.new(@width, LINE_SPACING, @viewport, _INTL("Desplazamientos de tiempo")))
    get_control(:time_shifts_label).underlined = true
    ctrl_y += LINE_SPACING
    # Shift all particles
    add_control_at(:shift_all_label, LABEL_X, ctrl_y,
                   UIControls::Label.new(label_width, LINE_SPACING, @viewport, _INTL("Todas las partículas")))
    add_control_at(:shift_all_left, CONTROL_X, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "<"))
    add_control_at(:shift_all_right, CONTROL_X + LEFT_RIGHT_BUTTON_WIDTH + BUTTON_SPACING, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, ">"))
    add_control_at(:shift_all_after_left, CONTROL_X + (LEFT_RIGHT_BUTTON_WIDTH + BUTTON_SPACING) * 2, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "|<"))
    add_control_at(:shift_all_after_right, CONTROL_X + (LEFT_RIGHT_BUTTON_WIDTH + BUTTON_SPACING) * 3, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "|>"))
    ctrl_y += LINE_SPACING
    # Shift selected particle
    add_control_at(:shift_one_label, LABEL_X, ctrl_y,
                   UIControls::Label.new(label_width, LINE_SPACING, @viewport, _INTL("Partícula seleccionada")))
    add_control_at(:shift_one_left, CONTROL_X, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "<"))
    add_control_at(:shift_one_right, CONTROL_X + LEFT_RIGHT_BUTTON_WIDTH + BUTTON_SPACING, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, ">"))
    add_control_at(:shift_one_after_left, CONTROL_X + (LEFT_RIGHT_BUTTON_WIDTH + BUTTON_SPACING) * 2, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "|<"))
    add_control_at(:shift_one_after_right, CONTROL_X + (LEFT_RIGHT_BUTTON_WIDTH + BUTTON_SPACING) * 3, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "|>"))
    ctrl_y += LINE_SPACING
    # Shift selected row
    add_control_at(:shift_row_label, LABEL_X, ctrl_y,
                  UIControls::Label.new(label_width, LINE_SPACING, @viewport, _INTL("Fila seleccionada")))
    add_control_at(:shift_row_left, CONTROL_X, ctrl_y + BUTTON_Y_OFFSET,
                  UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "<"))
    add_control_at(:shift_row_right, CONTROL_X + LEFT_RIGHT_BUTTON_WIDTH + BUTTON_SPACING, ctrl_y + BUTTON_Y_OFFSET,
                  UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, ">"))
    add_control_at(:shift_row_after_left, CONTROL_X + (LEFT_RIGHT_BUTTON_WIDTH + BUTTON_SPACING) * 2, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "|<"))
    add_control_at(:shift_row_after_right, CONTROL_X + (LEFT_RIGHT_BUTTON_WIDTH + BUTTON_SPACING) * 3, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(LEFT_RIGHT_BUTTON_WIDTH, BUTTON_HEIGHT, @viewport, "|>"))
    ctrl_y += LINE_SPACING
    # Command values header
    add_control_at(:command_values_label, LABEL_X, ctrl_y,
                  UIControls::Label.new(@width, LINE_SPACING, @viewport, _INTL("Valores de comando")))
    get_control(:command_values_label).underlined = true
    ctrl_y += LINE_SPACING
    # Edit command values button
    add_control_at(:offset_commands, LABEL_X, ctrl_y + BUTTON_Y_OFFSET,
                   UIControls::Button.new(100, BUTTON_HEIGHT, @viewport, _INTL("Aplicar desplazamiento")))
    ctrl_y += LINE_SPACING
  end
end
