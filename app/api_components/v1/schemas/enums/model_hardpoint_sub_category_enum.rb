# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class ModelHardpointSubCategoryEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::ModelHardpoint.sub_categories.keys
        })
      end
    end
  end
end
