# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronMemberUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            createdAt: {type: :string, format: :date},
            fleetSquadronRoleId: {type: :string, format: :uuid}
          },
          additionalProperties: false
        })
      end
    end
  end
end
