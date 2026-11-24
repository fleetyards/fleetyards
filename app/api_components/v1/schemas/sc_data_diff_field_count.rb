# frozen_string_literal: true

module V1
  module Schemas
    class ScDataDiffFieldCount
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {field: {type: :string}, count: {type: :integer}},
        additionalProperties: false,
        required: %w[field count]
      })
    end
  end
end
