# frozen_string_literal: true

module V1
  module Schemas
    class VehiclePublic < VehiclePublicMinimal
      include SchemaConcern

      schema({
        properties: {}
      })
    end
  end
end
