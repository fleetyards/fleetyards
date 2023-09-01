# frozen_string_literal: true

module V1
  module Schemas
    class RoadmapItemChangeset
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          release: {type: :array, items: {type: :string, nullable: true}},
          committed: {type: :array, items: {type: :boolean}},
          active: {type: :array, items: {type: :boolean}}
        },
        additionalProperties: false
      })
    end
  end
end
