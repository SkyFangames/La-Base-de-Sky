#===============================================================================
#  Utility for defining custom error messages
#===============================================================================
module LUTS
  module ErrorMessages
    #---------------------------------------------------------------------------
    #  base class structure
    #---------------------------------------------------------------------------
    class BaseError
      def initialize
        raise NotImplementedError
      end

      def raise
        ::LUTS::Logger.send(level, message)
      end

      private

      def level
        raise NotImplementedError
      end

      def message
        raise NotImplementedError
      end
    end
    #---------------------------------------------------------------------------
    #  unable to find bitmap error
    #---------------------------------------------------------------------------
    class ImageNotFound < BaseError
      def initialize(path)
        @path = path
      end

      private

      def level
        :error
      end

      def message
        "Image located at \"#{@path}\" was not found!"
      end
    end
    #---------------------------------------------------------------------------
    #  unable to create sprite instance error
    #---------------------------------------------------------------------------
    class SpriteError < BaseError
      def initialize(name)
        @name = name
      end

      private

      def level
        :warn
      end

      def message
        "Unable to instanciate `Sprites::#{@name}`! No such class!"
      end
    end
    #---------------------------------------------------------------------------
    #  unable to use component
    #---------------------------------------------------------------------------
    class ComponentError < BaseError
      def initialize(name)
        @name = name
      end

      private

      def level
        :warn
      end

      def message
        "Unable to load `#{@name}` component! No such class!"
      end
    end
    #---------------------------------------------------------------------------
  end
  #-----------------------------------------------------------------------------
  #  standard error wrapper for LUTS
  #-----------------------------------------------------------------------------
  class ScriptError < ::StandardError
  end
end
