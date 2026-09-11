# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class ImportStatusEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::Import.aasm.states.map(&:name),
          "x-enumNames": ::Import.aasm.states.map { |state| transform_enum_key(state.name) }
        })
      end
    end
  end
end
