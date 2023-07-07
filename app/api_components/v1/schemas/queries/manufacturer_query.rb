# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ManufacturerQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            withModels: {type: :boolean, nullable: true},
            nameCont: {type: :string, nullable: true},
            nameIn: {type: :array, items: {type: :string}, nullable: true}
          }
        })
      end
    end
  end
end
