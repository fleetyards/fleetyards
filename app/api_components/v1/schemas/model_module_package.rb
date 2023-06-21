# frozen_string_literal: true

module V1
  module Schemas
    class ModelModulePackage
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string, nullable: true},
          slug: {type: :string, nullable: true}
        },
        required: %w[name slug]
      })
    end
  end
end
