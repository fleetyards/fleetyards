# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class AdminFleetMemberUpdateInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              fleetRoleId: {type: :string, format: :uuid}
            },
            additionalProperties: false,
            required: %w[fleetRoleId]
          })
        end
      end
    end
  end
end
