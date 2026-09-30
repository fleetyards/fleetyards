# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # The signature a missile's seeker locks onto, as the game names it.
        class ComponentMissileTrackingSignalEnum
          include OpenapiRuby::Components::Base

          VALUES = %w[Infrared Electromagnetic CrossSection].freeze

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
