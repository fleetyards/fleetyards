# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetContractCrewRoleEnum
        include OpenapiRuby::Components::Base

        VALUES = ::FleetContractAssignment::ROLES.keys.map(&:to_s).freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
