# frozen_string_literal: true

module SchemaConcern
  extend ActiveSupport::Concern

  included do
    class_attribute :schema_value

    class << self
      def schema(schema_definition)
        self.schema_value = if schema_value.present?
          schema_value.deeper_merge(schema_definition)
        else
          schema_definition
        end
      end
    end

    def to_schema
      schema_value
    end
  end
end
