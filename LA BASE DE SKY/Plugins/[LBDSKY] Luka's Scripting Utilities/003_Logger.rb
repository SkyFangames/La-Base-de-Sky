#===============================================================================
#  Error logger utility
#-------------------------------------------------------------------------------
#  used to store custom error log messages
#===============================================================================
module LUTS
  module Logger
    class << self
      #-------------------------------------------------------------------------
      #  define path to which to log message output
      #-------------------------------------------------------------------------
      def log_path
        'luts_log.txt' # ::RTP.getSaveFileName('luts_log.txt')
      end
      #-------------------------------------------------------------------------
      #  log message to console and file
      #-------------------------------------------------------------------------
      def log_msg(msg, options = {})
        log_to_console(msg, options)

        File.open(log_path, 'ab') do |f|
          f.write("#{timestamp} [#{options[:type].to_s.upcase}] #{msg}\r\n")
        end
      end
      #-------------------------------------------------------------------------
      #  log message to console with formatting
      #-------------------------------------------------------------------------
      def log_to_console(msg, options)
        return if options[:skip_console] == true

        # print log level
        if options[:type].eql?(:debug)
          Console.echo_str("[#{options[:type].to_s.upcase}]")
        else
          Console.echo_str(" #{options[:type].to_s.upcase} ", bg: console_color(options[:type]))
        end

        # print header if applicable
        if options[:header].eql?(true)
          Console.echoln(Console.markup_style(" *** #{msg} ***", text: :brown))
          return
        end

        # print line item if applicable
        Console.echo_str(' -> ', text: :brown) if msg.start_with?('-> ')
        msg = " #{msg}"

        # print rest of message
        if options[:break].eql?(false)
          Console.echo_str(msg.sub('-> ', '').gsub('`', '"'), options.except(:type, :break))
        else
          Console.echo_p(msg.sub('-> ', '').gsub('`', '"'), options.except(:type, :break))
        end
      end
      #-------------------------------------------------------------------------
      #  get console color for message type
      #-------------------------------------------------------------------------
      def console_color(type)
        case type
        when :error
          :red
        when :warn
          :brown
        else
          :cyan
        end
      end
      #-------------------------------------------------------------------------
      #  format timestamp
      #-------------------------------------------------------------------------
      def timestamp
        Time.now.strftime('[%H:%M:%S %a %d-%b-%Y]')
      end
      #-------------------------------------------------------------------------
      #  INFO level log
      #-------------------------------------------------------------------------
      def info(msg, options = {})
        log_msg(msg, options.merge({ type: :info }))
      end
      #-------------------------------------------------------------------------
      #  ERROR level log
      #-------------------------------------------------------------------------
      def error(msg, options = {})
        log_msg(msg, options.merge({ type: :error }))
      end
      #-------------------------------------------------------------------------
      #  ERROR level log and crash application
      #-------------------------------------------------------------------------
      def critical(msg, options = {})
        log_msg(msg, options.merge({ type: :error }))

        raise LUTS::ScriptError, msg
      end
      #-------------------------------------------------------------------------
      #  WARN level log
      #-------------------------------------------------------------------------
      def warn(msg, options = {})
        log_msg(msg, options.merge({ type: :warn }))
      end
      #-------------------------------------------------------------------------
      #  DEBUG level log
      #-------------------------------------------------------------------------
      def debug(msg, options = {})
        return unless $DEBUG

        log_msg(msg, options.merge({ type: :debug }))
      end
      #-------------------------------------------------------------------------
    end
  end
end

#===============================================================================
#  Error logger utility
#-------------------------------------------------------------------------------
#  used to store custom error log messages
#===============================================================================
class ErrorLogger
  #-----------------------------------------------------------------------------
  # initialization
  #-----------------------------------------------------------------------------
  def initialize(file = nil)
    file = "systemout.txt" if file.nil?
    @file = RTP.getSaveFileName(file)
  end
  #-----------------------------------------------------------------------------
  # record message
  #-----------------------------------------------------------------------------
  def log_msg(msg, type = "INFO", file = nil)
    file = @file if file.nil?
    echoln "#{type.upcase}: #{msg}"
    msg = "#{time_stamp} [#{type.upcase}] #{msg}\r\n"
    File.open(file, 'ab') {|f| f.write(msg)}
  end
  #-----------------------------------------------------------------------------
  # format timestamp
  #-----------------------------------------------------------------------------
  def time_stamp
    time = Time.now
    return time.strftime "[%H:%M:%S %a %d-%b-%Y]"
  end
  #-----------------------------------------------------------------------------
  # logger input
  #-----------------------------------------------------------------------------
  def log(msg, file = nil); log_msg(msg, "INFO", file); end
  def info(msg, file = nil); log_msg(msg, "INFO", file); end
  def error(msg, file = nil)
    log_msg(msg, "ERROR", file)
    raise msg
  end
  def warn(msg, file = nil); log_msg(msg, "WARN", file); end
  def debug(msg, file = nil)
    return if !$DEBUG
    log_msg(msg, "DEBUG", file)
  end
