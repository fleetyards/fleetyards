# frozen_string_literal: true

module V1
  module Schemas
    # `category` is there for a loadout's slots alone, and says what the slot is for.
    class ScDataDiffField
      include OpenapiRuby::Components::Base

      VALUE = {type: [:number, :string, :boolean, :null]}.freeze

      schema({
        type: :object,
        properties: {field: {type: :string}, from: VALUE, to: VALUE, category: {type: :string}},
        additionalProperties: false,
        required: %w[field]
      })
    end
  end
end
