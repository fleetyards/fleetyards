# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class AccountUpdateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            username: {type: :string},
            email: {type: :string, format: :email}
          },
          additionalProperties: false
        })

        def to_strong_params
          to_schema[:properties].map do |key, value|
            if value[:type] == "string"
              key.to_s.underscore.to_sym
            elsif value[:type] == "object"
              if value[:properties].present?
                {key.to_s.underscore.to_sym => value[:properties].transform_keys { |k| k.to_s.underscore.to_sym }}
              else
                key.to_s.underscore.to_sym
              end
            elsif value[:type] == "array"
              {key.to_s.underscore.to_sym => []}
            else
              key.to_s.underscore.to_sym
            end
          end
        end
      end
    end
  end
end
