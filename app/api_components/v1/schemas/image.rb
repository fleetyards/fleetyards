# frozen_string_literal: true

module V1
  module Schemas
    class Image
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          background: {type: :boolean},
          bigUrl: {type: :string, format: :uri},
          caption: {type: :string},
          name: {type: :string},
          smallUrl: {type: :string, format: :uri},
          type: {type: :string},
          url: {type: :string, format: :uri},
          width: {type: :number},
          height: {type: :number},
          gallery: {"$ref": "#/components/schemas/Gallery"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name url type background smallUrl bigUrl createdAt updatedAt]
      })
    end
  end
end
