# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Which of the two elements the contract is declared as. The export
        # gives no other signal of the difference, and a career contract is the
        # repeatable kind an org offers by standing band.
        class GameMissionKindEnum
          include OpenapiRuby::Components::Base

          VALUES = %w[career contract].freeze

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
