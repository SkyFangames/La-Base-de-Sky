#===============================================================================
#
#===============================================================================
class AnimationEditor::BattlersLayout < UIControls::BaseContainer
  LABEL_X      = 4
  CONTROL_X    = 143
  FIRST_LINE_Y = 0
  LINE_SPACING = 24

  def initialize_controls
    label_width = CONTROL_X - LABEL_X
    ctrl_y = FIRST_LINE_Y
    ctrl_width = @width - CONTROL_X
    # Header
    add_control_at(:header, 0, ctrl_y,
                   UIControls::Label.new(@width, LINE_SPACING, @viewport, _INTL("Battler positions")))
    @controls[:header].header = true
    ctrl_y += LINE_SPACING
    # Side sizes
    add_control_at(:side_size_label, LABEL_X, ctrl_y,
                   UIControls::Label.new(label_width, LINE_SPACING, @viewport, _INTL("Side sizes")))
    add_control_at(:side_size_1, CONTROL_X, ctrl_y,
                   UIControls::DropdownList.new(38, LINE_SPACING, @viewport, {
                     1 => "1",
                     2 => "2",
                     3 => "3"
                   }, 1))
    add_control_at(:side_size_vs_label, CONTROL_X + 39, ctrl_y,
                   UIControls::Label.new(24, LINE_SPACING, @viewport, _INTL("vs.")))
    add_control_at(:side_size_2, CONTROL_X + 67, ctrl_y,
                   UIControls::DropdownList.new(38, LINE_SPACING, @viewport, {
                     1 => "1",
                     2 => "2",
                     3 => "3"
                   }, 1))
    ctrl_y += LINE_SPACING
    # User index
    # TODO: I want a better control for this to choose where the user is. This
    #       will incorporate the "User is opposing?" control below. Upon
    #       changing the index, update the target indices control's blacklist
    #       index.
    add_control_at(:user_index_label, LABEL_X, ctrl_y,
                   UIControls::Label.new(label_width, LINE_SPACING, @viewport, _INTL("User index")))
    add_control_at(:user_index, CONTROL_X, ctrl_y,
                   UIControls::DropdownList.new(38, LINE_SPACING, @viewport, {
                     1 => "1",
                     2 => "2",
                     3 => "3"
                   }, 1))
    ctrl_y += LINE_SPACING
    # Target indices
    # TODO: I want a better control for this to choose where the targets are.
    #       Includes a blacklist index (for the user) which can be changed. If
    #       it is changed, swap the booleans for the old and new blacklist
    #       indices.
    add_control_at(:target_indices_label, LABEL_X, ctrl_y,
                   UIControls::Label.new(label_width, LINE_SPACING, @viewport, _INTL("Target indices")))
    add_control_at(:target_indices, CONTROL_X, ctrl_y,
                   UIControls::TextBox.new(105, LINE_SPACING, @viewport, ""))
    ctrl_y += LINE_SPACING
    # User opposes
    add_control_at(:user_opposes_label, LABEL_X, ctrl_y,
                   UIControls::Label.new(label_width, LINE_SPACING, @viewport, _INTL("User is opposing?")))
    add_control_at(:user_opposes, CONTROL_X, ctrl_y,
                   UIControls::Checkbox.new(40, LINE_SPACING, @viewport, false))
  end
end
