# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class StationClassificationEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Station.classifications.keys
          })
        end
      end
    end
  end
end
