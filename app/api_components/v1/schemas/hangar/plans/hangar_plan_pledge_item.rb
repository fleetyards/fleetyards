# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanPledgeItem
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              kind: ::V1::Schemas::Enums::HangarPledgeItemKindEnum,
              quantity: {type: :integer}
            },
            additionalProperties: false,
            required: %w[id name kind quantity]
          })
        end
      end
    end
  end
end
