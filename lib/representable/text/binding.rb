require "representable/binding"

module Representable
  module Text
    class Binding < Representable::Binding
      class << self
        def build_for(definition)
          return Collection.new(definition) if definition.array?
          new(definition)
        end
      end

      def initialize(definition)
        super
        @length_capture = definition[:length_capture]
      end

      def read(capture_hash, as)
        length_capture_text = capture_hash[@length_capture]
        if length_capture_text
          return length_capture_text.length
        end

        if capture_hash.has_key?(as)
          return capture_hash[as]
        end
        FragmentNotFound
      end

      def deserialize_method
        :from_text
      end

      class Collection < self
        include Representable::Binding::Collection

        def initialize(definition)
          super
          @regexp = definition[:decorator].to_collection_regexp if definition[:decorator]
        end

        def read(capture_hash, as)
          result = super

          if @regexp && result.respond_to?(:scan)
            return result.scan(@regexp)
          end

          result
        end
      end
    end
  end
end
