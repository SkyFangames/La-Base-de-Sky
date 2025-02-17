#===============================================================================
#  LUTS compiler definition
#===============================================================================
module LUTS
  module Compiler
    class << self
      #-------------------------------------------------------------------------
      #  get base files to compile
      #-------------------------------------------------------------------------
      def compile_files(path)
        [].tap do |files|
          Dir.get(path, '*.txt', false).each do |d|
            f = d.split('.').first
            files << f unless files.include?(f)
          end
        end
      end
      #-------------------------------------------------------------------------
      #  start LUTS compiling process
      #-------------------------------------------------------------------------
      def compile(path:, schema:, file_ext:, force: false)
        path = path.split('/').compact.join('/')
        # don't compile if project archive exists or game is not running in debug
        return unless $DEBUG && !File.safe_data?('Game.rgssad') && Dir.safe?(path)

        label = schema.const_defined?(:LABEL) ? schema::LABEL : 'Unknown'
        # set compiling message
        pbSetWindowText('[LUTS] Compiling data...')
        compiled = false
        errored  = false
        LUTS::Logger.info("LUTS: Compiling #{label} data", text: :brown, header: true)

        # initialize main game data for enumerations
        GameData.load_all

        # iterate through each compile file
        compile_files(path).each do |map|
          # check if compile should go through
          refresh = !File.safe_data?("Data/#{map}.#{file_ext}")
          refresh = true if Input.press?(Input::CTRL) || force
          refresh = true if !refresh && safeExists?("#{path}/#{map}.txt") && File.mtime("#{path}/#{map}.txt") > File.mtime("Data/#{map}.#{file_ext}")
          # iterate through all possible packs
          pbs = Dir.get(path, '*.txt', false)
          pbs.each do |file|
            # skip if main or not part of current iterable
            next if file == "#{map}.txt" || !file.start_with?(map) || refresh

            refresh = true if File.mtime("#{path}/#{map}.txt") > File.mtime("Data/#{map}.#{file_ext}")
          end
          next unless refresh

          # show message
          LUTS::Logger.info("-> compiling `#{map}.txt` data ... ", break: false)
          next LUTS::Logger.warn("No schema defined for `#{map.upcase}`! ~Unable to compile PBS data!~") unless schema.const_defined?(map.upcase.to_sym)

          data = {}
          # read main PBS
          begin
            data.deep_merge!(compile_data("#{path}/#{map}.txt", schema: schema, const: map.upcase.to_sym))
            # iterate through all possible packs
            pbs.each do |file|
              # skip if main or not part of current iterable
              next if file == "#{map}.txt" || !file.start_with?(map)

              data.deep_merge!(compile_data("#{path}/#{file}", schema: schema, const: map.upcase.to_sym))
            end
            save_data(data, "Data/#{map}.#{file_ext}")
            compiled = true
            Console.echo_done(true)
          rescue StandardError => e
            Console.echo_done(false)
            LUTS::Logger.error("Failed to compile data: #{e.full_message}", skip_console: true)
            errored = true
          end
        end
        # clean up
        GC.start
        echoln('')
        # show console output
        if errored
          LUTS::Logger.error("Failed to compile all #{label} data.", text: :red)
        elsif compiled
          LUTS::Logger.info("Compiled all #{label} data.", text: :green)
        else
          LUTS::Logger.info("All `#{label}` data already compiled.")
        end
        pbSetWindowText(nil)
      end
      #-------------------------------------------------------------------------
      #  compile data for specified schema
      #-------------------------------------------------------------------------
      def compile_data(path, schema:, const:)
        current_schema = "#{schema}::#{const}".constantize
        data_hash      = {}
        idx            = 0
        section        = nil
        subsection     = nil

        # use Essentials compiler to process and cast property values
        ::Compiler.pbCompilerEachPreppedLine(path) do |line, _line_no|
          idx += 1
          Graphics.update if idx % 250 == 0
          if line[/^\s*\[\s*(.+)\s*\]\s*$/] # process section header
            # New section [type] or [type, name] or [type, name, version]
            line_data = ::Compiler.get_csv_record($~[1], [0, 'sSS'])

            section = [].tap do |array|
              array << line_data[0]

              # add catch for TRAINER and POKEMON ids
              if [:POKEMON, :TRAINERS].include?(const)
                array << if const.eql?(:POKEMON)
                           line_data[1].nil? ? '0' : line_data[1]
                         else
                           line_data[1]
                         end
              end

              array << line_data[2] if [:TRAINERS].include?(const)
            end.compact.join('_').to_sym

            # Construct data hash
            data_hash[section] = {}
          elsif line[/^\s*(\w+)\s*=\s*(.*)$/] # process line property
            target_hash = section ? data_hash[section] : data_hash
            property_name = $~[1]

            if current_schema.key?(:any)
              property_value = ::Compiler.get_csv_record($~[2], current_schema[:any])
              # Record XXX=YYY setting
              target_hash[subsection][property_name] = property_value
            else
              line_schema = current_schema[property_name]
              next unless line_schema

              property_value = ::Compiler.get_csv_record($~[2], line_schema)
              # Record XXX=YYY setting
              if property_name[/^(\w+)XYZ$/]
                [:x, :y, :z].each_with_index do |sym, i|
                  target_hash[[line_schema[0], sym].compact.map(&:to_s).join('_').to_sym] = property_value[i]
                end
              elsif property_name[/^(\w+)XY$/]
                [:x, :y].each_with_index do |sym, i|
                  target_hash[[line_schema[0], sym].compact.map(&:to_s).join('_').to_sym] = property_value[i]
                end
              else
                target_hash[line_schema[0]] = property_value
              end
            end
          elsif line[/^\s*([A-Z_]+)\s*$/] # process subsection
            target_hash = section ? data_hash[section] : data_hash
            property_name = $~[1]

            if property_name.eql?('END')
              current_schema = "#{schema}::#{const}".constantize
            elsif current_schema.key?(property_name)
              subsection = property_name.to_sym
              target_hash[subsection] = {}
              current_schema = "#{schema}::#{current_schema[property_name][0]}".constantize
            end
          end
        end

        # return compiled data hash
        data_hash
      end
      #-------------------------------------------------------------------------
    end
  end
end
