# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadoutMinimal
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            url: {type: :string},
            urlSource: {type: :string}
          },
          additionalProperties: false,
          required: %w[id name url]
        })
      end
    end
  end
end
