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
              upgradeFromModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              upgradeToModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel
            },
            additionalProperties: false,
            required: %w[id name kind used]
          })
        end
      end
    end
  end
end
