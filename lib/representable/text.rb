require "representable"
require "representable/text/version"
require 'representable/text/binding'

module Representable
  module Text
    extend Hash::ClassMethods

    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        register_feature Representable::Text
        @pattern = ""
      end
    end

    module ClassMethods
      def format_engine
        Representable::Text
      end

      def pattern(pattern, name: nil, escape: true)
        case pattern
        when nil
          return
        when String
          if escape
            pattern = Regexp.escape(pattern)
          end
        when Regexp
          pattern = pattern.source
        end

        if name
          pattern = "(?<#{name}>#{pattern})"
        end
        @pattern << pattern
      end

      def left(length)
        yield
        pattern " *", escape: false
      end

      def right(length)
        pattern " *", escape: false
        yield
      end

      def property(name, pattern = nil, **opt)
        pattern pattern, name: name
        super name, **opt
      end

      def to_regexp
        Regexp.new(@pattern)
      end
    end

    def from_text(text, options={})
      hash = regexp.match(text)&.named_captures || {}
      update_properties_from(hash, options, Binding)
    end

  private
    def regexp
      self.class.to_regexp
    end
  end
end
