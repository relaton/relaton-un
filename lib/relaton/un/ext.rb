require_relative "doctype"
require_relative "session"

module Relaton
  module Un
    class Ext < Bib::Ext
      attribute :doctype, Doctype
      attribute :submissionlanguage, :string, collection: true
      attribute :distribution, :string, values: %w[general limited restricted provisional]
      attribute :session, Session
      attribute :job_number, :string

      xml do
        map_element "submissionlanguage", to: :submissionlanguage
        map_element "distribution", to: :distribution
        map_element "session", to: :session
        map_element "job_number", to: :job_number
      end

      key_value do
        map "submissionlanguage", to: :submissionlanguage
        map "distribution", to: :distribution
        map "session", to: :session
        map "job_number", to: :job_number
      end

      def get_schema_version = Relaton.schema_versions["relaton-model-un"]
    end
  end
end
