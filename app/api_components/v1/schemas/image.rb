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
          caption: {type: :string, nullable: true},
          height: {type: :number, nullable: true},
          name: {type: :string},
          smallUrl: {type: :string, format: :uri},
          type: {type: :string},
          url: {type: :string, format: :uri},
          width: {type: :number, nullable: true}
        },
        additionalProperties: false,
        required: %w[id name url width height type background smallUrl bigUrl]
      })
    end
  end
end
