# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class HardpointSourceEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Hardpoint.sources.keys
          })
        end
      end
    end
  end
end
