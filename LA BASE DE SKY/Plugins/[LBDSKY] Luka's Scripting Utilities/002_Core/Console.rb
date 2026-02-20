#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Console` module
#===============================================================================
module ::Console
  class << self
    # Function to echo to console without line break
    # @param msg [String]
    # @param options [Hash]
    def echo_str(msg, options = {})
      echo markup_style(markup(msg), **options)
    end

    # Extend paragraph echo
    # @param msg [String]
    # @param options [Hash]
    def echo_p(msg, options = {})
      echoln markup_style(markup(msg), **options)
    end
  end
end
