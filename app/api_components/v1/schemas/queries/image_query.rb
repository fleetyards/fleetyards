# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ImageQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            modelIn: {type: :array, items: {type: :string}},
            stationIn: {type: :array, items: {type: :string}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
