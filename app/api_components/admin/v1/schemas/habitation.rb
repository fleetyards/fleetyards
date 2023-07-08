# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Habitation
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            habitationName: {type: :string, nullable: true},
            type: {type: :string},
            typeLabel: {type: :string}
          },
          required: %w[name type typeLabel]
        })
      end
    end
  end
end
