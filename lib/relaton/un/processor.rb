# frozen_string_literal: true

require "relaton/core/processor"

module Relaton
  module Un
    class Processor < Core::Processor
      attr_reader :idtype

      def initialize
        @short = :relaton_un
        @prefix = "UN"
        @defaultprefix = %r{^UN\s}
        @idtype = "UN"
      end

      def get(code, date, opts)
        require_relative "../un"
        Bibliography.get(code, date, opts)
      end

      def from_xml(xml)
        require_relative "../un"
        Bibdata.from_xml(xml)
      end

      def from_yaml(yaml)
        require_relative "../un"
        Item.from_yaml(yaml)
      end

      def grammar_hash
        require_relative "../un"
        @grammar_hash ||= Relaton::Un.grammar_hash
      end
    end
  end
end
