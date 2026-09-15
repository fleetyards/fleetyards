# frozen_string_literal: true

module V1
  module Schemas
    class InventoryVehicleModel
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          cargo: {type: :number},
          personalInventory: {type: :number},
          image: ::Shared::V1::Schemas::MediaFile
        }
      })
    end
  end
end
