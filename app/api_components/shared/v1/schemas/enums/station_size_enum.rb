# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class StationSizeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Station.sizes.keys
          })
        end
      end
    end
  end
end
