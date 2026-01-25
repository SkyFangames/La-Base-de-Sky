#===============================================================================
#
#===============================================================================
class AnimationEditor
  def apply_changed_menu_bar_value(property, value)
    case property
    when :quit
      @quit = true
    when :save
      save
    when :help
      # TODO: Show help pop-up window.
    when :name
      edit_animation_properties
      @components[:menu_bar].anim_name = get_animation_display_name
      refresh_component(:timeline)
    when :settings
      edit_editor_settings
    end
  end

  def apply_changed_battlers_layout_value(property, value)
    case property
    when :side_size_1
      old_val = @settings[:side_sizes][0]
      @settings[:side_sizes][0] = value
      if @settings[:user_index] >= value * 2
        @settings[:user_index] = (value - 1) * 2
        @components[:battlers_layout].get_control(:user_index).value = @settings[:user_index]
        @settings[:target_indices].delete_if { |val| val == @settings[:user_index] }
      end
      @settings[:target_indices].delete_if { |val| val.even? && val >= value * 2 }
      @settings[:target_indices].push(1) if @settings[:target_indices].empty?
      @components[:battlers_layout].get_control(:target_indices).value = @settings[:target_indices].join(",")
    when :side_size_2
      old_val = @settings[:side_sizes][1]
      @settings[:side_sizes][1] = value
      @settings[:target_indices].delete_if { |val| val == @settings[:user_index] }
      @settings[:target_indices].delete_if { |val| val.odd? && val >= value * 2 }
      @settings[:target_indices].push(1) if @settings[:target_indices].empty?
      @components[:battlers_layout].get_control(:target_indices).value = @settings[:target_indices].join(",")
    when :user_index
      @settings[:user_index] = value
      @settings[:target_indices].delete_if { |val| val == @settings[:user_index] }
      @settings[:target_indices].push(1) if @settings[:target_indices].empty?
      @components[:battlers_layout].get_control(:target_indices).value = @settings[:target_indices].join(",")
    when :target_indices
      @settings[:target_indices] = value.split(",")
      @settings[:target_indices].map! { |val| val.to_i }
      @settings[:target_indices].sort!
      @settings[:target_indices].uniq!
      @settings[:target_indices].delete_if { |val| val == @settings[:user_index] }
      @settings[:target_indices].delete_if { |val| val.even? && val >= @settings[:side_sizes][0] * 2 }
      @settings[:target_indices].delete_if { |val| val.odd? && val >= @settings[:side_sizes][1] * 2 }
      @settings[:target_indices].push(1) if @settings[:target_indices].empty?
      @components[:battlers_layout].get_control(:target_indices).value = @settings[:target_indices].join(",")
    else
      @settings[property] = value
    end
    save_settings
    refresh_component(:battlers_layout)
    refresh_component(:canvas)
  end

  def apply_changed_play_controls_value(property, value)
    case property
    when :play
      @ready_to_play = true
    end
  end

  def apply_changed_canvas_value(property, value)
    case property
    when :particle_index
      @components[:timeline].particle_index = value
      refresh
    when :x, :y
      particle = @anim[:particles][particle_index]
      before_all = particle[property] && particle[property].none? { |cmd| cmd[0] <= keyframe }
      after_all = particle[property] && particle[property].none? { |cmd| cmd[0] + cmd[1] >= keyframe }
      new_cmds = AnimationEditor::ParticleDataHelper.add_command(particle, property, keyframe, value)
      if new_cmds
        particle[property] = new_cmds
        if GameData::Animation.property_can_interpolate?(property)
          if before_all
            AnimationEditor::ParticleDataHelper.set_interpolation(
              particle, property, keyframe, @settings[:default_interpolation] || :linear
            )
          elsif after_all
            AnimationEditor::ParticleDataHelper.set_interpolation(
              particle, property, keyframe - 1, @settings[:default_interpolation] || :linear
            )
          end
        end
      else
        particle.delete(property)
      end
      @components[:timeline].change_particle_commands(particle_index)
      refresh_component(:timeline)
      refresh_component(:canvas)
    end
  end

  def apply_changed_timeline_value(property, value)
    case property
    when :add_particle
      new_idx = particle_index + 1
      AnimationEditor::ParticleDataHelper.add_particle(@anim[:particles], new_idx)
      @components[:timeline].add_particle(new_idx)
      @components[:timeline].particle_index = new_idx
      refresh
    when :move_particle_up
      idx1 = particle_index
      idx2 = idx1 - 1
      AnimationEditor::ParticleDataHelper.swap_particles(@anim[:particles], idx1, idx2)
      @components[:timeline].swap_particles(idx1, idx2)
      @components[:timeline].particle_index = idx2
      refresh
    when :move_particle_down
      idx1 = particle_index
      idx2 = idx1 + 1
      AnimationEditor::ParticleDataHelper.swap_particles(@anim[:particles], idx1, idx2)
      @components[:timeline].swap_particles(idx1, idx2)
      @components[:timeline].particle_index = idx2
      refresh
    when :main   # Particle properties
      if @anim[:particles][value[0]][:name] == "SE"
        # NOTE: value is actually [particle index, [button ID, index of SE]].
        #       Keyframe is the currently selected keyframe.
        case value[1][0]
        when :add
          new_filename, new_volume, new_pitch = choose_audio_file("", 100, 100)
          if new_filename != ""
            particle = @anim[:particles][value[0]]
            AnimationEditor::ParticleDataHelper.add_se_command(particle, keyframe, new_filename, new_volume, new_pitch)
            @components[:timeline].change_particle_commands(value[0])
            @components[:play_controls].duration = @components[:timeline].duration
          end
        when :edit
          particle = @anim[:particles][value[0]]
          list = AnimationEditor::ParticleDataHelper.get_all_particle_se_at_frame(particle, keyframe)
          old_file = list[value[1][1]]
          if old_file
            case old_file[0]
            when :user_cry, :target_cry
              old_filename = (old_file[0] == :user_cry) ? "USER" : "TARGET"
              old_volume = old_file[3] || 100
              old_pitch = old_file[4] || 100
            when :se
              old_filename = old_file[3]
              old_volume = old_file[4] || 100
              old_pitch = old_file[5] || 100
            end
            new_filename, new_volume, new_pitch = choose_audio_file(old_filename, old_volume, old_pitch)
            if new_filename != old_filename || new_volume != old_volume || new_pitch != old_pitch
              AnimationEditor::ParticleDataHelper.delete_se_command(particle, keyframe, old_filename)
              AnimationEditor::ParticleDataHelper.add_se_command(particle, keyframe, new_filename, new_volume, new_pitch)
              @components[:timeline].change_particle_commands(value[0])
            end
          end
        when :delete
          particle = @anim[:particles][value[0]]
          list = AnimationEditor::ParticleDataHelper.get_all_particle_se_at_frame(particle, keyframe)
          old_file = list[value[1][1]]
          if old_file
            case old_file[0]
            when :user_cry, :target_cry
              old_filename = (old_file[0] == :user_cry) ? "USER" : "TARGET"
            when :se
              old_filename = old_file[3]
            end
            AnimationEditor::ParticleDataHelper.delete_se_command(particle, keyframe, old_filename)
            @components[:timeline].change_particle_commands(value[0])
            @components[:play_controls].duration = @components[:timeline].duration
          end
        end
      else
        # NOTE: value is actually [particle_index, value].
        edit_particle_properties(value[0])
      end
    when :move_command
      # NOTE: value is actually [particle_index, [property, src_keyframe, dst_keyframe]].
      part_idx = value[0]
      prop = value[1][0]
      src_keyframe = value[1][1]
      dst_keyframe = value[1][2]
      if prop == :main   # SE
        [:se, :user_cry, :target_cry].each do |se_prop|
          AnimationEditor::ParticleDataHelper.move_command(
            @anim[:particles][part_idx], se_prop, src_keyframe, dst_keyframe
          )
        end
      else
        AnimationEditor::ParticleDataHelper.move_command(
          @anim[:particles][part_idx], prop, src_keyframe, dst_keyframe
        )
      end
      @components[:timeline].change_particle_commands(part_idx)
      refresh_component(:canvas)
      @components[:play_controls].duration = @components[:timeline].duration
    else
      if GameData::Animation::INTERPOLATION_TYPES.any? { |name, id| id == property }
        # Change interpolation
        # NOTE: value is actually [particle index, [property, keyframe]].
        part_idx = value[0]
        prop = value[1][0]
        clicked_keyframe = value[1][1]
        interp_type = property
        # Set the new interpolation type
        AnimationEditor::ParticleDataHelper.set_interpolation(
          @anim[:particles][part_idx], prop, clicked_keyframe, interp_type
        )
        @components[:timeline].change_particle_commands(part_idx)
        refresh_component(:canvas)
      else
        # NOTE: value is actually [particle_index, value].
        particle = @anim[:particles][value[0]]
        before_all = particle[property] && particle[property].none? { |cmd| cmd[0] <= keyframe }
        after_all = particle[property] && particle[property].none? { |cmd| cmd[0] + cmd[1] >= keyframe }
        new_cmds = AnimationEditor::ParticleDataHelper.add_command(particle, property, keyframe, value[1])
        if new_cmds
          particle[property] = new_cmds
          if GameData::Animation.property_can_interpolate?(property)
            if before_all
              AnimationEditor::ParticleDataHelper.set_interpolation(
                particle, property, keyframe, @settings[:default_interpolation] || :linear
              )
            elsif after_all
              AnimationEditor::ParticleDataHelper.set_interpolation(
                particle, property, keyframe - 1, @settings[:default_interpolation] || :linear
              )
            end
          end
        else
          particle.delete(property)
        end
        @components[:timeline].change_particle_commands(value[0])
        refresh_component(:canvas)
        @components[:play_controls].duration = @components[:timeline].duration
      end
    end
  end

  def apply_changed_editor_settings_value(property, value)
    case property
    when :color_scheme
      @settings[:color_scheme] = value
      self.color_scheme = value
    else
      @settings[property] = value
    end
    save_settings
    refresh_component(:canvas)
  end

  def apply_changed_animation_properties_value(property, value)
    case property
    when :type, :opp_variant
      type = @components[:animation_properties].get_control(:type).value
      opp = @components[:animation_properties].get_control(:opp_variant).value
      case type
      when :move
        @anim[:type] = (opp) ? :opp_move : :move
      when :common
        @anim[:type] = (opp) ? :opp_common : :common
      end
      refresh_component(:animation_properties)
      refresh_component(:canvas)
    when :pbs_path
      txt = value.gsub!(/\.txt$/, "")
      @anim[property] = txt
    when :has_user
      @anim[:no_user] = !value
      if @anim[:no_user]
        user_idx = @anim[:particles].index { |particle| particle[:name] == "User" }
        @anim[:particles].delete_if { |particle| particle[:name] == "User" }
        @anim[:particles].each do |particle|
          if ["USER", "USER_OPP", "USER_FRONT", "USER_BACK"].include?(particle[:graphic])
            particle[:graphic] = GameData::Animation::PARTICLE_DEFAULT_VALUES[:graphic]
          end
          if GameData::Animation::FOCUS_TYPES_WITH_USER.include?(particle[:focus])
            particle[:focus] = GameData::Animation::PARTICLE_DEFAULT_VALUES[:focus]
          end
          particle[:user_cry] = nil if particle[:name] == "SE"
        end
        @components[:timeline].delete_particle(user_idx)
      elsif @anim[:particles].none? { |particle| particle[:name] == "User" }
        @anim[:particles].insert(0, {
          :name => "User", :focus => :user, :graphic => "USER"
        })
        @components[:timeline].add_particle(0)
      end
      refresh
    when :has_target
      @anim[:no_target] = !value
      if @anim[:no_target]
        target_idx = @anim[:particles].index { |particle| particle[:name] == "Target" }
        @anim[:particles].delete_if { |particle| particle[:name] == "Target" }
        @anim[:particles].each do |particle|
          if ["TARGET", "TARGET_OPP", "TARGET_FRONT", "TARGET_BACK"].include?(particle[:graphic])
            particle[:graphic] = GameData::Animation::PARTICLE_DEFAULT_VALUES[:graphic]
          end
          if GameData::Animation::FOCUS_TYPES_WITH_TARGET.include?(particle[:focus])
            particle[:focus] = GameData::Animation::PARTICLE_DEFAULT_VALUES[:focus]
          end
          particle[:target_cry] = nil if particle[:name] == "SE"
        end
        @components[:timeline].delete_particle(target_idx)
      elsif @anim[:particles].none? { |particle| particle[:name] == "Target" }
        @anim[:particles].insert(0, {
          :name => "Target", :focus => :target, :graphic => "TARGET"
        })
        @components[:timeline].add_particle(0)
      end
      refresh
    when :usable
      @anim[:ignore] = !value
    else
      @anim[property] = value
    end
  end

  def apply_changed_particle_properties_value(property, value)
    idx_particle = (value.is_a?(Array)) ? value[0] : particle_index
    value = value[1] if value.is_a?(Array)
    case property
    when :graphic
      this_particle = @anim[:particles][idx_particle]
      new_file = choose_graphic_file(this_particle[:graphic])
      if this_particle[:graphic] != new_file
        this_particle[:graphic] = new_file
        # TODO: Ideally enable/disable the :frame row's control for this
        #       particle depending on whether the graphic is a spritesheet (i.e.
        #       isn't one of the below special names and is wide enough compared
        #       to its height). Also this_particle.delete(:frame) if the graphic
        #       isn't a spritesheet.
        if ["USER", "USER_OPP", "USER_BACK", "USER_FRONT",
            "TARGET", "TARGET_OPP" "TARGET_FRONT", "TARGET_BACK",].include?(new_file)
          this_particle.delete(:frame)
          @components[:timeline].set_particles(@anim[:particles])
          refresh_component(:timeline)
        end
        refresh_component(:particle_properties, idx_particle)
        refresh_component(:canvas)
      end
    when :spawn_quantity
      new_cmds = AnimationEditor::ParticleDataHelper.set_property(
        @anim[:particles][idx_particle], property, value
      )
      @components[:timeline].change_particle_commands(idx_particle)
      @components[:play_controls].duration = @components[:timeline].duration
      refresh
    when :duplicate
      p_index = idx_particle
      AnimationEditor::ParticleDataHelper.duplicate_particle(@anim[:particles], p_index)
      @components[:timeline].add_particle(p_index + 1)
      @components[:timeline].particle_index = p_index + 1
      refresh
    when :delete
      if confirm_message(_INTL("¿Estás seguro de que deseas eliminar esta partícula?"))
        p_index = idx_particle
        AnimationEditor::ParticleDataHelper.delete_particle(@anim[:particles], p_index)
        @components[:timeline].delete_particle(p_index)
        refresh
      end
    else
      # TODO: If any of these change, does anything special need to be done
      #       relating to values or other controls?
              # when :name
              # when :graphic_name
              # when :focus
              # when :random_frame_max
              # when :spawner
              # when :angle_override
              # when :foe_invert_x
              # when :foe_invert_y
              # when :foe_flip
      @anim[:particles][idx_particle][property] = value
      refresh_component(:particle_properties, idx_particle)
      refresh_component(:canvas)
      refresh_component(:timeline)   # If focus changes
    end
  end

  def apply_changed_value(component_sym, property, value)
    case component_sym
    when :menu_bar             then apply_changed_menu_bar_value(property, value)
    when :battlers_layout      then apply_changed_battlers_layout_value(property, value)
    when :play_controls        then apply_changed_play_controls_value(property, value)
    when :canvas               then apply_changed_canvas_value(property, value)
    when :timeline             then apply_changed_timeline_value(property, value)
    when :editor_settings      then apply_changed_editor_settings_value(property, value)
    when :animation_properties then apply_changed_animation_properties_value(property, value)
    when :particle_properties  then apply_changed_particle_properties_value(property, value)
    end
  end
end
