# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Image
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            caption: {type: :string, nullable: true},
            size: {type: :number},
            width: {type: :integer, nullable: true},
            height: {type: :integer, nullable: true},
            type: {type: :string},
            enabled: {type: :boolean},
            global: {type: :boolean},
            background: {type: :boolean},
            url: {type: :string, format: :uri},
            smallUrl: {type: :string, format: :uri},
            bigUrl: {type: :string, format: :uri},
            gallery: {"$ref": "#/components/schemas/Gallery", nullable: true},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id name createdAt updatedAt]
        })
      end
    end
  end
end
