#===============================================================================
#
#===============================================================================
class AnimationEditor
  DEBUG_SETTINGS_FILE_PATH = if File.directory?(System.data_directory)
                               System.data_directory + "debug_settings.rxdata"
                             else
                               "./debug_settings.rxdata"
                             end

  #=============================================================================
  #
  #=============================================================================
  module AnimationEditor::SettingsMixin
    def load_settings
      if File.file?(DEBUG_SETTINGS_FILE_PATH)
        @settings = SaveData.get_data_from_file(DEBUG_SETTINGS_FILE_PATH)[:anim_editor]
      else
        @settings = {
          :color_scheme       => :light,
          :side_sizes         => [1, 1],   # Player's side, opposing side
          :user_index         => 0,        # 0, 2, 4
          :target_indices     => [1],      # There must be at least one valid target
          :user_opposes       => false,
          :canvas_bg          => "indoor1",
          # NOTE: These sprite names are also used in Pokemon.play_cry and so
          #       should be a species ID (being a string is fine).
          :user_sprite_name   => "DRAGONITE",
          :target_sprite_name => "CHARIZARD"
        }
      end
    end

    def save_settings
      data = { :anim_editor => @settings }
      File.open(DEBUG_SETTINGS_FILE_PATH, "wb") { |file| Marshal.dump(data, file) }
    end
  end
end
