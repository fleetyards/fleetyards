# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Sorts
        class RoadmapItemSortEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: RoadmapItem::ALLOWED_SORTING_PARAMS
          })
        end
      end
    end
  end
end
