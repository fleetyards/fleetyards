# frozen_string_literal: true

module V1
  module Schemas
    class Vehicle < VehicleMinimal
      include SchemaConcern

      schema({
        properties: {}
      })
    end
  end
end
