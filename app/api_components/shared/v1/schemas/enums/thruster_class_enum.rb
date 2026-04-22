# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ThrusterClassEnum
          include OpenapiRuby::Components::Base

          TYPES = %w[main retro vtol mav].freeze

          schema({
            type: :string,
            enum: TYPES,
            "x-enumNames": TYPES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
