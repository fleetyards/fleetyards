# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetVehicleExport
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            slug: {type: :string},
            shipCode: {type: :string},
            manufacturerName: {type: :string},
            manufacturerCode: {type: :string},
            paintSlug: {type: :string},
            shipName: {type: :string},
            shipSerial: {type: :string},
            wanted: {type: :boolean},
            flagship: {type: :boolean},
            public: {type: :boolean},
            saleNotify: {type: :boolean},
            nameVisible: {type: :boolean},
            groups: {type: :array, items: {type: :string}},
            modules: {type: :array, items: {type: :string}},
            upgrades: {type: :array, items: {type: :string}},
            username: {type: [:string, :null]},
            userAvatar: {type: [:string, :null], format: :uri},
            userRsiHandle: {type: [:string, :null]}
          },
          additionalProperties: false,
          required: %w[
            name slug manufacturerName wanted flagship public saleNotify
            nameVisible groups modules upgrades
          ]
        })
      end
    end
  end
end
