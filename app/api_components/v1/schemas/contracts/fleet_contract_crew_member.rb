# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      class FleetContractCrewMember
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            role: ::V1::Schemas::Enums::FleetContractCrewRoleEnum,
            state: ::V1::Schemas::Enums::FleetContractCrewStateEnum,
            user: ::V1::Schemas::Contracts::FleetContractCrewUser,
            requestedAt: {type: [:string, :null], format: "date-time"},
            acceptedAt: {type: [:string, :null], format: "date-time"},
            createdAt: {type: [:string, :null], format: "date-time"},
            updatedAt: {type: [:string, :null], format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id role state]
        })
      end
    end
  end
end
