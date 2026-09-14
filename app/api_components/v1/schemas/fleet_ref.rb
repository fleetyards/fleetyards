# frozen_string_literal: true

module V1
  module Schemas
    # The fleet a record belongs to: enough to name it and link to it. Absent
    # entirely on a record that belongs to no fleet, rather than rendered as a
    # null -- see `UserRef` for the same shape on the person side.
    class FleetRef
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          logo: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false,
        required: %w[id name slug]
      })
    end
  end
end
