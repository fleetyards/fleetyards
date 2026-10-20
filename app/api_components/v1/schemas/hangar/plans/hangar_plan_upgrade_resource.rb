# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanUpgradeResource
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              quantity: {type: :integer},
              usedCount: {type: :integer},
              pledgeValue: {type: [:number, :null]},
              fromModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              toModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel
            },
            additionalProperties: false,
            required: %w[id name quantity usedCount]
          })
        end
      end
    end
  end
end
