# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class StationTypeEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::Station.station_types.keys
        })
      end
    end
  end
end
