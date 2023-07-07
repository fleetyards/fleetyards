# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ImageQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            modelIn: {type: :array, items: {type: :string}, nullable: true},
            stationIn: {type: :array, items: {type: :string}, nullable: true}
          }
        })
      end
    end
  end
end
