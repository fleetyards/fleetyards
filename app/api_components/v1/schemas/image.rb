# frozen_string_literal: true

module V1
  module Schemas
    class Image
      include SchemaConcern

      schema :base, {
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          caption: {type: :string},
          url: {type: :string},
          width: {type: :string},
          height: {type: :string},
          type: {type: :string},
          background: {type: :boolean},
          smallUrl: {type: :string},
          bigUrl: {type: :string},
          gallery: {"$ref" => "#/components/schemas/Gallery", :nullable => true},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[id name url width height type background smallUrl bigUrl createdAt updatedAt]
      }
    end
  end
end
