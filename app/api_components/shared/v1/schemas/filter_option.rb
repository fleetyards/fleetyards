# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class FilterOption
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            category: {type: :string},
            icon: {type: :string},
            label: {type: :string},
            value: {
              anyOf: [
                {type: [:string, :null]},
                {type: [:number, :null]}
              ]
            },
            name: {type: :string, deprecated: true}
          },
          additionalProperties: false,
          required: %w[label value]
        })
      end
    end
  end
end
