# frozen_string_literal: true

module SchemaConcern
  extend ActiveSupport::Concern

  included do
    class << self
      attr_accessor :schema_value

      def schema(schema_definition)
        self.schema_value = if superclass.respond_to?(:schema_value)
          parent_schema_definition = superclass.schema_value.deep_dup
          parent_schema_definition.deeper_merge(schema_definition)
        else
          schema_definition
        end
      end
    end

    def to_schema
      self.class.schema_value
    end
  end
end
