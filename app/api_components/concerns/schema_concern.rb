# frozen_string_literal: true

module SchemaConcern
  extend ActiveSupport::Concern

  included do
    class_attribute :schema_value

    class << self
      def schema(*args, **kwargs)
        name = (args.size == 2) ? args.first : :base
        definition = (args.size == 2) ? args.last : args.first
        extends = kwargs[:extends]

        self.schema_value ||= {}

        self.schema_value[name] = if extends && self.schema_value[extends]
          self.schema_value[extends].deep_merge(definition)
        else
          definition
        end
      end
    end

    def to_schema
      schema_value
    end
  end
end
