# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelHardpointSourceEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::ModelHardpoint.sources.keys
          })
        end
      end
    end
  end
end
