# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FleetFidClaimUpdateInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              endsAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[endsAt]
          })
        end
      end
    end
  end
end
