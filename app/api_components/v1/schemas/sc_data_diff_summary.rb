# frozen_string_literal: true

module V1
  module Schemas
    class ScDataDiffSummary
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          from: ::V1::Schemas::ScDataDiffBuild,
          to: ::V1::Schemas::ScDataDiffBuild,
          code: ::V1::Schemas::Enums::ScDataDiffCodeEnum,
          items: {type: :array, items: ::V1::Schemas::ScDataDiffCatalogue}
        },
        additionalProperties: false,
        required: %w[from to code items]
      })
    end
  end
end
