#===============================================================================
#  Luka's Scripting Utilities
#
#  Utility for defining custom error messages
#===============================================================================
module LUTS
  module ErrorMessages
    # Base class structure
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

    # Unable to find bitmap error
    class ImageNotFound < BaseError
      # @param path [String]
      def initialize(path)
        @path = path
      end

      private

      # @return [Symbol]
      def level
        :error
      end

      # @return [String]
      def message
        "Image located at \"#{@path}\" was not found!"
      end
    end

    # Unable to create sprite instance error
    class SpriteError < BaseError
      # @param name [String]
      def initialize(name)
        @name = name
      end

      private

      # @return [Symbol]
      def level
        :warn
      end

      # @return [String]
      def message
        "Unable to instanciate `Sprites::#{@name}`! No such class!"
      end
    end

    # Unable to use component
    class ComponentError < BaseError
      # @param name [String]
      def initialize(name)
        @name = name
      end

      private

      # @return [Symbol]
      def level
        :warn
      end

      # @return [String]
      def message
        "Unable to load `#{@name}` component! No such class!"
      end
    end

    # Unable to find function
    class MissingFunctionError < BaseError
      # @param class [Class]
      # @param function [Symbol]
      def initialize(klass, function)
        @klass    = klass
        @function = function
      end

      private

      # @return [Symbol]
      def level
        :warn
      end

      # @return [String]
      def message
        "Undefined function `#{@function}' for class `#{@klass}'!"
      end
    end

    # Wrong number of vertices
    class VertexError < BaseError
      # @param vertices [Integer]
      def initialize(vertices = 3)
        @vertices = vertices
      end

      private

      # @return [Symbol]
      def level
        :error
      end

      # @return [String]
      def message
        "Incorrect number of vertices. Must contain a minimum of #{@vertices} vertices."
      end
    end
  end

  # Standard error wrapper for LUTS
  class ScriptError < ::StandardError
  end
end
