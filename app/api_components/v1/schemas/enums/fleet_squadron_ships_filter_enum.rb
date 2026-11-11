# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetSquadronShipsFilterEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::FleetSquadronMembership.ships_filters.keys,
          "x-enumNames": ::FleetSquadronMembership.ships_filters.keys.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
