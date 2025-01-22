# [ g f y ]
# https://www.ruby-lang.org/en/news/2022/12/25/ruby-3-2-0-released/
MKXP.puts("Dir.exists?/File.exists? has been deprecated since Ruby 2.1.0, and then removed in Ruby 3.2.0")

class Dir
  class << self
    alias_method :exists?, :exist?
  end
end

class File
  class << self
    alias_method :exists?, :exist?
  end
end
