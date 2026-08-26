# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      # A map of container size in SCU to how many of them a ship must take, as
      # containerFit[16]=2&containerFit[32]=1. The sizes are the ones
      # CargoHoldContainerCapacity validates against; the controller ignores any
      # entry whose quantity is not positive.
      #
      # Spelled out property by property rather than as an additionalProperties
      # map: query values arrive as strings, and request validation only coerces
      # them for declared properties. A map typed through additionalProperties
      # rejects every request, which is what this parameter did before.
      class ContainerFitQuery
        include OpenapiRuby::Components::Base

        SIZES = ::CargoHoldContainerCapacity::CONTAINER_SIZES

        schema({
          type: :object,
          properties: SIZES.to_h { |size| [size.to_s, {type: :number, minimum: 0}] },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
