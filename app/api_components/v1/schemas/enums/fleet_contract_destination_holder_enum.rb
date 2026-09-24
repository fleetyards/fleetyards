# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Whose inventory a contract's end is: one of the fleet's, or the author's
      # own. A delivery into the second is addressed to the author.
      class FleetContractDestinationHolderEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[fleet user].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
