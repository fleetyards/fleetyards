# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class CelestialObject < ::V1::Schemas::CelestialObject
        include SchemaConcern

        schema({
          properties: {
            id: {type: :string, format: :uuid}
          }
        })
      end
    end
  end
end
