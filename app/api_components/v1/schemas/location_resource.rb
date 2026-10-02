# frozen_string_literal: true

module V1
  module Schemas
    class LocationResource
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          # Where on the body, as the description writes it: "Caves only".
          note: {type: [:string, :null]},
          commodity: {anyOf: [::V1::Schemas::LocationResourceCommodity, {type: :null}]}
        },
        additionalProperties: false,
        required: %w[name note commodity]
      })
    end
  end
end
