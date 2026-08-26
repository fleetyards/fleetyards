# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      # The pledge a bundled snub craft came with.
      class VehicleBundledParent
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            customName: {type: :string}
          }
        })
      end
    end
  end
end
