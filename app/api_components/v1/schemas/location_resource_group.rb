# frozen_string_literal: true

module V1
  module Schemas
    # One kind of thing a body offers, as its description headed it --
    # "Potential Ship Mineables" is `ship_mineables`. A string rather than an
    # enum: the export may head a section nobody has seen yet.
    class LocationResourceGroup
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          kind: {type: :string},
          items: {type: :array, items: ::V1::Schemas::LocationResource}
        },
        additionalProperties: false,
        required: %w[kind items]
      })
    end
  end
end
