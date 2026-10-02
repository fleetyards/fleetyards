# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # How much an RSI organisation asks of its members.
      class FleetCommitmentEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Fleet::COMMITMENTS

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
