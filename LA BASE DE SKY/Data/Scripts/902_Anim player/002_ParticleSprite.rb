#===============================================================================
# NOTE: This assumes that processes are added (for a given property) in the
#       order they happen.
#===============================================================================
class AnimationPlayer::ParticleSprite
  attr_reader   :sprite
  attr_accessor :focus_xy, :offset_xy, :focus_z
  attr_reader   :property_offsets
  attr_accessor :angle_override, :random_invert_angle, :random_invert_flip
  attr_accessor :foe_invert_x, :foe_invert_y, :foe_flip
  attr_accessor :slowdown
  # Used by particles from emitter
  attr_reader   :emitter_params

  def initialize
    @property_offsets = {}
    @processes = []
    @sprite = nil
    @is_battler_sprite = false
    @emitter_params = {:type => :none, :start_time => 0}
    @slowdown = 1
    initialize_values
  end

  def initialize_values
    @values = GameData::Animation::PARTICLE_KEYFRAME_DEFAULT_VALUES.clone
  end

  def dispose
    return if is_battler_sprite? || !@sprite || @sprite.disposed?
    @sprite.bitmap&.dispose
    @sprite.dispose
  end

  #-----------------------------------------------------------------------------

  # NOTE: is_battler_sprite is needed because sprite.is_a?(Battle::Scene::BattlerSprite)
  #       won't work in the Animation Editor, where battler sprites are just
  #       Sprites.
  def set_sprite(sprite, is_battler = false)
    @sprite = sprite
    set_as_battler_sprite if is_battler
  end

  def set_as_battler_sprite
    @is_battler_sprite = true
    @values[:visible] = true
  end

  def is_battler_sprite?
    return @is_battler_sprite
  end

  #-----------------------------------------------------------------------------

  # :angle => value is particle[:angle_override] from GameData::Animation::ANGLE_OVERRIDES.
  def set_base_property_offset(property, value)
    case property
    when :angle
      @angle_override = value || :none   # Only used for :always_point_at_focus
    else
      @property_offsets[property] = value
    end
  end

  #-----------------------------------------------------------------------------

  # start_time is in seconds.
  def add_set_process(property, start_time, value)
    add_move_process(property, start_time, 0, value, :none)
  end

  # start_time and duration are in seconds.
  def add_move_process(property, start_time, duration, value, interpolation = :linear)
    # First nil is progress (nil = not started, true = running, false = finished)
    # Second nil is start value (set when the process starts running)
    @processes.push([property, start_time, duration, value, interpolation, nil, nil])
  end

  def delete_processes(property)
    @processes.delete_if { |process| process[0] == property }
  end

  # Sets sprite's initial For looping purposes.
  def reset_processes
    initialize_values
    set_as_battler_sprite if is_battler_sprite?   # Start battler sprites as visible
    @values.each_pair { |property, value| apply_sprite_property(property, value) }
    @processes.each { |process| process[5] = nil }
  end

  #-----------------------------------------------------------------------------

  def start_process(process)
    return if !process[5].nil?
    process[6] = @values[process[0]]
    process[5] = true
  end

  def update_process_value(process, elapsed_time)
    # SetXYZ
    if process[2] == 0
      @values[process[0]] = process[3]
      process[5] = false   # Mark process as finished
      return
    end
    # MoveXYZ
    case process[0]
    when :color
      new_val = []
      4.times do |i|   # R, G, B, A
        start_val = process[6][2 * i, 2].to_i(16)
        end_val = process[3][2 * i, 2].to_i(16)
        val = AnimationPlayer::Helper.interpolate(
          process[4], start_val, end_val, process[2],
          process[1], elapsed_time
        )
        new_val.push(sprintf("%02X", val))
      end
      @values[process[0]] = new_val.join
    when :tone
      new_val = []
      4.times do |i|   # R, G, B, G
        start_val = process[6][3 * i, 3].to_i(16)
        end_val = process[3][3 * i, 3].to_i(16)
        val = AnimationPlayer::Helper.interpolate(
          process[4], start_val, end_val, process[2],
          process[1], elapsed_time
        )
        new_val.push((val >= 0 ? "+" : "-") + sprintf("%02X", val.abs))
      end
      @values[process[0]] = new_val.join
    else
      @values[process[0]] = AnimationPlayer::Helper.interpolate(
        process[4], process[6], process[3], process[2],
        process[1], elapsed_time
      )
    end
    # Mark process as finished (if it has)
    process[5] = false if elapsed_time >= process[1] + process[2]
  end

  # Usually only :x and :y.
  def update_emitter_type_properties(elapsed_time, changed_properties)
    return if (@emitter_params[:type] || :none) == :none
    delta_t = (elapsed_time - @emitter_params[:start_time]) / @slowdown.to_f
    case (@emitter_params[:type] || :none)
    when :no_movement
      # NOTE: This doesn't change any properties.
    when :straight
      new_x = (@emitter_params[:speed_x] * delta_t).round
      @values[:x] = new_x
      changed_properties.push(:x)
      new_y = (@emitter_params[:speed_y] * delta_t).round
      @values[:y] = new_y
      changed_properties.push(:y)
    when :projectile
      new_x = (@emitter_params[:speed_x] * delta_t).round
      @values[:x] = new_x
      changed_properties.push(:x)
      new_y = ((@emitter_params[:speed_y] * delta_t) + (@emitter_params[:gravity] * delta_t * delta_t / 2)).round   # s = ut + 1/2 at^2
      @values[:y] = new_y
      changed_properties.push(:y)
    when :helix
      new_angle = @emitter_params[:angle] + (360 * delta_t / @emitter_params[:period])
      new_x = @emitter_params[:radius] * Math.sin(new_angle * Math::PI / 180)
      @values[:x] = new_x
      changed_properties.push(:x)
      new_y = (@emitter_params[:speed] * delta_t).round
      @values[:y] = new_y
      changed_properties.push(:y)
      new_z = @emitter_params[:radius_z] * Math.cos(new_angle * Math::PI / 180)
      @values[:z] = new_z
      changed_properties.push(:z)
    end
  end

  def update_sprite(changed_properties)
    changed_properties.uniq!
    changed_properties.each do |property|
      apply_sprite_property(property, @values[property])
    end
  end

  def apply_sprite_property(property, value)
    if !@sprite
      pbSEPlay(*value) if [:se, :user_cry, :target_cry].include?(property) && value
      return
    end
    case property
    when :frame
      value += (@property_offsets[property] || 0)
      @sprite.src_rect.x = value.floor * @sprite.src_rect.width
    when :blending
      @sprite.blend_type = value
    when :flip
      @sprite.mirror = value
      @sprite.mirror = !@sprite.mirror if @foe_flip
      @sprite.mirror = !@sprite.mirror if @random_invert_flip
    when :x
      value = value.round + (@property_offsets[property] || 0)
      value *= -1 if @foe_invert_x
      AnimationPlayer::Helper.apply_xy_focus_to_sprite(@sprite, :x, value, @focus_xy)
      @sprite.x += @offset_xy[0]
      apply_sprite_property_override(:angle)
    when :y
      value = value.round + (@property_offsets[property] || 0)
      value *= -1 if @foe_invert_y
      AnimationPlayer::Helper.apply_xy_focus_to_sprite(@sprite, :y, value, @focus_xy)
      @sprite.y += @offset_xy[1]
      apply_sprite_property_override(:angle)
    when :z
      value += (@property_offsets[property] || 0)
      AnimationPlayer::Helper.apply_z_focus_to_sprite(@sprite, value, @focus_z)
    when :zoom_x
      value += (@property_offsets[property] || 0)
      @sprite.zoom_x = value / 100.0
    when :zoom_y
      value += (@property_offsets[property] || 0)
      @sprite.zoom_y = value / 100.0
    when :angle
      if @angle_override == :always_point_at_focus
        apply_sprite_property_override(:angle)
        @sprite.angle += value
      else
        @sprite.angle = value + (@property_offsets[property] || 0)
      end
      @sprite.angle *= -1 if @random_invert_angle
    when :visible
      @sprite.visible = value
    when :opacity
      @sprite.opacity = value + (@property_offsets[property] || 0)
    when :color
      @sprite.color = Color.new_from_rgb(value)
    when :tone
      @sprite.tone = Tone.new_from_rgbg(value)
    end
  end

  def apply_sprite_property_override(property)
    case property
    when :angle
      # NOTE: This assumes vertically up is an angle of 0, and the angle
      #       increases anticlockwise.
      return if @angle_override != :always_point_at_focus
      # Get coordinates
      sprite_x = @sprite.x
      sprite_y = @sprite.y
      target_x = (@focus_xy.length == 2) ? @focus_xy[1][0] : @focus_xy[0][0]
      target_x += @offset_xy[0]
      target_y = (@focus_xy.length == 2) ? @focus_xy[1][1] : @focus_xy[0][1]
      target_y += @offset_xy[1]
      # Recalculate angle
      @sprite.angle = AnimationPlayer::Helper.angle_between(sprite_x, sprite_y, target_x, target_y)
      @sprite.angle += (@property_offsets[property] || 0)
    end
  end

  # elapsed_time is in seconds since the start of the animation.
  def update(elapsed_time)
    changed_properties = []
    @processes.each do |process|
      next if process[1] > elapsed_time   # Not due to start yet
      next if process[5] == false   # Process has already fully happened
      start_process(process)
      update_process_value(process, elapsed_time)
      changed_properties.push(process[0])   # Record property as having changed
    end
    # Update constantly recalculated values, i.e. x/y for emitted sprites
    update_emitter_type_properties(elapsed_time, changed_properties)
    # Apply changed values to sprite
    update_sprite(changed_properties) if !changed_properties.empty?
  end
end
