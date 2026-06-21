# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventAdminCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            userId: {type: :string, format: :uuid},
            role: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEventAdmin::ROLES
            }
          },
          required: %w[userId],
          additionalProperties: false
        })
      end
    end
  end
end
