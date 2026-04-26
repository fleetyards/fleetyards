# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadoutMinimal
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            erkulUrl: {type: :string, nullable: true},
            spviewerUrl: {type: :string, nullable: true}
          },
          additionalProperties: false,
          required: %w[id name]
        })
      end
    end
  end
end
