# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ImportStatusEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Import.aasm.states.map(&:name)
          })
        end
      end
    end
  end
end
