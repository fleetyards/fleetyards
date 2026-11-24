# frozen_string_literal: true

module V1
  module Schemas
    class ScDataDiffField
      include OpenapiRuby::Components::Base

      VALUE = {type: [:number, :string, :boolean, :null]}.freeze

      schema({
        type: :object,
        properties: {field: {type: :string}, from: VALUE, to: VALUE},
        additionalProperties: false,
        required: %w[field]
      })
    end
  end
end
