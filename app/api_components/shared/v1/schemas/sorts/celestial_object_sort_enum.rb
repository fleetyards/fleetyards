# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Sorts
        class CelestialObjectSortEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: CelestialObject::ALLOWED_SORTING_PARAMS
          })
        end
      end
    end
  end
end
