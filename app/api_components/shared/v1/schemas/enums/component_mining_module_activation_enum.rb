# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Whether a mining module works for as long as it sits in its slot, or
        # is fired off for a limited time a set number of times.
        class ComponentMiningModuleActivationEnum
          include OpenapiRuby::Components::Base

          VALUES = %w[active passive].freeze

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
