# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ImportStatusEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Import.aasm.states.map(&:name),
            "x-enumNames": ::Import.aasm.states.map { |s| transform_enum_key(s.name) }
          })
        end
      end
    end
  end
end
