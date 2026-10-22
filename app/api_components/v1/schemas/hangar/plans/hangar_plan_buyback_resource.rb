# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanBuybackResource
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              kind: ::V1::Schemas::Enums::BuybackPledgeKindEnum,
              price: {type: [:number, :null]},
              used: {type: :boolean},
              lifetimeInsurance: {type: :boolean},
              insuranceMonths: {type: [:integer, :null], description: "Unknown until the pledge's details are synced"},
              insuranceKnown: {type: :boolean, description: "False until the pledge's details are synced, so no insurance listed is not yet none"},
              models: {
                type: :array,
                items: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
                description: "The ships buying the pledge back returns, where their names are known"
              },
              upgradeFromModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              upgradeToModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel
            },
            additionalProperties: false,
            required: %w[id name kind used lifetimeInsurance insuranceKnown models]
          })
        end
      end
    end
  end
end
