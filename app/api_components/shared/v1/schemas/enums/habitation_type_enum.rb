# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class HabitationTypeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Habitation.habitation_types.keys
          })
        end
      end
    end
  end
end
