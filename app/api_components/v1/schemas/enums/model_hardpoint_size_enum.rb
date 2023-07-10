# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class ModelHardpointSizeEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::ModelHardpoint.sizes.keys
        })
      end
    end
  end
end
