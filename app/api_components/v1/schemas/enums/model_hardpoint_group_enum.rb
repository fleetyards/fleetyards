# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class ModelHardpointGroupEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::ModelHardpoint.groups.keys
        })
      end
    end
  end
end
