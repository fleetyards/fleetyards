# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class BlueprintLogImportInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slugs: {
              type: :array,
              items: {type: :string},
              maxItems: 5000,
              description: "The blueprints to mark as owned"
            },
            unmatchedNames: {
              type: :array,
              items: {type: :string, maxLength: 255},
              maxItems: 5000,
              description: "Names from the logs no blueprint matched, kept with the import for the record"
            }
          },
          additionalProperties: false,
          required: %w[slugs]
        })
      end
    end
  end
end
