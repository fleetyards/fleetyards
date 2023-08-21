# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelHardpointCategoryEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::ModelHardpoint.categories.keys
          })
        end
      end
    end
  end
end
