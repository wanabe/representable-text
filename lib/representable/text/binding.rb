require "representable/binding"

module Representable
  module Text
    class Binding < Representable::Binding
      class << self
        def build_for(definition)
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
    end
  end
end
