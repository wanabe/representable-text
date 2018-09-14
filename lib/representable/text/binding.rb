require "representable/binding"

module Representable
  module Text
    class Binding < Representable::Binding
      class << self
        def build_for(definition)
          new(definition)
        end
      end

      def read(capture_hash, as)
        capture_hash.has_key?(as) ? capture_hash[as] : FragmentNotFound
      end
    end
  end
end
