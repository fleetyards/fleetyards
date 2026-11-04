# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanModel
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "A ship as a plan shows it",
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              manufacturerName: {type: [:string, :null]},
              manufacturerIcon: {type: [:string, :null], format: :uri, description: "The manufacturer's square icon"},
              classification: {type: [:string, :null]},
              size: {type: [:string, :null]},
              productionStatus: {type: [:string, :null]},
              pledgePrice: {type: [:number, :null], description: "Store price in USD; null when unknown"},
              onSale: {type: :boolean},
              ccuInto: ::V1::Schemas::Enums::HangarPlanCcuIntoEnum,
              ccuOutOf: ::V1::Schemas::Enums::HangarPlanCcuOutOfEnum,
              ccuIntoFrom: {
                type: [:array, :null],
                items: {type: :string, format: :uuid},
                description: "The only ships an upgrade leads into this one from, where every upgrade seen into it starts from a variant of its own hull; null when any ship can"
              },
              crew: {type: [:integer, :null]},
              cargo: {type: [:number, :null]},
              image: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false,
            required: %w[id name slug onSale ccuInto ccuOutOf]
          })
        end
      end
    end
  end
end
