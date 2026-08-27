# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetMembershipUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            primary: {type: :boolean},
            shipsFilter: ::V1::Schemas::Enums::FleetMembershipShipsFilterEnum,
            hangarGroupId: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
