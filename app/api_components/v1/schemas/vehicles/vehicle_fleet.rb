# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleFleet
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fid: {type: :string},
            name: {type: :string},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[id fid name slug]
        })
      end
    end
  end
end
