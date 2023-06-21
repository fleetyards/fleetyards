# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class ModelHardpointTypeEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::ModelHardpoint.hardpoint_types.keys
        })
      end
    end
  end
end