end
#===============================================================================
#  Environment module for easy Win directory manipulation
#===============================================================================
module Env
  @logger = ErrorLogger.new
  #-----------------------------------------------------------------------------
  # constant containing GUIDs found on MSDN for common directories
  #-----------------------------------------------------------------------------
  COMMON_PATHS = {
      "CAMERA_ROLL" => "AB5FB87B-7CE2-4F83-915D-550846C9537B",
      "START_MENU" => "A4115719-D62E-491D-AA7C-E74B8BE3B067",
      "DESKTOP" => "B4BFCC3A-DB2C-424C-B029-7FE99A87C641",
      "DOCUMENTS" => "FDD39AD0-238F-46AF-ADB4-6C85480369C7",
      "DOWNLOADS" => "374DE290-123F-4565-9164-39C4925E467B",
      "HOME" => "5E6C858F-0E22-4760-9AFE-EA3317B67173",
      "MUSIC" => "4BD8D571-6D19-48D3-BE97-422220080E43",
      "PICTURES" => "33E28130-4E1E-4676-835A-98395C3BC3BB",
      "SAVED_GAMES" => "4C5C32FF-BB9D-43b0-B5B4-2D72E54EAAA4",
      "SCREENSHOTS" => "b7bede81-df94-4682-a7d8-57a52620b86f",
      "VIDEOS" => "18989B1D-99B5-455B-841C-AB7C74E4DDFC",
      "LOCAL" => "F1B32785-6FBA-4FCF-9D55-7B8E7F157091",
      "LOCALLOW" => "A520A1A4-1780-4FF6-BD18-167343C5AF16",
      "ROAMING" => "3EB685DB-65F9-4CF6-A03A-E3EF65729F3D",
      "PROGRAM_DATA" => "62AB5D82-FDC1-4DC3-A9DD-070D1D495D97",
      "PROGRAM_FILES_X64" => "6D809377-6AF0-444b-8957-A3773F02200E",
      "PROGRAM_FILES_X86" => "7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E",
      "COMMON_FILES" => "F7F1ED05-9F6D-47A2-AAAE-29D317C6F066",
      "PUBLIC" => "DFDF76A2-C82A-4D63-906A-5644AC457385",
  }
  #-----------------------------------------------------------------------------
  # escape chars for Directories
  #-----------------------------------------------------------------------------
  @char_set = {
    "\\" => "&bs;", "/" => "&fs;", ":" => "&cn;", "*" => "&as;",
    "?" => "&qm;", "\"" => "&dq;", "<" => "&lt;", ">" => "&gt;",
    "|" => "&po;"
  }
  #-----------------------------------------------------------------------------
  # returns directory path based on GUID
  #-----------------------------------------------------------------------------
  def self.path(type)
    hex = self.guid_to_hex(COMMON_PATHS[type])
    return getKnownFolder(hex)
  end
  #-----------------------------------------------------------------------------
  # converts GUID to proper hex array
  #-----------------------------------------------------------------------------
  def self.guid_to_hex(string)
    chunks = string.split("-")
    hex = []
    for i in 0...chunks.length
      chunk = chunks[i]
      if i < 3
        hex.push(chunk.hex)
      else
        split = chunk.scan(/../)
        for s in split
          hex.push(s.hex)
        end
      end
    end
    return hex
  end
  #-----------------------------------------------------------------------------
  # returns working directory
  #-----------------------------------------------------------------------------
  def self.directory
    return Dir.pwd.gsub("/","\\")
  end
  #-----------------------------------------------------------------------------
  # return error logger
  #-----------------------------------------------------------------------------
  def self.log
    return @logger
  end
  #-----------------------------------------------------------------------------
  # escape characters
  #-----------------------------------------------------------------------------
  def self.char_esc(str)
    for key in @char_set.keys
      str.gsub!(key, @char_set[key])
    end
    return str
  end
  #-----------------------------------------------------------------------------
  # describe characters
  #-----------------------------------------------------------------------------
  def self.char_dsc(str)
    for key in @char_set.keys
      str.gsub!(@char_set[key], key)
    end
    return str
  end
  #-----------------------------------------------------------------------------
  # interpret file stream and convert to appropriate Hash map
  #-----------------------------------------------------------------------------
  def self.interpret(filename)
    # failsafe
    return {} if !safeExists?(filename)
    # read file
    contents = File.open(filename, 'rb') {|f| f.read.gsub("\t", "  ") }
    # begin interpretation
    data = {}; entries = []
    # skip if empty
    return data if !contents || contents.empty?
    indexes = contents.scan(/(?<=\[)(.*?)(?=\])/i)
    return data if indexes.nil?
    indexes.push(indexes[-1])
    # iterate through each index and compile data points
    for j in 0...indexes.length
      i = indexes[j]
      if j == indexes.length - 1 # when final entry
        m = contents.split("[#{i[0]}]")[1]
        next if m.nil?
      else # fetch data contents
        m = contents.split("[#{i[0]}]")[0]
        next if m.nil?
        contents.gsub!(m, "")
      end
      m.gsub!("[#{i[0]}]\r\n", "")
      m.gsub!("[#{i[0]}]\n", "")
      # safely read each line and push into array
      read_lines = []
      m.each_line do |ext_line|
        ext_line.gsub!("\r\n", "")
        ext_line.gsub!("\n", "")
        read_lines.push(ext_line)
      end
      # push read lines into array
      entries.push(read_lines) # push into array
    end
    # delete first empty data point
    entries.delete_at(0)
    # loop to iterate through each data point and compile usable information
    for i in 0...entries.length
      d = {}
      # set primary section
      section = "__pk__"
      # compiles data into proper structure
      for e in entries[i]
        d[section] = {} if !d.keys.include?(section)
        e = e.split("#")[0]
        next if e.nil? || e == "" || (e.include?("[") && e.include?("]"))
        a = e.split("=")
        a[0] = a[0] ? a[0].strip : ""
        a[1] = a[1] ? a[1].strip : ""
        next section = a[0] if a[1].nil? || a[1] == "" || a[1].empty?
        # split array
        a[1] = a[1].split(",")
        # raise error
        if a[0] == "XY" && a[1].length < 2
          raise self.lengthError(filename, indexes[i][0], section, 2, a[0], a[1])
        elsif a[0] == "XYZ" && a[1].length < 3
          raise self.lengthError(filename, indexes[i][0], section, 3, a[0], a[1])
        end
        # convert to proper type
        for q in 0...a[1].length
          typ = "String"
          begin
            if a[1][q].is_numeric? && a[1][q].include?('.')
              typ = "Float"
              a[1][q] = a[1][q].to_f
            elsif a[1][q].is_numeric?
              typ = "Integer"
              a[1][q] = a[1][q].to_i
            elsif a[1][q].downcase == "true" || a[1][q].downcase == "false"
              typ = "Boolean"
              a[1][q] = a[1][q].downcase == "true"
            end
          rescue
            self.log.error(self.formatError(filename, indexes[i][0], section, typ, a[0], a[1][q]))
          end
        end
        # add data to section
        d[section][a[0]] = a[1]
      end
      # delete primary if empty
      d.delete("__pk__") if d["__pk__"] && d["__pk__"].empty?
      # push data entry
      data[indexes[i][0]] = d
    end
    return data
  end
  #-----------------------------------------------------------------------------
  # print out formatting error
  #-----------------------------------------------------------------------------
  def self.formatError(filename, section, sub, type, key, val)
    sectn = (sub == "__pk__") ? "[#{section}]" : "[#{section}]\nSub-section: #{sub}"
    return "File: #{filename}\nError compiling data in Section: #{sectn}\nCould not implicitly convert value for Key: #{key} to type (#{type})\n#{key} = #{val}"
  end
  def self.lengthError(filename, section, sub, len, key, val)
    sectn = (sub == "__pk__") ? "[#{section}]" : "[#{section}]\nSub-section: #{sub}"
    return "File: #{filename}\nError compiling data in Section: #{sectn}\nWrong number of arguments for Key: #{key}, got #{val.length} expected #{len}"
  end
  #-----------------------------------------------------------------------------
end