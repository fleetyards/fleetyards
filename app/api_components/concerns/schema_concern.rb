# frozen_string_literal: true

module SchemaConcern
  extend ActiveSupport::Concern

  included do
    class << self
      attr_accessor :schema_value, :schema_hidden_value

      def schema(schema_definition)
        self.schema_value = if superclass.respond_to?(:schema_value)
          parent_schema_definition = superclass.schema_value.deep_dup
          parent_schema_definition.deeper_merge(schema_definition)
        else
          schema_definition
        end
      end

      def schema_hidden(flag = false)
        self.schema_hidden_value = flag
      end
    end

    def to_schema
      self.class.schema_value
    end

    def hidden?
      self.class.schema_hidden_value
    end
  end
end
