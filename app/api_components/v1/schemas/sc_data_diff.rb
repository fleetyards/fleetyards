# frozen_string_literal: true

module V1
  module Schemas
    class ScDataDiff < ::Shared::V1::Schemas::BaseList
      include OpenapiRuby::Components::Base

      schema({
        properties: {
          recorded: {type: :boolean},
          counts: ::V1::Schemas::ScDataDiffCounts,
          fields: {type: :array, items: ::V1::Schemas::ScDataDiffFieldCount},
          items: {type: :array, items: ::V1::Schemas::ScDataDiffEntry}
        },
        required: %w[recorded counts fields items]
      })
    end
  end
end
