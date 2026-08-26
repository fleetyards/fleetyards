# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class LoanerFilterEnum
          include OpenapiRuby::Components::Base

          # Tri-state filter: absent means "exclude loaners", true adds them
          # alongside owned ships, only narrows to loaners.

          VALUES = %w[true only].freeze

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
