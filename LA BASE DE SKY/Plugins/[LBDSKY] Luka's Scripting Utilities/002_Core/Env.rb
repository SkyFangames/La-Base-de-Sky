#===============================================================================
#  Environment module for easy Win directory manipulation
#===============================================================================
module ::Env
  class << self
    #---------------------------------------------------------------------------
    #  constant containing GUIDs found on MSDN for common directories
    #---------------------------------------------------------------------------
    COMMON_PATHS = {
      'CAMERA_ROLL'       => 'AB5FB87B-7CE2-4F83-915D-550846C9537B',
      'START_MENU'        => 'A4115719-D62E-491D-AA7C-E74B8BE3B067',
      'DESKTOP'           => 'B4BFCC3A-DB2C-424C-B029-7FE99A87C641',
      'DOCUMENTS'         => 'FDD39AD0-238F-46AF-ADB4-6C85480369C7',
      'DOWNLOADS'         => '374DE290-123F-4565-9164-39C4925E467B',
      'HOME'              => '5E6C858F-0E22-4760-9AFE-EA3317B67173',
      'MUSIC'             => '4BD8D571-6D19-48D3-BE97-422220080E43',
      'PICTURES'          => '33E28130-4E1E-4676-835A-98395C3BC3BB',
      'SAVED_GAMES'       => '4C5C32FF-BB9D-43b0-B5B4-2D72E54EAAA4',
      'SCREENSHOTS'       => 'b7bede81-df94-4682-a7d8-57a52620b86f',
      'VIDEOS'            => '18989B1D-99B5-455B-841C-AB7C74E4DDFC',
      'LOCAL'             => 'F1B32785-6FBA-4FCF-9D55-7B8E7F157091',
      'LOCALLOW'          => 'A520A1A4-1780-4FF6-BD18-167343C5AF16',
      'ROAMING'           => '3EB685DB-65F9-4CF6-A03A-E3EF65729F3D',
      'PROGRAM_DATA'      => '62AB5D82-FDC1-4DC3-A9DD-070D1D495D97',
      'PROGRAM_FILES_X64' => '6D809377-6AF0-444b-8957-A3773F02200E',
      'PROGRAM_FILES_X86' => '7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E',
      'COMMON_FILES'      => 'F7F1ED05-9F6D-47A2-AAAE-29D317C6F066',
      'PUBLIC'            => 'DFDF76A2-C82A-4D63-906A-5644AC457385'
    }
    #---------------------------------------------------------------------------
    #  escape chars for Directories
    #---------------------------------------------------------------------------
    @char_set = {
      '\\' => '&bs;', '/' => '&fs;', ':' => '&cn;', '*' => '&as;',
      '?' => '&qm;', '\'' => '&dq;', '<' => '&lt;', '>' => '&gt;',
      '|' => '&po;'
    }
    #---------------------------------------------------------------------------
    #  returns directory path based on GUID
    #---------------------------------------------------------------------------
    def path(type)
      getKnownFolder(guid_to_hex(COMMON_PATHS[type]))
    end
    #---------------------------------------------------------------------------
    #  converts GUID to proper hex array
    #---------------------------------------------------------------------------
    def guid_to_hex(string)
      [].tap do |hex_array|
        string.split('-').each_with_index do |chunk, i|
          if i < 3
            hex_array.push(chunk.hex)
          else
            chunk.scan(/../).each do |s|
              hex_array.push(s)
            end
          end
        end
      end
    end
    #---------------------------------------------------------------------------
    #  returns working directory
    #---------------------------------------------------------------------------
    def directory
      Dir.pwd
    end
    #---------------------------------------------------------------------------
    #  escape characters
    #---------------------------------------------------------------------------
    def char_esc(string)
      @char_set.each do |key, val|
        string.gsub!(key, val)
      end

      string
    end
    #---------------------------------------------------------------------------
    #  describe characters
    #---------------------------------------------------------------------------
    def char_dsc(string)
      @char_set.each do |key, val|
        string.gsub!(val, key)
      end

      string
    end
    #---------------------------------------------------------------------------
  end
end
