# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # The SCU container sizes a cargo hold is measured against. Referenced from
      # ContainerFitQuery's propertyNames so the generated client gets a runtime
      # constant — the cargo-grids tool used to keep its own copy of the list.
      class ContainerSizeEnum
        include OpenapiRuby::Components::Base

        VALUES = ::CargoHoldContainerCapacity::CONTAINER_SIZES.map(&:to_s).freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| "SCU_#{value}" }
        })
      end
    end
  end
end
