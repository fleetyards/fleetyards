# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class FleetInventoryVisibilityEnum
          include OpenapiRuby::Components::Base

          VALUES = ::FleetInventory.visibilities.keys.map(&:to_s).freeze

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
