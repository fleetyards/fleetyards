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
              classification: {type: [:string, :null]},
              size: {type: [:string, :null]},
              productionStatus: {type: [:string, :null]},
              pledgePrice: {type: [:number, :null], description: "Store price in USD; null when unknown"},
              onSale: {type: :boolean},
              crew: {type: [:integer, :null]},
              cargo: {type: [:number, :null]},
              image: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false,
            required: %w[id name slug onSale]
          })
        end
      end
    end
  end
end
