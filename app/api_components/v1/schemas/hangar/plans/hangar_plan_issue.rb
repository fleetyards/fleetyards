# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanIssue
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              kind: ::V1::Schemas::Enums::HangarPlanIssueKindEnum,
              name: {type: :string},
              slotId: {type: [:string, :null], format: :uuid}
            },
            additionalProperties: false,
            required: %w[kind name]
          })
        end
      end
    end
  end
end
