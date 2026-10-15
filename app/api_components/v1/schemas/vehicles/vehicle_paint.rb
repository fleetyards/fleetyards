# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehiclePaint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # Recorded on this ship.
            owned: {type: :boolean},
            # One of the owner's synced paint pledges resolves to it. A pledge
            # names no ship, so this is what the editor suggests, not ownership.
            pledged: {type: :boolean},
            # The ship's picture is this paint's.
            picture: {type: :boolean},
            paint: {"$ref": "#/components/schemas/ModelPaint"}
          },
          additionalProperties: false,
          required: %w[owned pledged picture paint]
        })
      end
    end
  end
end
