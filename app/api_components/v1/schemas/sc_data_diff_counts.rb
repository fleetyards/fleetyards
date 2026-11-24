# frozen_string_literal: true

module V1
  module Schemas
    class ScDataDiffCounts
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {added: {type: :integer}, removed: {type: :integer}, changed: {type: :integer}},
        additionalProperties: false,
        required: %w[added removed changed]
      })
    end
  end
end
