# frozen_string_literal: true

module V1
  module Schemas
    # `unrecorded` are the facts one of the builds never stated, left out of the
    # comparison, with the records each would have marked as changed.
    class ScDataDiff < ::Shared::V1::Schemas::BaseList
      include OpenapiRuby::Components::Base

      schema({
        properties: {
          recorded: {type: :boolean},
          counts: ::V1::Schemas::ScDataDiffCounts,
          fields: {type: :array, items: ::V1::Schemas::ScDataDiffFieldCount},
          unrecorded: {type: :array, items: ::V1::Schemas::ScDataDiffFieldCount},
          items: {type: :array, items: ::V1::Schemas::ScDataDiffEntry}
        },
        required: %w[recorded counts fields unrecorded items]
      })
    end
  end
end
