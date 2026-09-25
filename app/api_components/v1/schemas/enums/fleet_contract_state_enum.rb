# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetContractStateEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[draft open in_progress fulfilled settled cancelled expired].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
